# AAJOO Homes — Master Pending Tasks (single source of truth)

> **Reconciled 2026-09-04** against the live site, the live database and the three
> repos. Supersedes the 2026-07-11 edition, which had drifted badly — nine of its
> open items were already done and two of its "done" claims were wrong.
>
> **Repos:** FE `D:/Projects/aajao-frontend-vercel` (React/Vite → Vercel) ·
> BE `D:/Projects/aajaoBackend-render` (Node/Express/Sequelize → `aajaodev.onrender.com`) ·
> Mobile `aajoo_app_2026/` (Flutter). Deploy = push to `main`; **DB migrations do NOT auto-run.**
>
> **How to read the evidence column.** `verified` = checked against production or
> the live DB on 2026-09-04 and the check is named. `code` = read in the source.
> `carried` = taken from the previous edition and **not** re-checked — treat those
> as the least trustworthy rows here.

---

## How this list is ordered

By **who is blocked**, not by component. Most of what is left is not engineering
work; sorting by owner is what makes that visible.

| Section | Owner | Open |
|---|---|---|
| [1. Client decisions](#1-blocked-on-client-decisions) | Client | 6 |
| [2. Ops / Render access](#2-blocked-on-ops--render-access) | Whoever holds Render + GCP | 6 |
| [3. Engineering](#3-engineering--genuinely-open) | Us | 9 |
| [4. Contract deliverables](#4-contract-deliverables-) | Us | 8 |
| [5. Section-0 redo](#5-section-0-site-redo--separate-sow) | Blocked on a signed change order | 20 |
| [6. Unproven, not broken](#6-unproven-not-broken) | Us, when convenient | 6 |

**If only two things get done:** §2.1 (live payment keys) and §1.1 (delete the
seed listings). The first means the product currently looks like it is taking
money and is not. The second gates every honest SEO number on the site.

---

## 1. Blocked on client decisions

| # | Item | Why it is blocking | Evidence |
|---|---|---|---|
| **1.1** | **Delete the 29,227 seed listings** | 29,233 live listings; **29,227 belong to host 100**, 6 to real hosts. Sitemap excludes host 100, so the public site is 27 URLs. Every SEO figure, every bulk preview and every template test is measured against fabricated data until these go. | verified — DB count |
| **1.2** | **Cookie consent banner, then analytics** | GA4/GTM fields are wired and the master switch is off *on purpose*. Turning it on first sets profiling cookies with no way to decline. Legal exposure, not a marketing preference. | verified — Global SEO screen |
| **1.3** | **Cash / UPI collection — 4 decisions** | The rail is **built** (`tbl_host_dues`, 24 rows, offset against payouts). What is still missing is policy: who confirms collection, when, how the 15% + GST is recovered, and what happens if the host never confirms. Detail in §7. | verified — 24 rows in `tbl_host_dues` |
| **1.4** | **Cancellation-policy final copy** (was E-4) | `normaliseCancellationPolicy` ships Flexible/Moderate/Strict and the host picks one at listing time. The *text shown to guests* is still placeholder. | code |
| **1.5** | **Weather provider + key** (was E-2, RENT-7) | Renter-dashboard weather widget cannot start without a provider choice. | carried |
| **1.6** | **Brand assets** — logo set, favicon/PWA icons, animated illustrations, WhatsApp number, social links, reference designs (was E-5, S0-ASSET-1…5) | Gates most of Section-0. | carried |

---

## 2. Blocked on ops / Render access

| # | Item | Failure mode if missed | Evidence |
|---|---|---|---|
| **2.1** | **Live Razorpay keys + `ALLOW_TEST_PAYMENTS` off** | Checkout opens, the booking confirms, an invoice is issued — and **nothing is collected**, because every order was created against the bundled test key. Invisible from the UI by design; `/health/env` reports it. | code — `config/payments.config.js` |
| **2.2** | **RazorpayX credentials** (`RAZORPAYX_KEY_ID`, `_KEY_SECRET`, `_ACCOUNT_NUMBER`, `_WEBHOOK_SECRET`) | Approving a payout fails at the click with "Payouts are not configured". **Not verifiable without pressing Approve on a real ₹27,980 payout**, which was not done. Assume unset until someone checks Render. | unverified — see note |
| **2.3** | **`REQUIRE_IMAGE_ALT=true`** | Server accepts an image upload with no description. Both clients already refuse to upload without one; this closes the server side. Set once build 12 reaches testers. | code |
| **2.4** | **`HEALTH_TOKEN` (or `ADMIN_API_TOKEN`) unset** | `/health/env` returns bare `{"ready":true}`. The detail — including **`dbCutoverSafe`**, the check that would have caught July's outage — is unreadable by anyone. | verified — probe returns `{"ready":true}` only |
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
| **4.6** | **Test suite to contract standard** | **41 test files pass** on `npm test`, but the contract asks for >80% measured coverage, 200+ integration tests, plus load and OWASP reports. No coverage tooling is wired. |
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
(S0-SEO-1 — Phase 1 tasks 0–10, live).

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
- Sitemap generation at 29,000 URLs — measured at 27.
- The app's reviews path on a real device, after the reviews endpoint was opened to anonymous callers on 2026-09-03.
- Live end-to-end notification test (old BE-VERIFY-1) — code shipped, run deferred by the client.
- Google Search Console will not accept the sitemap without warnings until someone with GSC access submits it.
- Whether `dbCutoverSafe` currently reads true — see §2.4.

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
open long after they shipped. Two habits prevent it:

1. **Check the running system, not the note.** Every row above says how it was
   established. A row that only says `carried` has not been checked and should be
   the first thing anyone re-tests.
2. **An empty result is a finding, not a pass.** Several defects this cycle hid
   as absence — an empty change log, a form that rendered perfectly and could not
   save, a 401 swallowed into "this property has no reviews". Where a number
   should exist and does not, treat that as unverified rather than clean.

Detailed context: `SEO_CMS_PHASE1_TASKLIST.md` · `AAJOO_SECTION0_TASKLIST.md` ·
`CONTRACT_COMPLIANCE_CHECK.md` · `CLIENT_INPUTS_REQUIRED.md` ·
`RENDER_ENV_CHECKLIST.md` · `PAYOUTS_SETUP.md` · latest `SESSION_HANDOFF_*.md`.
