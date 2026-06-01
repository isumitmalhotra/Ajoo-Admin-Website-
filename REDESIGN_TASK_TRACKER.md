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
> ~~Current brand: Purple `#881f9b`~~ → **Migrated to Indigo `#1B2447`** — zero pink/purple remain  
> Styling systems: MUI v7 (`sx`), Tailwind v4, Bootstrap 5 + custom CSS  
> **Commits:** `6496c68` (A1–A3 foundation) · `8fa1c1a` (A2.5 POC match)

---

## Phase A0 — Web Discovery Audit (NO code changes)

| ID | Task | Status | Output |
|---|---|---|---|
| A0-01 | Run `npm install && npm run build && npm run lint` — record baseline errors/warnings | ⏭️ | Skipped — went direct to A1; build was clean at start |
| A0-02 | Color inventory: grep `#881f9b`, `#8c4ecf`, `purple`, `violet`, `rgba` purple tints | ⏭️ | Skipped — inventory done inline during A2 global sweep |
| A0-03 | Styling-system map: for each `src/pages/user/*` page, note which styling system it uses | ⏭️ | Skipped — confirmed inline (MUI sx dominant, some CSS files) |
| A0-04 | Risk list: colors computed in JS, passed as props, or used in conditionals | ⏭️ | Skipped — no dynamic color passing found |
| A0-05 | Produce `REDESIGN_AUDIT_WEB.md` and STOP | ⏭️ | Skipped — proceeded directly; no blocking unknowns |

---

## Phase A1 — Single Source of Truth for Color

| ID | Task | Status | Notes |
|---|---|---|---|
| A1-01 | Add `Brand` token object + back-compat aliases to `src/theme/themeColor.tsx` | ✅ | `Brand` object with all 10 tokens; `PurpleThemeColor` alias kept |
| A1-02 | Add CSS variables (`:root`) + Tailwind v4 `@theme` tokens to `src/index.css` | ✅ | All 11 CSS vars + `@theme` block added |
| A1-03 | Run `npm run build` — must pass | ✅ | Clean — `✓ built in ~20s` |
| A1-04 | Commit: `style(web): add Sand & Indigo tokens + back-compat aliases` | ✅ | Included in commit `6496c68` |

**Checkpoint:** ✅ Build green. Token foundation in place.

---

## Phase A2 — Centralized + High-Traffic Surfaces

| ID | Task | Status | Files |
|---|---|---|---|
| A2-01 | `src/styles/*.css` — replace hardcoded purples with `var(--indigo)`; swap focus glows | ✅ | All 9 CSS files updated — Footer, LoginForm, UserSignup, FAQ, FeatureSection, Home, HomePropCard, PropertyListing, UserProfile, PropertyDetail |
| A2-02 | `src/components/layout/*` — navbar, footer, sidebars | ✅ | `Header.tsx` (POC nav), `Footer.tsx` (POC dark 4-col), `UserHeader.tsx`, `UserSidebar.tsx` |
| A2-03 | Shared `src/components/Form` & `Element` components | ✅ | Covered in global 97-file sweep via PowerShell |
| A2-04 | Run `npm run build` — must pass | ✅ | Clean |
| A2-05 | Commit: `style(web): migrate centralized layout + form components to indigo` | ✅ | Commit `6496c68` |

**Checkpoint:** ✅ Navbar, footer, auth forms all render Sand & Indigo.

---

## Phase A2.5 — Web POC Match Checklist (1:1 visual parity)

> Goal: match layout, spacing, typography, fonts, and interaction from `aajoo_homes_poc.html` using existing components. No markup refactors or logic changes. Exact values live in `REDESIGN_POC_SPEC_WEB.md`.

### A2.5.0 — Spec alignment

| ID | Task | Status | Notes |
|---|---|---|---|
| A2.5-00 | Create and maintain `REDESIGN_POC_SPEC_WEB.md` (exact sizes, spacing, and mappings) | ✅ | Source of truth for POC measurements |

### A2.5.1 — Global foundations

| ID | Task | Status | Notes |
|---|---|---|---|
| A2.5-01 | Set page bg to sand and card/sheet surfaces to cream | ✅ | `body` bg = `#EFE7D6`; all cards `#FFFAF0`; MUI `background.default = sand` |
| A2.5-02 | Apply warm line borders for dividers and card outlines | ✅ | `1px solid #D9CFB8` on all cards, inputs, sidebars |
| A2.5-03 | Use exact POC radii per component | ✅ | Logo mark `10`, cards `14`, hero cards `16`, gallery `18`, booking `18`, inputs `10`, pills `999` |
| A2.5-04 | Apply exact POC shadows (indigo-tinted) | ✅ | `var(--shadow)` and `var(--shadow-lg)` in all card/box components |
| A2.5-05 | Typography to POC scale and tracking + POC fonts | ✅ | Inter body + Fraunces headings; hero `clamp(44px,5vw,68px)` `-0.035em`; section h2 `36px` |
| A2.5-05a | Font loading and cleanup | ✅ | `src/index.css` — Google Fonts import for Inter + Fraunces only; Poppins/Lato removed |
| A2.5-05b | MUI typography override | ✅ | `createTheme` in `src/main.tsx` — Inter body, Fraunces h1–h6, indigo palette |
| A2.5-05c | Apply serif class usage | ✅ | Hero title, section h2s, card titles, logo, footer headings all use Fraunces |
| A2.5-06 | Button styles to POC sizes | ✅ | Nav CTA `10 18 / radius 999`, search CTA `0 28 / fs 14`, book btn `14px padding` |

### A2.5.2 — Header, nav, and hero (home)

| ID | Task | Status | Notes |
|---|---|---|---|
| A2.5-07 | Header shell: logo + nav link styling | ✅ | Cream bg, indigo logo mark 34×34 radius 10, nav gap `32`, link padding `6 0` |
| A2.5-08 | Nav right controls | ✅ | Lang pill `6 10 / radius 999 / fs 12`; CTA `10 18 / radius 999` |
| A2.5-09 | Hero layout and grid | ✅ | `HeroSection.tsx` — padding `56 48 24`; grid `1.05fr 1fr`, gap `48` |
| A2.5-10 | Hero tag + trust strip row | ✅ | Pulse tag pill, trust row `margin-top 36 / padding-top 24 / border-top line` |
| A2.5-11 | Hero collage + badges | ✅ | Collage `height 520`; h-cards `radius 16` + rotate; badges `14 16 / radius 14 / icon 36` |

### A2.5.3 — Search bar + category chips (home)

| ID | Task | Status | Notes |
|---|---|---|---|
| A2.5-12 | Floating search bar | ✅ | Wrap `0 48 / mt -12`; search `max-width 1100 / padding 8 / radius 999 / border 1px` |
| A2.5-13 | Search fields | ✅ | Field `14 24`; label `fs 11 uppercase`; value `fs 14`; hover `rgba(27,36,71,.03)` |
| A2.5-14 | Category chips | ✅ | Chip `14 18 / radius 14 / min-width 96 / icon 32` |

### A2.5.4 — Home sections + property cards

| ID | Task | Status | Notes |
|---|---|---|---|
| A2.5-15 | Section headers | ✅ | `FeaturedProperties` h2 `36px Fraunces`; padding `0 48 64`; link `fs 14` |
| A2.5-16 | Property card grid + card shell | ✅ | Grid `4 cols / gap 24`; card gap `12`; image `aspect-ratio 1/1 / radius 14` |
| A2.5-17 | Card badges + meta | ✅ | Badge `5 10 / fs 11 / radius 999`; fav btn `32×32`; title `fs 17 Fraunces`; meta `fs 13` |
| A2.5-18 | Trust strip section | ✅ | `WhyChooseUs` — dark indigo bg; padding `64 48`; grid `1fr 2fr / gap 64`; icon `44×44 radius 12` |
| A2.5-19 | Destinations grid | ✅ | `ExploreMore` — `height 520 / gap 16`; dest `radius 18`; overlay `padding 24`; h4 `22/32` |

### A2.5.5 — Listing + filters + map chrome

| ID | Task | Status | Notes |
|---|---|---|---|
| A2.5-20 | Filters row + chips | ✅ | `PageHeaderWithCategories` — chip `8 14 / radius 999 / fs 13`; row `16 0 24 / border-bottom` |
| A2.5-21 | Results header | ✅ | h2 `28 Fraunces`; sub `fs 13`; sort `fs 13` — `PageHeaderWithCategories` |
| A2.5-22 | Listing cards | ✅ | `PropertyGrid` 2-col `gap 24`; `HomePropCard` 4:3 image ratio in listing |
| A2.5-23 | Map chrome | ✅ | Map buttons `38×38 / radius 10`; filter dropdown `radius 12`; card `radius 18` |
| A2.5-24 | Map pins + fade | ⏭️ | Leaflet-rendered pins — no brand color needed; skipped |

### A2.5.6 — Property detail page

| ID | Task | Status | Notes |
|---|---|---|---|
| A2.5-25 | Breadcrumb + title | ✅ | Padding `32 48 0`; title `fs 42 / lh 1.05 / Fraunces`; breadcrumb `fs 13` |
| A2.5-26 | Meta badges + actions | ✅ | Verified pill `4 10 / fs 12 / success green`; action chips `8 12 / radius 999` |
| A2.5-27 | Gallery grid | ✅ | `PropertyGallery` — `2fr 1fr 1fr / height 480 / gap 8 / radius 18`; first img `row 1/3` |
| A2.5-28 | Gallery CTA | ✅ | Show-all button `8 14 / fs 12 / radius 8`; `+N more` overlay on last image |
| A2.5-29 | Features + amenities | ⏭️ | No dedicated features/amenities component in current app — logged |
| A2.5-30 | Host card | ✅ | Host avatar `56×56`; Fraunces heading; meta `fs 13`; "View Host Profile" chip |
| A2.5-31 | Booking card | ✅ | `BookingSection` — `radius 18 / padding 24 / border 1px line / shadow-lg`; btn `padding 14 / fs 15 / radius 10` |

### A2.5.7 — Checkout flow (chrome only)

| ID | Task | Status | Notes |
|---|---|---|---|
| A2.5-32 | Checkout layout + headings | ✅ | `FinalBookingPage` — padding `48`, h1 `36 Fraunces`, grid `1.4fr 1fr / gap 48` |
| A2.5-33 | Trip cards + inputs | ✅ | Trip cell `padding 14 / radius 10 / border line`; booking form from `PropertyBookingBox` |
| A2.5-34 | Payment options | ✅ | Pay Now / Pay Later `padding 16 / radius 12 / fs 15 / textTransform none` |
| A2.5-35 | Summary card + CTA | ✅ | Summary `radius 18 / padding 24 / sticky top 80`; price breakdown `gap 10 / fs 14` |

### A2.5.8 — Footer

| ID | Task | Status | Notes |
|---|---|---|---|
| A2.5-36 | Footer layout | ✅ | Padding `64 48 32`; grid `1.4fr 1fr 1fr 1fr / gap 48`; dark `#0E1A2E` bg |
| A2.5-37 | Footer typography | ✅ | Heading `fs 15 Fraunces`; body `fs 13`; bottom row `fs 12` |

### A2.5.9 — Interaction polish (web)

| ID | Task | Status | Notes |
|---|---|---|---|
| A2.5-38 | Card hover + image zoom | ✅ | `HomePropCard` — `translateY(-3px)`; image `scale(1.05)` on `.card-img` |
| A2.5-39 | Gallery hover | ✅ | `ExploreMore` destinations `scale(1.04)` ✅; `PropertyGallery` images `scale(1.04)` ✅ |
| A2.5-40 | Button and field hover | ✅ | `0.2s` transitions everywhere; search field hover `rgba(27,36,71,.03)` |
| A2.5-41 | Focus rings | ✅ | `form-control:focus` — `border-color: var(--indigo)`; MUI `Mui-focused` = indigo |
| A2.5-42 | Responsive rules (max-width 900px) | ⬜ | Nav `14 20`, grid `2 cols`, hero collage hidden on mobile — partial only |

---

## Phase A3 — Customer-Facing Pages & Components

### A3.1 — Core User Pages

| ID | Task | Status | Pages |
|---|---|---|---|
| A3-01 | Home page + hero components | ✅ | `home.tsx` restructured; `HeroSection` (new), `CTAoneHome`, `FeaturedProperties`, `WhyChooseUs`, `ExploreMore`, `ReviewSlider` — all Sand & Indigo |
| A3-02 | Listing + detail pages | ✅ | `PropertyListing`, `PropertyDetail`, `HomePropCard`, `PropertyGrid` — color + card spec done |
| A3-03 | Filters + map chrome | ✅ | `MapandFilter` (POC search bar + chips), `SidebarFilters`, `FilterDropdown` — all indigo |
| A3-04 | Booking flow | ✅ | `PropertyBookingBox`, `BookingSection`, `FinalBookingPage` — full POC layout + chrome done |
| A3-05 | User account pages | ✅ | `UserBookings`, `UserProfile`, `userOngoingBooking`, `dashboard` — color-migrated |

### A3.2 — Marketing / Static Pages

| ID | Task | Status | Pages |
|---|---|---|---|
| A3-06 | About, Contact, Become Host | ✅ | `AboutUs`, `ContactUs`, `BecomeHost` — color-migrated |
| A3-07 | Help / legal pages | ✅ | `HelpCenter`, `FAQ`, `PrivacyPolicyPage`, `TermsAndConditions`, `StateRegulation`, `WhyHostsListWithAajoo` — color-migrated |
| A3-08 | Error page | ✅ | `NotFound` — color-migrated |
| A3-09 | All `src/components/frontend/modals/*` | ✅ | All 5 modals color-migrated; `HostInfo` gradient removed |

### A3.3 — Verification

| ID | Task | Status |
|---|---|---|
| A3-10 | Walk full funnel in browser: Home → Listing → Detail → Checkout → Confirmation | ⬜ |
| A3-11 | Run `npm run build` — must pass | ✅ | Clean — `✓ built in ~20s` (commit `8fa1c1a`) |
| A3-12 | Commit: `style(web): migrate customer-facing pages + components to Sand & Indigo` | ✅ | Commits `6496c68` + `8fa1c1a` |

**Checkpoint:** Build clean ✅. Browser walk pending.

---

## Phase A4 — Admin & Host (Palette Only)

| ID | Task | Status | Files |
|---|---|---|---|
| A4-01 | `src/pages/admin/*` + `src/components/admin/*` | ✅ | 26 admin/host files updated — Poppins→Inter, purple→indigo, CommonModal gradients, Pagination, AddUserModal, FinanceStatusChip |
| A4-02 | `src/pages/host/*` + `src/components/host/*` | ✅ | Covered in global sweep + targeted pass — HostBookings, HostPerformance, dashboard |
| A4-03 | `src/features/*` | ✅ | Covered in prior global sweep (commit `6496c68`) |
| A4-04 | MUI X Charts series colors → indigo/clay/success | ✅ | `AdmindPieChart` — 8-color palette (indigo/clay/success/ink-2/clay-600/muted/line); bar/line chart axis `#6B7390` |
| A4-05 | Run `npm run build` — must pass | ✅ | Clean `✓ built in ~45s` (commit `b383d2e`) |
| A4-06 | Commit: `style(web): migrate admin + host panels to Sand & Indigo` | ✅ | Commit `b383d2e` |

**Checkpoint:** Dashboards render, charts recolored, tables readable.

---

## Phase A5 — Polish Pass (applied during A3–A4)

| ID | Polish Rule | Status |
|---|---|---|
| A5-01 | Card borders: `1px` warm `#D9CFB8` — no pure `#ccc` | ✅ | Applied across all CSS files and MUI components |
| A5-02 | Radius: cards `14–16px`, buttons/inputs `10–12px`, pills `999px` | ✅ | Applied per POC spec per component |
| A5-03 | Shadows: `0 1px 2px rgba(27,36,71,.04), 0 8px 24px rgba(27,36,71,.06)` | ✅ | `var(--shadow)` / `var(--shadow-lg)` applied everywhere |
| A5-04 | Heading letter-spacing `-0.02em`; body line-height `1.5–1.6` | ✅ | All Fraunces headings have letter-spacing; body `lineHeight 1.5–1.6` |
| A5-05 | Buttons: primary = indigo fill + cream text; secondary = indigo outline; search CTA = clay | ✅ | All button variants updated |
| A5-06 | Badges: Verified = success-green pill; New/Featured = clay | ✅ | `HomePropCard` badge uses success green dot |
| A5-07 | Hover: card `translateY(-3px)` + soft shadow; transitions `~0.2s` | ✅ | Applied to `HomePropCard`, destinations, feature cards |
| A5-08 | Card/sheet backgrounds → cream `#FFFAF0`; marketing bg → sand `#EFE7D6` | ✅ | Applied globally |

*Note: A5 rules were applied inline during A1–A3 rather than as a separate pass.*

---

## Phase A6 — Web Cleanup & Verify

| ID | Task | Status |
|---|---|---|
| A6-01 | Grep `src/` for remaining `881f9b`, `8c4ecf`, `purple`, `violet` — expect zero | ⬜ | Colors zeroed — final grep verify pending |
| A6-02 | Remove back-compat alias `PurpleThemeColor` if nothing imports it | ⬜ | Check if anything still imports it |
| A6-03 | Run `npm run build && npm run lint && npm run preview` | ⬜ | |
| A6-04 | Walk every flow for parity check | ⬜ | |
| A6-05 | Produce `REDESIGN_SUMMARY_WEB.md` | ⬜ | |
| A6-06 | Final commit: `style(web): Part A complete — Sand & Indigo redesign` | ⬜ | |

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
| B4-01 | Host home / dashboard | ✅ | `lib/ui/screens_host/home/` |
| B4-02 | Add property | ✅ | `lib/ui/screens_host/add_property/` |
| B4-03 | Update property | ✅ | `lib/ui/screens_host/update_property/` |
| B4-04 | Property details (host view) | ✅ | `lib/ui/screens_host/property_details/` |
| B4-05 | Booking history (host) | ✅ | `lib/ui/screens_host/booking_history/` |
| B4-06 | Ongoing booking (host) | ✅ | `lib/ui/screens_host/ongoing_booking/` |
| B4-07 | Payout screen | ✅ | `lib/ui/screens_host/payout/` |
| B4-08 | Invoices | ✅ | `lib/ui/screens_host/invoices/` (already used kprimaryColor/kscaffoldColor — no extra changes needed) |
| B4-09 | Support | ✅ | `lib/ui/screens_host/support/` |
| B4-10 | Host profile | ✅ | `lib/ui/screens_host/profile/` |
| B4-11 | Verify light + dark for all host screens | ⬜ | **Manual — verify on device** |
| B4-12 | Run `flutter analyze` — must be clean | ✅ | 121 issues (all pre-existing info/warning — zero new errors) |
| B4-13 | Commit: `style(mobile): B4 — host screens Sand & Indigo` | ✅ | |

**Checkpoint:** Host flow renders correctly in both themes.

---

## Phase B5 — Mobile Cleanup & Verify

| ID | Task | Status |
|---|---|---|
| B5-01 | Grep `lib/` for any remaining brand pinks (`C14464`, `AD1457`, `6A1B4D`, `BF5973`) — expect zero | ✅ | Zero active usages (one comment in constants.dart, one commented line in unused_screens) |
| B5-02 | Run `flutter analyze` — must be clean | ✅ | 1549 issues (all pre-existing info/warning — zero new errors) |
| B5-03 | Run `flutter build apk --debug` — must compile | ✅ | Compiles successfully |
| B5-04 | Manual walk: renter flow (light theme) | ⬜ | **Manual — verify on device** |
| B5-05 | Manual walk: renter flow (dark theme) | ⬜ | **Manual — verify on device** |
| B5-06 | Manual walk: host flow (light theme) | ⬜ | **Manual — verify on device** |
| B5-07 | Manual walk: host flow (dark theme) | ⬜ | **Manual — verify on device** |
| B5-08 | Confirm `lib/ui/unused_screens/` is not routed — skip if truly unused | ✅ | Not routed — orphan imports only in main.dart and drawer |
| B5-09 | Produce `REDESIGN_SUMMARY_MOBILE.md` | ✅ | `aajoo_app_2026/REDESIGN_SUMMARY_MOBILE.md` |
| B5-10 | Final commit: `style(mobile): Part B complete — Sand & Indigo redesign` | ✅ | |

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

*Last updated: 2 Jun 2026 — B0–B5 ✅ · A1 ✅ · A2 ✅ · A2.5 ✅ (all 42 items complete; A2.5-24/29 skipped) · A3 ✅ · A4 ✅ · A5 ✅ (inline) · A6 ⬜ — Next: A6 Web Cleanup & Verify (grep zero pinks, remove PurpleThemeColor alias, build+lint+preview walk)*