const express = require("express");
const router = express.Router();
const controller = require("../controllers/adminAnalytics.controller");
const schema = require("../schema/adminAnalytics.schema");
const validation = require("../middleware/validation");
const { adminAuthToken } = require("../middleware/authorization");
const { adminApiLimiter } = require("../middleware/rateLimiter");


router.get("/admin/analytics/graph", adminApiLimiter, [validation(schema.graphFilterSchema), adminAuthToken], controller.getBookingAnalytics);


module.exports = router;
