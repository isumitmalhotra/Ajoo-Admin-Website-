const express = require("express");
const router = express.Router();
const controller = require("../controllers/adminPropertyReviews.controller");
const schema = require("../schema/adminPropertyReviews.schema");
const validation = require("../middleware/validation");
const { adminAuthToken } = require("../middleware/authorization");
const { adminApiLimiter } = require("../middleware/rateLimiter");

router.post("/admin/property/review/search", adminApiLimiter, [validation(schema.reviewSearchSchema), adminAuthToken], controller.reviewListing);
router.post("/admin/property/review/update", adminApiLimiter, [validation(schema.updateBookingStatusSchema), adminAuthToken], controller.updateReview);
router.post("/admin/property/review/detail", adminApiLimiter, [validation(schema.reviewIdSchema), adminAuthToken], controller.detailedReview);

module.exports = router;
