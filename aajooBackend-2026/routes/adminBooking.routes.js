const express = require("express");
const router = express.Router();
const controller = require("../controllers/adminBookings.controller");
const schema = require("../schema/adminBooking.schema");
const validation = require("../middleware/validation");
const { adminAuthToken } = require("../middleware/authorization");
const { upload } = require("../utils/fileHandler");
const { adminApiLimiter } = require("../middleware/adminRateLimiter");


router.post("/admin/booking/search", [adminAuthToken], controller.getBookingList);
router.post("/admin/booking/update", [validation(schema.bookingStatusUpdate), adminAuthToken], controller.updateBookingStatusforBookings);
router.post("/admin/booking/detail", [validation(schema.bookingId), adminAuthToken], controller.bpokingDetail);
router.get("/admin/booking/status/list", [adminAuthToken], controller.bookingStatusListing);
router.post("/admin/booking/status/update", [validation(schema.statusUpdate), adminAuthToken], controller.updateBookingStatus);
router.post("/admin/booking/status/listing/admin-page", [adminAuthToken], controller.bookingStatusListingforAdminPage);


module.exports = router;