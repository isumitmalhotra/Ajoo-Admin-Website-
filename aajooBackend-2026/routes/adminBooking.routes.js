const express = require("express");
const router = express.Router();
const controller = require("../controllers/adminBookings.controller");
const schema = require("../schema/adminBooking.schema");
const validation = require("../middleware/validation");
const { adminAuthToken } = require("../middleware/authorization");
const { adminApiLimiter } = require("../middleware/rateLimiter");

router.post("/admin/booking/search", adminApiLimiter, [validation(schema.bookingSearchSchema), adminAuthToken], controller.getBookingList);
router.post("/admin/booking/update", adminApiLimiter, [validation(schema.bookingStatusUpdate), adminAuthToken], controller.updateBookingStatusforBookings);
router.post("/admin/booking/detail", adminApiLimiter, [validation(schema.bookingId), adminAuthToken], controller.bpokingDetail);
router.get("/admin/booking/status/list", adminApiLimiter, [adminAuthToken], controller.bookingStatusListing);
router.post("/admin/booking/status/update", adminApiLimiter, [validation(schema.statusUpdate), adminAuthToken], controller.updateBookingStatus);
router.post("/admin/booking/status/listing/admin-page", adminApiLimiter, [validation(schema.bookingStatusListingSchema), adminAuthToken], controller.bookingStatusListingforAdminPage);


module.exports = router;
