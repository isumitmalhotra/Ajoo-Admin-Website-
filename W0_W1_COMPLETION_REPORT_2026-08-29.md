# W0 + W1 Completion Report — Production Hardening & Authorization

| | |
|---|---|
| Date | 2026-08-29 |
| Backend commits | `00c1a69` → `d0d2f7d` (7 commits), all pushed and **deployed** |
| Migrations applied to the live DB | `20260829120000-admin-roles`, `20260829150000-revoked-tokens` |
| Test suite | 15/15 files, 486 files parse, 71 new unit tests across W0+W1 |
| Production verification | **29/29 checks passed against the live API on 2026-08-29** (every claim below was re-verified the day this report was written, not remembered) |
| Source findings | `AAJOO_ADMIN_DASHBOARD_FULL_QA_AUDIT`, `AAJOO_APK_FINDINGS`, `AAJOO_WEBSITE_FINAL_GUEST_HOST_FINDINGS` |

**How to read this document.** Each section answers four questions: *what was wrong*,
*what we did*, *how the system behaves now*, and *how to check it yourself*. The check
commands are copy-paste ready and state the exact expected output. `$API` means
`https://aajaodev.onrender.com`.

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

# PART 5 — Standing actions on your side

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
