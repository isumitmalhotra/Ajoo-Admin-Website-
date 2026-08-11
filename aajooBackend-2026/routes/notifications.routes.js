'use strict';
/**
 * Routes: notifications (admin + host).
 * Sprint: Full Delivery 2026-06-09..18 (A-14).
 */
const express = require("express");
const router = express.Router();
const controller = require("../controllers/notifications.controller");
const schema = require("../schema/notification.schema");
const validation = require("../middleware/validation");
const { adminAuth, hostAuthentication } = require("../middleware/authorization");
const { adminApiLimiter, generalLimiter } = require("../middleware/rateLimiter");

// Admin
router.get(
    "/admin/notifications/search",
    adminApiLimiter,
    [validation(schema.search), adminAuth],
    controller.adminSearch
);
router.put(
    "/admin/notifications/:id/read",
    adminApiLimiter,
    [validation(schema.markRead), adminAuth],
    controller.markRead
);

// Host
router.get(
    "/host/notifications/search",
    generalLimiter,
    [validation(schema.search), hostAuthentication],
    controller.hostSearch
);
router.put(
    "/host/notifications/:id/read",
    generalLimiter,
    [validation(schema.markRead), hostAuthentication],
    controller.markRead
);

module.exports = router;
