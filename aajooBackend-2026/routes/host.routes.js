const express = require("express");
const router = express.Router();  // Initialize the router
const controller = require("../controllers/host.controller");
const commonController = require("../controllers/common.controller");
const schema = require("../schema/user.schema");
const hostSchema = require("../schema/host.schema");
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
router.get("/host/profile", generalLimiter, [hostAuthentication], controller.getHostProfile);
router.post("/host/profile/update", generalLimiter, [validation(hostSchema.updateHostProfile), hostAuthentication], controller.updateHostProfile);
router.post("/host/kyc/update", uploadLimiter, upload.single("kyc_doc"), [validation(hostSchema.updateHostKyc), hostAuthentication], controller.updateHostKyc);
router.get("/host/onboarding/status", generalLimiter, [hostAuthentication], controller.getHostOnboardingStatus);
router.post("/host/dashboard/summary", generalLimiter, [hostAuthentication], controller.getHostDashboardSummary);
router.post("/host/earnings/summary", generalLimiter, [hostAuthentication], controller.getHostEarningsSummary);
router.post("/host/earnings/list", generalLimiter, [validation(hostSchema.statementFilter), hostAuthentication], controller.getHostEarningsList);
router.post("/host/support/ticket", generalLimiter, [validation(hostSchema.supportTicketCreate), hostAuthentication], controller.createSupportTicket);
router.post("/host/support/tickets", generalLimiter, [validation(hostSchema.supportTicketList), hostAuthentication], controller.listSupportTickets);
router.post("/host/support/ticket/detail", generalLimiter, [validation(hostSchema.supportTicketDetail), hostAuthentication], controller.getSupportTicketDetail);
router.post("/host/support/ticket/status", generalLimiter, [validation(hostSchema.supportTicketStatus), hostAuthentication], controller.updateSupportTicketStatus);
router.post("/host/messages/threads", generalLimiter, [validation(hostSchema.listPagination), hostAuthentication], controller.getMessageThreads);
router.post("/host/messages/conversation", generalLimiter, [validation(hostSchema.messageUser), hostAuthentication], controller.getMessagesWithUser);
router.post("/host/messages/mark-read", generalLimiter, [validation(hostSchema.messageUser), hostAuthentication], controller.markMessagesRead);
//----------------COMMON-------------------------------





module.exports = router;  
