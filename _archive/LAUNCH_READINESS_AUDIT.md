# AajooHomes — Launch-Readiness Audit (real-data wiring)

> **Author:** Senior architect + tester pass · **Date:** 2026-06-12
> **Goal:** map every feature to real APIs, find all bugs / broken / unwired / mock pieces before go-live (mock data is being deleted).
> **Method:** static audit of `src/` (frontend) + `aajooBackend-2026/` (backend) + live smoke (FMS 27/27, HMS 24/24 verified on prod).

---

## 0 · Executive summary

| Layer | State | Verdict |
|---|---|---|
| **Backend API** (`aajaodev.onrender.com`) | 60+ endpoints live; FMS/HMS/KYC/RBAC/notifications deployed + smoke-verified with real data | ✅ Production-ready |
| **Admin dashboard** (`/admin/*`) | Login fixed; FMS + HMS panes return real data (27/27 + 24/24) | ✅ Working |
| **Host portal** (`/host/*`) | All 8 pages wired to real endpoints, verified | ✅ Working |
| **Customer website** (`/`, `/property/*`, `/user/*`) | **Redesigned UI shell running on hardcoded/mock data — almost nothing calls the backend** | 🔴 **This is the delivery gap** |
| **Payments / booking flow** | Razorpay opens client-side with hardcoded amount + no order creation + **no signature verification**; no booking persisted | 🔴 **P0 — money + data integrity** |

**The headline:** the backend and the admin/host apps are done. The **customer-facing site is the work.** Of ~40 customer files, **only 4 call any API** (`BecomeHost`, `SubmitReview`, `VerifyComplete`, `VerifyButton`). Everything a guest sees — home, search, listings, property detail, booking, payment, their bookings, profile, transactions — is static placeholder data. The good news: the backend endpoints these pages need **already exist** (see § 6). This is wiring, not new backend build.

---

## 1 · 🔴 P0 — Blocks launch (money, data integrity, security)

| # | Finding | File(s) | Fix → endpoint |
|---|---|---|---|
| P0-1 | **Payment is not verified.** `RazorpayPayment` opens checkout with `amount` from props, hardcoded `booking_id: "BOOKING123"`, fake prefill (`Guest User` / `guest@example.com` / `9999999999`). On success it just calls `onSuccess(response)` — **no server order, no signature check.** Anyone can fake a success. | `src/components/frontend/RazorpayPayment.tsx` | 1) `POST /booking/create` → returns Razorpay `order_id` + amount. 2) Open Razorpay with that `order_id`. 3) On handler → `POST /create/payment-verify` (HMAC signature). Only mark booked if verify passes. |
| P0-2 | **No booking is persisted.** `FinalBookingPage` bill-calc is commented out (`// fetch("/api/calculate-bill")`); "Confirm" just `navigate("/booking/confirmation")` with no API call. So a "booking" creates nothing in the DB. | `src/pages/user/FinalBookingPage.tsx` | Wire the create→pay→verify chain above; compute totals from the real property + dates (or a pricing endpoint). |
| P0-3 | **Razorpay prefill uses fake identity** (name/email/phone hardcoded). For live payments this must be the logged-in user. | `RazorpayPayment.tsx` | Pass real `user` (from `/user/detail` / session) into prefill. |
| P0-4 | **Demo/seed data must be purged before launch.** `scripts/seedFmsHmsDemo.js` inserted `SEED_DEMO`-tagged rows into the prod DB during testing. | backend DB | Run `node scripts/seedFmsHmsDemo.js --clean` before go-live. |
| P0-5 | **Dev bypasses still active** (signup doc-upload optional, OTP `000000`/`0000` master, `OTP_DEV_BYPASS`). Must revert before public launch. | `controllers/user.controller.js`, `schema/user.schema.js`, Render env | Revert per `TASK_TRACKER.md § DEV-BYPASS`; set `OTP_DEV_BYPASS=false` once Brevo email is live. |

---

## 2 · 🟠 P1 — Core customer features on mock data (no API wiring)

Every row below is a **redesigned page that renders hardcoded data** and must be wired to the (already-existing) backend endpoint.

| # | Page / component | Current | Fix → endpoint |
|---|---|---|---|
| P1-1 | **Property listing** — 12 dummy Goa properties from `buildProperties()` | static | `POST /properties/search` (filters: location, category, guests, price, map bounds) — replace `buildProperties()` with a fetch + loading/empty states |
| P1-2 | **Property detail** — static content | static | `GET /properties/:propId` + `POST /properties/reviews/list` + save/like buttons |
| P1-3 | **Home — Featured properties** | hardcoded arrays in `FeaturedProperties.tsx` | `POST /properties/list` (featured/recent slice) |
| P1-4 | **Home map + nearby** — `dummyHotels` array, `setTimeout` fake load | `MapandFilter.tsx` | `POST /properties/search` by current map bounds/location |
| P1-5 | **My Bookings** — static | `UserBookings.tsx` | `GET /user/booking-history` |
| P1-6 | **Ongoing booking** — static | `userOngoingBooking.tsx` | `POST /user/ongoing/bookings` |
| P1-7 | **User profile** — static | `UserProfile.tsx` | `GET /user/detail`, `POST /user/update`, `POST /user/add/profile-pic`, `POST /user/delete/profile-pic` |
| P1-8 | **User transactions** — static | `UserTransactions.tsx` | derive from `GET /user/booking-history` / payments (confirm a transactions endpoint or build one) |
| P1-9 | **User dashboard** — static | `dashboard.tsx` | summary from booking-history + saved + profile |
| P1-10 | **Saved / liked properties** — buttons not wired | listing/detail cards | `POST /properties/user-saveProp` / `user-likeProp` / `user-dislikeProp`; list via `POST /user/saved-properties` |
| P1-11 | **Cancel booking** — UI only | `CancelBookResult.tsx` / bookings | `POST /user/cancel/booking` |
| P1-12 | **Customer notifications dropdown** — static | `NotificationDropdown.tsx` | `GET /user/notification/Listing` + `POST /user/notification/mark-read` |
| P1-13 | **Search → results** — search bar navigates with params, but listing doesn't fetch by them | `PropertyListing.tsx` | once P1-1 is wired, apply `location`/`category`/`guests` query params to the search request |

---

## 3 · 🟡 P1 — Auth & account flows to verify/wire

| # | Finding | File | Action |
|---|---|---|---|
| P1-14 | **User login/signup forms** — confirm wired to `/user/login`, `/user/signup`, `/user/verify-otp` (host login via `/user/login` works; verify the customer auth forms post correctly + handle response/redirect). | `src/auth/*`, `src/pages/admin/adminLogin` (admin done) | Verify + fix any response-shape parsing like the admin-login `data.admin.token` bug (P0 we already fixed). |
| P1-15 | **Forgot-password (public)** — INT-12: ensure the logged-out flow calls the **public** endpoint, not the auth-gated one. | auth forms | Confirm `POST /user/forget-password` (+ verify-otp + update) path works when logged out. |
| P1-16 | **KYC gates** — VerifyButton/VerifyComplete are wired; confirm the host property-submit + guest checkout actually **block** until verified once Didit creds are live. | `kyc/*`, checkout | Functional test after `DIDIT_*` env set. |

---

## 4 · 🟢 P2 — Content, polish, and secondary

| # | Finding | File | Action |
|---|---|---|---|
| P2-1 | Static content pages (About / Contact / FAQ / Help / Terms / Privacy / State Regulation) | `src/pages/user/*` | Decide: keep static, or wire to CMS endpoints (`/common/about-us`, CMS sections, T&C, FAQ all exist). Low priority. |
| P2-2 | **Contact Us form** — no submit target | `ContactUs.tsx` | Needs a contact/lead endpoint (none exists) — build or route to support tickets. |
| P2-3 | **SEO `og:image`/`og:url` relative** — social previews need absolute URLs | `index.html` | Set to `https://www.aajoohomes.com/aajoo-logo.png`; add a 1200×630 banner. (Title/description/favicon already fixed.) |
| P2-4 | **Cold-start (~30s)** on Render free tier — first admin login/search is slow | infra | Keep-alive monitor (RDY-06): cron-job.org ping `/health` every 10 min. Do before client demo. |
| P2-5 | `console.log(address)` and similar dev logs in customer components | `MapandFilter.tsx` etc. | Remove stray logs. |
| P2-6 | Perf index `idx_book_host_status_date` skipped on a transient error during migrate | DB | Re-add via a one-off (optional; perf only). |

---

## 5 · 🔵 Backend / infra / go-live switches (mostly ready, need creds)

| # | Item | Status |
|---|---|---|
| B-1 | `/admin/verify-token` | ✅ implemented + deployed (was the login blocker) |
| B-2 | Brevo email (`BREVO_API_KEY`, `MAIL_FROM`) → real OTP | ⏭️ code ready; needs creds + `OTP_DEV_BYPASS=false` |
| B-3 | Razorpay **live** keys (`RAZORPAY_KEY_ID/SECRET`, FE `VITE_RAZORPAY_KEY`) | ⏭️ needs live keys |
| B-4 | Didit KYC (`DIDIT_*` + webhook registration) | ⏭️ needs console creds |
| B-5 | CORS hardening — backend currently `origin: true` (all origins) | ⏭️ tighten to `FRONTEND_URL=https://www.aajoohomes.com` (INT-13) |
| B-6 | API base URL | ✅ FE points to prod (`apiConfigs.ts`/`apis.ts`/`axios.ts`) |

---

## 6 · Backend endpoints already available for the customer wiring

(So FE work is connecting, not building.)

```
Properties:  POST /properties/search · POST /properties/list · GET /properties/:propId
             POST /properties/reviews/list
             POST /properties/user-saveProp | user-likeProp | user-dislikeProp
Booking:     POST /booking/create · POST /create/payment-verify
             POST /user/ongoing/bookings · POST /user/ongoing/bookings/payment/create
             POST /user/cancel/booking · GET /user/booking-history
User:        GET /user/detail · POST /user/update · add/delete profile-pic
             POST /user/saved-properties · POST /user/history · POST /user/review-add
             GET /user/notification/Listing · POST /user/notification/mark-read
Auth:        /user/signup · /user/login · /user/verify-otp · /user/otp-again
             /user/forget-password · /user/forget/verify-otp · /user/update/forget-password
Common:      GET /common/states · country · amenties · documents/list · safety · about-us
```

---

## 7 · Recommended fix sequence

**Phase 1 — the money path (P0, do first):**
1. P0-1/P0-2/P0-3 — wire `RazorpayPayment` + `FinalBookingPage` to `/booking/create` → Razorpay(order) → `/create/payment-verify`, real user prefill. **Nothing else matters if a guest can't actually book + pay.**

**Phase 2 — the browse → book funnel (P1):**
2. P1-1 Property listing → `/properties/search`
3. P1-2 Property detail → `/properties/:propId` + reviews
4. P1-3/P1-4 Home featured + map → `/properties/list` / search
5. P1-13 search params applied to the search request

**Phase 3 — the account area (P1):**
6. P1-5..P1-12 — bookings, ongoing, profile, transactions, dashboard, saved/liked, cancel, notifications

**Phase 4 — auth verification + content (P1/P2):**
7. P1-14/15/16 auth + forgot-password + KYC gate functional tests
8. P2-1/P2-2 content pages + contact form

**Phase 5 — go-live switches (ops + creds):**
9. B-2..B-5 env vars (Brevo, Razorpay live, Didit, CORS)
10. P0-4 purge seed data · P0-5 revert dev bypasses · P2-4 keep-alive

**Pre-launch gate:** a clean E2E as a real guest — signup → verify → search → property detail → book → pay (real Razorpay) → see it in My Bookings; and as host → see the booking + earnings; and as admin → see it in FMS ledger.

---

## 8 · How to verify as we fix (per page)

For each wired page, the acceptance is the same shape we used for admin/host:
- Network tab: the call goes to `https://aajaodev.onrender.com/...` and returns 200 with real data (not localhost, no CORS error).
- Loading + empty + error states present (no blank screen on slow/failed fetch).
- No console errors.
- The data shown matches the DB.

I can drive each of these in the headless browser as we go (same as the admin-login verification).

---

*This audit is the work list to take AajooHomes from "beautiful shell + working backend" to "fully wired, real-data product." The backend is done; the customer frontend is the remaining build. Start at Phase 1 (the money path).*
