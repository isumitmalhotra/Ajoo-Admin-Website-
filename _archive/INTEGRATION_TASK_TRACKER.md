# AajooHomes — Integration, Backend & Fixes Task Tracker

> **⚠️ This is now a DETAIL companion. The single source of truth is `MASTER_TASK_TRACKER.md` — read that first.**
>
> This file keeps the deep history of the backend integration / auth / OTP / host module work. New tasks and status changes go in `MASTER_TASK_TRACKER.md`; this file is preserved as the narrative record of how the H / M / E / P / RDY items got to where they are.
>
> **Last updated:** 2026-06-08 (Task M complete — only E and P remain, both blocked on client)
> **Companion docs:** `MASTER_TASK_TRACKER.md` (canonical), `REDESIGN_CONTEXT.md` (UI redesign handoff), `REDESIGN_TASK_TRACKER.md` (UI tasks), `EMAIL_OTP_DELIVERY_PROPOSAL.md` (client-facing email doc), `KEEP_ALIVE_SETUP.md` (cold-start mitigation).

---

## 0. Key Environment / Context (read first)

| Thing | Value |
|---|---|
| **App** | Flutter — `aajoo_app_2026/` (renter + host) |
| **Backend (our copy)** | `aajooBackend-2026/` (subfolder of monorepo, **not** a standalone git repo) |
| **Client's backend repo** | `github.com/ashishrahi366/aajooBackend-2026` (main now has merged `naxtre-optimization`) |
| **Render-connected repo** | `github.com/nameeshPatiyal100/aajaoBackend` → branch **`main`** auto-deploys |
| **Live backend URL** | `https://aajaodev.onrender.com` (app points here) |
| **Prod DB** | Clever Cloud MySQL `bf0mpow9qbd34cpwy8in` (creds in `config/db.config.js`, gitignored) |
| **OTP test bypass** | Env var `OTP_DEV_BYPASS=true` on Render → OTP `0000` verifies any account (REMOVE for production) |
| **Payments** | Razorpay, **TEST mode** (`rzp_test_...`) |
| **Delete test user** | `cd aajooBackend-2026 && node scripts/deleteTestUser.js <email>` (frees email + phone) |

**Render limitation:** blocks outbound SMTP (25/465/587) on all plans → Gmail OTP email can't send. Real OTPs require an HTTP email API (see Task P3).

---

## 1. ✅ COMPLETED (this session)

### A. Backend integration & deployment
- ✅ Merged client sub-branch `naxtre-optimization` → `main` on `ashishrahi366/aajooBackend-2026` (commit `eb75d88`).
- ✅ Synced merged client code into local monorepo backend (104 files) while preserving local config/secrets.
- ✅ Pushed production backend to Render repo `nameeshPatiyal100/aajaoBackend` main; **removed dev bypasses** for the pushed version (kept config/secrets).
- ✅ Fixed Render boot crash — restored the **live DB connection** in `models/index.js` (was using `config.json[NODE_ENV]` with no `production` block → crash). Now connects via `db.config.js` regardless of `NODE_ENV`.
- ✅ Made boot-time DB authenticate + chatbot scheduler **non-fatal** so the service starts even if DB blips.
- ✅ Added gitignore entries so `.env` / `db.config.js` / `serviceFirebase.json` are never committed to the monorepo.

### B. Email / OTP
- ✅ Diagnosed: Render blocks SMTP → Gmail OTP emails time out (`ETIMEDOUT`). Not a code/credential bug.
- ✅ Added **env-gated OTP test bypass** (`OTP_DEV_BYPASS=true` + code `0000`) so QA can proceed. 4-digit `0000` (OTPs are 4 digits).
- ✅ Authored `EMAIL_OTP_DELIVERY_PROPOSAL.md` (client-facing: issue, Brevo/Resend approaches, pricing).

### C. Auth fixes (signup / login / verify)
- ✅ **Signup "Missing required fields"** — `user_email` (and `user_ref`) were stripped by the validation middleware (`stripUnknown` + sanitize) because they weren't declared in the `createUser` schema. **Fixed:** added them to `schema/user.schema.js`.
- ✅ **Email lost across multi-step signup** — added dedicated `authEmail/authPassword/authConfirmPassword/authIsHost` fields in `auth_controller.dart`; `submitSignup` resolves from dedicated field → param → signupData.
- ✅ **`showAlert` crash ("No Overlay widget found")** — rewrote `controller/alert_dialog.dart` to use a global `ScaffoldMessenger` key (wired in `main.dart`), immune to overlay/transition issues.
- ✅ **Login crash on failure** (`List` vs `Map`) — `LoginResponse.fromJson` now coerces non-map `data` to `{}`.
- ✅ **Login routes unverified accounts to OTP** instead of "No record found" — backend `loginUser` re-issues OTP + returns `{userId, isVerified:false}`; client routes to `/verify`.
- ✅ **OTP screen showed wrong email** — `verify_page.dart` now prefers `Get.arguments['email']` over stale `userData.email`.
- ✅ **Verify-otp parse crash** (`type 'Null' is not a subtype of String`) — `KycDocs.fromJson` typo `ImgeUrl`→`ImageUrl` fixed + all fields null-safe.
- ✅ **Host signup created renter (CRITICAL)** — backend `createUser` checked `user_isHost === "true"` but validation casts it to boolean `true` → always renter. **Fixed:** accept `true/1/"true"/"1"`. Also hardened client selector (`OptionButton` no longer resets to Renter on init; `auth_page` sets `userType` synchronously; `submitSignup` uses `authIsHost`).
- ✅ Removed dev "Skip auth → Home" button from `auth_page.dart`.
- ✅ Cleaned up scary error strings across app → friendly empty states (notifications, history, profile, payout, etc.).

### D. Dev tooling
- ✅ `scripts/deleteTestUser.js` — delete a user by email across all tables (frees email + phone). Connects to prod DB via `db.config.js`.

### E. App fixes / UI
- ✅ Re-wired home search bar (`SearchPill`) to the new Airbnb-style `showSearchSheet` (was reverted to old `showFilterDialog`).
- ✅ Polished "Complete Your Profile" multi-step form (Sand & Indigo fields, dropzone, headers).
- ✅ Perf: gated home-screen API avalanche on real-user presence; short Dio timeouts on notifications.

---

## 2. ⬜ PENDING TASKS

### Task H — Host module fixes (from host endpoint audit)
**Status:** H1/H2/H3/H4/H5 ✅ complete (2026-06-07). Task H fully done.

- **H1** ✅ **Payout Account screen — DONE.**
  - Added backend `GET /payout/account/details` ([routes/payouts.routes.js](aajooBackend-2026/routes/payouts.routes.js)) + `getHostAccountDetails` controller; `addHostAccountDetails` now upserts if a record already exists (no duplicates).
  - New Flutter screen [add_payout_account_page.dart](aajoo_app_2026/lib/ui/screens_host/payout/add_payout_account_page.dart) with account-number / confirm / IFSC validation (IFSC regex `[A-Z]{4}0[A-Z0-9]{6}`).
  - New model [host_account_details_model.dart](aajoo_app_2026/lib/models/host_account_details_model.dart); service methods `getHostAccountDetails` + `saveHostAccountDetails` on [host_payout_service.dart](aajoo_app_2026/lib/service/host_payout_service.dart).
  - [payout_controller.dart](aajoo_app_2026/lib/ui/screens_host/payout/payout_controller.dart) tracks `accountDetails`, `hasAccount`, `isAccountLoading`, `isSavingAccount`.
  - [payout_page.dart](aajoo_app_2026/lib/ui/screens_host/payout/payout_page.dart) now shows: bank-account card (or "Add Bank Account" CTA); "Request Payout" disabled+gated until account exists; pull-to-refresh; removed the unused account-number/account-id/IFSC fields from the request bottom sheet (only `amount` was ever sent).
  - Drawer entry "Bank Account" added in [host_home_drawer.dart](aajoo_app_2026/lib/ui/screens_host/home/host_home_drawer.dart).

- **H2** ✅ **Host empty/error states — DONE.**
  - Booking history: `host_booking_history_controller.dart` now sets `hasError` + `hasFetched`; UI no longer shows infinite spinner on error — collapses to a friendly empty state with pull-to-refresh.
  - Host profile "Managed Properties": empty list (data:[] OR fetch error) now shows a card with icon + "Add Property" CTA instead of a blank screen or bare image.
  - Host home: `getHostOngoing(1)` hard-code replaced with real `authController.userData.value?.userId`; wrapped in `RefreshIndicator`; ongoing + transactions fetched concurrently.
  - [host_controller.dart](aajoo_app_2026/lib/ui/screens_host/host_controller.dart) has per-resource `propertiesFetched / ongoingFetched / transactionsFetched` flags so one endpoint's error doesn't bleed into another UI.

- **H3** ✅ **End-to-end host walkthrough — code-level audit + fixes DONE; device QA pending tester.**
  - Pre-existing bugs from audit (Obs #1192, #1197) fixed:
    - `deleteProperty` was setting `loading.value = false` at start (typo) and missing try/catch — now uses proper try/catch/finally, refreshes properties after delete, returns `bool`.
    - `updateCoverImage` was missing `finally { loading = false }` (loading hung true on error); now also null-checks `coverImage.value`, refreshes list on success, returns `bool`.
    - `updatePropertyStatus` now also refreshes the properties list after success so the badge updates immediately.
  - Update-property flow (`new_property_controller.updateProperty` → reuses `/properties/add` with `propertyId`) — verified correct per Obs #1206/1207.
  - **Tester checklist (closed testing):** signup host → add property (≥2 imgs + ≥3 docs) → edit it → toggle status → upload new cover image → view ongoing bookings (book one as renter) → view booking history → give review → transactions → payout: open Bank Account (drawer), add it, then request payout. Pull-to-refresh every list.

- **H4** ✅ **Remove dead `DummyScreen` slots — DONE (2026-06-07).**
  - [main_screen.dart](aajoo_app_2026/lib/ui/screens_host/home/main_screen.dart) `IndexedStack` had 8 slots with 5 unreachable `DummyScreen()` entries (tabs 0,1,3,4,6). Only tabs 2/5/7 are ever set (drawer's Home/Profile/Invoices); every other drawer item uses `Get.to`. Replaced the 8-slot list with the 3 live screens `[HostHomeScreen, HostProfilePage, InvoicePage]` and a `_tabToIndex = {2:0, 5:1, 7:2}` map — keeps `IndexedStack` state preservation, no changes to the provider or drawer.
  - Removed the dead app-bar title branches for `currentTab == 6` ("Payout") / `== 4` ("Privacy Policy") — those destinations are pushed via `Get.to` now, so the title always shows the host name.
  - Deleted the now-unused `components/dummy_screen.dart`.

- **H5** ✅ **Sand & Indigo pass on host screens — DONE (2026-06-07).**
  - Colors were already on-token from the Phase-0 restoration; this pass added the renter redesign's **typography (Fraunces headings / Inter body via [fonts.dart](aajoo_app_2026/lib/utils/fonts.dart))** and elevated card chrome for consistency.
  - **Host app bar** ([main_screen.dart](aajoo_app_2026/lib/ui/screens_host/home/main_screen.dart)): host name → Fraunces 28 w500.
  - **Host home** ([host_home_screen.dart](aajoo_app_2026/lib/ui/screens_host/home/host_home_screen.dart)): "Ongoing Bookings" / "Recent Transactions" now reuse the renter `SectionHeader` (Fraunces 22). Empty states ([no_ongoing_booking_view.dart](aajoo_app_2026/lib/ui/screens_host/home/components/no_ongoing_booking_view.dart), [no_recent_transaction_view.dart](aajoo_app_2026/lib/ui/screens_host/home/components/no_recent_transaction_view.dart)) → kMuted icon + Inter text.
  - **Quote banner** ([quote_widget.dart](aajoo_app_2026/lib/widgets/quote_widget.dart)): retargeted the 6 off-brand rainbow colors (purple/teal/pink hex) to the brand palette (kIndigo / kSuccess / kClay / kIndigo600 / kClay600 / kInk2); text → Inter.
  - **Recent transaction tile** ([host_recent_transaction_item_view.dart](aajoo_app_2026/lib/ui/screens_host/home/components/host_recent_transaction_item_view.dart)): kCream surface + kLine border (elevation 0), Inter typography, kInk/kMuted.
  - **Invoices** ([invoice_page.dart](aajoo_app_2026/lib/ui/screens_host/invoices/invoice_page.dart)): cream cards w/ kLine border + radius 14, Fraunces invoice numbers, Inter body, branded (kMuted) empty state, Fraunces app-bar title.
  - **Payout** ([payout_page.dart](aajoo_app_2026/lib/ui/screens_host/payout/payout_page.dart)): Fraunces app-bar title + "Payout History" / "Request Payout" headings, kMuted Inter empty state.
  - **Verified:** `flutter analyze` → **729 issues** (below the ~738 baseline; the 2 remaining errors are the pre-existing legacy `lib/screens/Host/host_support_screen.dart` `_staticPageController` bug, unrelated). No new errors; no behavior/layout changes.

---

### Task P — Payment gateway go-live (Razorpay)
**Status:** ⬜ Not started. **Current:** Razorpay fully integrated (backend `utils/razorpay.js` + app `razorpay_flutter`) in **TEST mode** (`rzp_test_XUTODhUdMAshi6`). No new gateway needed.

- **P1 (client action): Obtain LIVE Razorpay credentials.**
  - Client must complete Razorpay business KYC and provide **live** `key_id` (`rzp_live_…`) + `key_secret`.
  - Decide host-payout method (manual vs RazorpayX/Route).

- **P2 (code — pre-go-live cleanup): Centralize the Razorpay key.**
  - App **hardcodes** `rzp_test_...` in **6 places**: `property_page.dart`, `view_ongoing_booking.dart` (×2 incl. legacy), `negotitaion_page.dart` (×2 incl. legacy widgets), `screens/property_page.dart`.
  - **Do:** replace with a single source (ideally fetched from backend, or one app constant); move backend keys from `db.config.js` to **environment variables**.
  - **Done when:** switching test↔live is a single config change, no key scattered in UI files.

- **P3 (go-live): Swap test → live.**
  - After P1+P2: put live keys in backend env + app config, retest a real payment, confirm signature verification + booking confirmation.

---

### Task E — Real OTP emails (transactional email API)
**Status:** ⬜ Not started (blocked on client choosing a provider). See `EMAIL_OTP_DELIVERY_PROPOSAL.md`.

- **E1 (client action):** create Brevo (recommended) or Resend account; verify sender/domain (SPF/DKIM); provide API key + "from" address.
- **E2 (code):** rewrite `utils/mailer.js` from nodemailer-SMTP to the provider's HTTP API (port 443 — works on Render). All OTP/email flows route through `mailer`, so it's a contained change.
- **E3 (config):** add API key + `MAIL_FROM` as Render env vars.
- **E4 (cleanup):** once real OTPs work, **remove the `OTP_DEV_BYPASS` block** in `controllers/user.controller.js` and unset the Render env var.

---

### Task M — Misc / known issues
**Status:** M1/M2/M3 ✅ complete (2026-06-08). Task M fully done.

- **M1** ✅ **Chatbot scheduler spam — DONE.**
  - [campaignScheduler.js](aajooBackend-2026/utils/campaignScheduler.js) now runs a one-time `ensureChatbotTablesPresent()` preflight via `sequelize.getQueryInterface().showAllTables()`. If any of `tbl_chatbot_campaigns / tbl_chatbot_sessions / tbl_chatbot_leads / tbl_chatbot_logs` are missing, the scheduler logs ONE warning and self-disables — no more 15-min "doesn't exist" spam.
  - `startScheduler()` is now async; preflight runs before any interval is registered. [app.js](aajooBackend-2026/app.js) updated to `await startScheduler()`.
  - New helper [scripts/runChatbotMigrations.js](aajooBackend-2026/scripts/runChatbotMigrations.js) — applies ONLY the two chatbot migrations (in correct order: sessions first, then campaigns/leads/logs) against the live DB defined in `config/db.config.js`. Idempotent; supports `--dry-run`. Use this when the client is ready to turn the chatbot on; restart the backend afterward and the scheduler will activate on its own.

- **M2** ✅ **Render cold-start fix — DONE.**
  - Added lightweight `GET /health` endpoint in [app.js](aajooBackend-2026/app.js) — no rate limiter, no DB call, returns `{status:"ok", service, uptime, timestamp}`. `HEAD` also supported for HEAD-only monitors.
  - Authored [KEEP_ALIVE_SETUP.md](KEEP_ALIVE_SETUP.md) — step-by-step config for cron-job.org (recommended, free, 10-min interval), UptimeRobot, or BetterStack. Includes verification steps and the "self-ping doesn't work" note.
  - **Action needed:** set up the external monitor (5 min in cron-job.org) to actually stop cold starts. Code side is done.

- **M3** ✅ **Legacy `lib/screens/` cleanup — Cluster A DONE.**
  - Audited every file in `lib/screens/` against the new `lib/ui/` tree. Confirmed `main.dart` imports ZERO files from `lib/screens/` — all routes (`/`, `/login`, `/home`, `/host/home`, `/verify`, `/profile`, `/history`, `/settings`, `/onboarding`, `/forgot-password`, `/support`, `/faq`, `/bookmarkProperties`, `/negotiation`, `/location-picker`, `/notifications`) point at `ui/...` paths.
  - **Deleted 37 chain-orphan files** (Cluster A — zero live anchors, only chain-imported by other legacy files):
    - All 9 `screens/Auth/` files (dir removed) → replaced by `ui/screens_common/auth/{login_signup,basic_info,emergency_number,forgot_password,govt_id_upload,house_agreement,verify}/` + `ui/screens_common/auth/referral_code_screen.dart`.
    - 14 `screens/Host/` files (kept `chat_page.dart` only — Cluster B) → replaced by `ui/screens_host/{home,profile,add_property,booking_history,support,invoices,payout,update_property,property_details,ongoing_booking}/` + `ui/screens_common/location_picker/pick_location_screen.dart` + `ui/unused_screens/{cart,product}/`.
    - `screens/Profile/update_profile_screen.dart` (dir removed) → `ui/screens_common/update_profile/`.
    - 13 `screens/` root files (history_*, location_picker, negotiation_wrapper, onboarding, privacy-policy_page, profile_screen, sample_homepage, settings_page, splash_screen, terms_condition_user_page, view_property_all_reviews_page) + `screens/Home/search_screen.dart` → replaced by their `ui/` equivalents (see Cluster A audit table in session notes).
  - Recreated `screens/view_property_all_reviews_page.dart` as a thin re-export shim (single `export` line pointing at the `ui/` version) because the kept legacy `screens/property_page.dart` still imports it. Shim disappears when Cluster B is cleaned up.
  - **Kept 13 Cluster B files** (live-anchored via stale importers in `widgets/`, `controller/`, or `lib/faq_page.dart` that still use legacy paths instead of `ui/`): `screens/Home/{homescreen, map_screen, ongoing_widget, pre_booking_screen, view_ongoing_booking}.dart`, `screens/Host/chat_page.dart`, `screens/{property_page, about_page, safety_page, support_screen, checkout_page, location_permission_denied, notification_screen}.dart`. These need a follow-up pass that redirects 6 widget/controller importers to `ui/` paths first.
  - **Verified:** `flutter analyze` → 659 issues (down from 729 baseline = **70-issue drop**, all from deleted files). Zero errors introduced.

---

## 3. Suggested order for the next dev/model
1. ✅ **H1/H2/H3/H4/H5** done — Task H fully complete; closed-testing ready. Ship a closed-testing build now.
2. ✅ **M1/M2/M3** done — Task M fully complete.
3. **E1–E4** (real OTP emails) once client picks a provider → then remove OTP bypass.
4. **P1–P3** (Razorpay live) once client provides live keys (last step before public launch).
5. **Optional follow-up:** Cluster B `lib/screens/` cleanup — redirect 6 widget/controller importers (`widgets/{negotitaion_page, custom_drawer, bookmark_properties_page, hotel_dialog, prebooking_home_carousel, pre_booking_card}.dart`, `lib/faq_page.dart`, `controller/map_controller.dart`) from `screens/...` to `ui/...` paths, then delete the remaining 13 legacy `lib/screens/` files + the re-export shim.

## 4. Closed-testing readiness checklist (2026-06-07)
- ✅ Host signup creates host role correctly
- ✅ Add Bank Account screen + gated payout request
- ✅ Friendly empty/error states on host home, profile, booking history, payout
- ✅ deleteProperty / updateCoverImage / updatePropertyStatus loading-state bugs fixed
- ✅ Real `userId` used for ongoing-bookings fetch (was hard-coded `1`)
- ✅ Pull-to-refresh on host home, payout, booking history
- ⚠️ OTP still in dev-bypass mode (code `0000`) — fine for testers, MUST remove before public launch (E4)
- ⚠️ Razorpay still in TEST mode (`rzp_test_…`) — fine for testers, swap to live before public launch (P3)
- ⬜ Tester device walkthrough still required for H3 (signup → property → booking → review → payout)

> **Guardrails carried over:** no behavior changes outside the task; `flutter analyze` stays at/below baseline (~738); never commit secrets; OTP bypass + test Razorpay keys must be removed before production launch.
