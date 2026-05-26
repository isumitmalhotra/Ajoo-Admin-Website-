const express = require("express");
const router = express.Router();
const controller = require("../controllers/review.controller");
const schema = require("../schema/reviews.schema");
const validation = require("../middleware/validation");
const { authenticateJWT, hostAuthentication } = require("../middleware/authorization");
const { upload } = require("../utils/fileHandler");
const { generalLimiter, uploadLimiter } = require("../middleware/rateLimiter");

//-------------BASIC--------------------
router.post("/review/like", generalLimiter, [validation(schema.reviewId), authenticateJWT], controller.userLikedProperty);
router.post("/review/dislike", generalLimiter, [validation(schema.reviewId), authenticateJWT], controller.userDislikeProperty);
router.post("/review/user/delete-review", generalLimiter, [validation(schema.reviewId), authenticateJWT], controller.UserDeleteRview);
router.post("/review/user/checkout", uploadLimiter, upload.array("userReview_img"), [validation(schema.checkoutSchema), authenticateJWT], controller.checkoutPage);
//HOST GIVE REVIEW TO USER---------------------------->
router.post("/review/host/add-user-review", uploadLimiter, upload.array("hru_img"), [validation(schema.userReviewAddedByHost), authenticateJWT], controller.hostGiveReviewToUserAddData);
router.get("/review/host/user-review-list", generalLimiter, [authenticateJWT], controller.hostGiveReviewToUserListing);



module.exports = router;