# AAJOO Homes — Work Delivered To Date

**Prepared by:** Zyphex Technologies · **For:** AAJOO Homes Pvt. Ltd.
**Date:** 14 June 2026
**Repos covered:** Base codebase (shared) — Website (customer + admin + host portals), Backend (Node/Express + MySQL), Mobile app (Flutter)

> **Purpose:** A complete record of everything built on the AAJOO base codebase, with an honest estimate of how long each workstream **normally** takes to build (effort in person-days at a sustainable pace). This is the "value already delivered" view for the meeting.

---

## 0 · One-line summary

We have taken a partially-built, mock-data codebase and turned the **entire customer website + admin + host portals + shared backend** into a real, deployed, data-driven product — live at **https://www.aajoohomes.com** (frontend, Vercel) and **https://aajaodev.onrender.com** (backend, Render).

**Normal effort represented by the work below: ≈ 13–16 person-weeks.**
This was compressed into the ~3.5-week window after the codebase was received (see Doc 3).

---

## 1 · Website — Customer site (guest-facing)

| Workstream | What was delivered | Normal effort |
|---|---|---|
| **Sand & Indigo design system (web)** | Full visual redesign — typography (Fraunces/Inter), colour system, components, hero, cards, animations — applied across the customer site | 8–10 days |
| **Home page** | Live featured properties (geolocation search), interactive search bar (Where/Type/Guests), real category chips from backend, map with property pins, "Explore North India" destinations, "Places to visit", reviews with ratings, mobile + desktop layouts | 5–6 days |
| **Property Listing** | Wired to real `/properties/search`, map ↔ card sync, "search as I move", real category filter, **searches the clicked city** (geocoded), location-aware map | 4–5 days |
| **Property Detail** | Wired to real `/properties/:id`, image gallery + full-screen slider, real amenities, **real host profile** ("Meet your host"), guest reviews, booking box, map, "places nearby" | 4–5 days |
| **Booking & Checkout** | Real price/guests/nights through checkout, "attractive & classic" redesign, image slider, Razorpay checkout wiring (test), booking-confirmation flow | 3–4 days |
| **Account area** | My Bookings, Ongoing bookings (+ in-app directions, WhatsApp host chat, context-aware Pay/Check-out/Cancel wired to backend), Profile (controlled form + prefill + update), Transactions, Dashboard, Saved/liked, Notifications | 5–6 days |
| **Auth & onboarding** | Multi-step signup wired to backend + OTP verification, login, location autofill, real State + dependent City dropdowns, digits-only phone, themed calendar, validation UX | 4–5 days |
| **Content/marketing pages** | About, Contact, FAQ, Help Center, Privacy, Terms, State Regulation, Why-Host, Become-a-Host — all redesigned in-theme with icons/animations | 4–5 days |
| **Shared UI** | Reusable themed date picker, reveal animations, in-app directions modal, header/footer brand, responsive passes | 3 days |

**Customer site subtotal: ≈ 40–49 person-days (~8–10 weeks).**

---

## 2 · Website — Admin portal

| Workstream | What was delivered | Normal effort |
|---|---|---|
| **Admin core** | CRUD, dashboard, authentication (fixed token/session validation bug) | 4–5 days |
| **Finance Management System (FMS) — frontend** | 15 finance pages/panes wired to real data (ledgers, payouts, invoices, reports, reconciliation views) | 6–7 days |
| **Settings** | Platform / notifications / security / integrations sections | 2–3 days |
| **Notification center** | Typed notification list, read/unread, category chips, empty/error states, backend polling wired | 2 days |
| **Host management (admin side)** | Host list + detail + KYC review + performance + payout panes | 4–5 days |

**Admin subtotal: ≈ 18–22 person-days (~3.5–4.5 weeks).**

---

## 3 · Website — Host portal (HMS)

| Workstream | What was delivered | Normal effort |
|---|---|---|
| **Host portal foundation** | Host dashboard, bookings, profile & payout account, performance, communication panes wired to real endpoints | 5–6 days |
| **Become-a-Host onboarding** | Multi-step host onboarding form (host + property + verification) with validation, location autofill, state/city dropdowns | 3 days |

**Host portal subtotal: ≈ 8–9 person-days (~1.5–2 weeks).**

---

## 4 · Backend (shared — Node/Express + MySQL on Render)

| Workstream | What was delivered | Normal effort |
|---|---|---|
| **FMS backend** | 27 finance endpoints (ledger reads, payouts, invoices, reports, reconciliation views) + smoke/integration runners | 6–8 days |
| **HMS backend** | Host endpoints (bookings, profile, payout account, performance summary, onboarding), public host-profile endpoint, admin host/KYC panes | 5–6 days |
| **KYC (Didit)** | Didit KYC backend + HMAC webhook integration | 2–3 days |
| **Auth / RBAC** | Admin `verify-token` endpoint, role handling, login/session fixes, signup + OTP (Brevo email) | 3–4 days |
| **Notifications** | Notification listing + mark-read endpoints (polling model) | 1–2 days |
| **DB & migrations** | 14 sprint migrations on the live Clever Cloud DB, sequelize-cli baselining of 62 pre-existing migrations, schema alignment (pluralization, freezeTableName, information_schema KYC checks) | 3–4 days |
| **Deploy & smoke** | Render deployment, deep authenticated smoke (FMS 27/27 + HMS 24/24 returning real data) | 2 days |
| **Image pipeline** | Cloudinary property-image enrichment pipeline | 1–2 days |

**Backend subtotal: ≈ 23–31 person-days (~4.5–6 weeks).**

---

## 5 · Mobile app (Flutter — base codebase)

| Workstream | What was delivered | Normal effort |
|---|---|---|
| **App ↔ backend integration** | Auth/signup/KYC wiring against the shared backend, doc-type/signup fixes, host-signup role fix | 3–4 days |
| **Stabilisation** | Several auth/KYC crash + null-safety fixes to make the app runnable for testing | 2 days |

**Mobile subtotal: ≈ 5–6 person-days (~1–1.5 weeks).**
> Mobile Sand & Indigo manual passes, KYC gates, and on-device QA are **pending** (see Doc 2).

---

## 6 · Cross-cutting (QA, integration, docs)

| Workstream | What was delivered | Normal effort |
|---|---|---|
| **Backend↔frontend integration audit** | 13 wiring gaps (INT-01..13) identified + resolutions locked in API contract | 2 days |
| **Live QA & bug-fixing** | Pre-launch audits, critical bug fixes (admin login P0, home search P0, infinite-refresh-loop P0, 3 silent API-helper bugs, listing-location bug, etc.) | 4–5 days |
| **Documentation** | API contract handoff, delivery plan, task trackers, smoke-test reference, release/handoff docs | 2–3 days |

**Cross-cutting subtotal: ≈ 8–10 person-days (~1.5–2 weeks).**

---

## 7 · Grand total — normal effort represented

| Area | Normal effort (person-days) |
|---|---|
| Customer site | 40–49 |
| Admin portal | 18–22 |
| Host portal | 8–9 |
| Backend | 23–31 |
| Mobile | 5–6 |
| Cross-cutting | 8–10 |
| **Total** | **≈ 102–127 person-days** |

**≈ 13–16 person-weeks of normal-paced engineering** has been delivered on the base codebase.

> Key point for the meeting: this volume of work was executed in the **~3.5-week window** after the codebase was actually received (20–21 May → 15 June). The only way that was possible was sustained parallel execution and heavy compression — which is exactly the load discussed in Doc 3.

---

*Live: https://www.aajoohomes.com (frontend) · https://aajaodev.onrender.com (backend). Smoke-verified: FMS 27/27, HMS 24/24 endpoints returning real data.*
