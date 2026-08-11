# AajooHomes — Session Handoff (2026-06-24)

> Continue here in a new session. Big bug-fix + polish sprint done; **next major work = the full Host-Onboarding wizard (per doc) + DIDIT + BotPenguin setup.**

---

## 0 · Topology / accounts / deploy
- **3 repos:** FE `D:/Projects/aajao-frontend-vercel` (→ Vercel) · BE `D:/Projects/aajaoBackend-render` (→ Render) · monorepo/docs `D:/Projects/ajoo admin website`.
- **Push to `main` auto-deploys.** FE GitHub: `nameeshPatiyal100/Aajao-Admin-WebSIite`. BE GitHub: `nameeshPatiyal100/aajaoBackend`. Live: `https://aajoohomes.com` (web) + `https://aajaodev.onrender.com` (API).
- **DB:** Clever Cloud MySQL (shared), reachable from sandbox via `node` in the BE repo (`require("./models")`).
- **Test accounts:** Admin `admin@mailinator.com / Admin@123` (lives in `tbl_admins`) · Host1 `aajoo.host1@mailinator.com / Host@12345` (user_id **100**) · Renter1 `aajoo.renter1@mailinator.com / Renter@12345` (user_id **101**).
- **Test mode:** OTP `000000` · **Razorpay payment = UPI `success@razorpay`** (cards like 4111… are rejected as "international" on this test account) · KYC bypassed until DIDIT live.
- **Commit msgs end with:** `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`. Commit/push only when asked (user has been asking each time).

---

## 1 · DB state (after this session)
- Earlier this session I ran a **full fresh-start wipe** (`BE/scripts/freshStartClean.js`, JSON backup in `BE/backups/pre-clean-*`, git-ignored). Then the user ran a live UAT: host created **property #1 "Test property"** (Gurgaon, ₹3000, categories party+Apartment+couple), renter made **1 paid booking `B212765`** (₹12,600 total = ₹12,000 + 5% GST).
- Current live data: **1 property**, **1 paid booking** (+ 1 abandoned booking `B847763` soft-deleted), **users trimmed to 100 + 101** (+ admin in tbl_admins).
- Ledger from that booking: GUEST_PAYMENT 12600, PLATFORM_COMMISSION 1800, HOST_EARNING 9876, TAX_COLLECTED 600 (all CREDIT). 1 QUEUED payout ₹9,876. 1 invoice AAJOO-INV-202606-0001.
- **Amenities seeded to ~39** (admin-managed); junk ("GT Road","add update") soft-deleted.

---

## 2 · What was fixed/built THIS session (all pushed)

### Frontend commits (newest→older)
- `e3202d5` finance: invoice **detail** normalize (was ₹0/Invalid Date — slice now runs `normalizeInvoice`) + **invoice download** = client-side printable GST PDF + **payouts** "Invalid Date" → safe range/"Immediate".
- `6801328` **tags**: badges on listing/home cards + property detail; home "Featured" prefers `featured`-tagged stays; **host form tag selector** (`/common/tags`, posts `property_tag[]`).
- `e3d0d55` **reviews**: admin Property Reviews was 100% faker → real API (`/admin/property/review/search` + `/update`). **Host amenities** now load from admin-managed DB (`/common/amenties`) with countable-qty steppers.
- `e0f6784` admin dashboard hero: fixed-height banner → `minHeight` (Pending-Properties card no longer overflows gradient).
- `0bc3542` premium motion across listing cards (stagger+hover zoom) / property detail (reveals + hero zoom) / dashboards (**CountUp** KPI) + **Luxe color fix** (page stays cream; dark-gold banner only).
- `c6481af` **Luxe cinematic** (`LuxeIntro.tsx` black-gold reveal) wired to "Luxury Homes" → `/property/list?luxury=1` (luxe banner + filter to `is_luxury`); enhanced `Reveal` (variants + `RevealStagger/RevealItem`); hero mount entrance.
- `9b91cda` **RBAC**: each role confined to own dashboard. New `RenterRoute` wraps `/user-dashboard`; `HostRoute` host-only; `sessionRole()` resolver in `authGaurd.tsx` (host has BOTH tokens; check before renter).
- `aa7ed07` host bookings dates "Invalid Date" → DD-MM-YYYY-aware formatter.
- `e395989` host bookings slice read `items` (backend key) + statements Net (= host earning) + statement **download** (client-side PDF).
- `c7184af` host bookings render (numeric `booking_id` + `booking_code`).
- `ce0dd76` finance Revenue/Tax/CashFlow report slices normalized (Tax read gst*/CashFlow read total*/netFlow but backend sends taxCollected/inflow/net → showed ₹0).
- `f731260` commission report blanked whole admin shell (`row.rate.toFixed` on undefined; no error boundary) → slice normalizes + coerces numbers.
- `84570a5` listing category filter matches **any** of a property's categories (was first only).
- `d00923b` Total Spent counts only **paid** bookings (book_is_paid) using book_total_amt.
- `7731399` renter Booking-details modal was hardcoded mock (John Doe…) → real data + working invoice; modernized renter dashboard (welcome banner, clickable stats, recent bookings, quick actions).
- `dceeb34` property-detail booking card `position:fixed`+JS hack → real `position:sticky` two-column (no overlap); per-property amenities JSON.

### Backend commits (newest→older)
- `2697609` **cash-flow** stopped double-counting (every ledger row is CREDIT; summed guest+commission+host+tax = 24,876). Now inflow=GUEST_PAYMENT, outflow=HOST_EARNING → net = retained margin (₹2,724).
- `b4dedf5` **`/common/amenties`** filtered `amn_isDelete=isYes` (deleted!) → returned junk. Now `isNo`.
- `55dd136` admin **monthly-bookings** chart only counted status 13 → now counts success set `[3,5,6,7,8,9,10,13]`.
- `2f48532` host dashboard **occupancy** was hardcoded 0 → booked-nights ÷ (days-in-month × listings) parsing DD-MM-YYYY (=13%).
- `75d2674` host **earnings totals/payoutHistory** + **performance** revenue.trend (zero-filled 6-mo) + channelSplit.
- `9a7e710` host **bookings.search** returned raw rows → now joined/shaped (booking_id/property/guest/dates/status), excludes soft-deleted+abandoned.
- `7e52e22` + `152d09c` hide **abandoned online-unpaid** bookings (cod=0 & is_paid=0) from renter Bookings + Ongoing; `userBookingList` returns is_paid/total_amt.
- `35e32cc` `property_amenities_json` column (migration `20260623120001`) + addProperty stores it.
- `908a6c0` BE scripts (inspectState, freshStartClean).

### Key gotchas discovered (also in memory)
- Booking dates stored **DD-MM-YYYY**; `new Date()` can't parse → format explicitly.
- Finance report endpoints return `{items,totals}` with backend-specific names → **normalize in the slice**; admin pages have **no error boundary** (an undefined `.toFixed()` blanks the whole shell).
- Invoice/ledger/payout responses use **raw `inv_*`/`fl_*`/`po_*` columns**; `financeContracts.ts` normalizers read raw first — apply them everywhere (the detail slice didn't).
- Host session stores **both** customer + admin tokens (role `host`); admin = admin token only; renter = customer token only. `sessionRole()` checks host before renter.
- `amn_title` column max **20 chars**.
- After TRUNCATE, auto-increment reset → host's first property is `property_id=1`.

---

## 3 · NEXT MAJOR WORK — Host Onboarding wizard + DIDIT + BotPenguin

Two repo docs were reviewed and a plan written:
- **`LIST PROPERTY TYPE & CATEGORY.pdf`** = the updated **Host onboarding/listing form** (13 sections + state-wise legal layer).
- **`aajoo chat support flow updated.pdf`** = a **BotPenguin** support bot (Guest+Host flows, WhatsApp/Web/App).
- Plan doc: **`HOST_ONBOARDING_AND_CHATBOT_PLAN.md`**. DIDIT setup guide: **`DIDIT_WORKFLOW_SETUP_GUIDE.md`**.

### USER DECISIONS (locked)
1. **Form scope = FULL doc now** (all 13 sections + state-wise legal flow HP/Punjab/Chandigarh/Haryana + PG mode + party/group settings + verification tiers + audit logging).
2. **BotPenguin** — user has the platform login but needs me to **guide them click-by-click to build the flows per the doc** + I do the API/widget code.
3. **DIDIT** — user has login but needs me to **guide them to create the host + renter workflows** (guide already written) + I wire the host KYC step.

### Already-built backend scaffolding (big de-risker)
- **DIDIT fully wired:** `config/kyc.config.js` (env-driven, needs `DIDIT_API_KEY`/`DIDIT_WEBHOOK_SECRET`/`DIDIT_HOST_WORKFLOW_ID`/`DIDIT_GUEST_WORKFLOW_ID`), `utils/diditClient.js`, webhook `POST /webhooks/didit`, admin `/admin/host/kyc/detail|approve|reject`. FE: `components/frontend/kyc/VerifyButton.tsx` (guest KYC already wired at `UserCheckoutPage`), `VerifyComplete`, `HostProfile` KYC.
- **BotPenguin API surface exists:** `routes/chatbot.routes.js` → `/bp/session/start`, `/bp/document/invoice` (bpController).

### Planned build order (Workstream #2 — the codebase, me)
1. **Backend schema slice** — add `tbl_properties` cols: property_type(6), category Standard/LUX, booking_pref(instant/pre), area_locality, landmark, floor_no, bathrooms, security_deposit, weekend_price, extra_guest_charge, cleaning_fee, min_booking_amount, video_url, couple_friendly, local_id_allowed, quiet_hours, ownership_type, verification_status(verified/partial/unverified). New `tbl_property_documents` (doc_type/file/status) + PG fields (table or JSON) + party/group fields. **Flip `addProperty` to PENDING** (`is_verify=0`) — *currently it goes live immediately; user confirmed it should be Pending→admin-approval.*
2. **Frontend wizard** — rebuild `HostAddProperty.tsx` into a multi-step stepper covering all 13 sections + conditional **PG mode** + **state-wise legal** doc uploads (HP tourism reg, Chandigarh rental-approval Q, Haryana RWA for Gurgaon/Faridabad, Punjab flexible).
3. **Host DIDIT KYC step** (reuse VerifyButton w/ `host_kyc` context) + the **8 UI states** (not verified / in progress / submitted / approved / declined+retry / in review / already-verified / expired).
4. **Admin Property Verification** page (currently empty) — list Pending, view docs + KYC result, **Approve/Reject** → flips `is_verify` / verification_status (goes live). Endpoints exist.

### Workstream #3 (BotPenguin) — after form
- Verify/extend `/bp/*` APIs vs the doc's services (gaps: SUPPORT_SERVICE create/status, PAYMENT refund-status, guest invoice fetch, recommendations).
- Embed BotPenguin **widget** on the site.
- Write a **BotPenguin click-by-click build guide** for the user to construct every flow.

### ▶️ Immediate next steps
- **User (parallel):** do `DIDIT_WORKFLOW_SETUP_GUIDE.md` (create 2 workflows, set 4 env vars + webhook URL on Render).
- **Me (next session):** start the **backend schema slice** for the host wizard (pending I confirmed the user is OK with listings becoming **Pending** instead of instant-live — they said full doc, which implies Pending Admin Approval). Then the wizard, KYC step, admin verification page.

### Other still-pending (P4, mostly client-cred-blocked — NOT for test mode)
- Revert dev-bypasses (OTP/doc-verify) at real go-live; Cloudinary media; Brevo email; Razorpay live keys; DIDIT live cutover; CORS/API base hardening; mobile app parity + Play Store. Confirm GST rate with client.
