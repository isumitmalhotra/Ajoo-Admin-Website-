'use strict';
/**
 * Didit API client + webhook HMAC verification.
 * Sprint: Full Delivery 2026-06-09..18 (A-12).
 *
 * Env-gated via config/kyc.config.js. When Didit is not configured, createSession
 * returns a deterministic stub so local/dev flows don't crash (the controller
 * marks status 'pending' and the FE shows the pending screen; real decisions
 * only arrive via webhook once creds are live).
 */
const crypto = require("crypto");
const axios = require("axios");
const kycConfig = require("../config/kyc.config");
const logger = require("./logger");

/**
 * Create a Didit verification session.
 * @param {Object} params
 * @param {"host"|"guest"} params.context
 * @param {string} params.vendorData  e.g. "host_22" or "guest_301_booking_4101"
 * @returns {Promise<{sessionId:string, sessionUrl:string, stub:boolean}>}
 */
async function createSession({ context, vendorData }) {
    const workflowId = context === "host" ? kycConfig.hostWorkflowId : kycConfig.guestWorkflowId;

    if (!kycConfig.isConfigured) {
        // Dev/stub mode — no creds yet. Return a deterministic fake session so the
        // FE flow is testable end-to-end except the real Didit redirect.
        const stubId = `stub_${context}_${Date.now()}`;
        logger.warn("Didit not configured — returning stub session", { context, vendorData });
        return {
            sessionId: stubId,
            sessionUrl: `${kycConfig.returnUrl}?stub=1&session_id=${stubId}`,
            stub: true,
        };
    }

    const resp = await axios.post(
        kycConfig.sessionEndpoint,
        {
            workflow_id: workflowId,
            vendor_data: vendorData,
            callback: kycConfig.returnUrl,
        },
        {
            headers: {
                "x-api-key": kycConfig.apiKey,
                "Content-Type": "application/json",
                accept: "application/json",
            },
            timeout: 12000,
        }
    );

    return {
        sessionId: resp?.data?.session_id || resp?.data?.id,
        sessionUrl: resp?.data?.url || resp?.data?.session_url,
        stub: false,
    };
}

/**
 * Poll a session's decision (fallback when webhook hasn't arrived).
 * @returns {Promise<Object|null>} raw decision payload or null
 */
async function getDecision(sessionId) {
    if (!kycConfig.isConfigured || String(sessionId).startsWith("stub_")) {
        return null;
    }
    try {
        const resp = await axios.get(kycConfig.decisionEndpoint(sessionId), {
            headers: { "x-api-key": kycConfig.apiKey, accept: "application/json" },
            timeout: 12000,
        });
        return resp?.data || null;
    } catch (error) {
        logger.error("Didit getDecision failed", { sessionId, error: error?.message });
        return null;
    }
}

/**
 * Verify the webhook HMAC signature.
 * Didit signs the RAW request body with HMAC-SHA256 using the webhook secret.
 * The signature arrives in the `x-signature` header (hex).
 *
 * @param {Buffer|string} rawBody  the unparsed request body
 * @param {string} signatureHeader value of x-signature header
 * @returns {boolean}
 */
function verifyWebhookSignature(rawBody, signatureHeader) {
    if (!kycConfig.webhookSecret) {
        // No secret configured — in dev we accept (stub mode). In prod, set the secret.
        logger.warn("DIDIT_WEBHOOK_SECRET not set — skipping signature verification (dev only)");
        return true;
    }
    if (!rawBody || !signatureHeader) return false;

    const payload = Buffer.isBuffer(rawBody) ? rawBody : Buffer.from(rawBody, "utf8");
    const expected = crypto
        .createHmac("sha256", kycConfig.webhookSecret)
        .update(payload)
        .digest("hex");

    // Normalize possible "sha256=..." prefix
    const provided = String(signatureHeader).replace(/^sha256=/i, "").trim();

    try {
        const a = Buffer.from(expected, "hex");
        const b = Buffer.from(provided, "hex");
        if (a.length !== b.length) return false;
        return crypto.timingSafeEqual(a, b);
    } catch (e) {
        return false;
    }
}

module.exports = {
    createSession,
    getDecision,
    verifyWebhookSignature,
};
