'use strict';
/**
 * Controller: /admin/finance/* endpoints
 * Sprint: Full Delivery 2026-06-09..18 (A-03 phase 1; A-04 + A-05 extend this file)
 * Authored by: Account A
 *
 * All handlers follow the platform convention:
 *   common.response(req, res, status, success, message, data)
 *
 * Pre-migration tolerance: every DB call is wrapped in try/catch so that
 * before migrations apply, endpoints return empty-state envelopes (no crash).
 * After migrations run, the same code returns live data.
 */
const { Op } = require("sequelize");
const models = require("../models");
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");
const logger = require("../utils/logger");

const safeNumber = (v, fallback = 0) => {
    const n = Number(v);
    return Number.isFinite(n) ? n : fallback;
};

const safePaging = (body) => {
    const page = Math.max(1, parseInt(body?.page, 10) || commonConfig.listPage);
    const limit = Math.min(100, Math.max(1, parseInt(body?.limit, 10) || commonConfig.listLimit));
    return { page, limit };
};

const buildDateRange = (from, to, column) => {
    const range = {};
    if (from) range[Op.gte] = new Date(`${from}T00:00:00.000Z`);
    if (to) range[Op.lte] = new Date(`${to}T23:59:59.999Z`);
    return Object.keys(range).length ? { [column]: range } : {};
};

/**
 * GET /admin/finance/dashboard
 * Returns aggregated KPIs + recent ledger + reconciliation summary.
 * Empty-state safe.
 */
exports.getDashboard = async (req, res) => {
    try {
        const { from, to } = req.body; // validation middleware merges query into body
        const ledgerWhere = buildDateRange(from, to, "fl_created_at");

        // Aggregate KPIs — Promise.all for parallel queries
        const [totalRevenue, totalCommission, totalPayouts, pendingPayoutsAgg, reconSummary] = await Promise.all([
            models.tbl_financial_ledger.sumAmount({ ...ledgerWhere, fl_transaction_type: "GUEST_PAYMENT", fl_status: "COMPLETED" }).catch(() => 0),
            models.tbl_financial_ledger.sumAmount({ ...ledgerWhere, fl_transaction_type: "PLATFORM_COMMISSION", fl_status: "COMPLETED" }).catch(() => 0),
            models.tbl_payouts.findAll({ where: { po_status: "COMPLETED", ...(from || to ? buildDateRange(from, to, "po_completed_at") : {}) }, attributes: [[models.sequelize.fn("SUM", models.sequelize.col("po_amount")), "total"]], raw: true }).then(r => safeNumber(r?.[0]?.total)).catch(() => 0),
            models.tbl_payouts.findAll({ where: { po_status: ["QUEUED", "PROCESSING"] }, attributes: [[models.sequelize.fn("SUM", models.sequelize.col("po_amount")), "total"]], raw: true }).then(r => safeNumber(r?.[0]?.total)).catch(() => 0),
            models.tbl_reconciliation_records.summary().catch(() => ({ matched: 0, variance: 0, pending: 0 })),
        ]);

        // Recent transactions — last 5 ledger entries
        let recentTransactions = [];
        try {
            recentTransactions = await models.tbl_financial_ledger.findAll({
                limit: 5,
                order: [["fl_created_at", "DESC"]],
                raw: true,
            });
        } catch (e) {
            recentTransactions = [];
        }

        // Monthly revenue series — last 6 months
        let monthlyRevenue = [];
        try {
            const rows = await models.sequelize.query(
                `SELECT
                    DATE_FORMAT(fl_created_at, '%Y-%m') AS month_key,
                    DATE_FORMAT(fl_created_at, '%b') AS month,
                    SUM(CASE WHEN fl_transaction_type='GUEST_PAYMENT' THEN fl_amount ELSE 0 END) AS revenue,
                    SUM(CASE WHEN fl_transaction_type='PLATFORM_COMMISSION' THEN fl_amount ELSE 0 END) AS commission,
                    SUM(CASE WHEN fl_transaction_type='PAYOUT' THEN fl_amount ELSE 0 END) AS payouts
                 FROM tbl_financial_ledger
                 WHERE fl_status='COMPLETED' AND fl_created_at >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
                 GROUP BY month_key, month
                 ORDER BY month_key ASC`,
                { type: models.sequelize.QueryTypes.SELECT }
            );
            monthlyRevenue = rows.map(r => ({
                month: r.month,
                revenue: safeNumber(r.revenue),
                commission: safeNumber(r.commission),
                payouts: safeNumber(r.payouts),
            }));
        } catch (e) {
            monthlyRevenue = [];
        }

        // Category breakdown — placeholder until property-category join is wired (A-05)
        const categoryBreakdown = [];

        return common.response(req, res, commonConfig.successStatus, true, "success", {
            totalRevenue: safeNumber(totalRevenue),
            totalCommission: safeNumber(totalCommission),
            totalPayouts: safeNumber(totalPayouts),
            pendingPayouts: safeNumber(pendingPayoutsAgg),
            revenueGrowth: 0,
            commissionGrowth: 0,
            monthlyRevenue,
            categoryBreakdown,
            recentTransactions,
            reconciliationSummary: reconSummary,
        });
    } catch (error) {
        logger.error("getDashboard failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "dashboard failed");
    }
};

/**
 * POST /admin/finance/ledger/search
 * Paged ledger entries with filters.
 */
exports.searchLedger = async (req, res) => {
    try {
        const { page, limit } = safePaging(req.body);
        const { hostId, userId, transactionType, status, dateFrom, dateTo, search } = req.body;

        const where = {
            ...(hostId ? { fl_host_id: hostId } : {}),
            ...(userId ? { fl_user_id: userId } : {}),
            ...(transactionType ? { fl_transaction_type: transactionType } : {}),
            ...(status ? { fl_status: status } : {}),
            ...buildDateRange(dateFrom, dateTo, "fl_created_at"),
        };

        if (search) {
            where[Op.or] = [
                { fl_reference_id: { [Op.like]: `%${search}%` } },
                { fl_description: { [Op.like]: `%${search}%` } },
            ];
        }

        let items = [], totalRecords = 0;
        try {
            const result = await models.tbl_financial_ledger.findAndCountAll({
                where,
                limit,
                offset: (page - 1) * limit,
                order: [["fl_created_at", "DESC"]],
                raw: true,
            });
            items = result.rows;
            totalRecords = result.count;
        } catch (e) {
            // Pre-migration safe fallback
            logger.warn("ledger.searchLedger DB error (likely pre-migration)", { error: e?.message });
        }

        return common.response(req, res, commonConfig.successStatus, true, "success", {
            items,
            totalRecords,
            currentPage: page,
            totalPages: Math.max(1, Math.ceil(totalRecords / limit)),
            limit,
        });
    } catch (error) {
        logger.error("searchLedger failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "ledger search failed");
    }
};

/**
 * POST /admin/finance/payout/search
 * Paged payouts with filters.
 */
exports.searchPayouts = async (req, res) => {
    try {
        const { page, limit } = safePaging(req.body);
        const { hostId, status, dateFrom, dateTo } = req.body;

        const where = {
            ...(hostId ? { po_host_id: hostId } : {}),
            ...(status ? { po_status: status } : {}),
            ...buildDateRange(dateFrom, dateTo, "po_created_at"),
        };

        let items = [], totalRecords = 0;
        try {
            const result = await models.tbl_payouts.findAndCountAll({
                where,
                limit,
                offset: (page - 1) * limit,
                order: [["po_created_at", "DESC"]],
                raw: true,
            });
            items = result.rows;
            totalRecords = result.count;
        } catch (e) {
            logger.warn("payouts.search DB error (likely pre-migration)", { error: e?.message });
        }

        return common.response(req, res, commonConfig.successStatus, true, "success", {
            items,
            totalRecords,
            currentPage: page,
            totalPages: Math.max(1, Math.ceil(totalRecords / limit)),
            limit,
        });
    } catch (error) {
        logger.error("searchPayouts failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "payout search failed");
    }
};

// ============================================================================
// A-04 — Ledger CRUD
// ============================================================================

/** GET /admin/finance/ledger/:ledgerId */
exports.getLedgerEntry = async (req, res) => {
    try {
        const ledgerId = parseInt(req.params.ledgerId, 10);
        const row = await models.tbl_financial_ledger.findOne({ where: { fl_id: ledgerId }, raw: true }).catch(() => null);
        if (!row) {
            return common.response(req, res, commonConfig.successStatus, true, "no record found", null);
        }
        return common.response(req, res, commonConfig.successStatus, true, "success", row);
    } catch (error) {
        logger.error("getLedgerEntry failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "ledger fetch failed");
    }
};

/** POST /admin/finance/ledger/host/:hostId */
exports.getHostLedger = async (req, res) => {
    try {
        const hostId = parseInt(req.params.hostId, 10);
        const { page, limit } = safePaging(req.body);
        const { dateFrom, dateTo } = req.body;

        const where = { fl_host_id: hostId, ...buildDateRange(dateFrom, dateTo, "fl_created_at") };

        let items = [], totalRecords = 0, balance = 0;
        try {
            const result = await models.tbl_financial_ledger.findAndCountAll({
                where, limit, offset: (page - 1) * limit,
                order: [["fl_created_at", "DESC"]], raw: true,
            });
            items = result.rows;
            totalRecords = result.count;
            // Running balance = sum of CREDIT minus sum of DEBIT for this host
            const credits = safeNumber(await models.tbl_financial_ledger.sum("fl_amount", { where: { ...where, fl_entry_type: "CREDIT", fl_status: "COMPLETED" } }));
            const debits = safeNumber(await models.tbl_financial_ledger.sum("fl_amount", { where: { ...where, fl_entry_type: "DEBIT", fl_status: "COMPLETED" } }));
            balance = credits - debits;
        } catch (e) {
            logger.warn("getHostLedger DB error (likely pre-migration)", { error: e?.message });
        }

        return common.response(req, res, commonConfig.successStatus, true, "success", {
            items, balance,
            totalRecords, currentPage: page,
            totalPages: Math.max(1, Math.ceil(totalRecords / limit)), limit,
        });
    } catch (error) {
        logger.error("getHostLedger failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "host ledger failed");
    }
};

/** POST /admin/finance/ledger/user/:userId */
exports.getGuestLedger = async (req, res) => {
    try {
        const userId = parseInt(req.params.userId, 10);
        const { page, limit } = safePaging(req.body);
        const { dateFrom, dateTo } = req.body;

        const where = { fl_user_id: userId, ...buildDateRange(dateFrom, dateTo, "fl_created_at") };

        let items = [], totalRecords = 0;
        try {
            const result = await models.tbl_financial_ledger.findAndCountAll({
                where, limit, offset: (page - 1) * limit,
                order: [["fl_created_at", "DESC"]], raw: true,
            });
            items = result.rows;
            totalRecords = result.count;
        } catch (e) {
            logger.warn("getGuestLedger DB error", { error: e?.message });
        }

        return common.response(req, res, commonConfig.successStatus, true, "success", {
            items, totalRecords, currentPage: page,
            totalPages: Math.max(1, Math.ceil(totalRecords / limit)), limit,
        });
    } catch (error) {
        logger.error("getGuestLedger failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "guest ledger failed");
    }
};

/** POST /admin/finance/ledger/export — CSV stream */
exports.exportLedger = async (req, res) => {
    try {
        const { hostId, userId, dateFrom, dateTo, format = "csv" } = req.body;
        const where = {
            ...(hostId ? { fl_host_id: hostId } : {}),
            ...(userId ? { fl_user_id: userId } : {}),
            ...buildDateRange(dateFrom, dateTo, "fl_created_at"),
        };

        let rows = [];
        try {
            rows = await models.tbl_financial_ledger.findAll({ where, order: [["fl_created_at", "DESC"]], raw: true });
        } catch (e) {
            logger.warn("exportLedger DB error", { error: e?.message });
        }

        const headers = ["ledger_id", "booking_id", "host_id", "user_id", "transaction_type", "entry_type", "amount", "balance_after", "reference_id", "description", "status", "created_at"];
        const csvHeader = headers.join(",");
        const csvBody = rows.map(r => headers.map(h => {
            const val = r[`fl_${h === "ledger_id" ? "id" : h}`];
            if (val === null || val === undefined) return "";
            const s = String(val).replace(/"/g, '""');
            return /[,"\n]/.test(s) ? `"${s}"` : s;
        }).join(",")).join("\n");

        // UTF-8 BOM for Excel compatibility
        const csv = "﻿" + csvHeader + "\n" + csvBody;
        const filename = `ledger_${new Date().toISOString().slice(0, 10)}.csv`;

        res.setHeader("Content-Type", "text/csv; charset=utf-8");
        res.setHeader("Content-Disposition", `attachment; filename="${filename}"`);
        return res.status(200).send(csv);
    } catch (error) {
        logger.error("exportLedger failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "ledger export failed");
    }
};

// ============================================================================
// A-04 — Payout CRUD
// ============================================================================

/** GET /admin/finance/payout/:payoutId */
exports.getPayout = async (req, res) => {
    try {
        const payoutId = parseInt(req.params.payoutId, 10);
        let payout = null;
        try {
            payout = await models.tbl_payouts.findOne({ where: { po_id: payoutId }, raw: true });
        } catch (e) {
            logger.warn("getPayout DB error", { error: e?.message });
        }
        if (!payout) {
            return common.response(req, res, commonConfig.successStatus, true, "no record found", null);
        }

        // Sidecar — related ledger entries + host snippet
        let ledgerEntries = [], host = null;
        try {
            ledgerEntries = await models.tbl_financial_ledger.findAll({
                where: { fl_reference_id: payout.po_reference_id || `payout_${payoutId}` },
                raw: true,
            });
            // host name from tbl_users; email from tbl_user_creds (cred_user_email)
            const hostRow = await models.sequelize.query(
                `SELECT u.user_id, u.user_fullName, c.cred_user_email
                 FROM tbl_users u LEFT JOIN tbl_user_creds c ON c.cred_user_id = u.user_id
                 WHERE u.user_id = :id LIMIT 1`,
                { replacements: { id: payout.po_host_id }, type: models.sequelize.QueryTypes.SELECT }
            ).then((r) => r && r[0]).catch(() => null);
            if (hostRow) host = { id: hostRow.user_id, name: hostRow.user_fullName, email: hostRow.cred_user_email || null };
        } catch (e) {
            // sidecar best-effort
        }

        return common.response(req, res, commonConfig.successStatus, true, "success", { ...payout, ledgerEntries, host });
    } catch (error) {
        logger.error("getPayout failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "payout fetch failed");
    }
};

/** POST /admin/finance/payout/initiate — manual admin trigger */
exports.initiatePayout = async (req, res) => {
    try {
        const { hostId, amount, note } = req.body;
        const adminId = req.admin?.adminId || req.admin?.id || null;

        // If amount omitted, compute pending balance for the host
        let payoutAmount = amount;
        if (!payoutAmount) {
            try {
                const credits = safeNumber(await models.tbl_financial_ledger.sum("fl_amount", { where: { fl_host_id: hostId, fl_entry_type: "CREDIT", fl_transaction_type: "HOST_EARNING", fl_status: "COMPLETED" } }));
                const debits = safeNumber(await models.tbl_financial_ledger.sum("fl_amount", { where: { fl_host_id: hostId, fl_entry_type: "DEBIT", fl_transaction_type: "PAYOUT", fl_status: "COMPLETED" } }));
                payoutAmount = Math.max(0, credits - debits);
            } catch (e) {
                payoutAmount = 0;
            }
        }

        if (payoutAmount <= 0) {
            return common.response(req, res, commonConfig.errorStatus, false, "no pending earnings to pay out");
        }

        const created = await models.tbl_payouts.create({
            po_host_id: hostId,
            po_amount: payoutAmount,
            po_status: "QUEUED",
            po_payout_method: "BANK_TRANSFER",
            po_initiated_by: "ADMIN",
            po_note: note || null,
        });

        return common.response(req, res, commonConfig.successStatus, true, "success", {
            payoutId: created.po_id,
            status: created.po_status,
            amount: created.po_amount,
            initiatedBy: adminId,
        });
    } catch (error) {
        logger.error("initiatePayout failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "payout initiation failed");
    }
};

/** PUT /admin/finance/payout/:payoutId/approve */
exports.approvePayout = async (req, res) => {
    try {
        const payoutId = parseInt(req.params.payoutId, 10);
        await models.tbl_payouts.updateStatus(payoutId, "PROCESSING");

        // TODO(A-09 Razorpay live): once live, trigger RazorpayX transfer here.
        // For sprint: auto-transition to COMPLETED so end-to-end can be tested.
        await models.tbl_payouts.updateStatus(payoutId, "COMPLETED");

        // Write ledger entry for the payout
        const payout = await models.tbl_payouts.findOne({ where: { po_id: payoutId }, raw: true });
        if (payout) {
            await models.tbl_financial_ledger.addEntry({
                fl_host_id: payout.po_host_id,
                fl_transaction_type: "PAYOUT",
                fl_entry_type: "DEBIT",
                fl_amount: payout.po_amount,
                fl_reference_id: payout.po_reference_id || `payout_${payoutId}`,
                fl_description: `Payout #${payoutId} disbursed`,
                fl_status: "COMPLETED",
            }).catch(() => null);
        }

        return common.response(req, res, commonConfig.successStatus, true, "success", { payoutId, status: "COMPLETED" });
    } catch (error) {
        logger.error("approvePayout failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "payout approve failed");
    }
};

/** PUT /admin/finance/payout/:payoutId/reject */
exports.rejectPayout = async (req, res) => {
    try {
        const payoutId = parseInt(req.params.payoutId, 10);
        const { reason } = req.body;
        await models.tbl_payouts.updateStatus(payoutId, "FAILED", { po_failure_reason: reason });
        return common.response(req, res, commonConfig.successStatus, true, "success", { payoutId, status: "FAILED", reason });
    } catch (error) {
        logger.error("rejectPayout failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "payout reject failed");
    }
};

// ============================================================================
// A-04 — Payout Schedule CRUD
// ============================================================================

/** POST /admin/finance/payout/schedule/search */
exports.searchSchedules = async (req, res) => {
    try {
        const { page, limit } = safePaging(req.body);
        const { hostId } = req.body;

        const where = hostId ? { ps_host_id: hostId } : {};

        let items = [], totalRecords = 0;
        try {
            const result = await models.tbl_payout_schedules.findAndCountAll({
                where, limit, offset: (page - 1) * limit,
                order: [["ps_created_at", "DESC"]], raw: true,
            });
            items = result.rows;
            totalRecords = result.count;
        } catch (e) {
            logger.warn("searchSchedules DB error", { error: e?.message });
        }

        return common.response(req, res, commonConfig.successStatus, true, "success", {
            items, totalRecords, currentPage: page,
            totalPages: Math.max(1, Math.ceil(totalRecords / limit)), limit,
        });
    } catch (error) {
        logger.error("searchSchedules failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "schedule search failed");
    }
};

/** PUT /admin/finance/payout/schedule/:scheduleId */
exports.updateSchedule = async (req, res) => {
    try {
        const scheduleId = parseInt(req.params.scheduleId, 10);
        const { frequency, minPayoutAmount, isActive, payoutMethod } = req.body;

        const payload = {};
        if (frequency !== undefined && frequency !== null) payload.ps_frequency = frequency;
        if (minPayoutAmount !== undefined && minPayoutAmount !== null) payload.ps_min_payout_amount = minPayoutAmount;
        if (isActive !== undefined && isActive !== null) payload.ps_is_active = isActive ? 1 : 0;
        if (payoutMethod !== undefined && payoutMethod !== null) payload.ps_payout_method = payoutMethod;

        if (Object.keys(payload).length === 0) {
            return common.response(req, res, commonConfig.errorStatus, false, "no updatable fields supplied");
        }

        await models.tbl_payout_schedules.update(payload, { where: { ps_id: scheduleId } });
        const updated = await models.tbl_payout_schedules.findOne({ where: { ps_id: scheduleId }, raw: true });
        return common.response(req, res, commonConfig.successStatus, true, "success", updated);
    } catch (error) {
        logger.error("updateSchedule failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "schedule update failed");
    }
};

/** POST /admin/finance/payout/schedule/create */
exports.createSchedule = async (req, res) => {
    try {
        const { hostId, frequency, minPayoutAmount, payoutMethod, accountDetails } = req.body;

        // Mask account number — store only last 4
        const maskedAccount = {
            ...accountDetails,
            accountNumber: accountDetails?.accountNumber
                ? `XXXX${String(accountDetails.accountNumber).slice(-4)}`
                : null,
        };

        const result = await models.tbl_payout_schedules.upsertForHost(hostId, {
            ps_frequency: frequency,
            ps_min_payout_amount: minPayoutAmount,
            ps_payout_method: payoutMethod,
            ps_account_details: JSON.stringify(maskedAccount),
            ps_is_active: 1,
        });

        return common.response(req, res, commonConfig.successStatus, true, "success", result);
    } catch (error) {
        logger.error("createSchedule failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "schedule create failed");
    }
};

// ============================================================================
// A-05 — Invoice
// ============================================================================

const PDFDocument = require("pdfkit");

/** POST /admin/finance/invoice/search */
exports.searchInvoices = async (req, res) => {
    try {
        const { page, limit } = safePaging(req.body);
        const { hostId, userId, invoiceType, status, dateFrom, dateTo } = req.body;

        const where = {
            ...(hostId ? { inv_host_id: hostId } : {}),
            ...(userId ? { inv_user_id: userId } : {}),
            ...(invoiceType ? { inv_invoice_type: invoiceType } : {}),
            ...(status ? { inv_status: status } : {}),
            ...buildDateRange(dateFrom, dateTo, "inv_created_at"),
        };

        let items = [], totalRecords = 0;
        try {
            const result = await models.tbl_invoices.findAndCountAll({
                where, limit, offset: (page - 1) * limit,
                order: [["inv_created_at", "DESC"]], raw: true,
            });
            items = result.rows;
            totalRecords = result.count;
        } catch (e) {
            logger.warn("searchInvoices DB error", { error: e?.message });
        }

        return common.response(req, res, commonConfig.successStatus, true, "success", {
            items, totalRecords, currentPage: page,
            totalPages: Math.max(1, Math.ceil(totalRecords / limit)), limit,
        });
    } catch (error) {
        logger.error("searchInvoices failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "invoice search failed");
    }
};

/** GET /admin/finance/invoice/:invoiceId */
exports.getInvoice = async (req, res) => {
    try {
        const invoiceId = parseInt(req.params.invoiceId, 10);
        const invoice = await models.tbl_invoices.findOne({ where: { inv_id: invoiceId }, raw: true }).catch(() => null);
        if (!invoice) {
            return common.response(req, res, commonConfig.successStatus, true, "no record found", null);
        }

        // Parse line_items JSON if present
        let lineItems = [];
        try {
            if (invoice.inv_line_items) lineItems = JSON.parse(invoice.inv_line_items);
        } catch (e) {
            lineItems = [];
        }

        return common.response(req, res, commonConfig.successStatus, true, "success", { ...invoice, lineItems });
    } catch (error) {
        logger.error("getInvoice failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "invoice fetch failed");
    }
};

/** GET /admin/finance/invoice/:invoiceId/download — PDF stream */
exports.downloadInvoice = async (req, res) => {
    try {
        const invoiceId = parseInt(req.params.invoiceId, 10);
        const invoice = await models.tbl_invoices.findOne({ where: { inv_id: invoiceId }, raw: true }).catch(() => null);
        if (!invoice) {
            return common.response(req, res, commonConfig.notFoundStatus, false, "invoice not found");
        }

        const filename = `${invoice.inv_invoice_number || `invoice_${invoiceId}`}.pdf`;
        res.setHeader("Content-Type", "application/pdf");
        res.setHeader("Content-Disposition", `attachment; filename="${filename}"`);

        const doc = new PDFDocument({ size: "A4", margin: 50 });
        doc.pipe(res);

        // Header
        doc.fontSize(20).text("AAJOO Homes", { align: "center" });
        doc.fontSize(10).text("GST Invoice", { align: "center" });
        doc.moveDown();

        // Invoice meta
        doc.fontSize(12)
            .text(`Invoice Number: ${invoice.inv_invoice_number}`)
            .text(`Invoice Date: ${new Date(invoice.inv_created_at).toLocaleDateString("en-IN")}`)
            .text(`Type: ${invoice.inv_invoice_type}`)
            .text(`Status: ${invoice.inv_status}`)
            .text(`GSTIN: ${invoice.inv_gstin || "N/A"}`)
            .text(`HSN/SAC: ${invoice.inv_hsn_sac_code || "N/A"}`);
        doc.moveDown();

        // Line items
        let lineItems = [];
        try { if (invoice.inv_line_items) lineItems = JSON.parse(invoice.inv_line_items); } catch (e) { /* noop */ }
        doc.fontSize(11).text("Line Items:", { underline: true });
        if (lineItems.length === 0) {
            doc.text(`  ${invoice.inv_invoice_type} — Booking #${invoice.inv_booking_id || "N/A"}`);
        } else {
            lineItems.forEach((li, i) => {
                doc.text(`  ${i + 1}. ${li.description} — qty ${li.quantity}, rate INR ${li.rate}, amount INR ${li.amount}`);
            });
        }
        doc.moveDown();

        // Totals
        doc.fontSize(12)
            .text(`Subtotal: INR ${invoice.inv_subtotal}`, { align: "right" })
            .text(`Tax (${invoice.inv_tax_rate}%): INR ${invoice.inv_tax_amount}`, { align: "right" })
            .fontSize(14)
            .text(`Total: INR ${invoice.inv_total}`, { align: "right" });

        doc.moveDown(2);
        doc.fontSize(9).fillColor("gray").text(
            "This is a computer-generated invoice and does not require a signature.",
            { align: "center" }
        );

        doc.end();
    } catch (error) {
        logger.error("downloadInvoice failed", { error: error?.message });
        if (!res.headersSent) {
            return common.response(req, res, commonConfig.errorStatus, false, error?.message || "invoice download failed");
        }
    }
};

/** POST /admin/finance/invoice/void/:invoiceId */
exports.voidInvoice = async (req, res) => {
    try {
        const invoiceId = parseInt(req.params.invoiceId, 10);
        const { reason } = req.body;

        await models.tbl_invoices.update(
            { inv_status: "VOID", inv_void_reason: reason },
            { where: { inv_id: invoiceId } }
        );
        const updated = await models.tbl_invoices.findOne({ where: { inv_id: invoiceId }, raw: true });
        return common.response(req, res, commonConfig.successStatus, true, "success", updated);
    } catch (error) {
        logger.error("voidInvoice failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "invoice void failed");
    }
};

// ============================================================================
// A-05 — Reconciliation
// ============================================================================

/** POST /admin/finance/reconciliation/search */
exports.searchReconciliation = async (req, res) => {
    try {
        const { page, limit } = safePaging(req.body);
        const { status, dateFrom, dateTo } = req.body;

        const where = {
            ...(status ? { rr_status: status } : {}),
            ...buildDateRange(dateFrom, dateTo, "rr_created_at"),
        };

        let items = [], totalRecords = 0, summary = { matched: 0, variance: 0, pending: 0 };
        try {
            const result = await models.tbl_reconciliation_records.findAndCountAll({
                where, limit, offset: (page - 1) * limit,
                order: [["rr_created_at", "DESC"]], raw: true,
            });
            items = result.rows;
            totalRecords = result.count;
            summary = await models.tbl_reconciliation_records.summary(buildDateRange(dateFrom, dateTo, "rr_created_at"));
        } catch (e) {
            logger.warn("searchReconciliation DB error", { error: e?.message });
        }

        return common.response(req, res, commonConfig.successStatus, true, "success", {
            items, summary,
            totalRecords, currentPage: page,
            totalPages: Math.max(1, Math.ceil(totalRecords / limit)), limit,
        });
    } catch (error) {
        logger.error("searchReconciliation failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "reconciliation search failed");
    }
};

/** GET /admin/finance/reconciliation/:reconId */
exports.getReconciliation = async (req, res) => {
    try {
        const reconId = parseInt(req.params.reconId, 10);
        const record = await models.tbl_reconciliation_records.findOne({ where: { rr_id: reconId }, raw: true }).catch(() => null);
        if (!record) {
            return common.response(req, res, commonConfig.successStatus, true, "no record found", null);
        }

        // Sidecar — booking + first payment ledger entry + first payout
        let booking = null, payment = null, payout = null;
        try {
            booking = await models.tbl_bookings.findOne({ where: { book_pri_id: record.rr_booking_id }, raw: true });
            payment = await models.tbl_financial_ledger.findOne({
                where: { fl_booking_id: record.rr_booking_id, fl_transaction_type: "GUEST_PAYMENT" },
                raw: true,
            });
            payout = await models.tbl_payouts.findOne({ where: { po_host_id: booking?.book_host_id }, raw: true });
        } catch (e) { /* sidecar best-effort */ }

        return common.response(req, res, commonConfig.successStatus, true, "success", { ...record, booking, payment, payout });
    } catch (error) {
        logger.error("getReconciliation failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "reconciliation fetch failed");
    }
};

/** PUT /admin/finance/reconciliation/:reconId/resolve */
exports.resolveReconciliation = async (req, res) => {
    try {
        const reconId = parseInt(req.params.reconId, 10);
        const { notes, action } = req.body;
        const adminId = req.admin?.adminId || req.admin?.id || null;

        await models.tbl_reconciliation_records.update(
            {
                rr_status: "RESOLVED",
                rr_resolved_by: adminId,
                rr_resolved_at: new Date(),
                rr_action_taken: action,
                rr_notes: notes,
            },
            { where: { rr_id: reconId } }
        );
        const updated = await models.tbl_reconciliation_records.findOne({ where: { rr_id: reconId }, raw: true });
        return common.response(req, res, commonConfig.successStatus, true, "success", updated);
    } catch (error) {
        logger.error("resolveReconciliation failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "reconciliation resolve failed");
    }
};

/** POST /admin/finance/reconciliation/run — kicks off async reconciliation engine */
exports.runReconciliation = async (req, res) => {
    try {
        const { dateFrom, dateTo } = req.body;
        const jobId = `recon_${Date.now()}`;

        // Inline-async: iterate bookings in date window, upsert reconciliation row each.
        // Async = don't await; respond immediately.
        (async () => {
            try {
                const bookings = await models.tbl_bookings.findAll({
                    where: buildDateRange(dateFrom, dateTo, "book_added_at"),
                    raw: true,
                }).catch(() => []);

                for (const b of bookings) {
                    const expected = safeNumber(b.book_total_amt);
                    const paymentEntry = await models.tbl_financial_ledger.findOne({
                        where: { fl_booking_id: b.book_pri_id, fl_transaction_type: "GUEST_PAYMENT", fl_status: "COMPLETED" },
                        raw: true,
                    }).catch(() => null);
                    const payoutEntry = await models.tbl_financial_ledger.findOne({
                        where: { fl_booking_id: b.book_pri_id, fl_transaction_type: "PAYOUT", fl_status: "COMPLETED" },
                        raw: true,
                    }).catch(() => null);

                    const paymentAmount = paymentEntry ? safeNumber(paymentEntry.fl_amount) : 0;
                    const payoutAmount = payoutEntry ? safeNumber(payoutEntry.fl_amount) : 0;
                    const variance = +(expected - paymentAmount).toFixed(2);
                    const status = variance === 0 ? "MATCHED" : (paymentAmount === 0 ? "PENDING" : "VARIANCE");

                    await models.tbl_reconciliation_records.upsertForBooking(b.book_pri_id, {
                        rr_payment_amount: paymentAmount,
                        rr_expected_amount: expected,
                        rr_payout_amount: payoutAmount,
                        rr_variance: variance,
                        rr_status: status,
                    }).catch(() => null);
                }
                logger.info("reconciliation job done", { jobId, bookings: bookings.length });
            } catch (e) {
                logger.error("reconciliation job failed", { jobId, error: e?.message });
            }
        })();

        return common.response(req, res, commonConfig.successStatus, true, "success", { jobId, status: "PROCESSING", note: "Poll /admin/finance/reconciliation/search for updated rows." });
    } catch (error) {
        logger.error("runReconciliation failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "reconciliation run failed");
    }
};

// ============================================================================
// A-05 — Reports
// ============================================================================

const groupByExpr = (groupBy) => {
    switch (groupBy) {
        case "day":   return "DATE_FORMAT(fl_created_at, '%Y-%m-%d')";
        case "week":  return "YEARWEEK(fl_created_at, 1)";
        case "month":
        default:      return "DATE_FORMAT(fl_created_at, '%Y-%m')";
    }
};

/** POST /admin/finance/reports/revenue */
exports.reportRevenue = async (req, res) => {
    try {
        const { dateFrom, dateTo, groupBy = "month" } = req.body;
        const period = groupByExpr(groupBy);
        let items = [], totals = { revenue: 0, bookings: 0, avgValue: 0 };
        try {
            const rows = await models.sequelize.query(
                `SELECT ${period} AS period,
                        SUM(fl_amount) AS revenue,
                        COUNT(DISTINCT fl_booking_id) AS bookings
                 FROM tbl_financial_ledger
                 WHERE fl_transaction_type='GUEST_PAYMENT'
                   AND fl_status='COMPLETED'
                   AND fl_created_at BETWEEN ? AND ?
                 GROUP BY period
                 ORDER BY period ASC`,
                { replacements: [`${dateFrom} 00:00:00`, `${dateTo} 23:59:59`], type: models.sequelize.QueryTypes.SELECT }
            );
            let prev = null;
            items = rows.map(r => {
                const revenue = safeNumber(r.revenue);
                const bookings = safeNumber(r.bookings);
                const avgValue = bookings ? +(revenue / bookings).toFixed(2) : 0;
                const growth = prev !== null && prev > 0 ? +(((revenue - prev) / prev) * 100).toFixed(2) : null;
                prev = revenue;
                return { period: r.period, revenue, bookings, avgValue, growth };
            });
            totals = items.reduce((acc, r) => {
                acc.revenue += r.revenue;
                acc.bookings += r.bookings;
                return acc;
            }, { revenue: 0, bookings: 0, avgValue: 0 });
            totals.avgValue = totals.bookings ? +(totals.revenue / totals.bookings).toFixed(2) : 0;
        } catch (e) {
            logger.warn("reportRevenue DB error", { error: e?.message });
        }

        return common.response(req, res, commonConfig.successStatus, true, "success", { items, totals });
    } catch (error) {
        logger.error("reportRevenue failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "revenue report failed");
    }
};

/** POST /admin/finance/reports/commission */
exports.reportCommission = async (req, res) => {
    try {
        const { dateFrom, dateTo, groupBy = "month" } = req.body;
        const period = groupByExpr(groupBy);
        let items = [], totals = { commission: 0, bookings: 0 };
        try {
            const rows = await models.sequelize.query(
                `SELECT ${period} AS period,
                        SUM(fl_amount) AS commission,
                        COUNT(DISTINCT fl_booking_id) AS bookings
                 FROM tbl_financial_ledger
                 WHERE fl_transaction_type='PLATFORM_COMMISSION'
                   AND fl_status='COMPLETED'
                   AND fl_created_at BETWEEN ? AND ?
                 GROUP BY period ORDER BY period ASC`,
                { replacements: [`${dateFrom} 00:00:00`, `${dateTo} 23:59:59`], type: models.sequelize.QueryTypes.SELECT }
            );
            items = rows.map(r => ({ period: r.period, commission: safeNumber(r.commission), bookings: safeNumber(r.bookings) }));
            totals = items.reduce((acc, r) => ({ commission: acc.commission + r.commission, bookings: acc.bookings + r.bookings }), { commission: 0, bookings: 0 });
        } catch (e) {
            logger.warn("reportCommission DB error", { error: e?.message });
        }

        return common.response(req, res, commonConfig.successStatus, true, "success", { items, totals });
    } catch (error) {
        logger.error("reportCommission failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "commission report failed");
    }
};

/** POST /admin/finance/reports/tax */
exports.reportTax = async (req, res) => {
    try {
        const { dateFrom, dateTo } = req.body;
        let items = [], totals = { taxCollected: 0, taxPayable: 0 };
        try {
            const rows = await models.sequelize.query(
                `SELECT DATE_FORMAT(fl_created_at, '%Y-%m') AS period,
                        SUM(fl_amount) AS tax_collected
                 FROM tbl_financial_ledger
                 WHERE fl_transaction_type='TAX_COLLECTED'
                   AND fl_status='COMPLETED'
                   AND fl_created_at BETWEEN ? AND ?
                 GROUP BY period ORDER BY period ASC`,
                { replacements: [`${dateFrom} 00:00:00`, `${dateTo} 23:59:59`], type: models.sequelize.QueryTypes.SELECT }
            );
            items = rows.map(r => ({
                period: r.period,
                taxCollected: safeNumber(r.tax_collected),
                taxPayable: safeNumber(r.tax_collected), // for sprint: payable == collected (no input tax credit)
            }));
            totals = items.reduce((acc, r) => ({
                taxCollected: acc.taxCollected + r.taxCollected,
                taxPayable: acc.taxPayable + r.taxPayable,
            }), { taxCollected: 0, taxPayable: 0 });
        } catch (e) {
            logger.warn("reportTax DB error", { error: e?.message });
        }

        return common.response(req, res, commonConfig.successStatus, true, "success", { items, totals });
    } catch (error) {
        logger.error("reportTax failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "tax report failed");
    }
};

/** POST /admin/finance/reports/cashflow */
exports.reportCashflow = async (req, res) => {
    try {
        const { dateFrom, dateTo, groupBy = "month" } = req.body;
        const period = groupByExpr(groupBy);
        let items = [], totals = { inflow: 0, outflow: 0, net: 0 };
        try {
            const rows = await models.sequelize.query(
                `SELECT ${period} AS period,
                        SUM(CASE WHEN fl_entry_type='CREDIT' THEN fl_amount ELSE 0 END) AS inflow,
                        SUM(CASE WHEN fl_entry_type='DEBIT'  THEN fl_amount ELSE 0 END) AS outflow
                 FROM tbl_financial_ledger
                 WHERE fl_status='COMPLETED'
                   AND fl_created_at BETWEEN ? AND ?
                 GROUP BY period ORDER BY period ASC`,
                { replacements: [`${dateFrom} 00:00:00`, `${dateTo} 23:59:59`], type: models.sequelize.QueryTypes.SELECT }
            );
            items = rows.map(r => {
                const inflow = safeNumber(r.inflow);
                const outflow = safeNumber(r.outflow);
                return { period: r.period, inflow, outflow, net: +(inflow - outflow).toFixed(2) };
            });
            totals = items.reduce((acc, r) => ({
                inflow: acc.inflow + r.inflow,
                outflow: acc.outflow + r.outflow,
                net: acc.net + r.net,
            }), { inflow: 0, outflow: 0, net: 0 });
        } catch (e) {
            logger.warn("reportCashflow DB error", { error: e?.message });
        }

        return common.response(req, res, commonConfig.successStatus, true, "success", { items, totals });
    } catch (error) {
        logger.error("reportCashflow failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "cashflow report failed");
    }
};

/** POST /admin/finance/reports/export — CSV stream */
exports.reportExport = async (req, res) => {
    try {
        const { reportType, dateFrom, dateTo } = req.body;
        // Reuse the report handlers by calling them programmatically and converting to CSV
        const fakeRes = {
            _captured: null,
            status() { return this; },
            json(payload) { this._captured = payload; return this; },
        };
        const fakeReq = { body: { dateFrom, dateTo, groupBy: "month" }, params: {}, query: {} };

        const handlerMap = {
            revenue: exports.reportRevenue,
            commission: exports.reportCommission,
            tax: exports.reportTax,
            cashflow: exports.reportCashflow,
        };
        const handler = handlerMap[reportType];
        if (!handler) {
            return common.response(req, res, commonConfig.errorStatus, false, "unknown reportType");
        }

        await handler(fakeReq, fakeRes);
        const data = fakeRes._captured?.data || { items: [], totals: {} };

        const items = data.items || [];
        const headerKeys = items.length ? Object.keys(items[0]) : ["period"];
        const csvHeader = headerKeys.join(",");
        const csvBody = items.map(r => headerKeys.map(k => {
            const v = r[k];
            if (v === null || v === undefined) return "";
            const s = String(v).replace(/"/g, '""');
            return /[,"\n]/.test(s) ? `"${s}"` : s;
        }).join(",")).join("\n");

        const csv = "﻿" + csvHeader + "\n" + csvBody;
        const filename = `${reportType}_${dateFrom}_${dateTo}.csv`;

        res.setHeader("Content-Type", "text/csv; charset=utf-8");
        res.setHeader("Content-Disposition", `attachment; filename="${filename}"`);
        return res.status(200).send(csv);
    } catch (error) {
        logger.error("reportExport failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "report export failed");
    }
};
