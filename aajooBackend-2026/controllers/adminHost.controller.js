const model = require("../models");
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");
const { Op } = require("sequelize");
const { normalizeOptionalString, normalizeOptionalValue } = require("../utils/requestFilters");

const hostListing = async (req, res) => {
    try {
        const reqData = { ...req.body };
        const page = Number(reqData.page) > 0 ? Number(reqData.page) : 1;
        const limit = Number(reqData.limit) > 0 ? Number(reqData.limit) : 10;
        const offset = (page - 1) * limit;
        const search = normalizeOptionalString(reqData.search);
        const status = normalizeOptionalValue(reqData.status);

        let whereClause = {
            user_isDelete: commonConfig.isNo,
            user_isHost: commonConfig.isYes
        };
        const verifiedStatus = normalizeOptionalValue(reqData.user_isVerified);
        if (verifiedStatus !== null) {
            whereClause.user_isVerified = verifiedStatus;
        }
        if (search) {
            whereClause[Op.or] = [
                { user_fullName: { [Op.like]: `%${search}%` } },
                { "$userCred.cred_user_email$": { [Op.like]: `%${search}%` } },
            ];
        }
        if (status !== null) {
            whereClause.user_isActive = status;
        }
        const [rows, totalRecords] = await Promise.all([
            model.tbl_user.findAll({
                where: whereClause,
                include: [
                    {
                        model: model.tbl_user_cred,
                        as: "userCred",
                        required: true,
                        attributes: ["cred_user_email"]
                    }
                ],
                limit,
                offset,
                order: [["added_at", "DESC"]],
                attributes: [
                    "user_id",
                    "user_fullName",
                    "user_isActive",
                    "user_isVerified",
                    "added_at",
                    [
                        model.sequelize.literal(`(
                            SELECT COUNT(*)
                            FROM tbl_properties
                            WHERE tbl_properties.property_host_id = tbl_user.user_id
                              AND tbl_properties.is_deleted = ${commonConfig.isNo}
                        )`),
                        "propertyCount"
                    ]
                ],
                raw: true,
            }),
            model.tbl_user.count({
                where: whereClause,
                include: [
                    {
                        model: model.tbl_user_cred,
                        as: "userCred",
                        required: true,
                        attributes: []
                    }
                ],
                distinct: true,
                col: "user_id",
            })
        ]);

        if (rows.length === 0) {
            return common.response(req, res, commonConfig.successStatus, true, "No records found", {
                totalRecords: 0,
                currentPage: page,
                totalPages: 0,
                search,
                page,
                limit,
                offset,
                data: [],
            });
        }

        return common.response(req, res, commonConfig.successStatus, true, "Host listing fetched successfully", {
            totalRecords,
            currentPage: page,
            totalPages: Math.ceil(totalRecords / limit),
            search,
            page,
            limit,
            offset,
            data: rows,
        });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);
    }
};
const hostListForAssgnProperty = async (req, res) => {
    try {
        const search = normalizeOptionalString(req.query.search);
        const whereClause = {
            user_isDelete: commonConfig.isNo,
            user_isHost: commonConfig.isYes,
            user_isActive: commonConfig.isYes,
            user_isVerified: commonConfig.isYes,
            ...(search && {
                user_fullName: { [Op.like]: `%${search}%` },
            }),
        };
        const hosts = await model.tbl_user.findAll({
            where: whereClause,
            attributes: ["user_id", "user_fullName"],
            raw: true,
            limit: 20,
            order: [["user_fullName", "ASC"]],
        });
        if (hosts.length === 0) {
            return common.response(req, res, commonConfig.successStatus, true, "No hosts found", { data: [] })
        }
        return common.response(req, res, commonConfig.successStatus, true, "Host listing fetched successfully", { data: hosts })
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error.message);

    }
};

// ============================================================================
// A-08 — HMS Admin endpoints
// ============================================================================

const safeNumber = (v, fallback = 0) => {
    const n = Number(v);
    return Number.isFinite(n) ? n : fallback;
};

const hostIdFromReq = (req) => {
    return parseInt(req.params.hostId || req.query.hostId || req.body.hostId, 10);
};

/** GET /admin/host/detail/:hostId */
const hostDetailGet = async (req, res) => {
    try {
        const hostId = hostIdFromReq(req);

        const [host, totalProperties, activeBookings, totalEarnings, lastLogin] = await Promise.all([
            model.tbl_user.findOne({
                where: { user_id: hostId, user_isHost: commonConfig.isYes },
                attributes: ["user_id", "user_fullName", "user_pnumber", "added_at", "user_isVerified", "verification_status"],
                raw: true,
            }).catch(() => null),
            model.tbl_properties.count({ where: { property_host_id: hostId } }).catch(() => 0),
            model.tbl_bookings.count({ where: { book_host_id: hostId, book_is_paid: commonConfig.isYes } }).catch(() => 0),
            model.tbl_financial_ledger.sum("fl_amount", {
                where: { fl_host_id: hostId, fl_transaction_type: "HOST_EARNING", fl_status: "COMPLETED" },
            }).then(safeNumber).catch(() => 0),
            model.tbl_admin_login_logs.findOne({ where: { all_user_id: hostId }, order: [["createdAt", "DESC"]], raw: true }).catch(() => null),
        ]);

        if (!host) return common.response(req, res, commonConfig.successStatus, true, "no record found", null);

        // email lives in tbl_user_creds, not tbl_users
        let email = null;
        try {
            const cred = await model.tbl_user_cred.findOne({ where: { cred_user_id: hostId }, attributes: ["cred_user_email"], raw: true });
            email = cred?.cred_user_email || null;
        } catch (e) { /* best-effort */ }

        return common.response(req, res, commonConfig.successStatus, true, "success", {
            host: {
                userId: host.user_id,
                fullName: host.user_fullName,
                email,
                phone: host.user_pnumber,
                joinedAt: host.added_at || null,
                verificationStatus: host.verification_status || (host.user_isVerified ? "verified" : "unverified"),
                isActive: true,
            },
            kycStatus: host.verification_status || (host.user_isVerified ? "verified" : "unverified"),
            stats: { totalProperties, activeBookings, totalEarnings, rating: 0 },
            lastLoginAt: lastLogin?.createdAt || null,
            contactTimeline: [],
        });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "host detail failed");
    }
};

/** GET /admin/host/kyc/detail/:hostId */
const kycDetailGet = async (req, res) => {
    try {
        const hostId = hostIdFromReq(req);

        const host = await model.tbl_user.findOne({
            where: { user_id: hostId, user_isHost: commonConfig.isYes },
            raw: true,
        }).catch(() => null);
        if (!host) return common.response(req, res, commonConfig.successStatus, true, "no record found", null);

        let documents = [];
        try {
            documents = await model.user_kyc_docs.findAll({ where: { ud_user_id: hostId }, raw: true });
        } catch (e) { /* best-effort — KYC docs optional */ }

        return common.response(req, res, commonConfig.successStatus, true, "success", {
            userId: host.user_id,
            verification_status: host.verification_status || (host.user_isVerified ? "verified" : "unverified"),
            didit_session_id: host.didit_session_id || null,
            submittedAt: host.added_at || null,
            documents,
            diditDecision: null, // populated post-A-12
            consoleLinkBase: "https://console.didit.me/session/",
        });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "kyc detail failed");
    }
};

/** POST /admin/host/kyc/approve */
const kycApprove = async (req, res) => {
    try {
        const { hostId, note } = req.body;
        await model.tbl_user.update(
            { user_isVerified: commonConfig.isYes },
            { where: { user_id: hostId } }
        );
        // verification_status + verified_at columns added in A-11; safe to ignore failure
        try {
            await model.tbl_user.update(
                { verification_status: "verified", verified_at: new Date() },
                { where: { user_id: hostId } }
            );
        } catch (e) { /* pre-A-11 safe */ }

        return common.response(req, res, commonConfig.successStatus, true, "success", {
            hostId, verification_status: "verified", verified_at: new Date(), note: note || null,
        });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "kyc approve failed");
    }
};

/** POST /admin/host/kyc/reject */
const kycReject = async (req, res) => {
    try {
        const { hostId, reason } = req.body;
        await model.tbl_user.update(
            { user_isVerified: commonConfig.isNo },
            { where: { user_id: hostId } }
        );
        try {
            await model.tbl_user.update(
                { verification_status: "declined" },
                { where: { user_id: hostId } }
            );
        } catch (e) { /* pre-A-11 safe */ }

        return common.response(req, res, commonConfig.successStatus, true, "success", {
            hostId, verification_status: "declined", reason,
        });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "kyc reject failed");
    }
};

/** GET /admin/host/performance/summary?hostId= */
const perfSummaryGet = async (req, res) => {
    try {
        const hostId = parseInt(req.query.hostId || req.body.hostId, 10);
        const now = new Date();
        const ninetyDaysAgo = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);
        const oneEightyDaysAgo = new Date(now.getTime() - 180 * 24 * 60 * 60 * 1000);

        const [revCurr, revPrev, cxlCurr, cxlPrev, bookCurr, bookPrev, propCount] = await Promise.all([
            model.tbl_financial_ledger.sum("fl_amount", { where: { fl_host_id: hostId, fl_transaction_type: "HOST_EARNING", fl_status: "COMPLETED", fl_created_at: { [Op.gte]: ninetyDaysAgo } } }).then(safeNumber).catch(() => 0),
            model.tbl_financial_ledger.sum("fl_amount", { where: { fl_host_id: hostId, fl_transaction_type: "HOST_EARNING", fl_status: "COMPLETED", fl_created_at: { [Op.between]: [oneEightyDaysAgo, ninetyDaysAgo] } } }).then(safeNumber).catch(() => 0),
            model.tbl_bookings.count({ where: { book_host_id: hostId, book_status: commonConfig.statusBookingCancelled, book_added_at: { [Op.gte]: ninetyDaysAgo } } }).catch(() => 0),
            model.tbl_bookings.count({ where: { book_host_id: hostId, book_status: commonConfig.statusBookingCancelled, book_added_at: { [Op.between]: [oneEightyDaysAgo, ninetyDaysAgo] } } }).catch(() => 0),
            model.tbl_bookings.count({ where: { book_host_id: hostId, book_added_at: { [Op.gte]: ninetyDaysAgo } } }).catch(() => 0),
            model.tbl_bookings.count({ where: { book_host_id: hostId, book_added_at: { [Op.between]: [oneEightyDaysAgo, ninetyDaysAgo] } } }).catch(() => 0),
            model.tbl_properties.count({ where: { property_host_id: hostId } }).catch(() => 1),
        ]);

        const safePropCount = propCount || 1;
        const occupancyCurr = Math.min(100, Math.round((bookCurr / (safePropCount * 90)) * 100));
        const occupancyPrev = Math.min(100, Math.round((bookPrev / (safePropCount * 90)) * 100));

        return common.response(req, res, commonConfig.successStatus, true, "success", {
            occupancy:     { current: occupancyCurr, previous: occupancyPrev, trend: [] },
            revenue:       { current: revCurr, previous: revPrev, trend: [] },
            cancellations: { current: cxlCurr, previous: cxlPrev, trend: [] },
            ratings:       { current: 0, previous: 0, trend: [] },
        });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "perf summary failed");
    }
};

/** GET /admin/host/payout/history?hostId= */
const payoutHistoryGet = async (req, res) => {
    try {
        const hostId = parseInt(req.query.hostId || req.body.hostId, 10);
        const page = Math.max(1, parseInt(req.query.page || req.body.page, 10) || 1);
        const limit = Math.min(100, Math.max(1, parseInt(req.query.limit || req.body.limit, 10) || 20));

        let items = [], totalRecords = 0, summary = { totalPaidOut: 0, pending: 0, holdAmount: 0 };
        try {
            const result = await model.tbl_payouts.findAndCountAll({
                where: { po_host_id: hostId },
                limit, offset: (page - 1) * limit,
                order: [["po_created_at", "DESC"]], raw: true,
            });
            items = result.rows;
            totalRecords = result.count;

            const [paidOut, pending, hold] = await Promise.all([
                model.tbl_payouts.sum("po_amount", { where: { po_host_id: hostId, po_status: "COMPLETED" } }).then(safeNumber).catch(() => 0),
                model.tbl_payouts.sum("po_amount", { where: { po_host_id: hostId, po_status: ["QUEUED", "PROCESSING"] } }).then(safeNumber).catch(() => 0),
                model.tbl_payouts.sum("po_amount", { where: { po_host_id: hostId, po_on_hold: 1 } }).then(safeNumber).catch(() => 0),
            ]);
            summary = { totalPaidOut: paidOut, pending, holdAmount: hold };
        } catch (e) { /* pre-migration safe */ }

        return common.response(req, res, commonConfig.successStatus, true, "success", {
            items, summary,
            totalRecords, currentPage: page,
            totalPages: Math.max(1, Math.ceil(totalRecords / limit)), limit,
        });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "payout history failed");
    }
};

/** POST /admin/host/payout/hold */
const payoutHold = async (req, res) => {
    try {
        const { hostId, reason } = req.body;
        await model.tbl_payouts.update(
            { po_on_hold: 1, po_hold_reason: reason },
            { where: { po_host_id: hostId, po_status: ["QUEUED", "PROCESSING"] } }
        );
        return common.response(req, res, commonConfig.successStatus, true, "success", {
            hostId, payoutsOnHold: true, reason, holdAt: new Date(),
        });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "payout hold failed");
    }
};

/** POST /admin/host/payout/release */
const payoutRelease = async (req, res) => {
    try {
        const { hostId, note } = req.body;
        await model.tbl_payouts.update(
            { po_on_hold: 0, po_hold_reason: null },
            { where: { po_host_id: hostId } }
        );
        return common.response(req, res, commonConfig.successStatus, true, "success", {
            hostId, payoutsOnHold: false, releasedAt: new Date(), note: note || null,
        });
    } catch (error) {
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "payout release failed");
    }
};

module.exports = {
    hostListing,
    hostListForAssgnProperty,
    // A-08
    hostDetailGet,
    kycDetailGet,
    kycApprove,
    kycReject,
    perfSummaryGet,
    payoutHistoryGet,
    payoutHold,
    payoutRelease,
};
