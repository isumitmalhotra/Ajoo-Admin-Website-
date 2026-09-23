# After you press the two buttons — 23 September 2026

Both forms are staged in Chrome and stopped at the purchase. Nothing is bought.
This is what happens after each button, in order. The detail behind each step is
in `GO_LIVE_RUNBOOK_2026-09-19.md`; the corrections are in its §0a.

---

## Tab 1 — PlanetScale · "Create database" · $47/month

Staged: `aajoolive` / **aajoo** · **Vitess (MySQL)** · **ap-southeast-1
(Singapore)** · **PS-10** · 10 GB storage, estimated storage cost $0.

### 1. Enable foreign keys — BEFORE anything is imported

Database → Settings → enable **foreign key constraint support**.

This is not optional and it is not reversible cheaply. The schema carries **39
foreign keys across 21 tables**. Vitess ships with FK support **off**. If the
import runs first it fails partway and leaves a half-built schema on a database
you are already paying for. Only 3 of the 173 migration files declare an FK, so
nothing in the migration run warns you.

### 2. Create a password, and keep it

Settings → Passwords → New password → role **Admin**, name `render-singapore`.

**You copy these values. I never see them.** Put them in a file I can point a
script at without reading:

    D:/Projects/aajaoBackend-render/.env.planetscale

with exactly these keys — note `DB_PASSWORD`, **not** `DB_PASS`:

    DB_HOST=
    DB_PORT=3306
    DB_USER=
    DB_PASSWORD=
    DB_NAME=aajoo
    DB_DIALECT=mysql
    DB_SSL_REJECT_UNAUTHORIZED=true
    DB_POOL_MAX=20

That file is already covered by `.gitignore` (`*.env*`). Confirm before saving.

### 3. Then tell me, and I take it from there

- `scripts/freshDatabase.js` — builds the fresh production schema: all 125
  application tables, the 39 foreign keys, the `SequelizeMeta` ledger so the 173
  migrations do not re-run, and the 2,109 reference rows (categories, amenities,
  1,703 cities, 37 states, legal texts, CMS, the 6 platform blogs). No users, no
  properties, no bookings — §6's decision.
  It refuses to run if the target host is the live host; that guard is real.
- `scripts/dbRowCounts.js` on both sides, and I diff them.
- One backup restored and counted, dated in the master list, **before** Clever
  Cloud is deleted.

---

## Tab 2 — Render · "Deploy web service" · $25/month

Staged: **nameeshPatiyal100/aajaoBackend** · name **aajoo-api-singapore** ·
Docker · branch **main** · region **Singapore (Southeast Asia)** · **1 CPU /
2 GB, $25/month** · health check **`/health`** · **environment variables
deliberately empty**.

### 1. Expect the first deploy to fail. That is correct.

It has no configuration yet. Do not debug it.

### 2. Build the Environment Group

Render → Env Groups → New → link to **both** services.

The name list is **`GO_LIVE_ENV_INVENTORY.txt`** beside this file — **100
names**. Do not rebuild it from the runbook's §2.2 grep: that command misses
nine, because `config/db.config.js` reads through a local `env()` helper.
The nine it misses are

    CLOUDINARY_API_KEY  CLOUDINARY_API_SECRET  CLOUDINARY_CLOUD_NAME
    DB_DIALECT  DB_HOST  DB_PASSWORD  DB_PORT
    MAIL_EMAIL  MAIL_PASSWORD

— i.e. the database host and all image uploads.

**`FIELD_ENCRYPTION_KEY` is copied character for character from the Oregon
service. Never regenerated.** It exists nowhere else. A different value makes
every stored bank account unreadable for ever, silently.

### 3. Set the Singapore service's own DB values

The two services must **not** share a database during the overlap. Oregon stays
on Clever Cloud so testers keep their data; Singapore gets the PlanetScale
values from step 2 above, plus `DB_SSL_REJECT_UNAUTHORIZED=true` and
`DB_POOL_MAX=20`. Everything else comes from the shared group.

Also set on the new service only:
`PUBLIC_SITE_URL=https://www.aajoohomes.com`, `ALLOWED_ORIGINS` (same list as
Oregon), `APP_VERIFY_RETURN_URL=https://www.aajoohomes.com/verify/complete`.

**Absent** on the production group: `OTP_DEV_BYPASS`, `ALLOW_TEST_PAYMENTS`.
Present: `NODE_ENV=production`, `PAYOUT_MODE=manual`, `LOG_LEVEL=info`,
`HEALTH_TOKEN`.

### 4. Attach the domain

Service → Settings → Custom domains → `api.aajoohomes.com`. Then at Vercel,
point the `api` record at the CNAME Render shows. TLS is automatic.
Proof: `curl -sI https://api.aajoohomes.com/health` returns 200 from Render.

### 5. Then I drive it (§2.4)

Register a guest and a host on **our own** accounts — never 100 or 101 — list a
property through the five-step wizard, search for it, take a booking to the
Razorpay sheet, and open admin → categories, CMS, legal, Payouts. Nothing has
changed for anybody on the old stack.

---

## What is still yours alone

| | |
|---|---|
| §0.1 | **Rotate the Razorpay key.** The old secret is in public git history. Making the repo private does not un-leak it. |
| §0.2 | **Make `Ajoo-Admin-Website-` private.** Still PUBLIC today. Two commits of runbook corrections are held back locally until it is. |
| §3.1 | **Razorpay LIVE activation** (business KYC) — days, not hours, and it gates go-live. |
| §4 | **The switch itself** waits for the client's word. 30 minutes. |

## Money

Both resources bill from the moment you press the button, and **both stacks run
in parallel** until the §4 switch — that overlap is expected and is in the plan.

| | Monthly |
|---|---|
| Render Pro workspace | $25 — already paying |
| Render 1c-2g Singapore | $25 — new |
| PlanetScale PS-10 Singapore | $47 — new |
| **Total** | **$97** |

This is the figure in `AAJOO_INFRASTRUCTURE_STATUS_AND_DECISIONS_2026-09-19.html`
that the client already approved. Nothing here needs re-approving.
