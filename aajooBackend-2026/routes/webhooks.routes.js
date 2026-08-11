'use strict';
/**
 * Routes: external webhooks (/webhooks/*)
 * Sprint: Full Delivery 2026-06-09..18 (A-12)
 *
 * ⚠️ Didit webhook: NO auth middleware, NO rate limiter (Didit retries).
 * Signature is verified via HMAC over the RAW body inside the controller.
 *
 * Raw body capture: app.js registers `express.json({ verify: (req,res,buf) => { req.rawBody = buf } })`
 * globally, so `req.rawBody` is the unparsed Buffer here. We do NOT add a
 * route-level express.raw() (the global json parser already consumed the stream).
 */
const express = require("express");
const router = express.Router();
const controller = require("../controllers/verify.controller");

router.post("/webhooks/didit", controller.webhook);

module.exports = router;
