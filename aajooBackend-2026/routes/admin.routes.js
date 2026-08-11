const express = require("express");
const router = express.Router();
const controller = require("../controllers/admin.controller");
const schema = require("../schema/admin.schema");
const validation = require("../middleware/validation");
const { adminAuth } = require("../middleware/authorization");
const { adminApiLimiter, adminLoginLimiter, adminCriticalLimiter } = require("../middleware/rateLimiter");

const optionalAdminAuth = (req, res, next) => {
    if (!req.headers.authorization) {
        return next();
    }

    return adminAuth(req, res, next);
};

router.post("/admin/login", [adminLoginLimiter, validation(schema.adminLogin)], controller.adminLogin);
router.post("/admin/create", [adminCriticalLimiter, validation(schema.adminCreate)], controller.createAdmin);
router.post("/admin/logout", [adminApiLimiter, adminAuth], controller.adminLogout);
router.get("/admin/dashboard", [adminApiLimiter, adminAuth], controller.adminDashboard);
router.get("/admin/verify-token", [adminApiLimiter, adminAuth], controller.verifyToken);

module.exports = router;
