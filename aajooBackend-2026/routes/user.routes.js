const express = require("express");
const router = express.Router();  // Initialize the router
const controller = require("../controllers/user.controller");
const schema = require("../schema/user.schema");
const validation = require("../middleware/validation");
const { authenticateJWT } = require("../middleware/authorization");
const { upload } = require("../utils/fileHandler");
const { generalLimiter, strictLimiter, otpLimiter, uploadLimiter } = require("../middleware/rateLimiter");

router.post("/user/signup", strictLimiter, upload.single("user_id_doc"), [validation(schema.createUser)], controller.createUser);
router.post("/user/login", strictLimiter, [validation(schema.login)], controller.loginUser);
router.post("/user/logout", generalLimiter, [authenticateJWT], controller.logout);
router.post("/user/update", uploadLimiter, upload.single("user_id_doc"), [validation(schema.updateUser), authenticateJWT], controller.updateUser);
router.post("/user/delete/profile-pic", generalLimiter, [authenticateJWT], controller.deleteProfilePicture);
router.post("/user/add/profile-pic", uploadLimiter, upload.single("user_image"), [authenticateJWT], controller.addProfilePic);
router.post("/user/is-exist", strictLimiter, [validation(schema.isUserExist)], controller.checkEmailIsExist);
router.get("/user/detail", generalLimiter, [authenticateJWT], controller.getUserByToken);
router.post("/user/otp-again", otpLimiter, [validation(schema.userId)], controller.otpSendAgain);
router.post("/user/verify-otp", strictLimiter, [validation(schema.verifyOtp)], controller.verifyOtp);
router.post("/user/review-add", generalLimiter, [validation(schema.addUpdateReview), authenticateJWT], controller.userCreateReview);
router.post("/user/delete", generalLimiter, [authenticateJWT], controller.deleteUser);
//Notification----------------------------------------->
router.post("/user/notification/allow-notification", generalLimiter, [validation(schema.allowNotification), authenticateJWT], controller.addNotificationToken);
router.post("/user/notification/mark-read", generalLimiter, [validation(schema.markReadNotification), authenticateJWT], controller.markReadNotification);
router.get("/user/notification/Listing", generalLimiter, [authenticateJWT], controller.notificationListing);
//Forgate password------------------------------------->
router.post("/user/forget-password", otpLimiter, [validation(schema.forgotPassword)], controller.ForgetPasswordEmail);
router.post("/user/forget/verify-otp", strictLimiter, [validation(schema.verifyOptForgetPass)], controller.verifyForgetPasswordOtp);
router.post("/user/update/forget-password", generalLimiter, [validation(schema.updateForgetPassword), authenticateJWT], controller.updateForgotPassByEmail);


// router.get("/user/reg-docType", [], controller.userRegDocTypes);
router.post("/user/history", generalLimiter, [validation(schema.userId), authenticateJWT], controller.userHistory);

// router.post("/user/password/verify-otp", [validation(schema.updateForgetPasswordOtp)], controller.verifyOtpForUpdatePassword);

router.post("/user/update-password", generalLimiter, [validation(schema.updatePassword), authenticateJWT], controller.userUpdatePasswordManual);

router.post("/user/saved-properties", generalLimiter, [validation(schema.savedPropList)], controller.UserSavedProperties);
router.get("/user/booking-history", generalLimiter, [authenticateJWT], controller.userBookingList);


module.exports = router;