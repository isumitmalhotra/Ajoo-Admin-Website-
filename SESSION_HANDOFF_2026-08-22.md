# Session Handoff — 2026-08-22

**Read this first.** Everything below was shipped and verified live. Nothing is
sitting uncommitted, and nothing is waiting on a deploy. That is unusual for
this project — the 2026-08-21 handoff opened with three commits that were never
pushed and never seen in a browser. Those are now live (they went out in this
session's predecessor); this session's work went out too.

The one thing genuinely blocked is at the very bottom: **the user's checklist
answers cannot be read from a Claude session** — they live in the user's own
browser storage and they must paste them.

---

## 1. What this project is

**Aajoo Homes** — a negotiation-first stay marketplace for India. A guest can
send a host a price offer instead of only accepting the listed rate. Everything
else (search, booking, payments, reviews, host payouts) exists to support that.

**The non-negotiable product rule: a guest NEVER sees a host's minimum or ideal
price.** Not in the UI, not in an API response, not in a debug payload. If a
change could expose either number, stop and flag it.

### Three repos, three deploy targets

| Repo | Path | Branch | Deploys to | Push with |
|---|---|---|---|---|
| Web frontend | `D:\Projects\aajao-frontend-vercel` | `redesign/aajoo-2026` | Vercel → https://aajoohomes.com | `git push origin HEAD:main` |
| Backend | `D:\Projects\aajaoBackend-render` | `main` | Render → https://aajaodev.onrender.com | `git push origin main` |
| Flutter app + docs | `D:\Projects\ajoo admin website` | `main` | nothing auto | `git push origin main` |

The API base URL is **`https://aajaodev.onrender.com`**. Note it is *not*
`aajaobackend-render.onrender.com` — that host answers "Not Found" and I wasted
a round trip on it this session. The fallback is hardcoded in
`src/axios/axios.ts`.

The Flutter app lives inside the third repo at `aajoo_app_2026/`. Live code is
under `lib/ui`; **`lib/screens` is legacy and still present — do not edit it
thinking it ships.**

### Stack

React + Vite + TypeScript + Redux Toolkit · Node/Express/Sequelize/MySQL
(Clever Cloud, hosted on Render) · Flutter + GetX · Leaflet/OSM with a
Nominatim proxy both platforms share · DIDIT for identity · Cloudinary for
media · Razorpay (test mode) · RazorpayX for payouts.

`src/redesign/` is the current web UI. `src/pages/` is the pre-redesign stack —
still routed in places, but not where new work goes.

---

## 2. Exact repo state at handoff

All three clean, all three pushed. Verified with `git fetch` + `git log
origin/main..HEAD` in each.

| Repo | HEAD | Unpushed |
|---|---|---|
| Backend | `d907bd4` fix(host): stop asking for the same thing three times, and let mobile login work | 0 |
| Web | `4b98aaf` fix(host): password fields you can see into, and one ask per fact | 0 |
| App/docs | `80d817a` fix(app): ask for identity once, and let people see the password they type | 0 |

**Production was checked, not assumed:**

- Web bundle on aajoohomes.com is `assets/index-jjE8tLPg.js` — byte-identical
  name to the local `npm run build`, so Vercel has this commit. Six marker
  strings grepped out of the live bundle (`Show password`, `City / Town *`,
  `Auto-reject below`, `Use a different account for this property`, `Take a
  selfie`, `e.g. State Bank of India`) — all present.
- Backend: `/listing/schema` returns the new `help` text on `builtup_area`, and
  all three login error paths were exercised against production with `curl`.
- `flutter analyze`: **0 errors, 0 warnings in `lib/`** (608 `info` lines, all
  from the `ionicons` package, pre-existing).
- Release APK built: `aajoo_app_2026/build/app/outputs/flutter-apk/app-release.apk`,
  94 MB, delivered to the user.

---

## 3. What this session was about

The user supplied **`Host problems.pdf`** and then the same content as
**`Untitled document.docx`** with 11 embedded screenshots. Twelve numbered
issues, plus two standing instructions:

> "some pointers in the property fields are repeated multiple times analyze
> them once and make sure we are not asking same information again and again"

> "after making the changes update the host readliness testing doc if needed"

All twelve are done. The de-duplication analysis is in §5.

### 3a. The two actual bugs

**Mobile-number login always failed (#4).** This was the headline one.

`loginUser` resolves a non-email identifier by looking the phone up in
`tbl_users` — with **no `user_isDelete` filter and no ordering**. Phone numbers
are heavily reused here: the user's own number `8901717173` carries *five*
rows (three soft-deleted, plus a live guest #126 and a live host #151). The
lookup returned a deleted account, the credential lookup for that id found
nothing, and a correct number with a correct password was answered
**"No record found"**. Email login was never affected — it queries
`tbl_user_cred` directly.

Two things were needed, not one. Deleted rows had to go, *and* the same number
can legitimately hold both a guest and a host account — so the fix resolves the
set of live ids and lets the credential row's `cred_user_isHost` pick the right
one.

This is the **second** time this exact bug class has bitten (BotPenguin phone
lookups were the first). It is now written to memory as
`duplicate_phone_accounts.md`.

**PDF uploads were rejected outright (#11).** `/listing/media/upload` ran
multer's **image-only** filter, so every PDF Aadhaar and every PDF electricity
bill was refused before reaching a controller that handles PDFs perfectly well
(`resource_type: 'auto'`, folder `property_documents`). The identical bug had
already been fixed twice — once for signup, once for property-create — and this
route was missed both times. The route now uses `uploadDoc`; the
photo-must-be-an-image rule moved into the controller, where `req.body.kind` is
reliably parsed and can't be defeated by multipart field ordering.

### 3b. The other ten

| # | Issue | Where fixed |
|---|---|---|
| 1 | No show/hide on any password field | Web: new `PasswordInput` replaces **all 11** bare inputs. App: reset-password screen (login/change-password already had toggles) |
| 2 | Address + City/Town not mandatory at signup | Web form + `schema/user.schema.js` (`user_city` was commented out). App already required both |
| 3 | Login said "No record found" for everything | Three distinct messages now — wrong password / wrong tab / unknown identifier |
| 5 | Nothing warned an unverified account | New `VerifyNudge` on host **and** guest dashboards, web **and** app |
| 6 | Continue didn't scroll to the next step's top | Web wizard. App already did this |
| 7 | Built-up Area gave no unit hint | `config/listingSchema.js` `help` — one change, both platforms render it |
| 8 | Auto-reject/auto-accept: % or rupees? | Labels now read "(₹ per night)"; hints do the arithmetic against this listing's own rate |
| 9 | No example ranges on pricing fields | Web + app |
| 10 | Damage/compensation boxes were blank and abstract | Web (see scope note below) |
| 12 | Bank name accepted `4974000100062410` | Web (2 places) + app; also account-holder, emergency and caretaker names |

### 3c. Scope note — four items are web-only, correctly

I checked rather than assumed. **These fields do not exist in the Flutter app
at all**, so there was nothing to fix there:

`auto_reject_below` · `auto_accept_above` · `max_negotiation_percent` ·
`damage_reporting` · `compensation_rules` · any selfie field

If the client asks why the app lacks the damage policy and advanced negotiation
limits, that is a **feature gap, not a bug** — and it is a reasonable next piece
of parity work.

---

## 4. The duplication analysis (the client's specific ask)

Two things were being collected more than once. Both are fixed.

### Identity — was asked THREE times

1. Signup step 2: ID type, ID number, Upload ID — all optional, all sitting
   *directly beneath the form's own note* saying identity is verified in the
   next step and there was no need to type it there.
2. DIDIT — the real check, the only source anything downstream trusts.
3. Listing wizard step 5 — type, number, document scan, selfie.

**Now:** signup does not ask (the app's entire third step is gone, signup is
two steps). The wizard shows verified hosts a green confirmation with no
fields, and offers unverified hosts the DIDIT check first with manual entry as
a fallback. An admin acting for a host is never offered "verify my identity" —
they cannot verify an identity that isn't theirs.

### Bank details — was asked once PER PROPERTY

There are genuinely two stores, and this is the part worth understanding:

- **`tbl_host_acc_details`** — the host's payout account. Encrypted at rest
  (AES-256-GCM), penny-drop verified, wired to RazorpayX. **This is the account
  that actually receives money.**
- **`property_bank_details`** (`pbd_*`) — a per-property copy typed into wizard
  step 5. Unverified, and *not* what pays out.

So a host with five listings typed the same five fields six times, and the copy
they typed in the wizard — believing they were setting up payouts — was never
used. `getReadiness` now returns a masked `payoutAccount` summary and the
wizard displays it, with "Use a different account for this property" for anyone
who genuinely wants one.

### The knock-on I found while doing it

`readinessFrom()` scored **both** facts from per-property rows only. A host who
had verified with DIDIT and set up payouts on their profile still saw "Identity
verified" and "Bank details" unticked on every listing, lost 20 of 100 points
for work already done, and could be held under the 70% publishing threshold by
it. Worse, `submitListing` computed the score a second time with the same blind
spot, so the number on screen could disagree with the number enforced.

`readinessFrom(state, host)` now takes the host-level facts, and both call
sites pass them.

---

## 5. Files changed this session

### Backend — `D:\Projects\aajaoBackend-render` (`d907bd4`)

| File | What |
|---|---|
| `controllers/user.controller.js` | `loginUser` — the phone-lookup fix and all three error messages |
| `controllers/listingStep5.controller.js` | `getReadiness` returns `identity` + `payoutAccount`; `readinessFrom(state, host)`; `submitListing` passes the same facts; new `models_hostAcc()` helper |
| `controllers/listingMedia.controller.js` | photo-vs-document enforcement, with temp-file cleanup on refusal |
| `routes/listingEngine.routes.js` | `upload` → `uploadDoc` on `/listing/media/upload` |
| `schema/user.schema.js` | `user_city` required |
| `config/listingSchema.js` | `help` on `builtup_area` and `area_unit` |

### Web — `D:\Projects\aajao-frontend-vercel` (`4b98aaf`)

| File | What |
|---|---|
| `src/redesign/components/PasswordInput.tsx` | **New.** One reveal-capable field; used by all 11 password inputs |
| `src/redesign/components/VerifyNudge.tsx` | **New.** Dashboard prompt; renders nothing for verified or still-loading |
| `src/redesign/pages/Register.tsx` | Step 2 rewritten — ID fields removed, address/city required with field-level highlight + focus |
| `src/redesign/pages/host/ListProperty.tsx` | Scroll-to-top; `FIELD_HINT`/`baseRate`; every money hint; conditional identity + bank sections; `capture` selfie |
| `src/redesign/pages/Login.tsx`, `ForgotPassword.tsx`, `guest/Settings.tsx`, `components/SecurityPasswordCard.tsx` | `PasswordInput` swap |
| `src/redesign/pages/GuestDashboard.tsx`, `host/HostDashboard.tsx` | `VerifyNudge` |
| `src/redesign/pages/host/Profile.tsx` | Bank name letters-only |
| `src/services/listingApi.ts` | `identity` + `payoutAccount` on `ReadinessResult` |

### App — `aajoo_app_2026/` (`80d817a`)

| File | What |
|---|---|
| `lib/ui/screens_common/auth/basic_info/basic_info_screen.dart` | Step 3 deleted; 3-step wizard → 2; ~13 now-dead methods pruned |
| `lib/ui/widgets/verify_nudge.dart` | **New.** Mirrors the web wording |
| `lib/ui/screens_host/listing/listing_wizard_screen.dart` | `_p5Text` gains `help`/`formatters`; conditional identity + bank; pricing hints; name fields filtered |
| `lib/ui/screens_common/auth/forgot_password/forget_password_page.dart` | Two eye toggles |
| `lib/ui/screens_renter/dashboard/dashboard_screen.dart`, `lib/ui/screens_host/home/host_home_screen.dart` | `VerifyNudge` |

---

## 6. Technical notes worth keeping

### From this session

- **Two `AuthController` classes exist in the Flutter app.**
  `lib/controller/auth_controller.dart` and
  `lib/ui/screens_common/auth/auth_controller.dart`. Only the **second** is
  registered (`lib/binding/init_binding.dart`). `Get.find<AuthController>()`
  against the wrong one **compiles cleanly and throws at runtime** — I hit this
  writing `verify_nudge.dart`. Check the import before using `Get.find`.
- **`AppInputFormatters` helpers are `name` and `place`**, not `personName` /
  `placeName`. Also `digits(n)`, `mobile`, `pincode`, `amount`,
  `upperAlnum(n)`. Web equivalents live in `src/redesign/lib/inputTypes.ts`
  (`nameOnly`, `placeOnly`, `digitsOnly`, `decimalOnly`, `codeOnly`, …). Keep
  the two in step.
- **A Dart method-removal regex must anchor on two-space indentation.** A
  pattern like `\n[ \t]*\w+ _method\(` also matches the *call site*
  `return _buildStep3(theme);` and will delete from there to a brace in a later
  method. Anchor `\n  (?! )` — class-member level.
- **Python's `io.open(..., "w")` writes CRLF on Windows.** Harmless for the
  source repos (git normalises to LF in the index — I verified the diffs are
  small, not whole-file rewrites), but it breaks `\n`-anchored regexes when you
  later parse those files. Use `\r?\n`.
- **Top-level `return` is legal in a CommonJS script** and silently ends the
  whole file. Use `continue` inside loops in throwaway node test scripts.
- Bash heredocs choke on some of the JSX/Dart content I was inserting. Writing
  the Python patch script to a file in the scratchpad and running it is more
  reliable, and gives an atomic apply — every script asserts
  `s.count(old) == 1` before writing, so a failed match leaves the file
  untouched.

### Carried forward (still true, still bites)

- **React remount bug.** A component declared *inside* another and rendered as
  JSX gets a new identity every render, unmounting its whole subtree. This
  caused the "type one letter, click again" complaint (`Shell` in
  `ListProperty.tsx`, now hoisted to module scope). The Flutter equivalent is a
  `TextEditingController` created inside `build()`.
- **Booking dates are `DD-MM-YYYY`** in API payloads.
- **The server clock runs ahead.** Do not treat small future timestamps as bugs.
- `/properties/search` nests the property under `data.property`.
- The API envelope is always `{success, message, data}`.
- `verification_status` is a *session* status. An abandoned DIDIT attempt
  leaves it stale — gate on `verificationIsCurrent()` (`utils/kycGate.js`),
  never on `user_isVerified` (19 accounts carry `=1` with no KYC behind it).
- **Render is on the free tier and spins down after 15 minutes.** The
  intermittent blank responses are this, not a crash loop (uptime climbs
  steadily 92→113→133s). The GitHub keep-alive Action fires at 16–40 minute
  gaps, which is wider than the 15-minute sleep. **The fix is the $7/mo Starter
  plan** — worth raising with the client before go-live.
- `safeMessage()` / `utils/safeError.js` wraps errors at 261 call sites. Never
  return `err.message` raw; the classifier exists so DB text cannot reach a UI.

---

## 7. Testing artifacts

Three interactive checklists. They save answers in the browser's
`localStorage`, colour-code pass/fail/blocked, and have a **Copy report**
button that produces markdown of everything failing.

| Doc | URL | Size |
|---|---|---|
| **Host readiness** | https://claude.ai/code/artifact/34df640c-ea5a-45b3-8c90-e65768b595f7 | 13 phases, **125 checks** |
| **Guest readiness** | https://claude.ai/code/artifact/20985523-4e8d-4d14-b76e-195e0633f9e7 | 14 phases, 101 checks |
| **Admin readiness** | https://claude.ai/code/artifact/9801e05e-06d3-4012-a843-3761533d440e | 14 phases, 119 checks |

The host doc gained a **"Host feedback document"** section mapping all twelve
issues to a check, plus new rows for mobile login, the wrong-tab message, PDF
upload, scroll-to-top, and the de-duplication.

### The storage-key change — important if you edit these

Answers were keyed by **row position** (`"<sectionIndex>|<itemIndex>"`). Adding
a row mid-section therefore shifts every answer below it onto the wrong check —
a document quietly claiming the user tested things they hadn't. This session
added rows mid-section, so:

- Keys are now `"<section title>::<check title>"` — stable across insertion,
  reordering and renaming.
- Each page carries a **one-time migration** (`LEGACY_KEYS`) that remaps old
  positional keys through the ordering they were recorded against. For the host
  doc, **90 of 91** existing answers map; the 91st ("Step 5 identity") was split
  into two more specific checks, so there is nothing left for its answer to
  describe.
- The map resolves by **check title against the new data**, not by old section
  title — otherwise renaming "Regression — today's fixes" to "Regression —
  earlier fixes" would have orphaned all six of its answers.
- Verified by simulation, not by inspection: `scratchpad/test_migration.js`.
- All three docs have unique keys (125 / 101 / 119, zero collisions) — assert
  this again if you add checks, because a duplicate title silently merges two
  checks' answers.

**Build tooling** (session scratchpad —
`C:\Users\Asus\AppData\Local\Temp\claude\D--Projects-ajoo-admin-website\98ff0efb-3190-4f8f-bdec-7a413a69a1db\scratchpad\`):
`_shell_head.txt`, `_shell_tail.txt`, `_renter_data.js`, `_admin_data.js`,
`build.js`, plus `stable_keys.py`, `fix_legacy_map.py`, `test_migration.js`.
Host data is inline in `host-checklist.html` (there is no `_host_data.js`);
`host-checklist.bak.html` is the pre-edit copy the migration was built from.
**Scratchpad is session-scoped and will be gone next session** — if these
matter, copy them into the repo.

---

## 8. THE ONE BLOCKED THING

The user said: *"also check the state of the host doc that i marked for some
items and some things i mentioned there to check ad fix that too"*.

**Their ticks are in their own browser's `localStorage`. A Claude session
cannot read them.** I told them this and asked them to press **Copy report** at
the bottom of the host checklist and paste the output. **That paste has not
arrived yet — it is the first thing to chase.** Whatever they marked failed is
unaddressed work.

---

## 9. Pending / next up

**Immediate**

1. **Get the checklist report pasted** (§8) and work through whatever failed.
2. Have the user install the new APK and confirm the two-step signup and the
   dashboard verification prompt.

**Blocked on the client / on credentials**

3. **Payouts cannot move money** until 4 RazorpayX env vars are set on Render.
   Code is complete (RazorpayX + penny drop + AES-256-GCM). See
   `PAYOUTS_SETUP.md`.
4. **Render env is NOT correctly set** — verified previously; the secrets
   cutover is blocked on it. See `RENDER_ENV_CHECKLIST.md`.
5. **Render free-tier spin-down** — recommend the $7/mo Starter plan before
   go-live (`KEEP_ALIVE_SETUP.md` explains why the keep-alive Action is not
   enough).

**Known risks worth clearing**

6. **Cloudinary account is shared and polluted** — 704 assets, and a real
   person's CV was once published as a property photo (fixed 2026-08-03, assets
   deleted). **It may hold more PII.** An audit has not been done.
7. Android Maps API key restriction has never been checked.
8. `/help-center` has no container.

**Feature parity**

9. The app has no damage policy and no advanced negotiation limits (§3c).
10. `WEB_MOBILE_PARITY.md` is the running ledger.

**Client bug sheets**

11. `BUG_TRACKER_2026-08-12.md` — Block W (20 web/admin) done; Block A done
    through A-59. `_Web App Bugs.xlsx` is the source.

---

## 10. Working agreements with this user

- **Greenlight to test everything.** Verbatim: *"for android i am starting
  emulator and for web launch either the production site or local server to
  test as you wish as there are no real users anywhere for now only testing
  data and testing users are there so you have a greenlight to perform all the
  actions that you want on all the portals as well"*.
- **Quality bar, verbatim:** *"i don't want to redo everything again and again
  as i am spending my time and money over claude i expect best outputs not
  silly developers mistakes"*. Read the reference properly before building.
  **Verify against production rather than reporting from intent** — this
  session grepped the live bundle and curl'd the live API for every claim in §2.
- **Parity rule:** fix renter/host bugs on both platforms in the same pass, and
  say explicitly when a platform genuinely lacks the field (§3c) rather than
  quietly skipping it.
- **Standing security line:** do not type real bank account numbers or IFSC
  codes into forms. Test bank forms by submitting empty fields to check
  validation only.
- **`BOTPENGUIN_API_TOKEN` lives only on Render.** The repo's own checker
  deliberately never handles it in plain text — do not extract it.
- Correct mistakes plainly and move on. I got two things wrong in earlier
  sessions (claimed a Reserve error was console-only when there was a real
  toast; claimed the app had no KYC in checkout when it navigates by route
  string, which my class-name grep missed). Both were corrected in one sentence
  without ceremony, which is what this user wants.

### Test credentials

| Role | Login | Notes |
|---|---|---|
| Host | `aajoo.host1@mailinator.com` / `Host@12345` | user 100 · phone `9625236254` |
| Guest | `sumit.m@zyphextech.com` / `Haryana@2706` | user 126 |
| Guest (BotPenguin) | phone `9611577338` / `Renter@12345` | user 101 |
| Admin | `admin@mailinator.com` / `Admin@123` | field is `username`, **not** email |

Login payload fields are `user_email` / `user_password` / `isHost`. **`user_email`
also accepts a 10-digit mobile number** — that is what this session fixed.

The user's own number `8901717173` has five accounts on it (§3a). Keep that in
mind when they report something odd about their own login.

---

## 11. Reference docs in the repo root

| File | What |
|---|---|
| `SESSION_HANDOFF_2026-08-21.md` | Previous session — nav/search rebuild, themed 404 |
| `PAYOUTS_SETUP.md` | The 4 blocking env vars |
| `RENDER_ENV_CHECKLIST.md` | Env cutover |
| `KEEP_ALIVE_SETUP.md` | Why free-tier keep-alive is insufficient |
| `WEB_MOBILE_PARITY.md` | Parity ledger |
| `BUG_TRACKER_2026-08-12.md` | Client bug sheets |
| `DIDIT_WORKFLOW_SETUP_GUIDE.md` | Identity provider config |
| `MASTER_PENDING_TASKS.md` | Longer-range backlog |
| `DEPLOY_RUNBOOK.md` | Deploy + live-DB migration commands |
| `CODEBASE_INDEX.md` | Where things live |
