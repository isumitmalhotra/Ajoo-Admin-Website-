# AajooHomes Redesign — Live Context Handoff

> **Read this whole file before touching anything.** This is the single source of truth for the in-progress Sand & Indigo redesign across web (`src/`) and mobile (`aajoo_app_2026/`). It captures every change made so far, every change still pending, every guardrail, every gotcha. If you are a fresh Claude session being briefed, you do not need to read any other doc to get up to speed — but you should cross-reference `REDESIGN_BRIEF.md`, `REDESIGN_POC_SPEC_WEB.md`, `REDESIGN_TASK_TRACKER.md`, and `aajoo_homes_poc.html` for the original spec.

**Last updated:** 2026-06-03 (M3 + M4 + M5 + M6 + M7 + M8 + M9-01 landed; M9-02 deferred — see §7)
**Workspace:** `D:\Projects\ajoo admin website\` (Windows + PowerShell)
**Operator:** Sumit (sumit.m@zyphextech.com), Zyphex Tech, for AajooHomes Pvt Ltd

---

## 0. How to use this file

**If you are picking up mid-flight:**
1. Read §1 (mission), §2 (repo shape), §3 (design tokens), §6 (current state), §7 (next task) in order.
2. Run `git status` to see what's on disk. Verify it matches §6.
3. Pick up the next pending task in §7 (currently **M3** — see *Next up*).
4. **Never commit or push** unless the operator explicitly asks. They review every change before commit.
5. After each task, append a "✅ Completed [task ID]" entry to §5 with date + files touched.

**If you are the operator returning:**
- §6 tells you exactly which files are dirty and why.
- §7 shows what's done and what's queued.

---

## 1. Mission

Migrate the **AajooHomes** product (web + Android Flutter) from its legacy purple/pink branding to the **Sand & Indigo** palette (client-approved Option 3), and match the visual language of the design POC (`aajoo_homes_poc.html`). This is primarily a **visual re-skin** — no logic, routing, API, or dependency changes — with a handful of small **feature additions** (interactive listing map, become-a-host page, mobile UI restructure) the operator has explicitly approved.

Indigo `#1B2447` is the new brand color for both platforms — it replaced purple `#881f9b` on web and pink `#C14464` on mobile.

---

## 2. Repo shape

| Folder | Stack | Touch? |
|---|---|---|
| `src/` | **Web app** — React 19 + TypeScript + Vite + MUI v7 + Tailwind v4 | ✅ Redesign |
| `aajoo_app_2026/` | **Mobile app** — Flutter (Dart) + GetX + Material 3, light + dark themes | ✅ Redesign |
| `aajooBackend-2026/` | **Backend** — Node/Express, port 8080 (runs `npm run dev`) | ❌ Never touch |
| `aajoo_homes-main/` | Old mobile folder (deleted in working tree). Brief references it; ignore. | ❌ |

### Web entry points
- Routes: `src/App.tsx`
- Theme tokens: `src/theme/themeColor.tsx`, `src/index.css` (CSS vars + Tailwind `@theme`)
- Customer pages: `src/pages/user/*`
- Components: `src/components/frontend/*`, `src/components/layout/*` (Header, Footer)
- Admin: `src/pages/admin/*`
- Host portal: `src/pages/host/*`
- Page barrel export: `src/pages/index.ts`

### Mobile entry points
- Tokens: `aajoo_app_2026/lib/constants.dart`
- Theme: `aajoo_app_2026/lib/service/theme_service.dart` (light + dark)
- Font helpers: `aajoo_app_2026/lib/utils/fonts.dart`
- Renter home: `aajoo_app_2026/lib/ui/screens_renter/home/homescreen.dart`
- Renter property detail: `aajoo_app_2026/lib/ui/screens_renter/property_details/property_page.dart`
- Renter components dir: `aajoo_app_2026/lib/ui/screens_renter/home/components/`
- Host screens: `aajoo_app_2026/lib/ui/screens_host/*`
- Common screens: `aajoo_app_2026/lib/ui/screens_common/*`

---

## 3. Sand & Indigo design tokens (source of truth)

Identical across web and mobile.

| Token | Hex | Web (CSS var / Brand obj) | Mobile (Dart const) | Role |
|---|---|---|---|---|
| **indigo** (primary) | `#1B2447` | `--indigo` / `Brand.indigo` | `kIndigo` / `kprimaryColor` | Primary brand, headings, primary buttons, key text |
| indigo-600 (hover) | `#2A356B` | `--indigo-600` / `Brand.indigo600` | `kIndigo600` | Hover/pressed state |
| **sand** (warm bg) | `#EFE7D6` | `--sand` / `Brand.sand` | `kSand` / `kcontentColor` | Warm marketing/content bg |
| **cream** (surface) | `#FFFAF0` | `--cream` / `Brand.cream` | `kCream` / `kscaffoldColor` | Card / sheet / surface bg |
| **clay** (accent) | `#C16345` | `--clay` / `Brand.clay` | `kClay` | One pop-CTA per screen, "New" badges |
| clay-600 | `#A8512F` | `--clay-600` / `Brand.clay600` | `kClay600` | Clay hover |
| ink (text) | `#1B2447` | `--ink` / `Brand.ink` | `kInk` | Primary text |
| ink-2 | `#3D4670` | `--ink-2` / `Brand.ink2` | `kInk2` | Secondary text |
| muted | `#6B7390` | `--muted` / `Brand.muted` | `kMuted` | Captions, placeholders, axis labels |
| **line** (border) | `#D9CFB8` | `--line` / `Brand.line` | `kLine` | Warm borders, dividers |
| success | `#3F6B4E` | `--success` / `Brand.success` | `kSuccess` | Verified badges |
| danger | `#C0392B` | `--danger` / `Brand.danger` | `kDanger` | Error-only |

**Radius scale:** cards `14–16`, buttons/inputs/fields `10–12`, pills/chips `999`.
**Shadow:** `0 1px 2px rgba(27,36,71,.04), 0 8px 24px rgba(27,36,71,.06)` (cards) / `0 12px 40px rgba(27,36,71,.12)` (booking, search, modals).
**Typography pairing (POC):** Fraunces (serif) for headings + brand wordmark, Inter (sans) for body and UI.

---

## 4. Guardrails (non-negotiable)

1. **No behavior changes.** No edits to handlers, state, lifecycle, data fetching, props/params, navigation/routing, form submission, validation, or business logic. **Exception:** the operator has approved 3 feature additions — `/become-a-host` route wire-up, listing+map split screen, and the mobile UI restructure (M1–M9).
2. **No dependency changes** unless the operator explicitly asks. Work within what's installed.
3. **No file moves/renames/deletions** of existing files (you may add new files).
4. **Preserve every** `id`, `name`, `key`, `data-*`, `aria-*`, `role`, semantic label, and any class/identifier referenced from logic or tests.
5. **Payments are radioactive.** Web `RazorpayPayment.tsx` + checkout, Flutter `checkout/` flow: restyle chrome only, never touch payment handlers.
6. **Maps:** restyle chrome (buttons, tooltips, pulse color) only. Never touch marker logic, coordinates, clustering, map data.
7. **Builds stay green.** Web: `npm run build` must pass. Mobile: `flutter analyze` must not add new errors and `flutter build apk --debug` must compile.
8. **Dark mode (mobile)** must look correct in both light and dark.
9. **NEVER COMMIT, NEVER PUSH** unless the operator says so. Everything goes into the working tree and waits for them to review.
10. **Use design tokens** (`Brand.*` / CSS vars on web, `k*` consts on mobile), not raw hex codes.

---

## 5. Completed work log

In chronological order. Files listed are the ones touched.

### Phase 0 — Mobile-redesign restoration (uncommitted in working tree)

The Sand & Indigo redesign for the mobile app was **committed** earlier (commits `72dcfab` `87d41a5` `4b29d8a` `74e7e80` `2a00d4c` `3809d12` `36edaee`), but a later working-tree state had **systematically reverted** the tokens in ~37 mobile files while doing unrelated business-logic edits (Skip-flow rollback, lint cleanups). The first task was to selectively restore the redesign tokens without losing the unrelated edits.

**Files restored (37 mobile files):**

| File | What was restored |
|---|---|
| `aajoo_app_2026/lib/service/theme_service.dart` | Indigo seed `0xFF1B2447` in light + dark; primaryColor → kprimaryColor; dark-mode body text → `Colors.white`; cardColor → kCream |
| `aajoo_app_2026/lib/ui/screens_host/payout/payout_page.dart` | kCream/kIndigo600/kInk/kSuccess/kDanger restored across history tiles + snackbars |
| `aajoo_app_2026/lib/ui/screens_host/payout/components/plan_overview_card.dart` | `_cardBgColor = kCream`, `_titleColor = kIndigo600`, `_textColor = kInk` (was `0xFFF6D1DC`/`0xFF6A1B4D`/`0xFF4A2C35`) |
| `aajoo_app_2026/lib/ui/screens_renter/property_details/property_page.dart` | 13× `Color(0xFFAD1457)` → `kIndigo` (via two `replace_all`) |
| `aajoo_app_2026/lib/widgets/hotel_card.dart` | Re-added `import constants.dart` |
| `aajoo_app_2026/lib/widgets/product_card.dart` | `Colors.white` → `kCream`, added `BorderSide(color: kLine)`, restored indigo-tinted shadow, radius 16 |
| `aajoo_app_2026/lib/widgets/cart_tile.dart` | `Colors.white` → `kCream`, added `Border.all(color: kLine)`, radius 16 |
| `aajoo_app_2026/lib/ui/screens_host/profile/host_profile.dart` | `Colors.grey[200]` → `kSand`, `Colors.grey[400]` → `kLine`, `Colors.grey` → `kMuted`, `kCream`/`kInk2`/`kInk` restored throughout; fixed leading-space typo on cupertino import |
| `aajoo_app_2026/lib/ui/screens_host/home/components/host_recent_transaction_item_view.dart` | `Colors.green` → `kSuccess`, `Colors.red` → `kDanger` |
| `aajoo_app_2026/lib/ui/screens_host/home/components/host_home_shimmer.dart` | Re-added constants import, baseColor/highlightColor → kLine/kCream |
| `aajoo_app_2026/lib/ui/screens_host/add_property/host_property_listing_screen.dart` | kSand/kInk/kCream/kLine/kSuccess/kDanger restored across chips + buttons + Terms section |
| `aajoo_app_2026/lib/ui/screens_host/booking_history/booking_history_screen.dart` | `Colors.grey`/`Colors.white`/`Colors.black.withOpacity`/`Colors.red`/`Colors.green` → kSand/kCream/kInk/kDanger/kSuccess (10 sites) |
| `aajoo_app_2026/lib/ui/screens_host/ongoing_booking/view_ongoing_booking_page.dart` | kCream + kSuccess + kMuted restored (6 sites) |
| `aajoo_app_2026/lib/ui/screens_host/property_details/view_host_property_details.dart` | kscaffoldColor + kSand + kMuted + kInk2 + kSuccess + kDanger restored |
| `aajoo_app_2026/lib/ui/screens_host/support/host_support_screen.dart` | kLine + kInk.withOpacity(0.04) shadow + kMuted + kInk restored across 3 contact cards + FAQ tiles. **Also re-added the deleted `late StaticPageController _staticPageController;` field that was causing a real compile error** |
| `aajoo_app_2026/lib/ui/screens_renter/history/components/booking_cart.dart` | kCream + kLine + kSand restored, radius 12 (button) |
| `aajoo_app_2026/lib/ui/screens_renter/history/history_description/review/all_reviews_list/view_property_all_reviews_page.dart` | Verified-stay pill restored to kSuccess BG + kCream text + radius 999 |
| `aajoo_app_2026/lib/ui/screens_renter/home/homescreen.dart` | Major restoration: re-added `import constants.dart`, kCream sheet bg, indigo-tinted bottom shadow, kLine drag handle, kCream foregroundColor on Pre-Booking button, kCream + kLine review-list container, hotel-selector active/inactive states with kCream + kLine borders |
| `aajoo_app_2026/lib/ui/screens_renter/nearby_bookings/pre_booking_screen.dart` | Re-added constants import, kCream for AppBar bg + shimmer items |
| `aajoo_app_2026/lib/ui/screens_renter/profile/profile_screen.dart` | kCream bg restored across 3 bottom sheets + Verified text + KYC icons + camera button (~10 sites); kLine borders restored on KYC dropzone + viewer |
| `aajoo_app_2026/lib/ui/screens_common/auth/basic_info/basic_info_screen.dart` | Re-added constants import, kCream restored across AppBar/progress indicator/step card; `Border.all(color: Colors.grey[300])` → `Border.all(color: kLine)` via `replace_all` (5 sites). **Important:** business-logic reverts (Skip-flow removal, per-step `signupData.addAll` removal) were **intentionally left alone** — those are not redesign tokens. |
| `aajoo_app_2026/lib/ui/screens_common/update_profile/update_profile_screen.dart` | kCream bottom-sheet bg + kLine document-viewer border restored |

**Verified:** `flutter analyze` → 743 issues (only 2 errors, both pre-existing in legacy unrouted `lib/screens/Host/host_support_screen.dart` — same `_staticPageController` bug but in a different copy of the file). No new errors introduced.

### Phase 1 — Web: become-a-host wire-up (GAP-01)

The `BecomeHost.tsx` page (677 lines, 3-step host onboarding wizard) already existed at `src/pages/user/BecomeHost.tsx` but was not exported or routed. The Header's "Become a Host" link (`navigate("/become-a-host")`) hit a 404.

**Files touched (2):**
- `src/pages/index.ts` — added `export { default as BecomeHost } from "./user/BecomeHost";`
- `src/App.tsx` — imported `BecomeHost`, added `<Route path="/become-a-host" element={<BecomeHost />} />` inside `CommonLayout`

**Verified:** `npm run build` → `✓ built in ~53s`, zero errors.

### Phase 2 — Web: interactive listing+map split screen (new feature)

The POC showed a search-results layout with cards on the left and an Airbnb-style map with price pins on the right. Never built before.

**Files touched (3):**

1. **NEW** `src/components/frontend/ListingMap.tsx` — Leaflet map with:
   - Custom price-pin markers (cream pill, indigo text by default; flips to indigo fill + cream text on hover/featured)
   - Compact INR labels (`₹18,400` / `₹2.5K` / `₹1.2L`)
   - Width heuristic on the icon wrapper (`max(60, label.length * 8.5 + 28)`) so the pill fits any price; `iconAnchor` set to `[width/2, height]` (bottom-center → pill sits ON the lat/lng)
   - +/− custom zoom controls (top-right) using `map.zoomIn()`/`zoomOut()`
   - "Search as I move the map" toggle pill (top-left) with custom indigo checkbox
   - `useMapEvents` listens for `moveend`/`zoomend`, fires `onMoveEnd(bounds)` only when toggle is ON
   - Auto-fits bounds to property cluster on initial mount
   - **Initial bug fixed mid-session:** first version used `iconSize: [0, 0]` which caused the pill to render with its top-left at the lat/lng (overflowing). Fixed by sizing the wrapper to the label + bottom-center anchor + `width:100%; height:100%; display:flex` on the inner pill so it fills the wrapper.

2. **EDIT** `src/pages/user/PropertyListing.tsx` — Refactored from sidebar+grid to 2-col split:
   - Desktop: `gridTemplateColumns: "1.15fr 1fr"`, right column is a sticky `position:sticky; top:88px; height:calc(100vh - 120px)` map
   - Mobile: view-toggle pill (List / Map) that swaps between full-width cards and full-height map
   - Filters moved to a `<Drawer>` opened via "All filters" pill at top (POC chip pattern)
   - Mock dataset: 12 properties clustered around Goa (`lat 15.4909, lng 73.8278`), each carrying `{id, lat, lng, price, ...}`
   - `visibleProperties` derived from `mapBounds.contains([lat, lng])` when `searchOnMove` is ON
   - Bidirectional hover sync (card ↔ pin) via `hoveredId` state
   - **Pin click → navigates to `/property/detail/{id}`** via `useNavigate()` (was originally just a scroll-to-card; fixed after operator feedback)

3. **EDIT** `src/index.css` — Added `.ajoo-price-pin` class block that strips Leaflet's default wrapper bg/border/shadow so only the inner pill renders.

**Verified:** `npm run build` → `✓ built in 43.49s`, zero TS errors.

### Phase 3 — Mobile: M1 + M2 of the POC-match plan (in progress, see §7)

**M1 — Fonts foundation (✅ done)**
- **NEW** `aajoo_app_2026/lib/utils/fonts.dart` — `fraunces()`, `inter()`, `interTextTheme()` helpers wrapping GoogleFonts with default `letterSpacing: -0.02` for tight POC-style headings
- **EDIT** `aajoo_app_2026/lib/service/theme_service.dart` — Removed unused `fontFamily: "Mon"`, swapped `GoogleFonts.latoTextTheme()` → `interTextTheme()` in both themes
- Verified: `flutter analyze` → 740 issues, 0 new errors

**M2 — Branded header + search pill (✅ done)**
- **NEW** `aajoo_app_2026/lib/ui/screens_renter/home/components/branded_header.dart` — Logo mark "A" (34×34 indigo gradient w/ shadow) + Fraunces wordmark "aajoo`homes`" (clay italic for "homes") + heart + profile icons (40×40 cream circles with kLine border)
- **NEW** `aajoo_app_2026/lib/ui/screens_renter/home/components/search_pill.dart` — Cream pill (radius 999, kLine border, soft shadow) with magnifier + bold location + muted details
- **EDIT** `aajoo_app_2026/lib/ui/screens_renter/home/homescreen.dart`:
  - Removed `appBar:` from Scaffold
  - Added `Positioned(top, left, right)` Column with `BrandedHeader` + 12px gap + `SearchPill` + 8px + existing `OngoingBookingWidget`
  - Wired: logo tap → drawer / heart → `BookmarkedPropertiesPage` / profile → `NotificationsScreen` / SearchPill → `showFilterDialog()` (with corrected `mapController.fetchProperties()` + `applyPriceFilter()` calls)
  - Deleted the 114-line dead `_renterHomeAppBar()` method
  - Removed `slanted_container.dart` import (no longer needed)
- Verified: `flutter analyze` → 741 issues, 0 new errors

**M3 — Weekly hero card (✅ done, 2026-06-03)**
- **NEW** `aajoo_app_2026/lib/ui/screens_renter/home/components/weekly_hero_card.dart` — Dark indigo gradient block (kIndigo → kIndigo600, topLeft → bottomRight), radius 18, padding 20, soft indigo shadow. Content: "THIS WEEK" overline (Inter 11/w600/cream-70%/1.5 tracking, uppercase) → two-line headline "1,240 verified homes." / "No booking fee." (Fraunces 22/w500/cream, height 1.2) → stat row with `Icons.north_east` + "18 new in Goa this week" (Inter 13/cream-85%). Constructor takes `(verifiedCount, newThisWeek, region)` with defaults `(1240, 18, "Goa")`; internal `_formattedVerified` adds thousands commas.
- **EDIT** `aajoo_app_2026/lib/ui/screens_renter/home/homescreen.dart`:
  - Added `import .../components/weekly_hero_card.dart`
  - Mounted inside the `DraggableScrollableSheet` builder, right after the drag handle, wrapped in `Padding(EdgeInsets.symmetric(vertical: 12))`
- Verified: `flutter analyze` → 741 issues, 0 new errors. New file flagged zero times.

**M4 — Text category pills (✅ done, 2026-06-03)**
- **NEW** `aajoo_app_2026/lib/ui/screens_renter/home/components/text_category_pills.dart` — Horizontal `ListView.separated` of text pills (height 40, gap 8). Pill: padding 16×10, radius 999, Inter 13/w500. Active = kIndigo fill + kCream text + soft indigo shadow. Inactive = kCream BG + kInk text + 1px kLine border. Default categories `["All", "Villas", "Heritage", "Beach", "Hills", "Apartments"]`. V1 purely visual — `selectedIndex` + `onChanged(int)`.
- **EDIT** `aajoo_app_2026/lib/ui/screens_renter/home/homescreen.dart`:
  - Added `import .../components/text_category_pills.dart`
  - Added `int _propertyType = 0;` state field
  - Mounted above the "Find Your Stay" carousel block (between `fetchNearByProperties` and the Obx), bracketed by 16px vertical spacers. `setState` toggles `_propertyType` — no filter wire-up (per §7 spec).
  - Existing image-based "Browse by Category" section left untouched (search-intent vs property-type, different concept).
- Verified: `flutter analyze` → 741 issues, 0 new errors.

**M5 — Curated for you + vertical cards (✅ done, 2026-06-03)**
- **NEW** `aajoo_app_2026/lib/ui/screens_renter/home/components/section_header.dart` — Reusable section heading: Fraunces 22/w500 title on left (kInk), optional `onSeeAll` callback rendering "See all →" link on right (Inter 13/w600 kIndigo + arrow icon).
- **NEW** `aajoo_app_2026/lib/ui/screens_renter/home/components/curated_card.dart` — Vertical property card. 16:10 image with `VERIFIED` pill (kSuccess dot + kCream BG + shadow, top-left) and heart (cream-92% circle, top-right). Below image: city overline (Inter 10 caps muted, 1.2 tracking), property name (Fraunces 15/w500/kInk), price+rating row (`₹18,400 /n` Inter bold + kMuted, star kClay + rating Inter 12 w600). Indian-style thousands commas (`_formattedPrice`). Image errors → kSand fallback.
- **EDIT** `aajoo_app_2026/lib/ui/screens_renter/home/homescreen.dart`:
  - Added 3 imports: `curated_card.dart`, `section_header.dart`, `property_details/property_page.dart`
  - Mounted a "Curated for you" section between TextCategoryPills and "Find Your Stay" — Obx-reactive, takes first 4 properties from `mapController.properties`, renders SectionHeader + `GridView.builder(crossAxisCount: 2, childAspectRatio: 0.72)` of CuratedCards. "See all →" pushes to `PreBookingScreen`. Card tap pushes to `PropertyPage` using the same arg mapping as `PreBookingHomeCarousel` (rating hardcoded "4.5", same as existing carousel).
  - Existing horizontal PreBookingHomeCarousel kept below as the "Find Your Stay" / Featured section.
- Verified: `flutter analyze` → 738 issues, 0 new errors (3 below baseline).

**M8 — Detail: sticky bottom book bar (✅ done, 2026-06-03)**
- **EDIT** `aajoo_app_2026/lib/ui/screens_renter/property_details/property_page.dart`:
  - Collapsed branch of `_buildBottomSheet()` (~line 179) fully replaced. New design: full-width `Container` with kCream BG, 1px kLine top border, soft indigo top shadow, `EdgeInsets.fromLTRB(16, 14, 16, 14 + safeArea.bottom)`.
    - Left: `Expanded` Column with `RichText` (Fraunces 20 w700 kInk `₹{currentPrice}` + Inter 13 kMuted ` /night`) on line 1, and Inter 12 kMuted `₹{currentPriceString} total · {n} night(s)` on line 2. Singular/plural handled.
    - Right: `ElevatedButton` Reserve — kClay fill / kCream label, radius 12, padding 24×14, Inter 15 w600, elevation 0. `onPressed: _toggleExpanded` so the existing booking-sheet animation/flow runs unchanged.
  - Outer `Positioned(bottom: 16, left: 16, right: 16)` wrapper at ~line 1280 changed to `Positioned(bottom: 0, left: 0, right: 0)` so the bar is flush to the screen edge.
  - `bookingController.isLoading` branch restyled to a kCream container with kIndigo `CircularProgressIndicator` (was an indigo `FloatingActionButton`) for consistency with the new bar chrome.
  - Expanded `SizeTransition` branch untouched — same booking form, same handler, same Razorpay wiring.
- Verified: `flutter analyze` → 738 issues. `flutter build apk --debug` → `√ Built app-debug.apk`.

**M7 — Detail: host card + amenity row (✅ done, 2026-06-03)**
- **NEW** `aajoo_app_2026/lib/widgets/host_card.dart` — Row with 48×48 circular avatar (kSand BG + kLine border, photo if `photoUrl` provided else first-letter Fraunces 20/w600 fallback) + kSuccess 18×18 check badge clipped over bottom-right corner (cream 2px ring). Right column stacks Fraunces 16/w500 `Hosted by [Name]` and Inter 13 kMuted tagline (default `"Superhost · Replies in 1 hr"`). `isVerified` toggles the check badge.
- **NEW** `aajoo_app_2026/lib/widgets/amenity_row.dart` — Horizontal `ListView.separated` of icon+label chips (24×24 icon kInk2 + Inter 12/w500 kInk2, 16px gaps, height 32). Static `_iconFor(label)` maps lowercase keywords to Material icons (`wifi/pool/ac/bed/park/tv/kitchen/pet/gym`...), unknown labels fall back to `Icons.check_circle_outline`. V1 defaults `['Pool', '4 BR', 'Wi-Fi', 'AC']`.
- **EDIT** `aajoo_app_2026/lib/ui/screens_renter/property_details/property_page.dart`:
  - Added imports: `widgets/host_card.dart`, `widgets/amenity_row.dart`
  - Mounted `HostCard(hostName: 'Aajoo Host')` immediately under the M6 meta row, then `AmenityRow(...)`, then a 1px `kLine` Divider, then the existing "Property Description" Text. AmenityRow source picks `widget.property.amenities.take(4)` if non-empty, otherwise the POC default `['Pool', '4 BR', 'Wi-Fi', 'AC']`.
  - Host name is hardcoded to `'Aajoo Host'` for V1 (Property model has no host name; the existing "Host Details" section lower in the page also uses a hardcoded avatar). Easy follow-up: wire to `_single?.user?.name` or the host endpoint once a host-fetch exists.
- Verified: `flutter analyze` → 738 issues.

**M9 — Verify + device walkthrough (M9-01 ✅, M9-02 deferred to operator, 2026-06-03)**
- **M9-01 ✅** — Final `flutter analyze` after all redesign work: **738 issues, 3 below the 741 baseline, zero new errors**. None of the new files (`weekly_hero_card.dart`, `text_category_pills.dart`, `section_header.dart`, `curated_card.dart`, `verified_pill.dart`, `host_card.dart`, `amenity_row.dart`) appear in the analyzer output. All `property_page.dart` lints are pre-existing async-context warnings (also present in the legacy `lib/screens/property_page.dart` copy). `flutter build apk --debug` → `√ Built build\app\outputs\flutter-apk\app-debug.apk` in ~114s. Kotlin Gradle Plugin deprecation warnings are pre-existing plugin issues, unrelated.
- **M9-02 ⚠️ deferred to operator** — Cannot execute the interactive emulator walk (Home → tap SearchPill → return → tap pill category → CuratedCard → Detail → confirm sticky book bar → tap Reserve, both light and dark themes) from inside this session. **Reason:** the backend API at `https://api.aajoohomes.com` returns `DEPLOYMENT_NOT_FOUND` (see §8), so login is blocked and the property data needed for the Home / Curated / Detail surfaces never loads. Recommended path:
    1. Resolve §8 backend issue (option A — local backend at `http://10.0.2.2:8080` — is the fastest) OR seed a local stub for `mapController.properties`.
    2. `flutter emulators --launch Pixel_10_Pro_2`
    3. `cd aajoo_app_2026 && flutter run -d emulator-5554`
    4. Walk the script in §7 → §9.

---

**M6 — Detail: header overlay + title meta (✅ done, 2026-06-03)**
- **NEW** `aajoo_app_2026/lib/widgets/verified_pill.dart` — Reusable pill: kSuccess dot (7px) + label (Inter 12/w600 kInk), kCream BG with kLine border, padding 10×5, radius 999. Default label `"Verified"`.
- **EDIT** `aajoo_app_2026/lib/ui/screens_renter/property_details/property_page.dart`:
  - Added imports: `utils/fonts.dart`, `widgets/verified_pill.dart`
  - **M6-01** — SliverAppBar (~line 1007) now uses `automaticallyImplyLeading: false`, `backgroundColor: kCream`, no `leading:` or `actions:`. The `FlexibleSpaceBar.background` is now a `Stack(fit: StackFit.expand)` containing the original `_higlightedPropertyImageHeaderSection` plus a `Positioned(top: padding.top + 12, left: 16, right: 16)` Row of back / share / heart floating buttons.
  - Helper methods `backFromScreen`, `sharePropertyIcon`, `savedIcon` restyled — now all return a shared `_floatingHeaderButton(...)` (40×40 cream-92% circle, kInk icon, soft indigo shadow). Bookmark icon switched to `favorite`/`favorite_outline` (kClay when active, kInk otherwise) to match POC heart aesthetic. All handlers (Navigator.pop / Share.share / BookmarkService) preserved verbatim.
  - **M6-02** — Title block (~line 1024) rewritten:
    - Inline bookmark `IconButton` removed (duplicates the floating heart in the overlay)
    - New `_buildPropertyTitle(String)` helper renders Fraunces 30/w500/kInk; if the name contains an em-dash `—` or ` - ` it splits into a tight `RichText` with the head in regular Fraunces and the tail in italic Fraunces w400/kInk2 (POC subtitle pattern, e.g. "Casa Branca  —  *heritage villa*")
    - Location row restyled: `Icons.location_on_outlined` (kMuted) + Inter 13 kMuted text (was deepOrangeAccent + grey)
    - New meta row added below title: `VerifiedPill` on left, star+rating chip on right (cream pill + kLine border, star kClay, Inter 12 w600 kInk). Uses existing `widget.rating` from PropertyPage args.
- Verified: `flutter analyze` → 738 issues, 0 new errors. All bookmark / share / navigation behavior unchanged.

---

## 6. Current working-tree state

**Branch:** whatever the operator was on when this started (likely `master`/`main`). No new branch was created.

**Nothing committed by Claude. Nothing pushed.** Everything below is sitting in the working tree, ready for the operator to review.

### Modified files

Run `git status --short` to see live state. Approximate list as of this snapshot:

```
 M REDESIGN_TASK_TRACKER.md        # docs updates from earlier
 M TASK_TRACKER.md                  # docs updates from earlier
 M src/App.tsx                      # +become-a-host route
 M src/pages/index.ts               # +BecomeHost export
 M src/pages/user/PropertyListing.tsx  # split-screen refactor
 M src/index.css                    # +.ajoo-price-pin reset
?? src/components/frontend/ListingMap.tsx   # new file
 M aajoo_app_2026/lib/service/theme_service.dart  # indigo seed + Inter
 M aajoo_app_2026/lib/ui/screens_renter/home/homescreen.dart  # M2 + Phase 0 restoration
?? aajoo_app_2026/lib/utils/fonts.dart   # M1 new helper
?? aajoo_app_2026/lib/ui/screens_renter/home/components/branded_header.dart  # M2 new
?? aajoo_app_2026/lib/ui/screens_renter/home/components/search_pill.dart   # M2 new
?? aajoo_app_2026/lib/ui/screens_renter/home/components/weekly_hero_card.dart  # M3 new
?? aajoo_app_2026/lib/ui/screens_renter/home/components/text_category_pills.dart  # M4 new
?? aajoo_app_2026/lib/ui/screens_renter/home/components/section_header.dart  # M5 new
?? aajoo_app_2026/lib/ui/screens_renter/home/components/curated_card.dart  # M5 new
?? aajoo_app_2026/lib/widgets/verified_pill.dart  # M6 new
?? aajoo_app_2026/lib/widgets/host_card.dart  # M7 new
?? aajoo_app_2026/lib/widgets/amenity_row.dart  # M7 new
 M aajoo_app_2026/lib/ui/screens_renter/property_details/property_page.dart  # M6 + M7 + M8
 M aajoo_app_2026/lib/ui/screens_host/...        # ~16 Phase-0 token restorations
 M aajoo_app_2026/lib/ui/screens_renter/...      # ~10 Phase-0 token restorations
 M aajoo_app_2026/lib/widgets/hotel_card.dart
 M aajoo_app_2026/lib/widgets/product_card.dart
 M aajoo_app_2026/lib/widgets/cart_tile.dart
 M aajoo_app_2026/lib/ui/screens_common/...     # 2 Phase-0 restorations
```

Plus untracked older files: `aajoo_app_2026/.fvmrc`, `.metadata`, `README.md`, several screenshots, etc. — not Claude's work.

---

## 7. Mobile redesign plan — M1 to M9

Phasing **(A) Visible-first** — the operator's choice. Order:

| # | ID | Title | Status |
|---|---|---|---|
| 1 | **M1** | Fonts foundation (Fraunces + Inter) | ✅ Done |
| 2 | **M2** | Home: branded header + search pill | ✅ Done |
| 3 | **M3** | Home: weekly hero card | ✅ Done |
| 4 | **M4** | Home: text category pills | ✅ Done (re-ordered ahead of M5 at operator's request) |
| 5 | **M5** | Home: Curated for you + vertical cards | ✅ Done |
| 6 | **M6** | Detail: header overlay + title meta | ✅ Done (pulled ahead of M8) |
| 7 | **M8** | Detail: sticky bottom book bar | ✅ Done |
| 8 | **M7** | Detail: host card + amenity row | ✅ Done |
| 9 | **M9** | Verify + device walkthrough | ✅ M9-01 done · ⚠️ M9-02 deferred (backend blocker) |

> **All static milestones are complete.** Only the interactive emulator QA pass (M9-02) is outstanding, and it's gated on the §8 backend deployment being restored.

### Done: M3 — Weekly hero card

**Goal:** Add the dark indigo gradient "1,240 verified homes. No booking fee." block shown in the POC mobile Home phone, between the SearchPill and the existing content.

**One step:**
- **M3-01** — Build `WeeklyHeroCard` widget at `aajoo_app_2026/lib/ui/screens_renter/home/components/weekly_hero_card.dart`:
  - `Container` with `LinearGradient(kIndigo → kIndigo600, topLeft → bottomRight)`
  - `borderRadius: BorderRadius.circular(18)`
  - Padding 20
  - Inside, a Column:
    - Overline: "THIS WEEK" — `inter(fontSize: 11, fontWeight: w600, color: kCream.withOpacity(0.7), letterSpacing: 1.5)` uppercase
    - Title: "1,240 verified homes." then "No booking fee." — `fraunces(fontSize: 22, fontWeight: w500, color: kCream, height: 1.2)`
    - 12px gap
    - Stat row: ↗ arrow icon + "18 new in Goa this week" — `inter(fontSize: 13, color: kCream.withOpacity(0.85))`
  - Optional `BoxShadow` for depth: `BoxShadow(color: kInk.withOpacity(0.15), blurRadius: 16, offset: Offset(0, 8))`
  - Constructor accepts `(int verifiedCount, int newThisWeek, String region)` — for V1 hardcode `(1240, 18, "Goa")`; later wire to `commonController` / API
- **Mount it** in `homescreen.dart` inside the `DraggableScrollableSheet` builder, right after the drag handle (line ~175 currently). Wrap with `Padding(EdgeInsets.symmetric(vertical: 8))`.

**Verify:** `flutter analyze` must stay ≤ 741 issues. Run on emulator and confirm the hero card appears at the top of the sheet when expanded.

### M5 — Curated for you section + vertical cards (3 steps)

- **M5-01** — `lib/ui/screens_renter/home/components/section_header.dart` — Fraunces h4 left + "See all →" link right
- **M5-02** — `lib/ui/screens_renter/home/components/curated_card.dart` — Vertical card with image (16:10 aspect, radius 14), `VERIFIED` pill in top-left of image (kSuccess dot + cream BG, radius 999), heart in top-right, location overline (Inter 11 caps muted), Fraunces h5 name, single bottom row with price `₹18,400` bold + ` /n` muted + star icon + rating
- **M5-03** — In `homescreen.dart` add a "Curated for you" section using SectionHeader + 2-col grid (`GridView.count(crossAxisCount: 2)` or `Wrap`) of CuratedCards. Wire to existing `mapController.properties`. Keep the existing horizontal `PreBookingHomeCarousel` below as a separate "Featured" section.

### M8 — Detail: sticky bottom book bar (1 step)

- Replace the existing `_buildBottomSheet()` collapsed branch in `aajoo_app_2026/lib/ui/screens_renter/property_details/property_page.dart` (~lines 177–230)
- New widget: `Positioned(bottom: 0, left: 0, right: 0)` with cream BG, 1px top border `kLine`, padding 16
- Left column: bold `₹18,400` (Fraunces 20) + ` /night` (Inter 13 muted) on first line, `₹57,700 total · 3 nights` (Inter 12 muted) on second line
- Right: clay `Reserve` button (kClay fill, kCream text, radius 12, padding 14×24, fs 15 weight 600)
- On press, keep the existing booking-sheet flow (call the same handler)

### M6 — Detail: header overlay + title meta (2 steps)

- **M6-01** — In `property_page.dart` SliverAppBar (~line 1007), replace `leading`/`actions` with a `Positioned(top:16, left:16, right:16)` floating row inside `FlexibleSpaceBar`. Each button is a 40×40 cream-90% circle with subtle shadow (back / share / heart icons).
- **M6-02** — Restyle title block (~line 1024–1042): use `fraunces(fontSize: 28-32, fontWeight: w500, color: kInk, letterSpacing: -0.02)` for property name; break the dash subtitle into a separate italic Fraunces em (e.g. `Casa Branca` + ` — heritage villa`). Below the title, add a meta row: `VerifiedPill` (kSuccess dot + "Visited 12 May", cream pill, fs 12) + spacer + `RatingChip` (star icon + "4.92 · 164 reviews"). Use existing rating data from the model.
- **NEW** `lib/widgets/verified_pill.dart`

### M7 — Detail: host card + amenity row (2 steps)

- **M7-01** — `lib/widgets/host_card.dart` — Row with 48×48 circular avatar (initials or host photo) + small kSuccess check badge bottom-right, then `Hosted by [Name]` (Fraunces 16) and `Superhost · Replies in 1 hr` (Inter 13 kMuted) stacked. Mount under the meta row.
- **M7-02** — `lib/widgets/amenity_row.dart` — Horizontal scroll row of chips (24×24 icon + Inter 12 kInk2 label). Source: derive from `_single?.amenities` or hardcode 4 (Pool / 4 BR / Wi-Fi / AC) for v1. Mount under HostCard.

### M4 — Home: text category pills (2 steps)

- **M4-01** — `lib/ui/screens_renter/home/components/text_category_pills.dart` — Horizontal scroll row of text-only pills. Each pill: Inter 13 weight 500, padding 10×16, radius 999. Active = kIndigo fill + kCream text + shadow. Inactive = kCream BG + kInk text + 1px kLine border.
- **M4-02** — Mount above the existing carousel in `homescreen.dart`. Categories: `["All", "Villas", "Heritage", "Beach", "Hills", "Apartments"]`. Wire `selected` to a new `_propertyType` state — V1 just visual, no filtering wire-up. Keep the existing image-based "Browse by Category" section untouched (different concept — search-intent vs property-type).

### M9 — Verify + device walkthrough (2 steps)

- **M9-01** — `flutter analyze` must stay at ≤ 741 issues. Zero new errors.
- **M9-02** — Run on Pixel 10 Pro emulator (already created — `flutter emulators --launch Pixel_10_Pro_2`). Walk: Home → tap SearchPill → return → tap pill category → CuratedCard → Detail → confirm sticky book bar → tap Reserve. Verify both light and dark themes.

---

## 8. Known issues / context

### Backend (login blocker)
The mobile app's API URL `https://api.aajoohomes.com` returns Vercel `DEPLOYMENT_NOT_FOUND`. Login and signup from the running mobile app **do not work** because of this. Code is fine; the deployment is dead.

**Fix options** (operator must choose):
- (A) Run `aajooBackend-2026` locally with `npm run dev` (port 8080), point app at `http://10.0.2.2:8080` for Android emulator. Requires `usesCleartextTraffic="true"` in AndroidManifest.
- (B) Re-deploy the Vercel backend.

**Hardcoded URL locations:**
- `aajoo_app_2026/lib/data/ApiConstants.dart` lines 4–6
- `aajoo_app_2026/lib/service/auth_service.dart` line 12

### Pre-existing compile errors (legacy, NOT regressions)
`aajoo_app_2026/lib/screens/Host/host_support_screen.dart:296,298` — `_staticPageController` field is referenced but never declared. This is a **legacy unrouted file** (separate from the live `lib/ui/screens_host/support/host_support_screen.dart` which I fixed). Easy to mirror the fix: add `late StaticPageController _staticPageController;` to that class. Not blocking.

### Basic-info screen — unrelated business-logic was reverted in the working tree
`aajoo_app_2026/lib/ui/screens_common/auth/basic_info/basic_info_screen.dart` had its Skip-flow feature **removed** in the working tree (the per-step `signupData.addAll(...)` calls, `_skipAll()` method, `_placeholderJpeg`, and "Skip" button). This was intentional ground-truth from the operator's prior work — Claude only restored the design tokens, not the Skip flow. If signup is broken in testing, this is likely why.

### Auth controller — same situation
`aajoo_app_2026/lib/ui/screens_common/auth/auth_controller.dart` removed `skipMode` parameter and changed safe-default signup fallbacks (`?? ''`) to bare references with `!`/`int.parse`. Will crash on null fields during signup. Not redesign work — leave alone unless operator asks.

### Legacy mobile folder deletion
`aajoo_homes-main/` (old Flutter app) is deleted in the working tree (all `D` entries in git status). The new mobile work lives in `aajoo_app_2026/`. The `REDESIGN_BRIEF.md` references the old folder name — ignore that mismatch.

### Web `PURPLE` variable names
7 admin files still use `const PURPLE = "#1B2447"` (the variable name wasn't renamed, but the value is correct indigo). Cosmetic naming debt only — not a color regression. Files:
- `src/pages/admin/adminLogin/AdminLogin.tsx`
- `src/pages/admin/adminProperty/AdvancedFilters.tsx`
- `src/components/admin/Pagination/Pagination.tsx`
- `src/pages/admin/properties/HostAssignField.tsx`
- `src/components/admin/modals/userModals/{RoleSelector,ProfileUpload,IdUpload}.tsx`

### Emulator / device for mobile testing
- Pixel 10 Pro emulator already created. Launch: `flutter emulators --launch Pixel_10_Pro_2`
- Wait for boot: `until adb shell getprop sys.boot_completed | grep -q 1; do sleep 3; done`
- Run app: `flutter run -d emulator-5554` (from `aajoo_app_2026/`)

---

## 9. Verification commands

### Web
```pwsh
cd "D:\Projects\ajoo admin website"
npm run build          # tsc -b && vite build
npm run lint           # 210 pre-existing issues; should stay flat
npm run dev            # runs Vite dev server (localhost:5173)
```

### Mobile
```pwsh
cd "D:\Projects\ajoo admin website\aajoo_app_2026"
flutter pub get
flutter analyze        # baseline 741 issues; should stay ≤ that
flutter build apk --debug
flutter run            # picks up emulator-5554 if running
```

### Git inspection
```pwsh
cd "D:\Projects\ajoo admin website"
git status --short
git diff --stat aajoo_app_2026/
git diff --stat src/
git log --oneline -10
```

---

## 10. POC reference assets

- `aajoo_homes_poc.html` — Full POC, all 5 screens (Home, Search Results, Property Detail, Checkout, Mobile App)
- `aajoo_homes_poc_sand_indigo.html` — Sand & Indigo variant
- `REDESIGN_BRIEF.md` — Original mission brief (web + mobile)
- `REDESIGN_POC_SPEC_WEB.md` — Exact POC measurements for the web
- `REDESIGN_TASK_TRACKER.md` — Web/mobile task tracker (mostly historical now)
- `REDESIGN_SUMMARY_WEB.md` — What was done for Part A web
- `aajoo_app_2026/REDESIGN_SUMMARY_MOBILE.md` — What was done for Part B mobile
- `aajoo_app_2026/REDESIGN_AUDIT_MOBILE.md` — B0 audit
- `aajoo_app_2026/REDESIGN_OPEN_QUESTIONS.md` — Open items log (if it exists)

### POC mobile section reference
Inside `aajoo_homes_poc.html`, the mobile mockup is at `<section id="screen-mobile">` (line ~1520). Two phones:
- **Phone 1 (Home):** branded header → search pill → dark indigo hero card → text category pills → "Curated for you" + 2 vertical cards
- **Phone 2 (Detail):** full-bleed hero image → floating back/share/heart overlay → Fraunces mixed-italic title → kSuccess "Visited 12 May" pill + star rating → host card with badge → 4-icon amenity row → short description → sticky cream+clay book bar with Reserve CTA

---

## 11. Update protocol for the next Claude session

When you finish a task:
1. **Update §5** — Add a "Completed [task ID]" line with date + files touched + 1-line summary
2. **Update §7** — Move the task's row from ⬜ to ✅
3. **Update §6** — Bump the "Modified files" list if needed
4. **Update "Last updated"** at the top
5. **Tell the operator** in the chat: what changed + what's next

Keep this file in sync. It is the contract between sessions.

---

*End of context file. Open `REDESIGN_BRIEF.md` if you want the full original spec, but you should be able to continue from here alone.*
