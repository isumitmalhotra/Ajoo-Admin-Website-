# Singapore service — what to copy, what to change, what to leave out

`aajoo-api-singapore` is deployed (Docker, Singapore, 1 CPU / 2 GB, `/health`).
Its environment is empty. This is how to fill it.

**Copy from `aajaodev`, not from `aajooHomes`.** There are three services in
this workspace and only `aajaodev` (ungrouped, Oregon) serves the live API —
`aajaodev.onrender.com` is what the website calls. `aajooHomes` is a 2-year-old
Oregon service; its values are not the live ones.

---

## The rule

**Copy every variable that `aajaodev` has — about 34 — except the ones in the
two tables below. Then set those.**

That is simpler and safer than working from a list of 100 names, because the
code reads ~100 but most have working defaults and were never set. What is on
Oregon is, by definition, what the running platform needs.

---

## 1. DO NOT copy these — set them to the new values

| Variable | Singapore value | Why not Oregon's |
|---|---|---|
| `DB_HOST` | PlanetScale host | Oregon's points at Clever Cloud Paris |
| `DB_USER` | PlanetScale user | " |
| `DB_PASSWORD` | PlanetScale password | " |
| `DB_NAME` | `aajoo` | " |
| `DB_PORT` | `3306` | |
| `DB_DIALECT` | `mysql` | |
| `DB_SSL_REJECT_UNAUTHORIZED` | **`true`** | Oregon is `false` — Clever Cloud presents a certificate Node cannot chain. PlanetScale presents a public-CA certificate and **must** be verified, or a man-in-the-middle on the way to the database is invisible. |
| `DB_POOL_MAX` | **`20`** | Oregon's default is 5, sized for Clever Cloud's 5-connection limit. PS-10 allows far more, and a pool of 5 is the first thing that queues under load. |
| `NODE_ENV` | `production` | |
| `LOG_LEVEL` | `info` | |
| `PAYOUT_MODE` | `manual` | RazorpayX is dormant; payouts are run by hand |
| `PUBLIC_SITE_URL` | `https://www.aajoohomes.com` | |
| `APP_VERIFY_RETURN_URL` | `https://www.aajoohomes.com/verify/complete` | |

`ALLOWED_ORIGINS` — **copy Oregon's value exactly.** It is the same list; it is
in this table only because it is easy to assume it needs changing. It does not.

## 2. DO NOT set these at all

| Variable | Why |
|---|---|
| `OTP_DEV_BYPASS` | Skips OTP verification. Absent on production, always. |
| `ALLOW_TEST_PAYMENTS` | Permits sandbox payments. Absent on production. |
| `AAJOO_TEST_RUNNER` | Test-runner only; it disables winston's exception handlers. |
| `PORT` | Render sets it. Setting it by hand breaks the health check. |

If `aajaodev` currently has `OTP_DEV_BYPASS` or `ALLOW_TEST_PAYMENTS` set —
it probably does, testers have been using it — **do not carry them across.**

## 3. The one that must be character-for-character

    FIELD_ENCRYPTION_KEY

Copy it from `aajaodev` exactly. **Never regenerate it.** It exists nowhere but
on that service. A different value makes every stored bank account unreadable
for ever, and nothing errors — hosts simply stop being payable. It is not in
`REQUIRED` (the service boots without it) precisely because a boot failure was
judged the worse trade, which also means **nothing will tell you if you get it
wrong.**

---

## 3a. Environment Group, or per-service?

The runbook (§2.2) says put the shared values in an Env Group linked to both
services, so that at cutover one edit moves both. That is still right — but note
the group **cannot** hold the `DB_*` values, because the two services must point
at different databases during the overlap (Oregon keeps Clever Cloud so testers
keep their data; Singapore uses PlanetScale).

So: everything in table 1's bottom half and the shared credentials go in the
group; the eight `DB_*` values are set **on the Singapore service only**.

---

## 4. Verify without anyone reading a secret

Once it deploys:

    curl -s -H "x-health-token: <HEALTH_TOKEN>" https://<service>.onrender.com/health/env

`config/requiredEnv.js` reports **booleans only, never values**. Look for
`ready: true` and an empty `missingRequired`.

The nine it calls REQUIRED — the service is broken without them:

    DB_USER  DB_PASSWORD  DB_NAME  DB_HOST  DB_PORT
    JWT_SECRET  CLOUDINARY_CLOUD_NAME  CLOUDINARY_API_KEY  CLOUDINARY_API_SECRET

Worth checking in the optional report too, because each is a feature that fails
quietly rather than loudly:

| | If unset |
|---|---|
| `FIELD_ENCRYPTION_KEY` | no host can save a payout account |
| `BREVO_API_KEY` | **no email leaves the service at all** — Render blocks outbound SMTP, so the `MAIL_EMAIL`/`MAIL_PASSWORD` fallback cannot work on this host. A new host cannot receive a signup OTP. |
| `RAZORPAY_WEBHOOK_SECRET` | the webhook answers 503; payments still work but a closed tab is never confirmed |
| `MSG91_SENDER_ID` | SMS reports as configured and then refuses to send |

---

## 5. Then

1. Attach `api.aajoohomes.com` to the Singapore service, and point the Vercel
   DNS `api` record at the CNAME Render shows.
2. `curl -sI https://api.aajoohomes.com/health` → 200 from Render.
3. Tell me, and I drive the whole stack against the fresh database (§2.4) on our
   own accounts — never 100 or 101.

Nothing a user can see changes until §4, which waits for the client's word.

---

## 6. Health report read, 23 September ~23:05 IST

`ready: true` · `database.ok: true` · `missingRequired: []` · all nine REQUIRED set.

**`dbCutoverSafe: true`, all five `dbChecks` "match".** The DB values are not
merely present, they match what the service is actually running on — the July
outage was a set-but-*stale* `DB_HOST`, and that shape is excluded.

Set, and each one matters: `FIELD_ENCRYPTION_KEY` (host payouts),
`BREVO_API_KEY` + `MAIL_FROM` (the only mail path that works on Render),
`RAZORPAY_KEY_ID/SECRET`, `BOTPENGUIN_API_TOKEN`, `FIREBASE_PROJECT_ID`.
`OTP_DEV_BYPASS` correctly **absent**.

### Three to act on

**1. Payments refuse outright — this blocks both the drive and the cutover.**

    "mode": "test", "usableForPayments": false,
    "warning": "A TEST key is configured on a production deploy."

`config/payments.config.js:63`:
`usableForPayments = isConfigured && (isLiveMode || !isProduction || allowTestPayments)`
— on this service that is `true && (false || false || false)`.

So §2.4's "book to the Razorpay sheet" cannot run, and a cutover today would
put the website on a stack that takes no money. Either finish §3.1 (Razorpay
LIVE activation — client KYC, days) or set `ALLOW_TEST_PAYMENTS=true` for the
QA cycle only. The code supports the second deliberately; it must come off
before real users arrive.

**2. `RAZORPAY_WEBHOOK_SECRET: false`** — `/webhooks/razorpay` answers 503.
Payments still complete; a guest whose tab closed is never confirmed. Register
the webhook in the Razorpay dashboard and set the secret here.

**3. `SAFETY_ALERT_EMAIL: false`** and every SMS variable false. SMS is the
known dormant item (needs a provider and a DLT template, not code) so OTPs go
by email only. But an SOS today reaches only admins who open the panel — no
email goes anywhere. Worth setting before launch.

### Fine as they are

`FRONTEND_URL: false` — falls back to `https://www.aajoohomes.com`, which is
correct. `MAIL_EMAIL`/`MAIL_PASSWORD: false` — Brevo is set and Render blocks
outbound SMTP, so the fallback could never have worked anyway.
`ADMIN_API_TOKEN: false` — the `/bp/export/*` endpoints fall back to
`BOTPENGUIN_API_TOKEN`.

---

## 7. Read-only drive, 23 September — 13 of 14 identical to production

`ALLOW_TEST_PAYMENTS=true` took: `usableForPayments` flipped to **true**,
`warning` cleared, `collectsMoney` correctly still **false** (test key, no real
money). Everything else in the report unchanged and green.

Fourteen public endpoints hit on both stacks and compared:

| | Singapore (fresh) | Oregon (live) |
|---|---|---|
| amenities | 37 | 37 |
| categories | 11 | 11 |
| FAQ | 35 | 35 |
| legal documents | 5 | 5 |
| cancellation policies | 5 | 5 |
| states / tags / doc list | 6 / 3 / 4 | 6 / 3 / 4 |
| about-us, safety, T&C host, T&C user | present | present |
| **properties/destinations** | **0** | **8** |

Note the served counts differ from the raw table counts (44 amenities in the
table, 37 served; 22 categories, 11 served) because these endpoints filter to
active rows — and **both sides filter identically**, which is the actual proof.
No 500s, no schema drift: the fresh 127-table build serves production's own
reference data correctly.

The single difference is `/properties/destinations` — 0 against 8 — which is
the fresh database having no properties, exactly as decided in §6.

### What is left of §2.4, and why a session cannot finish it

The authenticated half: register a guest and a host, list a property through
the five-step wizard, search for it, take a booking to the Razorpay sheet,
open the admin screens. That needs accounts to be **created** and passwords
**typed**, which a session must not do. It is yours or a tester's, on our own
accounts, never 100 or 101.

Once those accounts exist, a session can drive everything that follows them.
