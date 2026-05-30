T# AajooHomes — UI Redesign Task Tracker (Sand & Indigo)

> **Palette:** Sand & Indigo (client-approved Option 3)  
> **Primary brand color:** Indigo `#1B2447` / `0xFF1B2447` — replaces purple (web) and pink (mobile)  
> **Scope:** Visual re-skin only — color, spacing, radius, shadow, typography. NO logic/behavior/API changes.  
> **Reference:** `REDESIGN_BRIEF.md` (full spec + guardrails)  
> **Started:** 29 May 2026
> 
---

## Status Legend

| Symbol | Meaning |
|---|---|
| ✅ | Completed & committed |
| 🔄 | In Progress |
| ⬜ | Not Started |
| ⏭️ | Skipped (logged in REDESIGN_OPEN_QUESTIONS.md) |
| 🔴 | Blocked |

---

## GUARDRAILS (non-negotiable)

- Style values only — no logic, routing, state, API, or dependency changes
- `npm run build` (web) and `flutter analyze` (mobile) must stay clean after every phase
- Payments (`checkout/`) and maps — restyle chrome only, never touch logic
- Dark mode (mobile) must stay correct alongside light — update both themes together
- When in doubt: skip + log in `REDESIGN_OPEN_QUESTIONS.md`

---

# PART A — WEB APP (React + TypeScript + MUI + Tailwind)

> Working directory: `D:/Projects/ajoo admin website/` (root with `src/`)  
> Current brand: Purple `#881f9b` (~96 occurrences across ~42 files)  
> Styling systems: MUI v7 (`sx`), Tailwind v4, Bootstrap 5 + custom CSS

---

## Phase A0 — Web Discovery Audit (NO code changes)

| ID | Task | Status | Output |
|---|---|---|---|
| A0-01 | Run `npm install && npm run build && npm run lint` — record baseline errors/warnings | ⬜ | Baseline in audit doc |
| A0-02 | Color inventory: grep `#881f9b`, `#8c4ecf`, `purple`, `violet`, `rgba` purple tints, `${FOCUS_COLOR}` — list files + per-file counts | ⬜ | Audit table |
| A0-03 | Styling-system map: for each `src/pages/user/*` page, note which of MUI sx / Tailwind / Bootstrap+CSS it uses | ⬜ | Per-page map |
| A0-04 | Risk list: colors computed in JS, passed as props, or used in conditionals | ⬜ | Risk table |
| A0-05 | Produce `REDESIGN_AUDIT_WEB.md` and STOP | ⬜ | `REDESIGN_AUDIT_WEB.md` |

**Checkpoint:** Review audit → approve before A1.

---

## Phase A1 — Single Source of Truth for Color

| ID | Task | Status | Notes |
|---|---|---|---|
| A1-01 | Add `Brand` token object + back-compat aliases to `src/theme/themeColor.tsx` | ⬜ | See brief §A1 for exact code |
| A1-02 | Add CSS variables (`:root`) + Tailwind v4 `@theme` tokens to `src/index.css` | ⬜ | See brief §A1 for exact snippet |
| A1-03 | Run `npm run build` — must pass | ⬜ | Centralized UI flips to indigo |
| A1-04 | Commit: `style(web): add Sand & Indigo tokens + back-compat aliases` | ⬜ | |

**Checkpoint:** Build green. Centralized components already render indigo.

---

## Phase A2 — Centralized + High-Traffic Surfaces

| ID | Task | Status | Files |
|---|---|---|---|
| A2-01 | `src/styles/*.css` — replace hardcoded purples with `var(--indigo)`; swap purple focus glows | ⬜ | Auth forms, footer CSS |
| A2-02 | `src/components/layout/*` — navbar, footer, sidebars | ⬜ | Propagates everywhere |
| A2-03 | Shared `src/components/Form` & `Element` components | ⬜ | |
| A2-04 | Run `npm run build` — must pass | ⬜ | |
| A2-05 | Commit: `style(web): migrate centralized layout + form components to indigo` | ⬜ | |

**Checkpoint:** Auth pages, navbar, footer, base forms render indigo.

---

## Phase A3 — Customer-Facing Pages & Components

### A3.1 — Core User Pages

| ID | Task | Status | Pages |
|---|---|---|---|
| A3-01 | Home page + hero components | ⬜ | `home.tsx`, `CTAoneHome`, `FeatureSection`, `FeaturedProperties`, `HomeCategorySection`, `WhyChooseUs`, `ExploreMore`, `ReviewSlider*` |
| A3-02 | Listing + detail pages | ⬜ | `PropertyListing`, `PropertyDetail`, cards (`HomePropCard`, `PlaceCard`, `PropertyGrid`, `HomeCustomGrid`) |
| A3-03 | Filters + map chrome | ⬜ | `FilterDropdown`, `SidebarFilters`, `MapandFilter`, `HotelTooltip`, `RecenterButton`, `MarkerPulse` (chrome only — no map logic) |
| A3-04 | Booking flow | ⬜ | `UserCheckoutPage`, `FinalBookingPage`, `BookingConfirmed`, `PropertyBookingBox`, `BookingSection`, `BookingDetailsModal` (payment handler = untouched) |
| A3-05 | User account pages | ⬜ | `UserBookings`, `UserProfile`, `userOngoingBooking`, `dashboard` |

### A3.2 — Marketing / Static Pages

| ID | Task | Status | Pages |
|---|---|---|---|
| A3-06 | About, Contact, Become Host | ⬜ | `AboutUs`, `ContactUs`, `BecomeHost` |
| A3-07 | Help / legal pages | ⬜ | `HelpCenter`, `FAQ`, `PrivacyPolicyPage`, `TermsAndConditions`, `StateRegulation`, `WhyHostsListWithAajoo` |
| A3-08 | Error page | ⬜ | `NotFound` |
| A3-09 | All `src/components/frontend/modals/*` | ⬜ | |

### A3.3 — Verification

| ID | Task | Status |
|---|---|---|
| A3-10 | Walk full funnel in browser: Home → Listing → Detail → Checkout → Confirmation | ⬜ |
| A3-11 | Run `npm run build` — must pass | ⬜ |
| A3-12 | Commit: `style(web): migrate customer-facing pages + components to Sand & Indigo` | ⬜ |

**Checkpoint:** Funnel works, looks Sand & Indigo, build clean.

---

## Phase A4 — Admin & Host (Palette Only)

| ID | Task | Status | Files |
|---|---|---|---|
| A4-01 | `src/pages/admin/*` + `src/components/admin/*` | ⬜ | Keep tables high-contrast — no sand-washing data tables |
| A4-02 | `src/pages/host/*` + `src/components/host/*` | ⬜ | |
| A4-03 | `src/features/*` | ⬜ | |
| A4-04 | MUI X Charts series colors → indigo/clay/success | ⬜ | Charts only, not data |
| A4-05 | Run `npm run build` — must pass | ⬜ | |
| A4-06 | Commit: `style(web): migrate admin + host panels to Sand & Indigo` | ⬜ | |

**Checkpoint:** Dashboards render, charts recolored, tables readable.

---

## Phase A5 — Polish Pass (applied during A3–A4)

| ID | Polish Rule | Status |
|---|---|---|
| A5-01 | Card borders: `1px` warm `#D9CFB8` — no pure `#ccc` | ⬜ |
| A5-02 | Radius: cards `16px`, buttons/inputs `12px`, pills `999px` | ⬜ |
| A5-03 | Shadows: `0 1px 2px rgba(27,36,71,.04), 0 8px 24px rgba(27,36,71,.08)` | ⬜ |
| A5-04 | Heading letter-spacing `-0.02em`; body line-height `1.5–1.6` | ⬜ |
| A5-05 | Buttons: primary = indigo fill + cream text; secondary = indigo outline; hero CTA = clay | ⬜ |
| A5-06 | Badges: Verified = success-green pill; New/Featured = clay | ⬜ |
| A5-07 | Hover: card `translateY(-2px)` + soft shadow; transitions `~0.2s` | ⬜ |
| A5-08 | Card/sheet backgrounds → cream `#FFFAF0`; marketing bg → sand `#EFE7D6` | ⬜ |

*Note: If any polish item requires JSX restructuring, skip + log in `REDESIGN_OPEN_QUESTIONS.md`.*

---

## Phase A6 — Web Cleanup & Verify

| ID | Task | Status |
|---|---|---|
| A6-01 | Grep `src/` for remaining `881f9b`, `8c4ecf`, `purple`, `violet` — expect zero | ⬜ |
| A6-02 | Remove back-compat alias `PurpleThemeColor` if nothing imports it | ⬜ |
| A6-03 | Run `npm run build && npm run lint && npm run preview` | ⬜ |
| A6-04 | Walk every flow for parity check | ⬜ |
| A6-05 | Produce `REDESIGN_SUMMARY_WEB.md` | ⬜ |
| A6-06 | Final commit: `style(web): Part A complete — Sand & Indigo redesign` | ⬜ |

---

# PART B — MOBILE APP (Flutter / Dart)

> Working directory: `aajoo_app_2026/`  
> Current brand: Pink `0xffC14464` — `kprimaryColor` referenced by **88 files**  
> Dark theme currently uses pink as body text (must migrate to white/cream)  
> Has BOTH light and dark themes — must update both.

---

## Phase B0 — Mobile Discovery Audit (NO code changes)

| ID | Task | Status | Output |
|---|---|---|---|
| B0-01 | Run `flutter pub get` + `flutter analyze` — record baseline errors | ✅ | **1534 pre-existing issues** (ionicons pkg only) |
| B0-02 | Color inventory: every file with `kprimaryColor` (86 files), hardcoded pinks — paths + counts | ✅ | See `REDESIGN_AUDIT_MOBILE.md §2` |
| B0-03 | List all `LinearGradient` definitions — 20 active files | ✅ | See `REDESIGN_AUDIT_MOBILE.md §3` |
| B0-04 | Confirm theme wiring: `theme_service.dart`, `constants.dart`, `main.dart` | ✅ | See `REDESIGN_AUDIT_MOBILE.md §4` |
| B0-05 | Risk list: dark-mode body text (HIGH), conditionals (LOW), checkout/map (MEDIUM) | ✅ | See `REDESIGN_AUDIT_MOBILE.md §5` |
| B0-06 | Produce `REDESIGN_AUDIT_MOBILE.md` | ✅ | `aajoo_app_2026/REDESIGN_AUDIT_MOBILE.md` |

**Checkpoint:** Review audit → approve before B1.

---

## Phase B1 — Central Theme Migration (The Big Win)

| ID | Task | Status | File |
|---|---|---|---|
| B1-01 | `lib/constants.dart`: replace `kprimaryColor` (pink → indigo), `kscaffoldColor` (white → cream), `kcontentColor` (gray → sand); add all new `k*` tokens | ✅ | `lib/constants.dart` |
| B1-02 | `lib/service/theme_service.dart` — lightTheme: seed → `0xFF1B2447`, primaryColor → `kprimaryColor`, cardColor → `kCream` | ✅ | `lib/service/theme_service.dart` |
| B1-03 | `lib/service/theme_service.dart` — darkTheme: seed → `0xFF1B2447`, bodyColor/displayColor → `Colors.white` (fixed dark-on-dark issue) | ✅ | `lib/service/theme_service.dart` |
| B1-04 | Run `flutter analyze` — 1534 issues (same as baseline, zero new) | ✅ | |
| B1-05 | Boot app in light AND dark mode — verify indigo brand | 
⬜ | **Hot-reload on device to confirm** |
| B1-06 | Commit: `style(mobile): B0+B1 — audit + central theme migration` | ✅ | commit `72dcfab` |

**Checkpoint:** App boots both themes. 88 files instantly read new brand.

---

## Phase B2 — Hardcoded Pinks & Gradients

| ID | Task | Status | Files |
|---|---|---|---|
| B2-01 | Replace `0xFFC14464` / `0xffC14464` → `kIndigo` | ✅ | `screens/sample_homepage.dart` |
| B2-02 | Replace `0xFFAD1457` → `kIndigo` | ✅ | `property_page.dart` (renter + legacy) — 13× each |
| B2-03 | Replace `0xFF6A1B4D` → `kIndigo600` | ✅ | `payout_page.dart` + `plan_overview_card.dart` |
| B2-04 | Seed `0xffBF5973` — verified none remain (handled in B1) | ✅ | |
| B2-05 | Gradient audit — most used `kprimaryColor`/`theme.primaryColor` (auto-fixed B1) | ✅ | |
| B2-06 | `flutter analyze` — 1534 (baseline, zero new) | ✅ | |
| B2-07 | Grep `lib/` for brand pinks — zero remaining | ✅ | |
| B2-08 | Commit `87d41a5` | ✅ | |

**Checkpoint:** Zero brand pinks remain. Gradients read indigo.

---

## Phase B3 — Renter (Customer-Facing) Screens

### B3.1 — Home & Discovery

| ID | Task | Status | Screens |
|---|---|---|---|
| B3-01 | Renter home screen | ✅ | Sheet bg, drag handle, buttons, categories, reviews |
| B3-02 | Map screen chrome | ⏭️ | No brand pink in shader paints — no change needed |
| B3-03 | View ongoing booking | ✅ | Uses `kprimaryColor` gradients — auto-fixed in B1 |
| B3-04 | Nearby bookings | ✅ | `pre_booking_screen`, `pre_booking_card` — kCream, kLine |

### B3.2 — Property & Booking

| ID | Task | Status | Screens |
|---|---|---|---|
| B3-05 | Property details screen | ✅ | 13× `0xFFAD1457` → `kIndigo` (done in B2) |
| B3-06 | Checkout chrome (payment handler = untouched) | ✅ | Gradients use `kprimaryColor` — auto B1 |
| B3-07 | Booking history | ✅ | `booking_cart`, `history_description`, review sub-files — kCream/kSand/kLine, radius 12 |
| B3-08 | Bookmark properties | ✅ | `white→kCream` card backgrounds |

### B3.3 — Profile & Safety

| ID | Task | Status | Screens |
|---|---|---|---|
| B3-09 | Renter profile | ✅ | `white→kCream`, `grey→kLine` borders |
| B3-10 | Safety screen | ✅ | Already correct via B1 token migration — `kprimaryColor`/`kscaffoldColor` = indigo/cream |

### B3.4 — Common Screens & Widgets

| ID | Task | Status | Screens |
|---|---|---|---|
| B3-11 | Auth screens (common) | ✅ | `basic_info_screen` — kCream, kLine, fixed import |
| B3-12 | Price negotiation chrome | ✅ | Uses `theme.primaryColor` — auto B1; gradient already indigo |
| B3-13 | Shared widgets | ✅ | `hotel_card`, `product_card`, `cart_tile` — radius/shadow/cream |

### B3.5 — Polish Rules Applied

| ID | Polish Rule | Status |
|---|---|---|
| B3-14 | Card: `BorderRadius.circular(16)`, `BorderSide(color: kLine)`, soft elevation | ✅ |
| B3-15 | Buttons/fields: `BorderRadius.circular(12)` | ✅ |
| B3-16 | Primary `ElevatedButton`: indigo fill + cream text | ✅ |
| B3-17 | Hero CTA clay fill | ⬜ | Logged in REDESIGN_OPEN_QUESTIONS — needs JSX-like restructure |
| B3-18 | Verified badge: success-green pill | ✅ | `view_property_all_reviews_page` — kSuccess bg + kCream text, radius 999 |
| B3-19 | New/Featured badge: clay | ✅ | `pre_booking_card`, bookmark, carousel — Luxury+Guest Favorite → kClay pill |

### B3.6 — Verification

| ID | Task | Status |
|---|---|---|
| B3-20 | Walk renter flow in LIGHT mode: Home → Details → Checkout → Confirmation | ⬜ | **Manual — verify on device** |
| B3-21 | Walk renter flow in DARK mode: same path | ⬜ | **Manual — verify on device** |
| B3-22 | `flutter analyze` — 1531 (≤ baseline, zero new from our changes) | ✅ | |
| B3-23 | Commits `4b29d8a` + `74e7e80` | ✅ | |

**Checkpoint:** Renter funnel works in both themes.

---

## Phase B4 — Host Screens (Palette Only)

| ID | Task | Status | Screens |
|---|---|---|---|
| B4-01 | Host home / dashboard | ⬜ | `lib/ui/screens_host/home/` |
| B4-02 | Add property | ⬜ | `lib/ui/screens_host/add_property/` |
| B4-03 | Update property | ⬜ | `lib/ui/screens_host/update_property/` |
| B4-04 | Property details (host view) | ⬜ | `lib/ui/screens_host/property_details/` |
| B4-05 | Booking history (host) | ⬜ | `lib/ui/screens_host/booking_history/` |
| B4-06 | Ongoing booking (host) | ⬜ | `lib/ui/screens_host/ongoing_booking/` |
| B4-07 | Payout screen | ⬜ | `lib/ui/screens_host/payout/` |
| B4-08 | Invoices | ⬜ | `lib/ui/screens_host/invoices/` |
| B4-09 | Support | ⬜ | `lib/ui/screens_host/support/` |
| B4-10 | Host profile | ⬜ | `lib/ui/screens_host/profile/` |
| B4-11 | Verify light + dark for all host screens | ⬜ | Keep dense forms/tables legible — no sand-wash |
| B4-12 | Run `flutter analyze` — must be clean | ⬜ | |
| B4-13 | Commit: `style(mobile): B4 — host screens Sand & Indigo` | ⬜ | |

**Checkpoint:** Host flow renders correctly in both themes.

---

## Phase B5 — Mobile Cleanup & Verify

| ID | Task | Status |
|---|---|---|
| B5-01 | Grep `lib/` for any remaining brand pinks (`C14464`, `AD1457`, `6A1B4D`, `BF5973`) — expect zero | ⬜ |
| B5-02 | Run `flutter analyze` — must be clean | ⬜ |
| B5-03 | Run `flutter build apk --debug` — must compile | ⬜ |
| B5-04 | Manual walk: renter flow (light theme) | ⬜ |
| B5-05 | Manual walk: renter flow (dark theme) | ⬜ |
| B5-06 | Manual walk: host flow (light theme) | ⬜ |
| B5-07 | Manual walk: host flow (dark theme) | ⬜ |
| B5-08 | Confirm `lib/ui/unused_screens/` is not routed — skip if truly unused | ⬜ |
| B5-09 | Produce `REDESIGN_SUMMARY_MOBILE.md` | ⬜ |
| B5-10 | Final commit: `style(mobile): Part B complete — Sand & Indigo redesign` | ⬜ |

---

# Summary: Execution Order

| Order | Phase | Scope | Effort |
|---|---|---|---|
| 1 | **B0** | Mobile audit — no code changes | ~1 hr |
| 2 | **B1** | `constants.dart` + `theme_service.dart` — ~88 files flip instantly | ~30 min |
| 3 | **B2** | ~6 hardcoded pink files + ~11 gradient files | ~1 hr |
| 4 | **B3** | Renter screens + shared widgets (polish pass) | ~3–4 hrs |
| 5 | **B4** | Host screens (palette only) | ~2 hrs |
| 6 | **B5** | Cleanup, build verify, summary doc | ~1 hr |
| 7 | **A0** | Web audit — no code changes | ~1 hr |
| 8 | **A1–A2** | Web tokens + centralized surfaces | ~1 hr |
| 9 | **A3** | Customer-facing pages (biggest batch) | ~4–5 hrs |
| 10 | **A4** | Admin/host panels | ~2 hrs |
| 11 | **A5** | Polish sweep (concurrent with A3–A4) | — |
| 12 | **A6** | Web cleanup, verify, summary doc | ~1 hr |

---

## Open Questions Log

> Anything ambiguous or logic-adjacent goes here. Never guess — log and move on.

*See `REDESIGN_OPEN_QUESTIONS.md` for running list.*

---

*Last updated: 30 May 2026 — B0 ✅ B1 ✅ B2 ✅ B3 ✅ (B3-20/21 need device walk — manual only) — Next: Phase B4*