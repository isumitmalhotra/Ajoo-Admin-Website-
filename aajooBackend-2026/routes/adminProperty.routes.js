const express = require("express");
const router = express.Router();
const controller = require("../controllers/adminProperty.controller");
const schema = require("../schema/adminProperties.schema");
const validation = require("../middleware/validation");
const { adminAuthToken } = require("../middleware/authorization");
const { upload } = require("../utils/fileHandler");
const { adminApiLimiter } = require("../middleware/rateLimiter");

router.post("/admin/property/create", upload.fields([{ name: "propertyCover", maxCount: 1 }, { name: "propertyImage" }, { name: "propertyDoc" }]), adminApiLimiter, [validation(schema.propertySchema), adminAuthToken], controller.createuUpdateProperty);
router.post("/admin/properties/search", adminApiLimiter, [validation(schema.propertySearchSchema), adminAuthToken], controller.PropertySearch);
router.post("/admin/property/delete", adminApiLimiter, [validation(schema.propertyIdSchema), adminAuthToken], controller.deleteProperty);
router.post("/admin/property", adminApiLimiter, [validation(schema.propertyIdSchema), adminAuthToken], controller.getPropetyById);
router.post("/admin/properties/update-status", adminApiLimiter, [validation(schema.propertyStatusSchema), adminAuthToken], controller.updateStatus);
router.post("/admin/properties/delete/image", adminApiLimiter, [validation(schema.deletePropImageSchema), adminAuthToken], controller.deletePropertyImages);


module.exports = router;
