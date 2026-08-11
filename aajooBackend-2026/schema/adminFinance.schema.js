'use strict';
/**
 * Yup schemas for /admin/finance/* endpoints.
 * Sprint: Full Delivery 2026-06-09..18 (A-03, A-04, A-05).
 *
 * REMINDER (the footgun): validation middleware uses `stripUnknown: true`.
 * Every field the controller reads MUST be declared here, even optional ones.
 * See API_CONTRACT_HANDOFF.md § 0.3.
 */
const yup = require("yup");

const TRANSACTION_TYPES = [
    "GUEST_PAYMENT",
    "HOST_EARNING",
    "PLATFORM_COMMISSION",
    "TAX_COLLECTED",
    "REFUND",
    "PAYOUT",
    "ADJUSTMENT",
];

const LEDGER_STATUSES = ["COMPLETED", "PENDING", "FAILED", "REVERSED"];
const PAYOUT_STATUSES = ["QUEUED", "PROCESSING", "COMPLETED", "FAILED"];

// GET /admin/finance/dashboard — accepts optional query window
exports.dashboardGet = yup.object({
    from: yup.string().optional().nullable(),
    to: yup.string().optional().nullable(),
});

// POST /admin/finance/ledger/search
exports.ledgerSearch = yup.object({
    page: yup.number().integer().min(1).optional().default(1),
    limit: yup.number().integer().min(1).max(100).optional().default(20),
    search: yup.string().optional().nullable(),
    hostId: yup.number().integer().optional().nullable(),
    userId: yup.number().integer().optional().nullable(),
    transactionType: yup.string().oneOf([...TRANSACTION_TYPES, null]).optional().nullable(),
    dateFrom: yup.string().optional().nullable(),
    dateTo: yup.string().optional().nullable(),
    status: yup.string().oneOf([...LEDGER_STATUSES, null]).optional().nullable(),
});

// POST /admin/finance/payout/search
exports.payoutSearch = yup.object({
    page: yup.number().integer().min(1).optional().default(1),
    limit: yup.number().integer().min(1).max(100).optional().default(20),
    hostId: yup.number().integer().optional().nullable(),
    status: yup.string().oneOf([...PAYOUT_STATUSES, null]).optional().nullable(),
    dateFrom: yup.string().optional().nullable(),
    dateTo: yup.string().optional().nullable(),
});

// --- A-04 — Ledger CRUD ---

// GET /admin/finance/ledger/:ledgerId
exports.ledgerGet = yup.object({
    ledgerId: yup.number().integer().positive().required("ledgerId is required"),
});

// POST /admin/finance/ledger/host/:hostId
exports.ledgerByHost = yup.object({
    hostId: yup.number().integer().positive().required("hostId is required"),
    page: yup.number().integer().min(1).optional().default(1),
    limit: yup.number().integer().min(1).max(100).optional().default(20),
    dateFrom: yup.string().optional().nullable(),
    dateTo: yup.string().optional().nullable(),
});

// POST /admin/finance/ledger/user/:userId
exports.ledgerByUser = yup.object({
    userId: yup.number().integer().positive().required("userId is required"),
    page: yup.number().integer().min(1).optional().default(1),
    limit: yup.number().integer().min(1).max(100).optional().default(20),
    dateFrom: yup.string().optional().nullable(),
    dateTo: yup.string().optional().nullable(),
});

// POST /admin/finance/ledger/export
exports.ledgerExport = yup.object({
    hostId: yup.number().integer().optional().nullable(),
    userId: yup.number().integer().optional().nullable(),
    dateFrom: yup.string().optional().nullable(),
    dateTo: yup.string().optional().nullable(),
    format: yup.string().oneOf(["csv", "excel"]).optional().default("csv"),
});

// --- A-04 — Payout CRUD ---

// GET /admin/finance/payout/:payoutId
exports.payoutGet = yup.object({
    payoutId: yup.number().integer().positive().required("payoutId is required"),
});

// POST /admin/finance/payout/initiate
exports.payoutInitiate = yup.object({
    hostId: yup.number().integer().positive().required("hostId is required"),
    amount: yup.number().positive().optional().nullable(),
    note: yup.string().max(500).optional().nullable(),
});

// PUT /admin/finance/payout/:payoutId/approve
exports.payoutApprove = yup.object({
    payoutId: yup.number().integer().positive().required("payoutId is required"),
});

// PUT /admin/finance/payout/:payoutId/reject
exports.payoutReject = yup.object({
    payoutId: yup.number().integer().positive().required("payoutId is required"),
    reason: yup.string().required("reason is required").min(10, "reason must be at least 10 chars").max(500),
});

// --- A-04 — Payout Schedule CRUD ---

// POST /admin/finance/payout/schedule/search
exports.scheduleSearch = yup.object({
    page: yup.number().integer().min(1).optional().default(1),
    limit: yup.number().integer().min(1).max(100).optional().default(20),
    hostId: yup.number().integer().optional().nullable(),
});

const FREQUENCIES = ["DAILY", "WEEKLY", "BIWEEKLY", "MONTHLY"];
const PAYOUT_METHODS = ["BANK_TRANSFER", "UPI"];

// PUT /admin/finance/payout/schedule/:scheduleId
exports.scheduleUpdate = yup.object({
    scheduleId: yup.number().integer().positive().required("scheduleId is required"),
    frequency: yup.string().oneOf(FREQUENCIES).optional().nullable(),
    minPayoutAmount: yup.number().min(0).optional().nullable(),
    isActive: yup.boolean().optional().nullable(),
    payoutMethod: yup.string().oneOf(PAYOUT_METHODS).optional().nullable(),
});

// POST /admin/finance/payout/schedule/create
exports.scheduleCreate = yup.object({
    hostId: yup.number().integer().positive().required("hostId is required"),
    frequency: yup.string().oneOf(FREQUENCIES).required("frequency is required"),
    minPayoutAmount: yup.number().min(100, "minPayoutAmount must be >= 100").required("minPayoutAmount is required"),
    payoutMethod: yup.string().oneOf(PAYOUT_METHODS).required("payoutMethod is required"),
    accountDetails: yup.object({
        accountNumber: yup.string().optional().nullable(),
        ifsc: yup.string().optional().nullable(),
        upiId: yup.string().optional().nullable(),
    }).required("accountDetails is required"),
});

// ============================================================================
// A-05 — Invoice
// ============================================================================

const INVOICE_TYPES = ["BOOKING_RECEIPT", "HOST_COMMISSION", "PAYOUT_STATEMENT"];
const INVOICE_STATUSES = ["GENERATED", "SENT", "VOID"];

// POST /admin/finance/invoice/search
exports.invoiceSearch = yup.object({
    page: yup.number().integer().min(1).optional().default(1),
    limit: yup.number().integer().min(1).max(100).optional().default(20),
    hostId: yup.number().integer().optional().nullable(),
    userId: yup.number().integer().optional().nullable(),
    invoiceType: yup.string().oneOf([...INVOICE_TYPES, null]).optional().nullable(),
    dateFrom: yup.string().optional().nullable(),
    dateTo: yup.string().optional().nullable(),
    status: yup.string().oneOf([...INVOICE_STATUSES, null]).optional().nullable(),
});

// GET /admin/finance/invoice/:invoiceId
exports.invoiceGet = yup.object({
    invoiceId: yup.number().integer().positive().required("invoiceId is required"),
});

// GET /admin/finance/invoice/:invoiceId/download
exports.invoiceDownload = yup.object({
    invoiceId: yup.number().integer().positive().required("invoiceId is required"),
});

// POST /admin/finance/invoice/void/:invoiceId
exports.invoiceVoid = yup.object({
    invoiceId: yup.number().integer().positive().required("invoiceId is required"),
    reason: yup.string().required("reason is required").min(10, "reason must be at least 10 chars").max(500),
});

// ============================================================================
// A-05 — Reconciliation
// ============================================================================

const RECON_STATUSES = ["MATCHED", "VARIANCE", "PENDING", "RESOLVED"];
const RECON_ACTIONS = ["ADJUST", "WRITE_OFF", "REFUND"];

// POST /admin/finance/reconciliation/search
exports.reconSearch = yup.object({
    page: yup.number().integer().min(1).optional().default(1),
    limit: yup.number().integer().min(1).max(100).optional().default(20),
    status: yup.string().oneOf([...RECON_STATUSES, null]).optional().nullable(),
    dateFrom: yup.string().optional().nullable(),
    dateTo: yup.string().optional().nullable(),
});

// GET /admin/finance/reconciliation/:reconId
exports.reconGet = yup.object({
    reconId: yup.number().integer().positive().required("reconId is required"),
});

// PUT /admin/finance/reconciliation/:reconId/resolve
exports.reconResolve = yup.object({
    reconId: yup.number().integer().positive().required("reconId is required"),
    notes: yup.string().required("notes are required").min(10, "notes must be at least 10 chars").max(2000),
    action: yup.string().oneOf(RECON_ACTIONS).required("action is required"),
});

// POST /admin/finance/reconciliation/run
exports.reconRun = yup.object({
    dateFrom: yup.string().required("dateFrom is required"),
    dateTo: yup.string().required("dateTo is required"),
});

// ============================================================================
// A-05 — Reports
// ============================================================================

const GROUP_BY = ["day", "week", "month"];

// POST /admin/finance/reports/revenue
exports.reportRevenue = yup.object({
    dateFrom: yup.string().required("dateFrom is required"),
    dateTo: yup.string().required("dateTo is required"),
    groupBy: yup.string().oneOf(GROUP_BY).optional().default("month"),
    propertyId: yup.number().integer().optional().nullable(),
    categoryId: yup.number().integer().optional().nullable(),
});

// POST /admin/finance/reports/commission
exports.reportCommission = yup.object({
    dateFrom: yup.string().required("dateFrom is required"),
    dateTo: yup.string().required("dateTo is required"),
    groupBy: yup.string().oneOf(GROUP_BY).optional().default("month"),
});

// POST /admin/finance/reports/tax
exports.reportTax = yup.object({
    dateFrom: yup.string().required("dateFrom is required"),
    dateTo: yup.string().required("dateTo is required"),
});

// POST /admin/finance/reports/cashflow
exports.reportCashflow = yup.object({
    dateFrom: yup.string().required("dateFrom is required"),
    dateTo: yup.string().required("dateTo is required"),
    groupBy: yup.string().oneOf(GROUP_BY).optional().default("month"),
});

// POST /admin/finance/reports/export
exports.reportExport = yup.object({
    reportType: yup.string().oneOf(["revenue", "commission", "tax", "cashflow"]).required("reportType is required"),
    dateFrom: yup.string().required("dateFrom is required"),
    dateTo: yup.string().required("dateTo is required"),
    format: yup.string().oneOf(["csv", "excel"]).optional().default("csv"),
});
