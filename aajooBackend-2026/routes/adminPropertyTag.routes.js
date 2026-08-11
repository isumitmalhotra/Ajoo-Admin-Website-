const express = require("express");
const router = express.Router();
const controller = require("../controllers/adminPropertyTag.controller");
const schema = require("../schema/adminPropertyTag.schema");
const validation = require("../middleware/validation");
const { adminAuthToken } = require("../middleware/authorization");
const { adminApiLimiter } = require("../middleware/rateLimiter");

router.post("/admin/tag/create", adminApiLimiter, [validation(schema.createOrUpdateTagSchema), adminAuthToken], controller.createOrUpdatePropertyTag);
router.post("/admin/tag/delete", adminApiLimiter, [validation(schema.deteletTagSchema), adminAuthToken], controller.deleteTag);
router.post("/admin/tag/search", adminApiLimiter, [validation(schema.tagListingSchema), adminAuthToken], controller.getTagListing);
router.get("/admin/tag/listing/dropdowns", adminApiLimiter, [adminAuthToken], controller.tagListingforDropdown);
router.post("/admin/tag/single", adminApiLimiter, [validation(schema.deteletTagSchema), adminAuthToken], controller.getTag);
router.post("/admin/tag/update-status", adminApiLimiter, [validation(schema.updateTagStatusSchema), adminAuthToken], controller.updateStatus);

module.exports = router;
