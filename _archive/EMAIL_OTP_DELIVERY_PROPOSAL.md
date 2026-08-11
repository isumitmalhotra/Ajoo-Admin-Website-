# AajooHomes — Email / OTP Delivery: Issue Analysis & Recommended Solution

**Prepared for:** AajooHomes (Client)
**Prepared by:** Zyphex Tech
**Date:** 2026-06-06
**Subject:** Why OTP verification emails are not being delivered, and the recommended permanent fix

---

## 1. Executive Summary

The AajooHomes backend currently **cannot send OTP / verification emails** when deployed on **Render** (our current hosting provider). This is **not a bug in our code** and **not a problem with the email credentials** — it is a network restriction enforced by Render's platform.

- **Account creation, login, document upload, and the database all work correctly.**
- **Only the email delivery step fails**, because Render blocks the network ports that traditional email (SMTP) uses.
- The fix is to switch email delivery from direct SMTP to a **transactional email service** (Brevo or Resend) that sends over standard web traffic, which Render allows.
- This is a **one-time change** that works on our current setup with **no need to move servers**, and includes a **free tier** sufficient for current testing and early production volume.

A temporary developer bypass (test code `0000`) is currently enabled so that QA and testing can continue while the permanent email solution is approved and set up.

---

## 2. The Problem in Detail

### 2.1 What is happening

When a user signs up, the backend generates a One-Time Password (OTP) and attempts to email it. The server logs show:

```
[ERROR]: Error: Connection timeout
  code: 'ETIMEDOUT', command: 'CONN'
```

This means the server **cannot even open a connection** to the email server — the request times out before any email is sent.

### 2.2 Why it happens — Render blocks SMTP

Our backend sends email using **SMTP** (Simple Mail Transfer Protocol) via Gmail (`smtp.gmail.com`, port `465`). SMTP is the standard "mail server to mail server" protocol.

**Render (our host) deliberately blocks all outbound SMTP ports — 25, 465, and 587 — on every plan, including paid plans.** This is a standard anti-spam / anti-abuse policy used by most modern cloud platforms. Because the port is blocked at the network level, the email connection can never be established.

> **Important:** Upgrading to a paid Render plan will **not** fix this. The SMTP block applies to all Render services regardless of plan.

### 2.3 What this means for users

| Step | Status |
|---|---|
| Sign up / create profile | ✅ Works |
| Upload KYC document (Cloudinary) | ✅ Works |
| Save user to database | ✅ Works |
| **Receive OTP email** | ❌ **Fails (blocked by Render)** |
| Verify account | ⛔ Blocked (no OTP received) |

### 2.4 Current temporary workaround

To keep testing/QA moving, a **developer test bypass** is enabled: entering OTP `0000` verifies the account. This is controlled by an environment flag (`OTP_DEV_BYPASS`) and **will be removed** once real email delivery is live. It is a stop-gap for testing only — not a production solution.

---

## 3. The Solution: Transactional Email Service (HTTP API)

Instead of sending email via SMTP (blocked by Render), we send it through a **transactional email provider's HTTP API**, which uses standard secure web traffic (port `443`). **Port 443 is never blocked** — it is the same port used for every website — so this works on Render with **no infrastructure change**.

Transactional email services are purpose-built for exactly this use case (OTPs, password resets, notifications) and provide:

- **Reliable inbox delivery** (proper sender authentication so emails don't land in spam)
- **Scalability** (handles growth from dozens to millions of emails)
- **Analytics** (delivery, open, bounce tracking)
- **Free tiers** that cover current needs at **₹0 / $0**

We recommend two providers: **Brevo** and **Resend**.

---

## 4. Option A — Brevo (formerly Sendinblue)

**Best for:** simplest setup, no domain required to start, generous free tier.

### How it works
1. Create a free Brevo account.
2. Verify a **sender** — either a single email address (2-minute setup, no DNS needed) or your own domain (best deliverability).
3. Generate an **API key**.
4. We update the backend to send OTPs via Brevo's API.
5. Add the API key to Render's settings → done.

### Setup steps (one-time)
| Step | Who | Time |
|---|---|---|
| Create account at brevo.com | Client | 5 min |
| Verify sender email / domain | Client | 5–30 min |
| Generate API key | Client | 2 min |
| Integrate into backend | Zyphex Tech | ~1–2 hrs |
| Deploy & test real OTP | Zyphex Tech | ~30 min |

### Pricing *(approximate — verify current rates at brevo.com/pricing)*
| Plan | Price | Volume | Notes |
|---|---|---|---|
| **Free** | ₹0 / $0 | **300 emails/day** (~9,000/month) | Includes daily sending limit |
| **Starter** | ~$9–$18 / month | from 5,000 → 20,000+ emails/month | Removes daily limit; price scales with volume |
| **Business** | ~$18+ / month | higher volume + advanced features | Automation, advanced analytics |

---

## 5. Option B — Resend

**Best for:** modern, developer-friendly API; clean integration; good monthly free allowance.

### How it works
1. Create a free Resend account.
2. Verify your **domain** (add SPF/DKIM DNS records) — or use their test sender to start.
3. Generate an **API key**.
4. We update the backend to send OTPs via Resend's API.
5. Add the API key to Render's settings → done.

### Setup steps (one-time)
| Step | Who | Time |
|---|---|---|
| Create account at resend.com | Client | 5 min |
| Verify domain (DNS records) | Client | 15–30 min |
| Generate API key | Zyphex Tech / Client | 2 min |
| Integrate into backend | Zyphex Tech | ~1–2 hrs |
| Deploy & test real OTP | Zyphex Tech | ~30 min |

### Pricing *(approximate — verify current rates at resend.com/pricing)*
| Plan | Price | Volume | Notes |
|---|---|---|---|
| **Free** | ₹0 / $0 | **3,000 emails/month** (100/day) | Great for testing + early production |
| **Pro** | ~$20 / month | **50,000 emails/month** | Standard production tier |
| **Scale** | ~$90+ / month | 100,000+ emails/month | High volume |

---

## 6. Provider Comparison

| Criteria | Brevo | Resend |
|---|---|---|
| Free tier | 300/day (~9,000/mo) | 3,000/month |
| Start without owning a domain | ✅ Yes (verify single sender) | ⚠️ Limited (domain recommended) |
| Setup ease | Very easy | Very easy (developer-focused) |
| Deliverability | Strong | Strong |
| Entry paid plan | ~$9/mo | ~$20/mo (50k emails) |
| Best fit | Quick start, low volume | Clean scaling, dev-friendly |

---

## 7. Future Cost Projection (if/when paid plan is needed)

OTP/verification email is **low-volume** — typically **one or two emails per signup/login**. The free tiers comfortably cover the early stage. Below is an indicative cost as the platform grows:

| Stage | Approx. emails/month | Recommended plan | Approx. monthly cost |
|---|---|---|---|
| Testing / launch | up to ~3,000 | Brevo Free **or** Resend Free | **₹0 / $0** |
| Early growth | ~5,000–10,000 | Brevo Starter | **~$9–$18** |
| Production | ~50,000 | Resend Pro or Brevo | **~$18–$20** |
| Scale | 100,000+ | Resend Scale / **AWS SES** | **$90+** (or AWS SES ≈ $0.10 per 1,000 emails — cheapest at large scale) |

> **Note:** Pricing is indicative and may change; confirm on each provider's pricing page at the time of purchase. For very high volume, **AWS SES** is the most cost-effective (~$0.10 per 1,000 emails) but requires more setup (domain verification + production-access request).

---

## 8. About the "Buy a VPS" Option

A self-managed VPS (DigitalOcean, Hetzner, Linode, AWS EC2, etc.) **would** generally allow SMTP on ports 465/587 (unlike Render), so Gmail + nodemailer could work there. However, we **do not recommend this just to fix email** because:

- **More operational overhead** — we'd have to manage the server, uptime, SSL, deployments, and security ourselves (Render handles all of this today).
- **Gmail limits** — free Gmail caps at ~500 emails/day; not built for transactional volume.
- **Deliverability risk** — app emails via Gmail are more likely to be flagged than a dedicated email service with domain authentication.
- **Port 25 is still often blocked** even on VPS providers.

A transactional email service (Brevo/Resend) solves the problem **on our current Render setup** with better reliability and **no added server maintenance**. A VPS may make sense later for other reasons (cost at scale, full control), but it is not required to fix email.

---

## 9. Recommendation

> **Adopt a transactional email API — recommended: Brevo to start (simplest, free, no domain required), with the option to use Resend or AWS SES as volume grows.**

This is a **permanent, one-time fix** that:
- Works on our current Render hosting (no migration needed)
- Sends **real OTP emails** reliably
- Costs **₹0** at current volume (free tier)
- Scales cleanly and predictably with the business

Once live, we will **remove the temporary `0000` test bypass** so verification is fully real and secure.

---

## 10. Next Steps (Action Items)

1. **Client:** choose a provider (recommended: **Brevo**) and create a free account.
2. **Client:** verify a sender email (or domain) and generate an **API key**.
3. **Client:** share the API key and the desired "from" address (e.g., `noreply@aajoohomes.com`) with Zyphex Tech.
4. **Zyphex Tech:** integrate the provider into the backend mailer, deploy to Render, and verify a real OTP is delivered.
5. **Zyphex Tech:** remove the temporary OTP bypass and confirm end-to-end verification.

**Estimated turnaround once the API key is provided:** ~half a day.

---

## 11. Technical Appendix (for the development team)

- **Root cause:** Render blocks outbound TCP on ports 25/465/587 (SMTP) platform-wide. `nodemailer` → `smtp.gmail.com:465` therefore fails with `ETIMEDOUT (CONN)`.
- **Fix location:** `utils/mailer.js` — replace the SMTP transport (`nodemailer.createTransport`) with the provider's HTTPS API client (Brevo: `@getbrevo/brevo` or REST; Resend: `resend` SDK). All OTP/email flows already route through this single module, so it is a contained change.
- **Config:** provider API key + `MAIL_FROM` added as Render environment variables (not committed to source).
- **Cleanup:** remove the `OTP_DEV_BYPASS` env-gated bypass in `controllers/user.controller.js` after go-live.
- **Deliverability:** configure SPF + DKIM (and ideally DMARC) DNS records for the sending domain to maximize inbox placement.

---

*Document prepared by Zyphex Tech for AajooHomes. Figures are indicative as of June 2026 and should be confirmed against each provider's current pricing.*
