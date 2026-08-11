'use strict';
/**
 * Routes: hostV2 — HMS host portal endpoints under /host/*
 * Sprint: Full Delivery 2026-06-09..18 (A-07)
 *
 * New paths added alongside existing legacy paths in host.routes.js + payouts.routes.js.
 * Old paths kept for back-compat; Day 10 cleanup deletes them.
 *
 * Auth: hostAuthentication for host-scoped routes; authenticateJWT for onboarding
 * (open to any logged-in user — flips them to host after admin approval).
 */
const express = require("express");
const router = express.Router();
const controller = require("../controllers/hostV2.controller");
const schema = require("../schema/hostV2.schema");
const validation = require("../middleware/validation");
const { hostAuthentication, authenticateJWT } = require("../middleware/authorization");
const { generalLimiter, uploadLimiter } = require("../middleware/rateLimiter");

// --- Dashboard ---
router.get(
    "/host/dashboard/summary",
    generalLimiter,
    [validation(schema.dashboardSummary), hostAuthentication],
    controller.dashboardSummary
);

// --- Bookings (INT-04) ---
router.post(
    "/host/bookings/search",
    generalLimiter,
    [validation(schema.bookingsSearch), hostAuthentication],
    controller.bookingsSearch
);

router.get(
    "/host/bookings/detail/:bookingId",
    generalLimiter,
    [validation(schema.bookingDetail), hostAuthentication],
    controller.bookingDetail
);

// --- Earnings ---
router.get(
    "/host/earnings/summary",
    generalLimiter,
    [validation(schema.earningsSummary), hostAuthentication],
    controller.earningsSummary
);

router.get(
    "/host/payout/history",
    generalLimiter,
    [validation(schema.payoutHistory), hostAuthentication],
    controller.payoutHistory
);

// --- Profile ---
router.get(
    "/host/profile/get",
    generalLimiter,
    [validation(schema.profileGet), hostAuthentication],
    controller.profileGet
);

router.put(
    "/host/profile/update",
    generalLimiter,
    [validation(schema.profileUpdate), hostAuthentication],
    controller.profileUpdate
);

// --- Payout Account (INT-05) ---
router.get(
    "/host/payout-account/get",
    generalLimiter,
    [validation(schema.payoutAccountGet), hostAuthentication],
    controller.payoutAccountGet
);

router.put(
    "/host/payout-account/update",
    generalLimiter,
    [validation(schema.payoutAccountUpdate), hostAuthentication],
    controller.payoutAccountUpdate
);

// --- Statements ---
router.post(
    "/host/statements/search",
    generalLimiter,
    [validation(schema.statementsSearch), hostAuthentication],
    controller.statementsSearch
);

router.get(
    "/host/statements/download/:statementId",
    generalLimiter,
    [validation(schema.statementsDownload), hostAuthentication],
    controller.statementsDownload
);

// --- Support tickets ---
router.post(
    "/host/support/tickets/search",
    generalLimiter,
    [validation(schema.ticketSearch), hostAuthentication],
    controller.ticketSearch
);

router.post(
    "/host/support/tickets/create",
    generalLimiter,
    [validation(schema.ticketCreate), hostAuthentication],
    controller.ticketCreate
);

router.post(
    "/host/support/tickets/reply",
    generalLimiter,
    [validation(schema.ticketReply), hostAuthentication],
    controller.ticketReply
);

// --- Performance ---
router.get(
    "/host/performance/summary",
    generalLimiter,
    [validation(schema.performanceSummary), hostAuthentication],
    controller.performanceSummary
);

// --- Onboarding (INT-10) ---
router.post(
    "/host/onboarding/submit",
    generalLimiter,
    [validation(schema.onboardingSubmit), authenticateJWT],
    controller.onboardingSubmit
);

module.exports = router;
