# Documentation vs Codebase — Gap Audit

## 1. What this is

You asked whether anything in the five documents below is still pending or differs from what is built. This is that check, document by document, verified against the code and the live system rather than from memory.

| Document | Verdict |
|---|---|
| Aajoo Homes Pricing Architecture | **Byte-identical to the pricing document answered earlier today.** Nothing new. |
| Aajoo Homes — Section 0 — Quick Summary & Project Direction | Content pages built to spec; **entry routing, brand assets, banners and CMS coverage are open** |
| CNT-11 Host Agreement (+ CNT-13–16, DEC-1–6, HOST-1–7, ADM-1–5) | **The largest block of open work**, including one legally material gap |
| Aajoo Homes — Legal & Compliance Documentation Suite | **18 of 20 documents are not published anywhere** |
| AAJOO HOMES PRIVATE LIMITED — Privacy Policy | **The v1.0 text you supplied is not the text on the site or in the app** |

Two things need a decision from you before code can move, because the documents contradict each other or contradict a fix you asked for. They are in section 8.

---

## 2. The one legally material gap

The Host Agreement's own **Developer Requirements** (page 5) ask for four things so that electronic acceptance is enforceable. One is done.

| Requirement | State |
|---|---|
| Require Hosts to scroll through the Host Agreement before publishing their first property | **Not done.** The agreement text is not shown anywhere in the flow, and there is no page to show. |
| Mandatory checkbox with the stated wording | **Partly.** Step 5 has seven declaration checkboxes, including "I accept the Host Agreement" — but none of them links to a document, so nothing has been read. |
| Store agreement version, date and time of acceptance, IP address, device information | **Not done.** `property_submission` stores one boolean per declaration and a single `psb_submitted_at` for the whole submission. No version, no IP, no device, no per-declaration timestamp. |
| Re-accept whenever a material update is published | **Not done.** There is no version to compare against. |

As it stands, a host ticks a box next to the words "I accept the Host Agreement" for an agreement that does not exist on the platform, and we keep no record of which version they accepted or when. That is the item to fix first.

---

## 3. Legal & Compliance Suite — 20 documents

The suite says these "should be available from the website footer, mobile app, and during user onboarding where applicable."

**Published today (4):** a single combined Terms & Conditions, Privacy Policy, Cancellation & Refund Policy, State Regulations. Plus a Safety page and a Help Center that are not from the suite.

**Not published (18):** Guest Terms & Conditions and Host Terms & Conditions as separate documents · Host Agreement · Community Standards · Trust & Safety Policy · Responsible Hosting Policy · Responsible Travel Policy · Cookie Policy · Payment Policy · Verification Policy · Content Policy · Review Policy · Referral & Rewards Policy · Promotional Offers Policy · Accessibility Statement · AI Usage & Recommendation Policy · Data Retention & Deletion Policy · Copyright & Trademark Policy.

**And the four that are published do not carry your text.** The Privacy Policy you supplied has 51 numbered sections across three parts; the live page has ten short summary paragraphs written before that document existed. Same for Terms. The app fetches its own separate copy from the server, also short-form, also not yours — so there are currently **three different Privacy Policies** in play: the site's, the app's, and the one in your PDF.

**Broken links in the legacy footer**, measured live:

| Link | Goes to | Result |
|---|---|---|
| Cancellation Policy | `/terms-condition` | wrong page — `/cancellation-policy` exists |
| Host Agreement | `/terms-condition` | wrong page — no Host Agreement page exists |
| FAQ | `/faqs` | **404** |
| Find Your Stay | `/property/list` | **404** |
| User Dashboard | `/user-dashboard` | **404** |

**One more thing worth knowing.** The admin panel has a Terms & Conditions editor that writes to `tbl_terms_conditions`. That table has **zero rows**, and neither the website nor the app reads it — the website's page is hardcoded and the app's comes from a hardcoded controller response. So the editor edits nothing, and the policies are not CMS-editable, which DEC-2 explicitly requires ("Policies (IMPORTANT): Privacy Policy, Terms & Conditions, Cancellation Policy, Host Agreement — must be editable 100%").

**Privacy Policy specifics.** §50 names a Grievance Officer at `grievance@aajoohomes.com` — not published anywhere. The section-8 contact addresses (`hello@`, `support@`, `hosts@`, `privacy@`, `legal@`) are not on the site either. Account deletion (§34) and access/correction (§33) do exist and work.

---

## 4. Section 0 — what is built and what is not

**Built to spec.** CNT-1 Getting Started, CNT-2 Explore homepage (all fifteen sections in the specified order, copy verbatim), CNT-3 About, CNT-4 Contact, CNT-5 Login, CNT-6 Sign Up, and **CNT-7 FAQ in full** — global search, category filters, expand/collapse, related questions, popular, recently updated, helpful/not-helpful voting, rich text, internal links and per-question SEO URLs. CNT-13 Why Host with Aajoo exists.

**Open:**

- **GS-2 entry routing.** `/` currently sends a signed-out visitor to `/explore`, not to Getting Started. This was changed deliberately — see section 8.
- **GS-7 navigation.** The minimal-then-expand-on-scroll behaviour is not implemented; the header is the Airbnb-pattern rebuild delivered earlier.
- **0.4 Support information.** The office address, WhatsApp number and social profiles named in the document are not on the site. The redesigned footer's social icons still point at bare `instagram.com` / `facebook.com`.
- **0.5 Configurable messaging.** Email and OTP templates are in code, not configurable without a deploy.
- **BR-1, BR-5, BR-6.** Logo variants, favicon and app-icon sets, and the Lottie/3D mission-and-vision animations are all waiting on brand assets you have not sent yet.
- **CNT-14 Help Center.** The current page is a static list of questions. The specified structure — guest/host split, smart search with auto-suggestions, trending and recently-viewed articles, an emergency section, SLA targets, and ticket-raising from within the Help Center — is not there. Ticketing itself exists for both guests and hosts, just not reachable from this page.
- **CNT-15 Footer.** The eight-section mega footer, contact block, newsletter, trust badges, popular destinations, SEO link grid, disclaimer and full CMS control are not built. The current footer has four columns and three legal links.
- **CNT-16 Announcements & Promotional Banners — nothing exists.** No table, no admin screen, no scheduling, no targeting by user type / location / device, no priority, no countdown, no impression or click tracking. This is the single largest untouched module in the pack.

---

## 5. Decisions (DEC-1 to DEC-6)

| | State |
|---|---|
| DEC-1 Getting Started owns `/` | **Differs — see section 8** |
| DEC-2 Hybrid CMS | Partly. Content pages are hardcoded; policies are hardcoded; banners and announcements have no CMS at all. Blog, FAQ, homepage sections and SEO are CMS-driven. |
| DEC-3 Property detail layout | Matches, section for section. |
| DEC-4 Android first, web parity | Largely matches. |
| DEC-5 Filter master list | **Four of seven groups missing.** Built: property type, price (free min/max rather than the four named bands), guest rating, pet-friendly. Missing: all location filters (city, village, mountain/river/forest view, near lake), stay features (entire place / private room / shared room), the amenity filters (WiFi, kitchen, parking, pool, bonfire, work-friendly), all experience filters (adventure, relaxation, family, couples, workation), and the special filters (instant booking, verified, discounted, top rated, new listings). |
| DEC-6 Categories, amenities, tags | **Categories:** "Eco Stay" is missing, and eight test rows are live in production — `couple`, `party`, `test`, `test`, `add one cate`, `Test Api Category updat`, plus `Resort` and `Pool House` which are not on your list. **Amenities:** 44 rows, covering the master list. **Tags:** the ten SEO tags are not seeded — the table holds six unrelated rows including `Test Tag update` and `add new`, and **no property carries a tag at all**, so the tag system is inert. |

---

## 6. Host dashboard (HOST-1 to HOST-7)

Most of this exists: ongoing bookings, property list, calendar, earnings, payouts, statements, messages, negotiations, reviews, performance, boost, support with ticketing. HOST-4 is done — there is no "Total Spent" box; occupancy, earnings and payouts are in its place.

**Open:**

- **HOST-3 smart edit rules.** The three tiers — always editable, needs admin review, locked — are not implemented. A host editing an approved listing re-enters the review queue but **stays live**, and every field is equally editable: property name, address, category and guest capacity can all be changed on a live listing without approval.
- **HOST-7:** Listing Optimizer (photo score, description score, AI suggestions, ranking tips) and Compliance Center (document status, verification progress, state-regulation reminders) do not exist.

---

## 7. Admin dashboard (ADM-1 to ADM-5)

- **ADM-1 — admin-only fields: none of them exist.** No commission override per property, no priority ranking score, no visibility boost score, no featured-listing toggle, no manual-verified flag, no verification notes, no legal approval status, no state-regulation compliance tag, no fraud risk level, no manual-review toggle, no payment-hold flag. (Host-paid Boost exists, which is a different thing.)
- **ADM-2 — invoice:** built and downloadable, with invoice number, booking id, dates, host name, guest, subtotal, discount, taxes, payment reference and a system-generated footer. Missing: **the GST number** (we do not have your GSTIN) and a separate **Platform Fee** line.
- **ADM-3 — BotPenguin placement:** correct. The widget is scoped to the signed-in renter area and host support; it does not load in the admin dashboard.
- **ADM-4 — verification workflow:** the state machine, the four admin actions and the host notifications are all built. **The preset rejection-reason list is not** — rejection reasons are free text, so the nine named reasons cannot be reported on.
- **ADM-5 — modules:** analytics, property control, user management, financial control, disputes, CMS, location and category control, and the role system are built. **Missing: the fraud & risk engine** (automatic flagging of fake listings, fake bookings, suspicious payments, duplicate accounts) **and the marketing control panel** (banners, campaigns, featured listings, homepage control) — the latter being CNT-16 again.

---

## 8. Two things only you can decide

### The front door

DEC-1 says Getting Started should own `/`. It does not: a signed-out visitor at `aajoohomes.com` is sent to `/explore`.

That was changed on purpose, and the reason still stands. The original build routed `/` by a `localStorage` flag written the first time someone chose an experience. The flag never expired and nothing cleared it, so anyone who had once tapped "Become a Host" landed on the host pitch every time afterwards, on that browser, with no way back to the front door by typing the address. It reads as a broken site. Separately, search engines have no `localStorage`, so Google only ever saw `/getting-started` — the homepage was never what `/` resolved to for indexing.

Both problems are solvable while honouring DEC-1: give the stored preference an expiry, keep an always-visible way back, and serve crawlers the real page. **Tell us to do that and we will.** We did not flip it back on our own because the current behaviour was itself a fix to a defect you reported.

### The brand: your documents disagree with each other

| | Section 0 (BR-2 / BR-4) | Later section of the Host Agreement PDF | HOST-6 |
|---|---|---|---|
| Headings | Plus Jakarta Sans | **Satoshi** ("LOCK IT") | — |
| Body / UI | Manrope | **Inter** | — |
| Primary | Evergreen Teal `#0F766E` | Ocean Teal `#0D9488` | Deep Indigo `#1B2447` |
| Background | Warm Ivory `#FAF8F4` | Warm Ivory `#FDF7F0` | Warm Sand `#EFE7D6` |
| Accent | Golden Amber `#E8A317` | Sunset Orange `#FF7A00` | Clay Orange `#C16345` |
| Dark | Charcoal Navy `#1F2937` | Deep Navy `#111827` | — |

HOST-6's palette is the Indigo + Sand + Clay scheme that **BR-4 explicitly rejects** two documents earlier. And the same PDF that says "lock in Satoshi and Inter" also says "Replace Poppins" — which is the display face the Android app currently uses.

The website today implements **Section 0's** direction: Plus Jakarta Sans + Manrope, Evergreen Teal, Warm Ivory, Golden Amber, Charcoal Navy. The app uses Manrope with Poppins for display.

We are not going to guess between three palettes and two type systems. **Name the one that wins and we will apply it across website, app, admin, emails and PDFs in a single pass.** Note that Satoshi is not a Google font — it needs a licence, which you would need to buy before we can ship it.

---

## 9. Suggested order of work

1. **Host Agreement acceptance** — publish the agreement, show it in the flow, and record version, timestamp, IP and device. This is the only item on this list with legal consequences.
2. **The legal suite** — publish all 20 documents from your text, wire them to one CMS-editable source that the website *and* the app both read, and fix the five broken footer links.
3. **Brand decision**, then one pass across every surface.
4. **Announcements & banners (CNT-16)** and the admin marketing panel — one module, two requirements.
5. **ADM-1 admin control fields** and **ADM-4 preset rejection reasons**.
6. **DEC-5 filters** and **DEC-6 tag seeding** (plus deleting the eight test categories from production).
7. **CNT-14 Help Center** and **CNT-15 mega footer**.
8. **HOST-3 edit tiers**, **HOST-7 optimizer and compliance centre**, **ADM-5 fraud engine**.

Nothing in items 3 to 8 blocks a launch on its own. Items 1 and 2 do.
