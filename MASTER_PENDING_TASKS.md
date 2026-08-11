# AAJOO Homes — Master Pending Task List (single source of truth)

> **Created:** 2026-07-11 · **Owner:** Zyphex Tech
> Consolidates every open item from `POST_25_PRIORITIZED_PLAN.md`, `CONTRACT_COMPLIANCE_CHECK.md` (§7), `CLIENT_INPUTS_REQUIRED.md`, and the mobile-parity notes into **one list**. Update the checkboxes here as work lands; the source docs stay for detail/screenshots.
>
> **Repos:** FE `D:/Projects/aajao-frontend-vercel` (React/Vite → Vercel) · BE `D:/Projects/aajaoBackend-render` (Node/Express/Sequelize → `aajaodev.onrender.com`) · Mobile `aajoo_app_2026/` (Flutter). Deploy = push to `main`; **DB migrations do NOT auto-run**.
>
> **Legend:** **P0** blocker · **P1** important · **P2** minor · 🔒 blocked on client · 🔁 needs FE+BE · 🔐 security · 📄 contractual deliverable.

---

## 0. Recommended execution order

1. **Pre-prod security** (§C) — remove `[DEV-BYPASS]` blocks + move hardcoded secrets to env. *Do before any go-live.*
2. ~~**Backend functional gaps** (§A1) — BE-3, BE-11, BE-4, BE-9~~ ✅ **DONE** (deployed `91966ad`; BE-4/BE-11 verified already built). *(BE-7/BE-8 auth + BE-6 categories now live in the Section-0 redo, §F.)*
3. ~~**Host wizard finish** (§A3) — HOST-7, HOST-10, HOST-12, HOST-13, HOST-14~~ ✅ **DONE** (deployed `2691465`; HOST-12/13 verified already working).
4. ~~**Booking/detail polish** (§A5) — BOOK-2, BOOK-5, BOOK-7, BOOK-8, BOOK-9~~ ✅ **DONE** (deployed `749388f`; BOOK-8 already done; BOOK-4 still client-blocked).
5. ~~**Cross-cutting** (§A6) — CC-1 skeletons, CC-2 unified calendar, CC-3 welcome-name~~ ✅ **DONE** (deployed `62957dc`; CC-2/CC-5 already satisfied).
6. **P2 batch** — ✅ mostly done (`e534172`): HOST-15/16/19, RENT-9, footer + contact address. **Remaining P2:** HOST-17 (needs BE `whatsapp` column), HOST-18 (→ Section-0), premium icons (→ Section-0), BE-10 auto-open (BotPenguin dashboard setting).
7. **Contract deliverables** (§B) — docs, Swagger, test suite (parallel track).
8. **Client-blocked** (§E) — as inputs arrive.

> 🔴 **Biggest single workstream — the Section-0 SITE REDO (§F):** a full rebrand + relaunch (new palette/fonts/icons, Getting-Started landing, OTP-first auth, CMS, new category set, every page restructured to spec). It's a **separate SOW/change-order** and it **supersedes** the Sand & Indigo theme + BE-6/BE-7/BE-8/ADM-3. Run it as its own project track once the change request is signed; the spec already provides the page copy so most of it is unblocked.

> ✅ **Already shipped this cycle (do NOT redo):** BE-1, BE-2, BE-5 · HOST-1/2/3/4/5/6/8/9/11 · ADM-1/2 · RENT-1/2/3/4/5/6/8 · BOOK-1/3/6 · search-radius fix · empty-state fallback · test-property seed.

---

## A. Functional — Post-25 remaining (in contract scope)

### A1. Backend
- [x] **BE-3** · P1 · **Notifications** — ✅ deployed `91966ad` + `5399987`. HOST+ADMIN in-app `tbl_notifications.notify()` now fires on **booking-create, payment, cancellation**. **Renter bell fixed** (`5399987`): `sendNotification` now **always persists** the `tbl_user_notification` row (read by the renter dropdown via `/user/notification/Listing`) — it previously skipped the write for any user without an FCM device token (all web users), so the bell was permanently empty. FCM push is now best-effort after the DB write.
- [x] **BE-4** · P1 · **Socket messaging** — ✅ backend **functional** (chat + negotiation persist to `tbl_messages`/`tbl_nagotiate_messages`). **Auth hardened** (`5399987`): socket handshake now verifies a JWT when present and pins `socket.userId`; chat + negotiation handlers prefer the authed id for room join and **reject spoofed `sender_id`**. Backward-compatible (tokenless mobile clients still work) → flip to strict reject once every client attaches a token. *(Web has no socket client — web chat would be a net-new build, not a fix.)*
- [ ] **BE-7** · P1 · 🔁 **Google sign-in (Firebase).** Backend token verification + Firebase config. → **superseded by S0-AUTH-2 (§F4).**
- [ ] **BE-8** · P1 · 🔁 **Phone-number signup.** Email-or-mobile first step + OTP send/verify. → **superseded by S0-AUTH-1 (§F4).**
- [x] **BE-9** · P1 · **Field & validation audit** — ✅ deployed `91966ad`. `middleware/validation.js` already returns **all** field messages (`abortEarly:false` → `error.errors[]` at HTTP 422); removed leftover debug `console.log`. *Note:* `stripUnknown:true` still drops any field not whitelisted in a schema — the systemic cause of past bugs; whitelist per-schema as they surface. A `{field: message}` map for inline display is a small FE-coordinated follow-up (HOST-14).
- [x] **BE-11** · P1 · 🔁 **KYC auto-verify write-back** — ✅ verified **already implemented**. `/webhooks/didit` (HMAC-verified) → on `verified` sets `tbl_user.verification_status='verified'` + `user_isVerified` + `verified_at`/`expires`, flips host's `pending_verification` properties to `active`, and notifies; declined/in-review handled with admin flags + queue. FE polls the status endpoint. *Only external step:* confirm the DIDIT dashboard webhook URL points at prod.
- [ ] **BE-6** · P1 · 🔒 **Seed real category list** into `tbl_categories` + expose to host/admin forms. → **superseded by S0-CAT-1 (§F3)** — the set is now specified in Section-0.
- [~] **BE-10** · P2 · **BotPenguin config** — widget scoping to renter done (RENT-9). *Stop-inbox-auto-open is a **BotPenguin dashboard setting** (no code control), not a code change → client/admin action in the BotPenguin console.*
- [ ] **BE-VERIFY-1** · **Live E2E notification test** (deferred by client) — log in as a test renter, trigger booking→payment→cancellation, confirm the bell populates from `tbl_user_notification`; confirm host/admin bells from `tbl_notifications`. Code shipped `5399987`; run when convenient.

### A2. Admin dashboard
- [ ] **ADM-3** · P1 · **Category management** reflects the seeded list. → tied to **S0-CAT-1 (§F3)** (set now specified).
- [ ] **ADM-4** · P2 · **Premium icon set** across admin (part of cross-cutting CC-4).

### A3. Host dashboard — wizard finish
- [x] **HOST-7** · P1 · ✅ `2691465` — location actions moved to the **top** of the Location step; "Use my current location" now **reverse-geocodes** to auto-fill address/city/state (was lat/lng only).
- [x] **HOST-10** · P1 · ✅ `2691465` — check-in/out **moved into the Details step** with industry-standard **defaults (14:00 / 11:00)**; removed from the Rules step.
- [x] **HOST-12** · P1 · ✅ verified **already working** — DIDIT flow auto-opens the hosted session (wizard = new tab + status poll; HostProfile = `VerifyButton` redirect), shows Verified via `KycStatusBadge`, and gates submit on verification (ties BE-11).
- [x] **HOST-13** · P1 · ✅ verified — screenshot `image41` = **Host Profile**; every button there (Verify identity, Save/Reset, Retry) + header (Go to Homepage, bell, account menu) + dashboard quick-actions are wired to valid routes/handlers. Save/Reset are correctly disabled until the form is edited; the "Host Workspace" pill is a decorative label (removal tracked in HOST-15).
- [x] **HOST-14** · P1 · ✅ `2691465` — **inline validation on blur** for address, city, state, name, description, price, min-price, contact, email; errors surface as the host leaves a field, not only on "Continue".
- [x] **HOST-15** · P2 · ✅ `e534172` — removed the "Host Workspace" chip from the host header. *(Blog nav is Section-0 — no Blog page yet; "Find your listing" = existing "My Properties".)*
- [x] **HOST-16** · P2 · ✅ already satisfied — host dashboard KPIs are Earnings / Active Listings / Upcoming Bookings / **Occupancy Rate** (no "Total Spent").
- [ ] **HOST-17** · P2 · **Surface host name** (already shown) + **WhatsApp field** — ⏳ needs a BE `whatsapp` column on the host account + save (FE-only won't persist; `stripUnknown` drops it).
- [ ] **HOST-18** · P2 · **Distinct host-portal accent** → deferred to **Section-0** (the rebrand re-themes the whole app; a half-measure now would be redone).
- [x] **HOST-19** · P2 · ✅ `e534172` — added "State Regulations" to the host sidebar (`/state-regulation`, page already exists).

### A4. Renter dashboard
- [ ] **RENT-7** · P1 · 🔒 **Weather widget** for current location. *Blocked: weather API/provider choice + key.*
- [x] **RENT-9** · P2 · ✅ `e534172` — support widget now shows **only** on the renter dashboard/account (`/user-dashboard`, `/user/*`), not on every public page. *(Small: booking-page footer removed + contact "Call support"→office address in the same commit.)*

### A5. Property Detail / Booking
- [x] **BOOK-2** · P1 · ✅ `749388f` — host phone revealed **only after booking** (fail-closed `getMyBookings` check); "Meet your host" shows a Call-host row when booked, "shared after you book" otherwise; `HostDetailsModal` gated too.
- [x] **BOOK-5** · P1 · ✅ `749388f` — booking-page slider shows the property's **real images** (already flowed via nav state); removed the misleading hardcoded "Chennai apartment"/Unsplash fallback + added a graceful "no image" state.
- [x] **BOOK-7** · P1 · ✅ `749388f` — ongoing-booking modal no longer renders fake "Manali / Aajoo Premium Homestay / cozy mountain views"/Unsplash placeholders; shows real booking data or hides the field.
- [x] **BOOK-8** · P1 · ✅ verified **already done** — `PropertyGallery` desktop is a hero + grid (`2fr 1fr 1fr`, first image spans as hero, "+N more" overlay); mobile keeps a slider (appropriate).
- [x] **BOOK-9** · P1 · ✅ `749388f` — location map moved to **after** the Guest Reviews section ("Where you'll be").
- [ ] **BOOK-4** · P1 · 🔒 **Nearby places dynamic** (places API or curated). *Blocked: data source decision.*

### A6. Cross-cutting
- [x] **CC-1** · P1 · ✅ `62957dc` — reusable `Skeletons` component (property card/grid, stat cards, list rows, detail page) using MUI wave skeletons; applied to the property listing grid, renter dashboard, and property-detail page (replacing bare spinners). Reusable for the rest as they surface.
- [x] **CC-2** · P1 · ✅ verified **already unified** — `ThemedDatePicker` (themed MUI-X `DatePicker`, ISO-string value) is the single customer date component: **booking dates, signup DOB, profile DOB** all use it; admin uses the same MUI-X base.
- [x] **CC-3** · P1 · ✅ `62957dc` (renter) — renter dashboard greets "Welcome back, {name}" (host dashboard already did); name from `getUserDetail()`.
- [x] **CC-5** · P1 · ✅ covered by **BE-9** (server returns all field errors) + **HOST-14** (inline on-blur validation).

---

## B. Contract closeout — deliverable artifacts 📄
*(From `CONTRACT_COMPLIANCE_CHECK.md` §7. Functional scope is delivered; these are the contractual to-dos.)*

- [ ] **B-1** · 🔐 **Move hardcoded secrets to env vars** — DB + Razorpay + Cloudinary + Google creds are hardcoded in `config/db.config.js` (violates §9.3). *Highest-priority technical fix.* → also §C.
- [ ] **B-2** · 📄 **API documentation (OpenAPI/Swagger)** for the backend endpoints.
- [ ] **B-3** · 📄 **Solution Architecture Document.**
- [ ] **B-4** · 📄 **FMS – Detailed Functional Specification.**
- [ ] **B-5** · 📄 **HMS – Detailed Functional Specification.**
- [ ] **B-6** · 📄 **Security & Compliance doc** incl. **RBAC access-control matrix.**
- [ ] **B-7** · 📄 **Test suite** — real framework (jest/supertest) + **>80% coverage**; integration (200+) + performance/load + OWASP security reports.
- [ ] **B-8** · 📄 **Deployment guide + Operational runbook + KT docs** (formalize existing handoff notes).
- [ ] **B-9** · 📄 **UAT test cases + sign-off** package (client-led).
- [ ] **B-10** · **Optional hardening / verify:** RBAC granularity (finance/support separation), real-time chat (BE-4), payout **dispute handling**, **audit trail** completeness, **AES-256 at rest**, performance monitoring/APM (<200ms p95, 99.5% uptime).

---

## C. Pre-production security hardening 🔐 — ⚠️ **C-2 ROLLED BACK** (2026-07-12); C-1 stands
**C-2 caused a production outage** and was reverted (`0e4d25b`). Root cause: the env-driven `db.config` (`ce0be2f`) read `process.env.DB_*` on Render, but the DB env vars were **never actually set there** — Render had a **stale/wrong `DB_HOST`** (`brcbbhhvhgihy7sgm6ca-…`, a decommissioned host → `ENOTFOUND`) that the old hardcoded config had been ignoring. Every DB query (incl. login) broke. The real addon (`bf0mpow9qbd34cpwy8in-…`) is alive + creds valid (verified by direct connect); `db.config.js` restored to the known-good values to bring production back.
**C-1 (OTP-bypass env gating) is unaffected and stays.** Secrets are (again) in `db.config.js` — same as before C-2, and still in git history.

**Follow-on outage — `JWT_SECRET`:** after login was restored, every authed call threw **"JWT secret is not configured"** — `JWT_SECRET` was env-only and **not set on Render** either. Hotfixed `c6f282b`: added a fallback in `commonConfig` used by both sign (`methods.genrateToken`) + verify (`authorization`); roundtrip verified with env unset. **Root theme: the Render environment was never fully populated for the env-driven refactor** (DB, JWT, likely Cloudinary/DIDIT/Brevo). Fix them together (next block) before re-attempting C-2.

**➡️ To re-apply C-2 SAFELY (correct order this time):**
1. In Render → Environment, set **all** of `DB_USER/DB_PASSWORD/DB_NAME/DB_HOST/DB_PORT` (host = `bf0mpow9qbd34cpwy8in-mysql.services.clever-cloud.com`) + **`JWT_SECRET`** + `CLOUDINARY_*` + `MAIL_*`/`BREVO_API_KEY` + `RAZORPAY_*` + DIDIT creds. **Delete the stale `DB_HOST`** if present.
2. Verify each value against the Clever Cloud dashboard (the wrong `brcbbhhvhgihy7sgm6ca` host must not be anywhere).
3. **Then** switch `db.config.js` back to `process.env.*` and deploy — confirm login works before/after.
4. Rotate the exposed credentials (still recommended; they're in git history).

- [x] **C-1** · **`[DEV-BYPASS]` blocks removed.** OTP `0000`/`000000` bypass is now **gated behind `OTP_DEV_BYPASS` env** → can never fire in production (leave the var unset on Render); still works locally. All `[DEV-BYPASS]` markers gone from both repos (`node --check` passes).
- [x] **C-2 (code)** · **Secrets moved out of `config/db.config.js`** — now env-driven (`process.env.*`) with a fail-fast check. Deploy repo's `.env` was **git-tracked with real secrets** → **untracked (`git rm --cached`) + added to `.gitignore`.** `db.config.js` boots clean with `.env` present.
- [x] **C-3** · **Signup doc identifiers already required** — `doc_type` + `doc_number` are `.required()` in both `schema/user.schema.js`. The doc **image** stays optional by design (DIDIT verifies later); a ready-to-enable production guard is left in `createUser` with a comment.

> ⚠️ **2026-08-03 — the "Render env vars set" claim below was VERIFIED FALSE.** Measured directly via the new `GET /health/env` probe on production:
> - **Missing entirely:** `JWT_SECRET`, `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET`.
> - **Set but WRONG:** all five `DB_*` vars differ from the instance the service is actually running on — i.e. **the exact July failure mode is still armed.** Cutting `db.config.js` over to `process.env` today would repeat the outage immediately.
> - The service only stays up because it still reads the hardcoded literals and ignores the bad env.
>
> 🚨 **`OTP_DEV_BYPASS` was set to `true` on Render, not unset** — so the dev OTP bypass was **LIVE in production**. `POST /user/verify-otp {userId, otp:"0000"}` returned a valid JWT for any account id (ids are sequential) = full account takeover, hosts and staff included. **Fixed in code** (`0f18ff6`): the bypass now additionally requires a loopback request origin, which is unreachable on Render. Verified closed on production. **Still remove `OTP_DEV_BYPASS` from the Render environment.**
>
> **To unblock the C-2 cutover:** in Render → Environment, add the four missing vars and *correct* the five `DB_*` values (source of truth = Clever Cloud dashboard), then confirm `GET /health/env` reports `"ready": true` **and** `"dbCutoverSafe": true`. The cutover is a small change once that reads green; do not attempt it before.

~~**✅ Render env vars set + credentials rotated** (client-confirmed). `OTP_DEV_BYPASS` left unset on Render → real OTP enforced in production.~~

**Open decision (non-blocking):** make the ID-document **image** mandatory at signup? Currently optional + DIDIT-verified. If yes, enable the ready guard in `createUser` — but confirm the signup form actually uploads a file first, or it 400s.

---

## D. Mobile app parity (Flutter `aajoo_app_2026/`)
*(Web is ahead; mobile lags on these. Detail in the archived `MOBILE_APP_TASKLIST.md`.)*
- [ ] **MOB-1** · **DIDIT KYC** flow in-app (currently absent).
- [ ] **MOB-2** · **Host add-property** still uses the old `/host/add` — align to the new add-property + H1 fields.
- [ ] **MOB-3** · **Surface verification status** (Verified badge / hide upload) as on web.
- [ ] **MOB-4** · Carry over web fixes where relevant (availability calendar, invoice download, empty-state guards).

---

## E. Blocked on client inputs 🔒
*(Cross-ref `CLIENT_INPUTS_REQUIRED.md`. Nothing below can start until provided.)*
- [x] **E-1** · **Category list** — ✅ now **specified in Section-0** (§F3 category set); no longer blocked.
- [ ] **E-2** · **Weather API** choice + key → unblocks RENT-7.
- [ ] **E-3** · **Nearby-places** data source → unblocks BOOK-4.
- [ ] **E-4** · **Cancellation-policy text** (final copy) → completes BOOK-6.
- [ ] **E-5** · **Marketing copy / logo / brand font** → unblocks the parked marketing-site UI + Section-0 (§F).

---

## F. SECTION-0 SITE REDO — full rebrand + relaunch ⚠️ *(separate SOW / change-order)*

> ⚠️ **2026-08-11 — THIS SECTION WAS STALE AND MISREAD.** Every item below was
> written unchecked, which read as "Section-0 has not started". It has: the
> palette, typography, favicon, mission/vision art, SEO layer and the 9-category
> set all shipped 2026-08-06/07 and are verified live in the code and the
> database. The authoritative per-item status is
> [`AAJOO_SECTION0_TASKLIST.md`](AAJOO_SECTION0_TASKLIST.md), which tracks
> Present/Partial/Missing properly. **Check there before quoting anything here.**
> The four items verified on 2026-08-11 are corrected below; the rest still need
> the same treatment.

> **This is a whole-site redo**, specified in the **"flow document"** — `Aajoo Homes – Section 0 – Quick Summary & Project Direction.pdf` — and analyzed page-by-page in [`AAJOO_SECTION0_TASKLIST.md`](AAJOO_SECTION0_TASKLIST.md). Per contract §6 it's a **visual overhaul = OUTSIDE the ₹1,60,000 contract → needs a signed change request.** Good news: the spec **provides the actual page copy** (the "content"), so content is mostly *not* blocked — only brand **assets** + provider **creds** are (§F9).
>
> ⚠️ **Supersession — retires earlier items:** the **Sand & Indigo theme** (to be redone in the new palette), **BE-6/ADM-3** category list (now specified → F3), **BE-7/BE-8** auth (now F4), and the **parked marketing-UI redesigns** (now F2/F6). Track them here, not in §A.
>
> **Build order below = client's dev priority (spec p5) + what's unblocked.**

### F1 · Brand foundation *(do first — underpins everything visual)*
- [x] **S0-BRAND-1** ✅ **LIVE** (verified 2026-08-11): `#0F766E` present in `src/index.css`, `src/main.tsx` and components; mobile too (`kIndigo = 0xFF0F766E` in `constants.dart`, token names kept for back-compat).
- [x] **S0-BRAND-2** ✅ **LIVE** (verified 2026-08-11): Manrope + Plus Jakarta Sans in `src/index.css` / `src/main.tsx`.
- [ ] **S0-BRAND-3** · **Lucide icon migration** — `lucide-react` already installed but unused; migrate off MUI icons app-wide (outline default, filled = active).

### F2 · Getting Started landing + intent routing *(dev priority #1)*
- [ ] **S0-GS-1** · Build **Getting Started page** (net-new): hero (badge, headline "Stay Better. Host Smarter. Belong Everywhere.", Explore Stays + Become a Host CTAs) · 6 value cards · How It Works (guest + host journeys) · Our Promise · Why We Exist · bottom CTA · footer quote. **Remove** listings/search/map/testimonials/FAQ from this page.
- [ ] **S0-GS-2** · **Intent-based routing** — first-time → Getting Started; returning → last experience; logged-in guest → dashboard; host → host dashboard; nav always allows switching.
- [ ] **S0-GS-3** · **Adaptive nav** — minimal initially, expands on scroll, sticky with shadow.

### F3 · Category re-seed *(unblocks selectors everywhere; was the blocked "category list")*
- [~] **S0-CAT-1** 🟡 **HALF DONE** (verified against the live DB 2026-08-11). All 9 spec categories ARE live — but the **purge never happened**: `Resort`, `couple` and `party` are still active rows in `tbl_categories`. This is the same thing the app sheet reports as **A-52** ("change Browse by category into homestay villas, remove single couple etc") — it is a **data fix, not a redesign**, and one UPDATE clears it on web AND mobile.

### F4 · Auth upgrade *(replaces BE-7/BE-8; partly blocked on creds)*
- [ ] **S0-AUTH-1** · **Mobile OTP-first** login + signup (default method). 🔒 needs SMS/OTP provider creds.
- [ ] **S0-AUTH-2** · **Social login** — Google (+ Apple). 🔒 needs Firebase/OAuth creds.
- [ ] **S0-AUTH-3** · Single account + **role-based routing/switching** (guest ↔ host).

### F5 · CMS + SEO layer
- [~] **S0-CMS-1** 🟡 **BUILT, EMPTY** (verified 2026-08-11): admin UI exists (`redesign/pages/admin/CMS.tsx`, route `/admin/cms`) and `tbl_cms_sections` has 5 rows — but `tbl_cms_content` has **0 rows**, so pages still render their hardcoded copy. Needs content entered, not code.
- [ ] **S0-SEO-1** · **Per-page SEO** — dynamic title/meta/OG/schema (add react-helmet), clean URLs.
- [ ] **S0-CFG-1** · Configurable **SMTP + email templates + SMS provider** (welcome / booking / host-verification / reset / notifications). 🔒 partly needs creds.

### F6 · Page restructures to spec *(apply provided copy — supersedes parked marketing UI)*
- [ ] **S0-PG-1** · **Home / Explore** (B2) — add Trust strip, Trending Stays, Browse-by-Property-Type, Featured Collections, Travel Inspiration, Download App, Newsletter, Bottom CTA; reorder to the 15-section spec.
- [ ] **S0-PG-2** · **About Us** (B3) — restructure (Story / Vision / Mission / Values / What-Makes-Different) + **animated mission/vision**.
- [ ] **S0-PG-3** · **Contact Us** (B4) — 6-field form (Name/Email/Mobile/Subject/Category/Message) + 9 categories + WhatsApp / office / 24-7 support sections.
- [ ] **S0-PG-4** · **Login** (B5) — OTP-first + email + social; side visual (animated gradient/glass); error + loading states.
- [ ] **S0-PG-5** · **Sign Up** (B6) — **choose-journey-first** (guest/host), OTP default, guest vs host field sets, benefits, success routing.
- [ ] **S0-PG-6** · **FAQ / Knowledge Center** (B7) — CMS-driven, 14 categories, search, helpful/not-helpful feedback, Guest (15) + Host (15) FAQ sets.

### F7 · Module gaps + Blog + property redesign *(B8/B9/B10)*
- [ ] **S0-ADM-1** · Admin missing modules — CMS, SEO Mgmt, **Coupon Mgmt UI** (backend exists), Notification Mgmt, dedicated Analytics.
- [ ] **S0-HOST-1** · Host missing modules — Calendar Mgmt, Smart Pricing, Offers, Coupons, Occupancy Reports.
- [ ] **S0-PROP-1** · **Property page redesign** (dev priority #5).
- [ ] **S0-PROP-2** · **Branded property placeholder** (line-art home + gradient) for photo-less listings.
- [ ] **S0-BLOG-1** · **Blog** frontend (backend `tbl_blog` scaffolded) + 10 categories.

### F8 · Content application *(the spec's copy IS the "content document")*
- [ ] **S0-CNT-1** · Apply the spec's **provided professional copy** (SEO/GEO/AEO-friendly) to every page — Getting Started, Home, About, Contact, Login, Signup, FAQ. Replace all placeholder/Lorem text. *(Copy is in the spec → actionable now, not blocked.)*

### F9 · Blocked on client assets / creds 🔒 *(see also §E)*
- [ ] **S0-ASSET-1** · Final **logo** set (transparent SVG/PNG @1x/2x/3x, mono, icon-only, light/dark, **no white-bg container**).
- [ ] **S0-ASSET-2** · **Favicon + PWA / Android adaptive / iOS icon** set (512×512, no text).
- [ ] **S0-ASSET-3** · **Animated illustrations** (Lottie / SVG / 3D) for mission/vision + auth side-visuals.
- [ ] **S0-ASSET-4** · **WhatsApp number + social profile links** (address + emails already given).
- [ ] **S0-ASSET-5** · **Reference/design images** to lock exact visual layout.

---

## G-SOW. Other out-of-contract (separate SOW)
- [ ] **OSC-1** · **iOS App Store deployment** (contract lists iOS as ongoing configuration).

---

## G. Repo / ops housekeeping
- [ ] **G-1** · **Commit the doc cleanup** — root docs archived to `_archive/` (2026-07-11); currently working-tree only.
- [ ] **G-2** · **Remove old duplicate Flutter app `aajoo_homes-main/`** from git — already empty on disk, still tracked (~300 files show as pending deletions).
- [ ] **G-3** · **Run pending DB migrations on live** when backend schema changes ship (migrations don't auto-run on Render).

---

_Update this file as the single tracker. Detailed context lives in `POST_25_PRIORITIZED_PLAN.md`, `CONTRACT_COMPLIANCE_CHECK.md`, `CLIENT_INPUTS_REQUIRED.md`, and `AAJOO_SECTION0_TASKLIST.md`._
