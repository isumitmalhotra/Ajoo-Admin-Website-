# Go-live runbook — Render Pro (Singapore) + PlanetScale, then production

**Written 19 September 2026**, the day the company confirmed both purchases:
the Render workspace is on **Pro** and **PlanetScale** is bought. This is the
ordered list of what makes the platform ready to go live, who does each step,
and what proves it done. Supersedes `DEPLOY_RUNBOOK.md` (June, Clever Cloud).
Open work stays in `MASTER_PENDING_TASKS.md`; this file is the sequence.

**Read from the live system on 19 September:** MySQL 8.0.43 on Clever Cloud
(Paris), **130 tables, 84,294 rows, 21.5 MB**, 39 foreign keys across 21
tables, 8 JSON columns, no triggers / views / routines / events, strict
`sql_mode` already (the same PlanetScale runs). The API is on Render
**Oregon**; the website on Vercel; `api.aajoohomes.com` still points at
Vercel and serves nothing.

**Decision, 19 September (Sumit, for the client): the production database is
a FRESH system — the live database's shape and its reference rows, none of
the four months of test data.** That removes the data restore from the
cutover and the "clean slate" question from §6; the tool for it is
`scripts/freshDatabase.js` (backend `bfc01d8`). What "fresh" means, exactly:

| Carried | Not carried |
|---|---|
| All 125 application tables (empty unless listed here), 39 foreign keys, ids restarting at 1 | The five scratch tables left by one-off scripts (`tbl_geo_cleanup_backup`, `tbl_lux_seed_backup`, `tbl_pricing_grid_backfill`, `tbl_seed_coord_backup`, the old lowercase `sequelizemeta`) — 60,677 rows nobody reads |
| The migration ledger `SequelizeMeta` (168) — or every migration re-runs | Every user, credential, OTP, session — **including the client's test accounts 100 and 101; they register afresh on production** |
| Admins (4, password hashes as they are — reset after launch) and the custom role | Every property and its 24 listing tables, media, offers, blocked dates |
| Categories (22), amenities (44), tags, document lists, booking statuses, cancellation policies, states (37), cities (1,703) | Every booking, payment, invoice, payout, run, ledger row, due, earning, wallet, referral, boost |
| CMS pages/sections/content, FAQs (41), legal versions (31), SEO settings and templates | Every notification, device token, email log, message, negotiation, chatbot session, support ticket, review, KYC row, audit row, coupon |
| The 6 live platform blogs with their covers, admin avatars | Property blogs, all other attachments (user photos, ID documents, listing images) |

2,109 rows in 26 tables; 99 tables empty. The Cloudinary URLs inside the
carried rows (category icons, blog covers) still point at today's shared
account until §3.4 moves the assets.

The whole move is **about two working days**; the only freeze is the
30-minute switch in §4, and that switch waits for the client's word.

---

## 0. Before touching infrastructure (this week, in this order)

These do not depend on Render or PlanetScale and two of them are security
holes today (master list §8a44):

| # | Action | Who | Proof |
|---|---|---|---|
| 0.1 | **Rotate the Razorpay test key** (dashboard → Settings → API keys → Regenerate). Set the new pair on Render (`RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`) and the new id on Vercel (`VITE_RAZORPAY_KEY`). The old secret was in a public repository. | Sumit / client | Checkout on the website opens with the new key id in the request |
| 0.2 | **Make the monorepo private** — `gh repo edit isumitmalhotra/Ajoo-Admin-Website- --visibility private` | Sumit | `gh repo view … --json visibility` → PRIVATE |
| 0.3 | **Change the passwords of test accounts 100 and 101** (they were in repo docs); keep them in a password manager | Client | — |
| 0.4 | **Build 106** against the *current* API with the *new* Razorpay id, so testers keep a working checkout after 0.1: `./tool/build_release.ps1 -ApiBaseUrl https://aajaodev.onrender.com -RazorpayKey rzp_test_<new> -AllowTestPayments -AllowDevEndpoint` | Sumit / session | `tool/verify_release_apk.py` names the endpoint and key |

Code prerequisites for PlanetScale — **done 19 Sep, backend `45ee037`**:
TLS verification and pool size are now environment-driven
(`DB_SSL_REJECT_UNAUTHORIZED`, `DB_POOL_MAX`; defaults keep today's
behaviour). The schema was checked for Vitess: the one `Model.upsert`
(`tbl_notification_prefs`) and the one `INSERT IGNORE` (`tbl_revoked_tokens`)
are both on tables **without** foreign keys, which is exactly the case
PlanetScale allows — no rewrite needed after all. `scripts/dbRowCounts.js`
is the proof-of-restore tool (one JSON of every table's count; run on both
sides, diff).

---

## 1. PlanetScale — the fresh database (now; no user impact)

Owner: Sumit in the PlanetScale console, a session for the import. Account
ownership: the company's login, the development team invited.

1.1 **Create the database in the API's region.** Console → New database →
name `aajoo` → provider AWS → region **Singapore (`ap-southeast-1`)** — the
same region as the Render service in §2, never Mumbai-with-Singapore-API
(each query would cross the sea). Cluster **PS-10**.

1.2 **Turn on foreign key constraints BEFORE importing.** Database →
Settings → General → *Allow foreign key constraints* → on. Off, the 39
constraints are silently dropped and the verify step fails on that count.

1.3 **Turn safe migrations off on `main`** (Branch settings). Our
migrations run `ALTER TABLE` directly through `sequelize-cli`.

1.4 **Create a connection password** (Database → Passwords → New → role
*Admin*, name `render-singapore`). **Sumit copies the values himself** into
a local, gitignored file in the backend repo — the session never sees them:

```
# aajaoBackend-render/.env.planetscale  (never committed; .env.* is ignored)
DB_HOST=aws.connect.psdb.cloud
DB_PORT=3306
DB_USER=<username from the console>
DB_PASSWORD=<password from the console>
DB_NAME=aajoo
DB_DIALECT=mysql
DB_SSL_REJECT_UNAUTHORIZED=true
DB_POOL_MAX=20
```

1.5 **Import the fresh database** (a session; the export from the live
database was made on 19 Sep and sits in `fresh/`, regenerate it with
`node scripts/freshDatabase.js export` if reference rows change first):

```bash
cd aajaoBackend-render
DOTENV_CONFIG_PATH=.env.planetscale node scripts/freshDatabase.js import
```

The import refuses the live host and a non-empty target; it replays 156
statements over TLS and then **verifies**: 125 tables present and no
others, 39 foreign keys, each of the 26 reference tables at its exact
count, every other table at 0. The last line must read
*fresh database verified*. Anything else is a stop.

1.6 **Prove the platform runs on it** from a laptop, before any switch:
`DOTENV_CONFIG_PATH=.env.planetscale npx sequelize-cli db:migrate` →
*No migrations were executed*; `DOTENV_CONFIG_PATH=.env.planetscale node app.js`
→ `/health` answers; the admin login with a carried admin account works
against it (the web dev server with `VITE_API_BASE_URL` at the local API).

1.7 **Backups:** Settings → Backups → daily, keep 7. A restore of the first
backup into a branch, counted with `scripts/dbRowCounts.js`, is done before
the old database is deleted (§4.6).

---

## 2. Render — the Singapore service (Day 1–2, no user impact)

2.1 **Create the service in Singapore** from the same GitHub repository and
Dockerfile as the Oregon one: Pro workspace → New Web Service → region
**Singapore** → instance **Standard (1 CPU / 2 GB)** → health check path
`/health` → auto-deploy on `main`.

2.2 **Move the environment into an Environment Group.** Render → Env Groups
→ New → copy **every** variable from the Oregon service (the inventory is
~100 names; `grep -rhoE "process\.env\.[A-Z0-9_]+" app.js config controllers services utils` in the backend lists them). Link the group to **both**
services. Two things about this step:
- **`FIELD_ENCRYPTION_KEY` is copied character for character — never
  regenerated.** It exists only on Render; a different value makes every
  stored bank account unreadable for ever.
- The group is also how cutover works: one edit to the `DB_*` values moves
  both services to PlanetScale at once (no split-brain between old app
  builds and the website).

Because the new database is fresh, the two services do **not** share data
during the overlap: keep the Oregon service on Clever Cloud (testers keep
their data until the switch) and give the **Singapore service its own**
`DB_HOST/USER/PASSWORD/NAME` = the PlanetScale values from 1.4, plus
`DB_SSL_REJECT_UNAUTHORIZED=true`, `DB_POOL_MAX=20`. The shared group holds
everything else. Set on the new service only, for now:
`PUBLIC_SITE_URL=https://www.aajoohomes.com`, `ALLOWED_ORIGINS` (the same
list as Oregon), `APP_VERIFY_RETURN_URL=https://www.aajoohomes.com/verify/complete`.

2.3 **Attach the domain.** Render service → Settings → Custom domains →
`api.aajoohomes.com`. Then at the DNS host (Vercel): change the
`api` record from Vercel to the CNAME Render shows. TLS is automatic.
Proof: `curl -sI https://api.aajoohomes.com/health` → 200 from Render.

2.4 **Drive the new service on the fresh database** — it is the production
stack, empty: register a guest and a host (our own accounts, never the
client's), list a property through the five-step wizard, search for it,
start a booking to the Razorpay sheet (test key until §3.1), open admin →
categories, CMS, legal, Payouts readiness. Nothing has changed for anybody
on the old stack; this proves the Singapore service and the fresh database
work end to end.

---

## 3. What only the company can do — start these in parallel (they take days, not hours)

| # | Gate | Why it blocks go-live | Where it lands |
|---|---|---|---|
| 3.1 | **Razorpay LIVE activation** (business KYC on the Razorpay dashboard) → live key id + secret | Every payment today is test-mode | Env group `RAZORPAY_KEY_ID/SECRET` (live), Vercel `VITE_RAZORPAY_KEY`, app build (§5) |
| 3.1b | **Razorpay payment webhook registered in LIVE mode** (dashboard → Settings → Webhooks → `https://api.aajoohomes.com/webhooks/razorpay`, events `payment.captured` + `payment.failed`, a secret of your choosing) — the test-mode one was registered 2026-09-21; live mode is a separate list | Without it a payment whose tab closed is money taken for a booking that expires; `/verify` alone hears only from the guest's device | `RAZORPAY_WEBHOOK_SECRET` on Render (the same string typed into the dashboard); `/health/env` lists it; the route answers 503 until it is set |
| 3.2 | **SMS provider + DLT registration** (MSG91 or Fast2SMS; sender id, OTP template approved by the operator) | Phone OTP is dormant; sign-in by phone does not work for a real user | `SMS_PROVIDER`, `MSG91_AUTH_KEY`, `MSG91_SENDER_ID`, `SMS_OTP_TEMPLATE_ID`; `OTP_DEV_BYPASS` **unset** |
| 3.3 | **Email sending domain authenticated** (Brevo → SPF + DKIM on `aajoohomes.com`) | Booking, payout and KYC mails otherwise land in spam | `BREVO_API_KEY`, `MAIL_FROM` on the domain |
| 3.4 | **The company's own Cloudinary account** (the current one is a shared account that held other people's records — memory `cloudinary_shared_account`) | Guest ID photos and listing images must live in an account the company controls | `CLOUDINARY_*`; existing assets copied by a session |
| 3.5 | **DIDIT on a paid plan**, webhook URL moved to `https://api.aajoohomes.com/webhooks/didit` | KYC verifications are billed per session | `DIDIT_*` unchanged; webhook in the DIDIT console |
| 3.6 | **Google Cloud billing + budget alert** on `aajoo-bdb20`; Android Firebase key restricted (`…iCk-WI`) | Maps stop when the free credit ends; an unrestricted key is abuse-able | Google Cloud console |
| 3.7 | **Vercel on Pro**, owned by the company | Commercial use of the website | Vercel |
| 3.8 | **Payout bank file column order** from the company's bank; **TDS §194-O** answer from the accountant | Manual payout runs export a CSV in the bank's format; TDS changes the amount sent | `services/payouts/manualPayouts.service.js` CSV columns; a config line |
| 3.9 | **Play Console**: developer account, app `com.aajoo.aajoohomes`, **Play App Signing** with a production upload key (today's `aajoo-testing.jks` is a testing key) | The Play Store build must be signed with a key the company holds | `android/key.properties` on the build machine |
| 3.10 | **Apple Developer account** + the eight iOS actions | TestFlight and the App Store | `aajoo_app_2026/IOS_READINESS.md` §3 |
| 3.11 | **Legal**: Terms, Privacy, Cancellation policy final text reviewed; the Host Agreement version | The acceptance ledger records what people agreed to | CMS / `tbl_legal_documents` |

None of these needs code from us; 3.1, 3.2 and 3.4 gate a *real* launch, the
rest gate a *good* one.

---

## 4. Cutover — the switch (when the client says go; 30 minutes)

There is no data to move, so the freeze is only the time it takes to point
everything at the new stack. **This step waits for the client's explicit
confirmation** — from that moment the test data is behind us.

4.1 **Tell testers** the old stack is being retired; anything they want to
keep from it (a screenshot, a booking id) is theirs to save now.

4.2 **Point the website at Singapore**: Vercel →
`VITE_API_BASE_URL=https://api.aajoohomes.com` → redeploy. From this
moment the website is on the fresh database.

4.3 **Move the webhooks** to `https://api.aajoohomes.com/…`: Razorpay
(payments, `/webhooks/razorpay` — §3.1b), DIDIT (`/webhooks/didit`), BotPenguin. RazorpayX stays dormant.
Firebase, Google Maps, Cloudinary, Vercel need nothing.

4.4 **Point the Oregon service at PlanetScale too** (its `DB_*` on the
service → the 1.4 values), so the installed APKs (102–106, compiled against
`aajaodev.onrender.com`) land on the same fresh database as the website
and nobody is on two systems at once. Testers sign up again.

4.5 **Smoke as our own accounts** (never 100/101): register, verify email,
list, search, book to the Razorpay sheet and back, a KYC session created,
a notification received, admin sign-in, `/health` on both hostnames.

4.6 **Retire, later**: after 48 hours with no requests on Oregon, delete
that service (the apps by then are on build 107, §5). Delete the Clever
Cloud database **only after** a PlanetScale backup has been restored into
a branch and counted (1.7) — and after the client confirms nothing from
the test period is wanted back.

---

## 5. Apps after the move (Day 3)

5.1 **Build 107 against the permanent API** so the last dependency on
`onrender.com` goes away:
`./tool/build_release.ps1 -ApiBaseUrl https://api.aajoohomes.com -RazorpayKey rzp_test_<new> -AllowTestPayments`
(no `-AllowDevEndpoint`: the script refuses only `onrender.com`). Verify,
hand to testers, push the client's app repo (handoff §9).

5.2 **The production build** comes only after 3.1 and 3.9:
`-ApiBaseUrl https://api.aajoohomes.com -RazorpayKey rzp_live_<id>` with
**no** `-AllowTestPayments`, signed with the production upload key; the
verifier must report the live key and no test flags. iOS: the `testflight`
job with the Apple secrets (§3.10).

---

## 6. Data — decided: fresh

Decided 19 September: the production database starts fresh (the table at
the top). Nothing to run here; the decision is executed by §1.5. Two
consequences for the client to know: the test accounts 100 and 101 do not
exist on production, and the four admin accounts arrive with their current
passwords — reset them on the first day.

---

## 7. Operations from day one

- **Uptime**: Render health checks on both services, plus one external
  monitor (UptimeRobot or Better Stack, free tier) on
  `https://api.aajoohomes.com/health` and `https://www.aajoohomes.com/`,
  alerting to the company's email.
- **Backups**: PlanetScale daily (1.8); one restore test done and dated in
  the master list before Clever Cloud is deleted.
- **Logs**: Render keeps 7 days on Pro — enough; `LOG_LEVEL=info`.
- **Secrets**: `HEALTH_TOKEN` set (so `/health/env` and `dbCutoverSafe` are
  readable by us and nobody else); `NODE_ENV=production`;
  `OTP_DEV_BYPASS` and `ALLOW_TEST_PAYMENTS` **absent** on the production
  group; `PAYOUT_MODE=manual`; the weekly payout reminder on Tuesday 10:00
  IST (`PAYOUT_RUN_DAY`/`HOUR` defaults).
- **The 300-case manual run**: batches 3–10 (240 cases) driven against the
  Singapore service as our own accounts, before the production build.
- **Cost, monthly, as read on 18–19 Sep**: Render Pro workspace 25 + Standard
  instance 25, PlanetScale PS-10 25, Vercel Pro 20, DIDIT per session,
  Cloudinary and Google within free tiers at launch volume ≈ **US$95 + usage**.

---

## 8. What proves "ready to go live"

- [ ] 0.1–0.4 done (key rotated, repo private, passwords changed, build 106 out)
- [ ] §1 fresh database imported and verified (125 tables, 39 FKs, 2,109 reference rows, migrations no-op)
- [ ] §2 Singapore service on `api.aajoohomes.com`, driven against the old data
- [ ] §4 switch done on the client's word; website and both services on the fresh database; webhooks moved
- [ ] Build 107 on the permanent API in testers' hands
- [ ] 3.1 live Razorpay keys in place; 3.2 SMS OTP delivering to a real number; 3.3 mail authenticated; 3.4 Cloudinary owned
- [ ] §6 fresh — done by §1.5; admin passwords reset on day one
- [ ] Production build verified (live key, no test flags, production signing)
- [ ] One PlanetScale backup restored and counted
- [ ] External uptime monitor alerting the company

When the last box is ticked, the platform is live on its own footing; the
Oregon service and the Paris database are deleted afterwards, not before.
