# AajooHomes Web Redesign Summary — Sand & Indigo

> **Completed:** 2 June 2026  
> **Palette:** Sand & Indigo (client-approved Option 3)  
> **Scope:** Visual re-skin only — color, spacing, radius, shadow, typography. Zero logic/routing/API changes.  
> **Final build:** `✓ 15390 modules transformed` — zero new errors  
> **Key commits:** `6496c68` · `8fa1c1a` · `b383d2e` · `ce89858` + cleanup

---

## What Changed

### Tokens & Foundation
| File | Change |
|---|---|
| `src/theme/themeColor.tsx` | Replaced `PurpleThemeColor` with full `Brand` token object (indigo, clay, sand, cream, ink, muted, line, success). Back-compat alias kept — now resolves to `Brand.indigo`. |
| `src/index.css` | Replaced Poppins/Lato/Manrope/Quicksand imports with Inter + Fraunces only. Added `:root` CSS variables + Tailwind v4 `@theme` block. Body font → Inter, bg → sand. |
| `src/main.tsx` | Wrapped app in MUI `ThemeProvider` — Inter body, Fraunces h1–h6, indigo primary palette, sand/cream background. |

### Global Color Migration — 97+ files
Every `#c14365` / `#881f9b` / `#8c4ecf` → `#1B2447` (indigo) across all TSX, CSS, and TS files via a single PowerShell sweep. Hover variants `#ab3864` / `#a83756` → `#2A356B` (indigo-600).

---

## Component-by-Component Changes

### Layout
| Component | Changes |
|---|---|
| `Header.tsx` | Full POC nav: cream bg `#FFFAF0`, indigo logo mark 34×34 radius 10, Fraunces brand text, nav links gap 32, lang pill radius 999, CTA pill `10 18`. |
| `Footer.tsx` | Rebuilt to POC dark footer: `#0E1A2E` bg, 4-col grid `1.4fr 1fr 1fr 1fr / gap 48`, Fraunces headings fs 15, body fs 13. |
| `UserSidebar.tsx` | Bg → indigo `#1B2447` (was pink). |

### Home Page
| Component | Changes |
|---|---|
| `HeroSection.tsx` *(new)* | POC hero: Fraunces title `clamp(44px,5vw,68px) / lh 1.02 / -0.035em`, pulse tag pill, CTA buttons, trust strip (3 numbers), image collage with 2 rotated cards + floating badges. |
| `MapandFilter.tsx` | Rebuilt: floating search bar `max-width 1100 / radius 999 / padding 8`, 3 search fields `padding 14 24 / fs 14`, clay CTA; category chips `14 18 / radius 14 / min-width 96 / icon 32`; map card `radius 18`, map buttons `38×38 / radius 10`. |
| `FeaturedProperties.tsx` | Section h2 `36px Fraunces / -0.025em`; subtitle `fs 14 / muted`; load-more btn indigo. |
| `HomePropCard.tsx` | Full POC card: `radius 14 / border line / shadow`; image `aspect-ratio 1/1`; badge `5 10 / radius 999 / fs 11`; fav btn `32×32`; Fraunces title `fs 17`; clay star icon; price Fraunces `fs 17`. Hover `translateY(-3px)` + image `scale(1.05)`. |
| `WhyChooseUs.tsx` | Rebuilt to POC trust strip: dark indigo bg `#1B2447`, grid `1fr 2fr / gap 64`, feature icons `44×44 / radius 12`, Fraunces headings. |
| `ExploreMore.tsx` | Rebuilt to POC destinations grid: `height 520 / gap 16`, 3-col layout `1.4fr 1fr 1fr`, card `radius 18`, dark overlay, Fraunces titles `fs 22/32`. |
| `ReviewSlider.tsx` | Removed pink gradient → cream bg + indigo-tinted shadow; Fraunces heading. |
| `FAQSection.tsx` | Hover color pink → sand; bg → sand. |
| `CTAoneHome.tsx` | Playfair Display → Fraunces; Roboto → Inter; pink hover → sand. |

### Listing Page
| Component | Changes |
|---|---|
| `PageHeaderWithCategories.tsx` | Results header `h2 28 Fraunces`; result count `fs 13`; sort `fs 13`; filter chips row `padding 16 0 24 / border-bottom`; chips `8 14 / radius 999 / fs 13 / indigo active state`. |
| `PropertyGrid.tsx` | 2-col listing grid, gap 24. |
| `SidebarFilters.tsx` | All purple → indigo (slider, checkboxes, search btn). |
| `PropertyListing.tsx` | Sand page bg, sidebar border `#D9CFB8`, result count passed to header. |

### Property Detail Page
| Component | Changes |
|---|---|
| `PropertyDetail.tsx` | Padding `32 48 0`; sand bg; title `h1 fs 42 / lh 1.05 Fraunces`; verified pill (success green `4 10 / fs 12`); action chips `8 12 / radius 999`; detail grid `1.5fr 1fr`; host card (avatar 56, Fraunces heading, meta fs 13); all section headings Fraunces. |
| `PropertyGallery.tsx` | Full POC gallery: `2fr 1fr 1fr` grid, height 480, gap 8, radius 18, show-all button `8 14 / fs 12 / radius 8`, `+N more` overlay, hover `scale(1.04)`, lightbox modal. |
| `BookingSection.tsx` | Radius 18, padding 24, border line, shadow-lg; book btn `padding 14 / fs 15 / radius 10`. |

### Checkout
| Component | Changes |
|---|---|
| `FinalBookingPage.tsx` | Sand bg; h1 `36 Fraunces`; grid `1.4fr 1fr / gap 48`; trip cell `padding 14 / radius 10`; summary card `radius 18 / padding 24 / sticky top 80`; price breakdown `gap 10 / fs 14`; Pay buttons `padding 16 / radius 12 / fs 15`. |

### CSS Files (9 updated)
`Footer.css`, `LoginForm.css`, `UserSignup.css`, `FAQ.css`, `FeatureSection.css`, `Home.css`, `HomePropCard.css`, `PropertyListing.css`, `UserProfile.css`, `PropertyDetail.css` — all purples/pinks → `var(--indigo)`; card borders → `var(--line)`; shadows → indigo-tinted; font-family → Inter/Fraunces.

### Admin & Host Panels (A4)
- **Charts:** `AdmindPieChart` series palette → indigo/clay/success/ink-2/clay-600/muted/line (8 distinct). Bar/Line chart axis labels → Inter, `#6B7390`.
- **Modals:** `CommonModal` purple gradients → indigo; `AddUserModal` gradient → indigo+clay; `Pagination` → indigo/ink-2.
- **Finance:** `FinanceStatusChip` dot → indigo.
- **Forms/SearchBars:** All purple borders/colors in admin `property-*` pages → `PurpleThemeColor` (= indigo).
- **Tables:** White background intentionally preserved — high-contrast data tables not sand-washed.

---

## Design Tokens Applied

| Token | Value | Usage |
|---|---|---|
| `--indigo` | `#1B2447` | Primary brand, text, borders, buttons |
| `--indigo-600` | `#2A356B` | Hover states |
| `--clay` | `#C16345` | Accent CTA, search button, star icons |
| `--clay-600` | `#A8512F` | Clay hover |
| `--sand` | `#EFE7D6` | Page backgrounds |
| `--cream` | `#FFFAF0` | Card/sheet surfaces |
| `--ink` | `#1B2447` | Body text |
| `--ink-2` | `#3D4670` | Secondary text |
| `--muted` | `#6B7390` | Meta/subtext |
| `--line` | `#D9CFB8` | Borders, dividers |
| `--success` | `#3F6B4E` | Verified badges |
| `--shadow` | `0 1px 2px rgba(27,36,71,.04), 0 8px 24px rgba(27,36,71,.06)` | Cards |
| `--shadow-lg` | `0 12px 40px rgba(27,36,71,.12)` | Booking card, search, modals |

---

## Typography

| Usage | Font | Size | Weight | Tracking |
|---|---|---|---|---|
| Hero title | Fraunces | `clamp(44,5vw,68px)` | 400 | `-0.035em` |
| Section h2 | Fraunces | `36px` | 400 | `-0.025em` |
| Detail title | Fraunces | `42px` | 400 | `-0.025em` |
| Results h2 | Fraunces | `28px` | 400 | `-0.02em` |
| Card title | Fraunces | `17px` | 500 | `-0.01em` |
| Body lead | Inter | `17px` | 400 | — |
| Body / UI | Inter | `13–15px` | 400–500 | — |
| Overlines | Inter | `11px` | 600 | `0.04–0.06em` uppercase |

---

## What Was NOT Changed (per guardrails)
- All routing, API calls, auth logic, Redux state, payment handlers (Razorpay)
- Map logic (Leaflet/OpenStreetMap)
- All TypeScript types and interfaces
- All form validation logic
- Admin data table row backgrounds (kept white for readability)
- `src/components/admin/common/` internal admin utilities
- Pre-existing lint errors (210 `no-explicit-any` / fast-refresh warnings — all pre-existing)

---

## Open Items
- **B5-04 to B5-07** (mobile): Device walk for renter + host flows in light/dark — manual only
- **A3-10**: Browser funnel walk: Home → Listing → Detail → Checkout → Confirmation — manual only
- **A6-04**: Full flow parity check against POC — manual
- **A2.5-29** (features/amenities): No standalone component exists in the app — logged in `REDESIGN_OPEN_QUESTIONS.md`
- **`PurpleThemeColor` alias**: Still used by ~15 admin files. Resolves to `Brand.indigo`. Can be cleaned up in a dedicated refactor sprint.
