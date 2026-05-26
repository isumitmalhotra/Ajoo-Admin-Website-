const express = require("express");
const router = express.Router();
const controller = require("../controllers/adminPropertyTag.controller");
const schema = require("../schema/adminPropertyTag.schema");
const validation = require("../middleware/validation");
const { adminAuthToken } = require("../middleware/authorization");
const { upload } = require("../utils/fileHandler");
const { generalLimiter, uploadLimiter } = require("../middleware/rateLimiter");

router.post("/admin/tag/create", [validation(schema.createOrUpdateTagSchema), adminAuthToken], controller.createOrUpdatePropertyTag);
router.post("/admin/tag/delete", [validation(schema.deteletTagSchema), adminAuthToken], controller.deleteTag);
router.post("/admin/tag/search", [adminAuthToken], controller.getTagListing);
router.get("/admin/tag/listing/dropdowns", [adminAuthToken], controller.tagListingforDropdown);
router.post("/admin/tag/single", [validation(schema.deteletTagSchema), adminAuthToken], controller.getTag);
router.post("/admin/tag/update-status", [validation(schema.updateTagStatusSchema), adminAuthToken], controller.updateStatus);





module.exports = router;