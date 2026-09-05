# AAJOO Homes — Master Pending Tasks (single source of truth)

> **Reconciled 2026-09-04** against the live site, the live database and the three
> repos; **updated 2026-09-05** after tester builds 14–16, the proactive defect
> sweep, and a fresh set of DB counts. Supersedes the 2026-07-11 edition, which
> had drifted badly — nine of its open items were already done and two of its
> "done" claims were wrong.
>
> **Repos:** FE `D:/Projects/aajao-frontend-vercel` (React/Vite → Vercel) ·
> BE `D:/Projects/aajaoBackend-render` (Node/Express/Sequelize → `aajaodev.onrender.com`) ·
> Mobile `aajoo_app_2026/` (Flutter). Deploy = push to `main`; **DB migrations do NOT auto-run.**
> Tester build in circulation: **16 (1.0.0+16)**, `aajoo-homes-1.0.0-build16-release.apk` at repo root.
>
> **How to read the evidence column.** `verified` = checked against production or
> the live DB and the check is named (dated 09-04 unless it says 09-05). `code` =
> read in the source. `carried` = taken from the previous edition and **not**
> re-checked — treat those as the least trustworthy rows here.

---

## How this list is ordered

By **who is blocked**, not by component. Most of what is left is not engineering
work; sorting by owner is what makes that visible.

| Section | Owner | Open |
|---|---|---|
| [1. Client decisions](#1-blocked-on-client-decisions) | Client | 7 |
| [2. Ops / Render access](#2-blocked-on-ops--render-access) | Whoever holds Render + GCP | 6 |
| [3. Engineering](#3-engineering--genuinely-open) | Us | 12 |
| [4. Contract deliverables](#4-contract-deliverables-) | Us | 8 |
| [5. Section-0 redo](#5-section-0-site-redo--separate-sow) | Blocked on a signed change order | 20 |
| [6. Unproven, not broken](#6-unproven-not-broken) | Us + tester | 9 |

**If only two things get done:** §2.1 (live payment keys) and §1.1 (delete the
seed listings). The first means the product currently looks like it is taking
money and is not. The second gates every honest SEO number on the site.

---

## 1. Blocked on client decisions

| # | Item | Why it is blocking | Evidence |
|---|---|---|---|
| **1.1** | **Delete the 29,227 seed listings** | 29,236 undeleted listings; **29,227 belong to host 100 and are live**, 16 belong to real hosts. Sitemap excludes host 100, so the public site is **26 URLs** (5 property, 7 blog, 14 pages). Every SEO figure, every bulk preview and every template test is measured against fabricated data until these go. | verified 09-05 — DB count, live sitemap |
| **1.2** | **Cookie consent banner, then analytics** | GA4/GTM fields are wired and the master switch is off *on purpose*. Turning it on first sets profiling cookies with no way to decline. Legal exposure, not a marketing preference. | verified — Global SEO screen |
| **1.3** | **Cash / UPI collection — 4 decisions** | The rail is **built** (`tbl_host_dues`, 24 rows, offset against payouts). What is still missing is policy: who confirms collection, when, how the 15% + GST is recovered, and what happens if the host never confirms. Detail in §7. | verified — 24 rows in `tbl_host_dues` |
| **1.4** | **Cancellation-policy final copy** (was E-4) | `normaliseCancellationPolicy` ships Flexible/Moderate/Strict and the host picks one at listing time. The *text shown to guests* is still placeholder. | code |
| **1.5** | **Weather provider + key** (was E-2, RENT-7) | Renter-dashboard weather widget cannot start without a provider choice. | carried |
| **1.6** | **Brand assets** — logo set, favicon/PWA icons, animated illustrations, WhatsApp number, social links, reference designs (was E-5, S0-ASSET-1…5) | Gates most of Section-0. | carried |
| **1.7** | **The four test listings that are now the public catalogue** | Of the 5 live real-host listings, **4 were approved on 2026-09-04 so the site was not empty** after approval started gating visibility: Garg Resorts (29263), Tharamani Farm Retreat (29265), Vrindavan Garden Farm Stay (29277), Delhi Green Farm Stay (29279 — the last two renamed from "Aish mobile host property…"). They are tester accounts' listings with tester phone numbers. Decide whether they stay through launch or come down with the seed data. | verified 09-05 — `property_submission` + `tbl_properties` |

---

## 2. Blocked on ops / Render access

| # | Item | Failure mode if missed | Evidence |
|---|---|---|---|
| **2.1** | **Live Razorpay keys + `ALLOW_TEST_PAYMENTS` off** | Checkout opens, the booking confirms, an invoice is issued — and **nothing is collected**, because every order was created against the bundled test key. Invisible from the UI by design; `/health/env` reports it. | code — `config/payments.config.js` |
| **2.2** | **RazorpayX credentials** (`RAZORPAYX_KEY_ID`, `_KEY_SECRET`, `_ACCOUNT_NUMBER`, `_WEBHOOK_SECRET`) | Approving a payout fails at the click with "Payouts are not configured". **Not verifiable without pressing Approve on a real ₹27,980 payout**, which was not done. Assume unset until someone checks Render. | unverified — see note |
| **2.3** | **`REQUIRE_IMAGE_ALT=true`** | Server accepts an image upload with no description. Both clients have refused to upload without one since build 12; **build 16 is with testers now**, so there is no longer a reason to wait. | code |
| **2.4** | **`HEALTH_TOKEN` (or `ADMIN_API_TOKEN`) unset** | `/health/env` returns bare `{"ready":true}`. The detail — including **`dbCutoverSafe`**, the check that would have caught July's outage — is unreadable by anyone. | verified 09-05 — probe still returns `{"ready":true}` only |
| **2.5** | **Credential rotation** | Deferred by instruction. Everything historic is in git history: DB password, Razorpay secret, Cloudinary secret, Gmail app password. | carried |
| **2.6** | **Google Cloud budget alert** | Maps + Places keys are live and unmetered. | carried |

> **On 2.2 —** the "not configured" message is raised inside the *approve*
> handler, not on page load, so its absence from the Payout Queue proves nothing.
> The queue renders and shows QUEUED/FAILED rows either way. The honest state is
> unknown; confirm in Render rather than by clicking.

---

## 3. Engineering — genuinely open

| # | Item | Notes | Evidence |
|---|---|---|---|
| **3.1** | **Purge junk categories** | `/common/categories` serves **13** to the public, including `Resort`, `couple`, `party` and `Pool House`. `tbl_categories` also holds `test`, `test`, `add one cate`, `Test Api Category updat`. One UPDATE fixes web **and** app. This is the app sheet's A-52. | verified — public endpoint |
| **3.2** | **64 of 65 images have no ALT text** | Blocks image-sitemap captions, which cannot populate until descriptions exist. | verified — Image SEO screen |
| **3.3** | **WebP / `f_auto` delivery** | Cloudinary URLs carry no `f_auto`. Core Web Vitals, not indexing. | verified — sitemap image URLs |
| **3.4** | **`/` and `/explore` have identical titles** | Two pages competing for one query. One line of copy, or canonical `/explore` → `/`. | verified — SEO Health |
| **3.5** | **Orphan pages / broken internal links** | Needs a crawl of the rendered site; nothing in the admin does one. The health dashboard lists it as unchecked rather than reporting a false zero. | verified — SEO Health |
| **3.6** | **Cloudinary account audit** | Shared/polluted account, ~704 assets. It has already published a real person's CV as a property photo once. Nobody has swept the rest. | carried |
| **3.7** | **Host `whatsapp` field** (was HOST-17) | Column still absent from `tbl_users`; a front-end-only change is dropped by `stripUnknown`. Needs a migration first. | verified — `SHOW COLUMNS` |
| **3.8** | **Admin Notification Management** (part of S0-ADM-1) | The only module from that list with no route. CMS, SEO, Coupons and Analytics all exist. | verified — 0 routes in `App.tsx` |
| **3.9** | **Lucide icon migration** (S0-BRAND-3) | `lucide-react` installed; MUI icons still in use app-wide. Cosmetic, and cheaper to do inside Section-0. | carried |
| **3.10** | **Web lint baseline is red** | `npm run lint` reports **~600 problems, 540 of them `no-explicit-any`**, so lint cannot gate the Vercel build (which runs `tsc -b` only). The empty-catch rule added on 09-05 therefore only bites when someone runs lint by hand. Either downgrade `no-explicit-any` to a warning and clean the rest, or fix the anys — then add `lint` to the build. | verified 09-05 — `eslint .` |
| **3.11** | **Report of listings whose stored contact fails the 6–9 mobile rule** | Two of yesterday's renames were blocked because the admin form re-validated a stored `1425369807`. The form now validates only what changed, but the junk is still stored and will surface the next time a host edits those listings in the wizard. A one-off query + host nudge. | verified 09-05 — the two numbers |
| **3.12** | **Leftovers from the sweep** | (a) Two screen-level empty catches remain in the app (`host_profile.dart:67`, `csc_picker.dart:750`); every *service* is clean. (b) `tbl_book_statuses` ids 12/13/14 double as payout-request states (`statusPayoutPending/Successfull/Failed` in `commonConfig`); 13 now counts as revenue by decision, but a booking table sharing ids with a payout table is a cleanup waiting to bite. | verified 09-05 — `flutter analyze`, `config/commonConfig.js` |

---

## 4. Contract deliverables 📄

Functional scope is delivered; these are the contractual artifacts. All still open.

| # | Item | Notes |
|---|---|---|
| **4.1** | **API documentation (OpenAPI/Swagger)** | No swagger/openapi tooling in the repo. |
| **4.2** | **Solution Architecture Document** | |
| **4.3** | **FMS — Functional Specification** | |
| **4.4** | **HMS — Functional Specification** | |
| **4.5** | **Security & Compliance doc + RBAC matrix** | The RBAC itself exists (`config/adminRoles.js`, incl. `SEO_MANAGER`); the document does not. |
| **4.6** | **Test suite to contract standard** | **43 backend test files pass** on `npm test` and **138 app tests** on `flutter test`, but the contract asks for >80% measured coverage, 200+ integration tests, plus load and OWASP reports. No coverage tooling is wired. |
| **4.7** | **Deployment guide + operational runbook + KT docs** | `DEPLOY_RUNBOOK.md` and the handoffs exist; they need formalising. |
| **4.8** | **UAT test cases + sign-off package** | Client-led. |

---

## 5. Section-0 site redo — separate SOW

Per contract §6 a visual overhaul is **outside** the ₹1,60,000 contract and needs
a signed change request. Per-item status lives in
[`AAJOO_SECTION0_TASKLIST.md`](AAJOO_SECTION0_TASKLIST.md) — check there before
quoting anything here.

**Already shipped from this section** (do not re-scope): brand palette `#0F766E`,
typography, the 9-category set, the CMS admin, and **the whole SEO layer**
(S0-SEO-1 — Phase 1 tasks 0–10, live; handover pack `SEO_Phase1_Handover.docx`
sent to the SEO team 2026-09-04).

**Still open:** Getting Started landing + intent routing (S0-GS-1/2/3) · OTP-first
and social auth (S0-AUTH-1/2/3) · page restructures for Home, About, Contact,
Login, Signup, FAQ (S0-PG-1…6) · property page redesign (S0-PROP-1) · branded
photo-less placeholder (S0-PROP-2) · content application (S0-CNT-1) · the five
blocked asset items (S0-ASSET-1…5).

**S0-CMS-1** is built but effectively empty — `tbl_cms_content` holds **1 row**
against 5 sections, so pages still render hardcoded copy. That is content entry,
not code. *(verified — DB count)*

**iOS App Store deployment** (OSC-1) is also a separate SOW.

---

## 6. Unproven, not broken

Nothing here is known to be defective. Each is a path nobody has exercised.

- The five destructive SEO writes: bulk apply (5,738 rows), 64-image ALT apply, CSV import apply, template enable, Global SEO save. Every one previews cleanly; only the final commit is untested.
- Sitemap generation at 29,000 URLs — measured at 26.
- The app's reviews path on a real device, after the reviews endpoint was opened to anonymous callers on 2026-09-03.
- Live end-to-end notification test (old BE-VERIFY-1) — code shipped, run deferred by the client.
- Google Search Console will not accept the sitemap without warnings until someone with GSC access submits it.
- Whether `dbCutoverSafe` currently reads true — see §2.4.
- **For the tester, on build 16** (each deploys cleanly and is covered by tests, but needs a signed-in host/guest on a device): #19's merged notification feed matches the website for the same host; the guest count survives "Move to Book at Agreed Price" on a *new* negotiation; airplane mode on host Notifications, guest My Negotiations and host Profile → properties shows "Couldn't load · Try again" rather than an empty state; #13's dropdown focus jump (fixed from the code, never reproduced on the emulator).
- **`psb_reviewed_by` on approvals.** The fix that records which admin approved a listing shipped *after* the four approvals of 2026-09-04 — all four rows still read `null`, and no approval has been made since. One listing is sitting at `submitted` right now; approving it is the proof.
- **`REQUIRE_IMAGE_ALT`** — whether it has been set on Render is not visible from outside (see §2.3).

---

## 7. Cash / UPI collection — what is built and what is not

**The rail is built.** `tbl_host_dues` exists with 24 live rows, host dues offset
against payouts, and screens on web host, web admin and the app. Captured test
payments were driven on both web and the app.

**What is still a client decision** (§1.3):

1. **Who confirms collection** — host marks "cash received", or admin reconciles?
2. **When** — at check-in, or at checkout?
3. **How the platform recovers 15% + GST** — net it off the host's next online payout, or invoice separately?
4. **If the host never confirms** — auto-mark collected at checkout, or flag to admin?

Recommendation already given: host marks collected at check-in; commission netted
off the next online payout; unconfirmed stays auto-flag to admin 24h after
checkout.

The commission model itself is unchanged and already implemented in
`utils/financeRecorder.js` — 15% of room subtotal charged to the host, 18% GST on
that commission, four ledger rows per booking.

---

## 8. Closed since the last edition — do not redo

### 8a. Closed 2026-09-04 → 09-05 (tester rounds, builds 13–16, the sweep)

| Was | Now | Evidence |
|---|---|---|
| **App #13** dropdown selection jumps back to the last numeric field | **Fixed, build 13.** The field kept focus under the pop-up sheet; it now unfocuses before the sheet opens. | code — not reproduced on the emulator, see §6 |
| **App #14** emails with `+` rejected at login | **Fixed, build 13.** The app's own regex; the server never had the rule. Sign-up was blocked by the same check, so the tester's `+host2` address had never existed. | verified — device |
| **App #15** white band above the keypad at login | **Fixed, build 13.** The keyboard inset was subtracted three times. | verified — device |
| **App #16** last wizard step blank on resume | **Fixed, build 13 + web + server.** `/listing/draft` never returned the step-5 tables; house rules were read under `ph_` instead of `phr_`; the web's `p5` was never hydrated either. Bank account comes back masked and is deliberately not re-filled. | verified — draft payload |
| **App #17** Submit for Review spun for three minutes | **Fixed, build 13.** 45-second submit timeout, then a read-back of the listing's state. | verified — device |
| **Admin** submitted listing never reached Pending Review | **Fixed, live.** New listings were created live+verified and submit changed nothing — **admin approval was gating nothing**, and unapproved listings were public and in Google. Migration `20260904100000-listing-offline-until-approved` applied on the live DB; unapproved listings now answer **404** at the edge (after a second fix — `build()` in `seoResolve.js` was dropping the `live` field). | verified 09-05 — `property_submission` rows; curl `Age: 0` → 404 |
| **App #18** ownership proof: no file upload, no document type | **Fixed, build 14 (in 16).** Image picker → file picker (PDF/DOC/DOCX/JPG/PNG); seven ownership + four identity types matching the web; upload was saved under a key the server never read. | verified — draft payload |
| **App #19** host notifications blank | **Fixed, server.** Hosts are written to two tables; the app read the rarely-used one (2 rows vs the website's 17). `hostSearch` now unions both; mark-read routes by `source`. | verified — DB counts per table |
| **Admin** "Ownership document missing" on approval | **Same root cause as #18** — the file was stored, the reference was not. Listings created before build 14 need one re-upload. | verified — DB column empty |
| **Web** guest count reset to 2 after a negotiation | **Fixed, live + app parity.** The party size was never stored with the offer. Migration `20260905100000-negotiation-offer-guests` (`offer_guests`) applied live; travels with the offer, comes back on the deal. | verified — column present, web build |
| **Reviews behind auth** | **Fixed 2026-09-03** in three places at once (route auth, client gate, edge markup); `aggregateRating` now server-rendered. | verified — curl of served HTML |
| **Duplicate `LodgingBusiness` + soft 404** on listing pages | **Fixed.** One business per page; a gone/unapproved listing answers 404 with `noindex`. | verified — curl |
| **Page SEO could not be saved** (ever) | **Fixed.** yup `.nullable()` rejected `""`; the empty audit log hid it. | verified — save round-trip |
| **Admin SEO scattered across menus** | **Done.** Dedicated SEO section in the nav + "Search & SEO" dashboard panel; change log now lists every SEO screen's edits; bulk tab sends its mode; keywords shown as lines, not JSON. | verified — admin UI |
| **SEO Phase 1 handover** | **Delivered** — `SEO_Phase1_Handover.docx` + artifact page, sent to the SEO team. | file |
| **Sweep class 1** — 26 silent-empty catches in app services | **Done, builds 15–16.** All 27 log through `utils/service_log.dart`; empty-vs-broken (`LoadFailed` + retry) on host notifications, guest negotiations, host properties; guest bookings already had it. | verified — `flutter analyze`, 138 tests |
| **Sweep class 2** — 34 `.nullable()` numerics with no empty-string transform | **Done.** 38 sites on `nullableNumber()`; `tests/nullableNumberSweep.test.js` rescans every schema. | verified — 43 test files |
| **Sweep class 3** — `.catch(() => {})` on the web | **Done — 37 sites, not 18.** The ESLint rule added at the end found 19 more written with a comment inside the braces. Four got real error states: notification bell, Book Now (was stuck on "one moment"), host and admin offer pickers. | verified 09-05 — `eslint .` 0 hits, real build |
| **Sweep class 4** — two arrays disagreeing on which statuses are revenue | **Done.** One list in `utils/bookingStatus.js` (3,5,6,7,8,9,10,13); a third, complement-shaped list in property analytics folded in; guard test refuses a private list. No real booking sits at 4/12/13, so no figure moved. | verified 09-05 — DB status counts |
| **Sweep class 5** — admin form validating untouched fields | **Done.** `PropertyForm.tsx` validates and sends only what changed. | verified — the two renames went through |
| **"14 listings moved into the review queue"** (build-14 sheet note) | **Overstated.** The DB records **4 approvals** on 09-04 (→ §1.7). Real-host listings today: 5 live, 1 approved-but-inactive, 1 `submitted` awaiting review, 9 drafts. | verified 09-05 — DB |

### 8b. Closed before 2026-09-04

The 2026-07-11 edition listed all of these as open. Each was checked on
2026-09-04 and found already delivered. Re-opening any of them wastes a day.

| Was | Now | Evidence |
|---|---|---|
| **B-1 / C-2** secrets hardcoded in `db.config.js` | **Done.** File is env-only with empty fallbacks; `/health/env` reports `ready: true` (vars present **and** DB reachable); Cloudinary uploads work in production. | verified |
| **C** "Render env never populated", "DB_* set but wrong" | **Stale.** Those warnings described July–August. The cutover has happened. | verified |
| **BE-4** "web has no socket client — web chat would be a net-new build" | **Done.** `socket.io-client` is a dependency; `useChat.ts` and `useNegotiationLive.ts` ship. | verified |
| **MOB-1** DIDIT KYC absent from the app | **Done.** `didit_kyc_screen.dart`, `kyc_controller.dart`, `verify_service.dart` mirror the web flow. | verified |
| **MOB-2** app still uses the old `/host/add` | **Done.** The 5-step schema wizard is the only property form on web and app since 2026-08-20. | code |
| **MOB-3** verification status not surfaced in the app | **Done.** `isKycVerified` drives the host profile and payout screens. | verified |
| **S0-SEO-1** per-page SEO | **Done.** The entire SEO Phase 1 — tasks 0 through 10 — is live. See `SEO_CMS_PHASE1_TASKLIST.md`. | verified |
| **S0-BLOG-1** blog frontend | **Done.** `tbl_blogs` holds 16 rows; the public blog and admin editor ship. | verified |
| **S0-ADM-1** admin missing CMS / SEO / Coupons / Analytics | **Done except Notification Mgmt** (→ §3.8). SEO alone now has 8 routes. | verified |
| **S0-HOST-1** host missing Calendar / Offers / Occupancy | **Done.** `/host/calendar`, `/host/offers`, `/host/performance`, `/host/boost`, `/host/settlements` all ship. | verified |
| **G-1** doc cleanup uncommitted | **Done.** `_archive/` holds 45 files and the tree is clean. | verified |
| **G-2** `aajoo_homes-main/` still tracked in git | **Done.** `git ls-files` returns 0. The directory remains on disk, untracked. | verified |
| **"29,232 listings have no photograph"** | **Misleading, now corrected.** Only 6 listings belong to real hosts and **all 6 have photos**. The gap is entirely inside the seed corpus no crawler sees. | verified |
| **"Seed data spells Uttarakhand as Uttrakhand"** | **Not reproducible.** 0 rows in `property_state`. | verified |

---

## 9. Keeping this file honest

The previous edition drifted because items were marked done in commit messages
and session handoffs but never reconciled back here, while other items stayed
open long after they shipped. Three habits prevent it:

1. **Check the running system, not the note.** Every row above says how it was
   established. A row that only says `carried` has not been checked and should be
   the first thing anyone re-tests.
2. **An empty result is a finding, not a pass.** Several defects this cycle hid
   as absence — an empty change log, a form that rendered perfectly and could not
   save, a 401 swallowed into "this property has no reviews", a host with
   seventeen notifications shown "No notifications yet". Where a number should
   exist and does not, treat that as unverified rather than clean.
3. **A count from a grep is a lower bound.** The web catch sweep was "18 sites"
   until an AST rule found 37; the "14 listings approved" note was 4 in the DB.
   When a number goes into this file, measure it with the tool that cannot be
   fooled by formatting — a lint selector, a guard test, a `COUNT(*)` — and say
   which one.

Detailed context: `PROACTIVE_FINDINGS_2026-09-05.md` · `SEO_CMS_PHASE1_TASKLIST.md`
· `AAJOO_SECTION0_TASKLIST.md` · `CONTRACT_COMPLIANCE_CHECK.md` ·
`CLIENT_INPUTS_REQUIRED.md` · `RENDER_ENV_CHECKLIST.md` · `PAYOUTS_SETUP.md` ·
latest `SESSION_HANDOFF_*.md`.
