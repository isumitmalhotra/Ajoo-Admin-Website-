# AAJOO Homes — Master Pending Tasks (single source of truth)

> **Reconciled 2026-09-04** against the live site, the live database and the three
> repos; **updated 2026-09-05** after tester builds 14–16, the proactive defect
> sweep, and a fresh set of DB counts. Supersedes the 2026-07-11 edition, which
> had drifted badly — nine of its open items were already done and two of its
> "done" claims were wrong.
>
> **Repos:** FE `D:/Projects/aajao-frontend-vercel` (React/Vite → Vercel) ·
> BE `D:/Projects/aajaoBackend-render` (Node/Express/Sequelize → `aajaodev.onrender.com`) ·
> Mobile `aajoo_app_2026/` (Flutter). Deploy = push to `main`; **DB migrations do NOT auto-run.**
> Tester build in circulation: **17 (1.0.0+17)**, `aajoo-homes-1.0.0-build17-release.apk` at repo root.
> Documents delivered 2026-09-05 (repo root): `UAT_WebApp_2026-09-05.docx` (81 cases) · `UAT_AndroidApp_2026-09-05.docx` (55 cases) ·
> `Delivery_Delay_Analysis_2026-09-05.docx` · `Deployment_Options_2026-09-05.docx`.
>
> **How to read the evidence column.** `verified` = checked against production or
> the live DB and the check is named (dated 09-04 unless it says 09-05). `code` =
> read in the source. `carried` = taken from the previous edition and **not**
> re-checked — treat those as the least trustworthy rows here.

---

## How this list is ordered

By **who is blocked**, not by component. Most of what is left is not engineering
work; sorting by owner is what makes that visible.

| Section | Owner | Open |
|---|---|---|
| [1. Client decisions](#1-blocked-on-client-decisions) | Client | 8 |
| [2. Ops / Render access](#2-blocked-on-ops--render-access) | Whoever holds Render + GCP | 7 |
| [3. Engineering](#3-engineering--genuinely-open) | Us | 12 |
| [4. Contract deliverables](#4-contract-deliverables-) | Us | 8 |
| [5. Section-0 redo](#5-section-0-site-redo--separate-sow) | Blocked on a signed change order | 20 |
| [6. Unproven, not broken](#6-unproven-not-broken) | Us + tester | 9 |

**If only two things get done:** §2.1 (live payment keys) and §1.1 (delete the
seed listings). The first means the product currently looks like it is taking
money and is not. The second gates every honest SEO number on the site.

---

## 1. Blocked on client decisions

| # | Item | Why it is blocking | Evidence |
|---|---|---|---|
| **1.1** | **Delete the 29,227 seed listings** | 29,236 undeleted listings; **29,227 belong to host 100 and are live**, 16 belong to real hosts. Sitemap excludes host 100, so the public site is **26 URLs** (5 property, 7 blog, 14 pages). Every SEO figure, every bulk preview and every template test is measured against fabricated data until these go. | verified 09-05 — DB count, live sitemap |
| **1.2** | **Switch analytics on — after two sign-offs** | The consent banner is **built and live** (the earlier wording here was stale): three categories, "Only essential" at equal weight, Consent Mode v2 defaults denied, Hotjar barred from host/booking/account/admin routes, chat widget off the public pages. Nothing loads until the admin switch is on **and** the visitor grants the category. What is still the client's: (1) counsel reads the Privacy Policy's cookie section (`/Privacy-Policy#cookies`, drafted 09-05, names every provider); (2) if Hotjar is used, set its URL targeting to public pages only; then flip **Admin → Global SEO → Load tracking scripts**. | verified 09-05 — live banner, storage and script list on an anonymous visit |
| **1.3** | **Cash / UPI collection — 4 decisions** | The rail is **built** (`tbl_host_dues`, 24 rows, offset against payouts). What is still missing is policy: who confirms collection, when, how the 15% + GST is recovered, and what happens if the host never confirms. Detail in §7. | verified — 24 rows in `tbl_host_dues` |
| **1.4** | **Cancellation policy — the admin controls the document asks for** (was E-4; the copy itself shipped 09-05, see §8a) | Policy v1.0 is implemented and live on web + app (build 17). What the document's *Admin Panel* section asks for and is **not** built: enable/disable a policy, create new policy types, restrict a policy to approved hosts, and an override in exceptional cases. Today the five policies are code-defined; Super Strict is assigned by an admin through the Edit-property form, which is the "business approval" in practice. Building the admin module is ~1.5 days; decide whether it is wanted before launch or after. Also unbuilt from §4 of the document: a guest-initiated *booking modification* flow (dates/guests/duration with host approval and a price difference) — bookings are cancelled and rebooked instead. | verified 09-05 — code + live endpoints |
| **1.5** | **Weather provider + key** (was E-2, RENT-7) | Renter-dashboard weather widget cannot start without a provider choice. | carried |
| **1.6** | **Brand assets** — logo set, favicon/PWA icons, animated illustrations, WhatsApp number, social links, reference designs (was E-5, S0-ASSET-1…5) | Gates most of Section-0. | carried |
| **1.7** | **The five test listings that are now the public catalogue** | Of the 6 live real-host listings, **5 are tester approvals**: four on 2026-09-04 so the site was not empty after approval started gating visibility — Garg Resorts (29263), Tharamani Farm Retreat (29265), Vrindavan Garden Farm Stay (29277), Delhi Green Farm Stay (29279 — the last two renamed from "Aish mobile host property…") — and Aish camping in the hills (29289) on 09-05, approved to prove the audit-trail fix. They are tester accounts' listings with tester phone numbers. Decide whether they stay through launch or come down with the seed data. | verified 09-05 — `property_submission` + `tbl_properties` |
| **1.8** | **Where the platform runs after UAT** | `Deployment_Options_2026-09-05.docx` compares staying on Render + Vercel with AWS, Azure, GCP, DigitalOcean and a VPS, with indicative costs. Recommendation: stay through UAT (Render Starter, $7/mo), then **DigitalOcean Bangalore** (~$45–75/mo) as the first managed home in India; hyperscaler only with an owner or credits; VPS only with a named operator. Needs the client's answers to §8 of that document: expected traffic, budget, who operates, existing cloud agreements. | doc |

---

## 2. Blocked on ops / Render access

| # | Item | Failure mode if missed | Evidence |
|---|---|---|---|
| **2.1** | **Live Razorpay keys + `ALLOW_TEST_PAYMENTS` off** | Checkout opens, the booking confirms, an invoice is issued — and **nothing is collected**, because every order was created against the bundled test key. Invisible from the UI by design; `/health/env` reports it. | code — `config/payments.config.js` |
| **2.2** | **RazorpayX credentials** (`RAZORPAYX_KEY_ID`, `_KEY_SECRET`, `_ACCOUNT_NUMBER`, `_WEBHOOK_SECRET`) | Approving a payout fails at the click with "Payouts are not configured". **Not verifiable without pressing Approve on a real ₹27,980 payout**, which was not done. Assume unset until someone checks Render. | unverified — see note |
| **2.3** | **`REQUIRE_IMAGE_ALT=true`** | Server accepts an image upload with no description. Both clients have refused to upload without one since build 12; **build 16 is with testers now**, so there is no longer a reason to wait. | code |
| **2.4** | **`HEALTH_TOKEN` (or `ADMIN_API_TOKEN`) unset** | `/health/env` returns bare `{"ready":true}`. The detail — including **`dbCutoverSafe`**, the check that would have caught July's outage — is unreadable by anyone. | verified 09-05 — probe still returns `{"ready":true}` only |
| **2.5** | **Credential rotation** | Deferred by instruction. Everything historic is in git history: DB password, Razorpay secret, Cloudinary secret, Gmail app password. | carried |
| **2.6** | **Google Cloud budget alert** | Maps + Places keys are live and unmetered. | carried |
| **2.7** | **Render Starter ($7/mo) + confirm Clever Cloud backups** | The API is on Render's free tier: 30–50 s cold starts hidden by a keep-alive ping, and a disk that is wiped on deploy (invoices are written there). Starter removes the sleep; Clever Cloud's backup schedule and retention should be confirmed in its dashboard before UAT — it is the only copy of the database. | verified — `KEEP_ALIVE_SETUP.md`; DB 43 MB on Clever Cloud |

> **On 2.2 —** the "not configured" message is raised inside the *approve*
> handler, not on page load, so its absence from the Payout Queue proves nothing.
> The queue renders and shows QUEUED/FAILED rows either way. The honest state is
> unknown; confirm in Render rather than by clicking.

---

## 3. Engineering — genuinely open

| # | Item | Notes | Evidence |
|---|---|---|---|
| **3.1** | **Purge junk categories** | `/common/categories` serves **13** to the public, including `Resort`, `couple`, `party` and `Pool House`. `tbl_categories` also holds `test`, `test`, `add one cate`, `Test Api Category updat`. One UPDATE fixes web **and** app. This is the app sheet's A-52. | verified — public endpoint |
| **3.2** | **64 of 65 images have no ALT text** | Blocks image-sitemap captions, which cannot populate until descriptions exist. | verified — Image SEO screen |
| **3.3** | **WebP / `f_auto` delivery** | Cloudinary URLs carry no `f_auto`. Core Web Vitals, not indexing. | verified — sitemap image URLs |
| **3.4** | **`/` and `/explore` have identical titles** | Two pages competing for one query. One line of copy, or canonical `/explore` → `/`. | verified — SEO Health |
| **3.5** | **Orphan pages / broken internal links** | Needs a crawl of the rendered site; nothing in the admin does one. The health dashboard lists it as unchecked rather than reporting a false zero. | verified — SEO Health |
| **3.6** | **Cloudinary account audit** | Shared/polluted account, ~704 assets. It has already published a real person's CV as a property photo once. Nobody has swept the rest. | carried |
| **3.7** | **Host `whatsapp` field** (was HOST-17) | Column still absent from `tbl_users`; a front-end-only change is dropped by `stripUnknown`. Needs a migration first. | verified — `SHOW COLUMNS` |
| **3.8** | **Admin Notification Management** (part of S0-ADM-1) | The only module from that list with no route. CMS, SEO, Coupons and Analytics all exist. | verified — 0 routes in `App.tsx` |
| **3.9** | **Lucide icon migration** (S0-BRAND-3) | `lucide-react` installed; MUI icons still in use app-wide. Cosmetic, and cheaper to do inside Section-0. | carried |
| **3.10** | **Web lint baseline is red** | `npm run lint` reports **~600 problems, 540 of them `no-explicit-any`**, so lint cannot gate the Vercel build (which runs `tsc -b` only). The empty-catch rule added on 09-05 therefore only bites when someone runs lint by hand. Either downgrade `no-explicit-any` to a warning and clean the rest, or fix the anys — then add `lint` to the build. | verified 09-05 — `eslint .` |
| **3.11** | **Report of listings whose stored contact fails the 6–9 mobile rule** | Two of yesterday's renames were blocked because the admin form re-validated a stored `1425369807`. The form now validates only what changed, but the junk is still stored and will surface the next time a host edits those listings in the wizard. A one-off query + host nudge. | verified 09-05 — the two numbers |
| **3.12** | **Leftovers from the sweep** | (a) Two screen-level empty catches remain in the app (`host_profile.dart:67`, `csc_picker.dart:750`); every *service* is clean. (b) `tbl_book_statuses` ids 12/13/14 double as payout-request states (`statusPayoutPending/Successfull/Failed` in `commonConfig`); 13 now counts as revenue by decision, but a booking table sharing ids with a payout table is a cleanup waiting to bite. | verified 09-05 — `flutter analyze`, `config/commonConfig.js` |

---

## 4. Contract deliverables 📄

Functional scope is delivered; these are the contractual artifacts. All still open.

| # | Item | Notes |
|---|---|---|
| **4.1** | **API documentation (OpenAPI/Swagger)** | No swagger/openapi tooling in the repo. |
| **4.2** | **Solution Architecture Document** | |
| **4.3** | **FMS — Functional Specification** | |
| **4.4** | **HMS — Functional Specification** | |
| **4.5** | **Security & Compliance doc + RBAC matrix** | The RBAC itself exists (`config/adminRoles.js`, incl. `SEO_MANAGER`); the document does not. |
| **4.6** | **Test suite to contract standard** | **43 backend test files pass** on `npm test` and **138 app tests** on `flutter test`, but the contract asks for >80% measured coverage, 200+ integration tests, plus load and OWASP reports. No coverage tooling is wired. |
| **4.7** | **Deployment guide + operational runbook + KT docs** | `DEPLOY_RUNBOOK.md` and the handoffs exist; `Deployment_Options_2026-09-05.docx` (05-09) covers requirements, sizing, tools, providers, cost and a migration plan. Still to formalise: the runbook for whichever host is chosen (§1.8) and the KT pack. |
| **4.8** | **UAT test cases + sign-off package** | **Manuals delivered 2026-09-05** — web (81 cases, 8 modules) and Android (55 cases, 6 modules), each with environment, accounts, procedure, defect template and sign-off table. Execution and sign-off are the client's; **an internal dry run of both manuals is recommended first** — see §6 for the cases that have only code/test-level verification so far. |

---

## 5. Section-0 site redo — separate SOW

Per contract §6 a visual overhaul is **outside** the ₹1,60,000 contract and needs
a signed change request. Per-item status lives in
[`AAJOO_SECTION0_TASKLIST.md`](AAJOO_SECTION0_TASKLIST.md) — check there before
quoting anything here.

**Already shipped from this section** (do not re-scope): brand palette `#0F766E`,
typography, the 9-category set, the CMS admin, and **the whole SEO layer**
(S0-SEO-1 — Phase 1 tasks 0–10, live; handover pack `SEO_Phase1_Handover.docx`
sent to the SEO team 2026-09-04).

**Still open:** Getting Started landing + intent routing (S0-GS-1/2/3) · OTP-first
and social auth (S0-AUTH-1/2/3) · page restructures for Home, About, Contact,
Login, Signup, FAQ (S0-PG-1…6) · property page redesign (S0-PROP-1) · branded
photo-less placeholder (S0-PROP-2) · content application (S0-CNT-1) · the five
blocked asset items (S0-ASSET-1…5).

**S0-CMS-1** is built but effectively empty — `tbl_cms_content` holds **1 row**
against 5 sections, so pages still render hardcoded copy. That is content entry,
not code. *(verified — DB count)*

**iOS App Store deployment** (OSC-1) is also a separate SOW.

---

## 6. Unproven, not broken

Nothing here is known to be defective. Each is a path nobody has exercised.

- The five destructive SEO writes: bulk apply (5,738 rows), 64-image ALT apply, CSV import apply, template enable, Global SEO save. Every one previews cleanly; only the final commit is untested.
- Sitemap generation at 29,000 URLs — measured at 26.
- The app's reviews path on a real device, after the reviews endpoint was opened to anonymous callers on 2026-09-03.
- Live end-to-end notification test (old BE-VERIFY-1) — code shipped, run deferred by the client.
- Google Search Console will not accept the sitemap without warnings until someone with GSC access submits it.
- Whether `dbCutoverSafe` currently reads true — see §2.4.
- **For the tester, on build 16** (each deploys cleanly and is covered by tests, but needs a signed-in host/guest on a device): #19's merged notification feed matches the website for the same host; the guest count survives "Move to Book at Agreed Price" on a *new* negotiation; airplane mode on host Notifications, guest My Negotiations and host Profile → properties shows "Couldn't load · Try again" rather than an empty state; #13's dropdown focus jump (fixed from the code, never reproduced on the emulator).
- **`REQUIRE_IMAGE_ALT`** — whether it has been set on Render is not visible from outside (see §2.3).
- **UAT cases with code/test-level verification only (2026-09-05).** Most manual cases were walked live during the 1 Sep sweep and this week's fixes, but these have not been driven end-to-end on production or a device: web **W-BOOK-04** (cancellation card + acknowledgement on Booking review — deployed, not exercised in a real checkout), **W-ACC-03** (cancel quote from the policy snapshot), **W-BOOK-11** (double-booking race), **W-NEG-02** (guest count through an accepted counter); Android **build 17 has not been run on a device** — A-BOOK-02 (reserve-sheet card), A-EXP-04 (policy tab from the server), A-X-01 (airplane-mode states), A-ACC-07 (push), A-ONB-04 (Google sign-in), A-ACC-12 (chat after the handoff-token change). Everything else in the manuals is either verified live or a known limitation named in the manuals.

---

## 7. Cash / UPI collection — what is built and what is not

**The rail is built.** `tbl_host_dues` exists with 24 live rows, host dues offset
against payouts, and screens on web host, web admin and the app. Captured test
payments were driven on both web and the app.

**What is still a client decision** (§1.3):

1. **Who confirms collection** — host marks "cash received", or admin reconciles?
2. **When** — at check-in, or at checkout?
3. **How the platform recovers 15% + GST** — net it off the host's next online payout, or invoice separately?
4. **If the host never confirms** — auto-mark collected at checkout, or flag to admin?

Recommendation already given: host marks collected at check-in; commission netted
off the next online payout; unconfirmed stays auto-flag to admin 24h after
checkout.

The commission model itself is unchanged and already implemented in
`utils/financeRecorder.js` — 15% of room subtotal charged to the host, 18% GST on
that commission, four ledger rows per booking.

---

## 8. Closed since the last edition — do not redo

### 8a5. Closed 2026-09-05 — the listing wizard's location picker

Client: the map picker sits below the fields it fills, Street Address comes out
as a locality where Google prints a street number, and moving the pin fills
"half the fields" slowly and leaves the City blank. Four separate faults.

| Was | Now | Evidence |
|---|---|---|
| **The picker sat at the BOTTOM** of "Where is the property?", under the six fields it fills, so hosts typed the address and then had the pin overwrite it. | **First in the section**, with a line saying it will fill the rest. | live — field order confirmed on the deployed wizard |
| **Picking a place from the search filled NOTHING but the coordinates.** The picker trusted the search hit's own address; the legacy Places Text Search cannot return address components at all, and production runs on it, so every hit arrived blank. The fields the client did see came later, from a map click — which is the "half the fields, slowly" they reported. | **Fixed.** The hit is used when it carries an address, otherwise the pin is looked up. One request, only for the chosen place. | live — every field fills on the first pick |
| **Street Address dropped the house number.** It was built as route + sublocality; Google returns the number separately as `street_number`, and a pin on a landmark with no route filled the locality name alone. | **Fixed.** Number and road, else the building's own name, else Google's formatted line with city/state/PIN/country trimmed. The two Google generations had a mapping each and had already drifted — one mapping now. | live — "S25/062, Katra Ahluwalia", "109 Court Road", "1, Chaura" |
| **The City the pin set was wiped a moment later.** `StateCityFields` clears the city when the state changes, since the old city belonged to the old state — but the map writes both in one update, so the clear ate the city that had just arrived. | **Fixed.** It tells the two cases apart by whether the city changed in the same commit. | live — City fills as "Amritsar", was blank |
| **Moving the pin left stale fields.** Merging non-empty values is right for a nudge, wrong for a move: Karnal → Amritsar kept "Karnal Division" in District. | **Fixed.** A different city or state replaces the address block outright. Same rule in the admin property form. | live — Amritsar → Karnal replaced all six fields |

**Found, not fixed — the app's host wizard has NO map picker at all.** It asks
for the address as text and never captures latitude or longitude, so a listing
created on the app has no coordinates and cannot be returned by any
location-based search. Only 6 of 29,252 listings are affected today and both
real ones are inactive, because almost nothing has been listed from the app yet
— but every future app listing lands the same way. Adding the picker to the
Flutter wizard is a screen's worth of work, not a patch, so it is listed here
rather than started.

### 8a4. Closed 2026-09-05 — app search parity, and pets in the search bar

**App (build 18).** The app carried every fault the website had just been fixed
for, in its own dialect. All verified against live data through the endpoints
the app calls.

| Was | Now | Evidence |
|---|---|---|
| **Map search sent a POINT and nothing else.** Whatever was typed went to the geocoder and no further, so a property NAME was resolved as a place. Worse, when the geocoder could not place it — which is what happens to a name — the app refused the search and told the guest to try a nearby town. | **Fixed.** The term goes to the server, which matches name and address wherever the search is centred; a term that will not geocode searches instead of dead-ending. | live — a name centred on the wrong continent returns the stay |
| **Price narrowed in Dart** over the properties already fetched. | **Fixed.** Sent to the server, and held on the controller with the dates so no refetch drops it. | live |
| **Results screen searched and sorted its own page.** A name search looked inside 60 rows; "Price: Low to High" ordered those 60 and presented them as the cheapest on the platform. | **Fixed.** Both are the API's, debounced to one request per typing pause. | live — asc opens at ₹900, desc at ₹12,000 |
| **`sort_by` went straight into the ORDER BY** as a column name, so an unknown value was a 500; and "rating" was sorted after the query, over the page that survived the limit. | **Fixed.** Allowlisted, ordered in SQL, unrated last. | live — ratings 5, 4, then unrated; a junk sort is ignored, not a 500 |
| **The radius cancelled the search term** — distance and text were AND-ed, so a named stay outside the searched area was lost. | **Fixed.** OR-ed, exactly as the website's endpoint. | live |

Category, price, rating, guests, dates and pets were already server-side on the
app's results screen and were re-verified. Paging exists on the endpoint
(`limit`/`offset` both honoured); the app still asks for one page of 60 and has
no "load more" — the one remaining difference from the website, listed in §6.

**Pets in the search bar (web).** The bar collected adults, children and
infants and stopped, so a guest travelling with a dog met the question for the
first time at checkout, after choosing a stay that may not take one. The
stepper was already built and switched off with a note saying the search API
could not filter on pets — it has been able to since August. In search the
count means "stays that take pets": pets never occupy beds, so it narrows on
the host's answer, and the host's own cap still applies on the listing. On the
desktop popover and the phone sheet both. The sidebar tick reflects a pet
carried in from the bar, and unticking it clears the pet.

*Verified live:* adding one pet on a Delhi search took 4,006 stays to 2.

### 8a3. Closed 2026-09-05 — pagination, result consistency, card design

Client, comparing our Delhi results with Airbnb's: "632 properties in delhi, on
map shows 100 stays only … no pagination exist … our page looks more like a
dummy". Six more defects, all fixed, deployed and re-verified live.

| Was | Now | Evidence |
|---|---|---|
| **No pagination.** The API answered with its first 100 rows and there was no way to ask for row 101 — `limit` had never been whitelisted (stripUnknown deleted it, which is where the suspiciously round 100 came from) and `offset` did not exist. | **Fixed.** 24 stays a page with a numbered pager: first and last page always reachable, current page ± 1, ellipsis over the gap. Changing the search returns to page one. | live — "1–24 of 4,006", page 2 shows "25–48" with different stays |
| **The header promised what the pages could not deliver.** The live-host rule (a listing whose owner is deleted or deactivated is not for sale) ran in JavaScript over the fetched rows while the total was pure SQL. | **Fixed.** Same rule, applied where the counting happens, so the total and every page agree. | test + live |
| **Sort ordered the page, not the search.** "Price: low to high" sorted the 24 stays on screen and presented that as the cheapest on the platform. | **Fixed.** Server-side, from a fixed map (never caller text — it lands in an ORDER BY). A search term still leads the ordering. Sorting returns to page one. | live — price_asc opens at ₹900, an invalid sort is refused 403 |
| **Guest rating filtered the page.** A 4-star filter searched 24 stays out of 632. | **Fixed.** A subquery over the same rows the ratings helper averages; unrated is excluded by a floor rather than counted as zero. | live — 2 stays at 4★+, 1 at 4.5★+ |
| **A ticked property type could search the wrong category.** The title→id map was keyed by a normalised title, and the normaliser strips a trailing "s", so "Villa" and "Villas" collapse to one key — both of which an admin may create. | **Fixed.** Keyed by the exact title. | code; no collision in today's data |
| **Cards read as a form beside Airbnb's.** Hard border, 14px padding, a 16/11 crop that made the photograph a thumbnail, and the tightest grid on the site (2 columns, 16px). | **Fixed.** 18px radius, border traded for a soft hover lift, 4/3 image, 16–18px padding, blurred pills that sit in the photograph, 24px grid taking a third column above 1600px. Same markup, so the rails move with it. | live — computed styles confirmed on the deployed page |

**Filters audited end to end against live data** — property type (single, multi-
select, an admin-created category, and one an admin switched off), price (each
bound alone), sort (all four), guest rating, pets, guests, dates, and a
combined query. All narrow at the database and all agree with their counts.

**Left as data, not code:** only **7 of 29,232** live listings have a
house-rules row at all, and 5 say pets are allowed — so "Travelling with a pet"
is correct but almost always answers empty. Separately, 3,247 listings sit in
the "Pet-Friendly Stays" *category* and none of them says pets are allowed in
its house rules. The two are different things and the filter reads the host's
actual answer; making the category stand in for it would tell a guest they can
bring a dog when no host ever said so.

### 8a2. Closed 2026-09-05 — property search and filters (client report)

Client: "we can't search property by entering the property exact name", and a
Kullu listing at ₹2,500 came back for neither Kullu nor a 2500–2500 price
band. Seven defects sat behind those two sentences. All fixed, deployed and
re-verified against live data; guarded by `tests/propertySearchFilters.test.js`.

| Was | Now | Evidence |
|---|---|---|
| **Search by name impossible (web).** `/properties/search` had no text parameter at all. The site geocodes whatever is typed, so a property NAME was resolved as a place — "Aish camping in the hills" resolved to a street in Woodbourne, New York, and the search ran there. | **Fixed.** `q` matches name / address / city / state, whitelisted in the schema. Name matches rank first and that order survives the second fetch. | live — site returns the property; API probe |
| **Search by name impossible (app).** `searchProperty` posted `latitude:"" longitude:"" radius:10`. `Number("")` is 0 and `isFinite(0)` is true, so every text search asked for stays within 10km of 0°N 0°E, in the Atlantic. | **Fixed server-side**, so installed builds are fixed too; the app also stops sending the blank values. | live — the old payload now returns the property |
| **A listing's address didn't reach search.** Distance was the only geo test, and the Kullu listings sit ~50km from Kullu, so no sane radius reached them. | **Fixed.** The text match is OR-ed against the geo group, so an address answers for itself whatever the pin says. | live — Kullu at radius 5 returns 51 stays, was 0 |
| **Price filter mostly inert.** Server: `if (minPrice && maxPrice)` around a BETWEEN, so a ceiling with no floor narrowed nothing and a floor of 0 disabled the filter. Web: filtered in the browser over the 100 rows already fetched. | **Fixed.** Two independent bounds, in SQL, on both endpoints; the web sends them instead of sieving a page. | live — Kullu 3000–3300 returns 23, all ₹3,300 |
| **LUXE deleted real stays from search.** The browse partition was applied to searches too, and three of the five real active listings are marked luxury — ordinary search sends `isLuxury:0`, so it could not return them. It also contradicts the host wizard, which promises only that luxury stays *appear* in the LUXE collection. | **Fixed.** Shelves stay separate while browsing (tester #17 still holds); a search answers from both. Cards keep their LUXE mark. | live — both the fix and the #17 guard re-checked |
| **LUXE overwrote the text search (app).** Both were assigned to `whereClause[Op.or]`, the same key. Whichever ran last won, so any search carrying `isLuxury` discarded the term and answered with the whole non-luxury catalogue. | **Fixed.** Both live under `Op.and`. | live — a nonsense term now returns nothing |
| **Two filter clauses could only throw or miss.** `filters.amenities` set a `property_amenities` column that does not exist, with a Postgres operator this MySQL dialect cannot render. `filters.city` was an exact match. | **Fixed.** Dead clause removed with a note on where amenity narrowing belongs; city matches loosely. | test + live |

**Left as data, not code:** listing 29289's map pin sits 50.6km from the Kullu
address it carries — the host placed it there. Every other real listing is
within 11km of the town it claims. Search no longer depends on the pin, but the
map and distance ordering still do, so it is worth correcting in admin.

### 8a. Closed 2026-09-04 → 09-05 (tester rounds, builds 13–16, the sweep)

| Was | Now | Evidence |
|---|---|---|
| **App #13** dropdown selection jumps back to the last numeric field | **Fixed, build 13.** The field kept focus under the pop-up sheet; it now unfocuses before the sheet opens. | code — not reproduced on the emulator, see §6 |
| **App #14** emails with `+` rejected at login | **Fixed, build 13.** The app's own regex; the server never had the rule. Sign-up was blocked by the same check, so the tester's `+host2` address had never existed. | verified — device |
| **App #15** white band above the keypad at login | **Fixed, build 13.** The keyboard inset was subtracted three times. | verified — device |
| **App #16** last wizard step blank on resume | **Fixed, build 13 + web + server.** `/listing/draft` never returned the step-5 tables; house rules were read under `ph_` instead of `phr_`; the web's `p5` was never hydrated either. Bank account comes back masked and is deliberately not re-filled. | verified — draft payload |
| **App #17** Submit for Review spun for three minutes | **Fixed, build 13.** 45-second submit timeout, then a read-back of the listing's state. | verified — device |
| **Admin** submitted listing never reached Pending Review | **Fixed, live.** New listings were created live+verified and submit changed nothing — **admin approval was gating nothing**, and unapproved listings were public and in Google. Migration `20260904100000-listing-offline-until-approved` applied on the live DB; unapproved listings now answer **404** at the edge (after a second fix — `build()` in `seoResolve.js` was dropping the `live` field). | verified 09-05 — `property_submission` rows; curl `Age: 0` → 404 |
| **App #18** ownership proof: no file upload, no document type | **Fixed, build 14 (in 16).** Image picker → file picker (PDF/DOC/DOCX/JPG/PNG); seven ownership + four identity types matching the web; upload was saved under a key the server never read. | verified — draft payload |
| **App #19** host notifications blank | **Fixed, server.** Hosts are written to two tables; the app read the rarely-used one (2 rows vs the website's 17). `hostSearch` now unions both; mark-read routes by `source`. | verified — DB counts per table |
| **Admin** "Ownership document missing" on approval | **Same root cause as #18** — the file was stored, the reference was not. Listings created before build 14 need one re-upload. | verified — DB column empty |
| **Web** guest count reset to 2 after a negotiation | **Fixed, live + app parity.** The party size was never stored with the offer. Migration `20260905100000-negotiation-offer-guests` (`offer_guests`) applied live; travels with the offer, comes back on the deal. | verified — column present, web build |
| **Reviews behind auth** | **Fixed 2026-09-03** in three places at once (route auth, client gate, edge markup); `aggregateRating` now server-rendered. | verified — curl of served HTML |
| **Duplicate `LodgingBusiness` + soft 404** on listing pages | **Fixed.** One business per page; a gone/unapproved listing answers 404 with `noindex`. | verified — curl |
| **Page SEO could not be saved** (ever) | **Fixed.** yup `.nullable()` rejected `""`; the empty audit log hid it. | verified — save round-trip |
| **Admin SEO scattered across menus** | **Done.** Dedicated SEO section in the nav + "Search & SEO" dashboard panel; change log now lists every SEO screen's edits; bulk tab sends its mode; keywords shown as lines, not JSON. | verified — admin UI |
| **SEO Phase 1 handover** | **Delivered** — `SEO_Phase1_Handover.docx` + artifact page, sent to the SEO team. | file |
| **Sweep class 1** — 26 silent-empty catches in app services | **Done, builds 15–16.** All 27 log through `utils/service_log.dart`; empty-vs-broken (`LoadFailed` + retry) on host notifications, guest negotiations, host properties; guest bookings already had it. | verified — `flutter analyze`, 138 tests |
| **Sweep class 2** — 34 `.nullable()` numerics with no empty-string transform | **Done.** 38 sites on `nullableNumber()`; `tests/nullableNumberSweep.test.js` rescans every schema. | verified — 43 test files |
| **Sweep class 3** — `.catch(() => {})` on the web | **Done — 37 sites, not 18.** The ESLint rule added at the end found 19 more written with a comment inside the braces. Four got real error states: notification bell, Book Now (was stuck on "one moment"), host and admin offer pickers. | verified 09-05 — `eslint .` 0 hits, real build |
| **Sweep class 4** — two arrays disagreeing on which statuses are revenue | **Done.** One list in `utils/bookingStatus.js` (3,5,6,7,8,9,10,13); a third, complement-shaped list in property analytics folded in; guard test refuses a private list. No real booking sits at 4/12/13, so no figure moved. | verified 09-05 — DB status counts |
| **Sweep class 5** — admin form validating untouched fields | **Done.** `PropertyForm.tsx` validates and sends only what changed. | verified — the two renames went through |
| **"14 listings moved into the review queue"** (build-14 sheet note) | **Overstated.** The DB records **4 approvals** on 09-04 (→ §1.7). Real-host listings after 09-05: 6 live, 1 approved-but-inactive, 9 drafts, 0 awaiting review. | verified 09-05 — DB |
| **Admin → Properties → "Approve & publish" was a second, broken approval path** (was 3.13) | **Fixed 2026-09-05.** It counted documents in two tables while the wizard writes them to a third (`property_media`), so it refused **15 of the 16 real-host listings** — and had the count ever passed, it would have approved with no state machine, no completeness gate, no `property_submission` record and no SEO regeneration. The queue's handler body is now `reviewListing()` — one implementation, no HTTP in it — and both entry points call it; the Properties dialog keeps its tier choice, drafts are refused with the machine's own message, and only older-form listings still take the attachment path (whose gate now counts all three tables). `tests/listingReview.test.js` pins the shape. Follow-up the same day: the list now carries `verification_status`, so the Pending tab shows drafts as **Draft / "Not submitted"** with no Approve button, and the review dialog says so and disables approve. | verified 09-05 — production probe on a draft answers the lifecycle message; live Pending tab shows 9 drafts with Review only; 44/44 |
| **Queue approvals never reached the admin audit ledger** (was 3.14) | **Fixed 2026-09-05.** Every decision, from either entry point, goes through `auditDecision()` → `tbl_admin_audit` as `property_approved / _rejected / _changes_requested / _suspended` with before/after. | verified 09-05 — audit row on the post-deploy re-approval |
| **UAT manuals, delay analysis, deployment options** | **Delivered 2026-09-05.** Two UAT manuals (web 81 cases, Android 55 cases) with sign-off tables; the delivery-delay analysis against the 13 July plan with a dated timeline and owners; the hosting comparison with sizing, tools, provider costs, VPS route, decision matrix and a migration plan. Generated from the repos and the session record, not from memory; structural check passed (no raw markup, tables intact). | verified 09-05 — files at repo root |
| **Cancellation & Refund Policy v1.0 — final copy** (was 1.4) | **Implemented 2026-09-05 against the client's document.** The five ladders already matched; two loopholes did not: a booking did **not** keep the policy it was made under (the refund read the listing's *current* policy — 48 bookings carried no snapshot), and "hours before check-in" was measured from **midnight UTC**, so a guest's free-cancellation window was up to ~18 h shorter than promised. Both fixed (`book_cancel_policy` snapshot; check-in = `pbr_checkin_time` in IST, default 14:00). Also: *Non-Refundable* and *Custom* removed from host selection (not in the document; no listing used them); guest-facing rules generated in the document's words; refund-timeline copy per §9; the app's hardcoded Firm/Strict sentences (wrong) replaced by the server's. New: `/cancellation-policy` page (web + app, one text served by `/common/cancellation-policy`), this stay's refund dates + a required acknowledgement before payment on web and app, colour-coded badge on every card, links from listing pages, footer, Settings and host menu. `tests/cancellationPolicyV1.test.js` pins the ladders to the document's table. | verified 09-05 — 46/46 BE, 138/138 app, live page 200 + index, cards badged on the live search |
| **Cookie banner asked for analytics, loaded marketing** (was inside 1.2) | **Fixed 2026-09-05.** One "yes" loaded GA4, GTM, a Meta pixel and Hotjar under a banner that mentioned only analytics; the chat widget fingerprinted every public visitor before the question; "Read more" went to Terms. Now: three categories at equal weight, Consent Mode v2 defaults denied, Hotjar barred from sensitive routes, BotPenguin mounted only in the signed-in renter area, policy section drafted and linked. The client's remaining part is in §1.2. | verified 09-05 — anonymous visit: no cookies, no vendor scripts, v2 storage shape |
| **BotPenguin was handed the user's 30-day session JWT** (was 3.13) | **Fixed 2026-09-05.** The widget now asks `POST /bp/handoff` (user session required) for a **15-minute, purpose-bound handoff token** signed with a key of its own, so no session verifier accepts it; `/bp/session/start` takes that, and an old tab's session token only until 2026-09-13. Consumed once at session start — a conversation cannot expire mid-way; a chat opened >15 min after landing falls back to the phone/OTP path. Bot flow on the vendor side unchanged. `tests/botHandoff.test.js`. | verified 09-05 — production mint: purpose `bp_handoff`, exp−iat = 900 s, rejected by `/user/detail` |
| **`psb_reviewed_by` fix unproven** | **Proven on production 2026-09-05.** Approving 29289 through Listing Verification wrote `psb_reviewed_by = 1` (admintest, super_admin), `psb_reviewed_at`, `psb_published_at` and all nine checks; the listing went `verified`/active and its slug page answers 200 `index, follow`. It reaches the property sitemap when that document's hour-long in-process cache expires (Admin → Global SEO → Regenerate forces it) — approval does not purge the cache. Found two things on the way → §3.13, §3.14. | verified 09-05 — DB + curl |

### 8b. Closed before 2026-09-04

The 2026-07-11 edition listed all of these as open. Each was checked on
2026-09-04 and found already delivered. Re-opening any of them wastes a day.

| Was | Now | Evidence |
|---|---|---|
| **B-1 / C-2** secrets hardcoded in `db.config.js` | **Done.** File is env-only with empty fallbacks; `/health/env` reports `ready: true` (vars present **and** DB reachable); Cloudinary uploads work in production. | verified |
| **C** "Render env never populated", "DB_* set but wrong" | **Stale.** Those warnings described July–August. The cutover has happened. | verified |
| **BE-4** "web has no socket client — web chat would be a net-new build" | **Done.** `socket.io-client` is a dependency; `useChat.ts` and `useNegotiationLive.ts` ship. | verified |
| **MOB-1** DIDIT KYC absent from the app | **Done.** `didit_kyc_screen.dart`, `kyc_controller.dart`, `verify_service.dart` mirror the web flow. | verified |
| **MOB-2** app still uses the old `/host/add` | **Done.** The 5-step schema wizard is the only property form on web and app since 2026-08-20. | code |
| **MOB-3** verification status not surfaced in the app | **Done.** `isKycVerified` drives the host profile and payout screens. | verified |
| **S0-SEO-1** per-page SEO | **Done.** The entire SEO Phase 1 — tasks 0 through 10 — is live. See `SEO_CMS_PHASE1_TASKLIST.md`. | verified |
| **S0-BLOG-1** blog frontend | **Done.** `tbl_blogs` holds 16 rows; the public blog and admin editor ship. | verified |
| **S0-ADM-1** admin missing CMS / SEO / Coupons / Analytics | **Done except Notification Mgmt** (→ §3.8). SEO alone now has 8 routes. | verified |
| **S0-HOST-1** host missing Calendar / Offers / Occupancy | **Done.** `/host/calendar`, `/host/offers`, `/host/performance`, `/host/boost`, `/host/settlements` all ship. | verified |
| **G-1** doc cleanup uncommitted | **Done.** `_archive/` holds 45 files and the tree is clean. | verified |
| **G-2** `aajoo_homes-main/` still tracked in git | **Done.** `git ls-files` returns 0. The directory remains on disk, untracked. | verified |
| **"29,232 listings have no photograph"** | **Misleading, now corrected.** Only 6 listings belong to real hosts and **all 6 have photos**. The gap is entirely inside the seed corpus no crawler sees. | verified |
| **"Seed data spells Uttarakhand as Uttrakhand"** | **Not reproducible.** 0 rows in `property_state`. | verified |

---

## 9. Keeping this file honest

The previous edition drifted because items were marked done in commit messages
and session handoffs but never reconciled back here, while other items stayed
open long after they shipped. Three habits prevent it:

1. **Check the running system, not the note.** Every row above says how it was
   established. A row that only says `carried` has not been checked and should be
   the first thing anyone re-tests.
2. **An empty result is a finding, not a pass.** Several defects this cycle hid
   as absence — an empty change log, a form that rendered perfectly and could not
   save, a 401 swallowed into "this property has no reviews", a host with
   seventeen notifications shown "No notifications yet". Where a number should
   exist and does not, treat that as unverified rather than clean.
3. **A count from a grep is a lower bound.** The web catch sweep was "18 sites"
   until an AST rule found 37; the "14 listings approved" note was 4 in the DB.
   When a number goes into this file, measure it with the tool that cannot be
   fooled by formatting — a lint selector, a guard test, a `COUNT(*)` — and say
   which one.

Detailed context: `Delivery_Delay_Analysis_2026-09-05.docx` (why the date slipped, and what changes) · `Deployment_Options_2026-09-05.docx` · `PROACTIVE_FINDINGS_2026-09-05.md` · `SEO_CMS_PHASE1_TASKLIST.md`
· `AAJOO_SECTION0_TASKLIST.md` · `CONTRACT_COMPLIANCE_CHECK.md` ·
`CLIENT_INPUTS_REQUIRED.md` · `RENDER_ENV_CHECKLIST.md` · `PAYOUTS_SETUP.md` ·
latest `SESSION_HANDOFF_*.md`.
