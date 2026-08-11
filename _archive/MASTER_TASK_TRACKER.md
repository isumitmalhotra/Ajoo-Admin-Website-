# AajooHomes — Master Task Tracker

> **This is the single source of truth** for all pending and completed engineering work across mobile, web, backend, payments, and ops. Every other tracker (`INTEGRATION_TASK_TRACKER.md`, `REDESIGN_TASK_TRACKER.md`, `WEB_QA_BUGS.md`) is a detailed companion — this file is the index and progress dashboard.
>
> **Last updated:** 2026-06-08 (🔴 NEW TOP PRIORITY: Section K — Didit KYC identity verification added across backend/mobile/web/admin. MOB-FEAT-04 + MOB-FEAT-09 complete.)
> **Update protocol:** Whenever a task moves status (⬜ → 🔄 → ✅), update its row here AND add a line under "§ Recently Completed". Whenever a new task is discovered, add it to the right section with a fresh ID. See "§ Update Protocol for the Next Model" at the bottom.

---

## 0 — Critical Context for Anyone Picking This Up Cold

**Read this first if you've never seen this project.** Everything else assumes you understand the architecture below.

### What this product is

AajooHomes — a short-term rental marketplace (Airbnb-like) with three user types:
- **Renters / customers** — browse, book, pay, review properties
- **Hosts** — list properties, manage bookings, receive payouts
- **Admins** — back-office moderation, coupons, FAQ, analytics

There are **three frontends** sharing **one backend + one database**:
1. **Mobile app** — Flutter, Android + iOS. Code at `aajoo_app_2026/`.
2. **Web app** — Vite + React + TypeScript + MUI v7 + Tailwind v4 + Bootstrap. Code at the **project root** (`src/`, `package.json`).
3. **Admin dashboard** — also React, lives inside the web app at `src/pages/admin/`.

### How the pieces connect

```
┌────────────────────┐   ┌────────────────────┐   ┌────────────────────┐
│   Mobile App       │   │     Web App        │   │  Admin Dashboard   │
│  (Flutter)         │   │  (React + MUI)     │   │  (inside web)      │
│  aajoo_app_2026/   │   │  src/ (root)       │   │  src/pages/admin/  │
└──────────┬─────────┘   └──────────┬─────────┘   └──────────┬─────────┘
           │                        │                        │
           │      HTTPS / JSON      │       HTTPS / JSON     │
           └────────────────────────┼────────────────────────┘
                                    ▼
                  ┌───────────────────────────────────────┐
                  │  Backend (Node 20 + Express + Sequelize) │
                  │  Deployed: https://aajaodev.onrender.com │
                  │  Code: aajooBackend-2026/                │
                  └───────────────────┬───────────────────┘
                                      ▼
                  ┌───────────────────────────────────────┐
                  │  Production DB (Clever Cloud MySQL)   │
                  │  bf0mpow9qbd34cpwy8in                 │
                  │  Creds: aajooBackend-2026/config/     │
                  │         db.config.js (gitignored)     │
                  └───────────────────────────────────────┘
```

**Consequence:** a host who signs up on web has the SAME `tbl_user` row as if they'd signed up on mobile. A booking created on mobile shows in web immediately. There is no cross-platform sync layer needed — same DB, same queries.

### Repo / folder map

```
D:\Projects\ajoo admin website\           ← project root (also web app root)
├── src/                                  ← WEB APP (React)
├── aajoo_app_2026/                       ← MOBILE APP (Flutter)
│   ├── lib/
│   │   ├── main.dart                     ← entry, GetX routes
│   │   ├── service/                      ← all Dio-based API clients
│   │   ├── models/                       ← JSON models
│   │   ├── ui/                           ← live screens (new redesign)
│   │   │   ├── screens_common/           ← shared (auth, settings, splash, support, FAQ)
│   │   │   ├── screens_renter/           ← customer-facing
│   │   │   ├── screens_host/             ← host portal
│   │   │   └── unused_screens/           ← intentionally inactive (chat, cart, product, search)
│   │   ├── widgets/                      ← shared widgets (some legacy)
│   │   └── screens/                      ← LEGACY 13-file holdover (Cluster B — see § Cleanup)
│   └── android/, ios/                    ← native shells
├── aajooBackend-2026/                    ← BACKEND (Node/Express)
│   ├── app.js                            ← entry; CORS, routes, scheduler boot
│   ├── routes/                           ← 25 route files (user, host, booking, payouts, property, review, common, chatbot, blog, admin*)
│   ├── controllers/                      ← route handlers
│   ├── models/                           ← Sequelize models, snake_case (tbl_user, tbl_property, …)
│   ├── migrations/                       ← Sequelize migrations
│   ├── schema/                           ← Yup validation schemas (uses stripUnknown — beware!)
│   ├── middleware/                       ← validation, auth (userAuthentication, hostAuthentication, adminAuthentication)
│   ├── utils/                            ← campaignScheduler, mailer, razorpay, common
│   ├── scripts/                          ← deleteTestUser, runChatbotMigrations, seedLocal
│   └── config/
│       ├── db.config.js                  ← LIVE DB creds (gitignored)
│       ├── config.json                   ← Sequelize CLI fallback (do NOT trust for prod)
│       └── commonConfig.js               ← status enums, magic numbers
└── *.md                                  ← 20+ docs — see § Documentation Map below
```

### Backend ↔ frontend wiring rules

- **Mobile**: every `lib/service/*.dart` uses `baseUrl = 'https://aajaodev.onrender.com'` hard-coded. NOT env-driven yet (acceptable for now).
- **Web**: `src/axios/axios.ts` line 17 → `https://aajaodev.onrender.com`. `src/configs/apiConfigs.ts` allows `VITE_API_BASE_URL` env override. ⚠️ `src/configs/apis.ts` line 2 still has `localhost:8000` hard-coded — legacy, should be removed (see WEB-CLEAN-01).
- **Auth model**: JWT in `Authorization: Bearer <token>` header on every protected call. Backend has three middlewares: `userAuthentication`, `hostAuthentication`, `adminAuthentication` — pick the right one per route.

### Critical guardrails (DO NOT VIOLATE)

1. **Never commit secrets.** `.env`, `config/db.config.js`, `serviceFirebase.json`, `rzp_live_*`, mailer API keys — all gitignored. Don't paste them into commits.
2. **Two dev bypasses still ON in production-deployed backend** — both must be removed before public launch:
   - `OTP_DEV_BYPASS=true` env var on Render → OTP code `0000` verifies any account. (Cleanup task E4.)
   - Razorpay `rzp_test_...` keys hardcoded in 6 Flutter files + `db.config.js`. (Cleanup task P2/P3.)
3. **`flutter analyze` baseline ~660 issues** (post M3 cleanup, down from 729). New code must not increase the count; new errors are a hard fail.
4. **Schema validation strips unknown fields** (`schema/*.js` uses Yup `stripUnknown`). If you add a new request field to a controller, you MUST also add it to the schema, or it'll silently be dropped.
5. **Render free tier sleeps after 15 min idle** — first request is slow. External pinger setup is documented in `KEEP_ALIVE_SETUP.md` — set up the cron-job.org monitor before testers complain.
6. **DB is shared with the client's Render-connected repo** (`github.com/nameeshPatiyal100/aajaoBackend`). Don't run destructive migrations without coordinating.

### Documentation Map (all under project root)

| Doc | Purpose | When to read |
|---|---|---|
| `MASTER_TASK_TRACKER.md` *(this file)* | Single source of truth for all work | Always start here |
| `KYC_DIDIT_INTEGRATION.md` | **🔴 Adapted engineering plan for Didit KYC (our MySQL/Sequelize/Flutter/React stack)** | Before starting any Section K task |
| `Aajoo_Homes_Didit_KYC_Integration_Brief.docx` | Original Didit KYC brief + verbatim code samples (Ishaan, Zyphex) | Source of truth for KYC code samples |
| `INTEGRATION_TASK_TRACKER.md` | Detailed backend integration / fixes history | Deep dive on past H/M/P/E work |
| `REDESIGN_TASK_TRACKER.md` | Detailed Sand & Indigo UI redesign phases (web A0–A6, mobile B0–B5) | Working on UI/visual tasks |
| `REDESIGN_BRIEF.md` | Brand palette spec + scope guardrails | Before any visual change |
| `REDESIGN_POC_SPEC_WEB.md` | Exact web POC measurements (radii, spacing, typography) | Visual parity work |
| `REDESIGN_CONTEXT.md` | UI redesign handoff narrative | Onboarding |
| `WEB_QA_BUGS.md` | gstack-captured web bug log (28 items, P0–P2) | Web debugging |
| `EMAIL_OTP_DELIVERY_PROPOSAL.md` | Client-facing proposal for Brevo vs Resend | Task E1 discussion |
| `KEEP_ALIVE_SETUP.md` | cron-job.org / UptimeRobot config to stop Render cold starts | Task M2 follow-through |
| `INTEGRATION_STATUS_FINDINGS.md` | Audit findings from earlier work | Reference |
| `PLATFORM_COMPLETION_STATUS_REPORT.md` | High-level platform status | Stakeholder reporting |
| `BACKEND_OPTIMIZATION_REPORT.md` | Backend performance findings | Optimization work |
| `FRONTEND_OPTIMIZATION_REPORT.md` | Frontend performance findings | Optimization work |
| `INTEGRATION_TESTING_CHECKLIST.md` | Manual QA checklist | Before each release |
| `SMOKE_TEST_REFERENCE.md` | API smoke tests | CI / pre-deploy |
| `aajoo_mobile_dev_doc.md` | Mobile dev notes | Mobile work |
| `QUICK_STATUS_SUMMARY.md` | Older one-pager status | Skip — superseded by this file |
| `WORK_COMPLETED_BY_ZYPHEX_TECH.md` | Client-facing completion log | Stakeholder reporting |
| `FMS_PLAN.md`, `HMS_SPRINT_PLAN.md`, `TASK_TRACKER.md` | Older sprint plans | Historical reference |
| `CODEBASE_INDEX.md` | High-level codebase map | Onboarding shortcut |
| `README.md` | Project README | Onboarding |

### Environment / connection cheatsheet

| Thing | Value |
|---|---|
| Backend repo (ours, source-of-truth) | `aajooBackend-2026/` (subfolder of monorepo, not a separate git repo) |
| Backend repo (client's) | `github.com/ashishrahi366/aajooBackend-2026` (main branch carries merged `naxtre-optimization`) |
| Render-connected backend repo | `github.com/nameeshPatiyal100/aajaoBackend` (auto-deploys on push to `main`) |
| Live backend URL | `https://aajaodev.onrender.com` |
| Health endpoint | `https://aajaodev.onrender.com/health` (no rate limiter, no DB call) |
| Production DB | Clever Cloud MySQL, name `bf0mpow9qbd34cpwy8in` (creds in `aajooBackend-2026/config/db.config.js`) |
| Mobile app base URL | hardcoded in every `lib/service/*.dart` |
| Web app base URL | `src/axios/axios.ts` line 17 + `src/configs/apiConfigs.ts` (env-overrideable via `VITE_API_BASE_URL`) |
| OTP dev bypass | env var `OTP_DEV_BYPASS=true` on Render → code `0000` accepts any OTP (REMOVE before launch) |
| Razorpay mode | TEST. Single source of truth: backend `aajooBackend-2026/config/payments.config.js` (reads env vars `RAZORPAY_KEY_ID` + `RAZORPAY_KEY_SECRET`), mobile `aajoo_app_2026/lib/constants/payment_config.dart` (reads `--dart-define=RAZORPAY_KEY=...`), web `src/components/frontend/RazorpayPayment.tsx` (reads `VITE_RAZORPAY_KEY`). To go live: set the env vars in Render / build flag / hosting dashboard — no code changes. |
| Delete test user (frees email + phone) | `cd aajooBackend-2026 && node scripts/deleteTestUser.js <email>` |
| Apply chatbot migrations to prod | `cd aajooBackend-2026 && node scripts/runChatbotMigrations.js` (idempotent, supports `--dry-run`) |

---

## 1 — Status Snapshot Dashboard

| Section | Total | ✅ Done | 🔄 In Progress | ⬜ Pending | 🔴 Blocked |
|---|---:|---:|---:|---:|---:|
| A. Backend (deployment, scheduler, infra) | 14 | 14 | 0 | 0 | 0 |
| B. Mobile App — UI redesign (Sand & Indigo) | 12 | 7 | 0 | 5 | 0 |
| C. Mobile App — Feature gaps from backend audit | 12 | 7 | 0 | 4 | 1 |
| D. Web App — UI redesign + bugs | 18 | 8 | 0 | 10 | 0 |
| E. Web App — Feature/data wiring | 4 | 0 | 0 | 4 | 0 |
| F. Payments (Razorpay) | 3 | 1 | 0 | 0 | 2 |
| G. Email / OTP | 4 | 1 | 0 | 0 | 3 |
| H. Cross-cutting cleanup | 6 | 2 | 0 | 4 | 0 |
| I. Closed-testing & launch readiness | 9 | 5 | 0 | 4 | 0 |
| 🔴 **K. KYC / Identity Verification (Didit)** | 29 | 0 | 0 | 25 | 4 |
| **TOTAL** | **111** | **45** | **0** | **56** | **10** |

Blocked items are all "waiting on client" — see § F and § G for details.

---

## Section A — Backend (Node/Express on Render)

> Everything under here is ✅ done. Listed for context so you know what state the backend is in. Companion: `INTEGRATION_TASK_TRACKER.md § 1`.

| ID | Status | Title | Notes |
|---|---|---|---|
| BE-DEPLOY-01 | ✅ | Merged client `naxtre-optimization` branch into `ashishrahi366/aajooBackend-2026:main` | commit `eb75d88` |
| BE-DEPLOY-02 | ✅ | Synced merged code into local monorepo backend (104 files) preserving local config/secrets | — |
| BE-DEPLOY-03 | ✅ | Pushed prod backend to Render repo `main` (dev bypasses removed for that copy) | — |
| BE-DEPLOY-04 | ✅ | Fixed Render boot crash — `models/index.js` now uses `db.config.js` regardless of `NODE_ENV` | was crashing on `config.json[production]` lookup |
| BE-DEPLOY-05 | ✅ | Boot-time DB authenticate + scheduler made non-fatal | service starts even on DB blip |
| BE-DEPLOY-06 | ✅ | Added gitignore entries for `.env`, `db.config.js`, `serviceFirebase.json` | secrets safety |
| BE-SCHED-01 | ✅ | Chatbot scheduler (`campaignScheduler.js`) preflights `tbl_chatbot_*` tables; self-disables silently if missing | Task M1 |
| BE-SCHED-02 | ✅ | `app.js` awaits async `startScheduler()` so preflight runs before any tick | — |
| BE-SCHED-03 | ✅ | New helper `scripts/runChatbotMigrations.js` — idempotent, `--dry-run` supported, connects via `db.config.js` | Task M1 |
| BE-OPS-01 | ✅ | Added `GET /health` endpoint (no rate limit, no DB call) + `HEAD /health` | Task M2 |
| BE-OPS-02 | ✅ | Authored `KEEP_ALIVE_SETUP.md` with cron-job.org / UptimeRobot config | Task M2 |
| BE-OTP-01 | ✅ | Diagnosed Render blocks SMTP → Gmail OTP times out; root cause documented | — |
| BE-OTP-02 | ✅ | Added env-gated `OTP_DEV_BYPASS` → code `0000` accepts any OTP (FOR QA ONLY) | Cleanup tracked as E4 |
| BE-OTP-03 | ✅ | Authored `EMAIL_OTP_DELIVERY_PROPOSAL.md` (Brevo vs Resend, pricing, sender domain steps) | Client decision pending |

---

## Section B — Mobile App — UI Redesign (Sand & Indigo)

> Brand spec: `REDESIGN_BRIEF.md`. Palette tokens in `aajoo_app_2026/lib/constants.dart` (`kIndigo`, `kSand`, `kCream`, `kClay`, `kLine`, `kInk`, `kInk2`, `kMuted`, `kSuccess`, `kDanger`). Typography: Fraunces (serif headings) + Inter (body) via `lib/utils/fonts.dart`.
> Companion: `REDESIGN_TASK_TRACKER.md PART B`.

| ID | Status | Title | Files / notes |
|---|---|---|---|
| MOB-RED-B1 | ✅ | Central theme migration (light + dark, all tokens applied) | `main.dart`, `constants.dart` |
| MOB-RED-B2 | ✅ | Hardcoded pinks + gradients purged | global sweep |
| MOB-RED-B3 | ✅ | Renter (customer-facing) screens — palette + chrome | `ui/screens_renter/*` |
| MOB-RED-B4 | ✅ | Host screens — palette pass (was H5) | `ui/screens_host/*` |
| MOB-RED-H5 | ✅ | Host typography pass (Fraunces headings, Inter body, cream cards) | `host_home_screen`, `main_screen`, `invoice_page`, `payout_page`, etc. |
| MOB-RED-Q1 | ✅ | Quote banner rainbow colors → brand palette | `widgets/quote_widget.dart` |
| MOB-RED-Q2 | ✅ | Recent transaction tile rebranded (cream + kLine, Inter) | `host_recent_transaction_item_view.dart` |
| MOB-RED-B3-17 | ⬜ | Hero CTA clay fill (renter home) | Needs JSX-like restructure; logged in `REDESIGN_OPEN_QUESTIONS.md` |
| MOB-RED-B3-20 | ⬜ | Renter device walkthrough — LIGHT theme (Home → Details → Checkout → Confirmation) | Manual — on physical device |
| MOB-RED-B3-21 | ⬜ | Renter device walkthrough — DARK theme | Manual — on physical device |
| MOB-RED-B4-11 | ⬜ | Host device walkthrough — light + dark for all host screens | Manual — on physical device |
| MOB-RED-B5 | ⬜ | Final cleanup + manual walks per theme (renter light/dark + host light/dark) | Manual — closes Phase B |

---

## Section C — Mobile App — Feature Gaps from Backend Audit

> These backend endpoints exist on `https://aajaodev.onrender.com` but the mobile app never calls them. Each row = a feature the user can't access from the app today. Priority tag in parentheses.
>
> Schema rule reminder: if you add new request fields to a controller, add them to `aajooBackend-2026/schema/<routeName>.schema.js` too — Yup `stripUnknown` will silently drop unknown keys.

| ID | Status | Endpoint | Missing UI / behaviour | Suggested file(s) | Acceptance |
|---|---|---|---|---|---|
| MOB-FEAT-01 | ✅ | `POST /user/notification/mark-read` | Tap on notification now fires mark-read with optimistic UI flip; reverts on failure. Also fixed inverted read/unread visual logic — unread is now bold + accent indigo icon + clay dot; read is muted. | `notification_service.dart` (new `markNotificationAsRead`), `notication_controller.dart` (new `markAsRead`), `notification_screen.dart`, `notification_list_item.dart` |
| MOB-FEAT-02 | ✅ | `POST /properties/user-saveProp` + `POST /user/saved-properties` | Bookmarks now backend-synced. Heart-icon toggle calls server; bookmarks page fetches user's saved list with pull-to-refresh; cache cleared on logout (no cross-user leakage). **Backend `UserSavedProperties` handler was BROKEN** (never sent a response, demanded a nonsensical `propId` filter, had no JWT middleware → security hole) — fixed: uses `req.user.userId` from JWT, returns properties with `propDetails` association, schema relaxed to optional pagination only, route gated on `authenticateJWT`. | `bookmark_service.dart` (full rewrite — backend-driven with in-memory cache), `bookmark_properties_page.dart` (pull-to-refresh, wired dead heart icon, optimistic remove), `property_page.dart` (optimistic toggle + revert), `auth_controller.dart` (clear cache on logout); backend `controllers/user.controller.js`, `routes/user.routes.js`, `schema/user.schema.js` |
| MOB-FEAT-03 | ⬜ | `POST /host/confirm-book` | Host can't approve a pending booking from the app. Either confirm with client this is auto-confirm, or wire a CTA. | `lib/ui/screens_host/booking_history/` or `lib/ui/screens_host/ongoing_booking/` | **First: clarify with client.** If manual confirm: "Approve" CTA on pending bookings, fires endpoint, refreshes list. |
| MOB-FEAT-04 | ✅ | `POST /user/update-password` | New "Change Password" entry in Settings (Account section) → dedicated screen. **Note:** the `/user/password/verify-otp` route is commented out on the backend, so this uses the live current-password-based endpoint (requires `userId` + `currentPassword` + `newPassword` + `confirmPassword`, JWT-auth) — cleaner than OTP for an authenticated user. Client-side validation mirrors the backend Yup rules (8+ chars, upper/lower/digit/special, no spaces, confirm match); server message surfaced on failure (e.g. wrong current password). | `service/user_service.dart` (`changePassword`), `controller/user_controller.dart` (`changePassword`), new `ui/screens_common/settings/change_password_page.dart`, `settings_page.dart` (new Account section + tile) | ✅ Done 2026-06-08 |
| MOB-FEAT-05 | ✅ | `POST /user/delete/profile-pic` | Tapping the avatar/camera badge on profile now opens a Change/Remove/Cancel bottom sheet (when a photo exists); pickers + remove wired through `UserController.removeProfileImage()` → `UserService.deleteProfileImage()`. UI reverts to initials avatar via existing `authController.getUserDetails()` refresh. | `service/user_service.dart`, `controller/user_controller.dart`, `ui/screens_renter/profile/profile_screen.dart` |
| MOB-FEAT-06 | ⬜ | `GET /user/reg-docType` | ⚠️ **SUPERSEDED by Section K (Didit KYC).** The manual doc-type upload approach is replaced by Didit's automated scan + liveness + face match. Do NOT re-enable the old commented-out KYC section as-is — implement the Didit host gate (`KYC-MOB-02`) instead. Kept here for historical context. | — | (parked — see Section K) |
| MOB-FEAT-07 | ✅ | `POST /review/user/delete-review` | Trash icon next to the edit pencil in `MyReviewSection` → confirm dialog ("Delete review?") → `UserController.deleteUserReview(reviewId)` → backend soft-deletes via `br_isDelete=1` (filtered by `br_userId` from JWT so users can never delete others' reviews) → list refresh via `PropertyReviewController.getPropertyReviews`. | `service/user_service.dart`, `controller/user_controller.dart`, `ui/screens_renter/history/history_description/review/my_review_section.dart` |
| MOB-FEAT-08 | ⬜ | `GET /common/states` + `GET /common/country` | Address forms use free-text; typos cause filter mismatches downstream. | `common_service.dart` + property listing form + profile address fields | State + Country become dropdowns wherever an address is collected (host_property_listing_screen, profile, checkout). |
| MOB-FEAT-09 | ✅ | `GET /common/term-condition-host` | "Host Terms & Conditions" entry added to host drawer. Reuses the existing renter `TermsPage` (response shape is identical) via a new `isHost` flag that switches the endpoint + title; `StaticPageService.getTermsAndCondtionData({isHost})` + `StaticPageController.getTermsData({isHost})` parameterized (default `false`, so renter callers are unaffected). | `service/static_page_service.dart`, `controller/static_page_controller.dart`, `ui/screens_common/terms_and_conditions/terms_condition_user_page.dart` (added `isHost`), `ui/screens_host/home/host_home_drawer.dart` (drawer entry) | ✅ Done 2026-06-08 |
| MOB-FEAT-10 | ✅ | `POST /user/logout` | `auth_controller.logout()` now calls `authService.serverLogout()` (deletes the `tbl_user_login_auth` row server-side, invalidates JWT) BEFORE local token clear. Failure tolerated — local logout always proceeds so users are never stuck signed-in due to a network blip. | `service/auth_service.dart` (new `serverLogout()`), `ui/screens_common/auth/auth_controller.dart` |
| MOB-FEAT-11 | ⬜ | `POST /properties/user-likeProp` + `POST /properties/user-dislikeProp` | Property like/dislike (separate from review-like). Unclear if product wants it. | `property_service.dart` + property detail screen | **First: clarify with client** if this is a planned feature. If yes: thumbs up/down on property detail. |
| MOB-FEAT-12 | 🔴 | E2E host device walkthrough | Tester walk: signup host → add property → edit → status → cover image → ongoing bookings → history → review → transactions → payout (Bank Account → add → request). | All host screens | Pull-to-refresh works on every list; no infinite spinners; no red errors on empty. Blocked on getting a test device + Razorpay test card. |

---

## Section D — Web App — UI Redesign + Bugs

> Companion: `REDESIGN_TASK_TRACKER.md PART A` + `WEB_QA_BUGS.md` (28 bugs catalogued by gstack QA).
> Brand tokens: `src/theme/themeColor.tsx` (`Brand` object) + `src/index.css` (CSS vars + Tailwind v4 `@theme`).
> Build: `npm run build` (must stay green every phase).

### D.1 Redesign phases

| ID | Status | Title | Notes |
|---|---|---|---|
| WEB-RED-A1 | ✅ | Color tokens — `Brand` object + CSS vars + Tailwind `@theme` | commit `6496c68` |
| WEB-RED-A2 | ✅ | Centralized surfaces — global CSS, layout, forms (97-file PowerShell sweep) | commit `6496c68` |
| WEB-RED-A2.5 | ✅ | POC parity (radii, shadows, typography Fraunces + Inter, hero, search bar, nav, footer) | commit `8fa1c1a` |
| WEB-RED-A2.5-42 | ⬜ | Responsive @ ≤900px — partial only (nav 14/20, grid 2-col, hero collage hide on mobile) | Mobile breakpoint finishing |
| WEB-RED-A3 | ⬜ | Customer-facing pages (listing, detail, checkout) full pass | Mostly done; A3-10 funnel walkthrough pending |
| WEB-RED-A3-10 | ⬜ | Manual funnel walkthrough Home → Listing → Detail → Checkout → Confirmation | Manual — browser |
| WEB-RED-A4 | ⬜ | Admin + Host palette pass | Some Sprint 1 P0 fixes landed; full pass pending |
| WEB-RED-A5 | ⬜ | Polish pass (applied during A3–A4) | Tracks as we go |
| WEB-RED-A6 | ⬜ | Final cleanup + parity verify | Pre-launch |
| WEB-RED-A6-04 | ⬜ | Manual walk every flow for parity | Manual — browser |

### D.2 Web QA bugs (from `WEB_QA_BUGS.md`)

| ID | Status | Severity | Bug |
|---|---|---|---|
| WEB-QA-P0-01..08 | ✅ | P0 | Sprint 1 done — host sidebar purple, admin login red/orange, admin logo missing, etc. (8 items) |
| WEB-QA-P0-09 | ⬜ | P0 | VerifyOtp + ResetPassword pages crash with React errors when navigated directly. Deferred from Sprint 1. |
| WEB-QA-P1-01..13 | ⬜ | P1 | 13 visual regressions: Playfair/Poppins still loaded, oversize hero images, Location-unavailable red widget on Home, Featured Properties empty, mobile listing no map toggle, desktop empty space, etc. See `WEB_QA_BUGS.md` for full list. |
| WEB-QA-P2-01..06 | ⬜ | P2 | 6 polish gaps: Property Detail amenities grid, checkout amenity pills off-spec, "Jhon!" typo, dashboard gray bg, stray Poppins fontFamily strings (14 files), Cancel Result page gray bg |

> Action: pull P1/P2 items into here as concrete IDs when you start the Sprint 2 web pass. Until then, this single row tracks the bucket.

---

## Section E — Web App — Feature/Data Wiring

| ID | Status | Title | Why | Where |
|---|---|---|---|---|
| WEB-FEAT-01 | ⬜ | Admin Dashboard timeout fix | `/admin/dashboard` and `/admin/users` time out on load (Obs #1183 from Jun 6 session) | `src/pages/admin/dashboard/*` — check API timeouts / pagination |
| WEB-FEAT-02 | ⬜ | Host Portal feature parity audit vs mobile | Confirm web host has every flow mobile host has (add property, payout account, etc.) | `src/pages/host/*` — match against §C MOB-FEAT-* list |
| WEB-FEAT-03 | ⬜ | Geolocation API console warning (Obs #1170) | Browser console emits Geolocation deprecation warnings on Home | `src/pages/user/home/*` |
| WEB-FEAT-04 | ⬜ | Deprecated `motion()` warning (P1-08) | Every page logs a `framer-motion` deprecation | global — update import API |

---

## Section F — Payments (Razorpay)

> Currently TEST mode. As of PAY-02, **every** Razorpay credential reference goes through one of three single-source-of-truth files (one per platform). To go live: set env vars; no code changes.

| ID | Status | Title | Owner / blocker |
|---|---|---|---|
| PAY-01 | 🔴 | Obtain LIVE Razorpay credentials (`rzp_live_*` + secret) after business KYC | **Client** |
| PAY-02 | ✅ | Centralize the Razorpay key across backend / mobile / web. See implementation below. | Done 2026-06-08 |
| PAY-03 | 🔴 | Swap test → live keys, retest real payment + signature verification | Blocked on PAY-01. When unblocked: see "PAY-03 procedure" below. |

### PAY-02 — Implementation (✅ done)

**Backend** — single source: `aajooBackend-2026/config/payments.config.js`
- Exports `{ razorpay: { keyId, keySecret, isLiveMode } }`.
- Reads `process.env.RAZORPAY_KEY_ID` + `RAZORPAY_KEY_SECRET`; falls back to bundled TEST key with a runtime warning if env vars are missing.
- Required by `aajooBackend-2026/utils/razorpay.js` (order + verify + payment-link) AND `aajooBackend-2026/controllers/booking.controller.js` (the second Razorpay instance in this file also flows through here now).
- Removed duplicate exports from `config/db.config.js` and `config/moduleConfigs.js` (those files now have comments pointing at `payments.config.js`).
- Added to `aajooBackend-2026/.env` + new `aajooBackend-2026/.env.example`.

**Mobile (Flutter)** — single source: `aajoo_app_2026/lib/constants/payment_config.dart`
- `PaymentConfig.razorpayKey` getter — resolves runtime override → `--dart-define=RAZORPAY_KEY=...` build flag → bundled TEST fallback.
- `PaymentConfig.isLiveMode` boolean helper.
- `PaymentConfig.overrideRazorpayKey(key)` for runtime injection if we ever expose `GET /config/payments`.
- All 6 hardcoded `"key": "rzp_test_..."` strings replaced with `PaymentConfig.razorpayKey`:
  - `lib/ui/screens_renter/property_details/property_page.dart:906`
  - `lib/ui/screens_renter/home/view_ongoing_booking.dart:451`
  - `lib/ui/screens_common/price_negotiation/negotitaion_page.dart:233`
  - `lib/widgets/negotitaion_page.dart:234` *(legacy widget — Cluster B; updated for safety)*
  - `lib/screens/Home/view_ongoing_booking.dart:445` *(legacy — Cluster B)*
  - `lib/screens/property_page.dart:864` *(legacy — Cluster B)*

**Web (React)** — single source: `src/components/frontend/RazorpayPayment.tsx`
- Reads `import.meta.env.VITE_RAZORPAY_KEY` with bundled TEST fallback.
- Documented in `.env.example` (root).

**Verification:** `grep -n "rzp_test_XUTODhUdMAshi6"` returns matches only in (a) the 3 single-source files' fallback constants, (b) `.env.example` documentation, (c) tracker docs. Zero business-logic files have the literal key. `flutter analyze` unchanged (659 baseline). Backend boot smoke-tested — every require chains correctly.

### PAY-03 procedure (when live keys arrive)

1. **Backend (Render):** Dashboard → Environment → set:
   - `RAZORPAY_KEY_ID=rzp_live_xxxxxxxxxxxx`
   - `RAZORPAY_KEY_SECRET=<live secret>`
   - Restart the service. Boot log should NOT show "RAZORPAY_KEY_ID env var not set — falling back" — if it does, the env vars didn't load.
2. **Mobile (app build):** rebuild with `--dart-define=RAZORPAY_KEY=rzp_live_xxxxxxxxxxxx`. Example: `flutter build apk --release --dart-define=RAZORPAY_KEY=rzp_live_xxx`. Confirm `PaymentConfig.isLiveMode == true` at runtime if you add a debug log.
3. **Web (Vercel/Netlify env):** set `VITE_RAZORPAY_KEY=rzp_live_xxx` in the hosting dashboard, redeploy.
4. **Test a real payment** with a real (small-amount) UPI/card transaction. Confirm `verifyPayment` HMAC check passes on the backend log. Cancel-and-refund flow if available.
5. Once live works, REMOVE the OTP dev bypass (EMAIL-04) so the cutover is complete.

---

## Section G — Email / OTP

> Render blocks outbound SMTP (25/465/587). Cannot use Gmail / nodemailer-SMTP. Must switch to HTTP API. Proposal doc: `EMAIL_OTP_DELIVERY_PROPOSAL.md`.

| ID | Status | Title | Owner / blocker |
|---|---|---|---|
| EMAIL-01 | 🔴 | Client picks Brevo (recommended) or Resend; creates account; verifies sender/domain (SPF/DKIM); provides API key + "from" address | **Client** |
| EMAIL-02 | 🔴 | Rewrite `aajooBackend-2026/utils/mailer.js` from nodemailer-SMTP → HTTP API (port 443; Render-friendly). All OTP/email flows route through `mailer`, so it's a contained ~1-hour change. | Blocked on EMAIL-01 |
| EMAIL-03 | 🔴 | Add API key + `MAIL_FROM` as Render env vars | Blocked on EMAIL-01 |
| EMAIL-04 | ✅ | OTP dev bypass added (env-gated `OTP_DEV_BYPASS=true` + code `0000`) so QA can proceed | Tracker note: REMOVE the bypass block in `controllers/user.controller.js` AND unset the Render env var once EMAIL-02/03 are live. Until then this stays as the QA path. |

---

## Section H — Cross-cutting Cleanup

| ID | Status | Title | Notes |
|---|---|---|---|
| CLEAN-01 | ✅ | Legacy `lib/screens/` Cluster A — 37 chain-orphan files deleted | Task M3; `flutter analyze` 729 → 659 |
| CLEAN-02 | ⬜ | Legacy `lib/screens/` Cluster B — redirect 6 stale importer files (`widgets/{negotitaion_page, custom_drawer, bookmark_properties_page, hotel_dialog, prebooking_home_carousel, pre_booking_card}.dart`, `lib/faq_page.dart`, `controller/map_controller.dart`) from `screens/...` → `ui/...` paths, then delete the remaining 13 legacy files + the `view_property_all_reviews_page.dart` re-export shim | After redirects, `flutter analyze` should drop another ~50–80 issues. Requires device verification of the affected flows (price negotiation, bookmarks, property detail). |
| WEB-CLEAN-01 | ⬜ | Remove `src/configs/apis.ts` `localhost:8000` constant | `src/configs/apis.ts` line 2 hardcodes `http://localhost:8000`. Live web uses `src/configs/apiConfigs.ts`. Delete `apis.ts` if nothing imports it; otherwise migrate importers to `apiConfigs.ts`. |
| CLEAN-03 | ⬜ | Update `MOBILE` Razorpay key references (subsumed by PAY-02) | See PAY-02 — same work |
| CLEAN-04 | ⬜ | Run `node scripts/runChatbotMigrations.js` against prod DB when client greenlights chatbot | Idempotent. After running, restart the Render service so `campaignScheduler` activates. |
| CLEAN-05 | ✅ | Env-gate every secret in `config/db.config.js` + `config/moduleConfigs.js` | **2026-06-08.** Live secrets (cloudinary ×3, mail ×2, DB ×6) and the leaking `whats_app_verify_token` (in a git-TRACKED file) now read `process.env.X \|\| "fallback"`. Vestigial `googleClientId/Secret` + `cloundinaryEnvVariable` commented out (zero consumers). Verified: identical resolved values when env unset; env wins when set; every consumer (`utils/cloudinary.js`, `utils/mailer.js`, all 59 Sequelize models) loads clean. Env-var names documented in `aajooBackend-2026/.env` + `.env.example`. **Production cutover:** set the env vars in Render Dashboard → Environment, restart. Behaviour is identical to today until you set them. |

---

## Section I — Closed-Testing & Launch Readiness

| ID | Status | Title | Notes |
|---|---|---|---|
| RDY-01 | ✅ | Host signup creates host role correctly (was creating renter) | Fixed in `createUser` controller — accepts `true/1/"true"/"1"` for `user_isHost` |
| RDY-02 | ✅ | Add Bank Account screen + gated payout request | Task H1 |
| RDY-03 | ✅ | Friendly empty/error states on host home, profile, booking history, payout | Task H2 |
| RDY-04 | ✅ | `deleteProperty` / `updateCoverImage` / `updatePropertyStatus` loading-state bugs fixed | Task H3 |
| RDY-05 | ✅ | Real `userId` used for ongoing-bookings fetch (was hard-coded `1`) | — |
| RDY-06 | ⬜ | Set up external keep-alive monitor (cron-job.org or UptimeRobot pinging `/health` every 5–10 min) | See `KEEP_ALIVE_SETUP.md`. 5 min setup. Without this, first request after 15 min idle takes 30–50s. |
| RDY-07 | ⬜ | E2E host walkthrough on real device (companion to MOB-FEAT-12) | signup host → property CRUD → booking lifecycle → review → payout |
| RDY-08 | ⬜ | E2E renter walkthrough on real device (light + dark theme) | search → book → pay (test card) → review → bookmark |
| RDY-09 | ⬜ | Pre-public-launch hard cutover checklist | (1) Remove `OTP_DEV_BYPASS` (EMAIL-04 cleanup) (2) Swap Razorpay test → live (PAY-03) (3) Delete `aajoo_app_2026/lib/screens/` entirely (after CLEAN-02) (4) Final `flutter analyze` ≤ baseline (5) Backup prod DB |

---

## Section K — KYC / Identity Verification (Didit) 🔴 TOP PRIORITY

> **Full plan:** `KYC_DIDIT_INTEGRATION.md` (our-stack adaptation) + `Aajoo_Homes_Didit_KYC_Integration_Brief.docx` (source + code samples).
> **Goal:** Didit identity verification (doc scan + passive liveness + face match + IP analysis) across backend + mobile + web + admin. Two hard gates:
> - **Host gate:** property cannot go live until host KYC `Approved`.
> - **Guest gate:** booking cannot confirm until guest KYC `Approved` (skip if verified within 90 days).
>
> ⚠️ **Stack reality (the brief is PostgreSQL/generic-Express):** our backend is **MySQL + Sequelize** (`tbl_*` snake_case, `common.response`), shared DB across two backend repos (coordinate migrations). Webhook `/webhooks/didit` must use **`express.raw()`** so the `x-signature-v2` HMAC is computed over the raw body. Yup `stripUnknown` — add new fields to `schema/*.js`. Flutter SDK `didit_flutter_sdk` — **verify it exists/maturity on pub.dev first**, else fall back to hosted `session_url` in an in-app browser. All Didit secrets env-gated (cf. PAY-02 / CLEAN-05).
>
> **Code can be built now** against env vars (same pattern as PAY-02) — only live end-to-end testing is blocked on the console credentials + a test device.

### K.1 Console / credentials setup (owner: Sumit — Didit Business Console)

| ID | Status | Title | Notes |
|---|---|---|---|
| KYC-SETUP-01 | ⬜ | Get Didit API key + Webhook Secret from Business Console | Console → API & Webhooks |
| KYC-SETUP-02 | ⬜ | Create + publish `host-kyc-v1` workflow → copy `workflow_id` | Template: Full KYC Onboarding; modules ID→Liveness→Face Match→IP |
| KYC-SETUP-03 | ⬜ | Create + publish `guest-kyc-v1` workflow → copy `workflow_id` | same modules |
| KYC-SETUP-04 | ⬜ | Add all Didit env vars to `aajooBackend-2026/.env` + `.env.example` + Render | API key, webhook secret, base URL, both workflow IDs |
| KYC-SETUP-05 | ⬜ | Register webhook URL in Console (`https://aajaodev.onrender.com/webhooks/didit`) | Cloudflare WAF IP-whitelist (`18.203.201.92`) N/A unless Cloudflare added |

### K.2 Backend (Node/Express + Sequelize/MySQL)

| ID | Status | Title | Where / acceptance |
|---|---|---|---|
| KYC-BE-01 | ⬜ | Migration: KYC columns on `tbl_user` (`didit_session_id`, `verification_status` enum unverified/pending/verified/declined/in_review, `verified_at`, `verification_expires_at`) + indexes | `migrations/`, model `models/user.js` |
| KYC-BE-02 | ⬜ | Migration: `tbl_bookings` (`guest_verification_status`, `guest_didit_session_id`) | adapt PG → MySQL |
| KYC-BE-03 | ⬜ | Migration: property status supports `pending_verification`; host gate respected in listing queries | `tbl_property` |
| KYC-BE-04 | ⬜ | New `tbl_admin_flags` table + Sequelize model (user_id, session_id, flag_type, resolved, notes, created_at) | for in_review queue |
| KYC-BE-05 | ⬜ | `POST /verify/create-session` → calls Didit `/v3/session/`, builds `vendor_data` (`host_<id>` / `guest_<id>_booking_<bid>`), stores `session_id` + sets status `pending` | controller + route + schema |
| KYC-BE-06 | ⬜ | `GET /verify/status?session_id=` → returns our DB verification_status (for web polling) | — |
| KYC-BE-07 | ⬜ | `POST /webhooks/didit` with **HMAC `x-signature-v2`** verification over **raw body** (`express.raw`), routes to approved/declined/in_review | #1 footgun — raw body |
| KYC-BE-08 | ⬜ | Handlers: `handleApproved` (host→property live + notify; guest→booking confirmed + notify), `handleDeclined`, `handleInReview` (+admin flag) | reuse existing notification system |
| KYC-BE-09 | ⬜ | `shouldSkipVerification` (verified within 90 days) + enforce gates (property not live / booking not confirmed until Approved) | guest skip logic |
| KYC-BE-10 | ⬜ | `GET /verify/check-session/:id` polling fallback → Didit `/v3/session/:id/decision/` | fallback only |

### K.3 Mobile (Flutter)

| ID | Status | Title | Where / acceptance |
|---|---|---|---|
| KYC-MOB-01 | ⬜ | Add `didit_flutter_sdk` to `pubspec.yaml` (verify availability first; else hosted-URL fallback) | `aajoo_app_2026/pubspec.yaml` |
| KYC-MOB-02 | ⬜ | **Host gate** on property submit → create session → launch SDK; do NOT submit listing until Approved (webhook) | `ui/screens_host/add_property/*` |
| KYC-MOB-03 | ⬜ | **Guest gate** on Confirm Booking → skip if verified <90d, else session+SDK; booking auto-confirms on webhook | `ui/screens_renter/.../checkout` / booking confirm |
| KYC-MOB-04 | ⬜ | Handle SDK callbacks (`onSuccess`→pending screen, `onError`, `onUserCancelled`) — never unlock on onSuccess | both gates |
| KYC-MOB-05 | ⬜ | All 8 KYC UI states + green "Verified" badge; Sand & Indigo styled | shared widget |

### K.4 Web (React)

| ID | Status | Title | Where / acceptance |
|---|---|---|---|
| KYC-WEB-01 | ✅ | Host verify gate — VerifyButton → `create-session` → redirect to `session_url`; surfaced on HostProfile (no host property-submit page in admin FE) | `src/components/frontend/kyc/VerifyButton.tsx`, `src/pages/host/HostProfile.tsx` |
| KYC-WEB-02 | ✅ | Guest verify gate at checkout + 90-day skip (activates when bookingId in router state) | `src/pages/user/UserCheckoutPage.tsx` |
| KYC-WEB-03 | ✅ | `/verify/complete` return page — polls `GET /verify/status` every 3s until terminal | `src/pages/user/verify/VerifyComplete.tsx` + `src/App.tsx` route |
| KYC-WEB-04 | ✅ | All 8 KYC UI states + verified badge (Sand & Indigo) | `src/components/frontend/kyc/KycStatusBadge.tsx` |

### K.5 Admin dashboard

| ID | Status | Title | Where / acceptance |
|---|---|---|---|
| KYC-ADM-01 | ⬜ | Verification Queue view — lists `in_review` users (name, type, session ID, date) + Console link + Approve/Decline buttons wired to backend | `src/pages/admin/*` + backend admin endpoint |

### K.6 End-to-end testing (🔴 blocked on KYC-SETUP creds + test device)

| ID | Status | Title | Notes |
|---|---|---|---|
| KYC-QA-01 | 🔴 | E2E host verification — app + web | needs live creds + device |
| KYC-QA-02 | 🔴 | E2E guest verification — app + web | — |
| KYC-QA-03 | 🔴 | Declined scenario — webhook fires + DB updates correctly | — |
| KYC-QA-04 | 🔴 | In-review scenario — admin flag appears in queue | — |

---

## § Recently Completed (rolling log, newest first)

Add a 1-line entry every time a task moves to ✅. Keep newest at the top; trim items older than 60 days into `INTEGRATION_TASK_TRACKER.md § 1`.

- **2026-06-08** — MOB-FEAT-04 + MOB-FEAT-09. (04) New "Change Password" screen under Settings → Account, backed by `POST /user/update-password` (current-password-based; the OTP verify route is commented out on the backend). Client-side validation mirrors the backend Yup rules; server message surfaced on failure. New `changePassword` on `UserService` + `UserController`, new `change_password_page.dart`. (09) "Host Terms & Conditions" added to the host drawer — renter `TermsPage` reused via a new `isHost` flag (identical response shape); `StaticPageService`/`StaticPageController` parameterized with `isHost` (default false, renter callers unaffected). `flutter analyze` stays at 648 issues; zero new errors/warnings.
- **2026-06-08** — MOB-FEAT-05/07/10 Three quick wins: (10) `auth_controller.logout()` now hits `POST /user/logout` to invalidate the server session before local-token clear; failure tolerated. (07) Trash CTA on `MyReviewSection` with confirm dialog → soft-delete via `POST /review/user/delete-review` → list refresh. (05) Profile avatar tap now opens a Change/Remove/Cancel bottom sheet when a photo exists; new `removeProfileImage()` plumbing through `UserController` + `UserService`. Project analyze stays at 648 issues; zero new errors/warnings.
- **2026-06-08** — MOB-FEAT-02 Bookmarks now backend-synced. Fixed broken `UserSavedProperties` controller (never returned a response + no JWT). Mobile `BookmarkService` rewritten to call `/properties/user-saveProp` (toggle) and `/user/saved-properties` (list) with in-memory cache + logout invalidation. Bookmarks page has pull-to-refresh; previously-dead heart-icon on each card now removes. Survives logout + reinstall. `flutter analyze` 659 → 648 (11 fewer issues).
- **2026-06-08** — MOB-FEAT-01 Notification tap now fires `/user/notification/mark-read` with optimistic local flip (reverts on server reject). Also fixed pre-existing inverted read/unread visual logic — unread is now bold + indigo accent + clay dot, read is muted on sand background. Brand-token pass on `notification_list_item.dart`.
- **2026-06-08** — CLEAN-05 All backend secrets env-gated with fallbacks. Discovered `whats_app_verify_token` was leaking in `config/moduleConfigs.js` (tracked in git). Cloudinary + mail + DB creds all now `process.env.X || fallback`. Zero functional change when env vars unset. Renders deploys can now rotate any secret via Dashboard → Environment without a code push.
- **2026-06-08** — PAY-02 Razorpay key centralized: new `aajooBackend-2026/config/payments.config.js` + `aajoo_app_2026/lib/constants/payment_config.dart` + `VITE_RAZORPAY_KEY` env var on web. All 6 mobile hardcoded copies + 2 backend duplicates replaced. Live cutover is now a 3-place env-var change (Render / `--dart-define` / Vercel) with zero code edits. `flutter analyze` unchanged at 659.
- **2026-06-08** — CLEAN-01 (M3) Legacy `lib/screens/` Cluster A — 37 files deleted, 659 analyze issues (down from 729), zero new errors. 13 Cluster B files kept for a CLEAN-02 follow-up.
- **2026-06-08** — BE-OPS-01 + BE-OPS-02 (M2) `GET /health` endpoint added (no rate limit, no DB call) + `KEEP_ALIVE_SETUP.md` authored with cron-job.org / UptimeRobot setup.
- **2026-06-08** — BE-SCHED-01..03 (M1) `campaignScheduler.js` self-disables silently when chatbot tables missing; `runChatbotMigrations.js` helper added.
- **2026-06-07** — MOB-RED-Q1/Q2 + H5 + H4 — host typography pass (Fraunces + Inter), dead `DummyScreen` removed from `main_screen.dart`, quote banner rainbow → brand palette.
- **2026-06-07** — Task H3 — host walkthrough code-level audit; `deleteProperty` / `updateCoverImage` / `updatePropertyStatus` bugs fixed.
- **2026-06-07** — Task H2 — friendly empty/error states across host home, profile, booking history, payout. Per-resource fetch flags on `HostController`. Pull-to-refresh on host home.
- **2026-06-07** — Task H1 — Payout Account screen + backend `GET /payout/account/details` + gated Request-Payout button + drawer entry.

---

## § Update Protocol for the Next Model

**When you finish a task:**
1. Flip its row's status from ⬜/🔄 → ✅ in this file.
2. Add a 1-line entry to "§ Recently Completed" with date + ID + 1-sentence summary.
3. Update "§ Status Snapshot Dashboard" counts in section 1.
4. If the task referenced a companion doc (`INTEGRATION_TASK_TRACKER.md`, `REDESIGN_TASK_TRACKER.md`, etc.), update that doc too — this file points; companions detail.
5. Update the "Last updated" line at the top.
6. Commit with a clear message: `chore(tracker): mark <ID> complete` or include it in the feature commit.

**When you discover a new task:**
1. Pick the right section. If none fits, add a section heading and update the dashboard.
2. Assign an ID: `<SECTION>-<TYPE>-<NN>` where SECTION = BE/MOB/WEB/PAY/EMAIL/CLEAN/RDY, TYPE = RED/FEAT/QA/DEPLOY/SCHED/OPS/OTP/CLEAN/FIX, NN = next free number. Examples: `MOB-FEAT-13`, `WEB-QA-P0-10`.
3. Fill in: Status ⬜, Title (1 line), Why/where/done-when (be concrete — file paths, acceptance criteria).
4. If it's blocked, mark 🔴 and put the blocker in the "Owner / blocker" column.

**When you mutate this file:**
- Keep the table structure — don't break columns; many models grep this file.
- Keep IDs stable; never renumber. New IDs go at the end of their section.
- Don't delete completed rows — keep them for context. Only archive when a section gets >40 rows.

**When you start a fresh chat in any Claude account:**
- Read this file FIRST. The "§ 0 Critical Context" section is enough to start coding cold.
- Then read whichever companion doc the task you're picking up points at.
- If you discover something this file is wrong about, fix this file before doing anything else.

---

## § Quick "What should I do next?" Decision Tree

```
🔴 TOP PRIORITY (client-requested, build ASAP): Section K — Didit KYC
  → Start the code now (env-var-driven, like PAY-02 — not blocked on creds):
       1. KYC-BE-01..04 (migrations + admin_flags model)
       2. KYC-BE-05/06/07/08 (create-session, status, webhook+HMAC, handlers)
       3. KYC-BE-09/10 (skip logic + gates + polling fallback)
       4. KYC-MOB-01..05 (Flutter gates) + KYC-WEB-01..04 (web) + KYC-ADM-01
  → In parallel, Sumit does KYC-SETUP-01..05 in the Didit Console so KYC-QA-* can run.

Then, lower-priority code-only tasks while waiting on client (EMAIL-01, PAY-01):
  - MOB-FEAT-08 (state/country dropdowns — data-quality fix)
  - CLEAN-02 (Cluster B legacy cleanup — needs device verification after)
  - WEB-QA P1/P2 sprint
  - RDY-06 (keep-alive monitor — 5-min ops win)

Client unblocked you →
  EMAIL-02/03 if Brevo/Resend keys arrived
  PAY-03 if live Razorpay keys arrived
  KYC-QA-01..04 once Didit creds + test device are ready
  Then RDY-09 hard cutover checklist
```
