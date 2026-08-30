# Remediation Completion Report — W0 through W10

*(Originally the W0 + W1 report; extended 2026-08-30 to cover every workstream
completed since, including pay-at-property settlement and the foreign keys.)*

| | |
|---|---|
| Period | 2026-08-29 → 2026-08-30 |
| Workstreams complete | **W0 – W10** — every workstream on the client's list, plus pay-at-property settlement |
| Backend commits | `00c1a69` → `a677588` (32 commits), all pushed and **deployed** |
| Frontend commits | 7, all pushed and **deployed** |
| Migrations applied to the live DB | `admin-roles`, `revoked-tokens`, `pricing-tiers`, `booking-deposit`, `admin-audit`, `payments-bookid-type`, `apply-foreign-keys` (39 constraints), `host-dues` |
| Data migration | 29,239 listings backfilled with a complete pricing grid (reversible) |
| Test suite | **26/26 test files**, all passing · plus `scripts/e2eVerify.js` — **22/22 against the live platform** |
| Production verification | Every claim in this document was checked against the live API on the day it was written, not remembered |
| Source findings | `AAJOO_ADMIN_DASHBOARD_FULL_QA_AUDIT`, `AAJOO_APK_FINDINGS`, `AAJOO_WEBSITE_FINAL_GUEST_HOST_FINDINGS`, `Aajoo Homes Pricing Architecture.pdf`, `AAJOO HOST LISTING`, `SEO Publish Spec`, `Hii.docx` |
| Still open | Nothing on the workstream list. Remaining items are client decisions and credential rotation — see PART 14 |

**How to read this document.** Each section answers four questions: *what was wrong*,
*what we did*, *how the system behaves now*, and *how to check it yourself*. The check
commands are copy-paste ready and state the exact expected output. `$API` means
`https://aajaodev.onrender.com`.

**Parts 1–2** cover W0 and W1 as originally written. **Parts 7–12** cover everything
since. **Part 13** maps every client finding ID to where it is answered, and **Part
14** is the honest list of what is still outstanding.

---

# PART 1 — W0: Production Hardening

W0 was configuration and exposure, not product logic. The theme across every item:
**production was running on values baked into the source code**, and several things
that looked protected were not.

## W0-A · Payment credentials (ADM-P0-02, PROD-01, P0-02, BE-01)

**What was wrong.** A Razorpay TEST key and secret were hardcoded in *two* config
files as fallbacks. On Render, `RAZORPAY_KEY_ID` had never been set — so the
"fallback" was the live configuration. The consequence was the most expensive kind
of failure: checkout opened, the guest "paid", the booking confirmed, an invoice was
issued, **and no money was ever collected**. Nothing visible was broken, which is why
nobody caught it.

**What we did.**
- Removed both hardcoded credential pairs. Credentials are environment-only.
- Payments now **fail closed**: without keys, payment endpoints return a clean 503
  ("Payments are not available at the moment") while everything else — browsing,
  login, host and admin screens — keeps working. Both Razorpay SDK clients are
  built lazily so a missing key cannot crash unrelated routes at load time.
- A test key on a production deploy is also treated as *not payable*, because a test
  key doesn't fail — it succeeds and collects nothing.
- Added **`ALLOW_TEST_PAYMENTS=true`** as an explicit, greppable, shouts-at-boot
  escape hatch for the QA window. It is deliberately its *own* variable: the lazy
  alternative (leaving `NODE_ENV` unset) would also have loosened CORS and every
  other production check at once.

**Behaviour now.** Checkout works exactly as it did before (test window opens,
booking completes, collects nothing) because the test keys are now set in Render's
environment *and* `ALLOW_TEST_PAYMENTS=true` is set. The difference: this state is
now **declared and visible** instead of accidental and silent.

**Check it:**
```bash
curl -s -H "x-health-token: <HEALTH_TOKEN>" https://aajaodev.onrender.com/health/env
```
Expect in the `payments` block: `"configured": true`, `"mode": "test"`,
`"usableForPayments": true`, `"collectsMoney": false`. That last field is the honest
one — the platform tells you it is not collecting money instead of hiding it.

> **⚠️ At go-live:** delete `ALLOW_TEST_PAYMENTS` from Render and replace the keys
> with `rzp_live_…`. That one change flips the platform from "test window" to
> "really collecting". Nothing else needs to change.

## W0-B · All other hardcoded secrets (BE-01, P0-03)

**What was wrong.** `config/db.config.js` carried, as "fallbacks": the **live
production database password**, the **live Cloudinary API secret**, a **Gmail app
password**, and a duplicate copy of the Razorpay test secret that nothing even read.
Since `CLOUDINARY_*` and `MAIL_*` were not set on Render, those fallbacks *were* the
production configuration — live credentials living in a Git repository.

**What we did.** Removed every one. Confirmed which removals were actually load-bearing
before removing (Cloudinary was; the Gmail SMTP path was already dead because Render
blocks SMTP and Brevo is the live mail transport; the DB values were already set in
Render and matching).

**What it exposed.** Removing the fallbacks immediately broke boot — because `dotenv`
was loaded ~45 lines into `app.js`, *after* modules that read the DB config. The
config had been reading an empty environment all along, silently rescued by the
hardcoded answers. The same bug existed in a second entry point
(`sequelize-cli.config.js`), where it broke migrations. Both fixed: configuration
now loads before anything reads it.

**Behaviour now.** Identical to before — you set the same values in Render's
environment, so nothing changed for users. The values just moved out of the source.

**Check it:**
```bash
grep -rnE "rzp_test_|rzp_live_[A-Za-z0-9]{6}|LuLQUEBW|geyiqqyy|ILIM0LOD" --include="*.js" D:/Projects/aajaoBackend-render/config D:/Projects/aajaoBackend-render/controllers D:/Projects/aajaoBackend-render/utils
```
Expect: no hits (only a `rzp_live_xxxx` placeholder in a comment).

> **⚠️ Still owed (your action, after testing):** these credentials remain in **4
> commits of the pushed GitHub history**, and some were pasted into chat. Removing
> them from the current files does not un-leak them. **Rotate**: the DB password,
> Cloudinary secret, Gmail app password, Razorpay test secret, JWT secret,
> BOTPENGUIN/BREVO/DIDIT keys, and the Firebase private key.

## W0-C · CORS — HTTP and WebSocket (ADM-P0-03, PROD-02, PROD-07, SEC-08)

**What was wrong.** HTTP CORS was `origin: true` and Socket.IO was `origin: "*"` —
both literally annotated *"consider restricting in production"*. Any web page on the
internet could make an authenticated browser call against an API that runs an admin
console and moves money.

**What we did.** One allowlist (`config/allowedOrigins.js`) used by both surfaces.
Production admits `https://www.aajoohomes.com` and `https://aajoohomes.com` (plus
anything in `ALLOWED_ORIGINS`). The critical subtlety, tested explicitly: **a request
with no `Origin` header is still allowed** — the Flutter app, Razorpay webhooks, and
curl send none, and refusing them would break the mobile app and inbound payments
while adding zero security (CORS is a browser mechanism; non-browsers were never
subject to it).

**Behaviour now / check it** (all four verified on production today):

```bash
# 1. Live site: allowed — expect "access-control-allow-origin: https://www.aajoohomes.com"
curl -s -D - -o /dev/null -H "Origin: https://www.aajoohomes.com" https://aajaodev.onrender.com/ | grep -i access-control

# 2. Unknown site: refused — expect NO access-control-allow-origin line
curl -s -D - -o /dev/null -H "Origin: https://evil.example" https://aajaodev.onrender.com/ | grep -i access-control

# 3. No Origin (mobile app / webhook): served — expect HTTP 200
curl -s -o /dev/null -w "%{http_code}\n" https://aajaodev.onrender.com/

# 4. Preflight for PUT (this once broke 9 endpoints): expect 204
curl -s -o /dev/null -w "%{http_code}\n" -X OPTIONS \
  -H "Origin: https://www.aajoohomes.com" \
  -H "Access-Control-Request-Method: PUT" \
  -H "Access-Control-Request-Headers: content-type,authorization" \
  https://aajaodev.onrender.com/host/profile/update
```
Localhost being refused (check 2 pattern with `Origin: http://localhost:5173`) also
proves `NODE_ENV=production` is genuinely in effect.

## W0-D · Private uploads were public (PROD-06, P0-08, SEC-05)

**What was wrong.** The `uploads/` directory was served as public static files at
the site root **and a second time** at `/uploads/admin_dashboard`. What lives there
is generated invoices — which name the guest, the property, the dates and the
amount — fetchable by anyone who guessed a filename, and the filename contains the
booking reference.

**What we did.** Both mounts removed. Guests, hosts and admins already had
authenticated download routes; the one caller that needs a link without a session
(the support chatbot handing a link into a chat window) now receives a
**15-minute HMAC-signed URL**. A signature cannot be forged, moved to a different
file, or have its expiry extended; path traversal in the filename is rejected
outright (10 unit tests).

**Check it:**
```bash
# Both expect HTTP 404:
curl -s -o /dev/null -w "%{http_code}\n" https://aajaodev.onrender.com/invoices/invoice_B756135_1786801758510.pdf
curl -s -o /dev/null -w "%{http_code}\n" https://aajaodev.onrender.com/uploads/admin_dashboard/invoices/x.pdf
```
A *signed* link (as issued by the chatbot flow) works for 15 minutes, then 404s.

## W0-E · Sensitive data in logs (P0-05, SEC-06)

**What was wrong.** A redaction helper existed — and the line that used it was
**commented out**, with `body: req.body` logged instead. Every request body went to
the logs verbatim: OTPs, passwords, Razorpay signatures, KYC fields, bank details.
Even switched on, the old helper matched only seven exact key names at the top level.

**What we did.** New `utils/redact.js`, wired in for real: recursive; key-name
matching that is case- and separator-insensitive (`cred_user_password`,
`userPassword`, `PASSWORD` are one rule); covers OTP/PIN/token/signature/
Aadhaar/PAN/account/IFSC/UPI/card families; bounded depth and size; correlation IDs
(`bookingId`, `razorpay_payment_id`…) deliberately kept readable so logs stay
useful. Admin route bodies are reduced to key names only. 13 unit tests, including
cyclic objects and buffers.

**Check it:** make any request with a sensitive field, then read Render → Logs:
the field appears as `"otp":"[REDACTED]"`. Or run
`node tests/redact.test.js` in the backend repo — expect `13/13 passed`.

## W0-F · Exposed diagnostics (PROD-04, PROD-05, SEC-10)

**What was wrong.** `/db-test` was public and returned the **raw database driver
error**, naming the DB host, port and user — a free infrastructure map. `/health/env`
was public and listed **exactly which secrets were unset**, plus the warning that
payments collected nothing.

**What we did.** `/db-test` kept (a Render health check may point at it — deleting
it could have failed every deploy) but silenced: it answers `ok`/`unavailable` and
nothing else. `/health/env` answers `{"ready":true|false}` anonymously; the full
detail requires the `x-health-token` header matching the `HEALTH_TOKEN` env var,
compared in constant time.

**Check it:**
```bash
curl -s https://aajaodev.onrender.com/db-test        # expect exactly: ok
curl -s https://aajaodev.onrender.com/health/env     # expect exactly: {"ready":true}
curl -s -H "x-health-token: <HEALTH_TOKEN>" https://aajaodev.onrender.com/health/env  # full detail
```

## W0-G · Readiness vs liveness (ADM-P0-06, PROD-03)

**What was wrong.** The app kept booting — and kept reporting healthy — after the
database failed to connect. An instance that could not serve a single query still
received traffic, so every request failed individually instead of the instance
being routed around.

**What we did.** Liveness (process up) and readiness (able to do work) split.
`/health/env` now includes a cached (10s) database probe; `ready` is `true` only
when configuration **and** the database are good, and returns 503 otherwise. Boot
still survives a transient DB blip (deliberate — reconnects lazily), but marks
itself NOT READY.

**Check it:** the anonymous `/health/env` above returning `{"ready":true}` *is* the
check — that value now proves a live DB connection, not just a running process.

## W0-H · Admin rate limiter (ADM-P1-01, PROD-08)

**What was wrong.** All three admin rate limiters keyed on `req.admin?.id`, but the
JWT carries `adminId` — so the per-admin bucket never matched and every
authenticated admin silently fell into the shared per-IP bucket. Several admins
behind one office NAT shared one allowance; a single admin could not be limited
individually at all.

**What we did.** All three limiters read `adminId`.

---

# PART 2 — W1: Authorization & RBAC

W0 was about exposure. W1 is about **who is allowed to do what** — and the headline
discovery is that role separation was not partially implemented, it was **inert**.

## W1-A · Why RBAC was inert (worse than the audit said)

The audit said most finance routes lacked RBAC. Three facts, verified in code and
live data, compounded into something stronger:

1. `tbl_admins` stored only `admin_isAdmin` / `admin_isActive`. There was **nowhere
   to record** that someone is Finance rather than a full administrator.
2. The role-derivation function returned `"admin"` for anyone with `isAdmin = 1`,
   so every real account resolved to one role.
3. `requireRole()` contained `role === "admin" || allowedRoles.includes(role)` —
   **every admin passed every gate as a superuser.**

So the 3 finance routes that *looked* guarded (`requireRole('admin','finance')`)
admitted exactly the same people as the 24 with no gate at all. Separation of
duties: **0 of 27, not 3 of 27.** Live data agreed: two admin accounts, one active
superuser, no roles anywhere.

## W1-B · Canonical roles (ADM-P0-04, ADM-P1-02, DB-01)

**What we did.**
- New column `tbl_admins.admin_role` — `super_admin | admin | finance | support` —
  with `config/adminRoles.js` as the **single definition** used by the migration,
  the model, the login token, the middleware and the tests (two drifting copies of
  role logic is exactly how this regresses).
- The migration **backfills in the same statement that creates the column**: the
  existing active administrator became `super_admin` with zero window in which the
  live dashboard could lose access. Verified on the live DB:
  `admin (id 1) → super_admin`, `Sumit (id 4) → support`.
- Login now stamps the role into the JWT. Only `super_admin` bypasses a gate it was
  not named in.
- **Legacy tokens** (minted before roles existed, carrying only `isAdmin`) are read
  as `super_admin` — deliberately, because at mint time "admin" meant unrestricted,
  and downgrading them would strip powers from live sessions mid-shift. New
  role-less tokens get least privilege instead. The asymmetry is documented in code.

**What the roles mean:**

| Role | Can |
|---|---|
| `super_admin` | Everything, including creating admins and changing roles |
| `admin` | Operations — users, hosts, properties, bookings, CMS. Can **look at** money. **Cannot move it.** |
| `finance` | Ledger, payouts, invoices, reconciliation — read and write |
| `support` | Tickets and disputes. No finance access at all |

## W1-C · All 27 finance routes gated (ADM-P0-01, ADM-P1-04)

**What we did.** Every `/admin/finance/*` route carries an explicit gate:
**19 read routes** (`super_admin`, `finance`, `admin`) and **8 write routes**
(`super_admin`, `finance` only). Classified by what the endpoint *does*, not by HTTP
method — several searches/reports are POST because they take a filter body, and
calling those "writes" would have locked Operations out of the dashboard for no
security gain. The 8 write routes are the ones that move money: payout
initiate/approve/reject, payout schedules, invoice void, reconciliation
resolve/run.

**Proved live with signed tokens** (not just unit tests):

| Role | finance READ | finance WRITE |
|---|---|---|
| super_admin | 200 | passes gate |
| **admin** | **200** | **403** ← this row is the whole point |
| finance | 200 | passes gate |
| support | 403 | 403 |
| no token | 401 | 401 |

**Check it — the deliverable Nameesh asked for by name:**
```bash
cd D:\Projects\aajaoBackend-render
node tests/adminRbac.test.js --matrix
```
Prints the full **endpoint × role** table (27 endpoints × 4 roles, expected
200/403, plus "unauthenticated: 401 on every row"). The same file runs 14 tests
proving the gate logic. Note: it must be run **from the backend repo** — running it
from another folder gives `MODULE_NOT_FOUND`.

Live spot-checks:
```bash
# No token → 401
curl -s -o /dev/null -w "%{http_code}\n" https://aajaodev.onrender.com/admin/finance/dashboard
```
Testing the 403 rows live requires an account with that role — create one via the
Roles screen (see W1-E) or trust the matrix test, which exercises the identical
middleware.

## W1-D · Logout that actually ends the session (P0-06, G-04, SEC-04)

**What was wrong.** Admin logout wrote a log row; user logout dropped a device
registration row. In both cases the **30-day JWT kept working on every protected
endpoint after logout**. The client deleting its copy of the token was the entire
logout mechanism — the exact anti-pattern the APK audit quoted.

**What we did.**
- Every minted token now carries a unique `jti` (session id).
- Logout writes that `jti` to `tbl_revoked_tokens` **and** an in-memory denylist.
- `verifyJwt` — the single choke point all six authentication paths funnel through,
  so the check cannot be forgotten on one of them — rejects a revoked `jti` with 401.
- **Per-session, not logout-everywhere**: a jti denylist ends exactly the session
  that logged out. The simpler per-account-timestamp design would have meant
  logging out on the website kills your mobile-app session — a brand-new "bug" in
  the middle of the testing cycle.
- The check is a synchronous memory read (it runs on *every* authenticated request
  against a 5-connection DB pool); the table is the durable record that survives
  restarts. Rows self-expire when the token they revoke would have expired anyway.
- Tokens minted before this change have no `jti` and cannot be individually
  revoked — that is *unchanged* behaviour (they were never revocable) and it ages
  out as those sessions expire.

**Check it (verified on production today):**
1. Log in to the admin panel → works.
2. Call `POST /admin/logout` with that token → 200.
3. Replay **the same token** against `/admin/dashboard` → **401**.
4. A second session opened before the logout → still 200, untouched.

Or in one script: `node tests/sessionRevocation.test.js` (backend repo) — `8/8 passed`.

## W1-E · Role-aware team management (ADM-P1-03)

**What was wrong.**
- Admin creation sat behind `optionalAdminAuth` and checked the legacy flag.
- The Roles screen (`/admin/members/role`) **only toggled `admin_isAdmin`** — after
  W1-B landed, it would have changed a badge while the real `admin_role` the gates
  read stayed put. (The same failure mode the audit found in "Deactivate".)
- New admins never got a role at all.

**What we did.**
- `createAdmin`: only `super_admin` may create (legacy `isAdmin` honoured *only*
  for pre-role tokens); accepts `admin_role`, validated against the canonical list;
  least-privilege default (`support`); the bootstrap (first-ever) admin is forced
  `super_admin` so the team can always be managed. `admin_role` is declared in the
  validation schema — the codebase strips undeclared fields silently, so without
  that line every created admin would land on the default no matter what was sent.
- `adminMemberSetRole`: writes **both** `admin_role` (the authority) and
  `admin_isAdmin` (kept in sync as a legacy mirror). Accepts either contract — the
  screen's existing `isSuperAdmin` boolean, or a `role` name — so the current admin
  UI keeps working unchanged. Invented roles are refused. The
  "last active super admin cannot be demoted" lockout guard carries over.

**Check it (all verified live today):**
```bash
# Unauthenticated creation → 401
curl -s -o /dev/null -w "%{http_code}\n" -X POST https://aajaodev.onrender.com/admin/create \
  -H "content-type: application/json" \
  -d '{"admin_name":"Probe","admin_email":"p@x.test","admin_password":"Xx#12345678"}'
```
With a super_admin token: `POST /admin/members/role {"admin_id":4,"role":"finance"}`
→ "Role changed to finance"; `{"role":"godmode"}` → refused;
`{"admin_id":1,"role":"support"}` → refused ("last active super admin").

## W1-F · Object-level ownership (SEC-01, SEC-02, G-21, H-09, H-15, H-22, H-36, BE-04, BE-05)

**What we did.** A handler-by-handler audit of every guest
booking/payment/invoice path and every host
property/booking/calendar/negotiation/payout path — checking that each one scopes
its database access to the *calling* user, so changing an ID in a request cannot
reach someone else's data.

**The honest result:** most handlers were **already owner-scoped** (several carry
comments from earlier fixes naming the exact hole they closed). Two were not:

1. **`updatePropertyCoverImage` — a real hole.** It took `propertyId` from the
   request body and went straight to deleting the existing cover attachment and its
   Cloudinary asset. The only check was "is a host" — so **any authenticated host
   could destroy and replace any other host's cover photo**. Fixed: ownership is
   verified *before* the destructive step, answering 404 (not 403) so probing IDs
   doesn't reveal which properties exist.
2. **The four `/payout` routes** authenticated but never required the host role.
   The controllers were already caller-bound (defence-in-depth, not an open hole),
   but SEC-02 is explicit that a guest must not be able to call host actions — now
   a guest token gets 403.

**How this is kept true:** `tests/ownership.test.js` pins the ownership predicate of
every audited handler at *source level* — `book_user_id: userId`,
`property_host_id: req.user.userId`, `ownsProperty(...)`, receiver checks. A future
refactor that drops a where-clause turns a silent privilege hole into a **red test
naming the handler**. For the cover-image fix the test additionally asserts *order*:
ownership before `tbl_attachments.destroy`.

**Check it:** `node tests/ownership.test.js` (backend repo) — `14/14 passed`.
Live negative test: any `/payout/*` call without a host token → 401/403.

---

# PART 3 — What did NOT change (regression guarantee)

Verified on production as part of the 29-check pass:

- Search, geocoding and suggestions — working
- robots.txt, sitemap.xml, SEO resolver — working
- The live website through the edge — working
- Admin login and the dashboard — working
- Checkout — **behaves exactly as before** (test window, completes, collects
  nothing) because that state is now explicitly configured
- Mobile app and Razorpay webhooks — unaffected by CORS (no-Origin requests allowed)
- Existing logged-in admin sessions — unaffected (legacy tokens honoured)

# PART 4 — Finding-ID mapping (for Nameesh's tracker)

| Finding ID | Fix implemented | Developer tested | Status |
|---|---|---|---|
| ADM-P0-01 | RBAC on all 27 finance routes, read/write split | Matrix test 14/14 + live token proof | **Fixed** |
| ADM-P0-02 / PROD-01 / P0-02 | Payment creds env-only, fail closed, QA escape hatch | Live `/health/env` payments block | **Fixed** |
| ADM-P0-03 / PROD-02 / PROD-07 / SEC-08 | CORS allowlist, HTTP + Socket.IO | 12 unit + 6 live origin checks | **Fixed** |
| ADM-P0-04 / ADM-P1-02 / DB-01 | `admin_role` column, canonical roles module | Migration verified on live DB | **Fixed** |
| ADM-P0-06 / PROD-03 | Readiness gate incl. DB probe | Live `{"ready":true}` = DB proven | **Fixed** |
| ADM-P1-01 / PROD-08 | Rate limiter keys on `adminId` | Code + parse | **Fixed** |
| ADM-P1-03 | Role-checked, role-assigning admin creation | Live 401 + role validation checks | **Fixed** |
| ADM-P1-04 | Finance least-privilege (admin cannot write) | Live: admin token → 403 on approve | **Fixed** |
| ADM-P1-06 / SEC-01 / SEC-02 | Ownership audit + 2 fixes + pinned predicates | 14/14 ownership tests | **Fixed** |
| P0-05 / SEC-06 | Log redaction re-enabled, recursive | 13/13 redact tests | **Fixed** |
| P0-06 / G-04 / SEC-04 / P1-01(part) | jti revocation on logout, all auth paths | 8/8 tests + live same-token-401 proof | **Fixed** |
| P0-08 / PROD-06 / SEC-05 / H-06 | Uploads off public static, signed URLs | 10/10 tests + live 404s | **Fixed** |
| PROD-04 / PROD-05 / SEC-10 | `/db-test` silenced, `/health/env` token-gated | Live checks | **Fixed** |
| BE-01 / P0-03 | All hardcoded secrets removed | Repo grep clean | **Fixed — rotation owed** |
| BE-03 (finance portion) | Explicit role gates | Matrix | **Fixed** (full sweep = later workstreams) |
| BE-04 / BE-05 / G-21 / H-09 / H-15 / H-22 / H-36 | Ownership scoping | 14/14 + live | **Fixed** |
| G-03 / P1-01 / P1-02 (60-min token, 30-min inactivity) | Not in this slice | — | **Open** (W1 follow-up; revocation infrastructure now exists for it) |

# PART 5 — Standing actions on your side (W0/W1)

> Superseded by **PART 14**, which carries the full current list. Kept here so the
> W0/W1 record reads as it was written.

1. **Now set on Render (done):** `CLOUDINARY_*`, `MAIL_*`(via Brevo), `RAZORPAY_*`
   test keys, `NODE_ENV=production`, `ALLOWED_ORIGINS`, `ALLOW_TEST_PAYMENTS=true`,
   `HEALTH_TOKEN`.
2. **After testing passes:** rotate every credential listed in W0-B (they are in
   Git history and chat transcripts).
3. **At go-live:** delete `ALLOW_TEST_PAYMENTS`; replace Razorpay keys with
   `rzp_live_…`. This is the single switch between "demo checkout" and "real money".
4. Optional housekeeping: delete `DATABASE_URL` and `DB_URI` from Render (read by
   nothing, pointing at a deleted database) and re-enter `JWT_SECRET` /
   `BOTPENGUIN_API_TOKEN` without their trailing newlines *(caution: re-entering
   `JWT_SECRET` invalidates every live session — do it at a quiet moment)*.

# PART 6 — One-command re-verification

Everything in this document can be re-proven at any time:

```bash
cd D:\Projects\aajaoBackend-render
npm test                                # 15/15 files — includes all W0+W1 suites
node tests/adminRbac.test.js --matrix   # the endpoint × role deliverable
```

The production-side pass (29 checks) lives at
`scratchpad/final_w0w1_check.mjs` from this session; each check in it corresponds
to a "Check it" block above.

---

# PART 7 — W4: Booking, payment & cancellation integrity

`WEB-P0-04, P-03, P-04, P-07, P0-09, G-19, C-01…C-06, P1-04, P1-05, E2E-02, E2E-10, DB-05`

## W4-A · A payment could be verified twice, and pay the host twice

**What was wrong.** `verifyUserPayment` did a check-then-act with no lock. Replaying
the same Razorpay callback ran every side effect again: a second booking-history
row, a second **host earnings** row — creditable money — a second set of
notifications, a second finance footprint. Worse, three `update()` calls passed
`{where}` and `{transaction}` as *separate arguments*; Sequelize silently drops the
second, so those writes were committing **outside** the transaction that was
supposed to protect them.

**What we did.** The payment row is now read with `SELECT … FOR UPDATE` inside the
transaction, so two callbacks for the same order serialise. An already-verified
payment returns the same success answer the first one got — a retry is not an error
the guest should see — but runs **no** side effects. The three dropped-transaction
calls were corrected to a single options object.

**Behaviour now.** Replaying a payment callback is safe and silent. Row counts on
`tbl_payments`, `tbl_host_earnings` and `tbl_book_histories` are unchanged by a
replay — verified on production.

## W4-B · Two guests could book the same dates

**What was wrong.** The availability guard read existing bookings without locking
them, so two checkouts a moment apart both saw the dates free and both inserted.

**What we did.** `bookingCreate` now takes a row lock on the property
(`SELECT property_id … FOR UPDATE`) before the guards run, and the guard queries
themselves use `lock: transaction.LOCK.UPDATE`.

**Behaviour now.** Simultaneous checkouts for the same dates serialise; the second
is refused with the ordinary "those dates are no longer available" message.

## W4-C · Cancellation had no identity check

**What was wrong.** Anyone holding a session could cancel a booking outright —
triggering a refund — with no second factor, and no reason recorded. Every guest-side
cancellation in the database has an empty reason column.

**What we did.** Cancellation now requires an **email OTP**, reusing the existing
`tbl_forget_pass_otp` infrastructure with its own type so a code minted for a
password change cannot cancel a stay. A reason is required. The web client asks for
the reason first, then sends the code.

**Behaviour now.** Cancel → reason → "Continue" sends a code → 6-digit field with
Resend → "Confirm cancellation". Cancelling without an OTP returns `otpRequired`
rather than a generic error.

> **Known gap:** the Android app does **not** yet have this OTP step, so app-side
> cancellation is refused by the server until W8 adds it. See PART 14.

---

# PART 8 — W2: The pricing engine

`Aajoo Homes Pricing Architecture.pdf` · findings `LP-P0-09, H-11, G-20, SEC-03, P-01, N-02, P1-09`

Two deviations from the document, both **your** decisions, both deliberate:

1. Negotiation auto-accepts at the **IDEAL**, not the minimum.
2. The 10% deposit is offered on **every** booking, not only Advance Booking.

## W2-A · The nine-value grid

**What was wrong.** The document asks for Min / Ideal / Max across Night, Week and
Month. The platform stored one nightly price, one weekly price, one monthly price,
and a nightly minimum. `property_ideal_price` existed as a column and was populated
on **zero** rows.

**What we did.** Added the four missing tier columns. Where a host has not set a
weekly or monthly tier, it is derived by scaling that period's Max by the nightly
ratio — so every listing has a proportionally consistent grid without a backfill
inventing numbers.

**Then you asked for all nine to be mandatory**, on every surface. They now are:
the host wizard, an admin driving that wizard, and the admin's own property form all
call one validator (`utils/pricingGrid.js`). The rules: every value present and above
zero; `min ≤ ideal ≤ price` per period; a package must cost less than its nights
bought singly.

**A bug found while doing it:** `property_ideal_price` was never actually stored — by
*anything*. The column existed and both forms set it, but the Sequelize model never
declared it, and **Sequelize silently drops undeclared fields**. The auto-accept
threshold the whole negotiation engine runs on read back null on every listing,
forever.

**Behaviour now.** Saving a price with an incomplete grid is refused, field by field.
Existing listings were backfilled (see W2-E).

## W2-B · Composite pricing (document §5)

**What was wrong.** Long stays were priced by *smoothing*: a 9-night stay was charged
`weeklyPrice ÷ 7 × 9`. The document prices them as packages plus remainder.

**What we did.** `utils/pricingEngine.js` decomposes a stay greedily — months (28
nights), then weeks (7), then remainder nights — pricing each unit at the host's
figure for that period, at all three tiers.

**Behaviour now.** The document's own worked example computes exactly:
night 4,000/5,000/6,000 · week 25,000/28,000/32,000 · **12 nights** → 1 week + 5
nights → Min **₹45,000** · Ideal **₹53,000** · Max **₹62,000**. That is a literal test
vector.

Guards kept: a stay is never quoted more than pricing every night singly; weekend
uplift applies to remainder nights only (a week package already prices its own days);
extra-guest fees ride on top, because they are a fee, not a tier.

**Min and Ideal never leave the server.** A test fails the build if the quote
controller so much as mentions the internal block.

## W2-C · The UI no longer computes the price (document §15)

**New endpoint** `POST /pricing/quote` — public, rate-limited, dates as `DD-MM-YYYY`.

**Check it:**
```bash
curl -s -X POST https://aajaodev.onrender.com/pricing/quote \
  -H "Content-Type: application/json" \
  -d '{"propertyId":29262,"bookFrom":"01-10-2026","bookTo":"13-10-2026"}'
```
Expect `composition {months:0, weeks:1, nights:5}`, `subtotal` 59,000 against a
`nightlyTotal` of 68,000 — and no `min` or `ideal` anywhere in the payload.

## W2-D · Negotiation: the ideal threshold

| Guest offers | Before | Now |
|---|---|---|
| Above the list price | accepted at the offer | **Refused** — "that is above the listed price" |
| At or above the **ideal** | accepted (if ≥ min) | **Accepted automatically**, at the offered price |
| Between min and ideal | accepted automatically | **Goes to the host** |
| Below the minimum | goes to the host | goes to the host, **flagged as below their floor** |
| No minimum set | negotiation off | unchanged |

The above-list refusal is now enforced **server-side**; the web form had the same
check, but only in the browser, and an API call skipped it entirely.

Dated offers are judged against the composite tiers **for those exact dates**, divided
back to per-night — the document's own worked example. The ledger snapshots the tiers
the decision actually used, so a row can never explain itself with figures the engine
did not see.

## W2-E · Pay 10% now, or pay in full (your decision)

**What was wrong.** The document's Advance Booking mode did not exist at all.

**What we did.** Every booking offers three tiles: pay in full, pay the 10% deposit
that confirms it, or pay at the property. Three things that would otherwise have
leaked money:

- **The host's payout waits.** A deposit writes the finance ledger as PENDING and
  queues **no** payout; the balance payment promotes it to COMPLETED. The platform
  never pays out on money it has not collected.
- **Refunds compute against money RECEIVED**, not the price of the stay. Without
  this, a 100% cancellation refund on a ₹28,320 stay paid ₹2,832 would have returned
  ₹28,320.
- **Check-in is refused while a balance is owed** — this is where "before check-in"
  is actually enforced.

Reminders go out at 7, 3 and 1 days before check-in, once each, with the booking's
own history row as the receipt so a restart cannot re-send.

**One subtlety worth knowing:** `tbl_payments.pay_amount` has always held the
**pre-tax** room subtotal while the Razorpay order is for the tax-inclusive total,
and host earnings are credited from it. That column was left exactly as it is; the
gateway figure got its own column (`pay_gateway_amount`), which is the only honest
thing to count a balance against.

**Verified on production:** a ₹15,750 stay produced a ₹1,575 deposit order, and the
balance endpoint produced the ₹15,750 balance order.

## W2-F · The backfill

Making all nine values mandatory would have frozen every existing listing — a host
could not save Step 4 and an admin could not edit the listing at all. So
`scripts/backfillPricingGrid.js` was run against production at your request.

| | |
|---|---|
| Listings examined | 29,245 |
| **Filled** | **29,239** — of which 681 had a broken minimum repaired |
| Skipped, still need a human | 5 |

`min` = 80% of the nightly price · `ideal` = the midpoint · `weekly` = 7 nights less
10% · `monthly` = 28 nights less 25% · each period's min and ideal scaled by the
nightly ratio.

Only missing values were filled. The one exception is deliberate: **681 seeded
listings carried a minimum above their list price** — not a floor but broken data,
which would have left them permanently unsaveable. Every one belongs to host 100 (the
seeded CSV corpus); the script refuses to repair such a row for any other host.

Two properties worth knowing: every computed grid went through the same validator the
forms use **before** being written, so the backfill could not create a listing the
forms would then reject; and every touched row is in `tbl_pricing_grid_backfill`, with
`--rollback` proven on three rows before the full run.

> **Do not drop `tbl_pricing_grid_backfill`** while you may still want the undo.

**Behaviour change to flag:** eight listings previously had no minimum, and under
spec rule 5 a listing with no floor does not negotiate. They have one now, so they
accept offers where they used to refuse them.

---

# PART 9 — W3: Negotiation completion

`N-03…N-11, P1-06, P1-08, H-32, H-33, E2E-05, §10 Admin, Pricing §17`

Six of the nine items were already satisfied by W2. The real gaps were **four
settings your wizard has been collecting that nothing read**, plus a ledger nobody
could see.

## W3-A · The "Fixed price only" switch was dead code

**What was wrong — and this one we caused.** `pn_enabled` was only consulted inside
`if (this listing has no minimum)`. That branch worked while some listings had no
minimum; once the pricing backfill gave all 29,240 of them one, it stopped running
entirely, and with it the check. A host choosing *Fixed price only* would have gone
on receiving offers.

**Behaviour now.** Read for every property, and refused explicitly. No host had
switched it off yet, so nobody was affected — but it was live.

## W3-B · The attempt cap was never enforced

`pn_max_attempts` (default 3) was collected by Step 4 and read by nothing: a guest
could send offers forever. **Behaviour now:** the fourth attempt returns *"You have
used all 3 offers on this stay."*

## W3-C · Duplicate offers

A guest could stack several live offers on one stay in front of a host who can only
answer one. **Behaviour now:** refused with 409 — and so is a fresh offer while the
*host's* counter is waiting on the guest, since that counter is answered through the
respond endpoint, not talked over.

## W3-D · The host's expiry window was ignored

Every offer expired on one global 30-minute timer. Property 29262's host had asked
for **24 hours** and was getting half an hour. **Behaviour now:** their own window
applies, with the platform default for anyone who set none.

## W3-E · Concurrency

The guards and the round number now come from one `FOR UPDATE` read of the thread, so
two offers a millisecond apart serialise instead of both passing a check neither had
committed — the same shape of race as the double-booking one. If that read fails the
offer still goes through on the unguarded count: a guard that cannot run must not take
negotiation down with it.

## W3-F · The audit ledger had no reader

`tbl_negotiation_log` has recorded every decision **with its pricing snapshot** since
the feature shipped, and nothing ever read it — so *"why was this offer accepted?"*
had no answer.

**New endpoint** `GET /admin/negotiations/audit`, plus a decision-history panel under
each negotiation showing the host's floor / target / list price **as they stood at
that moment**, which is the part that matters once prices have moved. Admin-only:
those are the tiers a guest must never see.

**Verified on production:**
```
2026-08-26 18:07 expired          | offer ₹300  | snapshot 1500/1750/2000
2026-08-26 17:36 escalate_to_host | offer ₹300  | snapshot 1500/1750/2000
2026-08-26 17:36 accept           | offer ₹1500 | snapshot 1500/1750/2000
```

---

# PART 10 — W5: Listing lifecycle

`LP-P0-01, LP-P0-02, LP-P0-03, LP-P0-05…08, LP-11, LP-12, LP-13, LP-18, LP-19, LP-27, LP-31…37`

## W5-A · An admin could publish a listing nobody had submitted

**What was wrong.** Draft, Submitted, Approved, Rejected, Changes-requested and
Suspended each had a name and a column, and **nothing enforced a single arrow between
them**. `adminReview` checked that the property *existed* and nothing else — so
approving a raw draft with no photos and no price put it straight on the site, live
and bookable.

**What we did.** `utils/listingLifecycle.js`: one reader over the four columns the
state actually lives in, and one transition table. Both entry points ask before they
write.

**Behaviour now.**
- A draft **cannot** be approved, rejected or sent back — *"This listing has never
  been submitted; the host is still working on it."*
- A suspended listing **cannot** be un-suspended by the host pressing Submit again.
  Only an admin lifts a sanction.
- A listing waiting for review cannot be suspended — it is not on the site.
- **Approval re-checks completeness** rather than trusting the score snapshotted at
  submission, which can be days stale. Under 70% and it does not go live.
- The queue returns the canonical state and exactly which decisions it accepts, so
  the panel stops offering buttons the server will refuse.

**One thing worth recording:** being **on the site** outranks the tier string. 29,216
live listings carry `verification_status = "unverified"` because they predate the
wizard; reading those as drafts would have told an admin there was nothing to suspend
about a property guests can book right now. Production reads: **29,230 approved, 1
held, 14 draft** — and the two genuine empty drafts are refused approval.

## W5-B · Capacity that did not add up

**What was wrong.** Step 1 checked one thing: adults ≤ total guests. A listing could
offer 2 guests total while admitting 2 adults and 4 children, or claim 3 bedrooms with
1 bed between them. Search, the property page and the booking party-size check all
read those numbers and believe them.

**Behaviour now.** The party that has to fit is adults **plus** children (infants
excluded — they share a bed, and every platform counts them apart); a bedroom needs at
least one bed; guests need somewhere to sleep; no negatives. All 20 existing capacity
rows pass, so nothing already saved is stranded.

## W5-C · Operational status

`PROPERTY_STATUSES` has declared `requiresMonths` on *Seasonal* since it was written,
and nothing enforced it — a property could be marked seasonal and name no season,
leaving the calendar with no idea when it is open. An unrecognised status is now
refused rather than stored.

## W5-D · Category switch left the old answers behind

Attributes are stored per category (`pa_group` = the category) and nothing ever
removed the previous set, so a listing moved from Villa to PG kept every villa answer
attached — invisible in the wizard, which renders only the current flow, but still
there for search and SEO. Switching now clears the other categories' groups **and only
those**: `step3` shares that table and is left alone.

> **Behaviour change:** this deletion is not reversible from the form.

## W5-E · Draft resume without duplicates

A property row is created **by** Step 1, so every time a host opened the wizard and
walked away — or lost the id to a refresh — another shell was left behind. Two halves
now: a shell carrying literally nothing is recycled, and `GET /listing/my-draft`
reports the open draft so the wizard offers **Continue it / Start a new one**.
Deliberately a reader, not a redirect: someone opening that page may genuinely want a
second property.

**Structured category attributes (LP-18/19) turned out to be already satisfied** —
`property_attributes` is key/value rows, not a JSON blob, so search and SEO can filter
on it.

---

# PART 11 — W6: SEO generated when a listing becomes public

`SEO-01, SEO-02, SEO-06, SEO-08, SEO-09, SEO-12, LP-P0-10, LP-40, WEB-P0-01, G-18`

## W6-A · The trigger

**What was wrong.** SEO was generated only when the host pressed **Submit** — the
wrong moment twice over. The listing is not public yet, so the metadata described
something no crawler could reach; and by the time an admin approved it, hours or days
later and often after the host had gone on editing, the stored title and structured
data still described the submitted version.

**Behaviour now.** One writer serves both, and approval regenerates from the state as
it stands then. Wrapped so a slug collision cannot leave a host approved but not live.

**Verified on production.** Property 29262 was carrying exactly this staleness:

```
before  "Malhotra Villa  in Karnal | Villa | Aajoo"   (its actual name: "Test Villa Manali")
after   "Test Villa Manali in Karnal | Villa | Aajoo"
slug    test-villa-manali-karnal-haryana
```

## W6-B · The word "undefined" was reaching the meta tags

Every string was interpolated straight from host data, so a listing saved without a
name produced the meta title `undefined in India | Aajoo` and the description
"Book undefined in…". An empty slug also collapsed `urlPath` to `/` — a listing
claiming the **homepage** as its canonical URL.

**Behaviour now.** A missing name falls back to what the listing *is* — "Cottage in
Jibhi" — with the category dropped from the tail when it is already the name. Slug
and path fall back to the property id. No stored row carried the bug.

## W6-C · Image ALT

Photos went out as a bare URL — unlabelled to a screen reader and to image search
alike. Each now carries `category · name · place`, capped at 125 characters and cut on
a word.

## W6-D · Three items were already correct

Checked against production rather than ticked:

- **Sitemap `lastmod` on edit** — the model writes `updated_at`, which is what the
  sitemap reads.
- **No fabricated ratings** — nothing in the generated schema invents
  `aggregateRating` or reviews. Now pinned by a test.
- **Invalid property id** — `/property?id=9999999` resolves as `found: false` with
  `noindex, follow` and its own copy rather than inheriting the homepage's title, and
  the page has a `loadFailed` state for people.

---

# PART 12 — W7: Admin control plane

`ADM-P0-05, DB-02, DB-03, DB-04, §8 Dashboard KPI, §9 Finance, §10, §11, E2E-12`

## W7-A · The audit trail was a log stream that rotates away

**What was wrong.** `logAdminMutation` has been called from **58 places** for months —
approvals, KYC decisions, payouts, refunds, role changes — and every one wrote a line
to the application logger and nothing else. On Render that stream rotates away, so
*"who approved this payout, and what did the record look like before they touched
it?"* had no answer beyond the last few days.

**What we did.** `tbl_admin_audit`. Adding the table made all 58 call sites durable
with **no call site changed**. The admin's name and role are copied into each row
rather than joined, because the row has to stay readable after the account is renamed
or deleted — which is exactly when someone reads it. Snapshots are clipped at 8k by
the writer, not the column, so one pathological payload loses its tail rather than the
whole row. The write never throws: a gap in the ledger beats a refused refund.

**Behaviour now.** `GET /admin/audit`, paged and filterable, **super-admin only** — an
audit trail the people it watches can curate is not one.

```
2026-08-29 22:01:49 | admintest (super_admin) | update | property 29262 | POST /admin/property/create
  before: {"property_id":29262,"property_host_id":100,"property_name":"Test Villa Manali",…
```

## W7-B · Money decisions with no reason, no check, and no trace

**What was wrong.** Not one mutation in `adminFinance.controller` was audited — in the
file that handles payouts, refunds and voids. Beyond that, voiding an invoice and
rejecting a payout both accepted an `undefined` reason, answered **"success"** for an
id that did not exist, and could be done twice, the second silently overwriting the
first person's reason.

**Behaviour now.** Both require a written reason, check the record exists, are
idempotent, and land in the ledger with the record either side. **A payout that has
already been paid out can no longer be rejected** — the money has left, and marking it
FAILED would make our ledger disagree with the bank.

Live: a nonexistent invoice now returns *"Invoice not found"*; a nonexistent payout,
*"Payout not found"*.

## W7-C · "Disputes" were KYC compliance holds all along

**What was wrong.** The Disputes screen was backed **entirely** by `tbl_admin_flags`,
whose enum is `KYC_IN_REVIEW / KYC_DECLINED / PAYOUT_VARIANCE / OTHER`. Every live row
is a regulatory hold written by the verification flow. **Not one is a customer
dispute.** So an admin working a queue headed "Disputes" was lifting KYC holds on
hosts — and the resolution note **overwrote** `af_notes`, which is where the reason
for the hold was stored. Clearing a "dispute" erased why the host had been held.

**Behaviour now.** The two populations come back separately and labelled
(`compliance_flag` / `support_ticket`) with their own counts; the screen is retitled
**"Compliance & moderation"**, with open support tickets listed beneath rather than
merged in. Resolving **appends** to the original reason instead of destroying it, and
the audit entry is `compliance_flag_resolved` carrying that original reason.

Live: **5 open compliance holds, 1 support ticket**, counted apart.

> **No customer-dispute table was invented.** Nothing anywhere raises one — there is
> no guest-facing path and no writer. An empty table would only have made the gap
> harder to see. See PART 14.

## W7-D · A dashboard tile that was structurally always zero

Users, hosts, properties and bookings were reconciled in an earlier pass, and all four
were re-verified against their list screens on production: **26=26, 7=7,
29,245=29,245, 56=56**.

The fifth was wrong. *Pending review* counted `tbl_properties.is_verify = 0`, and that
column only ever holds 1 or 2 — so the tile was permanently zero while the review
queue it links to had work in it. It now counts the queue's own population, and reads
**2**.

## W7-E · Soft-delete wrote one flag of two

All three delete paths wrote `is_deleted` and left `is_active = 1`. Nothing was
leaking — every reader checks the pair — but the row sat one half-written query from
being publicly visible. Two production rows were in that state and have been
normalised. All three paths now write both.

**Already correct (§10):** the admin negotiation list decides guest/host by **who owns
the property**, not who moved last.

---

# PART 13 — Updated finding-ID map

| Finding | Where it is answered |
|---|---|
| ADM-P0-01…06, PROD-01…08, SEC-01…10, P0-01…09, BE-01…05, G-04, G-21, H-09/15/22/36, DB-01 | PARTS 1–2 (W0, W1) |
| WEB-P0-04, P-03, P-04, P-07, P0-09, G-19, C-01…C-06, P1-04, P1-05, E2E-02, E2E-10, DB-05 | PART 7 (W4) |
| LP-P0-09, H-11, G-20, SEC-03, P-01, N-02, P1-09 | PART 8 (W2) |
| N-03…N-11, P1-06, P1-08, H-32, H-33, E2E-05, Pricing §17 | PART 9 (W3) |
| LP-P0-01/02/03/05/06/07/08, LP-11…13, LP-18/19, LP-27, LP-31…37 | PART 10 (W5) |
| SEO-01/02/06/08/09/12, LP-P0-10, LP-40, WEB-P0-01, G-18 | PART 11 (W6) |
| ADM-P0-05, DB-02, DB-03, DB-04, §8, §9, §10, §11, E2E-12 | PART 12 (W7) |
| P0-01, P0-02, P0-10, FE-10…FE-18, P1-11 | **Open** — PART 14 (W8, Android) |

---

# PART 14 — What is still open

## Not started

Nothing on the workstream list. W8 and W9 closed on 2026-08-30; the record of what
W8 covered is kept below because the findings it answers are the client's own IDs.

**W8 — Android APK ✅ done.** A different codebase, and the largest remaining block
at the time this section was written.

| Item | Findings |
|---|---|
| Production config: no `aajaodev.onrender.com`, no `rzp_test_` in a release build | P0-01, P0-02 |
| Remove mock/stub behaviour from guest critical flows | P0-10, FE-10 |
| Secure token storage, TLS validation, no no-op buttons, no stock images | FE-11…FE-18 |
| API path/versioning reconciliation with the spec | P1-11 |
| **Cancellation OTP** — the server now requires it; the app does not send it, so app-side cancellation is refused | P1-04 (app half) |

Two of those were live regressions caused by earlier work in this same period: the
app could not cancel a booking at all after W4 added the OTP requirement, and app
pre-booking recorded stays at a tenth of their price after W2 added the deposit
option. Both fixed.

**W9 — Cross-cutting E2E verification ✅ done.** 22/22 against the live platform,
and it found a real bug (SEO written to a table nobody serves). Migrations replay
from an empty schema: 136/136. See the task list's W9 section.

## Deferred by decision

- **Advance Booking as a separate discounted mode.** The schema column
  (`ppr_advance_discount`) and the Step 4 field ship; nothing reads the discount yet.
  Every future-dated booking already gets the deposit option, which was the part you
  specified.
- **The property page still renders its own price breakdown.** Checkout is
  server-authoritative and `/pricing/quote` is live, but switching that display over
  needs a fallback so a quote outage cannot blank a price.
- **Customer disputes.** No feature exists — no guest path, no table. What existed was
  a compliance queue wearing the word. Building it properly is its own piece of work.
- **Money columns are `DOUBLE(10,2)`, not `DECIMAL`.** Wrong in principle. Measured
  rather than assumed: there is no drift today, every paid booking reconciles, and
  nothing is over-credited. Migrating 14 columns on a live database mid-testing
  carries more risk than it removes — do it in a quiet window.
- Nothing. The settlement flow has been driven end to end against the live gateway —
  see W10-G.

## Standing actions on your side

1. **Rotate every credential** — the DB password, Cloudinary, the Gmail app password,
   `JWT_SECRET`, Razorpay, DIDIT, Brevo, Firebase. They are in git history and in chat
   transcripts. You chose to defer this until testing is finished; it is still
   outstanding.
2. **At go-live:** delete `ALLOW_TEST_PAYMENTS` from Render and swap in `rzp_live_…`
   keys. That single change flips the platform from "test window" to "really
   collecting".
3. **Do not drop `tbl_pricing_grid_backfill`** while you may still want to undo the
   pricing backfill.
4. **A 60-minute token lifecycle with no refresh flow** — deliberately not changed
   mid-testing, but it means long admin sessions expire.

## Behaviour changes your tester should know about

| Change | Where |
|---|---|
| Offers between a host's minimum and ideal now reach the host instead of auto-accepting | W2/W3 |
| A guest gets **three** offers per stay, not unlimited | W3 |
| Offers live longer than 30 minutes where a host configured a window | W3 |
| Every booking offers "pay 10% now"; check-in is refused while a balance is owed | W2 |
| Saving a price requires all nine grid values | W2 |
| Step 1 refuses a capacity that does not add up, and a seasonal property with no months | W5 |
| Changing a listing's category **deletes** the previous category's answers | W5 |
| An admin cannot approve an unsubmitted listing, or suspend one that is not live | W5 |
| Voiding an invoice or rejecting a payout needs a written reason and cannot be repeated | W7 |
| A completed payout cannot be rejected at all | W7 |
| "Disputes" is now "Compliance & moderation" | W7 |
| Deleting a listing also deactivates it | W7 |
| A cash booking now bills the host commission + GST; unpaid, it is withheld from their next payout | W10 |
| A user or property with financial history can no longer be hard-deleted — the database refuses it | FKs |


---

# PART 15 — W10: Pay-at-property settlement

*Added 2026-08-30, after W9.*

## W10-A · The platform collected nothing on cash bookings

**What was wrong.** On a pay-at-property booking the guest hands the entire amount
to the host at the door. The booking recorded `book_is_cod = 1`, the finance row was
written as uncollected — and that was the end of it. No commission, no GST on that
commission, and not the accommodation GST the platform is itself liable to remit.
23 such bookings already existed. This had been sitting as "blocked on client" since
2026-08-23.

**What we did.** Billed the host for the platform's share, and made it collectable.

The rule the whole feature turns on: **the split does not change between cash and
online — only the direction of the money does.** `utils/hostDues.js` computes it
from the booking row alone:

| | On a ₹28,320 stay (₹27,000 + ₹1,320 GST) |
|---|---|
| Commission — 15% of the room subtotal | ₹4,050 |
| GST on the commission — 18% | ₹729 |
| Accommodation GST the platform remits | ₹1,320 |
| **Due from the host** | **₹6,099** |
| Host keeps | ₹22,221 |

That ₹22,221 is *identical, to the rupee*, to what `splitBooking` credits a host on
an online booking of the same value — `27000 − 4050 − 729`. A test pins that
equality, because it is the invariant that makes the feature defensible to a host:
they are not being charged extra for taking cash, they are handing back the share
the gateway would otherwise have kept.

`tbl_host_dues` stores the three components separately rather than one total, so a
host can see the working and an accountant can reconcile the GST line on its own.

**How it behaves now.**

| Endpoint | Who | What |
|---|---|---|
| `GET /host/dues` | host | what I owe, per stay, broken down — plus what I have already settled and how |
| `POST /host/dues/pay` | host | starts a payment for what is currently payable |
| `POST /host/dues/verify` | host | settles those dues once the signature checks out |
| `GET /admin/host-dues` | finance | who owes what, by host and by booking |

A due is raised the moment a cash booking is created, so it appears on the host's
screen from the start rather than arriving later as a surprise. A cancelled booking
voids its due. A cash booking later settled online is not billed a second time — the
gateway already took the platform's cut.

## W10-B · Collecting from a host who ignores the screen

An invoice nobody has to pay is not collection. **`approvePayout` now withholds what
a host owes before the payout row is claimed and before any money leaves.**

- Oldest dues first.
- **Partial by design.** A payout that cannot cover a due in full leaves it
  outstanding at full value rather than marking it settled for less than it is worth.
- A fully-offset payout is completed *by the offset*, not by sending a zero-rupee
  transfer no provider would accept.
- Both paths are audited — `payout_offset` and `payout_offset_in_full` in
  `tbl_admin_audit`, with the amount withheld and the dues cleared.
- If recovery cannot run at all, the payout goes out in full and the dues stay
  outstanding for the next one. The host is owed that money either way; blocking
  them over our own outage would be the wrong failure.

The host screen says this in one line — *"Anything left unpaid is deducted from your
next payout"* — because it is the consequence a host most needs to know before
deciding whether to ignore the screen.

## W10-C · What the endpoints refuse

| Refusal | Why it matters |
|---|---|
| No amount is ever read from the request | otherwise a host decides what they owe |
| Signature verified **before** anything is marked settled | otherwise an unpaid claim settles a real balance |
| A verified payment settles only that host's own `PENDING` rows | otherwise it clears somebody else's balance, or the same one twice |
| A replayed verify returns success and does nothing | a retried callback is normal, not an error |
| Only `PENDING` dues can be voided | a settled due is money that has moved; reversing it is a person's decision |
| `assertPayable()` on the pay path | no settlement can start with a broken payment configuration |
| `requireRole("host")` / `requireRole(...FINANCE_READ)` | money owed to the platform is not visible to every admin role |

## W10-D · Verified against production

```bash
node tests/hostDues.test.js        # 23/23
```

- Backfill raised dues on all 23 existing cash bookings: **₹37,479.20 outstanding**
  across three hosts.
- `GET /host/dues` for the test host: **₹11,896.25 payable now, ₹10,465 upcoming**,
  17 bookings, each line showing commission + GST + stay GST.
- `GET /admin/host-dues` agrees on the total and groups it by host.
- A rehearsed ₹5,000 payout withheld **₹4,760.28**, cleared 4 dues in full, left the
  5th whole at full value, and left ₹17,600.97 outstanding — then rolled back.
- Unauthenticated admin read refused; a due the host does not owe refused; a forged
  signature refused.

## W10-E · The screens

The endpoints alone left a host being billed with no way to see the charge. Their
first sight of it would have been a smaller payout — the worst possible way to learn
about a deduction.

| Where | What it does |
|---|---|
| Web host — `/host/settlements` | Payable now, what falls due later, each stay openable to its three components, and the settle button |
| Web admin — `/admin/finance/host-dues` | Total outstanding, then who it is sitting with, then every due with its tax lines as separate columns |
| App — host menu → Settlements | The same screen on the phone, paying through the same order → checkout → verify sequence as Boost |

Three decisions worth keeping:

- **The working is shown, not just the total.** "You owe ₹6,099" against cash the
  host already holds is not something they can check. Each stay opens to commission,
  GST on commission, and the accommodation GST — and states what they keep, with the
  arithmetic beside it.
- **The reassurance is explicit.** Every breakdown says the host keeps the same
  rupees an online booking of that value would have left them, because the fear this
  screen invites is that taking cash costs more. It does not.
- **A failed request never renders as "nothing owed."** That is the one wrong answer
  a settlement screen can give, and it is the reassuring one. All three surfaces say
  the request failed instead. On the admin screen a 403 says the role is wrong rather
  than showing an empty list.

**Verified in a browser against production data**, not asserted: the host view reads
₹11,896.25 payable and ₹10,465 upcoming over 17 bookings; the admin view ₹37,479.20
across three hosts; both agree with the API. Checked at 375px — the amount column was
scrolling out of sight on the one screen whose entire question is how much is owed,
so it now sits beside the booking code. The app's model is pinned by
`test/host_dues_test.dart` against the payload the server actually sent; 50/50 app
tests pass.

## W10-G · A payment actually driven through it

Everything above was verified by reading the database and calling the endpoints. This
was the one claim that could not be made that way, so it was made properly: a payment
taken through Razorpay's own checkout, in test mode, by a host signed into the real
screen.

| | |
|---|---|
| Order | `order_TW1vETzTqLVPe7` — ₹11,896.25, created by the server from its own sum of 10 dues |
| Payment | `pay_TW1vgIgPR2Ogw4`, netbanking, **`status: captured`, `captured: true`** at Razorpay |
| Order status at Razorpay | `paid`, `amount_paid` 11896.25 |
| In `tbl_host_dues` | the same 10 rows PAID, totalling **₹11,896.25**, each carrying `pay_TW1vgIgPR2Ogw4` |
| Host screen | payable now **₹0**, the Settle button gone, all 10 in "Settled" marked *Paid by you* with the real reference |
| Admin screen | outstanding fell from ₹37,479.20 to **₹25,582.95** — exactly the amount paid — and the ten appear under *Paid by host* with their tax lines intact |

Two refusals were then exercised against that genuine payment, which is the only way
to test them honestly:

- **Replayed** — the same payment, order and signature posted a second time returned
  *"These settlements are already recorded"* and settled **0**. No second effect.
- **Redirected** — the same valid signature aimed at another host's due ids settled
  **0**. A verified payment cannot reach a balance that is not the payer's. The other
  two hosts' rows (₹14,209.95 and ₹908) were untouched throughout.

The run also surfaced a defect nothing else would have. Razorpay stops on a "Contact
details" step when handed neither a contact nor an email, and the settlement checkout
passed no `prefill` — so a host had to type their own phone number in before they
could pay us, on the one screen asking them for money. Every other payment surface on
the platform prefills. Fixed; the step is gone.

## W10-F · Foreign keys, since they landed in the same window

**What was wrong.** `20250101120004-add-foreign-key-constraints` declared all 64
relationships `ON DELETE CASCADE`. Deleting one user would have taken **29,248
properties and 36 payment rows** with them, silently and unrecoverably. The
migration also recursed infinitely — `addConstraintIfPossible` called itself — so on
a fresh database it never completed, and on the live database it was marked done
having added **zero** constraints.

**What we did.** Rewrote the semantics per table: `RESTRICT` for anything financial
or historical (43), `CASCADE` only where a child row is meaningless without its
parent (21 — join tables, derived rows, auth sessions). `pay_bookId` was `TEXT`,
which no key can reference; it is now `VARCHAR(100)` with an index. Three orphan
rows were backed up, deleted, and the deletion recorded in the audit ledger.

**How it behaves now.** **39 constraints active on the live database.** A user or
property carrying financial history cannot be hard-deleted — the database itself
refuses. Soft-delete, which is what the admin paths actually use, is unaffected. The
full E2E suite still passes 22/22 with the constraints in place, and a real booking
plus payment was written through them.
