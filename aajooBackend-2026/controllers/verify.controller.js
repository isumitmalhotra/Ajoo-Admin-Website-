'use strict';
/**
 * Controller: KYC verification (/verify/*) + Didit webhook.
 * Sprint: Full Delivery 2026-06-09..18 (A-12).
 *
 * Gates:
 *   - Host: property cannot go live (property_kyc_status = 'active') until host
 *     verification_status = 'verified'.
 *   - Guest: booking cannot confirm until guest verified, OR skipped if the user
 *     was verified within the last KYC_VALIDITY_DAYS (default 90).
 */
const models = require("../models");
const common = require("../utils/common");
const commonConfig = require("../config/commonConfig");
const logger = require("../utils/logger");
const diditClient = require("../utils/diditClient");
const kycConfig = require("../config/kyc.config");

const userIdFromReq = (req) => req.user?.userId || req.user?.user_id || null;

/**
 * Should we skip verification? True if the user verified within validity window.
 */
async function shouldSkipVerification(userId) {
    try {
        const user = await models.tbl_user.findOne({
            where: { user_id: userId },
            attributes: ["verification_status", "verified_at", "verification_expires_at"],
            raw: true,
        });
        if (!user) return false;
        if (user.verification_status !== "verified") return false;

        // expiry column wins if present
        if (user.verification_expires_at) {
            return new Date(user.verification_expires_at) > new Date();
        }
        if (user.verified_at) {
            const ageMs = Date.now() - new Date(user.verified_at).getTime();
            const validMs = kycConfig.verificationValidityDays * 24 * 60 * 60 * 1000;
            return ageMs < validMs;
        }
        return false;
    } catch (e) {
        return false;
    }
}

/**
 * POST /verify/create-session
 */
exports.createSession = async (req, res) => {
    try {
        const userId = userIdFromReq(req);
        if (!userId) return common.response(req, res, 401, false, "auth required");

        const { context, bookingId } = req.body;
        const isHost = context === "host_kyc";

        if (!isHost && !bookingId) {
            return common.response(req, res, commonConfig.errorStatus, false, "bookingId is required for guest_kyc");
        }

        // 90-day skip for guests (and hosts) already verified
        const skip = await shouldSkipVerification(userId);
        if (skip) {
            return common.response(req, res, commonConfig.successStatus, true, "success", {
                sessionId: null,
                sessionUrl: null,
                status: "verified",
                skipReason: "verified_within_validity_window",
            });
        }

        const vendorData = isHost ? `host_${userId}` : `guest_${userId}_booking_${bookingId}`;
        const { sessionId, sessionUrl, stub } = await diditClient.createSession({
            context: isHost ? "host" : "guest",
            vendorData,
        });

        // Persist session id + set status pending
        if (isHost) {
            await models.tbl_user.update(
                { didit_session_id: sessionId, verification_status: "pending" },
                { where: { user_id: userId } }
            ).catch((e) => logger.warn("createSession host persist failed", { error: e?.message }));
        } else {
            await models.tbl_bookings.update(
                { guest_didit_session_id: sessionId, guest_verification_status: "pending" },
                { where: { book_pri_id: bookingId } }
            ).catch((e) => logger.warn("createSession booking persist failed", { error: e?.message }));
            // also reflect pending on the user record for skip logic
            await models.tbl_user.update(
                { didit_session_id: sessionId, verification_status: "pending" },
                { where: { user_id: userId } }
            ).catch(() => null);
        }

        return common.response(req, res, commonConfig.successStatus, true, "success", {
            sessionId,
            sessionUrl,
            vendorData,
            stub: !!stub,
            expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
        });
    } catch (error) {
        logger.error("createSession failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "create session failed");
    }
};

/**
 * GET /verify/status?sessionId=
 * Returns our DB verification_status (FE polls this).
 */
exports.getStatus = async (req, res) => {
    try {
        const sessionId = req.query.sessionId || req.body.sessionId;

        // Look up by session id on user first, then booking
        let status = "unverified", verifiedAt = null, expiresAt = null, skipReason = null;

        const user = await models.tbl_user.findOne({
            where: { didit_session_id: sessionId },
            attributes: ["verification_status", "verified_at", "verification_expires_at"],
            raw: true,
        }).catch(() => null);

        if (user) {
            status = user.verification_status;
            verifiedAt = user.verified_at;
            expiresAt = user.verification_expires_at;
        } else {
            const booking = await models.tbl_bookings.findOne({
                where: { guest_didit_session_id: sessionId },
                attributes: ["guest_verification_status"],
                raw: true,
            }).catch(() => null);
            if (booking) status = booking.guest_verification_status;
        }

        return common.response(req, res, commonConfig.successStatus, true, "success", {
            sessionId, status, verifiedAt, expiresAt, skipReason,
        });
    } catch (error) {
        logger.error("getStatus failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "status failed");
    }
};

/**
 * GET /verify/check-session/:sessionId
 * Polling fallback — calls Didit decision endpoint directly, then applies it.
 */
exports.checkSession = async (req, res) => {
    try {
        const sessionId = req.params.sessionId;
        const decision = await diditClient.getDecision(sessionId);
        if (!decision) {
            // fall back to our stored status
            return exports.getStatus({ ...req, query: { sessionId }, body: {} }, res);
        }

        const outcome = mapDiditStatus(decision.status || decision.decision);
        await applyDecision(sessionId, outcome, decision);

        return common.response(req, res, commonConfig.successStatus, true, "success", {
            sessionId, status: outcome, source: "poll",
        });
    } catch (error) {
        logger.error("checkSession failed", { error: error?.message });
        return common.response(req, res, commonConfig.errorStatus, false, error?.message || "check session failed");
    }
};

/**
 * POST /webhooks/didit
 * NO auth middleware — verified via HMAC over raw body instead.
 * Mounted with the global express.json verify callback capturing req.rawBody.
 */
exports.webhook = async (req, res) => {
    try {
        const signature = req.headers["x-signature"] || req.headers["x-signature-v2"];
        const ok = diditClient.verifyWebhookSignature(req.rawBody, signature);
        if (!ok) {
            logger.warn("Didit webhook signature verification FAILED");
            return res.status(401).json({ received: false, reason: "invalid signature" });
        }

        const body = req.body || {};
        const sessionId = body.session_id || body.sessionId || body.id;
        const rawStatus = body.status || body.decision?.status;
        const outcome = mapDiditStatus(rawStatus);

        logger.info("Didit webhook received", { sessionId, rawStatus, outcome });

        await applyDecision(sessionId, outcome, body);

        // Always 200 so Didit doesn't retry a successfully-processed event
        return res.status(200).json({ received: true });
    } catch (error) {
        logger.error("Didit webhook handler failed", { error: error?.message });
        // 200 anyway to avoid infinite retries on a bug; logged for investigation
        return res.status(200).json({ received: true, note: "processed with error" });
    }
};

// ── Helpers ────────────────────────────────────────────────────────────────

function mapDiditStatus(s) {
    const v = String(s || "").toLowerCase();
    if (["approved", "verified", "success"].includes(v)) return "verified";
    if (["declined", "rejected", "failed"].includes(v)) return "declined";
    if (["in_review", "review", "in review", "pending_review"].includes(v)) return "in_review";
    return "pending";
}

/**
 * Apply a terminal/intermediate decision to our DB + side effects.
 */
async function applyDecision(sessionId, outcome, payload) {
    if (!sessionId) return;

    // Resolve which entity this session belongs to
    const user = await models.tbl_user.findOne({ where: { didit_session_id: sessionId }, raw: true }).catch(() => null);
    const booking = await models.tbl_bookings.findOne({ where: { guest_didit_session_id: sessionId }, raw: true }).catch(() => null);

    if (outcome === "verified") {
        await handleApproved({ user, booking, sessionId });
    } else if (outcome === "declined") {
        await handleDeclined({ user, booking, sessionId });
    } else if (outcome === "in_review") {
        await handleInReview({ user, booking, sessionId });
    } else {
        // pending — just reflect it
        if (user) await models.tbl_user.update({ verification_status: "pending" }, { where: { user_id: user.user_id } }).catch(() => null);
        if (booking) await models.tbl_bookings.update({ guest_verification_status: "pending" }, { where: { book_pri_id: booking.book_pri_id } }).catch(() => null);
    }
}

async function handleApproved({ user, booking, sessionId }) {
    const now = new Date();
    const expires = new Date(now.getTime() + kycConfig.verificationValidityDays * 24 * 60 * 60 * 1000);

    if (user) {
        await models.tbl_user.update(
            { verification_status: "verified", user_isVerified: commonConfig.isYes, verified_at: now, verification_expires_at: expires },
            { where: { user_id: user.user_id } }
        ).catch(() => null);

        // Host gate: flip their pending_verification properties to active
        await models.tbl_properties.update(
            { property_kyc_status: "active" },
            { where: { property_host: user.user_id, property_kyc_status: "pending_verification" } }
        ).catch(() => null);

        await writeNotification("HOST", user.user_id, "KYC", "Identity verified", "Your identity verification was approved. Your listings are now live.");
    }

    if (booking) {
        await models.tbl_bookings.update(
            { guest_verification_status: "verified" },
            { where: { book_pri_id: booking.book_pri_id } }
        ).catch(() => null);
        // Guest gate: mark booking confirmable (status paid/confirm path handled elsewhere)
        await writeNotification("GUEST", booking.book_user_id, "KYC", "Identity verified", "Your identity is verified. You can complete your booking.");
    }
}

async function handleDeclined({ user, booking, sessionId }) {
    if (user) {
        await models.tbl_user.update(
            { verification_status: "declined", user_isVerified: commonConfig.isNo },
            { where: { user_id: user.user_id } }
        ).catch(() => null);
        await raiseFlag(user.user_id, sessionId, "KYC_DECLINED", "HOST");
    }
    if (booking) {
        await models.tbl_bookings.update(
            { guest_verification_status: "declined" },
            { where: { book_pri_id: booking.book_pri_id } }
        ).catch(() => null);
        await raiseFlag(booking.book_user_id, sessionId, "KYC_DECLINED", "GUEST");
    }
}

async function handleInReview({ user, booking, sessionId }) {
    if (user) {
        await models.tbl_user.update({ verification_status: "in_review" }, { where: { user_id: user.user_id } }).catch(() => null);
        await raiseFlag(user.user_id, sessionId, "KYC_IN_REVIEW", "HOST");
    }
    if (booking) {
        await models.tbl_bookings.update({ guest_verification_status: "in_review" }, { where: { book_pri_id: booking.book_pri_id } }).catch(() => null);
        await raiseFlag(booking.book_user_id, sessionId, "KYC_IN_REVIEW", "GUEST");
    }
    // Admin notification so the in_review item surfaces in the admin queue (A-14)
    const subjectId = user?.user_id || booking?.book_user_id || null;
    await writeNotification("ADMIN", null, "KYC", "KYC needs review",
        `A verification (session ${sessionId}, user ${subjectId}) is in review and needs an admin decision.`, "/admin/host");
}

async function raiseFlag(userId, sessionId, flagType, role) {
    try {
        await models.tbl_admin_flags.create({
            af_user_id: userId,
            af_session_id: sessionId,
            af_flag_type: flagType,
            af_subject_role: role,
            af_resolved: commonConfig.isNo,
        });
    } catch (e) {
        logger.warn("raiseFlag failed", { error: e?.message });
    }
}

async function writeNotification(role, recipientId, category, title, body, linkPath = null) {
    // Uses the A-14 notify() helper (fire-and-forget, never throws).
    try {
        if (!models.tbl_notifications) return;
        await models.tbl_notifications.notify({ role, recipientId, category, title, body, linkPath });
    } catch (e) {
        // notifications table not present yet — ignore
    }
}

// Export helpers for reuse/testing
exports.shouldSkipVerification = shouldSkipVerification;
exports._applyDecision = applyDecision;
