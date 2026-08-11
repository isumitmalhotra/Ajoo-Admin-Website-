
# Post-25-Release — Prioritized Execution Plan (Backend · Admin · Host · Renter)

> **Source:** `_Web App Bugs (1).xlsx` → sheet **"Post 25 release"** (rows 1–493, 49 reference screenshots in [`post25_images/`](post25_images/)). Raw, ungrouped extraction lives in [`POST_25_RELEASE_TASKLIST.md`](POST_25_RELEASE_TASKLIST.md).
>
> **This doc** re-analyzes every task and keeps only the ones in our current priority lanes — **Backend, Admin Dashboard, Host Dashboard, Renter Dashboard** — plus the renter-facing **Property Detail / Booking** functional items. Pure marketing-site UI, cosmetic redesigns, and "content provided by us" items are listed under **§7 Parked** so nothing is lost, but they are out of scope for this pass.
>
> **Repos:** FE = `D:/Projects/aajao-frontend-vercel` (React/Vite — customer + admin + host portals). BE = `D:/Projects/aajaoBackend-render` (Node/Express + Sequelize/MySQL → `aajaodev.onrender.com`). File pointers below are directional — verify before editing.
>
> **Legend:** **P0** blocker · **P1** important · **P2** minor/config · 🔒 blocked on client input · 🔁 needs FE+BE · 🖼️ screenshot in raw doc.

---

## 0. Summary

| Lane | P0 | P1 | P2 | Total | Notes |
|------|----|----|----|-------|-------|
| Backend | 3 | 6 | 2 | 11 | Double-booking + notifications + sockets are the risky ones |
| Admin Dashboard | 0 | 3 | 1 | 4 | Add-property form + move BotPenguin out |
| Host Dashboard | 4 | 10 | 3 | 17 | Listing wizard, KYC flow, edit/list/ongoing pages |
| Renter Dashboard | 2 | 6 | 1 | 9 | Profile pic, geolocation, nav cleanup, filters |
| Property Detail / Booking | 1 | 8 | 0 | 9 | Double-booking guard is the P0 here too |
| **In-scope total** | **10** | **33** | **7** | **50** | |
| Parked (marketing UI / content) | — | — | — | ~55 | §7 |

**Do-first shortlist (P0):** BE-1 double-booking guard · BE-2 host dashboard on real data · HOST-1 property submit bug · HOST-2 property edit · HOST-3 ongoing page · HOST-4 host property list · RENT-1 profile-picture update · BOOK-1 booking dynamic data.

---

## 1. Backend

| ID | Task (cleaned) | Analysis / Action | Area | Pri |
|----|----------------|-------------------|------|-----|
| **BE-1** | **Double-booking not prevented** ("haven't seen double-booking functionality built/working") — *Critical* | Add an overlap check before confirming a booking: reject if an active booking exists for the same `property_id` with date-range overlap. Enforce in `booking.controller.js` (create/verify) with a transaction + row lock, not just FE. Add availability lookup used by the calendar. | BE `controllers/booking.controller.js`, `models/tbl_bookings`/`tbl_book_details` | **P0** |
| **BE-2** | **Host dashboard not dynamic** — "make things work on real data so we can test in single flow" 🔁 | Audit every host-dashboard widget; replace stubs/mock with real endpoints (earnings, transactions, ongoing, listings). Pair with HOST-* items. | BE host endpoints + FE host portal | **P0** |
| **BE-3** | **No notifications generated** | Notifications aren't being created on booking/payment/status events. Verify `tbl_notifications` writes fire in the relevant controllers + push (FCM) path; confirm `/notifications` list returns them. | BE `controllers/notifications.controller.js`, booking/payment controllers | P1 |
| **BE-4** | **Socket messaging not working** ("haven't seen sockets messaging work") | Verify `socketController.js` connects, auth handshake, room join, and message persist to `tbl_messages`/`tbl_nagotiate_messages`. Test negotiation chat end-to-end. | BE `controllers/socketController.js` | P1 |
| **BE-5** | **Invoice PDF download** — add download icon in Transaction listing 🔁 | Add/verify an endpoint that returns an invoice PDF for a payment/booking; wire the FE download icon to it. | BE invoice/payout + `tbl_invoices`; FE transaction page | P1 |
| **BE-6** | **Category list in DB + expose to forms** 🔒 | Seed the real category list (awaiting client list — see CLIENT_INPUTS) into `tbl_categories`; ensure the category API returns all active categories for host/admin forms. | BE `tbl_categories`, propCategory controller | P1 |
| **BE-7** | **Google sign-in not working** ("firebase connection") 🔁 | Backend token verification / Firebase config for Google OAuth. Confirm client_id/secret + verify-token endpoint. | BE auth (`user.controller.js`), FE auth page | P1 |
| **BE-8** | **Phone-number signup missing in flow** 🔁 | Add phone/OTP signup path (first step by email *or* mobile). Confirm OTP send/verify endpoints exist and are wired. | BE user/OTP controllers, FE signup | P1 |
| **BE-9** | **Field & validation audit across platform** | Server-side validation (schema) parity with FE; return field-level errors so FE can show inline (see HOST-14). | BE `schema/*`, `middleware/validation.js` | P1 |
| **BE-10** | **BotPenguin: inbox auto-opens; not part of admin** | Config: stop auto-open of the support inbox; ensure BotPenguin widget is scoped (renter only, not admin). Mostly embed/config, minor BE. | FE embed config + BE `bp_controller.js` | P2 |
| **BE-11** | **Verify KYC auto-verify write-back** (host+renter) 🔁 | On DIDIT completion, backend must persist `verification_status='verified'` so FE can show "Verified" and hide upload. Confirm `/webhooks/didit` + `/admin/host/kyc/*`. | BE `verify.controller.js`, didit webhook | P1 |

---

## 2. Admin Dashboard

| ID | Task | Analysis / Action | Area | Pri |
|----|------|-------------------|------|-----|
| **ADM-1** | **Add "Add Property" form in Admin** (same as host add-property document spec) 🔁 | Build the admin-side add-property form matching the `LIST PROPERTY TYPE & CATEGORY.pdf` spec; reuse the host wizard fields + backend addProperty. | FE admin portal, BE `property.controller.js` addProperty | P1 |
| **ADM-2** | **Remove BotPenguin from admin dashboard** | BotPenguin/support widget should not render in admin. | FE admin layout | P1 |
| **ADM-3** | **Category management surfaces full list** 🔒 | Admin category CRUD reflects the seeded list (ties to BE-6); ensure forms across app read from it. | FE admin categories, BE | P1 |
| **ADM-4** | **Premium icon set across platform** (incl. admin) | Swap category/amenity/nav icons for a consistent premium set. Cross-cutting; do once, applies to admin+host+renter. | FE shared icon set | P2 |

---

## 3. Host Dashboard

| ID | Task | Analysis / Action | Area | Pri |
|----|------|-------------------|------|-----|
| **HOST-1** | **Property is not submitted** (add-property submit fails) 🖼️🔁 | Reproduce the submit failure; likely a payload/validation/multipart mismatch between the wizard and `addProperty`. Fix so submission creates the property (→ Pending) reliably. | FE host add-property, BE addProperty | **P0** |
| **HOST-2** | **Property edit not available anywhere in dashboard** 🔁 | Add edit flow: load property into the form, PATCH via update path (addProperty already supports `propertyId` update). | FE host portal, BE update property | **P0** |
| **HOST-3** | **Ongoing page missing on host side** | Add the host "ongoing bookings" page (data exists via `/booking/ongoing-host`). Note: that endpoint returns `data:[]` when empty and the mobile parser chokes — guard for empty list. | FE host portal, BE ongoing-host | **P0** |
| **HOST-4** | **Host property list missing** | Add the host's "my listings" page (data via host property-search). | FE host portal | **P0** |
| **HOST-5** | **Listing basics shown as plain list** — "What are you listing / Booking Preference / Category / Tags" should be **icon + name** selectors, not a dropdown/list 🖼️ | Convert these steps to card/chip selectors with icons. Functional wizard UX. | FE host wizard | P1 |
| **HOST-6** | **Dynamic form by property type** — selecting **PG** (etc.) should change the whole form accordingly | Make the wizard schema conditional on `property_type` (PG vs Villa vs Flat…). | FE host wizard (+ BE fields already exist) | P1 |
| **HOST-7** | **Current location at top of form + geolocation broken** 🖼️ | Add a "use current location" action at the top; fix the geolocation call (returns wrong/empty). Autofill address/city/lat-lng. | FE host wizard, geolocation util | P1 |
| **HOST-8** | **Pricing fields** — max price/night (ideal), monthly, weekly, with example/suggested price 🖼️ | Add/relabel pricing inputs (fields exist in `tbl_properties`: weekend_price, min_booking_amount, propDetail weekly/monthly). Add helper/example text. | FE host wizard | P1 |
| **HOST-9** | **Amenities with icons** 🖼️ | Render amenity picker as icon grid (amenity list already in `tbl_amenities`). | FE host wizard | P1 |
| **HOST-10** | **Check-in/out placement + values** — put below property details; fix default times 🖼️ | Reorder step; fix check-in/out time inputs. | FE host wizard | P1 |
| **HOST-11** | **Remove "Couple Friendly" + "Party/Group booking"** from the form | Remove these fields from the wizard (leave DB columns; just don't collect). | FE host wizard | P1 |
| **HOST-12** | **Host KYC flow** — DIDIT scanner should auto-redirect; on completion show **Verified**; compare upload→shows Aadhaar 🖼️ | Wire host KYC to DIDIT (auto-redirect to session, no manual scanner), reflect verified state (ties BE-11). Remove manual upload once verified. | FE host KYC, BE didit | P1 |
| **HOST-13** | **"These buttons are not working"** (host dashboard) 🖼️ | Reproduce and fix the dead buttons on the host dashboard/wizard (identify which via screenshot image41). | FE host portal | P1 |
| **HOST-14** | **Inline validation** — show errors immediately, not at end of form 🖼️ | Field-level validation on blur/change (pairs with BE-9). | FE host wizard | P1 |
| **HOST-15** | **Host nav cleanup** — remove stray items ("Host Work Space" / nav item), add **Blog** + **Find your listing** | Trim + add host nav entries. | FE host nav | P2 |
| **HOST-16** | **Replace "Total Spent" box** on host dashboard with a more relevant metric | Swap the KPI tile (e.g., earnings/occupancy) — confirm replacement with client. | FE host dashboard | P2 |
| **HOST-17** | **Host name missing + add WhatsApp number** 🖼️ | Surface host name; add WhatsApp field below contact. | FE host profile, BE user | P2 |
| **HOST-18** | **Differentiate host vs user interface color** 🖼️ | Give the host portal a distinct accent from renter (still on-brand). | FE host theme | P2 |
| **HOST-19** | **Show State Regulations page in host area** | Add/link the state-regulations content page in host. | FE host | P2 |

---

## 4. Renter Dashboard

| ID | Task | Analysis / Action | Area | Pri |
|----|------|-------------------|------|-----|
| **RENT-1** | **Profile update + profile picture not updating** 🖼️ | Known issue: upload succeeds but detail refresh/render fails (see mobile fix S161 for pattern). Fix web: use returned image URL, don't hard-refresh on 400. | FE renter profile, BE `/user/add/profile-pic` + `/user/detail` | **P0** |
| **RENT-2** | **Prebooking button not working** (home) 🔁 | Wire the prebooking CTA to the prebooking flow/route. Appears in multiple places (home + get-started). | FE renter home | **P0** |
| **RENT-3** | **Current location not working + autofill address** 🖼️ | Fix renter geolocation (search bar shows wrong location though map is right); autofill address from current location. | FE renter (geolocation, search bar) | P1 |
| **RENT-4** | **Map filters not working** | Filters don't apply on the map results. Fix filter → query wiring. | FE renter map + search API params | P1 |
| **RENT-5** | **Show 4–5 listings on home + map** | Ensure home renders a handful of real listings beside the map. (Data now seeded — see test-properties.) | FE renter home | P1 |
| **RENT-6** | **Renter nav cleanup** — remove About us / Contact / Become a host / Add from renter nav | Trim renter nav to the intended items. | FE renter nav | P1 |
| **RENT-7** | **Weather widget** — show current weather for current location | Add a weather widget (needs a weather API/provider — confirm). | FE renter home | P1 |
| **RENT-8** | **KYC: hide "choose file" once DIDIT-verified** | When `verification_status=verified`, hide manual upload and show verified state (ties BE-11). | FE renter profile | P1 |
| **RENT-9** | **Support bot only on renter dashboard/profile, not everywhere** | Scope the support widget to renter area (pairs BE-10, ADM-2). | FE layout | P2 |

---

## 5. Property Detail / Booking (renter-facing, functional)

| ID | Task | Analysis / Action | Area | Pri |
|----|------|-------------------|------|-----|
| **BOOK-1** | **Detail/booking not dynamic** — show real DB fields: guests, beds, avg rating (★), more property details | Bind detail page to full property payload (fields exist). | FE detail, BE property detail | **P1**→P0-ish |
| **BOOK-2** | **"Meet your host" not dynamic; show host number post-booking** | Make host block dynamic; reveal host phone only after booking. | FE detail, BE | P1 |
| **BOOK-3** | **Availability calendar (before gallery)** — show real availability | Depends on BE-1 availability data; render calendar with booked dates blocked. | FE detail, BE availability | P1 |
| **BOOK-4** | **Nearby places dynamic** | Replace static "nearby" with a real source (places API or curated). Confirm data source. | FE detail | P1 |
| **BOOK-5** | **Booking page image slider not dynamic** | Bind slider to the property's real images. | FE booking page | P1 |
| **BOOK-6** | **Add host detail + cancellation-policy button on booking page** | Surface host info and a cancellation-policy action. | FE booking page | P1 |
| **BOOK-7** | **Ongoing-page booking modal** needs work 🖼️ | Fix/redesign the modal opened from the ongoing page. | FE | P1 |
| **BOOK-8** | **Gallery: big hero image + grid** (replace slider) | Detail-page gallery layout change (borderline UI, but tied to detail data). | FE detail | P1 |
| **BOOK-9** | **Map section after review section** on detail page | Reorder sections. | FE detail | P1 |

---

## 6. Cross-cutting (applies to multiple dashboards)

- **CC-1 (P1):** Loaders + skeleton loaders across the web app (we have this pattern on mobile — mirror it).
- **CC-2 (P1):** One consistent calendar/date-picker component app-wide.
- **CC-3 (P1):** "Welcome back, {name}" on dashboards (host + renter).
- **CC-4 (P2):** Premium icon set everywhere (see ADM-4).
- **CC-5 (P1):** Field/validation audit everywhere (see BE-9 / HOST-14).

---

## 7. Parked — pure marketing UI / cosmetic / content (out of scope this pass)

Tracked so nothing is lost; revisit after the dashboards are solid. Full wording + screenshots in [`POST_25_RELEASE_TASKLIST.md`](POST_25_RELEASE_TASKLIST.md).

- **Get Started page (Page 1):** logo background, font change, hero floating tags/"12k properties", stock-color slider backgrounds, remove rates/reviews/FAQ/footer, role-based entry redesign, nav behavior on scroll, "content provided by us". 🔒 (logo, font, copy pending client)
- **About Us (Page 3):** redesign, image swaps, mission/vision animated icons, "what makes us different", content. 🔒
- **Contact Us (Page 4):** form redesign; *quick win to keep:* remove call icon + add address.
- **Login (Page 6):** slider/animation, "looks cheap" restyle, login copy. 🔒 (copy pending) — *functional parts (Google/phone/KYC) are in §1.*
- **Signup (Page 7):** "looks cheap" restyle — *functional parts (phone signup, KYC, role select) are in §1/§3.*
- **Menu / sidebar (Page 5):** rename "Home"→"Prebooking", move "Why list with aajoo" + "State regulations" to footer, remove support button.
- **Luxury UI polish**, filter drawer redesign, move "Why guests love aajooHomes" CTA to About, move "places to visit" to property section, redesign Become-a-host/FAQ/review sections, general slider spacing.

---

## 8. Blocked on client inputs 🔒

Cross-reference [`CLIENT_INPUTS_REQUIRED.md`](CLIENT_INPUTS_REQUIRED.md). Needed to unblock in-scope items:
- **Category list** (unblocks BE-6, ADM-3, HOST-5).
- **Weather API** choice/key (unblocks RENT-7).
- **Nearby-places** data source (unblocks BOOK-4).
- **Cancellation policy** text (unblocks BOOK-6).
- Marketing copy / logo / font (unblocks most of §7).

---

## 9. Consolidated execution checklist (in-scope, priority order)

### P0 — do first
- [x] **BE-1** Double-booking overlap guard — *DONE (needs backend deploy).* Fixed the gap where online-payment (`statusPaymentPending`) bookings didn't hold their slot; now a 30-min pending hold + `bookConfirm` are counted. Validated the guard query against live DB.
- [x] **BE-2** Host dashboard on real data — *DONE (already dynamic — verified).* `GET /host/dashboard/summary` returns real aggregates for host 100 (`activeListings:15`, `upcomingBookings:1`, real ledger `recentActivity`); the dashboard fetches it via redux with skeleton/error states. Prior work resolved this; no change needed.
- [x] **HOST-1** "Property is not submitted" — *ROOT-CAUSED (no backend bug).* Live API repro: `/properties/add` returns `success:true` and creates the property as **pending** (`is_active:0`). Host can't see it because there's **no host property-list page** → resolves with **HOST-4**. (Also verify no FE validation gate silently blocks the PG path.)
- [x] **HOST-2** Property edit flow — *DONE (needs FE+BE deploy).* Edit button → `/host/add-property?edit=<id>` prefills the wizard (base fields + propDetails + amenities from JSON + cats/tags + party/pg) and submits with `propertyId`. **Live repro caught a real bug**: `propertyId` was stripped by `stripUnknown` validation → duplicate created; fixed by whitelisting `propertyId` in the schema + added an owner-only guard on update. FE typechecks; BE syntax OK.
- [x] **HOST-3** Host ongoing-bookings page — *DONE (needs FE deploy).* New `/host/ongoing` page + "Ongoing" nav; lists confirmed/in-progress stays (guest, dates, status) from `POST /booking/ongoing-host`. Empty case returns a bare `"no record found"` (the shape that crashed mobile) — the page guards `data?.bookings ?? []`. Verified against live API; typechecks.
- [x] **HOST-4** Host property list page — *DONE (needs FE deploy).* New `/host/properties` page + sidebar "My Properties" nav; lists all host listings with Live/Pending/Rejected status + Edit/View. Data path verified against live API (9 properties returned). Resolves HOST-1.
- [x] **RENT-1** Renter profile-picture bug — *DONE (needs FE deploy).* Root cause: the picker only set a local blob preview and never uploaded. Added `uploadProfilePic` → `POST /user/add/profile-pic` and wired it with optimistic preview + rollback. Typechecks clean.
- [x] **RENT-2** Prebooking button — *DONE (needs FE deploy).* The button had no `onClick` at all; wired it to `/property/list`.
- [x] **BOOK-1** Detail dynamic data — *DONE (needs FE deploy).* Detail already fetched real property + reviews + host; added: **real average rating** computed from fetched reviews (was a hardcoded 4.8 fallback) + a **guests · beds · bathrooms** facts strip (data was in the payload but never shown). Verified `/properties/8` returns `6 guests / 3 beds / 3 baths`; typechecks.

### P1 — next
- [ ] BE-3 Notifications generation · BE-4 Sockets messaging · BE-5 Invoice PDF · BE-6 Category seed 🔒 · BE-7 Google sign-in · BE-8 Phone signup · BE-9 Validation audit · BE-11 KYC verify write-back
- [ ] ADM-1 Admin add-property form · ADM-2 Remove BotPenguin from admin · ADM-3 Category mgmt 🔒
- [~] **HOST-5..14 Wizard** — DONE: HOST-5 (icon selectors for type + booking-pref), HOST-6 (dynamic PG form — already present), HOST-8 (suggested-price guide), HOST-9 (amenity icons), HOST-11 (removed Couple-Friendly + Party). REMAINING: HOST-7 (move location btn to top — btn exists), HOST-10 (check-in placement), HOST-12 (host KYC auto-redirect), HOST-13 (dead buttons — needs identifying), HOST-14 (on-blur inline validation — per-step already works).
- [x] **RENT-4** Map filters — fixed via the search-schema whitelist (radius/category/price were being stripped). · [x] **RENT-5** Home listings — now populate (radius=100 applies + properties relocated to real cities). · [ ] RENT-3 Geolocation/autofill · RENT-6 Nav cleanup · RENT-7 Weather 🔒 · RENT-8 Hide upload when verified
- [ ] BOOK-2..9 Detail/booking dynamic + host detail + calendar + gallery + reorder
- [ ] CC-1 Skeleton loaders · CC-2 Unified calendar · CC-3 Welcome-name · CC-5 Validation
- [x] **Follow-ups:** properties spread to real city coords (live) · empty-state fallback ("no stays nearby → show available")

### P2 — later
- [ ] BE-10 BotPenguin config · ADM-4 Premium icons · HOST-15..19 (nav, KPI, host name/WhatsApp, theme, state regs) · RENT-9 Scope support widget

---

_Generated 2026-07-10 from the "Post 25 release" sheet. Update checkboxes here as items land; keep the raw sheet extraction in `POST_25_RELEASE_TASKLIST.md` for screenshot reference._
