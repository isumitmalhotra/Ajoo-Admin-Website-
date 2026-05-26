const express = require("express");
const router = express.Router();
const controller = require("../controllers/adminPropAnalytics.controller");
const schema = require("../schema/adminProperties.schema");
const validation = require("../middleware/validation");
const { adminAuthToken } = require("../middleware/authorization");


router.post("/admin/properties/analytic/search", [adminAuthToken], controller.propAnalytics);
router.post("/admin/property/analytic/detail", [validation(schema.propertyIdSchema), adminAuthToken], controller.propAnalyticDetail);


module.exports = router;