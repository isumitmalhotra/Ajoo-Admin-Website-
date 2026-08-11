# Aajoo Homes — Frontend Rebuild Plan (client design handoff)

> **Goal:** rebuild the **web frontend** (and align the **mobile app**) to match the client's design deliverables **exactly**, with high-quality niche imagery and the shared design system.
> **Created:** 2026-07-12. This supersedes the earlier "Section-0" placeholder — we now have the *actual built designs*, not just a direction PDF.

---

## 0. What the client gave us (sources of truth)

| Source | What it is | Role |
|---|---|---|
| **`aajoo-site/`** (static HTML/CSS/JS) | The full site built by the client — **26 guest + 17 host + 18 admin pages** + `assets/css/aajoo.css` (design system) + `assets/js/aajoo.js` (shared components) | ⭐ **PRIMARY blueprint** — pixel + structure source of truth |
| **`aajoo_app/`** (Flutter) | The mobile app design as real Dart screens (guest + host) | ⭐ **Mobile blueprint** |
| **`Aajoo Design/`** (66 PNGs) | High-fidelity mockup renders (home, property, dashboards, admin…) | Visual confirmation / hero references |
| **`aajoo-homes-poc.html`** | Combined single-file web POC | Secondary reference |
| **Section-0 PDF** | Direction, page content/copy, categories, auth model | Content + intent (copy, SEO, flows) |
| **react-icons** (link) | Icon library the client chose | Web icon set |

**Rule of precedence:** exact look → `aajoo-site` CSS/HTML. Exact mobile → `aajoo_app`. Copy/flows/SEO → Section-0 PDF. Where the PDF's palette (Teal `#0F766E`/Amber `#E8A317`) differs from the built site (`#0D9488`/`#FF7A00`), **the built site wins** (it's what they actually designed).

---

## 1. Locked design system (from `aajoo.css`)

```
Colors    primary #0D9488 · primary-dark #0A6E63 · primary-deep #064E43
          accent (orange) #FF7A00 · accent-50 #FFF1E3
          bg/secondary #FDF7F0 · ink #1E293B · dark #0F172A · muted #64748B
          line #EAE4DA · line-soft #F1ECE3
          admin: bg #0B1120 · sidebar #111827 · card #1A2233
          success #22C55E · danger #EF4444 · warning #B45309
Fonts     display/headings: Poppins (--fd)   body/UI: Manrope (--fs)
Radius    18px (cards) · 12px (inputs/small) · 999px (pills)
Shadows   --shadow (soft), --shadow-lg
Logo      house mark + "aajoo" wordmark + tagline "Apno wali feeling" / "Homes"
Icons     react-icons (web) · lucide (mobile)
```

**Reusable components (mirror `aajoo.js`):** `topnav()`, `dashHeader()`, `buildSidebar()`, `footer()`, `pcard()` (property card), `logo()`, badges, buttons, modals, toast, `ic()` icons.

---

## 2. Strategy & key decisions

1. **Rebuild UI only — keep the working data layer.** The existing React app (`aajao-frontend-vercel`) has all the API wiring we've stabilised (auth, bookings, notifications, invoices, host wizard, KYC, payments). We **reskin/replace the presentation** and reuse `services/`, redux slices, `axios`, and route guards. No backend changes required for the rebuild.
2. **Tailwind-first + CSS tokens, reduce MUI.** The mockups are plain CSS (not MUI). Port `aajoo.css` `:root` tokens into `index.css` + Tailwind `@theme`; build new pages with Tailwind + small styled components. Migrate MUI-heavy screens progressively (don't rip MUI out on day 1 — replace page-by-page).
3. **react-icons everywhere (web).** Add `react-icons`; standardise on one icon pack (Lucide-compatible `react-icons/lu` to match the mockups). Remove ad-hoc MUI icons as pages are rebuilt.
4. **Fonts:** load **Poppins + Manrope** (Google Fonts); set Poppins for `h1–h5`, Manrope for body — matches both web + mobile.
5. **Imagery:** curated **high-quality niche images** (Himalayan homestays, cottages, villas, cabins, valley/mountain stays) — an optimized, lazy-loaded set with sensible fallbacks + the branded placeholder for photo-less listings.
6. **Component-per-`aajoo.js`-helper.** Port each shared JS builder to a React component so all 61 pages share one shell.
7. **Ship incrementally behind the existing routes** so nothing breaks mid-rebuild; each page swaps to the new design when ready.

---

## 3. Phase plan (web) — ~61 pages

### Phase 0 — Foundation (do first; everything depends on it)
- [ ] **Tokens:** port `aajoo.css` `:root` → `index.css` variables + Tailwind `@theme`; set bg = `#FDF7F0`.
- [ ] **Fonts:** Poppins + Manrope via Google Fonts; MUI theme + CSS defaults updated.
- [ ] **Icons:** install `react-icons`; create an `Icon` wrapper (Lucide set) + icon-name map.
- [ ] **Images:** create `src/assets/curated/` set + an `<Img>` component (lazy, aspect-ratio, fallback).
- [ ] **Shared shell components:** `Logo`, `TopNav` (marketing), `DashHeader`, `Sidebar` (guest/host variants), `AdminSidebar` (dark), `Footer`, `PropertyCard` (`pcard`), `Button`, `Badge`, `Card`, `Modal`, `Toast`, `StatCard`, `EmptyState`. Port CSS classes (`.btn-*`, `.b-*`, `.card`, `.topnav`, `.dashhdr`, `.side-nav`).

### Phase 1 — Guest: marketing + discovery (highest visibility)
- [ ] `index.html` → **Home / Getting-Started + Explore** (hero, search, categories, featured, trust, collections, CTA, footer)
- [ ] `explore.html` → **Explore Stays** · `search.html` → **Search/listing + map**
- [ ] `property.html` → **Property Detail** (hero+grid gallery, facts, host, availability, reviews, map, sticky booking)
- [ ] `login.html` · `register.html` → **Login / Sign-up** (OTP-first, role choice, social — per Section-0)

### Phase 2 — Guest: account & booking
- [ ] `dashboard.html`, `ongoing.html`, `upcoming.html`, `next-booking.html`, `past-stays.html`, `saved-stays.html`
- [ ] `checkout.html`, `payment.html`, `booking-confirmed.html`, `booking-review.html`, `cancelled.html`, `directions.html`
- [ ] `transactions.html`, `reviews.html`, `review.html`, `notifications.html`, `messages.html`, `support.html`, `refer.html`, `settings.html`

### Phase 3 — Host portal (17 pages)
- [ ] `host/index.html` (landing), `host-dashboard.html`, `host-properties.html`, `host-add-property.html`, `host-calendar.html`
- [ ] `host-bookings.html`, `host-earnings.html`, `host-payouts.html`, `host-performance.html`, `host-negotiations.html`
- [ ] `host-messages.html`, `host-boost.html`, `host-refer.html`, `host-profile.html`, `host-settings.html`, `host-support.html`, `host-register.html`

### Phase 4 — Admin portal (18 pages, dark theme)
- [ ] `admin-dashboard`, `admin-analytics`, `admin-reports`, `admin-users`, `admin-hosts`, `admin-properties`, `admin-bookings`
- [ ] `admin-payments`, `admin-negotiations`, `admin-reviews`, `admin-disputes`, `admin-boost`, `admin-refer`, `admin-coupons`
- [ ] `admin-cms`, `admin-settings`, `admin-roles`, `admin-logs`

### Phase 5 — Mobile (Flutter `aajoo_app_2026`)
- [ ] Apply the `aajoo_app` mockup screens to the existing app (getting-started, login, explore, property-detail, dashboard, bookings, ongoing, negotiate, saved, profile; host landing/dashboard/properties/add-property/bookings/messages/profile).
- [ ] Align theme to the same tokens (Poppins/Manrope, green/orange), keep GetX + existing controllers/services.

### Phase 6 — Polish & wiring
- [ ] Swap all placeholder imagery for the curated niche set; optimise + lazy-load.
- [ ] Wire every rebuilt page to the **real APIs** (reuse existing services); verify flows end-to-end.
- [ ] Responsive pass (mobile/tablet/desktop) · SEO meta/OG per page (Section-0 copy) · accessibility pass.

---

## 4. How each page gets built (repeatable recipe)
1. Open the matching `aajoo-site/**/<page>.html` + its render script + the mockup PNG.
2. Map its `aajoo.js` calls to our shared shell components (built in Phase 0).
3. Rebuild the page body as a React component using tokens + Tailwind, matching structure 1:1.
4. Replace lucide `data-lucide` icons with `react-icons`.
5. Wire data from the existing service/redux layer (keep the API contracts).
6. Drop in curated imagery + fallbacks.
7. Verify against the PNG + on device widths.

---

## 5. Effort & sequencing (realistic)
This is a **large rebuild (~61 web pages + mobile)** — effectively the full Section-0 relaunch, but de-risked because the client supplied exact HTML/CSS. Suggested order: **Phase 0 → 1 → 2 → 3 → 4 → 5 → 6**. Phases 1–2 (guest) give the biggest visible win first; admin (Phase 4) is the largest page count. Recommend shipping per-phase so the client sees progress and can approve as we go.

## 6. Decisions — ✅ LOCKED (2026-07-12)
1. **Start order:** ✅ **Foundation → Guest web** (Phase 0 → 1 → 2), then Host → Admin → Mobile → Polish.
2. **Approach:** ✅ **Tailwind-first**; retire MUI page-by-page (no big-bang removal).
3. **Imagery:** ✅ **Curated niche stock now** (Himalayan homestays/cottages/villas) + branded placeholder; swap for client brand photos later.
4. **Palette/fonts:** ✅ **built-site tokens** authoritative (`#0D9488`/`#0A6E63` green, `#FF7A00` orange, Poppins + Manrope) — override the PDF's slightly different values.
5. **Icons:** ✅ **react-icons** (Lucide set `react-icons/lu`) for web.
6. **Commercial (still to confirm):** this is the **Section-0 rebrand SOW**, out of the ₹1,60,000 contract (§6). Proceeding on the technical build as directed; change-order approval to be confirmed with the client.

## 6b. Branch & deploy safety
- Build the rebuild on a **feature branch** (`redesign/aajoo-2026`), **not `main`** — the live site (just recovered from the DB/JWT outages) must stay stable. Merge to `main` only per-phase once approved, so production never serves half-built pages.
- Keep the extracted client design as a local reference (scratchpad `design/`).

---

## 7. What I've already done (this analysis)
- Extracted + inventoried all 3 zips + POC HTML + PDF.
- Locked the design tokens from `aajoo.css`; catalogued all 61 web pages + Flutter screens + 66 mockups.
- Confirmed the visual direction from the host + admin dashboard renders.
- Mapped the build approach (reuse data layer, port shared components, react-icons, Poppins/Manrope, curated imagery).

_Reference copies of the extracted design live in the scratchpad `design/` folder; move into the repo (e.g. `design-ref/`) if you want them version-controlled._
