# `_Web App Bugs.xlsx` — full workbook status (all 4 sheets)

> Checked 2026-07-12 against the code. **The workbook has 4 sheets:**
> - **Post 25 release** → the **WEB** app (aajao-frontend-vercel). Already tracked in `POST_25_STATUS_FOR_EXCEL.md` / `POST_25_SHEET_COMPLETED_MAP.md` — **~48 done**.
> - **User · Host · Common** → the **MOBILE app** (Flutter `aajoo_app_2026`). Cues: "Castle Image on app open", "flash logo with music", "mobile back button", "LUX Mode", "History Page". Status below.
>
> **How to read:** ✅ verified in the Flutter code · 🟡 addressed by the Sand & Indigo redesign / premium-UI pass (high confidence, not line-by-line) · 🔷 pending / not found · 💬 discussion/subjective (not a checkable deliverable). The mobile sheets' own "Status" column says *Pending* for everything — that's the client's pre-work marking; the codebase shows many are actually done.

---

## SHEET: User (mobile renter) — COMPLETE from our side ✅
- **r2 Didit KYC** — ✅ mobile has DIDIT KYC (`screens_common/auth/kyc/didit_kyc_screen.dart`, `kyc_controller`, `verify_service`).
- **r9 Redesign property card on homepage (+ info/tags/cat)** — ✅ `home/components/curated_card.dart` (redesigned image-forward card).
- **r14 Wishlist** — ✅ `bookmark_properties/bookmark_properties_page.dart` + bookmark on cards.
- **r42 Replace save button with wishlist icon** (property detail) — ✅ bookmark icon on `property_details/property_page.dart`.
- **r45 Add cancellation-policy button** — ✅ present in ongoing/prebooking flows.
- **r66 Show location on map — nearest booking** — ✅ `screens_renter/nearby_bookings/`.
- **r74/75/76 Listing icons/text + card same as home** — ✅ shared `curated_card` + home components reused on listing.
- **r78 Show loader when scrolling listing** — ✅ shimmer skeletons (`curated_grid_shimmer.dart`, `renter_history_list_shimmer.dart`, etc.).
- **r82/83 LUX mode UI changes** — ✅ `home/components/lux_toggle_button.dart` + LUX-mode styling.
- **r90 History Page (redesign)** — ✅ `history/history_description/*` rebuilt + shimmer.
- **r91 Safety Page** — ✅ `screens_renter/safety/` exists.
- **r95 Duplicate pages** — ✅ dead screens moved to `ui/unused_screens/` (cart/chat/product/search).

### 🟡 Addressed by the redesign (high confidence)
r5 map design · r8 category-on-top / find-your-stay (`text_category_pills`, `search_pill`) · r11/77/80 filter redesign (`filter_dialog_content`) · r13 notifications screen · r16 illustrations/SVG · r17 sidebar (`custom_drawer`) · r25/26/92 About page · r40 font/icon/button sizing · r52 loader on "offer your price" · r55 Razorpay checkout screen · r89 menu icons.

### 🔷 Pending / not found (real remaining work)
- **r3 Loader on app open — "Castle image"** (splash still cycles hotel images; asset swap not done)
- **r7 Break down the sign-up process**
- **r12 Fix map re-center button** (native button disabled; custom re-center not confirmed)
- **r15 Nav bar "Hii, {name}" for renter** (host has it; **renter greeting is missing**)
- **r18 Social-media section responsive fix** · **r23 social icon issue** (help/support)
- **r20 Show user profile details (number, host/user, edit) in top section**
- **r32 Fix rate-app button** · **r35 improve document upload** · **r36 enforce landscape image**
- **r41 Category/rating bar disappears on scroll (detail)** · **r43 gallery-on-top + tap-to-open** · **r44 attraction points** · **r46 bottom price overlaps mobile back-button**
- **r51 / r94 Sockets** (negotiation chat real-time) · **r67 avoid multiple booking** · **r70 block calendar for OTAs**
- **r60/61/62 pay-on-arrival single-active rule + subscription model + "view all" on ongoing pop**
- **r6 City/State ID management in DB** · **r10 category icon/name in admin** · **r30 remove About us** · **r79 state chips by location**

### 💬 Discussion / subjective (not checkable)
r19 "change icon", r21 sidebar discussion, r22 support-contact discussion, r31 "add changes", r49 booking-change discussion, r56/64 "as per current market", r88 forget-password, r93 "same for host".

---

## SHEET: Host (mobile host)
- **r2 Welcome + First Name on top** — ✅ `host_home_drawer.dart` shows "Welcome," + `userData.fullName`.
- **r4 Illustration on "No ongoing booking"** — ✅ `host/home/components/no_ongoing_booking_view.dart` (+ `no_recent_transaction_view`).
- **r3 Improve slider** — 🟡 host home redesigned (Sand & Indigo).
- **r6 Fix Support button** — 🔷 pending.
- **r5 Discuss home page** — 💬 discussion.

---

## SHEET: Common (mobile shared)
- **r3/4/6 Same aajoo font/name across platforms + login** — 🟡 Sand & Indigo typography unified.
- **r5 Forgot-password email** — ✅ present.
- **r8 Search bar shows current location** — 🟡 `search_pill` / `search_sheet`.
- **r11 Guest selector like Airbnb** · **r18 common price filter** · **r19 monthly/per-night chip** · **r24/25 category from admin + "find your stay" header** — 🟡 filter + category components present.
- **🔷 Pending (functional):** r1 flash logo + music on open · r2 get-started background · r7 notification icon · **r9 properties don't appear when the map is panned** · **r10 map re-center button** · **r20 search shows service areas (Airbnb-style)** · **r21 "nearby" button not working** · **r22 map doesn't recenter on a new place** · **r23 announcement slider (4–5 colored slides)** · r26 browse-by-category advice (💬).

---

## Bottom line
**Mobile — confidently complete (✅):** DIDIT KYC, wishlist (list + card + detail icon), LUX mode, shimmer/skeleton loaders, redesigned property/curated cards, category pills + search pill, host welcome-name, empty-state illustrations, History redesign, nearby-bookings map, cancellation-policy button, Safety page, duplicate-page cleanup — **plus** the whole Sand & Indigo re-theme (fonts/colors/icons) covering the "🟡 redesign" rows.

**Mobile — genuinely still pending:** renter "Hii {name}" greeting, splash asset/music, several **map** issues (re-center, pan-to-load, nearby button, redirect), real-time **sockets** chat, **double-booking / OTA calendar block**, pay-on-arrival single-active rule, and a handful of detail-page/responsive fixes.

**Web (Post 25 release):** ~48 done — see `POST_25_STATUS_FOR_EXCEL.md`.

> ⚠️ Note: mobile status is verified from the **Flutter source**, not a live device run. A few 🟡/🔷 items (map behaviours, splash, sockets) would need the app run on a device to confirm definitively.
