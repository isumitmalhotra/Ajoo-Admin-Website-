const express = require("express");
const router = express.Router();
const controller = require("../controllers/adminTermsAndCond.controller");
const schema = require("../schema/adminTermsAndCond.schema");
const validation = require("../middleware/validation");
const { adminAuthToken } = require("../middleware/authorization");
// const { upload } = require("../utils/fileHandler");
const { adminApiLimiter } = require("../middleware/adminRateLimiter");


router.post("/admin/terms-condition/add", [validation(schema.termsConditionSchema), adminApiLimiter, adminAuthToken], controller.addUpdateTerms);
router.post("/admin/terms-condition/listing", [adminApiLimiter, adminAuthToken], controller.listingTerms);
router.post("/admin/terms-condition/delete", [validation(schema.termsConditionIdSchema), adminApiLimiter, adminAuthToken], controller.deleteTerms);
router.post("/admin/terms-condition/detail", [validation(schema.termsConditionIdSchema), adminApiLimiter, adminAuthToken], controller.detailTerms);


module.exports = router;
