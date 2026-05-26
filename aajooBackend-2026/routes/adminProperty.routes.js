const express = require("express");
const router = express.Router();
const controller = require("../controllers/adminProperty.controller");
const schema = require("../schema/adminProperties.schema");
const validation = require("../middleware/validation");
const { adminAuthToken } = require("../middleware/authorization");
const { upload } = require("../utils/fileHandler");
const { adminApiLimiter } = require("../middleware/adminRateLimiter");


router.post("/admin/property/create", upload.fields([{ name: "propertyCover", maxCount: 1 }, { name: "propertyImage" }, { name: "propertyDoc" }]), [validation(schema.propertySchema), adminAuthToken], controller.createuUpdateProperty);
router.post("/admin/properties/search", [adminAuthToken], controller.PropertySearch);
router.post("/admin/property/delete", [validation(schema.propertyIdSchema), adminAuthToken], controller.deleteProperty);
router.post("/admin/property", [validation(schema.propertyIdSchema), adminAuthToken], controller.getPropetyById);
router.post("/admin/properties/update-status", [validation(schema.propertyStatusSchema), adminAuthToken], controller.updateStatus);
router.post("/admin/properties/delete/image", [validation(schema.deletePropImageSchema), adminAuthToken], controller.deletePropertyImages);


module.exports = router;