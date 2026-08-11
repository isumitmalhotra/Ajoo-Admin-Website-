'use strict';
/**
 * Yup schemas for KYC /verify/* endpoints (A-12).
 * REMINDER: validation middleware strips unknown fields — declare everything.
 */
const yup = require("yup");

// POST /verify/create-session
exports.createSession = yup.object({
    context: yup.string().oneOf(["host_kyc", "guest_kyc"]).required("context is required"),
    // bookingId required only for guest_kyc — enforced in controller (yup .when keeps it simple here)
    bookingId: yup.number().integer().positive().optional().nullable(),
});

// GET /verify/status?sessionId=
exports.statusGet = yup.object({
    sessionId: yup.string().required("sessionId is required"),
});

// GET /verify/check-session/:sessionId
exports.checkSession = yup.object({
    sessionId: yup.string().required("sessionId is required"),
});
