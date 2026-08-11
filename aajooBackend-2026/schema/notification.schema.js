'use strict';
/**
 * Yup schemas for notification endpoints (A-14).
 */
const yup = require("yup");

const CATEGORIES = ["BOOKING", "USER", "HOST", "PAYOUT", "KYC", "SYSTEM"];

// GET /admin/notifications/search + /host/notifications/search
exports.search = yup.object({
    page: yup.number().integer().min(1).optional().default(1),
    limit: yup.number().integer().min(1).max(100).optional().default(20),
    category: yup.string().oneOf([...CATEGORIES, null]).optional().nullable(),
    unreadOnly: yup.boolean().optional().default(false),
});

// PUT /admin/notifications/:id/read + /host/notifications/:id/read
exports.markRead = yup.object({
    id: yup.number().integer().positive().required("id is required"),
});
