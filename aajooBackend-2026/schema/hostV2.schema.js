'use strict';
/**
 * Yup schemas for hostV2 (new HMS host portal endpoints under /host/*).
 * Sprint: Full Delivery 2026-06-09..18 (A-07).
 *
 * REMINDER: validation middleware strips unknown fields (stripUnknown: true).
 * Declare every field the controller reads, including URL params via req.params.
 */
const yup = require("yup");

const TICKET_CATEGORIES = ["PAYOUT", "BOOKING", "PROFILE", "GENERAL", "OTHER"];
const TICKET_STATUSES = ["OPEN", "PENDING", "RESOLVED", "CLOSED"];

const paged = {
    page: yup.number().integer().min(1).optional().default(1),
    limit: yup.number().integer().min(1).max(100).optional().default(20),
};

// GET /host/dashboard/summary — no body
exports.dashboardSummary = yup.object({});

// POST /host/bookings/search
exports.bookingsSearch = yup.object({
    ...paged,
    search: yup.string().optional().nullable(),
    status: yup.string().optional().nullable(),
    dateFrom: yup.string().optional().nullable(),
    dateTo: yup.string().optional().nullable(),
});

// GET /host/bookings/detail/:bookingId
exports.bookingDetail = yup.object({
    bookingId: yup.number().integer().positive().required("bookingId is required"),
});

// GET /host/earnings/summary
exports.earningsSummary = yup.object({});

// GET /host/payout/history
exports.payoutHistory = yup.object({
    ...paged,
});

// GET /host/profile/get
exports.profileGet = yup.object({});

// PUT /host/profile/update
exports.profileUpdate = yup.object({
    fullName: yup.string().min(2).max(100).optional().nullable(),
    email: yup.string().email().optional().nullable(),
    phone: yup.string().matches(/^\d{10}$/, "phone must be 10 digits").optional().nullable(),
    address: yup.string().max(500).optional().nullable(),
    city: yup.string().max(100).optional().nullable(),
    state: yup.string().max(100).optional().nullable(),
    country: yup.string().max(100).optional().nullable(),
});

// GET /host/payout-account/get
exports.payoutAccountGet = yup.object({});

// PUT /host/payout-account/update
exports.payoutAccountUpdate = yup.object({
    accountNumber: yup.string().min(6).max(32).optional().nullable(),
    confirmAccountNumber: yup.string().optional().nullable(),
    ifsc: yup.string().matches(/^[A-Z]{4}0[A-Z0-9]{6}$/, "Invalid IFSC code").optional().nullable(),
    accountHolderName: yup.string().min(2).max(100).optional().nullable(),
    upiId: yup.string().max(100).optional().nullable(),
});

// POST /host/statements/search
exports.statementsSearch = yup.object({
    ...paged,
    year: yup.number().integer().optional().nullable(),
    month: yup.number().integer().min(1).max(12).optional().nullable(),
});

// GET /host/statements/download/:statementId  (statementId = "YYYY-MM" or numeric)
exports.statementsDownload = yup.object({
    statementId: yup.string().required("statementId is required"),
});

// POST /host/support/tickets/search
exports.ticketSearch = yup.object({
    ...paged,
    status: yup.string().oneOf([...TICKET_STATUSES, null]).optional().nullable(),
    category: yup.string().oneOf([...TICKET_CATEGORIES, null]).optional().nullable(),
    dateFrom: yup.string().optional().nullable(),
    dateTo: yup.string().optional().nullable(),
});

// POST /host/support/tickets/create
exports.ticketCreate = yup.object({
    subject: yup.string().required("subject is required").min(3).max(255),
    category: yup.string().oneOf(TICKET_CATEGORIES).required("category is required"),
    message: yup.string().required("message is required").min(10).max(5000),
});

// POST /host/support/tickets/reply
exports.ticketReply = yup.object({
    ticketId: yup.number().integer().positive().required("ticketId is required"),
    message: yup.string().required("message is required").min(1).max(5000),
});

// GET /host/performance/summary
exports.performanceSummary = yup.object({
    dateFrom: yup.string().optional().nullable(),
    dateTo: yup.string().optional().nullable(),
});

// POST /host/onboarding/submit
exports.onboardingSubmit = yup.object({
    propertyType: yup.string().required("propertyType is required").max(100),
    city: yup.string().required("city is required").max(100),
    state: yup.string().required("state is required").max(100),
    country: yup.string().required("country is required").max(100),
    hostingExperience: yup.string().required("hostingExperience is required").max(255),
    contactName: yup.string().required("contactName is required").max(255),
    contactPhone: yup.string().matches(/^\d{10}$/, "phone must be 10 digits").required("contactPhone is required"),
    message: yup.string().optional().nullable().max(5000),
});
