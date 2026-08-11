# AajooHomes — Inputs Required from Client

**Purpose:** This document lists everything we need **from your side** to implement the changes agreed in the recent meeting and the *Post-25 Release* sheet — the new **Getting Started page**, the website-wide **content / images / icons** refresh, and the **missing admin & host functionalities**.

Please treat each item's **ID** (e.g. `GS-1`, `BR-2`) as a reference when you reply or send files, so nothing gets lost.

> **How to send assets:** share a single Google Drive / cloud folder (or Figma link) organized by the section headings below. Preferred formats are noted per item. For anything you're unsure about, leave a note and we'll advise.

---

## 0. Quick summary — the 6 things that block us most
1. **Getting Started page sketch/wireframe** + the entry-flow logic (GS-1, GS-2).
2. **Final website copy** for every page (Section 4) — currently placeholder text.
3. **Brand assets**: transparent logo, chosen font, icon set, brand colours (Section 2).
4. **Real support details**: WhatsApp number, phone, email, office address (CFG-1).
5. **Email/SMS provider** so real OTP + password-reset emails can be sent (CFG-2).
6. **Detailed specs for the missing admin/host features** you mentioned (Sections 7 & 8).

---

## 1. Getting Started Page (new)

You said you'll design how a first-time visitor should enter the site. We need:

| ID | What we need | Format |
|----|--------------|--------|
| GS-1 | **Sketch / wireframe / Figma** of the Getting Started page layout | Figma link or image/PDF |
| GS-2 | **Entry-flow logic** — when a *first-time* visitor lands, what do they see, and how are they routed to **Explore Stays (renter)** vs **Become a Host**? What happens for a **returning / logged-in** visitor? | Short written flow or arrows on the sketch |
| GS-3 | The **two main call-to-action** buttons — exact labels + which one is the primary (highlighted) | Text |
| GS-4 | **Content** for this page (headline, sub-text, any section copy) | Text/Doc |
| GS-5 | **Background image(s)** for the hero/slider (currently flat colours) | JPG/PNG, ≥1920px wide, or a set for the slider |
| GS-6 | Confirm what should be **removed** here (per the sheet: floating tags, the "12K+ properties" stats, Find-Your-Stay, location map, FAQ, reviews, footer) — and what, if anything, stays | Confirmation |
| GS-7 | **Nav bar behaviour** on this page — the sheet says show only "Getting Started", then reveal "Explore Stays / Become a Host" on scroll. Please confirm the exact nav items + scroll behaviour | Confirmation |

---

## 2. Brand assets (used across the whole site + app)

| ID | What we need | Notes / format |
|----|--------------|----------------|
| BR-1 | **Logo — transparent background**, high-res (the current logo sits in a white box; sheet R15) | SVG preferred, + PNG @1x/2x/3x |
| BR-2 | **Brand font** — the "aajoo" wordmark font + the body font you want site-wide (sheet R16) | Font files (.ttf/.otf) **with licence**, or Google Fonts name |
| BR-3 | **Icon set** — the sheet repeatedly asks for "premium / current-market" icons across the app (R127, R128, R253). Either provide an icon pack, or approve a library (e.g. Lucide / Phosphor / Heroicons) and a style (line vs filled) | Icon files or library + style choice |
| BR-4 | **Brand colour palette** — confirm the primary/secondary/accent hex codes (we currently use Indigo `#1B2447`, Sand `#EFE7D6`, Clay `#C16345`) | Hex list |
| BR-5 | **Favicon / app icon** (for browser tab + mobile app launcher) | 512×512 PNG |
| BR-6 | **Mission & Vision icons** + confirm you want **animation** there (sheet R134) | Icons / Lottie files |

---

## 3. Images (per section)

Please provide real images to replace stock/placeholder visuals. High-res, landscape unless noted.

| ID | Where | Item |
|----|-------|------|
| IMG-1 | Home / Getting Started hero | Hero + slider backgrounds (see GS-5) |
| IMG-2 | About Us | Main About image + the "What makes us different" image (sheet R117, R126) |
| IMG-3 | Login page | Side image / colour slider / animation (sheet R169) |
| IMG-4 | Sign-up page | Side image / animation |
| IMG-5 | Become a Host | Section image(s) |
| IMG-6 | Property placeholders | A branded fallback image for listings without photos |
| IMG-7 | Blog | Cover images for blog/news articles |

---

## 4. Website copy / content (final text)

Most pages currently show **placeholder or draft text**. We need the **final copy** for each. A Google Doc per page is ideal.

| ID | Page / section | What we need |
|----|----------------|--------------|
| CNT-1 | Getting Started | Headline + supporting copy (see GS-4) |
| CNT-2 | Home (Explore Stays) | Hero heading/sub-text, any section intros |
| CNT-3 | About Us | Full page copy incl. Mission & Vision text (sheet R118) |
| CNT-4 | Contact Us | Intro copy + the details in CFG-1 |
| CNT-5 | Login | Heading + supporting copy (sheet R170) |
| CNT-6 | Sign-up | Any intro copy + field help text |
| CNT-7 | FAQ | Final question/answer list (host + guest) |
| CNT-8 | Terms & Conditions | Final text — **separate host + user** versions (the site already supports both) |
| CNT-9 | Privacy Policy | Final text |
| CNT-10 | Cancellation Policy | Final text |
| CNT-11 | Host Agreement | Final text |
| CNT-12 | State Regulation | Final text (moving to footer per sheet R159/R360) |
| CNT-13 | Why Host with Aajoo | Final copy |
| CNT-14 | Help Center | Final content |
| CNT-15 | Footer | Company blurb, links list, social handles |
| CNT-16 | Announcements/banners | Any promo strip copy for the home page |

> Note: FAQ, About, Privacy, Safety, Terms are already wired to load from the admin/back-office, so once you give us the text we can load it centrally.

---

## 5. Blog / News

The sheet (R415–R417) asks for a Blog + "Find your listing" in the nav, with **host-specific and user-specific** blogs that are connected for major info (like news).

| ID | What we need |
|----|--------------|
| BLG-1 | Confirm the blog structure — separate Host vs User feeds, with shared "news" items? |
| BLG-2 | Initial set of **blog/news articles** (title, body, cover image, category, host-or-user audience) |
| BLG-3 | Who will maintain blogs going forward (you via admin, or us)? |

---

## 6. Credentials, contacts & integrations (config)

These are needed for real functionality and go-live. Please share securely (not in email/chat where possible).

| ID | Item | Why we need it |
|----|------|----------------|
| CFG-1 | **Support WhatsApp number, phone, email, and office address** | Wired behind "Support" / "Chat with host" / Contact page (placeholders today; sheet R476). |
| CFG-2 | **Email/SMS provider** (SMTP creds, or Twilio/MSG91 account) | To send **real OTP** and **password-reset** emails. Currently there is **no mail server**, so OTP uses a test code and "Forgot password" can't deliver. |
| CFG-3 | **Razorpay LIVE keys** (Key ID + Secret) + business KYC done | To take real payments. Currently in **test mode**. |
| CFG-4 | **DIDIT production** account confirmation (API key, webhook secret, workflow) | Live identity (KYC) verification. |
| CFG-5 | **BotPenguin production** bot config / API token | The support chatbot (and its behaviour: not auto-open, only on user dashboard/profile — sheet R428, R484). |
| CFG-6 | **Google Maps API key** (production, billing enabled) | Maps on search / property / current-location. |
| CFG-7 | **Social media links** | Footer icons. |
| CFG-8 | **SEO / business profile info** (business name, description, sitelinks structure, Google Search Console access) | To make the Google result look like the reference (sheet R2). |
| CFG-9 | **App store accounts** (Google Play, and Apple if iOS) + developer access | To publish the mobile app. |
| CFG-10 | **Domain / DNS access** (if not already with us) | Deployment + email + SEO. |

---

## 7. Admin dashboard — missing functionality (please confirm & spec)

You mentioned some admin features are missing. Below is our understanding from the sheet — **please confirm each and add detailed requirements for anything not listed**. For each feature we need: *what it should do, who can use it, and any fields/rules.*

| ID | Feature (our understanding) | Need from you |
|----|------------------------------|---------------|
| ADM-1 | **Add-Property form inside Admin** — the same property form hosts use, so admin can add listings directly (sheet R443) | Confirm + any admin-only fields |
| ADM-2 | **Invoice PDF download** — a download icon in the Transactions list to export invoice PDFs (sheet R482) | Confirm invoice layout/branding |
| ADM-3 | **Chatbot placement** — BotPenguin should **not** be part of the admin dashboard (sheet R429) | Confirm |
| ADM-4 | **Property verification workflow** — approve/reject host listings (built recently). Confirm the exact statuses, rejection reasons, and any notification to the host | Statuses + notification rules |
| ADM-5 | **Any other missing admin screens/controls** discussed in the meeting but not in the sheet | Full list + description |

> Please be specific — e.g. "Admin should be able to *feature* a property", "Admin should *refund* a booking", "Admin should *edit host payout %*", etc.

---

## 8. Host dashboard — missing functionality (please confirm & spec)

Same as above — our understanding from the sheet; **please confirm and detail**.

| ID | Feature (our understanding) | Need from you |
|----|------------------------------|---------------|
| HOST-1 | **Ongoing bookings page** on the host side (sheet R358) | Confirm what it shows |
| HOST-2 | **Host property list** view (sheet R359) | Confirm columns/actions |
| HOST-3 | **Property edit** available across the dashboard (sheet R334) | Confirm which fields are editable post-approval |
| HOST-4 | **State Regulations** page accessible to hosts (sheet R360) | Confirm content (see CNT-12) |
| HOST-5 | Replace the **"Total Spent" box** on the host dashboard with something relevant (sheet R480) | Tell us what metric should replace it |
| HOST-6 | **Support UI** on host side + real support contact (sheet R356, CFG-1) | Confirm |
| HOST-7 | **Distinct host vs user interface colours** (sheet R361) | Confirm the host palette (or keep shared) |
| HOST-8 | **Any other missing host screens/controls** discussed in the meeting | Full list + description |

---

## 9. Open decisions / clarifications we need

| ID | Question |
|----|----------|
| DEC-1 | **Getting Started page** — should it be a **brand-new entry/splash page** (and the current home content moves to an "Explore Stays" page), or a **restructure of the current home** in place? |
| DEC-2 | Which pages should be **editable by you via the admin** (CMS) vs fixed? |
| DEC-3 | **Property detail redesign** (sheet R444–R458: big image + grid gallery, guests/beds/rating, "meet your host", availability calendar, map after reviews) — please confirm the layout via the sketch. |
| DEC-4 | **Mobile app scope** — which of these website/redesign changes must also appear in the mobile app, and are we releasing **Android first** or Android + iOS together? |
| DEC-5 | **Filters** — confirm the exact filter options you want on the map/Homes page (sheet R433/R434). |
| DEC-6 | **Categories, amenities, tags** — confirm the master lists (you manage these in admin; we need the initial set). |

---

## 10. Priority (so we can start in parallel)

- **Start-blocking (please send first):** GS-1, GS-2, BR-1, BR-2, CFG-1, and the Admin/Host feature specs (Sections 7 & 8).
- **Needed for content pass:** all of Section 4 (copy) + Section 3 (images).
- **Needed for go-live only:** CFG-2, CFG-3, CFG-4, CFG-9.

Once we receive the start-blocking items we can begin immediately on the Getting Started page and the missing admin/host features in parallel, then apply the content/images as they arrive.

---

*Prepared by the development team, referencing the current AajooHomes codebase and the Post-25 Release change list. Reply against the item IDs above.*
