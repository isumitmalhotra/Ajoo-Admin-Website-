'use strict';
/**
 * Routes: KYC verification (/verify/*)
 * Sprint: Full Delivery 2026-06-09..18 (A-12)
 *
 * create-session accepts either a logged-in guest or host (authenticateJWT —
 * controller branches on context). status + check-session also JWT-gated.
 * The webhook is a SEPARATE file (webhooks.routes.js) with NO auth.
 */
const express = require("express");
const router = express.Router();
const controller = require("../controllers/verify.controller");
const schema = require("../schema/verify.schema");
const validation = require("../middleware/validation");
const { authenticateJWT } = require("../middleware/authorization");
const { generalLimiter } = require("../middleware/rateLimiter");

router.post(
    "/verify/create-session",
    generalLimiter,
    [validation(schema.createSession), authenticateJWT],
    controller.createSession
);

router.get(
    "/verify/status",
    generalLimiter,
    [validation(schema.statusGet), authenticateJWT],
    controller.getStatus
);

router.get(
    "/verify/check-session/:sessionId",
    generalLimiter,
    [validation(schema.checkSession), authenticateJWT],
    controller.checkSession
);

module.exports = router;
