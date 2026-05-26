const express = require("express");
const router = express.Router();
const controller = require("../controllers/adminPropertyReviews.controller");
const schema = require("../schema/adminPropertyReviews.schema");
const validation = require("../middleware/validation");
const { adminAuthToken } = require("../middleware/authorization");
const { upload } = require("../utils/fileHandler");
const { adminApiLimiter } = require("../middleware/adminRateLimiter");


router.post("/admin/propety/review/search", [validation(schema.reviewSearchSchema), adminAuthToken], controller.reviewListing);
router.post("/admin/propety/review/update", [validation(schema.updateBookingStatusSchema), adminApiLimiter, adminAuthToken,], controller.updateReview);
router.post("/admin/property/review/detail", [adminAuthToken], controller.detailedReview);



module.exports = router;