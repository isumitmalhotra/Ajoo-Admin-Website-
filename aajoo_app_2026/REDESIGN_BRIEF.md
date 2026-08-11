# AajooHomes — UI Redesign Brief (Web + Mobile) for Claude Code

<!-- ============================================================= -->
<!--  QUICK START — read this box, then scroll for full detail     -->
<!-- ============================================================= -->

## ⚡ QUICK START (operator copy-paste)

**Approved palette:** Sand & Indigo (Option 3, client-confirmed). Indigo `#1B2447` is the new
brand color for BOTH apps — it replaces purple `#881f9b` on web and pink `#C14464` on mobile.

**Setup (run once):**
```bash
git checkout -b redesign/sand-indigo
# place this file at repo root as REDESIGN_BRIEF.md
# open Claude Code at repo root
```

**Then send Claude Code these messages, ONE AT A TIME, approving each before the next:**

1. **Kickoff / web audit:**
   > Read `REDESIGN_BRIEF.md` in full. Then execute **Part A, Phase A0 only** — the web discovery audit. Produce `REDESIGN_AUDIT_WEB.md` and STOP. Make no code changes. Wait for my approval before Phase A1.

2. After reviewing the audit, approve each web phase in turn:
   > Proceed with **Phase A1**. (then A2, A3, A4, A5, A6 — one message each, checking the build after each)

3. **Mobile audit (after web is done & committed):**
   > Now Part B. Execute **Phase B0 only** — the Flutter discovery audit. Produce `REDESIGN_AUDIT_MOBILE.md` and STOP. No code changes. Wait for approval before B1.

4. Approve each mobile phase in turn:
   > Proceed with **Phase B1**. (then B2, B3, B4, B5 — one message each)

**Golden rules to remind it of if it drifts:**
- "This is a re-skin. No logic, no routing, no API, no dependency changes. Style values only."
- "Payments and maps are radioactive — restyle chrome only, never the logic."
- "Build must stay green after every change. Commit per phase."

---

> **Mission:** Re-skin BOTH the AajooHomes **web app** (React) and **mobile app** (Flutter)
> from their current brand colors to the finalized **Sand & Indigo** palette, plus a shared
> set of premium visual-polish rules — so that when launched, **web and mobile look like one
> coherent product.** Do this **without changing any functionality, navigation, data flow,
> state, or API behavior** in either app.
>
> This is a **visual re-skin** (color, spacing, radius, shadow, typography polish). It is
> **NOT a rebuild and NOT a logic change.** If you find yourself editing handlers, state,
> data fetching, routing, props, or business logic to achieve a look, **STOP** — out of scope.

---

## 0. THE REPO HAS THREE PARTS — KNOW WHICH YOU TOUCH

Confirmed from the codebase:

| Folder | What it is | Touch it? |
|---|---|---|
| Root `src/` | **Web app** — React 19 + TypeScript + Vite (the live aajoohomes.com) | YES — Redesign |
| `aajoo_homes-main/` | **Mobile app** — Flutter (Dart), 192 files, full renter + host UI, iOS + Android | YES — Redesign |
| `aajooBackend-2026/` | **Backend** — APIs, DB, server logic | NO — NEVER touch |

Other root files (`*.md` reports, the signed contract PDF, `scripts/`, `reports/`, `.env*`) — leave alone.

**Two languages, two apps, one palette.** The web is React/TS/MUI/Tailwind. The mobile is Dart/Flutter/GetX. You will migrate both to the same Sand & Indigo colors so they match at launch. Do them as **two separate workstreams** (Part A = Web, Part B = Mobile) — never edit one expecting it to affect the other.

---

## 1. THE FINALIZED PALETTE — "Sand & Indigo" (identical for web + mobile)

This is the single source of truth for both apps. Same hexes, expressed in each platform's format.

| Token | Hex | Flutter Color(...) | Role |
|---|---|---|---|
| indigo (primary) | `#1B2447` | `0xFF1B2447` | **Primary brand.** Replaces all current brand color. Headers, primary buttons, key text, active states, app bar. |
| indigo-600 (hover/light) | `#2A356B` | `0xFF2A356B` | Hover, pressed, lighter primary |
| sand (warm bg) | `#EFE7D6` | `0xFFEFE7D6` | Warm page/scaffold background on marketing & content surfaces |
| cream (surface) | `#FFFAF0` | `0xFFFFFAF0` | Card / sheet / surface background |
| clay (accent) | `#C16345` | `0xFFC16345` | **Accent only** — the single CTA that must pop, "New"/"Featured" badges. Seasoning, not a base. |
| clay-600 | `#A8512F` | `0xFFA8512F` | Clay hover/pressed |
| ink (text) | `#1B2447` | `0xFF1B2447` | Primary text |
| ink-2 | `#3D4670` | `0xFF3D4670` | Secondary text |
| muted | `#6B7390` | `0xFF6B7390` | Tertiary text, captions, placeholders |
| line (border) | `#D9CFB8` | `0xFFD9CFB8` | Borders, dividers (warm, never pure gray) |
| success | `#3F6B4E` | `0xFF3F6B4E` | Verified badges, success states |
| danger | `#C0392B` | `0xFFC0392B` | Errors only — leave existing error reds essentially as-is |

### Seed color for Flutter Material 3
Flutter's `ColorScheme.fromSeed` currently seeds from `0xffBF5973` (pink). Change the **seed to `0xFF1B2447`** (indigo) so the entire Material 3 scheme regenerates around the new brand. Set `primaryColor` to `0xFF1B2447` too.

---

## 2. WHAT EACH APP LOOKS LIKE TODAY (so you know what you're replacing)

### Web (React) — current brand: PURPLE
- Brand purple `#881f9b` (one stray `#8c4ecf`). Appears **~96 times across ~42 files.**
- **Partly centralized** in `src/theme/themeColor.tsx` (`PurpleThemeColor`, `FOCUS_COLOR`, `ThemeColors`, `commonFieldSx`, `menuProps`) — but mostly hardcoded.
- **Three coexisting styling systems:** MUI v7 (`sx` props, most UI), Tailwind v4 (`@tailwindcss/vite`), Bootstrap 5 + custom CSS (`src/styles/*.css` — auth forms, footer).
- Fonts: Poppins / Lato. Light mode only.

### Mobile (Flutter) — current brand: PINK/MAGENTA
- Brand pink `0xffC14464`, M3 seed `0xffBF5973`, plus accent pinks `0xFFAD1457`, `0xFF6A1B4D` used in gradients.
- **Mostly centralized:** `kprimaryColor` in `lib/constants.dart` is referenced by **51 files** (good — change once, propagates). The theme lives in `lib/service/theme_service.dart` (`lightTheme` + `darkTheme`).
- A few **hardcoded** brand pinks remain (`0xFFC14464` x3 files, `0xFFAD1457` x1, `0xFF6A1B4D` x2) and ~11 files use gradients.
- State mgmt: **GetX**. Fonts: Montserrat (`google_fonts`). **Has BOTH light AND dark themes — migrate both.**

---

## 3. NON-NEGOTIABLE GUARDRAILS (apply to BOTH apps)

Absolute. Violating any one fails the task regardless of how good it looks.

1. **No behavior changes.** No edits to handlers, state, effects/lifecycle, data fetching, props/params, navigation/routing, form submission, validation, or business logic. Style values only — color, spacing, radius, shadow, typography weight/size/spacing.
2. **No dependency changes.** No adding/removing/upgrading packages (npm or pub). Work within what's installed.
3. **No file moves, renames, or deletions.** Tree stays identical. No "refactor while I'm here."
4. **Preserve every** `id`, `name`, `key`, `data-*`, `aria-*`, `role`, semantic label, and any class/identifier referenced from logic or tests. Restyle what they point to; never rename them.
5. **Payments are radioactive.** Web `RazorpayPayment.tsx` + checkout, and the Flutter `checkout/` flow: restyle surrounding chrome only. Never touch payment handlers, order creation, gateway config, or callbacks.
6. **Maps:** restyle chrome (buttons, tooltips, pulse color) only. Never touch marker logic, coordinates, clustering, or map data (web: leaflet/mapbox/google-maps; mobile: whatever map lib is wired).
7. **Builds must stay green.** Web: `npm run build` (runs `tsc -b`) must pass. Mobile: `flutter analyze` must not add new errors and `flutter build apk --debug` (or `flutter run`) must compile.
8. **Dark mode (mobile):** the redesign must look correct in BOTH light and dark themes. Don't fix light and forget dark.
9. **When in doubt, leave it and log it** in `REDESIGN_OPEN_QUESTIONS.md`. Never guess on anything logic-adjacent.

---

## 4. THE TARGET LOOK (what "approved design" means — same language both apps)

The client approved the **Sand & Indigo** direction. Premium = **restraint**, not more decoration. Apply these consistently so web and mobile feel like siblings:

- **Color discipline:** indigo is the workhorse; clay is a rare spark (one pop-CTA per screen max); sand/cream are the calm backgrounds; everything else is ink/muted text on warm `line` borders.
- **Borders:** `1px` warm `line` (`#D9CFB8`) instead of heavy gray borders. Never pure `#ccc`.
- **Radius scale (consistent both apps):** cards `16`, buttons/inputs/fields `12`, pills/chips `999`. Don't scatter random radii.
- **Shadows:** soft and warm — `0 1px 2px rgba(27,36,71,.04), 0 8px 24px rgba(27,36,71,.08)`. Flat elements with a border need no shadow at all.
- **Spacing:** more breathing room in hero/section headers and around cards. Don't cramp; don't change column counts or break responsive/adaptive layout.
- **Typography:** keep existing families (web Poppins/Lato, mobile Montserrat). You MAY tighten large headings (`letter-spacing: -0.02em`) and set body line-height ~1.5–1.6 for readability. Do not swap fonts globally.
- **Buttons:** primary = indigo fill, cream text; secondary = indigo outline; the one hero CTA per screen MAY be clay fill.
- **Badges:** "Verified / Site-visited" = success-green marker on a dark/indigo pill; "New / Featured" = clay. Small, uppercase, tracked.
- **Hover/press:** subtle — card lift `translateY(-2px)` + soft shadow (web); standard ripple/press tint in indigo (mobile). Transitions ~0.2s.

> The HTML sample we built for the client is the **north star for the WEB look**. Match its
> hierarchy, spacing generosity, badge treatment, and card style — adapted into the existing
> React components, NOT pasted in as new markup. For **mobile**, translate the same visual
> language into native Flutter widgets (Material 3) — same colors, same restraint, same
> badge/card/button feel, but idiomatic Flutter, not a webview.

---

# PART A — WEB APP (React) — phased plan

> Paste to Claude Code to begin Part A:
> *"Read REDESIGN_BRIEF.md fully. Execute Part A, Phase A0 only — the web discovery audit. Produce REDESIGN_AUDIT_WEB.md and STOP. No code changes yet. Wait for my approval before Phase A1."*

### PHASE A0 — Web discovery audit (NO code changes)
Produce `REDESIGN_AUDIT_WEB.md`:
1. Run baseline and record any pre-existing errors/warnings (we must not increase them):
   ```bash
   npm install && npm run build && npm run lint
   ```
2. Color inventory: every file with `#881f9b`, `#8c4ecf`, `purple`, `violet`, purple `rgba()`, and `${FOCUS_COLOR}` tints — full paths + per-file counts.
3. Styling-system map for each `src/pages/user/*` page (MUI sx / Tailwind / Bootstrap+CSS / mix).
4. Risk list: anywhere color is computed in JS, passed as a prop, or used in a conditional.

**Checkpoint:** approve before code.

### PHASE A1 — Single source of truth for color
In `src/theme/themeColor.tsx`, **add** the Sand & Indigo tokens, and point the existing exports at indigo via a back-compat alias so centralized UI flips immediately and nothing breaks:
```ts
export const Brand = {
  indigo:"#1B2447", indigo600:"#2A356B", sand:"#EFE7D6", cream:"#FFFAF0",
  clay:"#C16345", clay600:"#A8512F", ink:"#1B2447", ink2:"#3D4670",
  muted:"#6B7390", line:"#D9CFB8", success:"#3F6B4E", danger:"#C0392B",
} as const;
export const PurpleThemeColor = Brand.indigo;  // back-compat alias (remove in A6 if unused)
export const FOCUS_COLOR = Brand.indigo;
export const ThemeColors = {
  primary: Brand.indigo, secondary: Brand.success, background: Brand.sand,
  text: { primary: Brand.ink, secondary: Brand.muted },
};
```
Expose CSS variables for the Bootstrap/custom-CSS files, and Tailwind v4 `@theme` tokens in `src/index.css`:
```css
:root{ --indigo:#1B2447; --indigo-600:#2A356B; --sand:#EFE7D6; --cream:#FFFAF0;
  --clay:#C16345; --clay-600:#A8512F; --line:#D9CFB8; --ink:#1B2447; --ink-2:#3D4670; --muted:#6B7390; }
@theme{ --color-brand-indigo:#1B2447; --color-brand-sand:#EFE7D6; --color-brand-cream:#FFFAF0;
  --color-brand-clay:#C16345; --color-brand-line:#D9CFB8; }
```
**Checkpoint:** `npm run build` passes; centralized UI already reads indigo. Commit.

### PHASE A2 — Centralized + high-traffic surfaces
`src/theme/*` -> `src/index.css` + `src/styles/*.css` (replace hardcoded purples with `var(--indigo)`, swap purple focus glows to indigo at same opacity) -> `src/components/layout/*` (navbar, footer, sidebars — propagates everywhere) -> shared `src/components/Form` & `Element`.
**Checkpoint:** auth pages, navbar, footer, base forms read indigo. Build clean. Commit.

### PHASE A3 — Customer-facing pages & components (priority — match the HTML sample look)
Pages `src/pages/user/`: `home`, `PropertyListing`, `PropertyDetail`, `UserCheckoutPage`, `FinalBookingPage`, `BookingConfirmed`, `UserBookings`, `UserProfile`, `AboutUs`, `ContactUs`, `BecomeHost`, `HelpCenter`, `FAQ`, `PrivacyPolicyPage`, `TermsAndConditions`, `StateRegulation`, `WhyHostsListWithAajoo`, `dashboard`, `userOngoingBooking`, `NotFound`.
Components `src/components/frontend/` (+ `modals/`): hero/landing (`CTAoneHome`, `FeatureSection`, `FeaturedProperties`, `HomeCategorySection`, `WhyChooseUs`, `ExploreMore`, `ReviewSlider*`), cards (`HomePropCard`, `PlaceCard`, `PropertyGrid`, `HomeCustomGrid`), booking (`PropertyBookingBox`, `BookingSection`, `BookingDetailsModal`), filters (`FilterDropdown`, `SidebarFilters`, `MapandFilter`), map chrome only (`HotelTooltip`, `RecenterButton`, `MarkerPulse`), all `modals/*`.
Apply palette + Section 4 polish. **After each page-group, walk it in the browser.**
**Checkpoint:** full funnel home -> listing -> detail -> checkout -> confirmation works, now Sand & Indigo. Build clean. Commit per group.

### PHASE A4 — Admin & host (palette only, no layout changes)
`src/pages/admin/*`, `src/pages/host/*`, `src/components/admin/*`, `src/components/host/*`, `src/features/*`. Retire purple; set MUI X Charts series to indigo/clay/success. Keep tables high-contrast and readable — **don't sand-wash data tables.**
**Checkpoint:** dashboards render, charts recolored, tables readable. Build clean. Commit.

### PHASE A5 — Polish (applied during A3–A4, per Section 4)
Style values only. If a polish idea needs JSX restructuring, **skip + log** in `REDESIGN_OPEN_QUESTIONS.md`.

### PHASE A6 — Web cleanup & verify
Grep `src/` for any remaining `881f9b`/`8c4ecf`/`purple`/`violet` -> expect zero brand purples. Remove the back-compat alias only if nothing imports it. Then:
```bash
npm run build && npm run lint && npm run preview
```
Walk every flow for parity. Produce `REDESIGN_SUMMARY_WEB.md`.

---

# PART B — MOBILE APP (Flutter) — phased plan

> Paste to Claude Code to begin Part B:
> *"Now Part B. Execute Phase B0 only — the Flutter discovery audit. Produce REDESIGN_AUDIT_MOBILE.md and STOP. No code changes. Wait for approval before B1."*
>
> Work entirely inside `aajoo_homes-main/`.

### PHASE B0 — Mobile discovery audit (NO code changes)
Produce `REDESIGN_AUDIT_MOBILE.md`:
1. Baseline:
   ```bash
   cd aajoo_homes-main
   flutter pub get
   flutter analyze            # record pre-existing issues as baseline
   ```
2. Color inventory: every file referencing `kprimaryColor`, and every hardcoded brand pink (`0xFFC14464`, `0xffC14464`, `0xFFAD1457`, `0xFF6A1B4D`, `0xffBF5973`) with paths + counts. List all gradient definitions (`LinearGradient`/`Gradient`) using brand pinks.
3. Confirm theme wiring: `lib/service/theme_service.dart` (light+dark), `lib/constants.dart` (`kprimaryColor`, `kscaffoldColor`, `kcontentColor`), and how `main.dart` consumes them.
4. Risk list: colors built in logic, passed to widgets as params, or used in conditionals; anything in `checkout/` or map screens.

**Checkpoint:** approve before code.

### PHASE B1 — Central theme migration (the big win)
1. In `lib/constants.dart`, retire the pink and add the palette:
   ```dart
   const kprimaryColor   = Color(0xFF1B2447); // indigo (was 0xffC14464)
   const kscaffoldColor  = Color(0xFFFFFAF0); // cream surface (was white) — verify readability
   const kcontentColor   = Color(0xFFEFE7D6); // sand content bg (was 0xffF5F5F5)
   // New brand tokens:
   const kIndigo   = Color(0xFF1B2447);
   const kIndigo600= Color(0xFF2A356B);
   const kSand     = Color(0xFFEFE7D6);
   const kCream    = Color(0xFFFFFAF0);
   const kClay     = Color(0xFFC16345);
   const kClay600  = Color(0xFFA8512F);
   const kInk      = Color(0xFF1B2447);
   const kInk2     = Color(0xFF3D4670);
   const kMuted    = Color(0xFF6B7390);
   const kLine     = Color(0xFFD9CFB8);
   const kSuccess  = Color(0xFF3F6B4E);
   ```
   Because **51 files reference `kprimaryColor`**, this single change propagates the new brand across most of the app instantly.
2. In `lib/service/theme_service.dart`, update **both** themes:
   - `lightTheme`: `seedColor: const Color(0xFF1B2447)`, `primaryColor: kprimaryColor`, `scaffoldBackgroundColor: kscaffoldColor` (or `kSand` on content screens), keep Montserrat.
   - `darkTheme`: `seedColor: const Color(0xFF1B2447)` with `brightness: Brightness.dark`, `primaryColor: kprimaryColor`. Verify text/`bodyColor` choices still read well on dark — the old theme set dark-mode body text to the pink; with indigo that will be too dark on a dark background, so switch dark-mode `bodyColor`/`displayColor` to a light tint (e.g. `Colors.white` or a cream) and use indigo only for fills/accents.
**Checkpoint:** `flutter analyze` clean; app boots in light AND dark; most screens already indigo. Commit.

### PHASE B2 — Hardcoded pinks & gradients
Replace the remaining hardcoded brand pinks (`0xFFC14464`, `0xFFAD1457`, `0xFF6A1B4D`, `0xffBF5973`) with the new tokens — usually `kIndigo`, with `kClay` only where it was a deliberate accent. For the ~11 gradient files: re-cast pink gradients as indigo->indigo600 (or a restrained indigo->clay for a single hero accent). Keep gradient direction/stops; change only colors.
**Checkpoint:** grep shows no brand pinks left; gradients read indigo. Analyze clean. Commit.

### PHASE B3 — Renter (customer-facing) screens — match the approved look
`lib/ui/screens_renter/`: `home`, `property_details`, `checkout` (chrome only — payments radioactive), `bookmark_properties`, `history`, `nearby_bookings`, `profile`, `safety`, plus `screens_common/` shared widgets and `lib/widgets/`.
Apply palette + Section 4 polish in Flutter idiom: `Card` elevation -> soft, `BorderRadius.circular(16)` for cards / `12` for buttons & fields, `BorderSide(color: kLine)`, primary `ElevatedButton` indigo/cream, hero CTA may be clay, verified badge success-green pill. **Verify in light AND dark after each screen group.**
**Checkpoint:** renter flow home -> details -> checkout -> confirmation works in both themes. Analyze clean. Commit per group.

### PHASE B4 — Host screens (palette only)
`lib/ui/screens_host/*` and host widgets: palette swap only, no layout redesign — these are operational. Keep dense forms/tables legible.
**Checkpoint:** host flow renders both themes. Analyze clean. Commit.

### PHASE B5 — Mobile cleanup & verify
Grep `lib/` for any remaining brand pinks -> expect zero. Then:
```bash
flutter analyze
flutter build apk --debug    # must compile (or flutter run on a device/emulator)
```
Manually walk renter + host flows in light AND dark for feature parity. Produce `REDESIGN_SUMMARY_MOBILE.md`.
> Note: `lib/ui/unused_screens/` — confirm it's truly unused (not routed) before spending time; if unused, skip and note it.

---

## 5. WORKING DISCIPLINE (both parts)

- **Do Part A fully, then Part B.** Don't interleave — different languages, different mental models.
- **Small commits, one phase / screen-group each**, clear messages — every step `git revert`-able. Suggested prefixes: `style(web): ...`, `style(mobile): ...`.
- **After every batch:** run the platform's build/analyze. If it fails, fix or revert before stacking more.
- **Keep `REDESIGN_OPEN_QUESTIONS.md`** for anything ambiguous or logic-adjacent. Ask, don't guess.
- **Never** improve unrelated code, rename props, bump deps, or move files.
- **Drive color from tokens** (`Brand` / CSS vars on web, `k*` constants on mobile), not fresh hardcoded hexes — so the next palette change stays near-one-file.
- **Parity is the bar.** A screen is "done" only when it looks Sand & Indigo AND behaves exactly as before (web: clicks/filters/modals/booking; mobile: navigation/gestures/booking; both light+dark on mobile).

---

## 6. QUICK REFERENCE — color migration

**Web (React):**
```
#881f9b -> #1B2447 (indigo)        [~96 occurrences, the main swap]
#8c4ecf -> #1B2447 (indigo)        [1 stray]
purple rgba glow -> rgba(27,36,71,.x)   |   ${FOCUS_COLOR} tints -> unchanged (now indigo)
attention CTA / "New" -> #C16345 (clay)  [only where it must pop]
white marketing bg -> #EFE7D6 (sand)  [NOT data tables]   |   card -> #FFFAF0 (cream)
gray borders/#ccc -> var(--line) #D9CFB8
```

**Mobile (Flutter):**
```
kprimaryColor 0xffC14464 -> 0xFF1B2447 (indigo)   [51 files inherit this]
M3 seedColor 0xffBF5973 -> 0xFF1B2447  (light AND dark)
hardcoded 0xFFC14464 / 0xFFAD1457 / 0xFF6A1B4D -> kIndigo (or kClay if a deliberate accent)
pink gradients -> indigo -> indigo600  (keep stops/direction, change colors)
kscaffoldColor white -> 0xFFFFFAF0 cream  |  kcontentColor 0xffF5F5F5 -> 0xFFEFE7D6 sand
dark-mode body text: was pink -> switch to light tint (indigo too dark on dark bg)
```

---

## 7. HOW TO RUN THIS (you, the operator)

1. Put this file at the repo root as `REDESIGN_BRIEF.md`.
2. New branch first: `git checkout -b redesign/sand-indigo`.
3. Open Claude Code at the repo root.
4. **Part A first.** Send the Phase A0 message (top of Part A). Review `REDESIGN_AUDIT_WEB.md`, confirm the web build is green at baseline, then approve **one phase at a time** (A1 -> A6).
5. **Then Part B.** Send the Phase B0 message. You'll need the Flutter toolchain installed (`flutter doctor` should be clean). Review `REDESIGN_AUDIT_MOBILE.md`, then approve B1 -> B5 one at a time.
6. Don't let it run all phases unattended on the first pass — checkpoint each, eyeball the screens, commit.

**Scope honesty:** this re-skins the look so web + mobile launch matching. It does **not** fix the web app's underlying client-rendered-SPA / SEO limitation — that's a separate Next.js rebuild conversation. Ship the visual win; keep the platform-rebuild pitch as a distinct phase.
