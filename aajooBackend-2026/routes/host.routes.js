const express = require("express");
const router = express.Router();  // Initialize the router
const controller = require("../controllers/host.controller");
const commonController = require("../controllers/common.controller");
const schema = require("../schema/user.schema");
const validation = require("../middleware/validation");
const { hostAuthentication } = require("../middleware/authorization");
const { upload } = require("../utils/fileHandler");
const { generalLimiter, uploadLimiter } = require("../middleware/rateLimiter");

router.post("/host/confirm-book", generalLimiter, [validation(schema.confirmBook), hostAuthentication], controller.confirmBooking);
router.post("/booking/ongoing-host", generalLimiter, [hostAuthentication], controller.getOngoingBook);
router.post("/host/property-search", generalLimiter, [hostAuthentication], controller.hostProperties);
router.post("/host/property/update-status", generalLimiter, [validation(schema.updateStatus), hostAuthentication], controller.updatePropertySatatus);
router.post("/host/delete-property", generalLimiter, [validation(schema.propertyId), hostAuthentication], controller.deleteProperty);
router.post("/host/update-property-cover", uploadLimiter, upload.single("property_cover"), [validation(schema.propertyId), hostAuthentication], controller.updatePropertyCoverImage);
router.post("/host/booking-history", generalLimiter, [hostAuthentication], controller.hostBookingHistory);
router.post("/host/transaction-history", generalLimiter, [hostAuthentication], controller.hostTransactionHistory);
//----------------COMMON-------------------------------





module.exports = router; 