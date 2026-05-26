const express = require("express");
const router = express.Router();
const controller = require("../controllers/adminFAQ.controller");
const schema = require("../schema/adminFAQ.schema");
const validation = require("../middleware/validation");
const { adminAuthToken } = require("../middleware/authorization");
const { adminApiLimiter } = require("../middleware/adminRateLimiter");


router.post("/admin/faq/add", [validation(schema.faqSchema), adminApiLimiter, adminAuthToken], controller.addUpdateFaq);
router.post("/admin/faq/listing", [adminApiLimiter, adminAuthToken], controller.listingFaq);
router.post("/admin/faq/delete", [validation(schema.faqId), adminApiLimiter, adminAuthToken], controller.deleteFaq);
router.post("/admin/faq/detail", [validation(schema.faqId), adminApiLimiter, adminAuthToken], controller.detailFaq);


module.exports = router;
