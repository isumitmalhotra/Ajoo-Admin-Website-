const express = require("express");
const router = express.Router();
const controller = require("../controllers/adminFAQ.controller");
const schema = require("../schema/adminFAQ.schema");
const validation = require("../middleware/validation");
const { adminAuthToken } = require("../middleware/authorization");
const { adminApiLimiter } = require("../middleware/rateLimiter");

router.post("/admin/faq/add", adminApiLimiter, [validation(schema.faqSchema), adminAuthToken], controller.addUpdateFaq);
router.post("/admin/faq/listing", adminApiLimiter, [validation(schema.faqListingSchema), adminAuthToken], controller.listingFaq);
router.post("/admin/faq/delete", adminApiLimiter, [validation(schema.faqId), adminAuthToken], controller.deleteFaq);
router.post("/admin/faq/detail", adminApiLimiter, [validation(schema.faqId), adminAuthToken], controller.detailFaq);


module.exports = router;
