# Aajoo — 300 Manual Test Cases: Execution Report

**Source:** `Aajoo-300-Manual-Test-Cases.docx` (client, v1.0) — BK-001…100 Booking · NG-001…100 Negotiation · HL-001…100 Host Listing
**Run started:** 17 September 2026 · **Environment:** `aajaodev.onrender.com` (dev API), `www.aajoohomes.com` (web), Android build 100 (emulator; **build 106 from 20 September**; the app fixes of 20 Sep evening go into build 107)
**This file is updated after every batch.** Nothing is marked PASS without a recorded actual value.

---

## Running totals

| | Cases | PASS | FAIL | SPEC CONFLICT | BLOCKED | INFO | Not yet run |
|---|---|---|---|---|---|---|---|
| **BK — Booking** | 100 | 47 | 6 | 1 | 3 | 2 | 41 |
| **NG — Negotiation** | 100 | 50 | 7 | 2 | 3 | 3 | 35 |
| **HL — Host Listing** | 100 | 4 | 0 | 0 | 6 | 0 | 90 |
| **Total** | **300** | **101** | **13** | **3** | **12** | **5** | **166** |

**Batches 1–3 complete, batch 6 run (26 of 30), batches 4 and 7 part-run: 134 of 300 run.** Batch 6 (guest negotiation, 20 Sep evening): 17 PASS · 5 FAIL · 3 INFO · 1 BLOCKED · 4 not yet run. Fourteen batch-4 booking cases and four batch-7 host cases were proven on the same live loop (offer → counter → deal → pay-at-property booking → approval → check-in → guest check-out) with guest 101 on Chrome and host 100 on the emulator.

**Defects found: 15.** Fourteen fixed and pinned by tests the same day (Defects 9–15 are this sitting's: an offer accepted on nights the guest had already booked, a zero-night offer, the booking gate's notice/season rules switched off since 9 Sep, two offers from one click, the host told twice, a stay sent without its listing, "Currently Staying" before the host approved). One reported for the client's decision because it moves money (the 28–31 night pricing cliff). One app defect (no live refresh on the host's Negotiations) goes into build 107.

**Spec conflicts: 3.** Cases that describe behaviour the client themselves changed after the document was written — the cleaning fee (15 Sep), the round-one instant counter, and countering below the floor (9 Sep). The product is right; the document is stale.

---

## How this run is conducted

The client's document says to run the **Critical** cases first, and that is the order being followed: 44 of the 300 are Critical.

Each case is proven the cheapest reliable way, and the report always records **the actual value seen**, not just a verdict:

| Method | Used for |
|---|---|
| **Backend API pulls** against the live dev API | Data shape, privacy, money maths, server-side validation |
| **Database reads** (read-only) | The truth a response is checked against |
| **Claude in Chrome** on the live website | What a real signed-in user sees |
| **Android emulator**, build 100 | App parity for the same case |

**Two standing constraints, and they shape what can be run:**

1. **No passwords are entered.** Cases that need a fresh login must be driven by a person, or run on an already-open session.
2. **No writes on the client's test accounts** (rule §9 — "Aajoo Renter" 101 / "Sam Tao" 100). A stray booking or negotiation on those accounts has already been reported once as a bug. Cases that create data need a test account we own, and are marked **BLOCKED** until one is available rather than being run on the client's.

---

## Batch 1 — COMPLETE (30/30) · Booking: public page and the pricing maths

**Run 17 September 2026.** Public API, database reads, Chrome on the public property page. No login. Ground truth for 29291 read from `property_pricing`: base ₹2,000, weekend Fri/Sat/Sun ₹2,500, weekly ₹12,000, monthly ₹40,000, deposit ₹5,000.

| ID | Case | Result | Actual value seen |
|---|---|---|---|
| BK-001 | Open a property page | **PASS** | `/property?id=29291` — title, address, Verified badge, gallery, breadcrumbs, sections |
| BK-002 | Date picker opens | **PASS** | Two-month calendar; 1–16 Sep greyed (past); today circled; "Stays can be booked up to 3 months ahead" |
| BK-003 | Guest selector | **PASS** | "Guests" button, "2 guests", "7 guests maximum" |
| BK-004 | Price shows per night | **PASS** | "₹2,167 avg / night · These dates are priced differently · usually ₹2,000/night" |
| BK-005 | Price breakdown visible | **PASS** | 4–7 Oct: "3 nights (weekend rates apply) ₹6,500 · Taxes & GST (5%) ₹325 · Total ₹6,825" — Sun ₹2,500 + Mon ₹2,000 + Tue ₹2,000. **Matches the API's weekend logic exactly** |
| BK-006 | Book Now button visible | **PASS** | Primary "Book Now" button present |
| BK-007 | Mobile layout | **BLOCKED** | Desktop window would not resize below 1568px; needs the emulator (batch 4) |
| BK-008 | Image gallery swipes | **PASS** (presence) | Gallery grid + "View all photos"; swipe not driven on desktop |
| BK-009 | Map shows location | **PASS** | Map region present; "Approximate area — the exact address is shared after booking" |
| BK-010 | Loading state | INFO | Not captured — page loads in under the wait |
| BK-011 | Book 1 night | **PASS** | ₹2,000 |
| BK-012 | Book 5 nights | **PASS** | ₹10,500 = 4 × ₹2,000 + 1 weekend × ₹2,500 |
| BK-013 | Weekly stay | **PASS** | ₹12,000 package, not ₹15,500 per-night |
| BK-014 | Monthly stay | **FAIL** | ₹48,000 as 4 weeks — defect 3 (reported) |
| BK-015 | Mixed period (12 nights) | **PASS** | Composed 1 week + 5 nights; ₹22,500 |
| BK-016 | Weekend pricing applies | **PASS** | One Saturday = ₹2,500 |
| BK-017 | Seasonal rate applies | **FAIL → fixed** | Diwali fest ₹8,000 on 29307 quoted ₹5,880 (base) — defect 4 |
| BK-018 | Long-stay discount | **BLOCKED** | No listing in dev has `ppr_weekly_discount` / `ppr_monthly_discount` set. Needs data |
| BK-019 | Cleaning fee added | **SPEC CONFLICT** | `cleaningFee 500, cleaningFeeCharged false` — client decision 15 Sep: **stated, not charged** |
| BK-020 | Extra-guest fee | **PASS** | 29302, 6 guests vs 4 included: `extraGuestFee 1600` = 2 × ₹400 × 2 nights |
| BK-021 | Charge = quote | **PASS** (partial) | ₹10,500 + ₹525 = ₹11,025 reconciles; a real payment is needed for the full proof |
| BK-047 | No deposit on nightly | **PASS** | Quote charges no deposit; the page states it as collected by the host |
| BK-080 | Min/ideal hidden | **FAIL → fixed** | Defect 1 |
| BK-081 | No bank/KYC leak | **FAIL → fixed** | Defect 2 |
| BK-084 | Rate limiting | **PASS** (config) | `generalLimiter` = 600 req / 15 min; a 40-call burst correctly did not trip it |
| BK-090 | Across a season boundary | **FAIL → fixed** | Same root cause as BK-017 |
| BK-091 | Leap/odd month monthly | **PASS** | Feb 28 nights = 1 month; Apr/Oct need 30/31 — the calendar-month rule holds |
| BK-092 | Very long stay | **PASS** | 120 nights = 3 months + 3 weeks + 6 nights = ₹169,500. *Note: `maxNights` is 31 — the quote prices it; the booking step must refuse it (BK-032, batch 3)* |
| BK-095 | Currency rounding | **PASS** | No sub-paise anywhere in a 3-night, 5-guest quote on 29302 |
| BK-098 | Timezone on dates | **PASS** | 05-10 → 08-10 prices exactly 3 nights |

**Batch 1: 21 PASS · 5 FAIL (4 fixed, 1 reported) · 1 SPEC CONFLICT · 2 BLOCKED · 1 INFO**

---

## Batch 2 — COMPLETE (30/30) · Negotiation privacy and engine; backend price rules

**Run 17 September 2026.** The pure decision engine against the real tiers (29291: min ₹1,500 / ideal ₹1,700 / list ₹2,000), the live API, database reads, and the validation source.

| ID | Case | Result | Actual value seen |
|---|---|---|---|
| NG-001 | Guest never sees minimum | **PASS** | No minimum anywhere in the rendered property page |
| NG-002 | Guest never sees ideal | **PASS** | No ideal anywhere in the rendered page; "Price negotiable — send the host an offer" only |
| NG-003 | Min/ideal not in API | **FAIL → fixed** | Defect 1 |
| NG-004 | Counter reveals no floor | **PASS** | The auto-counter payload carries `counterPrice` only; `belowFloor` and `ideal` are withheld with the reasoning written in the code |
| NG-005 | Displayed price is ceiling | **PASS** | ₹2,001 → `reject / above_list_price` |
| NG-006 | Offer ≥ ideal auto-accepts | **PASS** | ₹1,700 → accept |
| NG-007 | Between min & ideal → host | **SPEC CONFLICT** | Instant counter at ₹1,700 — the client's round-one design |
| NG-008 | Below minimum → host flagged | **SPEC CONFLICT** | Countered at ₹1,750, `belowFloor: true` — client decision 9 Sep |
| NG-009 | Above displayed rejected | **PASS** | ₹2,500 → reject |
| NG-012 | Min ≤ ideal ≤ displayed enforced | **PASS** (by code) | `validateGrid` refuses per period with named messages; applied server-side in the wizard save |
| NG-013 | Nightly negotiation | **PASS** | Per-night tiers; counter at ₹1,700 |
| NG-014 | Weekly negotiation | **PASS** | Weekly tiers (10,000/11,000/12,000); counter at ₹11,000 |
| NG-052 | Every offer logged | **FAIL → fixed** | 17 guest offers had no ledger row — defect 5 |
| NG-053 | Log has outcome | **PASS** | `nl_final_outcome` "booked"/"abandoned"/NULL, `nl_final_price` populated |
| NG-054 | Log has no leak | **PASS** | `tbl_negotiation_log` stores the tiers (an audit ledger should) but **no guest route reads it** — admin only |
| NG-055 | Status transitions valid | **PASS** | Only pending / countered / accepted / declined / expired exist |
| NG-064 | Offer exactly = ideal | **PASS** | accept |
| NG-065 | Offer exactly = minimum | **PASS** | countered at ₹1,700 — not accepted at the floor |
| NG-066 | Offer exactly = displayed | **PASS** | accept at ₹2,000 |
| NG-067 | 1 rupee below ideal | **PASS** | countered at ₹1,700 |
| NG-068 | 1 rupee below min | **PASS** | countered, `belowFloor: true` |
| NG-069 | Decimal offer | **PASS** | ₹1,650.50 handled, countered at ₹1,700 |
| NG-070 | Very low offer | **PASS** | ₹1 → countered at ₹1,900 — never at or below the floor |
| NG-085 | Min = ideal = displayed | **PASS** | ₹1,800 against 2,000/2,000/2,000 → countered at ₹2,000, never under list |
| NG-086 | Ideal just below displayed | **PASS** | countered at the ideal ₹1,999 |
| NG-087 | Very high displayed price | **PASS** | ₹900,000 vs ideal ₹800,000 → accept |
| HL-060 | Backend enforces min photos | **PASS** (by code) | `photoGap` / `photosBlock` computed server-side from `PHOTO_RULES.minimum`, returned as `blocking` |
| HL-066 | min ≤ ideal ≤ displayed | **PASS** (by code) | "ideal price can't be higher than your cheapest rate" |
| HL-067 | min > ideal rejected | **PASS** (by code) | "ideal price can't be below your minimum" |
| HL-087 | Backend re-validates publish | **PASS** (by code) | `submitListing` re-checks the lifecycle transition, all declarations, agreement acceptance, the photo gap and the document gap before any status changes |

**Batch 2: 26 PASS · 2 FAIL (both fixed) · 2 SPEC CONFLICT**

> The four "by code" verdicts are the server-side rule confirmed in source. They are **exercised through the API in batch 10**, which needs a host token.

---

## Batch 3 — COMPLETE (30/30 run; 20 PASS · 2 INFO · 8 BLOCKED) · Security, ownership and rejected input

**Run 20 September 2026** against the live dev API, by direct request. Only the cases that need **no account** were run: every other case in this batch needs a guest or host token, and the two sessions available on this machine that day were the client's own — host 100 in Chrome, guest 101 on the emulator — which rule §9 says are never to be driven, even for a refusal (a validation case that unexpectedly *succeeds* would create data on the client's account, which is how the earlier "test deal on 101" report happened).

| ID | Case | What was sent | Actual | Verdict |
|---|---|---|---|---|
| BK-033 | Book without login | `POST /booking/create` with a body that passes validation (property 29306, 25→26 Sep, ₹2,000, 2 guests), **no token** | `401 {"success":false,"message":"Authorization token is required"}` — nothing created | **PASS** |
| BK-083 | Auth required | `GET /user/booking-history` with no token; and `POST /booking/create` with a garbage bearer token | `401 "Authorization token is required"`; `401 "invalid token"` | **PASS** |
| NG-043 | Offer without login | `POST /user/negotiations/offer` (property 29306, ₹1,500, 25→26 Sep), **no token** | `401 "Authorization token is required"` — nothing created | **PASS** |

**Observation (not a defect, recorded):** `/booking/create` validates the body *before* checking the token, so an unauthenticated call with an incomplete body is answered `422` with the missing fields rather than `401`. No data is created either way and a complete body meets the auth wall; the order only means an anonymous caller can learn the field names, which the public API documentation already shows.

**Second sitting, 20 September 17:00–19:00 IST — on guest 101 "Aajoo Renter", by Sumit's explicit instruction of 20 Sep** ("I logged in this account, you can use this for any testing"), signed in on both Chrome (website) and the emulator (build 106). Every request below was made against **listings owned by our own hosts** (177 "Host Mobile": 29306, 29295; 194: 29305, 29303), so the client's host inbox saw nothing. The API calls were sent from the signed-in page (the token never left the browser); the UI was driven on both surfaces.

| ID | Case | Sent / done | Actual | Verdict |
|---|---|---|---|---|
| BK-026 | No dates | `POST /booking/create` with no dates | `422 "check in date is required \| check out date is required"`. Web: the bar reads *Select dates* and Book Now opens the calendar. App: *Book To* empty, the sheet will not price. | **PASS** |
| BK-027 | Check-out before check-in | 28→26 Sep on 29295 | `400 "Booking must be at least 1 day."` Both pickers are ranges; the reversed order cannot be chosen. | **PASS** |
| BK-028 | Past date | 10→12 Sep | `400 "Booking start date cannot be in the past."` Web calendar: 1–19 Sep greyed. App: 1–19 Sep greyed. | **PASS** |
| BK-029 | Zero guests | `no_of_guests: 0` | `422 "Number of guests must be at least 1"`. Web: the adults minus stops at 1. App: minus disabled at 1. | **PASS** |
| BK-030 | Over capacity | 6 guests on 29306 (sleeps 5) | `400 "This stay sleeps up to 5 guests."` Web: plus disabled at 5, *"that's the maximum"*. App: plus disabled at 5. **But** the host set *3 adults + 2 children + 2 infants* and **five adults were accepted by the API, the website and the app** — only the total bound anything. → **Defect 6**, fixed the same day (backend `0d0afed`, web `9886e06`, app in the next build). | **PASS** (total) · **Defect 6** (per-type) |
| BK-031 | Below min stay | 1 night on 29306 (min 3), at the server's own quote of ₹4,500 | `400 "This host asks for a minimum stay of 3 nights."` Web calendar: *"Minimum 3 nights — check out 28 Sept or after"*, 26/27 unselectable. App picker: *MINIMUM STAY 3 NIGHTS*, 21/22 unselectable. | **PASS** |
| BK-032 | Above max stay | 41 nights on 29306 (max 40), at the quote of ₹1,09,500 | `400 "This host accepts stays of up to 40 nights."` Footer on both pickers states the rule. | **PASS** |
| BK-034 | Book without KYC | — | Guest 101 is verified; the gate (`blockUnlessVerified`) is pinned by `verificationIsCurrent.test.js` and §8a43's tests. A live refusal needs an unverified guest we own. | **BLOCKED** |
| BK-035 | Empty guest details | — | The platform books for the **verified account** (name, phone and ID come from the profile); the checkout collects no guest details, and saved travellers are optional. There is no empty state to refuse. The case describes a form the product does not have. | **INFO** |
| BK-036 | Invalid phone | `POST /user/update {user_pnumber: "12345"}` | `422 "Phone number must be exactly 10 digits"` | **PASS** |
| BK-037 | Invalid email | `POST /user/update {user_email: "not-an-email"}` | `200 Success` — and the email on file **unchanged** (read back). Email is read-only platform-wide (§account security); the field is ignored rather than refused, and no screen offers it. | **PASS** · note |
| BK-079 | Own bookings only | `GET /user/booking-history`; DB read | 3 rows (B115781, B675275, B939553), all `book_user_id = 101` in the table; 3 = every booking 101 has. `POST /admin/booking/detail` with the guest token: `401 "Invalid token"`. | **PASS** |
| BK-082 | Tampered price | `price: 1` for 29295 (quote ₹7,650), pay-at-property | `400 "The price for these dates has changed. Please reload and try again."` — nothing created (the server compares the sent price with its own quote, ±₹1). | **PASS** |
| NG-039 | Zero offer | `offerPrice: 0` | `422 "offer price must be greater than 0"` | **PASS** |
| NG-040 | Negative offer | `offerPrice: -100` | `422 "offer price must be greater than 0"` | **PASS** |
| NG-041 | Non-numeric offer | `offerPrice: "abc"` | `422 "offerPrice must be a number type…NaN"` | **PASS** |
| NG-042 | Offer on fixed-price listing | — | Every active listing has negotiation on (DB read: none with `pn_enabled = 0`). Needs a host to switch one off (batch 8/10). | **BLOCKED** |
| NG-090 | Replay | The identical offer sent twice (29306, today→23 Sep, ₹3,100) | Second: `400 "The host has countered your offer — accept or decline that first."` | **PASS** |
| NG-091 | Tampered offer | Offer with `status: "accepted", agreedPrice: 1, finalPrice: 1, couponCode: "FREE100"` in the body | `200` — created as an ordinary offer; DB: offer 221 stored at **₹3,100, status countered**; the engine's counter 222 at ₹3,800 pending. None of the extra fields took effect. (An offer for October was first refused: *"Offers are for stays starting today. This is an advance booking, so the listed price applies"* — the platform's own rule.) | **PASS** |
| NG-094 | Expired session | A token expired 60 s ago, through the real `authenticateJWT` | `401 "Session expired, please try again"`; a token signed with the wrong key: `401 "invalid signature"` (`anExpiredSessionIsRefused.test.js`). Live: the platform's secret is not the local one, so an expired live token cannot be minted on demand. | **PASS** by test |
| NG-096 | Guest offers on own listing | — | 101 owns no listing. | **BLOCKED** (host) |
| HL-077, 079, 080, 098, 099, 100 | Host-side | — | | **BLOCKED** (host sign-in) |

**Records this sitting created on account 101** (so nobody reads them as a bug): negotiation thread on listing 29306 for 20→23 Sep — offer 221 (₹3,100, countered) and the engine's counter 222 (₹3,800, pending, expires by itself). No booking was created; every booking attempt was a refusal by design.

**Found beside the cases (not in the sheet), all fixed the same day and pinned by tests:**
- **Defect 6 (Medium, all three surfaces)** — per-type capacity not enforced; see BK-030.
- **Defect 7 (Medium, app)** — the booking sheet printed *"Check-in/Check-out Time 12:00PM / 12:00PM · set by the host"* for a host who set 14:00 / 11:00: the app read only the legacy row and never the wizard's `stayWindow` (the API sends it). Fixed: the sheet now reads the wizard hours and prints *2:00 PM / 11:00 AM*.
- **Defect 8 (Low, app parity)** — *"Where you'll sleep"* on a three-bedroom listing listed only *Bathroom 1, Bathroom 2*: a bedroom with no bed line was skipped, while the website lists every bedroom. Fixed: every bedroom is shown.
- Observation (Low, app): the sticky bar prices *"1 night"* before any dates are chosen, on a listing with a 3-night minimum. Not changed; noted for the design pass.

---

## Batch 6 — RUN (26/30; 17 PASS · 5 FAIL · 3 INFO · 1 BLOCKED) · Negotiation — the guest side

**Run 20 September 2026, 18:00–19:30 IST.** Guest 101 "Aajoo Renter" on Chrome (website), host 100 "Sam Tao" on the emulator (build 106) — both by Sumit's instruction that day. The loop was run on **host 100's own listing 29291 "Aajoo Homes"** (₹2,000/night, ₹2,500 on the weekend night of Sun 20 Sep; floor ₹1,500, target ₹1,700; approval required, 1 hour) so that the host half could be driven on the emulator; the API probes went to our own host 177's listing 29306 and to 29302. Every record created is listed at the end of this section.

**First obstacle, and a host-calendar PASS:** 29291 carried a host block *"QA end-to-end test block"* for 20–22 Sep (left by the 10 Sep QA run), and offers are only for stays starting today. The host's calendar on the app showed the block (amber, *"September at a glance"*), *Unblock these dates* removed it, and the guest's offer calendar on the website offered 20 Sep on the next open — **BK-054 / BK-055 PASS** (blocked dates greyed on the guest side while blocked; accurate the moment the host changed it).

| ID | Case | Sent / done | Actual | Verdict |
|---|---|---|---|---|
| NG-016 | Make an Offer button | Listing 29291, signed in | *Send an Offer · Negotiate and save more* under Book Now; opens *Send an Offer* (price per night placeholder = listed, dates, optional message) | **PASS** |
| NG-017 | Offer input validates | Send with nothing; `abc`; `0`; `-500`; ₹1,700 with no dates | *"Enter the price you'd like to offer."* — `abc` and the minus sign are stripped at the keyboard; `0` → the same message; a price with no dates → *"Pick the dates you'd like to stay — the host agrees to them along with the price."* (API: 0 / −100 / abc → 422, batch 3) | **PASS** |
| NG-018 | Offer confirmation | ₹1,700, 20→21 Sep, *"Test run NG-018 — one night, two of us."* | *"Your price is with the host — They can accept, decline or counter… we've emailed them as well."* with *View in My Negotiations* | **PASS** |
| NG-019 | Offer status visible | My Negotiations | Card **Waiting on host**; tabs *All (5) · Your move (1) · Waiting on host (1) · Accepted (2)* move with every step | **PASS** |
| NG-020 | Counter shown to guest | Host countered ₹2,200 on the app at 18:10 | *Host countered ₹2,200/night — "Weekend night - best I can do is 2200"* at 18:10, with **Accept ₹2,200/night · Counter · Decline** | **PASS** |
| NG-022 | Real-time update | Watched both screens without reloading | **Web:** banner *"The host countered — ₹2,200/night"* and the card flipped to *Your move* without a reload (socket). **App (host):** the guest's ₹2,000 counter did **not** appear on the open Negotiations list — it needed pull-to-refresh; after the host's own second counter the card kept showing Accept/Counter/Decline. The app subscribes to no `negotiation:*` or `notification:new` event. | **PASS web · FAIL app** → build 107 |
| NG-023 | Offer thread readable | The 29291 card | One transcript, dated (13 · 15 · 17 · 20 Sept), every price with its clock and its message, both directions, sessions separated | **PASS** |
| NG-024 | Mobile negotiation UI | Host side on the emulator | Card: *Aajoo Renter offered ₹1,700 · Round 9 · ~~was ₹2,500~~ · 32% below · ⚠ This is below the minimum you set for this stay*, dates, the transcript, **Accept · Counter · Decline**; counter dialog *"Aajoo Renter offered ₹1,700/night against your ₹2,500/night"*. Guest side on the app not run (the emulator holds host 100). | **PASS** (host) · guest side pending sign-in |
| NG-025 | Waiting state | After the ₹1,700 offer and after the ₹2,000 counter-back | *Waiting on host* badge; the *"host is away… usually reply within 1 hour"* line is written to appear after 90 s and was not seen because the host answered inside two minutes each time | **PASS** |
| NG-034 | Guest counters back | Counter dialog | ₹2,300 refused: *"That is at or above the ₹2,200/night the host offered. Counter lower, or accept their price instead."*; ₹2,000 with *"Could you meet me at the weekday rate?"* sent → *Waiting on host* | **PASS** |
| NG-035 | Multiple rounds | 1,700 → 2,200 → 2,000 → 2,100 | Rounds 9–12 on the thread (offers 223–226); the app labelled *Round 11* on the guest's second counter; no cap | **PASS** |
| NG-036 | Guest accepts counter | Accept ₹2,100/night | Card **Accepted**; *Book at the agreed price · Your deal is applied at checkout and lasts until midnight tonight*; on the listing: *"Your negotiated deal is on — 16.01% off (code DEAL29291101C226) · Agreed for 20-09-2026 → 21-09-2026 · Expires in 5h 38m"*, ₹2,100 ~~₹2,500~~, dates locked (*Book different dates without the deal*) → booked as **B021812** | **PASS** (the 16.01% is Defect 10) |
| NG-037 | Guest declines counter | *Decline* on the 29306 thread (host counter ₹3,800 from batch 3) | *"Offer declined."*; card **Declined**; the host's ₹3,800 marked declined. A guest decline sets no lock-out (only a host decline does) | **PASS** |
| NG-038 | Round limit | — | No cap by the client's instruction of 12 Sep; twelve rounds ran on 29291 | **INFO** (spec behind the product) |
| NG-044 | Offer on unavailable dates | API: offer for 20→21 Sep on 29291 **after** B021812 booked those nights; the website had greyed 20 Sep | `200` — **offer 227 created, pending, on the host's queue** for a night the guest already held. Fixed the same day (`4a88a61`): now `409 "You already have a booking here for these dates — there is nothing left to negotiate. Find it under My Bookings."`; someone else's booking → *"These dates are already booked for this property."*; a host block → *"The host has closed these dates…"* | **FAIL → fixed** (Defect 11) |
| NG-045 | Offer after booking | Listing 29291 after B021812 | Sidebar: *You're booked here 20 Sep → 21 Sep · B021812 · View your booking · Book other dates*; today greyed in the offer calendar; 21→22 refused *"Offers are for stays starting today…"*. The API hole above is the same defect. | **FAIL → fixed** (Defect 11) |
| NG-046 | Offer expiry | Offer 230 on 29306 (₹3,200, 19:03) left pending; platform default 30 min | *(read after 19:35 — see the note below the table)* | **pending** |
| NG-071 | Rapid repeat offers | Three identical offers fired in the same instant (29306, ₹3,200, 20→23 Sep) | **Two created** (230, 231), only the third refused *"You already have an offer waiting on this stay."* The claim locked the guest's existing rows — none — and committed before the insert. Fixed (`62e652f`): the claim takes the listing row and holds it across the insert. Re-run after deploy: see the note. | **FAIL → fixed** (Defect 15) |
| NG-072 | Offer then cancel | — | There is no way for a guest to withdraw a pending offer; it expires (30 min, or the host's window) or the host answers it. Recorded for the design pass. | **INFO** |
| NG-073 | Guest edits offer before submit | Offer dialog and counter dialog | 2000 → abc → 0 → −500 → 1700 before *Send Offer*; 2300 (refused) → 2000 before *Send counter*; the field keeps the last edit | **PASS** |
| NG-075 | Negotiate weekly then book nightly | The 29291 deal banner | A deal is pinned to its dates (`cpn_book_from/to`): *"The deal only applies to these dates"*, and the picker's only way out is *Book different dates without the deal* at the listed price. A weekly deal cannot price a single night. | **PASS** (by the date lock) |
| NG-076 | Offer on LUXE listing | — | Not run this sitting | not run |
| NG-078 | Offer notification failure | — | A failed notification never fails the reply — pinned (*"a failed notification cannot fail the reply"*, `theHostHearsEveryGuestReply.test.js`); failures are logged at WARN and the offer stands | **INFO** |
| NG-079 | Currency in offer | Every screen and the API | ₹ with Indian grouping throughout — *₹2,200/night*, *₹43,050 for 7 nights*; an extra `currency: "USD"` field in the body is ignored | **PASS** |
| NG-080 | Session lost mid-negotiation | — | Signing out means a password to sign back in, which a session never types. The expired-token refusal is pinned (NG-094). | **BLOCKED** |
| NG-081 | Accept exactly at expiry | — | Not run this sitting (needs a counter timed to its own expiry) | not run |
| NG-082 | Guest offers after decline | Offer on 29306 after the guest's own decline (NG-037) | `200` — offer 229 accepted and escalated (a guest decline sets no lock-out); expired again as clean-up | **PASS** |
| NG-088 | Offer history after booking | The 29291 card after B021812 | Every round and the accepted ₹2,100 still on the thread; the card's badge follows the **latest** message, so after the expired probe 227 it read *Expired* while the deal below it had already been used — noted, not a defect | **PASS** |
| NG-089 | Language in negotiation | — | Not run this sitting | not run |
| NG-092 | Offer for 0 nights | API: 20→20 Sep on 29302 | `200` — **offer 228 created, pending**, on a listing that asks for two nights and six hours' notice. Fixed (`bdab3b1`): *"Choose a check-out after your check-in — a stay is at least one night."*; and the host's rules now bind offers: *"This host needs 6 hours notice before check-in, so the earliest available date is 21-09-2026."*, *"This host asks for a minimum stay of 2 nights."*, a past date → *"The earliest available check-in is 20-09-2026."* | **FAIL → fixed** (Defect 12) |

**NG-046 / NG-071 follow-up:** _to be filled when offer 230 has expired and the three-at-once probe is repeated against the deployed lock._

**Batch 4 cases proven on the same loop** (the deal was booked pay-at-property, the host approved and checked the guest in on the app, the guest checked out on the website):

| ID | Case | Actual | Verdict |
|---|---|---|---|
| BK-022 | Confirmation created | *Request sent — Your request for Aajoo Homes has gone to the host. They have 1 hour to respond — if they don't, your booking is confirmed automatically.* Reference, payment, dates, ₹2,205 on arrival, *You saved ₹400* | **PASS** |
| BK-025 | Booking ID generated | **B021812** (pri 140), on the confirmation, Next Booking and the host's card | **PASS** |
| BK-048 | Currency correct | ₹ on every line, both surfaces | **PASS** |
| BK-049 | Tax shown | *Taxes & GST (5%) ₹104.99* on the listing, review and payment pages; total ₹2,204.74 | **PASS** |
| BK-054 | Blocked dates unbookable | 20–22 Sep greyed on the guest calendar while the host's block stood | **PASS** |
| BK-055 | Availability calendar accurate | Open the moment the host removed the block; 20 Sep greyed again the moment B021812 held it | **PASS** |
| BK-057 | Minimum notice | The calendars honoured 29302's six hours (*earliest 21-09-2026*) — but the **booking gate's SELECT dropped the notice, advance, same-day and season columns** (since `c2dd020`, 9 Sep), so `checkInAllowed` and `stayFitsSeason` were running on `undefined`. Proven by reading the code (a live probe was refused earlier by the one-unpaid-pay-on-arrival rule); fixed `bdab3b1` and pinned so the SELECT can never narrow again. | **FAIL → fixed** (Defect 12) |
| BK-073 | Ongoing stay shown | Next Booking / Ongoing Stays showed B021812 — but read *Currently Staying* with a *Check out* button **before the host had approved** (Defect 14, web, fixed `32fb9c1`) | **PASS** after fix |
| BK-076 | Check-in details | Host set 02:01 / 10:00 in the wizard. Review page: *check-in was 20 Sept, 2:01 am IST*; confirmation: *2 AM / 10 AM*; Next Booking: **2 PM / 11 AM** — `/user/ongoing/bookings` read its listing id from the wrong key and sent the platform default (Defect 13, fixed `4aab209`); after deploy: *20 Sept, 2 AM · 21 Sept, 10 AM* | **FAIL → fixed** |
| BK-077 | Host contact revealed | Before approval: *"The exact address appears once the host accepts your request."* After the host confirmed (18:58): full address, map, *Get directions*, host phone link | **PASS** |
| BK-078 | Review after stay | Guest *Check out* → *"Checked out — thanks for staying with Aajoo Homes."* → **Write a Review** (overall + six categories) | **PASS** |
| BK-085 | Negotiated price used | ₹2,500 − 16.01% = ₹2,099.75 + GST ₹104.99 = **₹2,204.74**, `book_coupon_code = DEAL29291101C226`, `book_discount_amt = 400.25`. (Defect 10: the exact 16% became 16.01% in floating point — 25 paise under, fixed for the next deal.) | **PASS** |
| BK-093 | Instant vs approval | Approval-required listing → *Request sent*, host card *Awaiting approval* with *Confirm this booking / Decline this request*; *Confirming…* → *Staying now* with *Mark guest as checked-in / Guest didn't arrive (no-show)* | **PASS** |
| BK-096 | Coupon applied | The deal code applied itself at checkout: review page *Negotiated deal applied — Coupon DEAL29291101C226 — you save ₹400*, payment page *Discount (DEAL29291101C226) − ₹400.25* | **PASS** |

Also on this loop: the host's check-in **recorded the cash collection** (`book_is_paid = 1`, status 6) and the web showed *Paid* the next reload; the guest's check-out took the stay to status 7 on both ends and the host's card to *Completed · Paid* with no check-out button (Defect 8 of §8a45, verified live). The app files that completed stay under **Ongoing** (by its dates) rather than *Completed* (by its status) — Low, for build 107.

**Batch 7 cases proven on the host's emulator:**

| ID | Case | Actual | Verdict |
|---|---|---|---|
| NG-021 | Accept/decline buttons (host) | *Accept · Counter · Decline* under the guest's latest offer; *Counter the offer* dialog with price and message | **PASS** |
| NG-026 | Host notified of offer | Bell: *New price offer — A guest offered ₹1,700/night for Aajoo Homes for 20-09-2026 → 21-09-2026. Review it in Negotiations.* (5 min after); tapping it lands on Negotiations. **But** the guest's counter produced **two** rows at the same minute (*The guest countered your price* + *The guest countered back*) — Defect 9, fixed. No push notification reached the emulator's shade (FCM on an emulator; the in-app rows and the email path are the record). | **PASS** (Defect 9 beside it) |
| NG-029 | Host counters | ₹2,200 *"Weekend night - best I can do is 2200"* and ₹2,100 *"Meet you halfway - 2100"* → *Counter sent — the guest decides next.*; both reached the guest live | **PASS** |
| NG-032 | Host sees offer amount | *₹1,700 · Round 9 · ~~was ₹2,500~~ · 32% below*, then *₹2,000 · Round 11 · 20% below* | **PASS** |

**Records this sitting created (host 100 / guest 101 — the client's own test accounts, by instruction):**
- Host 100's calendar: block 19 *"QA end-to-end test block"* (20–22 Sep, 29291) **removed** through the app.
- Negotiation on 29291: offers **223** (₹1,700) · **224** (host ₹2,200) · **225** (₹2,000) · **226** (host ₹2,100, accepted); deal coupon **DEAL29291101C226** (16.01%, used once).
- Booking **B021812** (pri 140) on 29291, 20→21 Sep, pay at property, ₹2,204.74: approved 18:58, checked in 18:59 (cash recorded), guest check-out 19:00 → status 7. **Host dues row `hd_id 49` — ₹476.99 PENDING against host 100** (commission ₹315 + GST ₹57 + accommodation tax ₹104.99) was raised by this test booking and **needs an admin void with reason "test run"**, or it will surface in the client's payout ledger.
- Probe offers, each set to *expired* by a direct database update the moment its case was read (there is no guest withdraw): **227** (29291), **228** (29302), **229** and **231** (29306). **230** (29306, ₹3,200) left pending for NG-046.
- The 29306 thread from batch 3: host counter 222 **declined** by the guest (NG-037).
- No review was submitted; the *Write a Review* page was opened and left.

**Found beside the cases, all fixed the same day and pinned by tests** (details under Defects 9–15): the host told twice for one counter; the deal percentage rounded by floating point; an offer accepted on the guest's own booked night; a zero-night offer and the booking gate's stay rules half switched off; an ongoing stay sent without its listing (cover, hours, pin); *Currently Staying* before the host approved; two offers from one click. **For build 107 (app):** the host's Negotiations list does not refresh live and keeps stale buttons after the host's own counter; a completed stay is filed by its dates under Ongoing; the app never subscribes to `negotiation:*` / `notification:new`. Also noted: the payment page said *"The host has 1 hours to approve"* (fixed with Defect 14).

---

## Defect 1 — the host's floor and accept line were public (Critical)

**Cases:** BK-080, NG-003 · **Found:** 17 Sep 2026 · **Status:** fixed, pinned, awaiting deploy

An **unauthenticated** `GET /properties/:id` returned the complete W2 negotiating grid inside the modular pricing block:

| Property | `nightlyMin` (floor) | `nightlyIdeal` (accept line) |
|---|---|---|
| 29291 Aajoo Homes | ₹1,500 | ₹1,700 |
| 29302 QA Sunrise Villa | ₹2,500 | ₹2,800 |
| 29310 Glamping at the Ladakh | ₹10,000 | ₹11,000 |

…plus the weekend, weekly and monthly pairs for each.

**Why it matters.** The client's own document names this as golden rule 3: *"the guest NEVER sees the minimum or ideal price. If the minimum leaks, every guest offers exactly minimum and all margin is lost."* Concretely:

- A guest could read the exact price that **auto-accepts** and never offer a rupee more.
- A guest could read the host's **true floor** and anchor every offer to it.
- Anyone at all — no login — could walk `/properties/1..n` and harvest **every host's cost base**.

It also corroborates the client's own 17 Sep screenshots: the auto-counter they saw at ₹2,300 is `weekendIdeal`, and the ₹1,700 they settled at is `nightlyIdeal`.

**Why it survived.** This leak had **already been found and fixed once** — for the two flat columns `property_mini_price` and `property_ideal_price`, with a comment in `getProperty` explaining exactly why. The fix never reached the **nested pricing block** that `getListingExtras` builds, because the negotiation engine legitimately needs those figures and nothing trimmed them on the way out. One door shut, the other left open.

**Fix.** `getProperty` now strips every `*Min` / `*Ideal` field from the pricing block for anyone who is not the listing's owner. The engine still reads them from the database; only the wire shape is trimmed. The host keeps them on their own listing.

**Verified safe:** no guest client reads these fields — the only readers are the admin panel, on different endpoints with different field names.

---

## Defect 2 — every host's phone number, in bulk, unauthenticated (Critical)

**Case:** BK-081 · **Found:** 17 Sep 2026 · **Status:** fixed, pinned, awaiting deploy

`POST /properties/search` selected `property_contact` and returned it on every result card:

```
property 29291 "Aajoo Homes"
   property_contact = '9876543210'
```

**Why it matters.** Search takes a latitude and longitude, so this is not one number — it is **every host's personal phone number, harvestable by walking the map**, with no account required.

**Why it survived.** The same pattern as defect 1. `getProperty` hides `property_contact` and `property_email` from non-owners and carries a note saying these are written from the host's own mobile and email at listing time and that no guest-facing screen uses them. Search was never given the same treatment.

**Fix.** The column is no longer selected by search.

**Verified safe:** both app models declare it `String? propertyContact` — nullable — so its absence parses cleanly. Every screen that displays a host contact reads it from a **booking** or from the host's **own** listing, never from search.

---

## Defect 3 — a shorter stay can cost ₹12,000 more than a longer one (Critical, money)

**Case:** BK-014 · **Found:** 17 Sep 2026 · **Status:** reported, NOT changed — it moves money

A stay is decomposed greedily into months, then weeks, then nights. A "month" is a **real calendar month**, by the client's own decision of 5 September 2026: *"the host's monthly price buys a month, so it is divided by the month the stay actually starts in."* October has 31 days, so a month there is 31 nights.

That rule works exactly as documented. Its **consequence** is the problem:

| Stay starting 5 Oct 2026 | Price | Composed as |
|---|---|---|
| 28 nights | ₹48,000 | 4 weeks |
| 29 nights | ₹50,000 | 4 weeks + 1 night |
| 30 nights | ₹52,000 | 4 weeks + 2 nights |
| **31 nights** | **₹40,000** | **1 month** |

**A guest staying 30 nights pays ₹12,000 more than one staying 31.** The 28-night quote even advertises a "22.6% saving" while charging ₹8,000 above the host's own monthly rate of ₹40,000.

Confirmed to be a function of month length rather than a one-off:

| Stay starts in | 28 nights | 29 | 30 | 31 |
|---|---|---|---|---|
| February 2027 (28 days) | ₹40,000 · 1 month | ₹42,000 | ₹44,000 | ₹46,000 |
| April 2027 (30 days) | ₹48,000 · 4 weeks | ₹50,000 | — | — |
| October 2026 (31 days) | ₹48,000 | ₹50,000 | ₹52,000 | **₹40,000** |

So BK-014's premise — "28 nights = monthly price" — is only true for a stay starting in February. The rest of the time the guest is charged four weekly packages.

**Recommended fix:** the price for N nights must never exceed the price for N+1. Cap the greedy decomposition at the cheapest package that covers the stay — if one month is cheaper than four weeks plus nights, charge the month.

**Not changed unilaterally.** The client decided the month rule on 5 September, and this fix lowers revenue on 28–30 night stays, so it belongs with them — the same treatment as the counter-price question. Nobody intends "stay less, pay more", but it is their money.

**On the deposit half of BK-014:** the quote carries no deposit field at all, but the guest *is* shown it — the property page reads `securityDeposit` from the property payload and prints "The host asks for a ₹5,000 security deposit". So that half passes in substance; the quote endpoint simply is not where it lives.

---

## Defect 4 — a host's festival or season price was silently ignored (High, money)

**Cases:** BK-017, BK-090 · **Status:** fixed, pinned

Property 29307 carries "Diwali fest — from 8 Nov — ₹8,000". A night inside it quoted **₹5,880**, identical to any other night. Two silences stacked: the wizard saved the period with **no end date** (and would save one with no price — 29291 has a September "season" priced null), and the pricing engine **dropped any period missing either** on read. The host was never told; the guest was never charged the host's price.

**Fix:** the wizard now refuses a period the host started but did not finish, naming it — *"Diwali fest" needs a start date, an end date and a price to apply*. An untouched blank row is still ignored quietly. The engine honours an existing row with a start and a price but no end **for its start date** — one day is the least it can mean and the most it is safe to assume.

---

## Defect 5 — an accepted negotiation was missing from the ledger (High, data)

**Case:** NG-052 · **Status:** fixed, pinned

**17 guest offers** had no row in `tbl_negotiation_log`, and the ledger held **4 `accept` actions against 21 accepted offers.** One branch: a guest counters back at or above the accept line, the platform takes it, a coupon is minted, the host is told — and nothing was logged. The escalation branch beside it got its log row on 9 September; this one never did.

**Fix:** the branch logs with the same tier snapshot as its neighbour. `nl_final_outcome` is deliberately left NULL — it becomes "booked" via an UPDATE that only touches NULL rows, so writing anything there would have stopped that landing.

---

## Defect 6 — the host's per-type capacity was decoration (Medium, all three surfaces)

Listing 29306 is set to 3 adults, 2 children, 2 infants — 5 in all. The API, the website's picker and the app's counter all allowed **five adults**: only `pc_total_guests` was ever read. Fixed 20 Sep: `utils/partyCapacity.js` reads the per-type caps (0 = unanswered, exactly as pets), children count within guests so adults are what is left, and the booking passes children and infants; the website's picker stops at the caps and says them (*"Up to 3 adults · 2 children · 2 infants"*); the app's counter stops the same way. Backend `0d0afed`, web `9886e06`, app monorepo `f0ff3ba`. Pinned: `partyFitsProperty.test.js` (+5), web `theClientsFiveOf18September` re-anchored, app `the_party_fits_the_hosts_caps_test.dart`.

## Defect 7 — the app told guests the wrong check-in time (Medium, app)

For every wizard-built listing the booking sheet said *12:00PM / 12:00PM · set by the host* — the host's actual hours (`stayWindow`, sent by the API) were never read. Fixed 20 Sep (monorepo `f0ff3ba`): `StayWindow` on the model, the sheet reads it first and prints *2:00 PM / 11:00 AM*. Pinned: `the_listing_says_what_the_host_set_test.dart`.

## Defect 8 — "Where you'll sleep" without the bedrooms (Low, app)

Same fix set: a bedroom the host had not described was hidden, so a three-bedroom stay listed two bathrooms under that heading while the website listed the bedrooms. Every bedroom is shown now, as on the web.

## Defect 9 — the host was told twice for one guest counter (Medium, backend)

One guest counter of ₹2,000 put two rows in the host's bell at the same minute — *The guest countered your price* and *The guest countered back* — and since both writers push and mail, two pushes and two emails. The 17 Sep fix (`8e26e26`) put `tbl_notifications.notify` inside `tellHost` for accept, decline **and** counter on the premise that the endpoint had only ever sent a socket event; true of accept and decline, but the counter branch had told the host since 23 Aug through `methods.sendNotification`, and the merged notification list reads both stores. The same double row sat on the counter-that-meets-the-line path. Fixed `0008c3e`; the live `negotiation:guest_reply` event, which lived in the same helper, was restored for both paths in `a7a5929` after the website's `notificationsArriveLive` test caught its loss. One event, one row, still one live event.

## Defect 10 — a deal that divides exactly was rounded up by floating point (Low, backend, money)

₹2,100 agreed on a ₹2,500 night came out as *16.01% off* and billed ₹2,099.75: `1 − 2100/2500` is `0.16000000000000003` to the machine and a bare `Math.ceil` made an exact 16% into 16.01%. Under a rupee and in the guest's favour, which is the documented tolerance, but a deal that divides exactly should say so. Fixed `54b13c8`: the percentage is settled to a millionth before the ceiling, in one exported `dealPercent()` the test imports instead of copying.

## Defect 11 — an offer was accepted on nights the guest could not book (High, backend)

The website greys a booked night out of the offer calendar; the endpoint did not look. Guest 101 had just booked 29291 for 20→21 Sep (B021812) and an offer for the same night went straight to the host as *pending* (offer 227) — the host was asked to price a stay that was already theirs. Fixed `4a88a61`: `submitOffer` now measures the dates with the booking guard's own yardstick before it prices anything — an occupying booking overlapping the half-open stay, or a host block on any of its nights, refuses with a 409 that says what is true (the guest's own booking / somebody else's / the host's block). Pinned: `anOfferNeedsNightsThatCanBeBooked.test.js` (8 assertions, including the half-open check-out day and the inclusive block).

## Defect 12 — a zero-night offer, and the booking gate's stay rules half switched off (High, backend)

Two findings, one fix (`bdab3b1`). **(a)** The offer endpoint took a 20→20 Sep "stay" — zero nights — on 29302, which asks for two nights and six hours' notice (offer 228, pending); the booking gate had every one of those checks and the offer path never called them. An offer is a request for a stay, so it is now held to `stayRefusal()`: at least a night, inside the arrival window, in season, within the host's minimum and maximum. **(b)** The booking gate's own checks were only half alive: `c2dd020` (9 Sep) wired `checkInAllowed` and `stayFitsSeason` into `createBooking` but fed them a rules row SELECTed for four other columns, so `pbr_minimum_notice_hours`, `pbr_max_advance_days`, `pbr_same_day_booking` and `pbr_open_months` arrived as `undefined` and each rule answered "no rule" — the calendar greyed the day, the API took the booking (the inert-SELECT trap, eleven days). The columns the helpers read are now one exported list, `RULE_COLUMNS`, spread into that SELECT; the test reads the helpers' source and fails if anything they touch is missing from it. Pinned: `theStayRulesBindOffersAndBookingsAlike.test.js` (10 assertions).

## Defect 13 — an ongoing stay was sent without its listing: cover, hours, pin (Medium, backend)

`/user/ongoing/bookings` queries with `raw: true, nest: true`, so the join comes back as `item.bookingProperty.property_id` — while the endpoint read the dotted key `item['bookingProperty.property_id']` in five places, and every one got `undefined`. The cover map, the stay window and the exact-location flag were built for a list of `[undefined]`: each ongoing stay went out with no picture, the platform's 2 PM / 11 AM in place of the host's hours (29291 checks in at 02:01 by the host's own answer; the review page said so, Next Booking said *2 PM*), and the pin withheld whatever the host chose. Since June. Fixed `4aab209` with one helper that reads either shape; the test lifts it out and runs it on the nested row. The 18 Sep location test is re-anchored on it.

## Defect 14 — "Currently Staying" and "Booking Confirmed" before the host approved (Medium, web)

B021812 was requested at 18:26 with an hour for the host to answer; at 18:45 the guest's Next Booking page read **Currently Staying**, the timeline's first step said *Booking Confirmed — Your booking has been confirmed*, and a **Check out** button was offered — on a stay nobody had approved, let alone checked in. `lifecycleLabel` already refuses to call such a row *Staying now*; the `currentlyStaying` flag, computed from the clock alone, drove the badge, the timeline and the button on its own — the same fault the function's own note describes, one layer up. Fixed `32fb9c1`: the ongoing row says `awaitingApproval` by the same rule, `currentlyStaying` is false while it does, and the first timeline step reads *Awaiting host approval* until the host answers. The payment page's *"The host has 1 hours to approve"* goes through `answerWindowLabel` in the same commit. Pinned: `aRequestIsNotAStay.test.mjs`.

## Defect 15 — two offers from one click (Medium, backend, race)

Three identical submits fired in the same instant for 29306 produced two pending offers (230 and 231) and refused only the third. `claimNextRound` locked the guest's existing offer rows `FOR UPDATE` — nothing, for a guest with none — and **committed before `submitOffer` inserted**, so both requests read "no offer waiting" and both wrote. Fixed `62e652f`: the claim takes the listing's row (`tbl_properties … FOR UPDATE`, the row `createBooking` already serialises on) and hands its transaction back open; every offer row is written inside it and committed once the rows are in, before coupons, mail and sockets. The second request waits on the row until the first has written, then sees it. Pinned: `theOfferClaimHoldsItsLock.test.js`, which drives the claim against a fake that behaves like InnoDB for that one statement; the 16 Sep claim test is re-anchored on the open transaction.

## Spec conflicts — the case sheet is behind the product

Neither of these is a defect. Both describe behaviour the client **changed after the document was written**, and they are recorded so the document can be corrected rather than the code.

**NG-007 — "offer between min and ideal → sent to host".** The engine instead answers instantly with a counter at the host's target. That is the "instant counter" the client signed off: it fires on **round one only**, and a guest who counters the counter is escalated to a person. The case describes the design before that feature existed.

**NG-008 — "offer below minimum → reaches host marked below minimum".** The engine counters this too, at ₹1,750, flagging `belowFloor: true` internally. Also deliberate: *"an offer under the floor is countered too, not refused (client, 2026-09-09)"* — the floor is an internal number the guest was never shown, so the counter answers rather than refuses.

> **Both should be re-worded in the case document**, or the client should tell us the engine is wrong. Worth noting that NG-008's counter at ₹1,750 sits **above** the ideal of ₹1,700 — which is exactly the counter-pricing question already put to the client in `AAJOO_NEGOTIATION_DECISIONS_2026-09-17.pdf`.

---

## Fixes made in this run

| Commit | What |
|---|---|
| `0e6d863` | Festival/season periods: wizard refuses a half-filled period by name; engine honours an existing start-only row for its start date. Accepted counter-backs now reach `tbl_negotiation_log`. 11 new assertions; 150/150 |
| `656f6df` | `getProperty` strips the min/ideal tier grid for non-owners; `/properties/search` stops selecting `property_contact`; `tests/theHostsFloorIsNotPublic.test.js` adds 5 assertions pinning both doors, including that the host still sees their own figures. 148/148 backend tests pass |
| `0d0afed` · web `9886e06` · app `f0ff3ba` | Defects 6–8 (batch 3): per-type capacity on all three surfaces; the app reads the wizard's stay hours; every bedroom listed |
| `0008c3e` + `a7a5929` | Defect 9: the host hears a guest counter once — and still gets the live event |
| `54b13c8` | Defect 10: `dealPercent()` settles the fraction before the ceiling |
| `4a88a61` | Defect 11: `datesUnavailableRefusal` — an offer on nights nobody can book is refused at the door |
| `bdab3b1` | Defect 12: `stayRefusal` + `RULE_COLUMNS` — the host's stay rules bind offers, and the booking gate reads all of them again |
| `4aab209` | Defect 13: `/user/ongoing/bookings` reads its listing id from the nested join — cover, hours, pin |
| web `32fb9c1` | Defect 14: a request the host has not answered is not a stay in progress; "1 hour", not "1 hours" |
| `62e652f` | Defect 15: the offer claim holds the listing's row lock across the insert. Backend 164/164; web 30/30 + `tsc -b` + build |

---

## What is needed to unblock the rest

1. **A guest test account we own, with a password held by the client**, so booking, payment and negotiation cases can be driven without touching accounts 101/100. Roughly **120 of the 300** cases create data and need this. *(20 Sep: the account exists — guest 179 "Renter test web"; what is needed is a person signing it in on Chrome and on the emulator, because a session never types a password. On 20 Sep Chrome held host 100 and the emulator held guest 101.)*
2. **A host test account on the same basis**, for the 100 HL listing cases. *(20 Sep: host 194 or 177 "Host Mobile", same condition.)*
3. **A test payment method** for the BK payment cases (BK-038…BK-049).
4. Confirmation that the **dev environment** is the right target, and that test bookings there are acceptable.

---

## The ten batches

Thirty cases each, grouped by **what unblocks them** and ordered so the earliest batches need the least. Every one of the 300 is in exactly one batch (validated by script).

| Batch | Theme | Needs from the client | Cases | Critical |
|---|---|---|---|---|
| **1** | Booking — public page and pricing maths | **Nothing** — **COMPLETE** | 30 | 8 |
| **2** | Negotiation — privacy and engine; backend price rules | **Nothing** — **COMPLETE** | 30 | 10 |
| 3 | Security, ownership, rejected input | Guest + host tokens (creates nothing) | 30 | 9 |
| 4 | Booking — create, confirm, availability, post-stay | Guest account | 30 | 3 |
| 5 | Payment, cancellation, refunds, double-booking | Guest + **test payment method** + 2nd guest | 30 | 8 |
| 6 | Negotiation — guest side | Guest account | 30 | 0 |
| 7 | Negotiation — host side, timing, bot, cross-flow | Host + guest; BotPenguin | 30 | 2 |
| 8 | Host listing — steps 1–2, location, capacity | Host account | 30 | 0 |
| 9 | Host listing — type fields, amenities, photos | Host account + sample photos | 30 | 0 |
| 10 | Host listing — pricing, publish, drafts | Host account + admin | 30 | 4 |

### Batch 1 — Booking — public page and the pricing maths
**Needs:** Nothing. Public API, database reads, Chrome on public pages.  
**Cases:** 30 · Critical: 7 · Already run: 7

| ID | Pri | Case | Status |
|---|---|---|---|
| BK-001 | High | Open a property page |  |
| BK-002 | High | Date picker opens |  |
| BK-003 | High | Guest selector |  |
| BK-004 | High | Price shows per night |  |
| BK-005 | High | Price breakdown visible |  |
| BK-006 | High | Book Now button visible |  |
| BK-007 | Med | Mobile layout |  |
| BK-008 | Med | Image gallery swipes |  |
| BK-009 | Med | Map shows location |  |
| BK-010 | Med | Loading state |  |
| BK-011 | Critical | Book 1 night | PASS |
| BK-012 | Critical | Book multiple nights | PASS |
| BK-013 | Critical | Book a weekly stay | PASS |
| BK-014 | Critical | Book a monthly stay | FAIL |
| BK-015 | High | Mixed period (12 nights) |  |
| BK-016 | High | Weekend pricing applies |  |
| BK-017 | High | Seasonal rate applies |  |
| BK-018 | High | Long-stay discount |  |
| BK-019 | Med | Cleaning fee added |  |
| BK-020 | Med | Extra-guest fee |  |
| BK-021 | Critical | Charge = quote | PASS |
| BK-047 | Med | No deposit on nightly |  |
| BK-080 | Critical | Min/ideal price hidden | FAIL→fixed |
| BK-081 | Critical | No bank/KYC leak | FAIL→fixed |
| BK-084 | Med | Rate limiting |  |
| BK-090 | Med | Book across a season boundary |  |
| BK-091 | Low | Leap/odd month monthly |  |
| BK-092 | Med | Very long stay |  |
| BK-095 | Med | Currency rounding |  |
| BK-098 | Med | Timezone on dates |  |

### Batch 2 — Negotiation — privacy and the engine, plus backend price rules
**Needs:** Nothing. Public API, the pure engine, database reads.  
**Cases:** 30 · Critical: 11 · Already run: 4

| ID | Pri | Case | Status |
|---|---|---|---|
| NG-001 | Critical | Guest never sees minimum |  |
| NG-002 | Critical | Guest never sees ideal |  |
| NG-003 | Critical | Min/ideal not in API | FAIL→fixed |
| NG-004 | Critical | Counter reveals no floor |  |
| NG-005 | High | Displayed price is ceiling |  |
| NG-006 | Critical | Offer ≥ ideal auto-accepts | PASS |
| NG-007 | Critical | Offer between min & ideal → host | SPEC |
| NG-008 | Critical | Offer below minimum → host flagged | SPEC |
| NG-009 | High | Offer above displayed rejected |  |
| NG-012 | Critical | Min ≤ ideal ≤ displayed enforced |  |
| NG-013 | High | Nightly negotiation |  |
| NG-014 | High | Weekly negotiation |  |
| NG-052 | High | Every offer logged |  |
| NG-053 | High | Log has outcome |  |
| NG-054 | Med | Log has no leak |  |
| NG-055 | High | Offer status transitions valid |  |
| NG-064 | High | Offer exactly = ideal |  |
| NG-065 | High | Offer exactly = minimum |  |
| NG-066 | Med | Offer exactly = displayed |  |
| NG-067 | Med | Offer 1 rupee below ideal |  |
| NG-068 | Med | Offer 1 rupee below min |  |
| NG-069 | Low | Decimal offer |  |
| NG-070 | Med | Very low offer |  |
| NG-085 | Med | Min=ideal=displayed |  |
| NG-086 | Low | Ideal just below displayed |  |
| NG-087 | Low | Very high displayed price |  |
| HL-060 | High | Backend enforces min |  |
| HL-066 | Critical | min ≤ ideal ≤ displayed |  |
| HL-067 | Critical | min > ideal rejected |  |
| HL-087 | Critical | Backend re-validates publish |  |

### Batch 3 — Security, ownership and rejected input
**Needs:** A guest account and a host account we own (tokens only — these tests get REFUSED, they create nothing).  
**Cases:** 30 · Critical: 8 · Already run: 30 (20 PASS · 2 INFO · 8 BLOCKED)

| ID | Pri | Case | Status |
|---|---|---|---|
| BK-026 | High | No dates selected | PASS (20 Sep) |
| BK-027 | High | Check-out before check-in | PASS (20 Sep) |
| BK-028 | High | Past date | PASS (20 Sep) |
| BK-029 | Med | Zero guests | PASS (20 Sep) |
| BK-030 | High | Guests over capacity | PASS · Defect 6 fixed (20 Sep) |
| BK-031 | High | Below min stay | PASS (20 Sep) |
| BK-032 | Med | Above max stay | PASS (20 Sep) |
| BK-033 | High | Book without login | PASS (20 Sep) |
| BK-034 | Critical | Book without KYC | BLOCKED — needs an unverified guest |
| BK-035 | Critical | Empty guest details | INFO — see batch 3 notes |
| BK-036 | Med | Invalid phone | PASS (20 Sep) |
| BK-037 | Med | Invalid email | PASS · note (20 Sep) |
| BK-079 | Critical | See only own bookings | PASS (20 Sep) |
| BK-082 | Critical | Tampered price rejected | PASS (20 Sep) |
| BK-083 | High | Auth required | PASS (20 Sep) |
| NG-039 | High | Zero offer | PASS (20 Sep) |
| NG-040 | High | Negative offer | PASS (20 Sep) |
| NG-041 | Med | Non-numeric offer | PASS (20 Sep) |
| NG-042 | High | Offer on fixed-price listing | BLOCKED — no live listing with negotiation off |
| NG-043 | High | Offer without login | PASS (20 Sep) |
| NG-090 | Med | Screenshot/replay attack | PASS (20 Sep) |
| NG-091 | Critical | Tampered offer price | PASS (20 Sep) |
| NG-094 | Med | Offer with expired session | PASS by test (20 Sep) |
| NG-096 | Med | Guest offers on own listing | BLOCKED — needs host sign-in |
| HL-077 | High | Identity linked | BLOCKED — needs host sign-in |
| HL-079 | Critical | Bank details save | BLOCKED — needs host sign-in |
| HL-080 | High | Bank shown last-4 | BLOCKED — needs host sign-in |
| HL-098 | Critical | Host edits own only | BLOCKED — needs host sign-in |
| HL-099 | Critical | Host sees own listings only | BLOCKED — needs host sign-in |
| HL-100 | High | Docs access-controlled | BLOCKED — needs host sign-in |

### Batch 4 — Booking — create, confirm, availability, after the stay (14 of 30 run on 20 Sep, on the batch-6 loop)
**Needs:** The guest account. Creates real test bookings on dev.  
**Cases:** 30 · Critical: 3 · Already run: 0

| ID | Pri | Case | Status |
|---|---|---|---|
| BK-022 | Critical | Confirmation created | PASS (20 Sep, B021812) |
| BK-023 | High | Confirmation email/app |  |
| BK-024 | High | Host notified |  |
| BK-025 | High | Booking ID generated | PASS (20 Sep) |
| BK-048 | Med | Currency correct | PASS (20 Sep) |
| BK-049 | Med | Tax shown | PASS (20 Sep) |
| BK-054 | High | Blocked dates unbookable | PASS (20 Sep) |
| BK-055 | High | Availability calendar accurate | PASS (20 Sep) |
| BK-056 | Med | Booking horizon |  |
| BK-057 | Med | Minimum notice | FAIL → fixed bdab3b1 (Defect 12) |
| BK-058 | Med | Same-day conflict |  |
| BK-071 | High | My Bookings list |  |
| BK-072 | High | Booking detail accurate |  |
| BK-073 | Med | Ongoing stay shown | PASS after fix 32fb9c1 (Defect 14) |
| BK-074 | High | Invoice download |  |
| BK-075 | Med | Modify booking |  |
| BK-076 | High | Check-in details | FAIL → fixed 4aab209 (Defect 13) |
| BK-077 | Med | Host contact revealed | PASS (20 Sep) |
| BK-078 | Med | Review after stay | PASS (20 Sep) |
| BK-085 | Critical | Negotiated price used | PASS (20 Sep) |
| BK-086 | Critical | Auto-accept → booking |  |
| BK-087 | Med | Guest count feeds capacity |  |
| BK-088 | High | Price change reflects |  |
| BK-089 | High | Deposit single-source |  |
| BK-093 | High | Instant vs approval | PASS (20 Sep) |
| BK-094 | Med | Approval timeout |  |
| BK-096 | Med | Coupon applied | PASS (20 Sep) |
| BK-097 | Med | Invalid coupon |  |
| BK-099 | Med | Back button mid-booking |  |
| BK-100 | High | Refresh mid-payment |  |

### Batch 5 — Payment, cancellation, refunds, double-booking
**Needs:** The guest account + a TEST payment method + a second guest account for the concurrency cases.  
**Cases:** 30 · Critical: 11 · Already run: 0

| ID | Pri | Case | Status |
|---|---|---|---|
| BK-038 | Critical | Successful payment |  |
| BK-039 | Critical | Failed payment |  |
| BK-040 | High | Cancelled payment |  |
| BK-041 | High | Payment timeout |  |
| BK-042 | Critical | Double-click Pay |  |
| BK-043 | Critical | Network drop during pay |  |
| BK-044 | High | Webhook confirms booking |  |
| BK-045 | High | Webhook arrives twice |  |
| BK-046 | High | Deposit on monthly |  |
| BK-050 | Critical | Double-booking prevented |  |
| BK-051 | Critical | Availability re-check at confirm |  |
| BK-052 | High | Overlapping dates |  |
| BK-053 | High | Same-day double |  |
| BK-059 | High | View cancellation policy |  |
| BK-060 | Critical | Cancel booking |  |
| BK-061 | Critical | Refund = policy |  |
| BK-062 | High | Cancel with OTP |  |
| BK-063 | High | Full refund window |  |
| BK-064 | High | Partial refund window |  |
| BK-065 | High | No refund window |  |
| BK-066 | High | Refund status visible |  |
| BK-067 | High | Deposit refunded |  |
| BK-068 | High | Host cancels |  |
| BK-069 | Critical | Policy version locked |  |
| BK-070 | Med | Refund to original method |  |
| NG-010 | Critical | Accept creates booking |  |
| NG-011 | Critical | Accepted price is charged |  |
| NG-047 | High | Payment timeout after accept |  |
| NG-059 | High | Negotiated booking in My Bookings |  |
| NG-098 | High | Refund on negotiated booking |  |

### Batch 6 — Negotiation — the guest side
**Needs:** The guest account. Creates real test offers on dev.  
**Cases:** 30 · Critical: 0 · Already run: 26 (17 PASS · 5 FAIL, 4 fixed same day · 3 INFO · 1 BLOCKED) — 20 Sep

| ID | Pri | Case | Status |
|---|---|---|---|
| NG-016 | High | Make an Offer button | PASS (20 Sep) |
| NG-017 | High | Offer input validates | PASS (20 Sep) |
| NG-018 | High | Offer confirmation | PASS (20 Sep) |
| NG-019 | High | Offer status visible | PASS (20 Sep) |
| NG-020 | High | Counter shown to guest | PASS (20 Sep) |
| NG-022 | High | Real-time update | PASS web · FAIL app (20 Sep) → build 107 |
| NG-023 | Med | Offer thread readable | PASS (20 Sep) |
| NG-024 | Med | Mobile negotiation UI | PASS host side (20 Sep) · guest side pending |
| NG-025 | Med | Waiting state | PASS (20 Sep) |
| NG-034 | High | Guest counters back | PASS (20 Sep) |
| NG-035 | Med | Multiple rounds | PASS (20 Sep) |
| NG-036 | High | Guest accepts counter | PASS (20 Sep) |
| NG-037 | Med | Guest declines counter | PASS (20 Sep) |
| NG-038 | Low | Round limit | INFO — no cap by client decision |
| NG-044 | Med | Offer on unavailable dates | FAIL → fixed 4a88a61 (Defect 11) |
| NG-045 | Low | Offer after booking | FAIL → fixed 4a88a61 (Defect 11) |
| NG-046 | High | Offer expiry | pending — offer 230 left to expire |
| NG-071 | Med | Rapid repeat offers | FAIL → fixed 62e652f (Defect 15) |
| NG-072 | Low | Offer then cancel | INFO — no withdraw; offers expire |
| NG-073 | Low | Guest edits offer before submit | PASS (20 Sep) |
| NG-075 | Med | Negotiate weekly then book nightly | PASS by the date lock (20 Sep) |
| NG-076 | Low | Offer on LUXE listing |  |
| NG-078 | Med | Offer notification failure | INFO — pinned by test |
| NG-079 | Low | Currency in offer | PASS (20 Sep) |
| NG-080 | Med | Session lost mid-negotiation | BLOCKED (needs a sign-in) |
| NG-081 | Med | Accept exactly at expiry |  |
| NG-082 | Low | Guest offers after decline | PASS (20 Sep) |
| NG-088 | Low | Offer history after booking | PASS (20 Sep) |
| NG-089 | Med | Language in negotiation |  |
| NG-092 | Med | Offer for 0 nights | FAIL → fixed bdab3b1 (Defect 12) |

### Batch 7 — Negotiation — the host side, timing, bot, cross-flow (4 of 30 run on 20 Sep, on the host's emulator)
**Needs:** Host account + guest account together; BotPenguin for NG-056..058.  
**Cases:** 30 · Critical: 3 · Already run: 0

| ID | Pri | Case | Status |
|---|---|---|---|
| NG-015 | High | Monthly negotiation |  |
| NG-021 | High | Accept/decline buttons (host) | PASS (20 Sep, app) |
| NG-026 | High | Host notified of offer | PASS (20 Sep) — Defect 9 beside it |
| NG-027 | High | Host notified of auto-accept |  |
| NG-028 | Critical | Host accepts |  |
| NG-029 | High | Host counters | PASS (20 Sep, app) |
| NG-030 | High | Host declines |  |
| NG-031 | Med | Host ignores → expiry |  |
| NG-032 | High | Host sees offer amount | PASS (20 Sep, app) |
| NG-033 | Med | Host response-time honoured |  |
| NG-048 | Critical | Two offers same unit |  |
| NG-049 | High | Host accepts after unit booked |  |
| NG-050 | Med | Concurrent counters |  |
| NG-051 | Med | Offer during price change |  |
| NG-056 | High | Negotiate via chatbot |  |
| NG-057 | Critical | Bot shows no floor |  |
| NG-058 | High | Bot offer → host |  |
| NG-060 | High | Host earnings reflect negotiated |  |
| NG-061 | High | Commission on negotiated price |  |
| NG-062 | High | Fixed-price toggle works |  |
| NG-063 | High | Turn negotiation on |  |
| NG-074 | Med | Host counters above displayed |  |
| NG-077 | Med | Two-role user offers |  |
| NG-083 | Med | Host bulk offers |  |
| NG-084 | Low | Offer on paused listing |  |
| NG-093 | High | Simultaneous accept + guest cancel |  |
| NG-095 | Med | Host declines then guest re-offers higher |  |
| NG-097 | High | Offer notification to right host |  |
| NG-099 | Low | Negotiation analytics captured |  |
| NG-100 | Low | Offer amount localization |  |

### Batch 8 — Host listing — steps 1 and 2, location, capacity
**Needs:** The host account.  
**Cases:** 30 · Critical: 0 · Already run: 0

| ID | Pri | Case | Status |
|---|---|---|---|
| HL-001 | High | Owner vs Manager |  |
| HL-002 | High | Property type cards |  |
| HL-003 | High | Booking unit |  |
| HL-004 | Med | LUXE toggle |  |
| HL-005 | High | Property name valid |  |
| HL-006 | Med | Name too short |  |
| HL-007 | Med | Name too long |  |
| HL-008 | High | Name special chars |  |
| HL-009 | High | Description min length |  |
| HL-010 | Med | Description too short |  |
| HL-011 | Low | Description counter |  |
| HL-012 | Med | AI help write |  |
| HL-013 | High | Address search |  |
| HL-014 | High | Map pin drop |  |
| HL-015 | Med | Address-pin mismatch |  |
| HL-016 | Med | PIN validation |  |
| HL-017 | Med | State-city relationship |  |
| HL-018 | High | Show exact location toggle |  |
| HL-019 | Med | Nearby places auto-suggest |  |
| HL-020 | Med | Nearby by type not name |  |
| HL-021 | Low | Manual place add |  |
| HL-022 | Low | Duplicate place dedupe |  |
| HL-023 | Low | Closed business excluded |  |
| HL-024 | High | Adults stepper |  |
| HL-025 | High | Total auto-calculated |  |
| HL-026 | Med | Infants separate |  |
| HL-027 | High | Bedrooms/beds/baths |  |
| HL-028 | Med | Bed types |  |
| HL-029 | Low | Zero bedrooms (studio) |  |
| HL-030 | High | Apartment fields |  |

### Batch 9 — Host listing — type fields, amenities, photos
**Needs:** The host account + a few sample photos.  
**Cases:** 30 · Critical: 0 · Already run: 0

| ID | Pri | Case | Status |
|---|---|---|---|
| HL-031 | Med | Camping fields |  |
| HL-032 | Med | PG fields |  |
| HL-033 | Low | Farm stay fields |  |
| HL-034 | High | Type change warns |  |
| HL-035 | Med | Cross-validate BHK |  |
| HL-036 | Med | Parking None hides spaces |  |
| HL-037 | Low | Parking shows spaces |  |
| HL-038 | Low | Construction year |  |
| HL-039 | Low | Future year rejected |  |
| HL-040 | Low | Area + unit |  |
| HL-041 | Med | Negative area rejected |  |
| HL-042 | Med | Amenity chips |  |
| HL-043 | Med | Amenity search |  |
| HL-044 | Med | Pool sub-questions |  |
| HL-045 | Med | Pet policy sub |  |
| HL-046 | Med | Wheelchair cross-check |  |
| HL-047 | Med | Internet speed band |  |
| HL-048 | Low | Highlights max 5 |  |
| HL-049 | Low | Smart lock → self check-in |  |
| HL-050 | High | Upload photos |  |
| HL-051 | High | Minimum photos |  |
| HL-052 | Med | Tiered minimum |  |
| HL-053 | High | Required tags |  |
| HL-054 | Med | First = cover |  |
| HL-055 | Low | Reorder photos |  |
| HL-056 | Low | Delete photo |  |
| HL-057 | High | Invalid file type |  |
| HL-058 | Med | Oversized file |  |
| HL-059 | Med | Upload fails |  |
| HL-061 | High | Set nightly price |  |

### Batch 10 — Host listing — pricing, publish, drafts
**Needs:** The host account + admin access for the publish/reject cases.  
**Cases:** 30 · Critical: 1 · Already run: 0

| ID | Pri | Case | Status |
|---|---|---|---|
| HL-062 | Med | Price out of range |  |
| HL-063 | Med | Weekly price |  |
| HL-064 | Med | Monthly price |  |
| HL-065 | Critical | Set min & ideal |  |
| HL-068 | High | Guests-never-see note |  |
| HL-069 | High | Deposit single field |  |
| HL-070 | Med | Cleaning fee frequency |  |
| HL-071 | High | Negotiation toggle |  |
| HL-072 | High | Cancellation policy |  |
| HL-073 | Med | Check-in default sensible |  |
| HL-074 | Med | Same-day vs notice conflict |  |
| HL-075 | Med | Min ≤ max stay |  |
| HL-076 | High | Readiness computed |  |
| HL-078 | High | Ownership doc upload |  |
| HL-081 | Med | Emergency contact |  |
| HL-082 | Low | Caretaker conditional |  |
| HL-083 | Med | Compliance questions |  |
| HL-084 | High | Declarations required |  |
| HL-085 | Med | Host Agreement scroll |  |
| HL-086 | High | Agreement acceptance stored |  |
| HL-088 | High | Publish state machine |  |
| HL-089 | Med | Rejected → resubmit |  |
| HL-090 | High | Autosave draft |  |
| HL-091 | Med | Save only on backend confirm |  |
| HL-092 | Med | Save fails message |  |
| HL-093 | High | Resume draft |  |
| HL-094 | High | Back navigation keeps data |  |
| HL-095 | High | Edit published listing |  |
| HL-096 | High | Edit preserves untouched |  |
| HL-097 | High | Double-submit protection |  |
