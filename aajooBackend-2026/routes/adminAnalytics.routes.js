const express = require("express");
const router = express.Router();
const controller = require("../controllers/adminAnalytics.controller");
// const schema = require("../schema/adminUser.schema");
const validation = require("../middleware/validation");
const { adminAuthToken } = require("../middleware/authorization");
const { upload } = require("../utils/fileHandler");
const { adminLoginLimiter, adminApiLimiter } = require("../middleware/adminRateLimiter");


router.get("/admin/analytics/graph", [adminAuthToken], controller.getBookingAnalytics);


module.exports = router;