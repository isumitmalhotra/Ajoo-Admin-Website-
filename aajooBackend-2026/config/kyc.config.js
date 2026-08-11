'use strict';
/**
 * Single source of truth for Didit KYC configuration.
 * Sprint: Full Delivery 2026-06-09..18 (A-12).
 *
 * Mirrors PAY-02 / mail.config pattern — fully env-var driven. Code ships now;
 * live testing happens once Sumit sets these in Render:
 *   DIDIT_API_KEY          (Business Console → API & Webhooks)
 *   DIDIT_WEBHOOK_SECRET   (Business Console → Webhooks)
 *   DIDIT_HOST_WORKFLOW_ID (published host-kyc-v1 workflow id)
 *   DIDIT_GUEST_WORKFLOW_ID(published guest-kyc-v1 workflow id)
 *   DIDIT_BASE_URL         (default https://verification.didit.me)
 *   APP_VERIFY_RETURN_URL  (where Didit redirects after session, e.g. https://app/verify/complete)
 *
 * isConfigured = true only when API key + both workflow ids exist.
 */

const apiKey = process.env.DIDIT_API_KEY || null;
const webhookSecret = process.env.DIDIT_WEBHOOK_SECRET || null;
const hostWorkflowId = process.env.DIDIT_HOST_WORKFLOW_ID || null;
const guestWorkflowId = process.env.DIDIT_GUEST_WORKFLOW_ID || null;
const baseUrl = process.env.DIDIT_BASE_URL || "https://verification.didit.me";
const returnUrl = process.env.APP_VERIFY_RETURN_URL || "http://localhost:5173/verify/complete";

// Verifications are valid for 90 days (guest skip logic).
const verificationValidityDays = Number(process.env.KYC_VALIDITY_DAYS || 90);

module.exports = {
    apiKey,
    webhookSecret,
    hostWorkflowId,
    guestWorkflowId,
    baseUrl,
    returnUrl,
    verificationValidityDays,
    sessionEndpoint: `${baseUrl}/v2/session/`,
    decisionEndpoint: (sessionId) => `${baseUrl}/v2/session/${sessionId}/decision/`,
    isConfigured: Boolean(apiKey && hostWorkflowId && guestWorkflowId),
};
