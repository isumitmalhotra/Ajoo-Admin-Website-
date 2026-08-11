'use strict';
/**
 * Controller: hostV2 (new HMS host portal endpoints under /host/*)
 * Sprint: Full Delivery 2026-06-09..18 (A-07)
 *
 * Coexists with existing host.controller.js. Old paths kept for back-compat.
 * Day 10 cleanup deletes old paths.
 */
const { Op } = require("sequelize");
const PDFDocument = require("pdfkit");
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

const hostIdFromReq = (req) => req.user?.userId || req.user?.user_id || null;

// ============================================================================
// Dashboard
// ============================================================================

/** GET /host/dashboard/summary */
exports.dashboardSummary = async (req, res) => {
    try {
        const hostId = hostIdFromReq(req);
        if (!hostId) return common.response(req, res, 401, false, "host id missing from token");

        const monthStart = new Date(); monthStart.setDate(1); monthStart.setHours(0, 0, 0, 0);

        const [monthEarnings, activeListings, upcomingBookings, recentActivity] = await Promise.all([
            // earnings — sum host_earning ledger entries this month
            models.tbl_financial_ledger.sum("fl_amount", {
                where: { fl_host_id: hostId, fl_transaction_type: "HOST_EARNING", fl_status: "COMPLETED", fl_created_at: { [Op.gte]: monthStart } },
            }).then(v => safeNumber(v)).catch(() => 0),
            // active listings
            models.tbl_properties.count({ where: { property_host_id: hostId } }).catch(() => 0),
            // upcoming bookings — confirmed bookings with check_in > now (simplified)
            models.tbl_bookings.count({ where: { book_host_id: hostId, book_is_paid: 1 } }).catch(() => 0),
            // recent activity — last 5 ledger entries
            models.tbl_financial_ledger.findAll({
                where: { fl_host_id: hostId },
                limit: 5,
                order: [["fl_created_at", "DESC"]],
                raw: true,
            }).catch(() => []),
        ]);

        // Occupancy rate placeholder — would need bookings vs availability calc
        const occupancyRate = 0;

        return common.response(req, res, commonConfig.successStatus, true, "success", {
            monthEarnings,
            activeListings,
            upcomingBookings,
            occupancyRate,
            recentActivity: recentActivity.map(r => ({
                id: `L-${r.fl_id}`,
                type: r.fl_transaction_type?.toLowerCase() || "ledger",
                title: r.fl_description || `${r.fl_transaction_type} ${r.fl_amount}`,
                when: r.fl_created_at,
                status: r.fl_status,
            })),
        });
    } catch (error) {
        logger.error("host dashboardSummary failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "dashboard failed");
    }
};

// ============================================================================
// Bookings (INT-04 resolution — new path alongside /host/booking-history)
// ============================================================================

/** POST /host/bookings/search */
exports.bookingsSearch = async (req, res) => {
    try {
        const hostId = hostIdFromReq(req);
        const { page, limit } = safePaging(req.body);
        const { search, status, dateFrom, dateTo } = req.body;

        const where = {
            book_host_id: hostId,
            ...(status ? { book_status: status } : {}),
            ...buildDateRange(dateFrom, dateTo, "book_added_at"),
        };

        let items = [], totalRecords = 0;
        try {
            const result = await models.tbl_bookings.findAndCountAll({
                where, limit, offset: (page - 1) * limit,
                order: [["book_added_at", "DESC"]], raw: true,
            });
            items = result.rows;
            totalRecords = result.count;
        } catch (e) {
            logger.warn("host bookings.search DB error", { error: e?.message });
        }

        return common.response(req, res, commonConfig.successStatus, true, "success", {
            items, totalRecords, currentPage: page,
            totalPages: Math.max(1, Math.ceil(totalRecords / limit)), limit,
        });
    } catch (error) {
        logger.error("host bookingsSearch failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "bookings search failed");
    }
};

/** GET /host/bookings/detail/:bookingId */
exports.bookingDetail = async (req, res) => {
    try {
        const hostId = hostIdFromReq(req);
        const bookingId = parseInt(req.params.bookingId, 10);

        const booking = await models.tbl_bookings.findOne({
            where: { book_pri_id: bookingId, book_host_id: hostId },
            raw: true,
        }).catch(() => null);
        if (!booking) return common.response(req, res, commonConfig.successStatus, true, "no record found", null);

        // Sidecar — guest snippet (email comes from tbl_user_creds), property snippet
        const [guestRows, property] = await Promise.all([
            models.sequelize.query(
                `SELECT u.user_id, u.user_fullName, u.user_pnumber, c.cred_user_email
                 FROM tbl_users u LEFT JOIN tbl_user_creds c ON c.cred_user_id = u.user_id
                 WHERE u.user_id = :id LIMIT 1`,
                { replacements: { id: booking.book_user_id }, type: models.sequelize.QueryTypes.SELECT }
            ).catch(() => []),
            models.tbl_properties.findOne({ where: { property_id: booking.book_prop_id }, raw: true }).catch(() => null),
        ]);
        const guest = (guestRows && guestRows[0]) || null;

        return common.response(req, res, commonConfig.successStatus, true, "success", { booking, guest, property });
    } catch (error) {
        logger.error("host bookingDetail failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "booking detail failed");
    }
};

// ============================================================================
// Earnings
// ============================================================================

/** GET /host/earnings/summary */
exports.earningsSummary = async (req, res) => {
    try {
        const hostId = hostIdFromReq(req);
        const now = new Date();
        const thisMonthStart = new Date(now.getFullYear(), now.getMonth(), 1);
        const lastMonthStart = new Date(now.getFullYear(), now.getMonth() - 1, 1);
        const lastMonthEnd = new Date(now.getFullYear(), now.getMonth(), 0, 23, 59, 59);
        const ytdStart = new Date(now.getFullYear(), 0, 1);

        const baseWhere = { fl_host_id: hostId, fl_transaction_type: "HOST_EARNING", fl_status: "COMPLETED" };

        const [thisMonth, lastMonth, ytd, pendingPayout] = await Promise.all([
            models.tbl_financial_ledger.sum("fl_amount", { where: { ...baseWhere, fl_created_at: { [Op.gte]: thisMonthStart } } }).then(safeNumber).catch(() => 0),
            models.tbl_financial_ledger.sum("fl_amount", { where: { ...baseWhere, fl_created_at: { [Op.between]: [lastMonthStart, lastMonthEnd] } } }).then(safeNumber).catch(() => 0),
            models.tbl_financial_ledger.sum("fl_amount", { where: { ...baseWhere, fl_created_at: { [Op.gte]: ytdStart } } }).then(safeNumber).catch(() => 0),
            models.tbl_payouts.sum("po_amount", { where: { po_host_id: hostId, po_status: ["QUEUED", "PROCESSING"] } }).then(safeNumber).catch(() => 0),
        ]);

        // Recent earnings — last 5
        let recentEarnings = [];
        try {
            const rows = await models.tbl_financial_ledger.findAll({
                where: baseWhere,
                limit: 5,
                order: [["fl_created_at", "DESC"]],
                raw: true,
            });
            recentEarnings = rows.map(r => ({ booking_id: r.fl_booking_id, amount: safeNumber(r.fl_amount), date: r.fl_created_at }));
        } catch (e) { /* noop */ }

        // Monthly trend — last 12 months
        let trend = [];
        try {
            const rows = await models.sequelize.query(
                `SELECT DATE_FORMAT(fl_created_at, '%b') AS month,
                        SUM(fl_amount) AS earnings
                 FROM tbl_financial_ledger
                 WHERE fl_host_id=? AND fl_transaction_type='HOST_EARNING' AND fl_status='COMPLETED'
                   AND fl_created_at >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
                 GROUP BY DATE_FORMAT(fl_created_at, '%Y-%m'), month
                 ORDER BY DATE_FORMAT(fl_created_at, '%Y-%m') ASC`,
                { replacements: [hostId], type: models.sequelize.QueryTypes.SELECT }
            );
            trend = rows.map(r => ({ month: r.month, earnings: safeNumber(r.earnings) }));
        } catch (e) { /* noop */ }

        // Next payout date — from schedule
        let nextPayoutDate = null;
        try {
            const sched = await models.tbl_payout_schedules.findOne({ where: { ps_host_id: hostId, ps_is_active: 1 }, raw: true });
            if (sched) nextPayoutDate = sched.ps_next_payout_date;
        } catch (e) { /* noop */ }

        return common.response(req, res, commonConfig.successStatus, true, "success", {
            thisMonth, lastMonth, ytd, pendingPayout, nextPayoutDate,
            trend, commissionRate: 15, recentEarnings,
        });
    } catch (error) {
        logger.error("host earningsSummary failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "earnings summary failed");
    }
};

/** GET /host/payout/history (INT-06 — new path alongside /payout/request/list) */
exports.payoutHistory = async (req, res) => {
    try {
        const hostId = hostIdFromReq(req);
        const { page, limit } = safePaging(req.query);

        let items = [], totalRecords = 0;
        try {
            const result = await models.tbl_payouts.findAndCountAll({
                where: { po_host_id: hostId },
                limit, offset: (page - 1) * limit,
                order: [["po_created_at", "DESC"]], raw: true,
            });
            items = result.rows;
            totalRecords = result.count;
        } catch (e) {
            logger.warn("host payoutHistory DB error", { error: e?.message });
        }

        return common.response(req, res, commonConfig.successStatus, true, "success", {
            items, totalRecords, currentPage: page,
            totalPages: Math.max(1, Math.ceil(totalRecords / limit)), limit,
        });
    } catch (error) {
        logger.error("host payoutHistory failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "payout history failed");
    }
};

// ============================================================================
// Profile
// ============================================================================

/** GET /host/profile/get */
exports.profileGet = async (req, res) => {
    try {
        const hostId = hostIdFromReq(req);
        // Real schema: profile lives in tbl_users; email lives in tbl_user_creds.
        // No silent .catch() here — a query error should surface as a real 500.
        const rows = await models.sequelize.query(
            `SELECT u.user_id, u.user_fullName, u.user_pnumber, u.user_address, u.user_city,
                    u.added_at, u.verification_status, u.verified_at, c.cred_user_email
             FROM tbl_users u LEFT JOIN tbl_user_creds c ON c.cred_user_id = u.user_id
             WHERE u.user_id = :id LIMIT 1`,
            { replacements: { id: hostId }, type: models.sequelize.QueryTypes.SELECT }
        );
        const user = rows && rows[0];
        if (!user) return common.response(req, res, commonConfig.notFoundStatus, false, "user not found");

        return common.response(req, res, commonConfig.successStatus, true, "success", {
            userId: user.user_id,
            fullName: user.user_fullName,
            email: user.cred_user_email || null,
            phone: user.user_pnumber,
            address: user.user_address,
            city: user.user_city,
            state: null,      // not stored on tbl_users
            country: null,    // not stored on tbl_users
            avatarUrl: null,  // profile image not on tbl_users
            joinedAt: user.added_at || null,
            verificationStatus: user.verification_status || "unverified",
            verifiedAt: user.verified_at || null,
        });
    } catch (error) {
        logger.error("host profileGet failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "profile fetch failed");
    }
};

/** PUT /host/profile/update */
exports.profileUpdate = async (req, res) => {
    try {
        const hostId = hostIdFromReq(req);
        const { fullName, email, phone, address, city } = req.body;
        // Note: state/country are not columns on tbl_users — ignored. email lives in tbl_user_creds.

        const payload = {};
        if (fullName) payload.user_fullName = fullName;
        if (phone) payload.user_pnumber = phone;
        if (address) payload.user_address = address;
        if (city) payload.user_city = city;

        if (!fullName && !phone && !address && !city && !email) {
            return common.response(req, res, commonConfig.errorStatus, false, "no updatable fields supplied");
        }

        if (Object.keys(payload).length) {
            await models.tbl_user.update(payload, { where: { user_id: hostId } });
        }
        if (email) {
            await models.sequelize.query(
                `UPDATE tbl_user_creds SET cred_user_email = :email WHERE cred_user_id = :id`,
                { replacements: { email, id: hostId } }
            ).catch((e) => logger.warn("profileUpdate email update failed", { error: e?.message }));
        }
        return exports.profileGet(req, res);
    } catch (error) {
        logger.error("host profileUpdate failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "profile update failed");
    }
};

// ============================================================================
// Payout Account (INT-05 — new path alongside /payout/account/*)
// ============================================================================

const maskAccountNumber = (n) => n ? `XXXX${String(n).slice(-4)}` : null;

/** GET /host/payout-account/get */
exports.payoutAccountGet = async (req, res) => {
    try {
        const hostId = hostIdFromReq(req);
        const acc = await models.tbl_host_acc_details.findOne({
            where: { had_host_id: hostId, had_isDelete: { [Op.or]: [0, null] } },
            raw: true,
        }).catch(() => null);

        if (!acc) {
            return common.response(req, res, commonConfig.successStatus, true, "no record found", null);
        }

        return common.response(req, res, commonConfig.successStatus, true, "success", {
            accountNumber: maskAccountNumber(acc.had_acc_no),
            ifsc: acc.had_ifsc,
            accountHolderName: null, // not stored in existing schema; would need new column
            upiId: null,
            isVerified: !!acc.had_isVerified,
        });
    } catch (error) {
        logger.error("host payoutAccountGet failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "payout account fetch failed");
    }
};

/** PUT /host/payout-account/update */
exports.payoutAccountUpdate = async (req, res) => {
    try {
        const hostId = hostIdFromReq(req);
        const { accountNumber, confirmAccountNumber, ifsc, upiId } = req.body;

        if (accountNumber && confirmAccountNumber && accountNumber !== confirmAccountNumber) {
            return common.response(req, res, commonConfig.errorStatus, false, "account numbers do not match");
        }
        if (!accountNumber && !upiId) {
            return common.response(req, res, commonConfig.errorStatus, false, "either accountNumber or upiId is required");
        }

        const existing = await models.tbl_host_acc_details.findOne({
            where: { had_host_id: hostId, had_isDelete: { [Op.or]: [0, null] } },
        }).catch(() => null);

        const payload = {
            had_host_id: hostId,
            had_acc_no: accountNumber || null,
            had_ifsc: ifsc || null,
            had_isVerified: 0,
            had_isDelete: 0,
            had_status: 1,
        };

        if (existing) {
            await existing.update(payload);
        } else {
            await models.tbl_host_acc_details.create(payload);
        }

        return exports.payoutAccountGet(req, res);
    } catch (error) {
        logger.error("host payoutAccountUpdate failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "payout account update failed");
    }
};

// ============================================================================
// Statements (derived from ledger + payouts; no separate table)
// ============================================================================

/** POST /host/statements/search */
exports.statementsSearch = async (req, res) => {
    try {
        const hostId = hostIdFromReq(req);
        const { page, limit } = safePaging(req.body);
        const { year, month } = req.body;

        // Group ledger + payouts by month
        let items = [], totalRecords = 0;
        try {
            const yearFilter = year ? `AND YEAR(fl_created_at)=${parseInt(year, 10)}` : "";
            const monthFilter = month ? `AND MONTH(fl_created_at)=${parseInt(month, 10)}` : "";

            const rows = await models.sequelize.query(
                `SELECT DATE_FORMAT(fl_created_at, '%Y-%m') AS period,
                        SUM(CASE WHEN fl_transaction_type='HOST_EARNING'  THEN fl_amount ELSE 0 END) AS totalEarnings,
                        SUM(CASE WHEN fl_transaction_type='PLATFORM_COMMISSION' THEN fl_amount ELSE 0 END) AS totalCommission,
                        SUM(CASE WHEN fl_transaction_type='PAYOUT' THEN fl_amount ELSE 0 END) AS totalPayouts,
                        COUNT(DISTINCT fl_booking_id) AS invoiceCount,
                        MAX(fl_created_at) AS generatedAt
                 FROM tbl_financial_ledger
                 WHERE fl_host_id=? AND fl_status='COMPLETED' ${yearFilter} ${monthFilter}
                 GROUP BY period
                 ORDER BY period DESC
                 LIMIT ${limit} OFFSET ${(page - 1) * limit}`,
                { replacements: [hostId], type: models.sequelize.QueryTypes.SELECT }
            );
            items = rows.map((r, i) => ({
                statement_id: r.period,    // YYYY-MM is the statement key
                period: r.period,
                totalEarnings: safeNumber(r.totalEarnings),
                totalCommission: safeNumber(r.totalCommission),
                totalPayouts: safeNumber(r.totalPayouts),
                invoiceCount: safeNumber(r.invoiceCount),
                generatedAt: r.generatedAt,
            }));

            const countRows = await models.sequelize.query(
                `SELECT COUNT(DISTINCT DATE_FORMAT(fl_created_at, '%Y-%m')) AS total
                 FROM tbl_financial_ledger
                 WHERE fl_host_id=? AND fl_status='COMPLETED'`,
                { replacements: [hostId], type: models.sequelize.QueryTypes.SELECT }
            );
            totalRecords = safeNumber(countRows?.[0]?.total);
        } catch (e) {
            logger.warn("host statementsSearch DB error", { error: e?.message });
        }

        return common.response(req, res, commonConfig.successStatus, true, "success", {
            items, totalRecords, currentPage: page,
            totalPages: Math.max(1, Math.ceil(totalRecords / limit)), limit,
        });
    } catch (error) {
        logger.error("host statementsSearch failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "statements search failed");
    }
};

/** GET /host/statements/download/:statementId — PDF stream */
exports.statementsDownload = async (req, res) => {
    try {
        const hostId = hostIdFromReq(req);
        const statementId = req.params.statementId; // expected YYYY-MM

        const match = /^(\d{4})-(\d{2})$/.exec(statementId);
        if (!match) {
            return common.response(req, res, commonConfig.errorStatus, false, "statementId must be YYYY-MM");
        }
        const [, year, month] = match;

        // Aggregate the statement
        const rows = await models.sequelize.query(
            `SELECT fl_transaction_type, fl_amount, fl_description, fl_created_at, fl_booking_id
             FROM tbl_financial_ledger
             WHERE fl_host_id=? AND fl_status='COMPLETED'
               AND YEAR(fl_created_at)=? AND MONTH(fl_created_at)=?
             ORDER BY fl_created_at ASC`,
            { replacements: [hostId, year, month], type: models.sequelize.QueryTypes.SELECT }
        ).catch(() => []);

        const filename = `statement_${statementId}.pdf`;
        res.setHeader("Content-Type", "application/pdf");
        res.setHeader("Content-Disposition", `attachment; filename="${filename}"`);

        const doc = new PDFDocument({ size: "A4", margin: 50 });
        doc.pipe(res);
        doc.fontSize(20).text("AAJOO Homes", { align: "center" });
        doc.fontSize(10).text(`Host Statement — ${statementId}`, { align: "center" });
        doc.moveDown();
        doc.fontSize(11).text(`Host ID: ${hostId}`);
        doc.moveDown();

        let totalEarn = 0, totalCom = 0, totalPay = 0;
        rows.forEach(r => {
            doc.fontSize(10).text(
                `${new Date(r.fl_created_at).toISOString().slice(0, 10)} | ${r.fl_transaction_type.padEnd(20)} | ${String(r.fl_amount).padStart(10)} | ${(r.fl_description || "").slice(0, 40)}`
            );
            if (r.fl_transaction_type === "HOST_EARNING") totalEarn += safeNumber(r.fl_amount);
            if (r.fl_transaction_type === "PLATFORM_COMMISSION") totalCom += safeNumber(r.fl_amount);
            if (r.fl_transaction_type === "PAYOUT") totalPay += safeNumber(r.fl_amount);
        });

        doc.moveDown();
        doc.fontSize(12).text(`Total Earnings: INR ${totalEarn}`, { align: "right" });
        doc.text(`Total Commission: INR ${totalCom}`, { align: "right" });
        doc.text(`Total Payouts: INR ${totalPay}`, { align: "right" });
        doc.moveDown(2);
        doc.fontSize(9).fillColor("gray").text("Computer-generated statement.", { align: "center" });
        doc.end();
    } catch (error) {
        logger.error("host statementsDownload failed", { error: error?.message });
        if (!res.headersSent) {
            return common.response(req, res, commonConfig.errorStatus, false, error?.message || "statement download failed");
        }
    }
};

// ============================================================================
// Support tickets
// ============================================================================

/** POST /host/support/tickets/search */
exports.ticketSearch = async (req, res) => {
    try {
        const hostId = hostIdFromReq(req);
        const { page, limit } = safePaging(req.body);
        const { status, category, dateFrom, dateTo } = req.body;

        const where = {
            st_host_id: hostId,
            ...(status ? { st_status: status } : {}),
            ...(category ? { st_category: category } : {}),
            ...buildDateRange(dateFrom, dateTo, "st_created_at"),
        };

        let items = [], totalRecords = 0;
        try {
            const result = await models.tbl_support_tickets.findAndCountAll({
                where, limit, offset: (page - 1) * limit,
                order: [["st_created_at", "DESC"]], raw: true,
            });
            items = result.rows;
            totalRecords = result.count;
        } catch (e) {
            logger.warn("host ticketSearch DB error", { error: e?.message });
        }

        return common.response(req, res, commonConfig.successStatus, true, "success", {
            items, totalRecords, currentPage: page,
            totalPages: Math.max(1, Math.ceil(totalRecords / limit)), limit,
        });
    } catch (error) {
        logger.error("host ticketSearch failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "ticket search failed");
    }
};

/** POST /host/support/tickets/create */
exports.ticketCreate = async (req, res) => {
    try {
        const hostId = hostIdFromReq(req);
        const { subject, category, message } = req.body;

        const ticket = await models.tbl_support_tickets.create({
            st_host_id: hostId,
            st_subject: subject,
            st_category: category,
            st_status: "OPEN",
            st_unread_count: 0,
            st_last_reply_at: new Date(),
        });

        await models.tbl_support_ticket_messages.create({
            stm_ticket_id: ticket.st_id,
            stm_sender_role: "HOST",
            stm_sender_id: hostId,
            stm_message: message,
            stm_is_read: 1,
        });

        return common.response(req, res, commonConfig.successStatus, true, "success", { ticket_id: ticket.st_id, status: "OPEN" });
    } catch (error) {
        logger.error("host ticketCreate failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "ticket create failed");
    }
};

/** POST /host/support/tickets/reply */
exports.ticketReply = async (req, res) => {
    try {
        const hostId = hostIdFromReq(req);
        const { ticketId, message } = req.body;

        // Verify ownership
        const ticket = await models.tbl_support_tickets.findOne({ where: { st_id: ticketId, st_host_id: hostId } }).catch(() => null);
        if (!ticket) return common.response(req, res, commonConfig.notFoundStatus, false, "ticket not found");

        const msg = await models.tbl_support_ticket_messages.create({
            stm_ticket_id: ticketId,
            stm_sender_role: "HOST",
            stm_sender_id: hostId,
            stm_message: message,
            stm_is_read: 1,
        });

        await ticket.update({ st_last_reply_at: new Date(), st_status: "PENDING" });

        return common.response(req, res, commonConfig.successStatus, true, "success", {
            messageId: msg.stm_id, ticketId, at: msg.stm_created_at,
        });
    } catch (error) {
        logger.error("host ticketReply failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "ticket reply failed");
    }
};

// ============================================================================
// Performance (single endpoint, 4 dimensions)
// ============================================================================

/** GET /host/performance/summary */
exports.performanceSummary = async (req, res) => {
    try {
        const hostId = hostIdFromReq(req);
        const now = new Date();
        const ninetyDaysAgo = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);
        const oneEightyDaysAgo = new Date(now.getTime() - 180 * 24 * 60 * 60 * 1000);

        // Revenue (host earnings) — current vs prior 90 days
        const [revCurr, revPrev] = await Promise.all([
            models.tbl_financial_ledger.sum("fl_amount", { where: { fl_host_id: hostId, fl_transaction_type: "HOST_EARNING", fl_status: "COMPLETED", fl_created_at: { [Op.gte]: ninetyDaysAgo } } }).then(safeNumber).catch(() => 0),
            models.tbl_financial_ledger.sum("fl_amount", { where: { fl_host_id: hostId, fl_transaction_type: "HOST_EARNING", fl_status: "COMPLETED", fl_created_at: { [Op.between]: [oneEightyDaysAgo, ninetyDaysAgo] } } }).then(safeNumber).catch(() => 0),
        ]);

        // Cancellations — bookings with status cancelled (book_status === statusBookingCancelled = 2)
        const [cxlCurr, cxlPrev] = await Promise.all([
            models.tbl_bookings.count({ where: { book_host_id: hostId, book_status: commonConfig.statusBookingCancelled, book_added_at: { [Op.gte]: ninetyDaysAgo } } }).catch(() => 0),
            models.tbl_bookings.count({ where: { book_host_id: hostId, book_status: commonConfig.statusBookingCancelled, book_added_at: { [Op.between]: [oneEightyDaysAgo, ninetyDaysAgo] } } }).catch(() => 0),
        ]);

        // Bookings count for occupancy proxy
        const [bookCurr, bookPrev] = await Promise.all([
            models.tbl_bookings.count({ where: { book_host_id: hostId, book_added_at: { [Op.gte]: ninetyDaysAgo } } }).catch(() => 0),
            models.tbl_bookings.count({ where: { book_host_id: hostId, book_added_at: { [Op.between]: [oneEightyDaysAgo, ninetyDaysAgo] } } }).catch(() => 0),
        ]);
        const propertyCount = await models.tbl_properties.count({ where: { property_host_id: hostId } }).catch(() => 1) || 1;
        const occupancyCurr = Math.min(100, Math.round((bookCurr / (propertyCount * 90)) * 100));
        const occupancyPrev = Math.min(100, Math.round((bookPrev / (propertyCount * 90)) * 100));

        // Ratings — average from reviews if available
        let ratingsCurr = 0, ratingsPrev = 0;
        try {
            const r1 = await models.sequelize.query(
                `SELECT AVG(br_rating) AS avg_rating FROM tbl_reviews r
                 JOIN tbl_bookings b ON r.br_book_id = b.book_id
                 WHERE b.book_host_id=? AND r.br_created_at >= ?`,
                { replacements: [hostId, ninetyDaysAgo], type: models.sequelize.QueryTypes.SELECT }
            );
            ratingsCurr = safeNumber(r1?.[0]?.avg_rating);
        } catch (e) { /* table maybe missing review columns; default to 0 */ }

        return common.response(req, res, commonConfig.successStatus, true, "success", {
            occupancy:     { current: occupancyCurr, previous: occupancyPrev, trend: [] },
            revenue:       { current: revCurr, previous: revPrev, trend: [] },
            cancellations: { current: cxlCurr, previous: cxlPrev, trend: [] },
            ratings:       { current: ratingsCurr, previous: ratingsPrev, trend: [] },
        });
    } catch (error) {
        logger.error("host performanceSummary failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "performance summary failed");
    }
};

// ============================================================================
// Onboarding (INT-10 — Become a Host)
// ============================================================================

/** POST /host/onboarding/submit */
exports.onboardingSubmit = async (req, res) => {
    try {
        const userId = req.user?.userId || req.user?.user_id || null;
        if (!userId) return common.response(req, res, 401, false, "auth required");

        const { propertyType, city, state, country, hostingExperience, contactName, contactPhone, message } = req.body;

        const app = await models.tbl_host_onboarding_apps.create({
            hoa_user_id: userId,
            hoa_property_type: propertyType,
            hoa_city: city,
            hoa_state: state,
            hoa_country: country,
            hoa_hosting_experience: hostingExperience,
            hoa_contact_name: contactName,
            hoa_contact_phone: contactPhone,
            hoa_message: message || null,
            hoa_status: "RECEIVED",
        });

        return common.response(req, res, commonConfig.successStatus, true, "success", {
            applicationId: app.hoa_id,
            status: "RECEIVED",
            nextStep: "kyc",
        });
    } catch (error) {
        logger.error("host onboardingSubmit failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "onboarding submit failed");
    }
};
