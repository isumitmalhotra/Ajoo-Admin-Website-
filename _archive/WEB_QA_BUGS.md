# Web QA Bug Log — Final Consolidated Report

**Date:** 2026-06-06
**Scope:** All web surfaces — customer funnel, auth, account, marketing/static, admin, host portal
**Method:** gstack headless Chromium at 1440×900 + 375×812 viewports
**Dev server:** http://localhost:5173
**Screenshots:** `C:/Users/Asus/AppData/Local/Temp/ajoo-qa/*.png`

**Severity:** **P0** broken/blocker · **P1** visual regression · **P2** polish/parity gap

**Counts:** 9 P0 · 13 P1 · 6 P2 = **28 bugs**

**Sprint 1 status — COMPLETE (2026-06-07):** P0-01 through P0-08 fixed and verified in browser. P0-09 deferred to Sprint 2.

---

## P0 — Blockers (9)

### ✅ P0-01 — Host Portal sidebar is entirely PURPLE (full redesign regression)
- **Where:** `src/components/layout/HostSidebar.tsx:90`
- **Bug:** `linear-gradient(176deg, #4c1d95 0%, #6d28d9 36%, #7c3aed 100%)` — full purple gradient sidebar on every host page (Dashboard, Bookings, Earnings, Performance, Statements, Support, Communication, Profile)
- **Related:** `src/components/layout/HostHeader.tsx:85` — "Host Workspace" pill uses `#ede9fe` bg + `#5b21b6` text
- **Related:** `src/pages/host/layout/HostLayout.tsx:14` — radial gradient uses `rgba(167,139,250,0.18)` (lavender)
- **Related:** Charts (Performance page) — line + axis colors all purple; Health Score progress bar purple; +New Ticket button purple
- **Fix:** Replace gradient with `#1B2447 → #2A356B` (indigo); pill `kCream` bg + `Brand.indigo` text; chart series → indigo/clay/success palette (same as admin charts already migrated in A4-04)
- **Evidence:** `host-dashboard.png`, `host-bookings.png`, `host-earnings.png`, `host-performance.png`, `host-statements.png`, `host-support.png`, `host-communication.png`, `host-profile.png`

### ✅ P0-02 — Admin Login has red/orange gradient + maroon Sign In button
- **Where:** `src/pages/admin/adminLogin/AdminLogin.tsx`
- **Bug:** Left split-screen panel has red/orange/maroon gradient bg (pre-redesign brand). Sign In button is maroon gradient.
- **Fix:** Panel bg → indigo or sand+cream; Sign In button → solid indigo `#1B2447`
- **Evidence:** `admin-login.png`

### ✅ P0-03 — Admin Dashboard logo missing
- **Where:** `src/components/layout/Sidebar.tsx` or admin layout
- **Bug:** Sidebar shows "Your Logo" placeholder text + a hollow purple circle outline. No actual logo.
- **Fix:** Wire to real aajoo logo asset; rebrand circle to indigo solid
- **Evidence:** `admin-dashboard.png`

### ✅ P0-04 — Admin Dashboard sidebar nav icons are purple
- **Where:** `src/components/layout/Sidebar.tsx` (admin)
- **Bug:** "Dashboard" link icon is purple, several other icons use purple. Items: Properties, Bookings, Finance have purple chevrons.
- **Fix:** Replace with indigo
- **Evidence:** `admin-dashboard.png`

### ✅ P0-05 — Booking Confirmation page has pink gradient
- **Where:** `src/pages/user/BookingConfirmed.tsx:25`
- **Bug:** `background: "linear-gradient(135deg, #ffffff, #ffe6ee)"` — leftover pink
- **Also:** Line 118 — "Go to Home" button hover state still pink `#a63655`
- **Fix:** Bg → `Brand.sand`; hover → `Brand.indigo600`
- **Evidence:** `05-confirmation-desktop.png`

### ✅ P0-06 — Become a Host page has pink full-page background
- **Where:** `src/pages/user/BecomeHost.tsx`
- **Bug:** Page wrapper bg is pink (same `#ffe6ee` family). Form card inside is cream — contrast looks weird.
- **Fix:** Wrapper bg → `Brand.sand`
- **Evidence:** `static-become-a-host.png`

### ✅ P0-07 — Help Center page has pink full-page background
- **Where:** `src/pages/user/HelpCenter.tsx`
- **Bug:** Same pink bg as Become a Host
- **Fix:** Wrapper bg → `Brand.sand`
- **Evidence:** `static-help-center.png`

### ✅ P0-08 — Why Hosts List With Aajoo has pink full-page background
- **Where:** `src/pages/user/WhyHostsListWithAajoo.tsx`
- **Bug:** Same pink bg pattern
- **Fix:** Wrapper bg → `Brand.sand`
- **Evidence:** `static-Why-Hosts-List-With-Aajoo.png`

### P0-09 — VerifyOtp + ResetPassword pages crash with React errors when navigated directly
- **Where:** `src/auth/VerifyOtp.tsx`, `src/auth/ResetPassword.tsx`
- **Bug:** React component throws on mount: "An error occurred in the <VerifyOtpForm> / <ResetPasswordForm> component". Page renders completely blank (sand bg only). Likely reads navigation state that doesn't exist when arrived at directly.
- **Fix:** Add null guards + redirect to forgot-password if required state missing
- **Evidence:** `auth-auth-verifyOtp.png` (blank), `auth-auth-reset-password.png` (blank), console errors captured

---

## P1 — Visual Regressions (13)

### P1-01 — index.html still loads Playfair Display + Poppins from Google Fonts
- **Where:** `index.html:7`
- **Bug:** `<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@600&family=Poppins:wght@400;500&display=swap">` — redesign cleaned `src/index.css` but missed `index.html`
- **Impact:** 3-second blocking font request + 14 component files with hardcoded `fontFamily: "Poppins"` / `Playfair Display` render with wrong font
- **Affected files (14):** HostInfo.tsx, WhyHostsListWithAajoo.tsx, UserProfile.tsx, userOngoingBooking.tsx, UserCheckoutPage.tsx, UserBookings.tsx, StateRegulation.tsx, HelpCenter.tsx, ContactUs.tsx, AboutUs.tsx, BookingDetailsModal.tsx, AppBreadcrumbs.tsx, RegulationModal.tsx, OngoingBookingModal.tsx
- **Fix:** Delete index.html line; sweep 14 files replacing Poppins → Inter, Playfair → Fraunces

### P1-02 — Massively oversized `room*.jpg` images on Home (~23 MB)
- **Where:** `/public/room1.jpg` (6.9 MB), room2.jpg (4.9 MB), room3.jpg (9.8 MB), room4.jpg (1.9 MB)
- **Referenced from:** PropertyDetail, ContactUs, HomeCustomGrid, HomeCategorySection, FAQ, `styles/utils/reusableData.ts`
- **Fix:** Compress to <300 KB WebP; add `loading="lazy"` to off-screen instances

### P1-03 — Home renders "Location unavailable" red error widget mid-page
- **Where:** `src/components/frontend/MapandFilter.tsx`
- **Bug:** Geolocation request rejected → renders blocking red error box. Console: `GeolocationPositionError`.
- **Fix:** Suppress error UI when permission denied; degrade gracefully

### P1-04 — Featured Properties section empty on Home
- **Where:** `src/components/frontend/FeaturedProperties.tsx`
- **Bug:** Heading renders but no cards, no empty state, no loading state
- **Fix:** Add fallback UI; investigate data source

### P1-05 — Mobile listing has no Map view-toggle
- **Where:** `src/pages/user/PropertyListing.tsx`
- **Bug:** At 375px, map is hidden and no toggle pill visible. Per REDESIGN_CONTEXT.md, mobile should have List/Map toggle.
- **Fix:** Add view-toggle UI for `@media (max-width: 900px)`

### P1-06 — Desktop listing has large empty white space below sticky map
- **Where:** `src/pages/user/PropertyListing.tsx`
- **Bug:** Right-column map ends with viewport scroll; cards keep going down left; right side becomes white void
- **Fix:** Ensure map sticky for full scroll, OR match column heights

### P1-07 — Mobile home hero collage not hidden (A2.5-42)
- **Where:** `src/components/frontend/HeroSection.tsx`
- **Bug:** Hero collage cards still render at 375px causing cramped layout
- **Fix:** `@media (max-width: 900px) { display: none }` on collage container

### P1-08 — `motion()` deprecated console warning on every page
- **Where:** Framer Motion usage somewhere in customer-facing code
- **Fix:** Migrate `motion(...)` calls to `motion.create(...)` per Framer Motion 12

### P1-09 — Forgot Password page illustration is RED/PINK
- **Where:** `src/auth/ForgotPassword.tsx`
- **Bug:** Right-side illustration shows red fingerprint, red corner brackets, and red/pink woman figure. "RETURN TO LOGIN" button is dark maroon.
- **Fix:** Replace illustration (or recolor SVG) to indigo/sand; secondary button → indigo outline
- **Evidence:** `auth-auth-forget.png`

### P1-10 — About Us page has RED illustrations + UNREADABLE WHITE TEXT
- **Where:** `src/pages/user/AboutUs.tsx`
- **Bugs:**
  - **(a)** "Our Mission" section: red dartboard illustration (pre-redesign brand)
  - **(b)** "Our Vision" section: red eye illustration + body text is white-on-white (UNREADABLE)
  - **(c)** "What Makes Us Different?" section: pink/red character illustration
- **Fix:** Replace illustrations or recolor SVGs; fix Our Vision text color → `Brand.ink`
- **Evidence:** `static-about.png`

### P1-11 — 404 page has PURPLE cat illustration
- **Where:** `src/pages/user/NotFound.tsx` (uses `assets/UI/404.jpg`)
- **Bug:** The 404 hero image shows a purple cat — leftover pre-redesign brand color
- **Fix:** Replace image with indigo/sand-themed 404 illustration
- **Evidence:** `static-nonexistent-page.png`

### P1-12 — User Dashboard "Welcome Back" banner has pink gradient
- **Where:** `src/pages/user/dashboard/*` or DashboardLayout
- **Bug:** Top welcome banner uses `#ffe6ee` pink gradient (same family as BookingConfirmed)
- **Also:** Outer page bg is gray instead of `Brand.sand`
- **Fix:** Banner → indigo or sand; outer bg → sand
- **Evidence:** `static-user-dashboard.png`

### P1-13 — MUI Select warnings on User Dashboard (out-of-range value)
- **Where:** User dashboard form (Gender, State, ID Type)
- **Bug:** Console: `MUI: You have provided an out-of-range value 'undefined' for the select component. The available values are 'male', 'female', 'other'`. Same for state and document type.
- **Fix:** Set default to `''` instead of `undefined` when value is empty

---

## P2 — Polish / Parity Gaps (6)

### P2-01 — Property Detail missing dedicated Features/Amenities grid (A2.5-29)
- **Where:** `src/pages/user/PropertyDetail.tsx`
- **Bug:** POC shows icon grid for amenities between gallery and host card. Currently rendered as small inline list.
- **Fix:** Build `<AmenitiesGrid>` sourced from `property.amenities`

### P2-02 — Checkout amenity pills off-spec
- **Where:** `src/pages/user/FinalBookingPage.tsx` (or inner component)
- **Bug:** "Apartment / Luxury / Family" pills small + uncategorized; POC chip pattern is `8 14 / radius 999 / fs 13 / cream bg + line border`
- **Fix:** Apply POC chip styles

### P2-03 — User Dashboard "Welcome Back, Jhon!" typo
- **Where:** `src/pages/user/dashboard/*`
- **Bug:** Hardcoded "Jhon" instead of "John" (or should use actual user name)
- **Fix:** Wire to user.name from auth state

### P2-04 — User Dashboard outer bg is gray, not sand
- **Where:** DashboardLayout
- **Bug:** Outer page area renders gray-ish; should be `Brand.sand` per palette
- **Fix:** Set bg → sand

### P2-05 — 14 files with stray Poppins/Playfair `fontFamily` strings
- See P1-01 list. Cleanup pass after index.html font fix lands.

### P2-06 — Cancel Result page bg is gray instead of sand
- **Where:** `src/pages/user/CancelBookResult.tsx`
- **Bug:** Outer bg is gray. White card centers OK but page bg should be `Brand.sand`
- **Fix:** Set outer bg → sand
- **Evidence:** `cancel-result.png`

---

## Pages Walked OK (no significant bugs)

- Customer funnel: Property Listing (split-screen works), Property Detail (correct typography), Checkout (chrome OK)
- Auth: Login (clean), Signup (clean)
- Static: Contact Us, FAQ, Privacy Policy, Terms & Conditions, State Regulation
- Admin: All admin interior routes correctly redirect to /admin/login (auth-gated)

---

## What's Not Verified (gated by auth)

- Admin interior pages (Dashboard data, Users table, Properties table, Bookings table, Finance modules, Charts/Pie/Bar/Line) — all redirect to login. To verify: need admin credentials or a test-mode bypass.
- Authenticated user pages with real data (UserBookings, UserOngoingBooking, Bookmarks, Notifications)

---

## Suggested Fix Order (when ready)

**Sprint 1 — P0 visual blockers (1-2 hrs)**
1. P0-01 — Host Portal indigo migration (sidebar gradient, header pill, chart palette)
2. P0-02 — Admin Login red/orange → indigo
3. P0-05/06/07/08 — Pink-bg pages (BookingConfirmed, BecomeHost, HelpCenter, WhyHosts) → sand
4. P0-03/04 — Admin logo + sidebar nav colors

**Sprint 2 — P0 functional + P1 quick wins (1 hr)**
5. P0-09 — VerifyOtp / ResetPassword null guards
6. P1-01 — index.html font link removal + 14-file sweep
7. P1-03 — Geolocation error suppression
8. P1-09/10/11 — Replace red illustrations (Forgot, About, 404)
9. P1-10b — Fix About Us white-on-white text
10. P1-12 — User Dashboard pink banner + bg
11. P1-13 — MUI Select default values

**Sprint 3 — P1 layout + perf (2-3 hrs)**
12. P1-02 — Compress room*.jpg images
13. P1-05/06/07 — Responsive (mobile listing toggle, sticky map, hero collage hide)
14. P1-04 — Featured Properties empty state
15. P1-08 — motion() migration

**Sprint 4 — P2 polish (optional, 1-2 hrs)**
16. P2-01/02 — Amenities grid + checkout pills
17. P2-03/04/05/06 — Naming, bg colors, font cleanup
