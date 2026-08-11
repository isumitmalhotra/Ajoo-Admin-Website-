const express = require("express");
const router = express.Router();
const controller = require("../controllers/adminPropAnalytics.controller");
const schema = require("../schema/adminProperties.schema");
const validation = require("../middleware/validation");
const { adminAuthToken } = require("../middleware/authorization");
const { adminApiLimiter } = require("../middleware/rateLimiter");

router.post("/admin/properties/analytic/search", adminApiLimiter, [validation(schema.propertyAnalyticsSearchSchema), adminAuthToken], controller.propAnalytics);
router.post("/admin/property/analytic/detail", adminApiLimiter, [validation(schema.propertyIdSchema), adminAuthToken], controller.propAnalyticDetail);


module.exports = router;
