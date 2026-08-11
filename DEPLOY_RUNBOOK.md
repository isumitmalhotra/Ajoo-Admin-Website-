# AajooHomes Backend — Deploy Runbook

> **Authored:** 2026-06-10 by Account A (A-16). Covers everything built in the Full Delivery sprint (A-02..A-14).
> **Audience:** Sumit (deploy operator).
> **Scope:** backend (`aajooBackend-2026/`) deploy to Render + DB migrations on Clever Cloud MySQL.
>
> **Golden rule:** every change here is **additive + backward-compatible**. Nothing is destructive. The app already runs today; this runbook turns on the new FMS/HMS/KYC/notifications surfaces.

---

## 0 · Pre-flight (5 min)

```bash
cd "D:/Projects/ajoo admin website/aajooBackend-2026"
# 1. Backup the production DB FIRST (Clever Cloud dashboard → Backups → create manual backup)
#    OR mysqldump if you have CLI access. DO NOT skip this.
# 2. Confirm you're pointed at the right DB:
node -e "const c=require('./config/db.config'); console.log('DB host:', c.host || process.env.CLEVER_DB_HOST); console.log('DB name:', c.database || process.env.CLEVER_DB_NAME);"
```

⚠️ The DB is shared with the client's Render-connected repo. Coordinate before migrating (MASTER_TASK_TRACKER guardrail #6).

---

## 1 · Apply migrations (10 min)

**14 migration files** were added this sprint. All are idempotent or additive.

> ⚠️ **Two gotchas discovered during the first live run (already fixed in code, documented so you understand the procedure):**
>
> 1. **The live DB was never tracked by sequelize-cli** — `SequelizeMeta` was empty, so `db:migrate:status` showed ALL 76 migrations as `down`, including tables that already exist. A plain `db:migrate` would crash trying to re-create `tbl_users`. **Fix:** run `node scripts/baselineMigrations.js` FIRST — it marks the 62 pre-existing migrations as applied (writes only to `SequelizeMeta`, touches no real tables), so the subsequent migrate runs ONLY this sprint's 14.
> 2. **Sequelize pluralizes table names** — the live tables are `tbl_users`, `tbl_user_creds`, `tbl_book_histories`, etc. (model `tbl_user` → table `tbl_users`). The sprint migrations + models were aligned to this (`kyc-user-cols` targets `tbl_users`; new models use `freezeTableName`). Don't "fix" them back to singular.
>
> Also note: the CLI connects to the live DB via the `.sequelizerc` + `config/sequelize-cli.config.js` bridge (which reads `config/db.config.js`), NOT the stale `config/config.json`.

### Procedure (run from a machine that can reach the DB — your laptop, NOT a sandbox)

```bash
cd "D:/Projects/ajoo admin website/aajooBackend-2026"

# 0. (read-only) sanity-check connection + what's in the DB
node scripts/dbInspect.js

# 1. baseline pre-existing migrations (writes only to SequelizeMeta)
node scripts/baselineMigrations.js --dry-run     # review
node scripts/baselineMigrations.js               # apply

# 2. run ONLY this sprint's 14 migrations
npx sequelize-cli db:migrate

# 3. confirm — the 14 (20260609… → 20260611…) should all show 'up'
npx sequelize-cli db:migrate:status
```

This applies, in order:

| Migration | Creates / Alters |
|---|---|
| `20260609210001-create-tbl-financial-ledger` | `tbl_financial_ledger` (FMS) |
| `20260609210002-create-tbl-payouts` | `tbl_payouts` (FMS) |
| `20260609210003-create-tbl-payout-schedules` | `tbl_payout_schedules` (FMS) |
| `20260609210004-create-tbl-invoices` | `tbl_invoices` (FMS) |
| `20260609210005-create-tbl-reconciliation-records` | `tbl_reconciliation_records` (FMS) |
| `20260609230001-create-tbl-support-tickets` | `tbl_support_tickets` (HMS) |
| `20260609230002-create-tbl-support-ticket-messages` | `tbl_support_ticket_messages` (HMS) |
| `20260609230003-create-tbl-host-onboarding-apps` | `tbl_host_onboarding_apps` (HMS) |
| `20260610120001-kyc-user-cols` | adds 4 KYC cols to `tbl_user` (idempotent — `describeTable` guard) |
| `20260610120002-kyc-booking-cols` | adds 2 guest-KYC cols to `tbl_bookings` |
| `20260610120003-property-kyc-status` | adds `property_kyc_status` to `tbl_properties` |
| `20260610120004-create-tbl-admin-flags` | `tbl_admin_flags` (KYC review queue) |
| `20260610130001-create-tbl-notifications` | `tbl_notifications` |
| `20260611040001-add-perf-indexes` | 6 composite perf indexes (FMS/HMS/notifications); all guarded/safe to re-run |

**Verify:**
```bash
node -e "const db=require('./models'); ['tbl_financial_ledger','tbl_payouts','tbl_payout_schedules','tbl_invoices','tbl_reconciliation_records','tbl_support_tickets','tbl_support_ticket_messages','tbl_host_onboarding_apps','tbl_admin_flags','tbl_notifications'].forEach(t=>console.log(t, db[t]?'OK':'MISSING'));"
```

**Rollback (if needed):**
```bash
npx sequelize-cli db:migrate:undo:all --to 20260609205959   # the last pre-sprint migration timestamp
# (or undo one at a time: npx sequelize-cli db:migrate:undo)
```

**Optional — seed demo data (for UAT / FE testing, NOT for go-live):**
```bash
node scripts/seedFmsHmsDemo.js          # populates all 11 new tables with tagged demo rows
node scripts/seedFmsHmsDemo.js --clean  # removes ONLY the demo rows (run before go-live)
```
Idempotent + reversible (every row carries a `SEED_DEMO` marker). Gives the FMS
dashboards / host portal / notifications something to render before real traffic,
and gives the post-deploy EXPLAIN pass rows to profile. **Run `--clean` before
public launch** so no demo data ships.

---

## 2 · Set environment variables on Render (10 min)

Render Dashboard → your service → **Environment** → add these. All have safe fallbacks, so the app keeps working even if you set them later — but the new live integrations need them.

### 2a · Email (A-10) — turns OTP emails ON via Brevo (Render blocks SMTP)
```
BREVO_API_KEY=xkeysib-...        # from Brevo dashboard
MAIL_FROM=no-reply@aajoohomes.com # a Brevo-verified sender
MAIL_FROM_NAME=Aajoo Homes
```
After setting + restart, boot log shows `Mail transport: BREVO_HTTP`. Then:
```
OTP_DEV_BYPASS=false             # turn OFF the 0000 bypass once real email works
```

### 2b · Razorpay (A-09) — live payments
```
RAZORPAY_KEY_ID=rzp_live_xxxxxxxx
RAZORPAY_KEY_SECRET=<live secret>
```
Boot log must NOT show "RAZORPAY_KEY_ID env var not set — falling back".

### 2c · Didit KYC (A-12)
```
DIDIT_API_KEY=...
DIDIT_WEBHOOK_SECRET=...
DIDIT_HOST_WORKFLOW_ID=...        # published host-kyc-v1 workflow id
DIDIT_GUEST_WORKFLOW_ID=...       # published guest-kyc-v1 workflow id
APP_VERIFY_RETURN_URL=https://<your-web-app>/verify/complete
# DIDIT_BASE_URL defaults to https://verification.didit.me — override only if told
```
Then in the **Didit Business Console** → Webhooks → register:
```
https://aajaodev.onrender.com/webhooks/didit
```
Boot log: `config/kyc.config.isConfigured` becomes true (sessions stop being stubs).

### 2d · RBAC (A-13) — no env needed
Role claim is automatic. Nothing to set.

---

## 3 · Restart the service

Render auto-restarts on env change. If not: Dashboard → Manual Deploy → "Clear build cache & deploy" (or just Restart).

---

## 4 · Smoke verification (10 min)

From your local machine, pointed at prod:

```bash
cd "D:/Projects/ajoo admin website"

# FMS — all 27 endpoints. Without a JWT, every one should say "auth required (route mounted)".
FMS_BASE_URL=https://aajaodev.onrender.com node scripts/financeSmoke.js

# HMS — 24 endpoints (host + admin).
HMS_BASE_URL=https://aajaodev.onrender.com node scripts/hmsSmoke.js
```

**Expected:** every endpoint shows ✓ (401 auth-required = mounted). Any ✗ 404 = the deploy didn't pick up the new routes (re-check the push/restart).

**With real tokens (deeper check):**
```bash
FMS_BASE_URL=https://aajaodev.onrender.com ADMIN_JWT=<admin token> node scripts/financeSmoke.js
HMS_BASE_URL=https://aajaodev.onrender.com ADMIN_JWT=<admin token> HOST_JWT=<host token> node scripts/hmsSmoke.js
```
Now endpoints should return 200 / 400-validation (not 401).

**KYC webhook (after Didit configured):**
- Trigger a test verification in the Didit console; confirm a row appears: `SELECT * FROM tbl_user WHERE didit_session_id IS NOT NULL;`
- Confirm webhook signature works: a malformed `x-signature` returns 401 from `/webhooks/didit`.

**Health:**
```bash
curl https://aajaodev.onrender.com/health     # {"status":"ok",...}
```

**Post-deploy runtime perf pass (deferred half of A-15):** once real data exists,
run `EXPLAIN` on the heaviest dashboards (finance dashboard, host earnings,
statements, reports) and confirm the A-15 composite indexes are being used
(look for `Using index` / key = `idx_fl_host_txn_status_date` etc.). If the
reconciliation `run` job is slow on large date ranges, batch-fetch ledger
entries by booking_id once instead of the per-booking lookups (noted in
FULL_DELIVERY_PLAN A-15).

---

## 5 · Keep-alive (RDY-06) — stop cold starts

Set up an external monitor (5 min) per `KEEP_ALIVE_SETUP.md`:
- cron-job.org (recommended, free) → GET `https://aajaodev.onrender.com/health` every 10 min.

---

## 6 · Production cutover checklist (final go-live)

- [ ] DB backed up before migrations
- [ ] `npx sequelize-cli db:migrate` applied; all 10 new tables verified
- [ ] Brevo env vars set; boot log `BREVO_HTTP`; real OTP email received
- [ ] `OTP_DEV_BYPASS=false` set
- [ ] Razorpay live keys set; one real ₹1 payment + signature verify passes
- [ ] Didit env vars set; webhook registered; test verification round-trips
- [ ] `financeSmoke.js` + `hmsSmoke.js` green against prod
- [ ] Keep-alive monitor active
- [ ] FE deployed with `VITE_USE_FINANCE_MOCKS=false`, `VITE_USE_HOST_MOCKS=false`, `VITE_USE_NOTIFY_MOCKS=false` (Account B's B-19)

---

## 7 · Rollback plan

| Problem | Action |
|---|---|
| Migration fails midway | `npx sequelize-cli db:migrate:undo` repeatedly back to `20260609205959`; restore DB backup if needed. New tables are standalone — dropping them does not affect existing flows. |
| New route crashes boot | Unlikely (all route files load-tested). If so: the auto-loader (`app.js` readdir) already wraps each `require` in try/catch and logs `❌ Failed to load route X` without crashing the server. Check logs, fix the file, redeploy. |
| Brevo emails fail | Unset `BREVO_API_KEY` → mailer falls back to SMTP automatically (or re-enable `OTP_DEV_BYPASS=true` for QA). |
| Razorpay live issue | Revert the 2 env vars to the test keys; restart. Instant rollback to test mode. |
| Didit webhook noise | Didit retries on non-2xx; our handler always 200s after processing. To pause: remove the webhook URL in the Didit console. |

---

## 8 · What changed vs the live backend (summary for the client)

- **+10 new tables** (FMS 5, HMS 3, KYC admin-flags 1, notifications 1) — all additive.
- **+3 columns on tbl_user, +2 on tbl_bookings, +1 on tbl_properties** — all nullable/defaulted, zero impact on existing rows.
- **+63 new endpoints** (FMS 27, HMS 24, KYC 4, notifications 4, + auth/admin). All JWT-gated. No existing endpoint changed behavior (new host/payout paths added alongside legacy ones).
- **mailer.js** now dual-transport (Brevo HTTP / SMTP fallback) — identical behavior until `BREVO_API_KEY` is set.
- **JWT** now carries a `role` claim — purely additive; old tokens still work.

*Runbook authored by Account A. Questions → see `API_CONTRACT_HANDOFF.md` for endpoint shapes, `FULL_DELIVERY_PLAN.md` for task provenance.*
