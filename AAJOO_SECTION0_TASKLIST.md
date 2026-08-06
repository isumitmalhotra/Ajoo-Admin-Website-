# Aajoo Homes — Section 0 Spec → Understanding & Task List

> **Source:** `Aajoo Homes – Section 0 – Quick Summary & Project Direction.pdf` (102 pages).
> This document captures **what every page must DO and HOLD**, derived from the spec.
>
> **Workflow:** (1) this understanding + task list ← *you are here*; (2) verify each item against the current codebase/site → mark **Present ✅ / Partial 🟡 / Missing ❌**; (3) build the pending ones; (4) apply the client's reference images for visual layout.
>
> **Big picture:** Section 0 is a **rebrand + new landing + CMS + OTP-auth** direction. It partly supersedes the older `POST_25_PRIORITIZED_PLAN.md` (e.g. the Get-Started redesign, color/font/icon change, Google/phone auth are now *specified* here). The spec **provides the actual page copy**, so content is mostly NOT blocked — only final brand *assets* (logo file, illustrations) are pending.

---

## PART A — Global / cross-cutting directives (apply to every page)

| # | Directive | Detail (from spec) | Status |
|---|-----------|--------------------|--------|
| **A1** | **Color palette — CHANGE** | Drop current Indigo/Sand/Clay. **New:** Primary **Evergreen Teal `#0F766E`** · Bg **Warm Ivory `#FAF8F4`** · Accent/CTA **Golden Amber `#E8A317`** · Dark surface **Charcoal Navy `#1F2937`** · Success `#22C55E` · Warning `#F59E0B` · Error `#EF4444` · Info `#3B82F6`. Use modern gradients (Evergreen→Deep Teal, Amber→Gold), glassmorphism, soft glows. | ✅ shipped 2026-08-06 |
| **A2** | **Typography — CHANGE** | Drop current Fraunces/Inter. **New:** Primary UI **Manrope** (nav, dashboard, forms, cards, buttons, listings); Headings/marketing **Plus Jakarta Sans**. Weights 400/500/600/700. Responsive hierarchy. | ✅ shipped 2026-08-06 |
| **A3** | **Icons — CHANGE** | Single library: **Lucide Icons**. Outline default, filled only for active/selected, rounded, uniform stroke, SVG only. No mixing libraries. | 🟡 redesign is Lucide-only (2026-08-06); 98 legacy MUI-icon files remain |
| **A4** | **Logo** | Transparent SVG + PNG @1x/2x/3x + mono black/white + icon-only + horizontal/vertical. **Remove the white-background container** around the logo. Header supports light/dark logo. Swappable without code changes. *(final logo file pending from client)* | 🟡 (verify) |
| **A5** | **Favicon + App icons** | Website favicon, PWA icons, Android adaptive+legacy, iOS icons, 512×512. Recognizable at small sizes, no text in icon. | ✅ shipped 2026-08-06 (generated from the header mark; regenerate when the client logo lands) |
| **A6** | **Mission/Vision visuals** | Animated illustrations (Lottie / smooth SVG / 3D), activate on scroll-into-view, subtle. | ✅ shipped 2026-08-06 (inline SVG, swappable for Lottie) |
| **A7** | **Content** | Replace ALL placeholder text with the professionally-written copy **provided in this spec** (SEO/GEO/AEO-friendly, conversational, no Lorem). Copy is captured per-page below. | ❌ |
| **A8** | **CMS-driven content** | Every public page's content editable via Admin (per-page CMS field lists given in spec). No hardcoded marketing copy. | ❌ |
| **A9** | **Auth model** | **Mobile OTP = default/primary**, Email+password secondary, Social (Google, Apple) — for both Guest & Host, single account, role-based routing + switching. | 🟡 (email + Google sign-in live; mobile OTP still pending a provider) |
| **A10** | **SEO readiness** | Per-page dynamic `<title>`/meta description, Open Graph tags, schema markup, clean URLs. Copy for titles/meta/OG is provided per page below. | ❌ |
| **A11** | **Configurable services** | SMTP, SMS/OTP provider, email templates (welcome, booking confirmation, host verification, password reset, notifications) — configurable without code changes. | 🟡 |
| **A12** | **Scalability** | DB/API/components ready for future categories (villas, farm stays, campsites, experiences, tour packages) + future modules without redesign. | 🟡 |
| **A13** | **Mobile-first · Performance · Security** | Responsive-first, lazy loading + image optimization, input validation + RBAC + web-vuln protection. | 🟡 |
| **A14** | **Property categories (new set)** | Homestays · Villas · Apartments · Cottages · Farm Stays · Heritage Homes · Boutique Stays · Luxury Stays · Pet-Friendly Stays. | ❌ (verify) |

---

## PART B — Page by page

### B1 · Getting Started page (NEW default landing) — `GS-1…7`, `CNT-1`, `IMG-1`
**DO (behaviour):**
- Become the **default landing page** for first-time visitors — intent capture, not listings.
- **Routing logic:** first-time → Getting Started; returning (localStorage pref) → open last-chosen experience directly; logged-in **Guest** → User Dashboard / Explore; logged-in **Host** → Host Dashboard; nav must **always allow switching** (Switch to Host / Explore Stays).
- Nav **minimal initially** (Logo · Getting Started · Login · Sign Up); **expands on scroll** to reveal Explore Stays · Become a Host · About · Blog · Contact · Help Center; **sticky** with subtle shadow after scroll.

**HOLD (content/sections):** Hero (badge "India's Smart Stays Marketplace", headline **"Stay Better. Host Smarter. Belong Everywhere."**, supporting text, **Explore Stays** [primary] + **Become a Host** [secondary] CTAs, small note "No hidden charges • Verified Hosts • Secure Payments") · 6 cards (Verified Properties, Trusted Community, Secure Payments, Flexible Booking, Local Experiences, Dedicated Support) · How It Works (Guest journey: Search→Choose→Book→Enjoy; Host journey: Register→List→Get Verified→Receive Bookings) · Our Promise · Why We Exist · Bottom CTA · Footer quote · full SEO/OG meta · CMS fields (all of the above).

**REMOVE from this page:** floating tags · "12K+ Properties" stat · search bar · Find Your Stay · map · testimonials · FAQ · listings · promo banners · category grids · newsletter.

**Hero images:** full-width slider, 4–6 lifestyle images @1920×1080, warm lighting; optional 8–12s bg video with image fallback. — 🟡 **slider shipped 2026-08-06** (`HeroSlider.tsx`, 6 frames, scrim + solid fallback, reduced-motion aware). Still placeholder photography, not the client’s own 1920×1080 originals; bg video not built.

---

### B2 · Home / Explore Stays — `CNT-2`, `IMG-1`
**DO:** primary discovery, **emotion-first / search-second**. Two CTAs surface the search.
**HOLD — section order (exact):**
1. Hero banner (+ badge, headline "Every Journey Deserves a Better Stay.", search placeholder "Where would you like to go?") 2. Search bar (Destination · Check-in · Check-out · Guests; CTAs Search Stays + Explore on Map) 3. Trust strip 4. Featured Destinations 5. Trending Stays 6. Browse by Property Type (the 9 categories in A14) 7. Why Travelers Love Aajoo (6 feature cards) 8. Featured Collections (Luxury/Family/Pet-Friendly/Workcation…) 9. Travel Inspiration 10. Become a Host 11. Guest Reviews 12. Download App 13. Newsletter 14. Bottom CTA 15. Footer.
**PLUS:** SEO/meta/OG copy (provided) + full CMS field list (provided).

---

### B3 · About Us — `CNT-3`, `IMG-2`
**HOLD:** Hero ("More Than a Stay. A Place to Belong.") · Our Story · Our Vision · Our Mission · Our Values (People First, Trust Above Everything, Simplicity Matters, Empower Local Communities, Grow Together) · What Makes Aajoo Different (6) · Looking Ahead · "Welcome to Aajoo. Welcome Home." Full copy provided. **Mission/Vision → animated illustrations.** Imagery = people/community, not buildings/office stock.

---

### B4 · Contact Us — `CNT-4`
**HOLD:** Hero ("Let's Connect") · Get in Touch (Customer Support email `contactus@aajoohomes.com`, Business email, **WhatsApp**, **Office address** Hamirpur HP) · Support Availability (24/7) · Contact form — fields **Full Name · Email · Mobile · Subject · Category · Message**; **9 categories** (Booking, Hosting, Payments, Property Verification, Cancellations & Refunds, Technical, Business Partnership, Media, General) · success message · Help Center CTA · Partnership section · Follow Us (IG/FB/LinkedIn/X/YouTube) · Trust section · FAQ CTA · Footer CTA · SEO/OG · CMS fields.

---

### B5 · Login — `CNT-5`, `IMG-3`
**DO:** Guest/Host role routing (by last session/selection); **OTP-first**, frictionless, mobile-first.
**HOLD:** Hero ("Welcome Back to Aajoo") · **3 login methods**: (1) **Mobile OTP** [primary], (2) Email+password (+ forgot password), (3) **Social — Google, Apple** · switch mode (Host/Guest) · trust elements · error states (invalid mobile, incorrect OTP, session expired) · loading state · forgot-password flow · sign-up redirect · **side visual = animated gradient / 3D / glassmorphism** (no stock photo) · SEO/OG · CMS fields.

---

### B6 · Sign Up — `CNT-6`, `IMG-4`
**DO:** **Choose journey first** (Continue as Guest / Continue as Host); **Mobile OTP default**; collect only essential fields; separate Guest/Host onboarding but **single account** (role-switchable later).
**HOLD:** Hero ("Join the Aajoo Community") · Choose Your Journey · Registration methods (Mobile OTP default; Email secondary; Google/Apple/Facebook future) · **Guest fields** (Full Name, Mobile, Email opt, City opt, Referral opt) · **Host fields** (Full Name, Mobile, Email, Property Location, State, City) · Benefits (6 cards) · terms acceptance · OTP verification · success screen (Guest→Explore, Host→Complete Host Profile) · security section · side illustration · error messages · SEO/OG · CMS fields.

---

### B7 · FAQ / Knowledge Center — `CNT-7`
**DO:** fully **CMS-driven**, searchable, categorized, feedback-enabled → evolve into "Knowledge Center" (200+ FAQs).
**HOLD:** **Guest FAQs (15)** + **Host FAQs (15)** + General FAQs (all copy provided) · **14 categories** (Getting Started, Booking, Payments, Cancellations & Refunds, Account & Login, Properties, Reviews, Hosting, Property Verification, Payouts, Safety & Security, Technical, Legal & Policies, Travel Tips) · features (global search, category filters, expand/collapse, related questions, popular, recently updated, helpful/not-helpful feedback, rich text+images, internal links, SEO URLs).
**Admin CMS:** add/edit/delete FAQs, categorize, reorder, publish/unpublish, last-updated, featured, SEO metadata.

---

### B8 · Admin dashboard — future-ready modules (`0.6`)
Build with scalability so these can be added without redesign: **CMS · SEO Management · Reports · Analytics · Refund Management · User Moderation · Host Verification · Property Verification · Category Management · Amenities Management · Commission Management · Coupon Management · Notification Management.**

### B9 · Host dashboard — future-ready modules (`0.6`)
**Revenue Analytics · Occupancy Reports · Calendar Management · Smart Pricing · Offers · Coupons · Booking Insights · Guest Communication · Property Performance · Payout History.**

### B10 · Property / Booking / Blog (implied, dev priority)
- **Property page redesign** (dev priority #5).
- **Branded property placeholder** (`IMG-6`) — line-art home + soft gradient + Aajoo branding when a listing has no photos.
- **Blog** (`IMG-7`) — cover image per article; categories (Travel Guides, Hidden Destinations, Weekend Getaways, Host Success Stories, Property Tips, Festivals, Food & Culture, Local Experiences, Travel News, Announcements).
- **Negotiation/flexible pricing** feature is core (mentioned in About + FAQ) — verify it's live.

---

## PART C — Immediate dev priority (spec page 5)
1. Getting Started page structure + routing  2. New UI component library (brand)  3. Admin feature enhancements  4. Host dashboard enhancements  5. Property page redesign  6. Dynamic CMS improvements.

---

## PART D — What's blocked on client vs. actionable now

**Actionable NOW (spec gives the values/copy):**
- Brand tokens: **colors (hex given), fonts (Manrope + Plus Jakarta Sans), icons (Lucide)** → build the new theme/token system + component library.
- **All page copy** (Getting Started, Home, About, Contact, Login, Signup, FAQ) — provided verbatim in the spec.
- Getting Started page + intent-based routing.
- New property category set.
- SEO meta/OG per page (copy provided).
- CMS field scaffolding.

**Blocked / pending from client:**
- Final **logo file** + **illustration/3D/Lottie assets** + favicon/app-icon set.
- **WhatsApp number + social profile links** (address + email are given).
- Production **SMTP + SMS/OTP provider credentials** (for OTP auth, welcome/booking/verification emails).
- Google/Apple **OAuth credentials** (Firebase config).
- **Reference/design images** (coming next per your message) — for exact visual layout.

---

## PART E — Verification Results (current codebase + live site)

> Checked against `aajao-frontend-vercel` + `aajaoBackend-render` + live API on 2026-07-11.
> **✅ Present · 🟡 Partial · ❌ Missing**

### Global (Part A)
| # | Item | Status | Finding |
|---|------|--------|---------|
| A1 | New color palette | ✅ | Teal/Ivory/Amber/Navy are live in `src/index.css` and the mobile app. White-on-amber failed contrast at 2.17:1, so `--accent-ink` carries text on amber instead. |
| A2 | Manrope + Plus Jakarta Sans | ✅ | Both load in `src/index.css`; Caveat was dropped with them. |
| A3 | Lucide icons | 🟡 | Redesign now imports `lucide-react` through a generated map — react-icons is out of the bundle and the main chunk fell 3,311→2,701 kB. The 98 pre-redesign files still on `@mui/icons-material` go with the legacy screens. |
| A4 | Logo (transparent, multi-format) | 🟡 | Uses `favicon.jpeg` with a white bg container. Needs the transparent SVG set (client asset pending). |
| A5 | Favicon + app icons | ✅ | .ico/16/32/48 + SVG, 180 apple-touch, 192/512 and a maskable 512, wired by `site.webmanifest`. The old favicon was a JPEG of a *different* logo than the header renders. |
| A6 | Animated Mission/Vision | ✅ | `MissionVisionArt.tsx` — strokes draw on scroll-into-view, nothing loops, reduced-motion shows the finished drawing. |
| A7 | Professional page copy | ❌ | Current copy is generic/placeholder; the spec's provided copy is not applied anywhere. |
| A8 | CMS-driven content | 🟡 | Backend has `adminCMSSection.controller` + `tbl_cms_section`/`tbl_cms_pages`, but **no admin CMS UI** and public pages are **hardcoded**. |
| A9 | OTP-first + social auth | 🟡 | Email login + **forgot-password OTP** work. **No mobile-OTP login/signup, no Google/Apple** (no `firebase`/`react-otp-input` deps). |
| A10 | SEO (meta/OG/schema) | ❌ | No `react-helmet`; no per-page dynamic meta/OG/schema. |
| A11 | Configurable services | 🟡 | SMTP works; **SMS/OTP provider not configured**; email templates partial. |
| A12 | Scalability | 🟡 | DB is extensible; some hardcoded areas. |
| A13 | Mobile-first / perf / security | 🟡 | Responsive + RBAC present; lazy-load/perf partial. |
| A14 | New category set | ❌ | Live categories = **Villa, Resort, couple, party, Apartment + test junk**. Missing **Homestays, Cottages, Farm Stays, Heritage, Boutique, Luxury, Pet-Friendly**; needs a clean re-seed (this is the client's **category list** we were blocked on — now specified). |

### Pages (Part B)
| Page | Status | Finding |
|------|--------|---------|
| **B1 Getting Started** | ❌ | **No page, no route, no intent-routing.** Index route goes straight to Home. This is a **net-new build** (dev priority #1). |
| **B2 Home / Explore** | ✅ | Rebuilt 2026-08-07 to CNT-2: all **15 sections in spec order** with spec copy, on `/explore` (`redesign/pages/Explore.tsx`). SEO title/meta + separate OG copy wired. Newsletter posts to a real endpoint (`/newsletter/subscribe`); Guest Reviews reads `/public/reviews/recent` and shows an honest empty state — `tbl_reviews` has 0 rows. **Remaining:** section content is not yet CMS-editable (that’s A8), and the Play Store link is disabled until the Android app is published. |
| **B3 About Us** | ✅ | Rebuilt 2026-08-07 to CNT-3 on `/about`: hero, Our Story, Vision, Mission, the five named Values, six What-Makes-Aajoo-Different cards, Looking Ahead and the closing passage — copy verbatim. Mission/Vision carry the A6 illustrations. Spec supplies no SEO block for this page, so the existing title/meta stand. **Remaining:** not CMS-editable (A8). |
| **B4 Contact Us** | ✅ | Rebuilt 2026-08-07 to CNT-4 on `/contact`: all 10 sections, 6-field form, the **9 spec categories** (whitelisted server-side), SEO + separate OG copy. Form now POSTs `/contact/message` into `tbl_contact_messages` — it previously built a `mailto:` link and lost the message on any device without a mail client. **Blocked on client:** WhatsApp number + the 5 social URLs (render as plain labels, one constant each to go live). **Remaining:** not CMS-editable (A8). Admin inbox shipped at `/redesign/admin/contact-messages` (search, status, soft delete). |
| **B5 Login** | 🟡 | Email login only; no OTP-first, no Google/Apple, side-visual not to spec. |
| **B6 Sign Up** | 🟡 | Signup exists; no "choose journey first", no mobile-OTP default, no social. |
| **B7 FAQ / Knowledge Center** | 🟡 | `FAQ.tsx` exists but not CMS-driven; missing 14 categories, search, feedback, Guest/Host FAQ sets. |
| **B8 Admin modules** | 🟡 | **Present:** Property Verification, Category Mgmt, Amenities, Tags, Reviews, Users, Bookings, Finance (revenue/commission/tax/cashflow reports + reconciliation/refunds). **Missing:** CMS, SEO Mgmt, Coupon Mgmt (backend exists, no UI), Notification Mgmt, Blog, dedicated Analytics. **Added 2026-08-07:** Categories, Amenities, Contact Messages inbox. |
| **B9 Host modules** | 🟡 | **Present:** Dashboard, Properties, Ongoing, Bookings, Earnings, Statements, Performance, Communication, Support, Payout. **Missing/partial:** Calendar Mgmt, Smart Pricing, Offers, Coupons, Occupancy Reports. |
| **B10 Property / Booking / Blog** | 🟡 | Property + booking pages exist (redesign pending, dev priority #5). **Branded placeholder ❌.** **Blog ❌** (no FE; backend `tbl_blog` scaffolded). Negotiation/flexible pricing 🟡 (present). |

### Verification headline
**Mostly built:** the transactional core (search/book/pay, host portal, admin property+finance) exists and works.
**The big gaps are the Section-0 *direction* items:** (1) **rebrand** — palette + fonts + icon migration (A1/A2/A3); (2) **Getting Started landing + intent routing** (B1); (3) **OTP-first + social auth** (A9); (4) **CMS for all public content** (A8) + admin CMS/SEO/Coupon/Blog modules; (5) **spec copy + SEO** across every page (A7/A10); (6) **new category set** (A14); (7) Home/About/Contact/Login/Signup/FAQ **restructure to spec** (B2–B7).

---

## PART F — Suggested build sequence (after reference images)
Aligned to the client's dev priority (Part C) + what's unblocked:
1. **Brand token system** — new palette + fonts (Manrope/Plus Jakarta Sans) + Lucide migration, as swappable tokens (A1/A2/A3). *Foundation for everything visual.*
2. **Getting Started page + intent routing** (B1) — dev priority #1.
3. **Category re-seed** to the spec set (A14) — unblocks selectors everywhere.
4. **Auth upgrade** — mobile-OTP + Google (needs SMS provider + Firebase creds from you) (A9).
5. **CMS layer** — admin CMS UI + wire public pages (A8) + SEO meta (A10).
6. **Page restructures to spec** — Home, About, Contact, Login, Signup, FAQ (B2–B7) with the provided copy (A7).
7. **Admin/Host module gaps** (B8/B9), **Blog** (B10), property-page redesign.

_Verification complete. Next: apply the client's reference images to lock the visual layout, then execute from Part F._
