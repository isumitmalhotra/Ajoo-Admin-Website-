'use strict';
/**
 * Yup schemas for /admin/host/* HMS admin endpoints (A-08).
 * Separate file from existing adminUser.schema.js (which has hostSearchSchema etc).
 *
 * REMINDER: validation middleware merges body + params + query then strips
 * unknown fields. Declare every URL param + query field used.
 */
const yup = require("yup");

// GET /admin/host/detail/:hostId
exports.hostDetailGet = yup.object({
    hostId: yup.number().integer().positive().required("hostId is required"),
});

// GET /admin/host/kyc/detail/:hostId
exports.kycDetailGet = yup.object({
    hostId: yup.number().integer().positive().required("hostId is required"),
});

// POST /admin/host/kyc/approve
exports.kycApprove = yup.object({
    hostId: yup.number().integer().positive().required("hostId is required"),
    note: yup.string().optional().nullable().max(500),
});

// POST /admin/host/kyc/reject
exports.kycReject = yup.object({
    hostId: yup.number().integer().positive().required("hostId is required"),
    reason: yup.string().required("reason is required").min(10, "reason must be >= 10 chars").max(500),
});

// GET /admin/host/performance/summary?hostId=
exports.perfSummaryGet = yup.object({
    hostId: yup.number().integer().positive().required("hostId is required"),
    dateFrom: yup.string().optional().nullable(),
    dateTo: yup.string().optional().nullable(),
});

// GET /admin/host/payout/history?hostId=
exports.payoutHistoryGet = yup.object({
    hostId: yup.number().integer().positive().required("hostId is required"),
    page: yup.number().integer().min(1).optional().default(1),
    limit: yup.number().integer().min(1).max(100).optional().default(20),
});

// POST /admin/host/payout/hold
exports.payoutHold = yup.object({
    hostId: yup.number().integer().positive().required("hostId is required"),
    reason: yup.string().required("reason is required").min(10).max(500),
});

// POST /admin/host/payout/release
exports.payoutRelease = yup.object({
    hostId: yup.number().integer().positive().required("hostId is required"),
    note: yup.string().optional().nullable().max(500),
});
