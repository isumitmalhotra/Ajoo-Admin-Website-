const express = require("express");
const router = express.Router();
const controller = require("../controllers/adminTermsAndCond.controller");
const schema = require("../schema/adminTermsAndCond.schema");
const validation = require("../middleware/validation");
const { adminAuthToken } = require("../middleware/authorization");
// const { upload } = require("../utils/fileHandler");
const { adminApiLimiter } = require("../middleware/rateLimiter");

router.post("/admin/terms-condition/add", adminApiLimiter, [validation(schema.termsConditionSchema), adminAuthToken], controller.addUpdateTerms);
router.post("/admin/terms-condition/listing", adminApiLimiter, [validation(schema.termsListingSchema), adminAuthToken], controller.listingTerms);
router.post("/admin/terms-condition/delete", adminApiLimiter, [validation(schema.termsConditionIdSchema), adminAuthToken], controller.deleteTerms);
router.post("/admin/terms-condition/detail", adminApiLimiter, [validation(schema.termsConditionIdSchema), adminAuthToken], controller.detailTerms);

module.exports = router;
