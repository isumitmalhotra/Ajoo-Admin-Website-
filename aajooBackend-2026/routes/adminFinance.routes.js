'use strict';
/**
 * Routes: /admin/finance/* — Finance Management System
 * Sprint: Full Delivery 2026-06-09..18 (A-03 phase 1, extended in A-04 + A-05)
 * Authored by: Account A
 *
 * Auto-loaded by app.js (fs.readdirSync of routes/). No manual wire needed.
 * Auth: adminAuth (canonical — NOT adminAuthToken; see API_CONTRACT_HANDOFF.md § 0.2)
 */
const express = require("express");
const router = express.Router();
const controller = require("../controllers/adminFinance.controller");
const schema = require("../schema/adminFinance.schema");
const validation = require("../middleware/validation");
const { adminAuth, requireRole } = require("../middleware/authorization");
const { adminApiLimiter } = require("../middleware/rateLimiter");

// --- Phase 1 (A-03) ---

// Dashboard also demonstrates the A-13 RBAC gate: adminAuth decodes the token,
// requireRole("admin","finance") enforces the role claim. (admin is superuser.)
router.get(
    "/admin/finance/dashboard",
    adminApiLimiter,
    [validation(schema.dashboardGet), adminAuth, requireRole("admin", "finance")],
    controller.getDashboard
);

router.post(
    "/admin/finance/ledger/search",
    adminApiLimiter,
    [validation(schema.ledgerSearch), adminAuth],
    controller.searchLedger
);

router.post(
    "/admin/finance/payout/search",
    adminApiLimiter,
    [validation(schema.payoutSearch), adminAuth],
    controller.searchPayouts
);

// --- Phase 2 (A-04) — Ledger CRUD ---

router.get(
    "/admin/finance/ledger/:ledgerId",
    adminApiLimiter,
    [validation(schema.ledgerGet), adminAuth],
    controller.getLedgerEntry
);

router.post(
    "/admin/finance/ledger/host/:hostId",
    adminApiLimiter,
    [validation(schema.ledgerByHost), adminAuth],
    controller.getHostLedger
);

router.post(
    "/admin/finance/ledger/user/:userId",
    adminApiLimiter,
    [validation(schema.ledgerByUser), adminAuth],
    controller.getGuestLedger
);

router.post(
    "/admin/finance/ledger/export",
    adminApiLimiter,
    [validation(schema.ledgerExport), adminAuth],
    controller.exportLedger
);

// --- Phase 2 (A-04) — Payout CRUD ---

router.get(
    "/admin/finance/payout/:payoutId",
    adminApiLimiter,
    [validation(schema.payoutGet), adminAuth],
    controller.getPayout
);

const { adminCriticalLimiter } = require("../middleware/rateLimiter");

router.post(
    "/admin/finance/payout/initiate",
    adminCriticalLimiter,
    [validation(schema.payoutInitiate), adminAuth],
    controller.initiatePayout
);

router.put(
    "/admin/finance/payout/:payoutId/approve",
    adminCriticalLimiter,
    [validation(schema.payoutApprove), adminAuth],
    controller.approvePayout
);

router.put(
    "/admin/finance/payout/:payoutId/reject",
    adminCriticalLimiter,
    [validation(schema.payoutReject), adminAuth],
    controller.rejectPayout
);

// --- Phase 2 (A-04) — Payout Schedule CRUD ---

router.post(
    "/admin/finance/payout/schedule/search",
    adminApiLimiter,
    [validation(schema.scheduleSearch), adminAuth],
    controller.searchSchedules
);

router.put(
    "/admin/finance/payout/schedule/:scheduleId",
    adminApiLimiter,
    [validation(schema.scheduleUpdate), adminAuth],
    controller.updateSchedule
);

router.post(
    "/admin/finance/payout/schedule/create",
    adminCriticalLimiter,
    [validation(schema.scheduleCreate), adminAuth],
    controller.createSchedule
);

// --- Phase 3 (A-05) — Invoice ---

router.post(
    "/admin/finance/invoice/search",
    adminApiLimiter,
    [validation(schema.invoiceSearch), adminAuth],
    controller.searchInvoices
);

router.get(
    "/admin/finance/invoice/:invoiceId",
    adminApiLimiter,
    [validation(schema.invoiceGet), adminAuth],
    controller.getInvoice
);

router.get(
    "/admin/finance/invoice/:invoiceId/download",
    adminApiLimiter,
    [validation(schema.invoiceDownload), adminAuth],
    controller.downloadInvoice
);

router.post(
    "/admin/finance/invoice/void/:invoiceId",
    adminCriticalLimiter,
    [validation(schema.invoiceVoid), adminAuth],
    controller.voidInvoice
);

// --- Phase 3 (A-05) — Reconciliation ---

router.post(
    "/admin/finance/reconciliation/search",
    adminApiLimiter,
    [validation(schema.reconSearch), adminAuth],
    controller.searchReconciliation
);

router.get(
    "/admin/finance/reconciliation/:reconId",
    adminApiLimiter,
    [validation(schema.reconGet), adminAuth],
    controller.getReconciliation
);

router.put(
    "/admin/finance/reconciliation/:reconId/resolve",
    adminCriticalLimiter,
    [validation(schema.reconResolve), adminAuth],
    controller.resolveReconciliation
);

router.post(
    "/admin/finance/reconciliation/run",
    adminCriticalLimiter,
    [validation(schema.reconRun), adminAuth],
    controller.runReconciliation
);

// --- Phase 3 (A-05) — Reports ---

router.post(
    "/admin/finance/reports/revenue",
    adminApiLimiter,
    [validation(schema.reportRevenue), adminAuth],
    controller.reportRevenue
);

router.post(
    "/admin/finance/reports/commission",
    adminApiLimiter,
    [validation(schema.reportCommission), adminAuth],
    controller.reportCommission
);

router.post(
    "/admin/finance/reports/tax",
    adminApiLimiter,
    [validation(schema.reportTax), adminAuth],
    controller.reportTax
);

router.post(
    "/admin/finance/reports/cashflow",
    adminApiLimiter,
    [validation(schema.reportCashflow), adminAuth],
    controller.reportCashflow
);

router.post(
    "/admin/finance/reports/export",
    adminApiLimiter,
    [validation(schema.reportExport), adminAuth],
    controller.reportExport
);

module.exports = router;
