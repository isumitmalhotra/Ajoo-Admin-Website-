# KYC / Identity Verification — Didit Integration (Aajoo Homes)

> **Status: 🔴 TOP PRIORITY — build ASAP.** Tracked in `MASTER_TASK_TRACKER.md § Section K`.
> **Source of truth (full brief + code samples):** `Aajoo_Homes_Didit_KYC_Integration_Brief.docx` (parent folder), prepared by Ishaan Garg, Zyphex Tech.
> **This file** = the *adapted* engineering plan for our actual stack + the task breakdown. Read the `.docx` for the verbatim code samples; read this for how it maps onto Aajoo's MySQL/Sequelize backend, Flutter app, and React web/admin.
> **Last updated:** 2026-06-08

---

## 1. What we're building

Integrate **Didit** identity verification (document scan + passive liveness + face match + IP analysis) into Aajoo Homes across **all three frontends + backend + admin**. Two hard gates:

- **Gate 1 — Host verification:** triggered when a host submits a new property listing. **Property must NOT go live until the host's KYC is `Approved`.**
- **Gate 2 — Guest verification:** triggered when a guest taps *Confirm Booking*. **Booking must NOT confirm until the guest's KYC is `Approved`** (or a 24h hold window — *confirm policy with client*). Skip re-verification if the guest verified within the last **90 days**.

**Free tier:** 500 full KYC verifications/month, no card. Covers dev + early prod (sub-30 properties). Beyond: $0.33/bundle.

**Didit Business Console (already provisioned):**
`https://business.didit.me/console/5de72dc5-c39e-4cbe-a0fe-b5ab001ac8d3/5496ef81-773f-4455-9c96-faa7e659572f`

---

## 2. ⚠️ Stack adaptation notes (READ — the brief is written for a different stack)

The brief's samples assume **PostgreSQL** + generic Express + a React web app. Our reality:

| Brief assumes | Aajoo reality | What changes |
|---|---|---|
| PostgreSQL (`users`, `bookings`, `properties`, `admin_flags`) | **MySQL via Sequelize**, snake_case `tbl_user`, `tbl_bookings`, `tbl_property`, models in `aajooBackend-2026/models/` | Schema changes become **Sequelize migrations** (`migrations/`), not raw `ALTER TABLE`. New `tbl_admin_flags` model + migration. |
| Raw `db.query(...)` | Sequelize models + `controllers/*.controller.js` returning via `common.response(req,res,...)` | Rewrite handlers in our controller style. |
| `redirect_url: https://aajoo homes.com/...` (note stray space) | Web app served from our host; backend live at `https://aajaodev.onrender.com` | Use real URLs. `callback_url`/webhook → `https://aajaodev.onrender.com/webhooks/didit`. |
| Webhook needs public HTTPS | **Render already gives us this** (`aajaodev.onrender.com`) | No ngrok needed in prod. **Cloudflare WAF IP-whitelist step (`18.203.201.92`) is N/A** unless we put Cloudflare in front. |
| `express.raw()` for webhook body | Our `app.js` uses global `express.json()` | **Must mount the `/webhooks/didit` route with `express.raw({type:'application/json'})` BEFORE/around the global json parser** so the HMAC (`x-signature-v2`) is computed over the raw body. This is the #1 footgun. |
| Schema validation | Our backend uses **Yup `stripUnknown`** | Any new request field must be added to the relevant `schema/*.js` or it's silently dropped. |
| Single backend | **Two backend repos share one DB** (ours `aajooBackend-2026` = source of truth; Render auto-deploys from `nameeshPatiyal100/aajaoBackend`). DB is shared. | **Coordinate migrations** (guardrail #6 in master tracker). Don't run destructive migrations unilaterally. |

**Mobile:** Flutter SDK `didit_flutter_sdk` (pub.dev) embeds the full verification UI natively (no WebView). ⚠️ **Verify the package actually exists + its current API** before committing to it — the brief says "search pub.dev for latest"; if it's unavailable/immature, fall back to the hosted `session_url` opened via in-app browser/WebView.

**Secrets:** follow the established env-gated pattern (cf. PAY-02 / CLEAN-05). Never hardcode the API key / webhook secret / workflow IDs.

---

## 3. Environment variables (backend)

```
DIDIT_API_KEY=...
DIDIT_WEBHOOK_SECRET=...
DIDIT_BASE_URL=https://verification.didit.me
DIDIT_HOST_WORKFLOW_ID=...     # from published host-kyc-v1 workflow
DIDIT_GUEST_WORKFLOW_ID=...    # from published guest-kyc-v1 workflow
```
Set in `aajooBackend-2026/.env` + `.env.example` (documented, no real values) and in the **Render dashboard**. Auth header on every Didit call: `x-api-key: $DIDIT_API_KEY`.

---

## 4. Five session outcomes → required behaviour

| Status | System action |
|---|---|
| **Approved** | Unlock listing / confirm booking. Set `verified_at`. |
| **Declined** | Block. Show reason. Allow retry of the failed step only. |
| **In Review** | Hold as pending. Flag in admin queue (`tbl_admin_flags`). |
| **Abandoned** | Session timed out → allow fresh restart. |
| **Expired** | 90-day validity lapsed → auto-trigger re-verification. |

**Never unlock on the SDK `onSuccess` callback** — that only means the user finished the flow. Approval comes **only via the webhook** (async). Show a "submitted, under review" state in between.

---

## 5. Eight UI states (build for BOTH app + web)

Not verified · Verification in progress · Submitted/awaiting result · Approved · Declined (+retry) · In Review · Already verified (green badge, skip gate) · Expired (re-verify).

---

## 6. Admin dashboard addition

A **Verification Queue** view listing all `in_review` users: name, type (host/guest), session ID, flagged date, a link to open the session in the Didit Console, and Approve/Decline buttons that call our backend (updates DB + notifies user).

---

## 7. Relationship to existing tasks

- **Supersedes `MOB-FEAT-06`** (the legacy `/user/reg-docType` manual KYC-doc-type upload). Didit replaces manual document handling with automated scan + liveness + face match. The old commented-out KYC section in `host_profile.dart` should be replaced by the Didit host gate, not re-enabled as-is.

---

## 8. Contacts / references

- Didit Console: https://business.didit.me · API docs: https://docs.didit.me
- Flutter SDK: pub.dev → `didit_flutter_sdk`
- Webhook IP (if Cloudflare added later): `18.203.201.92`
- Integration questions / blockers: **Ishaan — ishaan@zyphextech.com** (WhatsApp / Google Chat). For API issues include request payload + response body + `session_id`.
