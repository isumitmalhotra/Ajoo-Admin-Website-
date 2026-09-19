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

The whole move is **about three working days** with **one 30-minute freeze**.
Nothing here is destructive until step 4.6, which is explicitly the last.

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

## 1. PlanetScale — build the new database beside the old one (Day 1, no user impact)

Owner: Sumit (console + CLI), with a session. Account ownership: the
company's login, development team invited (as agreed in the 18 Sep document).

1.1 **Create the database in the API's region.** Console → New database →
name `aajoo` → provider AWS → region **Singapore (`ap-southeast-1`)** — the
same region as the Render service in §2, never Mumbai-with-Singapore-API
(each query would cross the sea; the 18 Sep document has the arithmetic).
Cluster **PS-10**.

1.2 **Turn on foreign key constraints BEFORE importing anything.**
Database → Settings → General → *Allow foreign key constraints* → on. A dump
restored with this off loses all 39 constraints silently.

1.3 **Turn safe migrations off on `main`** (Branch → Settings, or
`pscale branch safe-migrations disable aajoo main`). Our migrations run
`ALTER TABLE` directly with `sequelize-cli`; safe migrations would refuse
them. (Deploy requests can come later if we want them.)

1.4 **Create a connection password** for the Render service:
`pscale password create aajoo main render-singapore` → host
(`aws.connect.psdb.cloud`), username, password. Store them in the password
manager and in the Render environment group (§2.2) only. **Never in a repo.**

1.5 **Dump Clever Cloud and restore into `main`** (a session runs this with
the credentials in local, gitignored env files):

```bash
# from the backend repo, Windows Git Bash or the Mac
mysqldump -h <clever-host> -P <port> -u <user> -p <db> \
  --single-transaction --set-gtid-purged=OFF --no-tablespaces \
  --skip-lock-tables --column-statistics=0 --no-create-db \
  --routines=false --triggers=false > clever.sql          # ~21 MB
pscale shell aajoo main < clever.sql                       # minutes; the dump's SET FOREIGN_KEY_CHECKS=0 is honoured
```

1.6 **Prove the restore, table by table**, not "it finished":

```bash
node scripts/dbRowCounts.js > counts-clever.json
DOTENV_CONFIG_PATH=.env.planetscale node scripts/dbRowCounts.js > counts-planetscale.json
diff counts-clever.json counts-planetscale.json            # silence = identical (130 tables, 84,294 rows on 19 Sep)
```

Then, in `pscale shell`: `SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_TYPE='FOREIGN KEY';` → **39**,
and `SELECT COUNT(*) FROM SequelizeMeta;` → the same number as on Clever
Cloud (so migrations do not re-run).

1.7 **Run the backend against it once from a laptop** with
`.env.planetscale` (`DB_HOST/USER/PASSWORD/NAME` from 1.4, `DB_PORT=3306`,
`DB_SSL_REJECT_UNAUTHORIZED=true`, `DB_POOL_MAX=20`):
`DOTENV_CONFIG_PATH=.env.planetscale npx sequelize-cli db:migrate` must say
*No migrations were executed*; `node app.js` must answer `/health`. Then
every backend test that touches the database, once.

1.8 **Backups:** Settings → Backups → daily, keep 7; note the first backup's
time. A restore test of that backup into a branch is the last step of §4.

This rehearsal (1.5–1.7) is repeated once more on cutover day; the first run
is where surprises are allowed.

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

Add to the group, with the values from §1: `DB_SSL_REJECT_UNAUTHORIZED=true`,
`DB_POOL_MAX=20` — **not yet** the PlanetScale `DB_HOST/USER/PASSWORD/NAME`
(those go in at 4.2). Set on the new service only, for now:
`PUBLIC_SITE_URL=https://www.aajoohomes.com`, `ALLOWED_ORIGINS` (the same
list as Oregon), `APP_VERIFY_RETURN_URL=https://www.aajoohomes.com/verify/complete`.

2.3 **Attach the domain.** Render service → Settings → Custom domains →
`api.aajoohomes.com`. Then at the DNS host (Vercel): change the
`api` record from Vercel to the CNAME Render shows. TLS is automatic.
Proof: `curl -sI https://api.aajoohomes.com/health` → 200 from Render.

2.4 **Drive the new service against the OLD database** (it is still on
Clever Cloud via the group): sign in on the website with the API base
overridden in the browser (`localStorage`/`.env.local` `VITE_API_BASE_URL`),
search, open a listing, start a booking to the Razorpay sheet, open
Payouts. Nothing has changed for users yet; this proves the Singapore
service is equivalent.

---

## 3. What only the company can do — start these in parallel (they take days, not hours)

| # | Gate | Why it blocks go-live | Where it lands |
|---|---|---|---|
| 3.1 | **Razorpay LIVE activation** (business KYC on the Razorpay dashboard) → live key id + secret | Every payment today is test-mode | Env group `RAZORPAY_KEY_ID/SECRET` (live), Vercel `VITE_RAZORPAY_KEY`, app build (§5) |
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

## 4. Cutover — the 30-minute freeze (Day 2, evening IST)

Announce a maintenance window to testers. Then:

4.1 **Freeze writes**: scale the Oregon service to 0 instances (Render →
Manual scaling) — the website and apps show errors for the window; that is
the point. Note the time.

4.2 **Final dump and restore** (repeat 1.5 into a **fresh** PlanetScale
branch or after `DROP` of every table on `main` — cleaner: create the
database's `main` again from empty, FK setting on, restore). Run 1.6 — the
diff must be silent.

4.3 **Switch the environment group**: `DB_HOST/USER/PASSWORD/NAME` → the
PlanetScale values; `DB_SSL_REJECT_UNAUTHORIZED=true`; `DB_POOL_MAX=20`.
Both services pick it up on restart. Scale Oregon back to 1 — **it now
serves the same PlanetScale data as Singapore**, so every installed APK
(102–106, compiled against `aajaodev.onrender.com`) keeps working with no
split-brain.

4.4 **Point the website at Singapore**: Vercel → `VITE_API_BASE_URL=https://api.aajoohomes.com` → redeploy.

4.5 **Move the webhooks** to `https://api.aajoohomes.com/…`: Razorpay
(payments), DIDIT (`/webhooks/didit`), BotPenguin. RazorpayX stays dormant.
Firebase, Google Maps, Cloudinary, Vercel need nothing.

4.6 **Smoke, then unfreeze**: sign in as **179 / 194 / 177** (never 100/101),
search, a listing, a booking to the Razorpay sheet and back (test key),
a KYC session created, a notification received, admin → Payouts → readiness
loads, `/health` from both hostnames. Only then tell testers the window is
over. Total freeze: dump 2 min, restore 5 min, checks 10 min, switch 5 min.

4.7 **Decommission, later**: after 48 hours with no requests in Oregon's
logs, delete the Oregon service (the apps by then are on build 107, §5).
Delete the Clever Cloud database **only after** a PlanetScale backup has
been restored into a branch and `dbRowCounts` matches it.

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

## 6. Data: launch clean or launch with what is there — the client decides

The database holds 98 users, 19 properties, 37 bookings and every test
payout, ledger row and negotiation from four months of testing. Two options,
both fine, one decision:

- **Clean slate** (recommended): a session writes a script that deletes test
  users (all but the admins and the two client accounts if wanted),
  properties, bookings, payments, payouts, ledgers, notifications, KYC rows
  and chatbot sessions, **keeping** CMS pages, categories, amenities, tags,
  legal documents, admin users/roles and notification templates. Dry run
  first (counts of what would go), then run on PlanetScale after 4.6, then
  `dbRowCounts` again. Backup before.
- **Keep everything**: nothing to do, but the first real host sees test
  listings beside theirs, and finance sees test payouts in history.

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
- [ ] §1 PlanetScale restored and proven (diff silent, 39 FKs, migrations no-op)
- [ ] §2 Singapore service on `api.aajoohomes.com`, driven against the old data
- [ ] §4 cutover done; website and both services on PlanetScale; webhooks moved
- [ ] Build 107 on the permanent API in testers' hands
- [ ] 3.1 live Razorpay keys in place; 3.2 SMS OTP delivering to a real number; 3.3 mail authenticated; 3.4 Cloudinary owned
- [ ] §6 decided and done
- [ ] Production build verified (live key, no test flags, production signing)
- [ ] One PlanetScale backup restored and counted
- [ ] External uptime monitor alerting the company

When the last box is ticked, the platform is live on its own footing; the
Oregon service and the Paris database are deleted afterwards, not before.
