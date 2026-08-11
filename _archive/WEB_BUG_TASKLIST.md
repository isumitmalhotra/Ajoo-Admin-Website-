# Aajoo Web Platform — Bug Task List

Scope: **website only** (React/Vercel customer + admin + host portals). Mobile-app-only
items from `bugs (2).xlsx` are excluded (splash/music, app loaders, OS back-bar overlap,
rate-app button, history/safety pages, get-started background).

Source: `bugs (2).xlsx` (User / Host / Common sheets). Row refs in parentheses.

---

## ✅ Done (this cycle)
- Nav bar "Hi, <name>" greeting + account menu (User 15)
- Real aajoo logo + name in header/footer; logo → home; "Go to Homepage" in dashboards (Common 6)
- Functional fixes not itemized in the sheet: host/renter login wiring, admin logout, blank
  Finance dashboard + 4 report pages, public property/host routes (401), GuestRoute redirects,
  host-login role, host profile endpoint, nights-based pricing.

---

## 🔴 P0 — Tackle first (broken functionality + core discovery funnel)

### 1. Map (home + listing) — ✅ DONE (verified)
- [x] **Home map** pan/drag → reloads properties for the new area (Common 9) — verified (commit 7f13290)
- [x] **Home map** re-centre button → returns to user location + reloads; serves as "near me" (User 12 / Common 10 / Common 21)
- [x] **Listing map** refetch on far pan (>~50km) instead of only filtering loaded set (commit 2dec80c) — verified (setView→new search)
- [x] **Place-search recentres the map** (Common 22) — verified: ?location=Manali → map centre {32.25,77.19}; ?location=Delhi shows 3 stays
- [x] **Price-chip markers** unified across home + listing (shared priceMarker util) (User 4, 5) — verified: 3 ₹-chips render at Delhi
- [x] (Web has no separate "Nearby" button — re-centre now covers it)
- NOTE: maps look empty for Goa/Manali/most areas only because the **test data is clustered near Delhi**; the map UI is correct. Real population depends on properties having coordinates (see backend search/data).

### 2. Search & filters — ✅ DONE (verified, commit 262c7a6)
- [x] Price filter now actually applies (was passed in but ignored) (Common 18) — verified: "Under ₹1K" → 0 cards, "₹1K–₹5K" → 3 cards
- [x] Price chips at top of listing (Common 19)
- [x] Popular-destination **state chips** on listing → click searches that state (User 79) — verified (Himachal Pradesh etc.)
- [x] Airbnb-style **guest selector** (Adults/Children) in home search bar (Common 11) — verified (popover + count updates)
- [x] Search bar destination **suggestions** (datalist) (Common 20) — verified
- [x] Search bar seeds current location; guest field cleaned up via the new selector (Common 8)
- [x] Weekly tier removed; listing filter redesigned to price ranges/chips (User 11). NOTE: "Monthly" remains as a booking *stay type* (intentional — monthly rentals), not a filter tier.

### 3. Wishlist — ✅ DONE (verified, commit 171d600)
- [x] Card heart: functional save + **login-guarded** (was redirecting logged-out users to home via the 401 trap) (User 14)
- [x] Property detail: dead "Save" chip → working wishlist toggle (heart fill + Saved/Save), reflects saved state on load, login-guarded (User 42)
- [x] "Share" chip copies the page link
- [x] Saved list (dashboard → Saved) reflects saves — verified (saved-properties API returns saved id)

### 4. Booking integrity — PARTIAL (1 done; 2 blocked on Razorpay + backend)
- [x] On-going popup on homepage redesigned + "View All" button (User 62) — commit 8a6c7b9; verified (hides correctly, no 401 loop, no errors). Full card display needs a real ongoing booking.
- [ ] ⛔ Prevent multiple overlapping bookings (User 67) — lives in the booking-creation/payment flow (Razorpay-gated) and needs **backend** enforcement to be real. Defer until Razorpay live keys are provided.
- [ ] ⛔ Pay-on-arrival: only one active POA at a time (User 60, 61) — same: booking/payment flow + backend rule. Defer until Razorpay unblocked.

---

## 🟠 P1 — Conversion UX (search → detail → book)
- [x] Property card redesigned (home) + reused on listing + wishlist heart (User 9, 75, 76)
- [x] Property detail: gallery lightbox (43) — verified (click image → lightbox Modal)
- [x] Property detail: attraction points "Explore places nearby" (44) — verified present
- [x] Property detail: cancellation-policy button (45) — verified (opens policy modal)
- [x] Host portal: "Welcome <first name>" on top (Host 2) — verified ("Welcome back, Aajoo")
- [x] Host portal: no-booking illustration (Host 4) — verified
- [x] Host portal: support button (Host 6) — host Support page functional (raise-ticket dialog + tickets list)
- [x] Property detail: font/icon/button sizing (40) — addressed by Sand & Indigo redesign; page is well-proportioned (verified by screenshot)
- [x] Home: "Find Your Stay" section header after category chips (User 8, Common 25) — commit be30916, verified
- [x] Listing: compact filter drawer + chips + loader already in place (74/77/78/80 — from the #2 search/filter work)
- [x] **Categories from admin + icon upload** (Common 24, User 10) — DONE + verified end-to-end:
  - Backend: migration adds `tbl_categories.cat_icon` (applied to live DB), model, `/admin/category/create` accepts a `cat_icon` file (multer → Cloudinary), `/common/categories` returns it. (aajaoBackend commit 908efcb)
  - Frontend: admin category form has an icon picker + preview; home chips render the icon. (commit 144fa89)
  - Verified: uploaded an icon to "Resort" via admin → Cloudinary URL → shows on the home chip.
- [x] **Nearest-booking map (66)** — ongoing booking modal now shows a Leaflet location map + "Get directions" (commit cfece15 + backend 4531e17 to return coords). Verified live.
- [x] **Ongoing page polish (59)** — empty-state illustration + working detail modal (commit 3b17083). Verified.
- [x] **Booking flow fixed** — the checkout never actually created a booking (RazorpayPayment was client-only: no /booking/create, no order, no verify) + date format mismatch (YYYY-MM-DD vs backend DD-MM-YYYY). Now: createBooking → Razorpay order → /create/payment-verify → invoice; "Reserve & pay later" = POA (commit 588f7e1). Booking-create verified from UI (POST /booking/create → 200, persists, shows in ongoing + OngoingFloat). **Test payment (Razorpay test card) is the one manual step.**
- [ ] Cancel page redesign per market (64) — not in this pass
- [ ] 🎨 Property detail sticky category/rating on scroll (41) — mobile-specific; needs design direction
- [ ] 🎨 Host portal announcement slider (Host 3) — needs content/design direction

---

## 🟡 P2 — Polish & redesign
- [ ] Announcement slider on home (4–5 colored) (Common 23)
- [ ] Illustrations/SVGs (16); footer social responsive (18); social icons on Help page (23)
- [ ] Notification icon (Common 7)
- [ ] About Us redesign (26, 92); Settings cleanup (30, 31); sidebar redesign (17)
- [ ] Profile summary in top section (20)
- [ ] Signup: break into steps (7); Forget Password flow (88, Common 5); login page styling (Common 4)
- [ ] Consistent aajoo font (Common 3)
- [ ] Document upload UX + landscape enforcement (35, 36); duplicate-pages cleanup (95)

---

## ⛔ Blocked — need client inputs (unblock in parallel)
- [ ] Razorpay LIVE keys → real payments + booking persistence (User 56)
- [ ] DIDIT credentials → host KYC verification (User 2)
- [ ] Sockets: confirm socket server live (offer-your-price loader, real-time) (User 51, 52, 94)
- [ ] OTA calendar block — needs channel-manager details (70)

---

## 💬 Decisions needed (not coding yet)
- [ ] Sidebar listing approach (21)
- [ ] Booking-change flow (49)
- [ ] Support contact details (22)
- [ ] "Browse by category" approach (Common 26)
- [ ] City/State ID cleanup in DB (6)

---

## First sprint (recommended order)
1. **Map fixes** (pan-to-load, nearby, recentre, place redirect, markers) ← current
2. Search bar + filter redesign
3. Wishlist
4. Property card redesign (home + listing)
5. Ongoing popup + View All / multiple-booking guard

In parallel: request **Razorpay live keys** + **DIDIT credentials** (lead time).
