const express = require('express');
const router = express.Router();
const bpController = require('../controllers/bp_controller');
const { generalLimiter } = require('../middleware/rateLimiter');

// ─── SESSION ──────────────────────────────────────────────────────────────────
router.post('/bp/session/start', generalLimiter, bpController.startSession);
router.post('/bp/session/get-by-phone', generalLimiter, bpController.getSessionByPhone);
router.post('/bp/session/analyze', generalLimiter, bpController.analyzeSession);

// ─── CONTEXT ─────────────────────────────────────────────────────────────────
router.post('/bp/context', generalLimiter, bpController.getContext);

// ─── LISTINGS ────────────────────────────────────────────────────────────────
router.post('/bp/listings/search', generalLimiter, bpController.searchListings);

// ─── BOOKING ─────────────────────────────────────────────────────────────────
router.post('/bp/booking/details', generalLimiter, bpController.getBookingDetails);
router.post('/bp/booking/policy', generalLimiter, bpController.getBookingPolicy);
router.post('/bp/booking/modify', generalLimiter, bpController.modifyBooking);

// ─── OTP ─────────────────────────────────────────────────────────────────────
router.post('/bp/otp/send', generalLimiter, bpController.sendOtp);
router.post('/bp/otp/verify', generalLimiter, bpController.verifyOtp);

// ─── PAYMENT ─────────────────────────────────────────────────────────────────
router.post('/bp/payment/check-transaction', generalLimiter, bpController.checkTransaction);
router.post('/bp/payment/refund-status', generalLimiter, bpController.refundStatus);

// ─── PROPERTY ────────────────────────────────────────────────────────────────
router.post('/bp/property/location', generalLimiter, bpController.propertyLocation);
router.post('/bp/property/amenities', generalLimiter, bpController.getAmenities);

// ─── DOCUMENT ────────────────────────────────────────────────────────────────
router.post('/bp/document/invoice', generalLimiter, bpController.getInvoice);

// ─── SUPPORT ─────────────────────────────────────────────────────────────────
router.post('/bp/support/housekeeping', generalLimiter, bpController.createHousekeepingRequest);
router.post('/bp/support/create-case', generalLimiter, bpController.createCase);
router.post('/bp/support/close-case', generalLimiter, bpController.closeCase);

// ─── HOST ────────────────────────────────────────────────────────────────────
router.post('/bp/host/listing', generalLimiter, bpController.hostListing);
router.post('/bp/host/calendar', generalLimiter, bpController.hostCalendar);
router.post('/bp/host/payout', generalLimiter, bpController.hostPayout);
router.post('/bp/host/analytics', generalLimiter, bpController.hostAnalytics);

// ─── SUPPORT EVENTS ───────────────────────────────────────────
router.post('/bp/support/log-event', generalLimiter, bpController.logSupportEvent);

// ─── ADMIN EXPORT ENDPOINTS (NEW) ────────────────────────────────────────────
// Protected by x-admin-token header
// GET /bp/export/leads?from=2025-01-01&to=2025-12-31&status=new
// GET /bp/export/logs?type=ticket&from=2025-01-01
router.get('/bp/export/leads', bpController.exportLeads);
router.get('/bp/export/logs', bpController.exportLogs);

router.post('/bp/host/guest-issues', generalLimiter, bpController.hostGuestIssues);

module.exports = router;
