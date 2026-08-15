# Platform audit — started 2026-08-14

End-to-end audit of the whole platform against `_Web App Bugs.xlsx`, plus a
sweep for dead APIs, unsynced data, dummy data and errors that should not be
there. Web and app.

**This file is the running record across all phases.** Anything found and not
yet fixed lives in §Open below, so nothing is carried only in conversation.

## The two sheets

| Sheet | Rows | What it is |
|---|---|---|
| `Aug 08-26` | 28 (8 headers + **20 items**) | web / admin — "Block W" |
| `Aug 08-26  App` | 105 | mobile — "Block A", = A-1…A-83 |

The Status column in the workbook says "Pending" against every web row. That
column was last touched on 10 Aug, **before** most of the fixes landed — it is
the client's own tracking, not evidence. Everything below was checked against
the running system instead.

## Phases

| Phase | Scope | Status |
|---|---|---|
| 1 | Admin portal — the 20 web-sheet items | ✅ **Done** — 19/20, W-13 partial |
| 2 | Guest web E2E — every public page, dead APIs, dummy data | ✅ **Done** — 14 fixed, 5 open |
| 3 | Host web E2E | ✅ **Done** — 2 fixed, 7 open |
| 4 | App E2E | ✅ **Done** — 5 fixed, 5 open |
| 5 | Fix → redeploy → re-verify | ✅ **Done** — all fixes live and re-verified in production |
| 6 | Transactional E2E — booking, payment, invoice, ledger | ✅ **Done** — 5 fixed, 3 open |

## Deployed and verified live

| What | Commit | Verified in production |
|---|---|---|
| CORS PUT/PATCH | BE `1e8aa98` | `OPTIONS` from `https://www.aajoohomes.com` → `204`, `access-control-allow-methods: GET,POST,PUT,PATCH,DELETE,OPTIONS` |
| Offer note reaches admin | BE `dfe7f92` | deployed |
| User Active/Inactive toggle | FE `ffdcb7c` | string `Deactivate this user` present in the live bundle |
| Add User / Add Host dialog | FE `c75dfcb` | `Add New Host`, `A profile photo is required` present |
| Offer note rendered | FE `f67f5ca` | `Message sent with the offer` present |

---

## Phase 1 results — the 20 web items

### 🔴 Root cause behind several: PUT and PATCH were CORS-blocked

`app.js` allowed `GET, POST, DELETE, OPTIONS` only. Every PUT/PATCH failed its
preflight and died inside the browser — status 0, empty body, nothing in the
server log. Nine endpoints were dead **on the web only**; the mobile app was
unaffected because Dio is not a browser and sends no preflight. That is why
"works in the app, not on the web" kept recurring.

```
PUT  /admin/finance/payout/:id/approve   ← "payout is not working"
PUT  /admin/finance/payout/:id/reject
PUT  /admin/finance/payout/schedule/:id
PUT  /admin/finance/reconciliation/:id/resolve
PUT  /admin/notifications/:id/read
PUT  /host/notifications/:id/read
PUT  /host/payout-account/update         ← hosts could not save bank details
PUT  /host/profile/update
PATCH /listing/media
```

Proof, same button before and after: `PUT …/approve` went from **status 0,
empty body** to **400** carrying the server's real message, which the admin
now sees on screen.

### Item by item

| # | Item | Status | Evidence |
|---|---|---|---|
| W-1 | Host name missing on payout detail | ✅ works | "To Ashish Rahi", Host ID #133, email |
| W-2 | Payout detail (host / booking / user / bank) | ✅ works | host + masked account + booking + guest + property + full ledger |
| W-3 | Period shows invalid data | ✅ correct | fixed in code; payouts 7–8 (post-fix) carry real periods. Payouts 1–6 predate it and have **no linked booking dates** — checked — so "—" is honest, nothing to backfill |
| W-4 | Payout is not working | 🔧 fixed | CORS. Now returns 400 naming `RAZORPAYX_KEY_ID/KEY_SECRET/ACCOUNT_NUMBER`. **Cannot send money until those 3 env vars are set** |
| W-5 | Invoice download not working | ✅ works | `200 application/pdf`, 1792 bytes |
| W-6 | Reports should show the period in the file | ✅ works | CSV opens `Aajoo Homes — Cash flow report / Period,2026-08-01 to 2026-08-14 / Generated,…` |
| W-7 | Active/Inactive button not working | 🔧 built | The control **did not exist** — the redesign made status a read-only badge. Wired to `/admin/user/update/status` (which already writes an audit row). Verified `200 Status Updated Successfully`; test host restored to Active |
| W-8 | Doc number validation by doc type | 🔧 built | Server always enforced it. Client now matches: Aadhaar 12 digits, DL `MH0123456789012`, Passport `A1234567`. Verified: Passport + 12-digit Aadhaar → "Passport must be like A1234567" |
| W-9 | Error message should match the error | 🔧 built | Empty submit names all ten fields individually, incl. "A profile photo is required" |
| W-10 | Where can I check the negotiation message | 🔧 fixed | The offer's note lives on the offer row; the thread read the chat table, so an offer with a note but no chat said "no messages were exchanged" **and the note was never sent to the admin at all**. Now included and rendered above the thread |
| W-11 | Rename form to "Add New Host" | 🔧 built | — |
| W-12 | Add host form is not working | 🔧 built | There was no form. `src/pages/admin/*` (15 folders) is unrouted dead code. One dialog now covers user and host — the backend has always had one endpoint, `/admin/user/create` with `user_isHost` |
| W-13 | Host **update** form title | ⚠️ **partial** | Creation built; there is still no host *update* form in the new admin. Same cause as W-11/12 |
| W-14 | Description points vanish after save | ✅ verified | Property 15 reads its saved point back; confirmed in `propDetail_extra` |
| W-15 | Same for property document upload | ✅ fixed | Docs live in **two** tables (admin → `tbl_attachments`, wizard → `tbl_property_documents`); the read merges both |
| W-16 | Pet / Smoking unchanged after save | ✅ verified | DB `0/0` ↔ form loads `0/0` |
| W-17 | Deleted host still shown on property | ✅ fixed | Deleting a host now deactivates their listings — they used to stay searchable and bookable with no host behind them |
| W-18 | Logo missing on email | ✅ fixed | Templates pointed at placeholder `yourcompanylogo.com`; now `LOGO_URL`, asset verified `200 image/png`, 26,351 bytes |
| W-19 | Host full info not on profile | ✅ works | `/host/profile/get` returns fullName, email, phone, address, city, verification_status. Its **update** is a PUT — was CORS-blocked, now fixed |
| W-20 | Cannot log in as an unverified user | ✅ fixed | Unverified now routes to the code step instead of "No record found", and the password is checked **first** so the endpoint is not an account-existence oracle |

---

## Open — carry forward

### Blocked on the client (nothing more I can do)

| # | Item | What is needed |
|---|---|---|
| C-1 | 🔴 `OTP_DEV_BYPASS` is `true` in production | Set `false` in Render. OTP can be bypassed on a live system |
| C-2 | 🔴 Payouts cannot send money | `RAZORPAYX_KEY_ID`, `RAZORPAYX_KEY_SECRET`, `RAZORPAYX_ACCOUNT_NUMBER` (+ `FIELD_ENCRYPTION_KEY`) |
| C-3 | Render env wrong | 5 `DB_*` incorrect, 4 vars missing — `RENDER_ENV_CHECKLIST.md` |
| C-4 | Phone verification (A-5) | SMS provider credentials + DLT approval |
| C-5 | App loader / ringtone / launcher icon (A-1, A-2, A-3) | The branded assets |
| C-6 | List-your-property parity (A-77) | The SEO design + a decision to schedule the Listing Engine port |
| C-8 | 🔴 **Boost sells plans that charge nothing and do nothing** (H-3, H-4) | Decide: wire payment + search ranking (with paid-placement labelling), or take the page down. It currently offers ₹499/₹1,499/₹3,999 plans |
| C-9 | **Referral reward has no payment path** (H-6) | Commit to settling manually via `/admin/referrals/list`, or build a wallet. Guests are promised ₹300 |
| C-10 | Blog is placeholder content (G-13) | Five posts reading "blog one".."blog five", live and linked from the homepage |
| C-12 | 🔴 **This deploy cannot collect money** (T-5) | `RAZORPAY_KEY_ID` is not set on Render, so checkout runs on the bundled test key: guests can complete a booking and nothing is charged. Check `GET /health/env` → `payments` before go-live |
| C-11 | App will still call the **dev** backend in production (M-6) | Decide the production API host. `_prodBaseUrl` currently equals `_devBaseUrl` and the host is hardcoded in 20 files |

### Engineering — found, not yet fixed

| # | Item | Notes |
|---|---|---|
| P-1 | W-13 host **update** form | Creation exists; update does not |
| P-2 | Placeholder identities in finance | Invoices show `Host #111` / `Guest #123`, payouts `Host #12`. IDs where names belong |
| P-3 | Blank columns everywhere | User PHONE, host LOCATION, invoice PARTY all `—` on every row |
| P-4 | Property form Submit is silent on validation failure | Errors render beside fields only. On property 7 it did nothing because zip/country are NULL in the DB — no top-level "fix these" signal |
| P-5 | Legacy admin is dead code | All 15 folders of `src/pages/admin/*` unrouted. Delete or restore deliberately. **Caution:** `src/pages/user/*` is NOT all dead — `/home` and `/user-dashboard` are routed. Check reachability by symbol, not by path: App.tsx imports `Home` from `./pages`, so grepping for `user/home` finds nothing |
| P-6 | `apiValidation.ts` is documentation only | Not wired to anything, and says POST where the code uses PUT |
| P-7 | Junk city labels (E-3) | ~4,260 listings show wrong cities; needs a licensed geocoder |
| P-8 | Categories are a placeholder (E-15) | Even split across 9 categories; not real classification |
| P-9 | App: notifications reopen on cold start | Suspect `NotificationRoutingMiddleware` |
| P-10 | App: listing upload size | ~4MB never completed; ~180KB took ~90s. Needs client-side image compression |

---

## Phase 2 — guest web E2E

Run against a local backend so every API call lands in a request log, with the
frontend pointed at it. Pages walked: home/explore, search, property detail,
about, contact, FAQ/help centre, blog, safety, getting started, become a host,
login, guest dashboard.

### The theme of this phase

Phase 1 was about things that were **broken**. Phase 2 is about things that
were **untrue**. Every finding below is a screen stating something the
database does not support — invented inventory, invented statistics, invented
photographs. None of it would have shown up as an error.

### Fixed and verified

| # | Finding | Evidence |
|---|---|---|
| G-1 | 🔴 **Search invented six listings when it found none.** `FALLBACK_RESULTS` rendered whenever the live query was empty. Searching Manali reported "**6 properties found**" and showed The Maple Cottage 4.8 (126), The Skyfall Villa 4.9 (98) and four more — invented ratings, invented review counts, every card linking to `/property` with no id — while the map beside them correctly said "No stays to show here yet". It also fires on a **failed request**, so an outage rendered as a healthy result page. The honest empty state was already written and simply unreachable. | Removed; loading state added. `?q=Tokyo` now shows the empty state, `?q=Manali` returns 100 real stays near Mandi |
| G-2 | Explore's trending rail had the same fallback, showing on **first paint every time**, before the request finished. | Removed; loading and empty states added |
| G-3 | 🔴 **Featured Destinations was five hardcoded tiles with hardcoded counts.** Manali "1,250+ stays" → **0 in the database**; Jibhi "680+" → 0; Kasol "520+" → 0; Shimla "910+" → 50; McLeod Ganj "430+" → 0. Four of five led to a search that could return nothing. | New `GET /properties/destinations`. Rail now reads Uttar Pradesh 2,843 / Madhya Pradesh 2,115 / Bihar 1,891 / Tamil Nadu 1,871 / Odisha 1,486, and clicking through returns real listings |
| G-4 | The empty state's "here's where we do have places" chips were read off the fetched result set — empty exactly when they are needed, so that row was **always blank**. | Now from the destinations endpoint |
| G-5 | **Foreign place names silently resolved to Indian villages.** The geocoder is India-restricted (correct) but matches loosely: "Tokyo" → the village of Takyo, Kurung Kumey, and the page reported "«Tokyo» stays · 100 properties found" for stays 4,500 km away. | Now says "No exact match — showing stays near Takyo, Hiya, Sangram SDO" |
| G-6 | 🔴 **Become a Host led with three invented statistics.** "₹48,750 Avg. monthly earning" (no basis — 24 bookings have *ever* been made), "2,153 Active hosts" (**there are 4**, two with a live listing), "4.8★ Avg. host rating" (**every review table has 0 rows**), "Join thousands of hosts" (four). An earnings figure is an inducement to sign up. | Replaced with three claims that are true and need no number; "listing is free" is the platform's own FAQ answer |
| G-7 | Two of six advertised host tools **do not exist**: "Smart Calendar — block dates and sync bookings" (no blocking, no sync) and "Dynamic Pricing — smart price suggestions" (no pricing endpoint at all). The other four are real. | Rewritten to what exists. Also softened "Fast Payouts" (admin-scheduled, RazorpayX not live) and "24x7 Support" (a ticket system) |
| G-8 | Safety told guests to "add a trusted contact **in your profile**" — `tbl_users` has no such column and no screen offers one. The only emergency contact in the product belongs to a *listing*. | Replaced with something a guest can act on |
| G-9 | 🔴 **Every listing without a photo showed a random stock photograph as its own.** `picsum.photos/seed/aajoo<id>`, stable per listing, styled exactly like a real photo. **16 of 29,228** active listings have an image. | Inline SVG "Photo coming soon" placeholder |
| G-10 | "You may also like" used the **visitor's** location, not the property's — a Chattarpur, New Delhi listing recommended four stays in Mandi, HP. | Now passes the property's coordinates; the same page recommends Delhi stays |
| G-11 | Guest dashboard rendered a lone " ★" chip over unrated stays — a rating badge with no rating. | Hidden when null |
| G-18 | 🔴 **Property detail invented a listing when the fetch failed.** The placeholder was a complete stay — "The Maple Cottage", Jibhi, ₹3,200/night, full description — with a live **Book Now**. A dead id, deleted listing or network blip rendered a convincing property that does not exist. A missing listing returns `null` rather than throwing, so that path rendered the shell around empty values instead: nameless stay, ₹0, Book Now still live. | `?id=999999` now says "We couldn't load this stay"; `?id=15` unchanged |
| G-19 | 🔴 **`/account/checkout` was fabricated end to end.** Someone else's stay ("The Maple Cottage, Manali, 25–27 May"), a fake financial summary (**₹12,600 paid, ₹2,000 refundable deposit, +₹250 coins**), a star rating and review box that discarded whatever was typed, and a "Complete Check-out" button that checked nobody out — it navigated to Past Stays. Unlinked, but reachable by URL. | Deleted. The real review flow already exists at `/account/review`, wired to `submitReview` |
| G-12 | Host Terms contained the literal editing marker "**[specific time frame]**" in a clause hosts agree to. | Describes the mechanism instead; there is no fixed figure (per-schedule, admin-set) |

### Verified working (no defect)

- **Contact form** — end to end: submit → `POST /contact/message` 200 → row in `tbl_contact_messages` → confirmation banner. Social links are already CMS-driven and render as non-links when unset.
- **Help Centre** — 35 real FAQs, live category counts.
- **About**, **Getting Started** — no fabricated figures.
- **Login → guest dashboard** — real data (4 bookings, ₹34,251 spent, 1 saved).
- **Property detail** — real listing data, tabs, availability, host block.

### Phase 2 — still open

| # | Item | Notes |
|---|---|---|
| G-13 | Blog is placeholder content | Five posts titled "blog one"…"blog five", each "blog short description", live and linked from the homepage and footer. Machinery works; **content is the client's** |
| G-14 | 99.95% of listings have no photograph | Now honest, but a stay with no photo barely sells. Needs real images or the seeded catalogue trimmed — same root as the junk city labels |
| G-15 | Document title does not update on SPA navigation | `/account/dashboard` still reads "Login to Aajoo Homes"; `/search` reads the generic site title |
| G-16 | "24x7" support claimed on Contact and Getting Started | A staffing promise, not a code defect — **client to confirm or drop** |
| G-17 | Copy says "North India" / "the Himalayas" | Inventory is nationwide (Tamil Nadu 1,871, Odisha 1,486, Kerala 707); the destination rail now shows those states while the prose says Himalayas |

---

## Phase 3 — host web E2E

Signed in as `aajoo.host1@mailinator.com` (user 100 — **29,227 live listings,
19 bookings**, verified). Walked dashboard, properties, bookings, calendar,
messages, negotiations, earnings, payouts, performance, boost, refer, profile,
settings, support. Every API call captured in the request log: **39 distinct
endpoints, 2 non-2xx**, one of which was my own curl typo.

### Fixed and verified

| # | Finding | Evidence |
|---|---|---|
| H-1 | 🔴 **Boost was dead on arrival.** The model set `modelName: 'tbl_boost'` and no `tableName`, so Sequelize pluralised it and queried **`tbl_boosts`** — the real table is `tbl_boost`. `GET /host/boost/list` returned **400 "Table 'tbl_boosts' doesn't exist"** on every load of the Boost page, silently, while the page went on offering three paid plans. `POST /host/boost/activate` would have failed identically. Most models here survive the default because their tables are already plural (`tbl_user` → `tbl_users`); this one is not. | 400 → **200**. Activate now writes a row (starter, ₹499, 7-day window). Test row deleted |
| H-2 | Payouts promised "reach your account within **2-3 business days**" — printed directly above a history where **all six payouts read FAILED**. Nothing enforces 2-3 days: release is admin-scheduled and the transfer goes through RazorpayX, which has no credentials, which is *why* they failed. | Now describes the process and points at the status column |

### Verified working (no defect)

Checked carefully because they looked wrong at first glance and were not:

- **Host dashboard** — reads ₹55,980 this month, 29,227 active listings, 3 upcoming, 15% commission, real ledger activity. My first look showed zeros because I read the page before the fetches resolved, not because of a bug.
- **Performance** — ₹73,757 / 90 days, 6 cancellations, and `—` for average rating rather than a fabricated 0. Correct on the empty-means-hidden rule.
- **Calendar, Messages, Negotiations, Earnings, Properties, Bookings** — all live data.
- **Referrals** — genuinely implemented end to end: `recordReferralOnSignup` on signup, `creditReferralForUser` from the booking flow, `/user/referrals/summary` reporting real counts.

### Phase 3 — still open

| # | Item | Notes |
|---|---|---|
| H-3 | 🔴 **Boost takes no payment** | `POST /host/boost/activate` needs only host auth. No Razorpay order, no verification. A host clicks Boost Now on the ₹3,999 Pro plan and it activates instantly, free. **Confirmed by activating one.** Every plan sold on that page currently earns ₹0 |
| H-4 | 🔴 **Nothing consumes a boost** | `boost` appears in exactly three files: `host.controller` (create/list), `admin.controller` (list), `models/tbl_boost`. `property.controller`, which serves `/properties/search`, never references it. So "Top of search", "2x/3x more visibility", "Featured badge", "Homepage feature" are not delivered by any code. Note that paid placement normally has to be **labelled** to guests — this is a product and compliance decision, not a bug fix I should make unilaterally |
| H-5 | "Priority support" / "Dedicated manager" on the Boost plans | Support is one ticket queue with no tiering |
| H-6 | Referral reward has **no way to be paid** | The programme is built, but `creditReferralForUser` only flips `ref_status` to "credited". There is **no wallet, balance, coin or reward table anywhere in the database** — I checked. Guests are promised "₹300 Aajoo Coins", hosts "you earn ₹300", and there is nowhere for it to land. It *is* fulfillable manually — an admin can read `/admin/referrals/list` and settle by hand — so this needs a **client decision: commit to settling manually, or build the wallet** |
| H-7 | `POST /properties/search` peaked at **3.9 s** | The slowest endpoint on the platform, and it is on the critical browse path |
| H-8 | "29227 Active Listings" | Missing thousands separator; the same page writes "29,228 listings" and "₹55,980" correctly |
| H-9 | Property pickers list 100 of 29,230 as a flat wall of names | Calendar and Boost both. An artifact of the seeded catalogue, but unusable as a picker |

---

## Phase 4 — app E2E

Built, installed and driven on `emulator-5554` (Android 17). `flutter analyze`:
**0 errors in our code** (640 issues, all `info` lints, almost all from the
ionicons package).

### First, what the app does *not* have

Worth stating, because the web's worst findings do not carry over. The app has
**no** fabricated listing fallbacks, **no** hardcoded destination counts,
**no** invented host statistics, **no** "Dynamic Pricing" or "Smart Calendar"
claims, **no** referral rupee promise, and **no** paid Boost plans — its
"boost banner" is a *List a new property* CTA. It also already renders a
neutral placeholder for listings with no photo, so it never had G-9.

**Every API call the app makes maps to a real backend route** — extracted every
`.get/.post/.put/.patch/.delete` path and diffed against all 281 routes:
**zero dead endpoints**.

### Fixed and verified

| # | Finding | Evidence |
|---|---|---|
| M-1 | 🔴 **The Safety page described a different product.** `GET /common/safety` — what a guest reads before deciding to sleep in a stranger's house — promised an **"in-app emergency button that connects them to local authorities"**, **host insurance**, **user protection programmes**, a **reporting system** with a team that "continuously monitors" it, **host safety training**, and that hosts are "required" to provide smoke detectors and first aid kits. None of it exists; there is no report or flag endpoint anywhere in the API. Two of those describe **financial cover**. This is E-13, fixed on web in an earlier session — but the web reads `cmsSchema.ts` and the app reads the backend, so the app never got it. | Rewritten to what the platform does, mirroring the web page. Live in production and confirmed on device |
| M-2 | About Us claimed "along with **SOS features**" | Same invented capability. Removed |
| M-3 | 🔴 **The app's FAQ was six questions for a different product** — "How do I book a **hotel** on the app?", "Do we have host facilities?" — hardcoded in `utils/data.js`, while **35 real, categorised, admin-editable FAQs** sat in `tbl_faqs` (the ones the website's Help Centre shows). An admin editing them saw no change in the app, because the app never read them. | Fixed **in the backend, not the app**, so it reaches every installed copy with no store update. Verified on device: the FAQ screen now lists "What is Aajoo Homes?", "Who can become a host?"… |
| M-4 | `[Your Platform Name]` appeared **four times** in the guest and host Terms | An unfilled template marker in a document users are asked to agree to. Confirmed gone in production |
| M-5 | 🔴 **Shared properties carried a made-up rating and a dead link.** The share sheet printed `Rating: ${widget.rating} ★` — the value the *caller* passes, which `NegotiatedDealBanner` hardcodes to `'4.5'` and `CuratedCard` defaults to `'4.5'`. A stay with no reviews was recommended into someone else's WhatsApp at 4.5 stars. The fourth copy of the invented-rating bug, and the only one that leaves the platform. The link pointed at `https://aajoo.com/property/<id>` — **that domain does not resolve** (curl: 000), and the route is `/property?id=<id>`. Every shared property was a dead link twice over. | Real rating + review count, "Newly listed" when there is none, and `https://www.aajoohomes.com/property?id=<id>` (verified 200) |

### Phase 4 — still open

| # | Item | Notes |
|---|---|---|
| M-6 | The shipped app points at the **dev** backend | `_prodBaseUrl` is set to the same value as `_devBaseUrl` (`aajaodev.onrender.com`), and the host is **hardcoded again in 20 files** rather than read from `ApiConstants`. When a production API is stood up, the app will keep calling dev, and pointing it at the new one is a 20-file edit |
| M-7 | Host menu has no "switch to guest" | `/user/switch-mode` exists and the web offers it; the host menu ends at Logout |
| M-8 | "29230 Properties" | Missing thousands separator — the same defect as H-8 on web |
| M-9 | Dead twin tree under `lib/screens/` and `lib/widgets/` | Confirmed unreachable from the live tree, but it still carries the old `aajoo.com` share link and Lorem ipsum (`models/product.dart`), and it ships in the binary |
| M-10 | "24x7" support claimed in 3 places | Same client decision as G-16 on web |

---

## Phase 6 — the money path

Ran a real booking end to end as the renter: property → dates → review →
payment → confirmation → host → ledger. **Booking `B478912`** — Azure Sky
Apartment, 23–26 Sep 2026, 3 nights, ₹10,080, pay-at-property. Left in place as
evidence; the phantom row my abandoned card attempt created was deleted.

### The money is right

Checked to the rupee against `tbl_financial_ledger`:

| Line | Amount | Check |
|---|---|---|
| Guest payment | ₹10,080 | ₹3,200 × 3 = ₹9,600 room + ₹480 GST |
| Accommodation GST (5%) | ₹480 | correct band — 5% applies under ₹7,500/night |
| Platform commission (15%) | ₹1,440 | 15% of ₹9,600 |
| GST on commission (18%) | ₹259 | folded into the host earning line |
| **Host earning** | **₹7,901** | 9,600 − 1,440 − 259 ✓ |

The rate band is applied correctly too: `calculateBookingtax` charges 5% at or below ₹7,500 a night and 18% above it, which matches the Indian GST rule for accommodation. I had this down as a defect until I read it.

7,901 + 1,440 + 259 + 480 = **10,080**. Balances exactly. All four entries
`PENDING`, correct for an unpaid pay-at-property booking. Host's booking count
went 19 → 20, so it reached the host.

### Things that turned out to be right (checked because they looked wrong)

- **Abandoned checkouts.** Clicking Pay and walking away from Razorpay leaves a `statusPaymentPending` row. It does **not** leak into the guest's bookings list, and `getPropertyAvailability` only honours pending rows for **30 minutes** before releasing the dates — a proper payment hold with a timeout.
- **Non-host hitting host APIs.** A renter's token returns **200** from `/host/bookings/search`, `/host/dashboard/summary` and `/host/payout/history`. I checked the response bodies before calling it a leak: all three come back **empty**, because every query is scoped to the caller's own id. **Not a vulnerability.** The role gate is missing and safety rests entirely on that scoping — worth closing as defence in depth, not an incident.
- **"Guest" in the nav** on the confirmation page was my screenshot landing before `getUserDetail()` resolved. Not a regression.

### Fixed and verified

| # | Finding | Evidence |
|---|---|---|
| T-1 | 🔴 **Every listing claimed a mountain view.** The category chip read `category_titles` and fell back to the literal `"Mountain View"` — so a 2-BHK in Sector 62, Noida advertised a mountain view. The category was never missing: **search** returns `category_titles`, **single-property** returns `categories[].cat_title`, and this page only reads the single one. | Reads both; drops the chip when there is genuinely no category. Property 9 now reads "Apartments" |
| T-2 | 🔴 **Bookings never recorded whether the guest was verified.** `guest_verification_status` is only written by the per-booking DIDIT flow, so all 26 bookings read `unverified` — including ones by a renter DIDIT-verified since 28 July. A host checking who is arriving saw **every** guest as unverified. | Snapshotted at creation from the account's real status; failure can never block a booking |
| T-3 | I overstated a safety claim in Phase 4 | I wrote *"Guests complete an identity check before a booking is confirmed."* Running a booking showed that states more than the system holds: the check runs in the flow and does redirect an unverified guest to DIDIT, but it **fails open** if the service is unreachable and `POST /booking/create` has **no server-side gate**. Corrected on both platforms |
| T-4 | The **"Invoice"** button on the confirmation page, with a download icon, navigated to the dashboard — no invoice anywhere | The invoice is real: a PDF attached to the confirmation email. The page now says where it is |
| T-5 | 🔴 **A deploy with no Razorpay key takes payments that collect nothing** | `RAZORPAY_KEY_ID` is **not set on Render** (confirmed via `/health/env`), so the API runs on the bundled fallback test key. Checkout opens, the guest pays, the booking confirms, an invoice is issued — and no money moves. Invisible until someone reconciles a bank account. `/health/env` now reports `payments: { mode, usingFallbackKey, collectsMoney, warning }`. **Deliberately not a hard failure** — I first wrote it as a boot-time throw, then checked production: the key is missing *now*, so that would have crashed the API on the next deploy |

### Phase 6 — still open

| # | Item | Notes |
|---|---|---|
| T-6 | No server-side role gate on `/host/*` | Harmless today because every query is scoped by caller id, and confirmed empty for a non-host. Add the gate anyway |
| T-7 | KYC before booking is client-side and fails open | `POST /booking/create` accepts any authenticated user. If identity checks are meant to be a real gate, they belong on the server |
| T-8 | Bookings are capped at **3 months ahead** | `validateBookingDates` rejects anything further out. Probably deliberate, but it is not stated anywhere a guest can see — worth confirming it is intended |
