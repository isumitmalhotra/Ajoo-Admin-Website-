/**
 * Centralized payment-gateway credentials.
 *
 * Single source of truth for Razorpay (and any future gateway). Reads from
 * environment variables when present, falls back to the existing TEST key
 * baked in below so local dev works out of the box.
 *
 * Production (Render) MUST set these env vars:
 *   RAZORPAY_KEY_ID       = rzp_live_xxxxxxxxxxxx
 *   RAZORPAY_KEY_SECRET   = <secret from Razorpay dashboard>
 *
 * Both the order-creator (utils/razorpay.js) and the payment-link creator
 * (controllers/booking.controller.js) read from this file. Do NOT add new
 * Razorpay credential constants anywhere else.
 *
 * The publishable key (key_id) is exposed to the client app via
 * GET /config/payments (see routes/common.routes.js + controllers/
 * commonConfig.controller.js if you add a runtime config endpoint later).
 * The secret stays server-only.
 */

const FALLBACK_TEST_KEY_ID = "rzp_test_XUTODhUdMAshi6";
const FALLBACK_TEST_KEY_SECRET = "pquKHeZnpWnSJgMGiqF6EuOy";

const keyId = process.env.RAZORPAY_KEY_ID || FALLBACK_TEST_KEY_ID;
const keySecret = process.env.RAZORPAY_KEY_SECRET || FALLBACK_TEST_KEY_SECRET;

// Helpful runtime hint so it's obvious when we're using the fallback key on
// a server where env vars were forgotten. Logs once at require-time.
if (!process.env.RAZORPAY_KEY_ID) {
  console.warn(
    "[payments.config] RAZORPAY_KEY_ID env var not set — falling back to bundled TEST key. " +
    "Set RAZORPAY_KEY_ID + RAZORPAY_KEY_SECRET in your env (and Render env vars) before going live."
  );
}

module.exports = {
  razorpay: {
    keyId,
    keySecret,
    isLiveMode: keyId.startsWith("rzp_live_"),
  },
};
