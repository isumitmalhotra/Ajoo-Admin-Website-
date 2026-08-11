'use strict';
/**
 * Single source of truth for email/transactional-mail configuration.
 * Sprint: Full Delivery 2026-06-09..18 (A-10).
 *
 * Mirrors the PAY-02 pattern: env-var driven with safe fallbacks so behaviour
 * is identical to today until you set the env vars in Render.
 *
 * Provider selection logic (see utils/mailer.js):
 *   - If BREVO_API_KEY is set  -> send via Brevo HTTP API (port 443, Render-friendly).
 *   - Else                     -> fall back to nodemailer SMTP (legacy; blocked on Render,
 *                                 works locally / on SMTP-capable hosts).
 *
 * To go live on Render (which blocks outbound SMTP 25/465/587):
 *   1. Create a Brevo account, verify sender domain (SPF/DKIM).
 *   2. Render Dashboard -> Environment -> set:
 *        BREVO_API_KEY=xkeysib-...
 *        MAIL_FROM=no-reply@aajoohomes.com   (a verified sender)
 *        MAIL_FROM_NAME=Aajoo Homes
 *   3. Restart. Boot log should show "Mail transport: BREVO_HTTP".
 *      No code change required.
 */

const brevoApiKey = process.env.BREVO_API_KEY || null;

// "from" address. Falls back to the legacy Gmail sender (db.config mailEmail)
// only if neither MAIL_FROM nor that legacy value is available — resolved in mailer.js.
const mailFrom = process.env.MAIL_FROM || null;
const mailFromName = process.env.MAIL_FROM_NAME || "Aajoo Homes";

// Provider switch
const useBrevoHttp = Boolean(brevoApiKey);

module.exports = {
    // Brevo HTTP API
    brevo: {
        apiKey: brevoApiKey,
        endpoint: process.env.BREVO_API_URL || "https://api.brevo.com/v3/smtp/email",
    },
    // Shared "from"
    from: {
        email: mailFrom,        // may be null -> mailer.js falls back to legacy SMTP user
        name: mailFromName,
    },
    // Which transport to use
    useBrevoHttp,
    // Helpful boolean for boot logging
    transportLabel: useBrevoHttp ? "BREVO_HTTP" : "SMTP_FALLBACK",
};
