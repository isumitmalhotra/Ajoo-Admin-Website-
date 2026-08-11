
# AajooHomes Web POC Match Spec (Sand and Indigo)

## Purpose
Match the web app UI to the POC layout, spacing, typography, and interaction 1:1 while using the approved Sand and Indigo palette. This is a visual-only re-skin. Do not change logic, routing, state, API, or dependencies. Keep existing React component structure and DOM as much as possible.

## Sources of truth
- POC: `aajoo_homes_poc.html` (exact measurements)
- Palette: `REDESIGN_BRIEF.md` and `palette_tokens_web.ts`
- Web app: `src/` (React + MUI + Tailwind + Bootstrap/CSS)

## Color translation (POC to Sand and Indigo)
Replace POC colors with Sand and Indigo tokens while keeping every size and spacing value unchanged.

| POC token | POC value | Sand and Indigo replacement |
|---|---|---|
| --bg | #F5F1EA | #EFE7D6 (sand) |
| --surface | #FFFDF8 | #FFFAF0 (cream) |
| --ink | #1A2B22 | #1B2447 (ink) |
| --ink-2 | #3C4A42 | #3D4670 (ink-2) |
| --muted | #7A8079 | #6B7390 (muted) |
| --line | #E3DCD0 | #D9CFB8 (line) |
| --brand | #1F3D32 | #1B2447 (indigo) |
| --brand-2 | #2C5746 | #2A356B (indigo-600) |
| --accent | #C8552A | #C16345 (clay) |
| --accent-2 | #E07A47 | #A8512F (clay-600) |
| --success | #3F6B4E | #3F6B4E (success) |

## Shadows
Use POC geometry with indigo-tinted RGBA values.

- shadow: `0 1px 2px rgba(27,36,71,.04), 0 8px 24px rgba(27,36,71,.06)`
- shadow-lg: `0 12px 40px rgba(27,36,71,.12)`

## Radii by component
Follow the POC sizes exactly.

- Logo mark: 10
- Cards (property cards): 14
- Hero image cards: 16
- Gallery container: 18
- Booking and summary cards: 18
- Inputs: 10
- Buttons: 10 to 12 depending on component
- Pills and chips: 999

## Typography
Use the exact POC fonts. Replace Poppins and Lato with Inter (body/UI) and Fraunces (serif headings/brand). Load via Google Fonts in the app stylesheet or layout.

- Base font: `Inter`, system fallback
- Serif font: `Fraunces` for hero/title/brand elements (match POC `.serif` usage)
- Hero title: `clamp(44px, 5vw, 68px)`, line-height `1.02`, letter-spacing `-0.035em`
- Section title (home): `36px`, letter-spacing `-0.025em`
- Listing header title: `28px`, letter-spacing `-0.02em`
- Detail page title: `42px`, letter-spacing `-0.025em`
- Body lead: `17px`, line-height `1.55`
- Body text: `14px` to `15px`, line-height `1.5` to `1.65`
- Overline labels: `10px` to `11px`, letter-spacing `.04em` to `.06em`, uppercase

### Typography implementation notes (web)
1) Replace font imports in `src/index.css` with Inter + Fraunces only.
2) Set `body { font-family: 'Inter', system-ui, sans-serif; }` and keep a `.serif` utility for Fraunces.
3) Update MUI typography (create theme if needed) so MUI components use Inter by default and Fraunces for display styles (h1/h2/h3, hero titles, section headers, logo text).
4) Wrap the app in `ThemeProvider` in `src/main.tsx` if not already present.

## Layout and spacing
Use the POC paddings and grid values.

- Header padding: `18px 48px`
- Hero padding: `56px 48px 24px`
- Search wrap padding: `0 48px`, margin-top `-12px`
- Categories padding: `48px 48px 8px`
- Section header padding: `48px 48px 24px`
- Property grid padding: `0 48px 64px`, gap `24px`, 4 columns
- Trust strip padding: `64px 48px`
- Destinations padding: `64px 48px`
- Footer padding: `64px 48px 32px`
- Results list padding: `24px 48px 64px`
- Detail page padding: `32px 48px 0`
- Detail body padding: `48px 0 64px`, grid columns `1.5fr 1fr`, gap `64px`
- Checkout container padding: `48px`, grid columns `1.4fr 1fr`, gap `48px`

## Component specs (web)

### Header and nav
- Logo mark: `34x34`, radius `10`, font size `18`
- Logo text: `20px`
- Nav links: gap `32`, link padding `6 0`
- CTA button: padding `10 18`, radius `999`, font size `13`
- Language pill: padding `6 10`, radius `999`, font size `12`

### Hero
- Grid columns `1.05fr 1fr`, gap `48`
- Tag pill: padding `6 12`, font size `12`, uppercase, letter-spacing `.04em`
- Trust row: gap `28`, margin-top `36`, padding-top `24`
- Collage height `520`, card radius `16`, badge padding `14 16`, badge radius `14`, icon `36`

### Search bar
- Search container: max-width `1100`, padding `8`, radius `999`, border `1px`
- Search field: padding `14 24`, label fs `11`, value fs `14`
- Search CTA: padding `0 28`, font size `14`

### Categories
- Chip padding `14 18`, radius `14`, min-width `96`, icon `32`, label fs `12`

### Section headers
- Section title `36`, link fs `14`, subtext fs `14`, margin-top `6`

### Property cards
- Card gap `12`
- Image ratio `1/1`, radius `14`
- Badge padding `5 10`, fs `11`
- Favorite button `32x32`
- Title fs `17`, meta fs `13`, price fs `14`, rate fs `13`

### Trust strip
- Inner grid `1fr 2fr`, gap `64`
- Feature icon `44x44`, radius `12`

### Destinations
- Grid height `520`, gap `16`
- Card radius `18`
- Overlay padding `24`
- Title fs `22` (large tile `32`)

### Listing and filters
- Filter row padding `16 0 24`, chip padding `8 14`, fs `13`
- Results header h2 `28`, sub fs `13`, sort fs `13`
- Listing grid `2 cols`, gap `24`

### Map chrome
- Map pane width `520`, sticky top `50`, height `calc(100vh - 50px)`
- Map pin padding `6 12`, fs `12`, border `2`
- Map buttons `38x38`, radius `10`
- Map search toggle padding `10 16`

### Detail page
- Breadcrumb fs `13`, gap `8`
- Detail title fs `42`, line-height `1.05`
- Verified pill padding `4 10`, fs `12`
- Action chip padding `8 12`
- Gallery height `480`, gap `8`, radius `18`
- Show-all button padding `8 14`, fs `12`, radius `8`
- Host avatar `56`, tick `20`

### Booking card
- Sticky top `80`, radius `18`, padding `24`
- Book form radius `12`
- Book button padding `14`, radius `10`, font size `15`
- Book breakdown rows gap `10`, font size `14`

### Checkout
- Checkout h1 `36`
- Trip cell padding `14`, radius `10`
- Pay option padding `14 16`, radius `12`
- Pay option selected: border width `2`, padding `13 15`
- Input padding `14`, radius `10`
- Summary radius `18`, padding `24`
- Pay button padding `16`, radius `12`, font size `15`

### Footer
- Grid columns `1.4fr 1fr 1fr 1fr`, gap `48`
- Heading fs `15`, body fs `13`, bottom row fs `12`

## Responsive rules (max-width 900px)
- Nav padding `14 20`
- Hero grid becomes `1fr`, collage height `340`
- Grid becomes `2 cols`
- Detail body becomes `1 col`, gap `32`
- Checkout grid becomes `1 col`
- Map pane hidden

## Mapping to app components
Use this mapping when applying the POC spec.

| POC section | Web app areas |
|---|---|
| Header and nav | `src/components/layout/*`, `src/components/frontend/*` |
| Home hero, trust row, collage | `src/pages/user/home.tsx`, `CTAoneHome`, `FeatureSection` |
| Search bar | `HomeCategorySection`, `FilterDropdown`, `MapandFilter` |
| Categories | `HomeCategorySection` |
| Property cards | `HomePropCard`, `PlaceCard`, `PropertyGrid`, `HomeCustomGrid` |
| Trust strip | `WhyChooseUs` |
| Destinations | `ExploreMore` (or equivalent section on home) |
| Listing page | `PropertyListing` and related components |
| Map chrome | `MapandFilter`, `HotelTooltip`, `RecenterButton`, `MarkerPulse` |
| Property detail | `PropertyDetail`, `PropertyBookingBox`, `BookingSection` |
| Booking card | `PropertyBookingBox` |
| Checkout | `UserCheckoutPage`, `FinalBookingPage` (chrome only) |
| Footer | `src/components/layout/*`, `src/styles/*.css` |

## Acceptance rule
If a designer overlays a screenshot of the web app with the POC (with Sand and Indigo colors), spacing and layout must align within a few pixels across hero, cards, listing, detail, and checkout.
