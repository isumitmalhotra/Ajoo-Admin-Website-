const express = require("express");
const router = express.Router();
const controller = require("../controllers/booking.controller");
const schema = require("../schema/booking.schema");
const validation = require("../middleware/validation");
const { authenticateJWT } = require("../middleware/authorization");
const { generalLimiter, strictLimiter } = require("../middleware/rateLimiter");

router.post("/booking/create", strictLimiter, [validation(schema.createBooking), authenticateJWT], controller.bookingCreate);
router.post("/create/payment-verify", generalLimiter, [validation(schema.verifyPayment), authenticateJWT], controller.verifyUserPayment);
router.post("/create/test", generalLimiter, [authenticateJWT], controller.test);
router.post("/user/ongoing/bookings", generalLimiter, [authenticateJWT], controller.ongoingBookingsUser);
router.post("/user/ongoing/bookings/payment/create", generalLimiter, [validation(schema.ongoingBookingPayment), authenticateJWT], controller.createPaymentOrderOngoingBooking);
router.post("/user/cancel/booking", generalLimiter, [validation(schema.cancelBooking), authenticateJWT], controller.cancelBooking);

router.post("/test/mail", generalLimiter, [], controller.testSendEmail);



module.exports = router;