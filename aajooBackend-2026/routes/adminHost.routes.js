const express = require("express");
const router = express.Router();
const controller = require("../controllers/adminHost.controller");
const schema = require("../schema/adminUser.schema");
const schemaV2 = require("../schema/adminHost.schema");
const validation = require("../middleware/validation");
const { adminAuthToken, adminAuth } = require("../middleware/authorization");
const { adminApiLimiter, adminCriticalLimiter } = require("../middleware/rateLimiter");

// --- Existing (pre-A-08) ---
router.post("/admin/host/search", adminApiLimiter, [validation(schema.hostSearchSchema), adminAuthToken], controller.hostListing);
router.get("/admin/host/search/assign-property", adminApiLimiter, [validation(schema.hostAssignPropertySearchSchema), adminAuthToken], controller.hostListForAssgnProperty);

// --- A-08 — HMS Admin endpoints ---
// Note: using `adminAuth` (canonical) for new endpoints per API_CONTRACT_HANDOFF.md § 0.2

router.get(
    "/admin/host/detail/:hostId",
    adminApiLimiter,
    [validation(schemaV2.hostDetailGet), adminAuth],
    controller.hostDetailGet
);

router.get(
    "/admin/host/kyc/detail/:hostId",
    adminApiLimiter,
    [validation(schemaV2.kycDetailGet), adminAuth],
    controller.kycDetailGet
);

router.post(
    "/admin/host/kyc/approve",
    adminCriticalLimiter,
    [validation(schemaV2.kycApprove), adminAuth],
    controller.kycApprove
);

router.post(
    "/admin/host/kyc/reject",
    adminCriticalLimiter,
    [validation(schemaV2.kycReject), adminAuth],
    controller.kycReject
);

router.get(
    "/admin/host/performance/summary",
    adminApiLimiter,
    [validation(schemaV2.perfSummaryGet), adminAuth],
    controller.perfSummaryGet
);

router.get(
    "/admin/host/payout/history",
    adminApiLimiter,
    [validation(schemaV2.payoutHistoryGet), adminAuth],
    controller.payoutHistoryGet
);

router.post(
    "/admin/host/payout/hold",
    adminCriticalLimiter,
    [validation(schemaV2.payoutHold), adminAuth],
    controller.payoutHold
);

router.post(
    "/admin/host/payout/release",
    adminCriticalLimiter,
    [validation(schemaV2.payoutRelease), adminAuth],
    controller.payoutRelease
);

module.exports = router;
