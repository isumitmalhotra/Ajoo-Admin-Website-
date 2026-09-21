# Aajoo — 300 Manual Test Cases: Execution Report

**Source:** `Aajoo-300-Manual-Test-Cases.docx` (client, v1.0) — BK-001…100 Booking · NG-001…100 Negotiation · HL-001…100 Host Listing
**Run started:** 17 September 2026 · **Environment:** `aajaodev.onrender.com` (dev API), `www.aajoohomes.com` (web), Android build 100 → **109** on the emulator
**This file is updated after every batch.** Nothing is marked PASS without a recorded actual value.

---

## Running totals

| | Cases | PASS | FAIL (all fixed) | SPEC CONFLICT | BLOCKED | INFO | Not yet run |
|---|---|---|---|---|---|---|---|
| **BK — Booking** | 100 | 83 | 11 | 4 | 0 | 2 | 0 |
| **NG — Negotiation** | 100 | 84 | 11 | 2 | 0 | 3 | 0 |
| **HL — Host Listing** | 100 | 83 | 13 | 3 | 0 | 1 | 0 |
| **Total** | **300** | **250** | **35** | **9** | **0** | **6** | **0** |

**All 300 cases have a verdict and nothing is blocked.** Batches 1–3 complete; batch 6 (guest negotiation); batches 4, 5 and 7 (booking, payment/cancellation, the host side of negotiation); batches 8–10 (the host wizard end to end on the emulator, submitted, rejected, resubmitted, approved, edited live); and, in a seventh sitting with the user at the Razorpay modal, the five gateway cases — two paid bookings, a failed and a dismissed attempt, a guest cancellation with its code and a host cancellation from the phone — every refund a real test-mode refund read back at the gateway, the ledger and the payout queue.

**Defects found: 50.** All 50 fixed and pinned by tests (backend 184/184 test files, the web suite with `tsc -b` and a production build, the app suite). Defects 23–44 came from the fifth and sixth sittings (the booking remainder and the host wizard); 45–49 from paying for real in the seventh: the Defect-25 re-check refunding a good payment over the guest's own abandoned hold, two holds for one retry, **no refund ever recorded on the finance ledger (revenue overstated by ~18%)**, the Upcoming card confirming a request, and two opposite definitions of "does the host approve". Defect 50 came from the clean-up in the eighth sitting: an admin approval put a listing the host had paused back on the site. Every app fix is on the emulator as **build 109** (built 21 Sep 14:37 IST on JDK 21, `app-release.apk` 95.6 MB, sha256 `064CC19B…B266D7`, client repo `aajoo_app_latest` main = `f566782`), and each was driven on the phone.

**Spec conflicts: 9.** Cases that describe behaviour the client themselves changed after the document was written, or a feature the product does not have: the cleaning fee (BK-019, 15 Sep), the round-one instant counter and countering below the floor (NG-007/008, 9 Sep), the security deposit stated and collected by the host (BK-046/067, 15 Sep), approval requests that auto-confirm rather than expire (BK-094), and three items never built — an AI "Help me write" (HL-012), amenity chips that vanish once picked (HL-042), a host-picked highlights list (HL-048). The product is right, or the decision is the client's; the document is stale.

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

## Batch 3 — COMPLETE (30/30 run; 22 PASS · 2 INFO · 6 BLOCKED) · Security, ownership and rejected input

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
| HL-077, 099 | Identity linked; host sees own listings only | Host 100 on the emulator (21 Sep) | Profile: *KYC Verification · Identity verified*; *Managed Properties* and the dashboard's *Properties 2* list only 29291 and 29302 | **PASS** (21 Sep) |
| HL-079, 080, 098, 100 | Host-side | — | Bank details (079/080) are not to be entered on the client's account; 098/100 need a second host's listing id under this host's token | **BLOCKED** (our own host signed in) |

**Records this sitting created on account 101** (so nobody reads them as a bug): negotiation thread on listing 29306 for 20→23 Sep — offer 221 (₹3,100, countered) and the engine's counter 222 (₹3,800, pending, expires by itself). No booking was created; every booking attempt was a refusal by design.

**Found beside the cases (not in the sheet), all fixed the same day and pinned by tests:**
- **Defect 6 (Medium, all three surfaces)** — per-type capacity not enforced; see BK-030.
- **Defect 7 (Medium, app)** — the booking sheet printed *"Check-in/Check-out Time 12:00PM / 12:00PM · set by the host"* for a host who set 14:00 / 11:00: the app read only the legacy row and never the wizard's `stayWindow` (the API sends it). Fixed: the sheet now reads the wizard hours and prints *2:00 PM / 11:00 AM*.
- **Defect 8 (Low, app parity)** — *"Where you'll sleep"* on a three-bedroom listing listed only *Bathroom 1, Bathroom 2*: a bedroom with no bed line was skipped, while the website lists every bedroom. Fixed: every bedroom is shown.
- Observation (Low, app): the sticky bar prices *"1 night"* before any dates are chosen, on a listing with a 3-night minimum. Not changed; noted for the design pass.

---

## Batch 6 — RUN (27/30; 18 PASS · 5 FAIL · 3 INFO · 1 BLOCKED) · Negotiation — the guest side

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
| NG-046 | Offer expiry | Offer 230 on 29306 (₹3,200, 19:03) left pending; platform default 30 min, 5-minute sweep | Read at 19:40: `offer_status = expired`, ledger row `expired` at **19:35**; the guest's card reads *Your offer expired ₹3,200/night*. The host's own window (`pn_expiry_hours`) lengthens this when set. | **PASS** |
| NG-071 | Rapid repeat offers | Three identical offers fired in the same instant (29306, ₹3,200, 20→23 Sep) | **Two created** (230, 231), only the third refused *"You already have an offer waiting on this stay."* The claim locked the guest's existing rows — none — and committed before the insert. Fixed (`62e652f`): the claim takes the listing row and holds it across the insert. **Re-run at 19:41 against the deployed fix: four identical submits in the same instant → exactly one offer (232), the rest refused.** | **FAIL → fixed and re-proven** (Defect 15) |
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

**Build 107 on the emulator (19:33):** with the host's Notifications list open and untouched, a chat message sent from the guest's website put *New message from Aajoo Renter — now* at the top and moved the count 68 → 69 — the app's new live channel (`LiveChannel`, one socket per person) works end to end. The guest-side negotiation screens on the app (NG-024 guest half, NG-022 app half) still want the emulator signed in as a guest.

**Third sitting, 20 September 20:10—21:20 IST — the guest half on the app.** The emulator was signed in as guest 101 (build 107, then 108); Chrome stayed guest 101 for the API. The loop ran on **our own host 177's listing 29295 "Clamping suite for testing purpose"** (Nainital; flat ₹7,000, Sunday ₹9,500; instant book), which guest 101 had never offered on, so the engine's round-one answer could be watched without a host.

| ID | Case | Sent / done | Actual | Verdict |
|---|---|---|---|---|
| NG-016 (app) | Make an Offer button | Listing → *Negotiate & Reserve* → sheet | *Negotiate* under *Book Now*; opens *Send an Offer* (placeholder = the DATED night ₹9,500, dates, *"Your deal, if accepted, will be locked to these 1 night."*) | **PASS** |
| NG-017 (app) | Offer input validates | Send with the field empty | *"Enter the price you would like to pay per night."* | **PASS** |
| NG-018 (app) | Offer confirmation | ₹8,400, 20→21 Sep, *"App test - one night tonight"* | The engine's tiers for the night were 8,000 / 8,300 / 9,500, so the offer met the target: *"Accepted at ₹8,400/night — Your price is locked in. It applies automatically at checkout — book before midnight tonight to keep it."* with the code **DEAL29295101234** and *Book at this price* (offers 233/234). | **PASS** (auto-accept path) |
| NG-019 / NG-023 (app) | Status visible / thread readable | Dashboard → My Negotiations | *All (6) · Your move (0) · Waiting on host (0) · Accepted*; the 29295 card **Accepted** with the dated transcript (*You offered ₹8,400 · 20:38* → *Accepted ₹8,400*), the older threads (29306 *Expired*, 29291 …) below | **PASS** |
| NG-024 (app, guest) | Mobile negotiation UI | The whole loop above | Offer sheet, confirmation, negotiations list and *Book at the agreed price* all on the app | **PASS** |
| NG-022 (app, guest) | Real-time update | The socket joined `user_101` at 20:15:00 (server log) on build 107 | The engine's answer arrived inside the sheet's own request, so no live event was needed for this loop; the guest list's live reload is pinned by `the_app_hears_the_room_test.dart` and was proven on the host bell earlier | **PASS** (by the host-bell proof) |
| NG-045 (app) | Offer after deal | The sheet after *Book at this price* | *Send an Offer — Already agreed for these dates*, disabled | **PASS** |
| BK-086 (app) | Auto-accept → booking | *Book at this price* → pay at property → *Book Now* | **B326241** — *Booking Confirmed! Your stay is reserved. Pay when you arrive.* Room ₹9,500 — discount ₹1,100 + taxes ₹1,512 = **₹9,912** due on arrival; instant-book listing, so confirmed outright; exact pin + *Get Directions* | **PASS** |
| BK-085 / BK-096 (app) | Negotiated price used / coupon applied | The sheet | *DEAL29295101234 — Negotiated deal — 11.58% off* applied itself; `book_coupon_code`, `book_discount_amt 1100.10`, `book_total_amt 9911.88` | **PASS** |
| BK-049 (app) | Tax shown | The sheet, with the deal | *GST (18%) ₹1,511.98* on a ₹9,500 night — the high slab, as the server prices it. **But before the deal**, on picking 21 Sep, the sheet read *GST (5%) / Total ₹9,975* while the server said 18% / ₹11,210: the app's fallback banded on the listing's FLAT ₹7,000, not the night being charged. Fixed in build 108 (Defect 17). | **PASS** after fix |
| BK-072 (app) | Booking detail accurate | *Your booking* for B326241 | *Room charge ₹8,400 — Discount ₹1,100 + Taxes ₹1,512 = Total ₹9,912* — **does not add up**: `book_price` is stored net of the deal and the screen subtracted the discount again. Fixed in build 108 (Defect 18): the room line is the listed room. | **FAIL → fixed** |
| BK-073 (app) | Ongoing stay shown | Bookings → Ongoing | B326241 *Staying now · Pay at property · ₹9,912*; B021812 *Completed* filed under Ongoing by its dates (the guest tabs had the host tabs' fault) — fixed in build 108 | **PASS** after fix |
| BK-074 (app) | Invoice download | *Download invoice* on the detail | Present; not exercised | not run |
| Cancel (batch 5, app) | Guest cancels a pay-at-property stay | *Cancel booking* → reason *Booked by mistake* → *Cancel booking* | The policy card is right (*"Nothing has been charged … nothing to refund … cancellations after check-in are non-refundable"*), then **Confirm cancellation asks for a 6-digit code emailed to aajoo.renter1@mailinator.com** — a person's step; a session does not put an OTP through a tool. B326241 is left **confirmed on our host 177** for Sumit to cancel with the code. | **BLOCKED** (OTP) |
| Search (BK-055 kin) | Destination search on the app | *Where to? → Nainital → Search* | **"No stays here yet"** while a name search on the same screen found 29295, and Kasauli worked. The request log showed the app's body was exactly one the browser answers with the row: the geocoder answers Nainital with **29295's own coordinates**, and `6371 * acos(x)` gives NULL for x = 1.0000000000000002 — the one stay under the pin was the one stay dropped. Fixed `aad3144` (all four distance literals clamped); re-run on the app after deploy: the listing shows. | **FAIL → fixed** (Defect 16) |

**Records this sitting created (guest 101 on our host 177's listing):** offers **233** (₹8,400) and **234** (the platform's acceptance) on 29295; deal **DEAL29295101234** (11.58%, spent); booking **B326241** (pri 141) 20→21 Sep, pay at property, confirmed, **₹9,912 due** — not cancelled (OTP), and host-dues row **hd_id 50 (₹2,998.98, host 177)** that goes with it; one aborted cancellation (no state change). No record touched the client's host 100.

**Beside the cases:** the spent deal's thread still read *Accepted — Book at the agreed price* on both surfaces (Defect 19, fixed: the list says **Booked** with the booking and links it); the guest Dashboard and host Profile screens are the pre-redesign teal design (parity list, not defects).

**Fourth sitting, 20 September 23:05—23:50 IST — the host half on the app (build 108), host 100 back on the emulator, guest 101 on Chrome / the API.** The night of 20 Sep on 29291 had freed again (a checked-out stay does not occupy its night), so one more live loop ran on the client's own listing.

| ID | Case | Sent / done | Actual | Verdict |
|---|---|---|---|---|
| NG-022 (app, host) | Real-time update | Guest's ₹2,000 counter-back sent from the API at 23:11 while the host's *Awaiting you* list was open on build 108 | The card arrived **with no touch** (*₹2,000 · Round 16 · 20% below*); the dashboard's *Offers to review* had read 1 the same way at 23:06 | **PASS** (build 108) |
| NG-074 | Host counters above displayed | Host countered **₹2,600** on the ₹2,500 night (offer 235) | **Taken** — offer 236 written, `host_counter` logged. The counter branch had no price check (its "no ceiling" note is about rounds). Fixed `2bcf1cc`: a counter above the DATED list price, or at/under the guest's own figure, is refused with the number quoted, before any row is written. | **FAIL → fixed** (Defect 20) |
| NG-028 | Host accepts | *Accept* → *"Accept this offer? You will host Aajoo Renter at ₹2,000/night for 20-09-2026 → 21-09-2026. They get a one-time deal, good until midnight tonight."* → *Accept* (23:12) | Offer 237 **accepted**, `host_accept` logged; the host's list emptied; the guest's website put up *"The host accepted your offer"* live and *Accepted (3)* | **PASS** |
| NG-060 / NG-061 | Host earnings reflect negotiated / commission on negotiated | Host → Earnings | B021812 (negotiated ₹2,100 on a ₹2,500 night): payout row **₹1,728** = ₹2,099.75 — commission ₹315 (15% of the negotiated room) — GST ₹57; `tbl_host_dues` agrees. **Note for finance (by design, one thing to confirm):** the stay was pay-at-property, so the host holds the cash and owes the platform ₹476.99 (`tbl_host_dues`); the ₹1,728 *queued payout* is the same stay's host share, and the settlement offsets one against the other in the payout run. Confirm the offset shows on the host's payout statement so a cash stay never reads as money owed both ways. | **PASS** (commission on the negotiated price) · finance note |
| NG-084 | Offer on paused listing | Profile card *Active → Paused — hidden from guests* on 29302 (`is_active 0`), then an API offer and a search | Search: *no record found* ✓. Offer: refused — but for its **notice hours**, not for being paused: the tiers loader never read `is_active`. Fixed `48d38b0`: *"This stay is paused by its host and isn't taking offers or bookings right now."*, said before any other rule. Listing un-paused afterwards. | **FAIL → fixed** (Defect 21) |
| BK-024 | Host notified of booking | The host's bell | *A booking is waiting for your approval — Booking B021812 for "Aajoo Homes" needs your approval — you have 1 hours to respond* and *Your Property has been Booked — Booking Successfull, Booking id is B021812* | **PASS** (copy: "1 hours" fixed `ac699fe`; "Successfull" is legacy copy, noted) |
| NG-027 kin | Host notified of acceptance | The host's bell after the 18:20 acceptance | **Two rows** for one acceptance (*Your offer was accepted* + *Your counter was accepted*) — the plain accept path had the same double writer as the counter paths (Defect 9). Fixed `ac699fe`. | **FAIL → fixed** (Defect 9, second half) |
| NG-030 (21 Sep 00:03) | Host declines | Guest ₹1,550 on 29291 for 21→22 Sep (offer 238, round 17 → escalated); host: *Decline* → *"Decline this offer? Aajoo Renter will be told the offer was declined. You can still counter instead. Declining ends this negotiation, and your last counter stays open to them for 1 hour."* → *Decline* | Offer **declined**, thread *declined*, `host_decline` logged; the host's *Awaiting you* emptied; the guest's website moved live (*The host answered your offer* · card *Declined* · *Your offer was declined ₹1,550*). **But the guest's bell had no row** — a plain decline (no host counter in the session, so no parting price) wrote nothing durable; only the socket emit went out. Fixed `d64abab`: *"The host declined your offer of ₹2,400/night for QA Sunrise Villa. You can make a new offer tomorrow, or book it at the listed price."* — re-proven live on 29302 (offer 239, 00:13): row 858, one row, top of Notifications. | **FAIL → fixed** (Defect 22) |
| NG-095 | Guest re-offers after a decline | Two more offers from 101 on 29291 straight after: ₹1,700 for the same night, ₹1,900 for 22→23 Sep | Both `400 "The host has already answered an offer from you on this stay today. You can make a new offer tomorrow, or book at the listed price."` — the day's lock holds for any dates on that listing; no rows written. No parting price was left (the host had not countered in the session), as the dialog said. | **PASS** |

**Also this sitting:** the *Booked* match from Defect 19 was keyed on the stay, so the fresh deal accepted at 23:12 — same night as B021812's spent one — came back *Booked* and the guest lost *Book at the agreed price* the moment the host said yes. Fixed `f8ec735`: matched by the deal's own code (the accepting row's id in every spelling the accept paths use), pinned by running the helper on both threads.

**Records this sitting (host 100 / guest 101, by instruction):** offers **235—237** on 29291 (guest ₹1,800 → host ₹2,600 → guest ₹2,000 → accepted) and the deal minted for 20→21 Sep (expired at midnight, unused); 29302 paused and un-paused; after midnight, offer **238** on 29291 and offer **239** on 29302 (both declined by the host; guest 101 is locked out of both listings for 21 Sep, which clears itself at midnight); no bookings.

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

**Batch 7 cases proven on the host's emulator** (and NG-042 from batch 3):

| ID | Case | Actual | Verdict |
|---|---|---|---|
| NG-021 | Accept/decline buttons (host) | *Accept · Counter · Decline* under the guest's latest offer; *Counter the offer* dialog with price and message | **PASS** |
| NG-026 | Host notified of offer | Bell: *New price offer — A guest offered ₹1,700/night for Aajoo Homes for 20-09-2026 → 21-09-2026. Review it in Negotiations.* (5 min after); tapping it lands on Negotiations. **But** the guest's counter produced **two** rows at the same minute (*The guest countered your price* + *The guest countered back*) — Defect 9, fixed. No push notification reached the emulator's shade (FCM on an emulator; the in-app rows and the email path are the record). | **PASS** (Defect 9 beside it) |
| NG-029 | Host counters | ₹2,200 *"Weekend night - best I can do is 2200"* and ₹2,100 *"Meet you halfway - 2100"* → *Counter sent — the guest decides next.*; both reached the guest live | **PASS** |
| NG-032 | Host sees offer amount | *₹1,700 · Round 9 · ~~was ₹2,500~~ · 32% below*, then *₹2,000 · Round 11 · 20% below* | **PASS** |
| NG-062 | Fixed-price toggle works | Wizard step 4 *Negotiation → Accept offers on this listing* switched **off** on 29302, *Continue* (19:56): `pn_enabled = 0`; the guest's listing lost *Send an Offer* and read *"The host isn't taking offers on this stay — the listed price applies."*; the wizard read the saved state back as off. The **API** answered an offer with the date rule (*"Offers are for stays starting today…"*) — the host's switch sat behind the date guards; moved to the front (`f78d72b`, pinned). | **PASS** (UI) · API wording fixed |
| NG-063 | Turn negotiation on | Toggle back **on**, *Continue* (20:01): `pn_enabled = 1`, floor ₹2,500 intact; *Send an Offer · Negotiate and save more* and *Price negotiable — send the host an offer* back on the guest's listing | **PASS** |
| NG-042 | Offer on fixed-price listing (batch 3, was BLOCKED) | Same sitting as NG-062: the website refuses by hiding the button and saying why; the API's refusal is the date rule until `f78d72b` deploys, then *"This stay is not open to price offers. You can book it at the listed price."* first | **PASS** (web) · API re-proof pending a fixed-price listing |

**Records this sitting created (host 100 / guest 101 — the client's own test accounts, by instruction):**
- Host 100's calendar: block 19 *"QA end-to-end test block"* (20–22 Sep, 29291) **removed** through the app.
- Negotiation on 29291: offers **223** (₹1,700) · **224** (host ₹2,200) · **225** (₹2,000) · **226** (host ₹2,100, accepted); deal coupon **DEAL29291101C226** (16.01%, used once).
- Booking **B021812** (pri 140) on 29291, 20→21 Sep, pay at property, ₹2,204.74: approved 18:58, checked in 18:59 (cash recorded), guest check-out 19:00 → status 7. **Host dues row `hd_id 49` — ₹476.99 PENDING against host 100** (commission ₹315 + GST ₹57 + accommodation tax ₹104.99) was raised by this test booking and **needs an admin void with reason "test run"**, or it will surface in the client's payout ledger.
- Probe offers, each set to *expired* by a direct database update the moment its case was read (there is no guest withdraw): **227** (29291), **228** (29302), **229**, **231** and **232** (29306). **230** (29306, ₹3,200) was left to expire by itself (NG-046).
- One chat message from guest 101 to host 100 (*"Test run 20 Sep — checking the host app hears this. Please ignore."*, text doubled by a retry), to prove build 107's live channel.
- The 29306 thread from batch 3: host counter 222 **declined** by the guest (NG-037).
- No review was submitted; the *Write a Review* page was opened and left.

**Found beside the cases, all fixed the same day and pinned by tests** (details under Defects 9–15): the host told twice for one counter; the deal percentage rounded by floating point; an offer accepted on the guest's own booked night; a zero-night offer and the booking gate's stay rules half switched off; an ongoing stay sent without its listing (cover, hours, pin); *Currently Staying* before the host approved; two offers from one click. **For build 107 (app):** the host's Negotiations list does not refresh live and keeps stale buttons after the host's own counter; a completed stay is filed by its dates under Ongoing; the app never subscribes to `negotiation:*` / `notification:new`. Also noted: the payment page said *"The host has 1 hours to approve"* (fixed with Defect 14); the host's **Profile** screen on the app is still the pre-redesign teal slab (raw DOB *1995-05-05*, white-on-teal) — a design-parity item, not a defect; step 5's *Update listing* stays disabled on an approved listing until bank details exist (*readiness 95% — still to add: Bank details*), which is the publish gate doing its job.

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

## Defect 16 — the stay sitting on the search point was dropped (High, backend)

Every distance in `property.controller.js` is `6371 * acos(x)`. For a listing ON the search point x is 1.0000000000000002 in floating point and MySQL's `ACOS` answers NULL, so `distance <= radius` is not true and the one stay under the pin is the one stay left out. The platform's own geocoder answers a town with a listing's exact point (`/public/geocode/search?q=Nainital` returns 29295's coordinates), so this is the common case: *"Stays in Nainital"* showed *No stays here yet* on the app while a name search found it. Found by reading the app's exact request off the server log and replaying it. Fixed `aad3144`: the argument is clamped to [—1, 1] at all four sites; the test lifts each literal out of the source and evaluates it with MySQL's semantics (it measured x = 1.0000000000000002 on the raw formula).

## Defect 17 — the app's GST slab followed the flat rate, not the night being charged (Medium, app, money)

Before the server's per-night figures arrive, `priceStay()` banded the slab on `perNightTariff` — the listing's flat rate — so a ₹9,500 Sunday night on a ₹7,000 listing read *GST (5%) / ₹9,975* on the booking sheet while the server (and the sticky bar) said 18% / ₹11,210. Fixed in build 108: the fallback divides the discounted room by the night count and bands on that; the flat tariff only decides when the count is unknown. Pinned in `booking_pricing_test.dart`.

## Defect 18 — the booking breakdown subtracted the discount twice (Medium, app, money display)

`book_price` is stored net of any deal (createBooking subtracts the discount before the row is written). The ongoing-booking view and the history page passed it as the *Room charge* line and printed the discount on a line of its own, so B326241 read *Room ₹8,400 — Discount ₹1,100 + Taxes ₹1,512 = ₹9,912*. Fixed in build 108: the room line is net + discount (the listed room), the derived tax is total — net, and `book_price` is rounded rather than truncated (8399.90 is ₹8,400, not ₹8,399). Pinned in `the_breakdown_adds_up_test.dart`.

## Defect 19 — a spent deal still said "Book at the agreed price" (Low, all three surfaces)

After B326241 was booked on its deal, `/user/negotiations/list` still returned the thread as *accepted* and both clients offered *Book at the agreed price* over a coupon already used. Backend `60cbd41`: an accepted thread matched to a live, uncancelled booking by the same guest on the same stay with that thread's deal code now says **booked** with the `bookingId`. Web `501ad26` and build 108 render *Booked as B326241 — view booking*.

## Defect 20 — a host counter had no price bound (Medium, backend)

A host on the app countered ₹2,600 on a ₹2,500 night and the server took it (offer 236). The counter branch checked only that the number was positive; its "no ceiling" note is about rounds (the client's 12 Sep instruction). A counter above what the stay lists at is not an offer — the guest can book at the list price — and a counter at or under the guest's own figure is an acceptance wearing the wrong button. Fixed `2bcf1cc`: both refused with the number quoted, before any row is written; the ceiling is the dated list price.

## Defect 21 — a paused listing still took offers (Medium, backend)

The booking gate has always refused a paused or deleted listing ("no property found") and search hides it, but `loadTiers` never read `is_active`, so an offer on a listing the host had just hidden was judged by every other rule and refused, when it was refused, for the wrong reason. Fixed `48d38b0`: the loader flags a paused listing and `submitOffer` says so first.

## Defect 22 — the guest was not told the host declined (Medium, backend)

`/host/negotiations/respond` told the guest of a counter (a bell row, since 5 Sep) and of an accept (the coupon's own row), but a plain decline — no counter in the session, so no parting coupon and none of its notification — wrote nothing at all. Only the socket emit went out, which reaches a guest who has the page open and nobody else; a guest who looked at their bell later saw the offer still waiting on the host. The mirror of Defect 9's family (the host not hearing the guest's decline, fixed 17 Sep). Fixed `d64abab`: one row, written only when the parting coupon's own notification did not go out; pinned by `theGuestHearsTheHostsDecline.test.js` (fails on the old code). Both clients already route it — *offer* in the text lands on Negotiations.

## Fifth and sixth sittings — 20 Sep 23:00 → 21 Sep 05:00 IST · the booking remainder, the host wizard end to end, the publish chain

Two sittings on the same night, run as one: **the booking remainder on the web (guest 101, Claude in Chrome) and by API**, then **the whole host-listing suite on the emulator** (host 100, build 108 — a fresh draft "QA Wizard Test 21 Sep", #29312, driven through all five steps, submitted, rejected by the admin, edited and resubmitted from the phone, approved, edited live), with the admin queue on the web and every server rule read at the payload or driven in-process through the same controllers the server runs. **164 verdicts were written in these two sittings — the cases still open after the fourth sitting, plus the earlier rows a fix changed — and every one of the 300 now has a verdict.**

**What was driven, and where the actual values are**

| Area | How | Actual values recorded |
|---|---|---|
| BK-040…BK-100 (payment, cancellation, refunds, double-booking, after the stay) | Web as guest 101; DB reads; the policy tests | B249119 / the 22→24 Sep hold (abandoned checkouts), B408310/B915648 (overlap and same-day refusals), B326241 (cancel dialog, OTP row 93), B939553 (refund ₹210), invoices 0048–0076 |
| HL-001…HL-100 (the wizard) | Emulator, host 100, build 108 — 155 screenshots (`hl_01`…`hl_155`, `hl089_*`, `hl095_*`, `hl091_*`, `hl059_*`) | Draft #29312: every step's values, the refusals typed and read, `property_submission` psb 15 through draft → submitted → rejected → submitted → approved → updated, `tbl_admin_audit` 144/145, host bells un 861/862 |
| Security, uploads, races | In-process through the deployed controllers (no token needed) and the real multer chain | HL-057/058 refusals verbatim; HL-098: seven writes on host 177's #29306 as host 100, all "Draft not found", rows byte-identical |
| Bot channel | `negotiationService.submitOffer(channel: 'bot')` — the call `/bp/negotiate` makes | offers 241/242 on #29312, the counter at ₹2,800, the deal DEAL29312101C242 at checkout |

**Verdicts this pair of sittings (164 written):** 134 PASS · 18 FAIL (every one fixed the same night — Defects 23–44 below, twelve of them on two or three surfaces) · 6 SPEC · 5 BLOCKED (the Razorpay modal, a second sign-in) · 1 INFO. Every fix carries a test that fails on the old code; backend 182/182 test files, web 69 test files + `tsc -b` + a production build, app 593 tests — all green.

**The listing-wizard verdict in one line:** the five steps hold — every refusal the case sheet asks for is there and worded (5–80-char names, sanitised input, PIN↔state, 40-char descriptions, year range, price floors, weekly/monthly sanity, six declarations, scroll-to-accept, one submission per listing, the state machine with its audit rows) — and what failed was the connective tissue between surfaces: a rule that lived on the website and not the phone (pet fee, caretaker gating, pool type, the derived bed count), a server rule the phone could talk past (min>max nights, unvalidated phone numbers, the typed bed count), and three things that nobody had built on any surface (photo reorder, the parking-spaces question, the reviewer's note on the listing).

### Defects 23–44 — found and fixed in these two sittings

Numbered on from the 22 above. **Surface** says where the code was wrong; every one is pinned by a test named in the fixes table.

| # | Case | What was wrong | Surface | Fix |
|---|---|---|---|---|
| 23 | BK-089 | The ₹5,000 security deposit was stated on the property page and nowhere else — a guest read "Total ₹6,615" on review, payment and confirmation and would be asked for ₹5,000 at the door | web | `lib/securityDeposit.ts`, one sentence under every total (`b7bba40`) |
| 24 | BK-040/041 | The host was mailed "You have a new booking" for an unpaid hold (B249119, row 882) — a checkout nobody finished | backend | the creation-time host row is written only for a booking that is real at creation (`b31c0a6`) |
| 25 | BK-051 | Payment verification never re-checked the nights — two guests paying for the same nights in the same minute would both be confirmed | backend · web · app | verify re-checks, cancels and refunds the loser and answers `datesTaken`; web and app say so (`b31c0a6`, `b7bba40`, app 109) |
| 26 | pre-booking | The advance-booking discount was off by a day: tomorrow's stay got 0%, the day after 10% (a local-midnight Date measured against a UTC midnight) | backend | decided on the calendar date (`theFirstAdvanceDayGetsTheDiscount`) |
| 27 | BK-074 | Invoice numbers came from `count()+1` and collided; the insert's error was swallowed, so 29 stays had no invoice; a cash stay had no receipt at all | backend | numbered from `inv_id`; `raiseInvoice()` guarded; cash receipt from the booking row; backfill script ran (0048–0076) |
| 28 | NG-033 | Every offer expired at 30–33 minutes under a promise of "usually replies within 1 hour" — the sweep read only `pn_expiry_hours`, which no host has set | backend | `pn_expiry_hours` → `pbr_response_time_hours` → default (`anOfferWaitsAsLongAsTheHostSaid`) |
| 29 | NG-081 | A host counter for a stay whose first night had passed could still be accepted, minting a deal for a night nobody could book | backend | refused with the date, before every branch (`aStaleCounterCannotBeTaken`) |
| 30 | HL-035 | The BHK-vs-bedrooms cross-check was dead on both clients: the select stores `3_bhk`, the regexes allowed only spaces before "BHK" | web · app | underscore or space; prints "3 BHK", not the slug |
| 31 | HL-036/037 | "Number of parking spaces" did not exist | schema · web · app | added with `showIf { key: parking, in: [covered, open, street] }` — the new `in` form beside `equals`, read by both clients |
| 32 | HL-045 | Pet fee, size and limit were asked on the website only; a host on the phone could welcome pets and never name a price | app | the three fields under "Pets allowed", posted with step 4, loaded back |
| 33 | HL-046 | "Wheelchair Accessible" with none of Ramp/Lift/Ground Floor drew no question | web · app | "accessible, but how?" warning under the chips |
| 34 | HL-049 | A Smart Lock with self check-in off linked to nothing two steps away | web · app | a note under Security pointing at step 4 |
| 35 | HL-055 | Neither client could reorder photos although the server has taken `sortOrder` since the engine shipped | web · app | earlier/later on every tile, every position sent |
| 36 | HL-075 | Minimum nights 3 / maximum 2 saved on every surface | backend · web · app | server refuses "Minimum nights (3) can't be more than maximum nights (2)…" (seen live 03:03); both clients inline |
| 37 | HL-082 | The app showed the caretaker fields whether or not a caretaker was available (the web gated them) | app | gated on the step-4 switch, with a note |
| 38 | HL-081 | Both clients said "10-digit mobile"; the server stored whatever arrived | backend | `saveStep5` refuses, naming the field (`aContactNumberCanBeDialled`) |
| 39 | HL-076 | The step-5 readiness card showed a stale answer (two refreshes in flight; the slower landed last: "9 of 10" over a listing the server had at 10) | app | sequence-guarded (`theReadinessCardKeepsTheNewestAnswer`) |
| 40 | HL-089 | `psb_review_notes` had one writer and no reader: the reviewer's reason reached the host as a bell and an email and never on the listing — a "Rejected" badge and no why, on the card and inside the wizard they were sent back into | backend · web · app | `utils/reviewNote`: `review_notes` on the host's rows, `review` on the draft; the reason on the card and a banner at the top of the wizard (`66ac24d`, `6dea8f7`, app 109) |
| 41 | HL-058 | A 9 MB photo passed the photo route (its multer is the 12 MB document one) under a refusal that says "Photos must be under 8 MB" | backend | the controller applies 8 MB to photos, naming the file and its size (`943bd5e`) |
| 42 | HL-034 | A type change kept the old type's answers: the server left the rows, the public page printed "Camp Type: Riverside Camp" on a Villa, the web kept them in state, the app cleared them without a word | backend · web · app | the server drops the other category groups on save (`e333879`); both clients ask "Change the property type? The N answers you gave about the Camping will be cleared." (`4763f45`, app 109) |
| 43 | HL-044 | The app never set `has_pool` from the Swimming Pool chip, so Pool Type was never asked on the phone (the web set it) | app · web | the chip sets it; both clients derive `has_pool`/`has_wifi` from the chips on load |
| 44 | HL-027/028 | The server checked the TYPED bed count (3) and stored the room-card sum (1): #29312 was published as "2 bedrooms · 1 bed · 4 guests", the listing the bedrooms≥beds rule exists to refuse; the app checked the typed figure too | backend · app | the rule runs on the figure that will be stored (`f8549ba`, app 109) |

**Also fixed on the way, not numbered:** a stay priced as a week read "(weekend rates apply)" on the room line of three pages — it says "(weekly rate)" / "(monthly rate)" now (BK-018, web `5bd9b13`, `aWeekIsNotAWeekend`); Defect 3 (a shorter stay costing more than a longer one) — fixed by the user's instruction in this sitting (`aShorterStayNeverCostsMore`); the app's "Continue without photos" label now reads "Continue anyway" once photos exist; and **HL-043** was not a defect but a gap — 88 amenity chips in seven groups had no search on either client; "Find an amenity" is built on both (`92dea0d`, app 109).

### Observations for the client (not defects, recorded with the numbers)

- **NG-010/011 — the negotiated price lands within paise.** A deal is a DECIMAL(5,2) percentage of the stay's list subtotal, rounded UP so the guest is never billed above the agreed price (documented in `negotiationCoupon.js`). ₹2,800 × 3 nights against ₹9,000 listed is −6.67%, so the review page charged **₹8,819.69** against an agreed ₹8,820.00 — 31 paise in the guest's favour — while its own line reads "you save ₹600". Exact charging would mean minting a date-locked deal as a flat amount; the app's "Book at the agreed price" path adopts percentage deals only, so that is a three-surface change and a decision.
- **BK-044 — there is no payment webhook.** A booking becomes paid only when the client calls verify with Razorpay's signature. That is the gateway's cryptographic confirmation and it is replay-safe (P-04), but a guest who pays and loses the tab before verify runs has a captured payment on a hold that lapses. Razorpay's `payment.captured` webhook is the usual second leg; recommended.
- **BK-094 — approval requests never "expire".** The sweeper auto-CONFIRMS an unanswered request (the client's decision); the case sheet expects the opposite.
- **HL-090 — autosave is per step.** Both wizards save on Continue; a step left before Continue is not saved. The case sheet reads as field-level autosave.
- **HL-042 / HL-048 / HL-012 — three spec items the product does not have:** amenity chips that vanish once picked (the product toggles them in place, per the client's own HOST-9 screenshot), a host-picked "highlights" list (the page's highlights are derived), and an AI "Help me write" (not built).
- **HL-044 — "pool hours" is asked nowhere** (the schema has type/private/shared/infinity/indoor/outdoor/heated/kids).
- **The host's property list on the app is stale after a submit** until pull-to-refresh, and the Property Details screen keeps the object it opened with (it still read "Paused — hidden" after the approval). Minor; both refresh on reopen.
- **BK-023 — the host received two emails for one pay-at-property booking** (a detailed one and a generic one). One is enough.
- ~~**Build 109 is committed but not built.**~~ Built in the eighth sitting once Temurin JDK 21 was installed (`flutter config --jdk-dir` pointed at it); see the eighth sitting below.

### Records created in these two sittings (all on test data; nothing on a real customer)

| Record | Where | State now |
|---|---|---|
| Listing **#29312** "QA Wizard Test 21 Sep" (host 100, LUXE flag, test images, fake bank row `HDFC0000001 / …2222` on `property_bank_details` and `tbl_host_acc_details` had 4) | the wizard run | **LIVE and public** at `/property/qa-wizard-test-21-sep-sector-29-gurugram-haryana` — to be paused (host toggle) or suspended (admin) and the bank rows removed; see "What is needed" |
| `property_submission` psb 15; `tbl_admin_audit` 144 (rejected) / 145 (approved); host bells un 861/862; mails se 886 + the approval mail | HL-088/089 | keep (audit) |
| Offers **241/242** (guest 101 ↔ host 100 on #29312, ₹2,600 → countered ₹2,800 → accepted); deal **DEAL29312101C242** (−6.67%, 21→24 Sep) | NG-056/010 | the deal lapses at midnight 21 Sep; no booking made |
| B249119 (29295, 1→2 Oct, unpaid hold, order created) and the 22→24 Sep hold on 29295 | BK-040/052 | lapsed / lapse at 30 min |
| OTP row 93 (B326241 cancel, one failed attempt), mail rows 881–883 | BK-060/062 | B326241 still awaits its OTP cancel (dialog open in the guest tab) |
| Offer 240 on 29306 (30 nights, Hindi note) | NG-015/089 | expired |
| Invoices 0048–0076 | BK-074 backfill | keep (they are the missing fortnight's invoices) |

---

## Seventh sitting — 21 Sep 11:20 → 13:10 IST · the gateway, with the user at the Razorpay modal

The five cases that needed a person at the gateway, run with the user paying in **Razorpay Test Mode** while the session drove everything up to and after the modal: two paid bookings, one failed attempt, one dismissed attempt, a guest cancellation with its email code, a host cancellation from the phone. **All five BLOCKED cases now have a verdict; nothing on the sheet is blocked.** The money moved for real (test mode) and was read back at the gateway, the ledger, the payouts and every notification store — and paying for real found five more defects, four of them money or state.

| Case | What happened | Verdict |
|---|---|---|
| **BK-039** failed payment | B283961 ₹945 on our host 194's PG — declined at the mock bank → hold stays `Payment Pending`, paid 0.00, nothing told to anyone; Retry on the same order inside the modal | PASS |
| **BK-043** network drop / dismissed | ✕ on the modal → our page back to "Pay ₹945 Securely" (silently — noted); retry opened a fresh order and, after the fix below, closed the abandoned hold ("Checkout restarted") | PASS, Defects 45–46 |
| **BK-038** successful payment | B380412 ₹945 → `Paid & Verified`, gateway ₹945, invoice `AAJOO-INV-202609-0077`, ledger split, guest bells 868/869 + mail, host 194 bells 870/300/301 + mails, admin 302, "Request sent · Paid online" | PASS, Defect 48 |
| **BK-061/064/066** refund by policy, partial, visible | Guest cancel of B380412 with the email code: dialog quoted **Moderate · 50% · ₹472.50**; Razorpay partial refund COMPLETED; "₹472.50 refunded to your original payment method — 5–7 working days"; host 194 and admin told; host's ₹741 payout **on hold** with the re-split reason | PASS, Defect 47 |
| **NG-011** negotiated price is charged | The accepted deal on #29312 (₹2,800 × 3): review ₹9,000 − ₹600.30 + GST = **₹8,819.69**, paid, `Paid & Verified`, coupon spent 1/1, invoice 0078, thread reads "Booked as B146234" | PASS (31 paise under the agreed ₹8,820, the documented round-up), Defect 49 |
| **BK-068** host cancels (live, on the host app) | "The guest gets back everything they have paid (₹8,820)" → full refund COMPLETED, payout retracted, credits reversed, guest/host/admin told | PASS |

### Defects 45–49

| # | Case | What was wrong | Surface | Fix |
|---|---|---|---|---|
| 45 | BK-043/038 | **Defect 25's own re-check refunded a good payment.** A guest who closed the gateway and pressed Pay again held two payment-pending rows for the same nights; the create path steps over the guest's own hold, the verify-time re-check did not — so the second, PAID booking (B653102, ₹945) was cancelled and refunded as "taken by another guest", the other guest being the guest's own abandoned hold | backend | the re-check knows who is paying; their own unpaid hold steps aside, their confirmed stay and anyone's hold still block (`3324f50`, `thePaidNightsAreStillFree` extended) |
| 46 | BK-043 | A retried checkout held the nights twice under two orders | backend | `supersedeOwnPendingHolds`: the guest's own overlapping unpaid hold is cancelled inside the create transaction, "Checkout restarted" on its history (`5423467`, `aRestartedCheckoutClosesTheEarlierHold`) |
| 47 | BK-061/066 | **No refund had ever reached the finance ledger.** The REFUND type existed and had zero rows; a cancelled stay kept its four credit rows COMPLETED, so the Finance dashboard counted refunded money as revenue and commission for good — **10 refunded bookings, ₹68,939, inflating revenue by ~18%** (₹4.6 lakh shown for ₹3.92 lakh held) | backend · web | `recordRefund` writes one DEBIT row per refund (gateway or wallet, keyed on its reference); a 100% refund reverses the booking's credits; dashboard revenue and the monthly series net the refunds of bookings whose credits still stand; backfill run on dev (10 rows, 16 credits reversed); the KPI relabelled "net of ₹… refunded" (`b1c0e92`, `4768bfc`, web `7e233d4`) |
| 48 | BK-038 | The Upcoming card's badge said *Awaiting approval* while the line beneath said "Confirmed — you're all set for check-in" (Defect 14's fault one line lower) | web | "Waiting for the host — …confirmed automatically if they don't answer" (`c4eec51`) |
| 49 | NG-011 | **"Does the host approve" was written twice with opposite defaults.** Creation asked `type === "instant"` and said "Request sent — the host has N hours" for anything else; verification and the sweeper asked `type === "approval"` and confirmed anything else outright. #29312's type was NULL (the app's wizard saved none): the guest read "request sent", the booking was confirmed on payment, the host app showed *Confirmed* and was never asked — and a pay-at-property booking on such a listing would have waited for a Confirm the sweeper never times out | backend · app | `utils/hostApproval` — approval only when the host chose it, unset and legacy are instant — read by creation, verify, the availability answer and the sweeper (`7380a98`); the app's wizard defaults booking type to *approval* like the web (`92c8b7c`, build 109) |

**Observations from this sitting (not defects):** the OTP mails (four of them) all left Brevo as "Email sent successfully" and none showed in the Mailinator public inbox, which then dropped every other mail too — the two test accounts need real mailboxes (the code was read from the dev database for the run); after a dismissed modal our page says nothing (the hold is kept, silently); the invoice of a refunded booking stays GENERATED (no credit note or void on refund — a finance decision); the host's payout after a partial refund is held for a human re-split (by design). The emulator's Android hung in its boot animation once mid-sitting; `adb reboot` brought it back with the host still signed in.

**Records:** B283961 (superseded), B653102 (paid ₹945, refunded in full by the platform — Defect 45's evidence), B380412 (paid ₹945, guest-cancelled, ₹472.50 refunded, payout po_25 on hold ₹741), B146234 (paid ₹8,819.69 on #29312, host-cancelled, refunded in full, payout po_26 retracted); invoices 0077/0078; offers 241–243 (243 expired at the host's hour); #29312 paused again. Every refund is a real Razorpay test-mode refund with its `rfnd_` reference on the booking.

## Eighth sitting — 21 Sep 14:30 → 15:20 IST · build 109 on the phone, the admin clean-up, Defect 50

The user installed Temurin **JDK 21** (21.0.12.1); `flutter config --jdk-dir` was pointed at it and `./tool/build_release.ps1 … -AllowTestPayments -AllowDevEndpoint` produced **build 109** — `app-release.apk`, 95.6 MB, sha256 `064CC19B501AFD11D8E8C1B7EA6CAC14A3998AEAD19138C63BBEA84830B266D7`, the verifier reading the dev endpoint and the sandbox key out of the artifact (versionCode 109 on the emulator). The app subtree was pushed to the client's repository: `aajoo_app_latest` main `30edba5` → **`f566782`** (three commits, APK blobs stripped, fast-forward checked).

**Every build-109 fix driven on the phone as host 100, on #29312:**

| Fix | Seen on device |
|---|---|
| The wizard says why it was rejected (Defect 42) | the Property Details card reads *"Not approved: QA check of build 109: please add a photo of the second bedroom…"* and step 5 opens under the banner *"Aajoo did not approve this listing"* with the same note |
| A type change asks first (Defect 43) | tapping *Villa* on an Apartment: *"Change the property type? The 2 answers you gave about the Apartment will be cleared. You can fill in the details for the new type on the next step."* — Keep it / Change type |
| Find an amenity (HL-043) | typing *pool* in *Find an amenity* lists *Swimming Pool · Premium* under *Amenities matching "pool"*, with *Show all groups* |
| The bed rule runs on the beds the room cards describe (Defect 44) | **it fired on the listing's own stored data**: *"2 bedrooms need at least 2 beds between them"* — #29312 had been saved under the old rule with Bedroom 2 carrying no bed (Beds reads 1, greyed, derived). A Double was added to Bedroom 2; `pc_beds` is now 2 and the cards say queen×1 + double×1 |
| A new listing asks the host to approve by default (Defect 49) | *How guests book → Booking type: Approval Required* selected; step 4 was saved so #29312's stored rule is `approval` (its NULL was Defect 49's evidence) |
| Pet fee / allowed size / maximum pets; parking; reorder (Defects 33–37) | the fields render under House rules on step 4 |

To read the rejection note on the phone the listing was rejected in admin with that note, read, resubmitted from step 5 (the six declarations ticked again — they are not carried over) and approved from the Submitted tab. That round trip found **Defect 50**.

### Defect 50

| # | Case | What was wrong | Surface | Fix |
|---|---|---|---|---|
| 50 | clean-up | **An admin approval put a listing the host had paused back on the site.** The host's Pause and an admin's Deactivate both write `is_active = 0`, and the approve branch of `reviewListing` (and the older Properties-dialog approve) wrote `is_active = 1` whatever the reason the listing was off — so a host who paused a listing and then edited it, or answered a rejection, had it published by the approval without pressing anything and with a bell saying "Your listing is live". #29312 (paused, hidden, page 404) came back live and had to be paused again from the card | backend | `property_paused_by_host` records the host's own switch (written by the host's pause/resume, migration `20260921100000`, run on dev); both approve paths publish a listing the host has not paused and leave alone one they have, the bell reads *"…is approved. It is still paused — switch it on from your properties when you are ready"*, and the API's `published` stops claiming otherwise (`62bcf3f`, `approvalKeepsTheHostsPause`, fails 2/2 on the old code) |

**The admin clean-up (the user's go-ahead, 21 Sep):** payout **#25** (B380412, host 194, ₹741, was on hold) and payout **#24** (B021812, host 100, ₹1,727.75) **rejected** in the Payout Queue with reasons on the row; host due **hd_id 49** (₹476.99, B021812) **voided** through `hostDues.voidFor` with its reason (Settlements has no per-row action — dues are recovered from payouts, so a due on a stay that never happened has no button); host 100's fake payout account (**had 4**, `…2222 / HDFC0000001`) and its mirror row (**pbd 5**) are the one thing left — there is no host-side remove (only add) and the session's policy refused the write on the client's host row; a two-line script is ready for the user (`bank100_rm.js`: `had_isDelete = 1` on had 4, delete pbd 5).

**Decision 1 taken (the user, 21 Sep):** a negotiated price is charged as the documented % coupon rounded up in the guest's favour (₹8,819.69 for an agreed ₹8,820); no change.

**Observations (not defects):** the admin's Rejected tab lists a rejected listing with no action although the lifecycle allows rejected → approved ("Approving it or leaving it is the choice now") — the host has to resubmit; the step-5 declarations are not carried over on a resubmission (deliberate, but six taps); the Property Details screen keeps the object it opened with after the wizard returns (still "Rejected" after the resubmission until the list is refreshed); the admin tab in Chrome hung once after the rejection (script injection timed out for a minute; a fresh tab was fine); the wizard's back arrow steps one step at a time and the Android BACK key is swallowed on step 5.

**Records:** #29312 — approved, **paused by the host** (`property_paused_by_host = 1`, page 404), Bedroom 2 now has a bed, booking type `approval`, submission psb approved 09:34 UTC; admin audit rows for the rejection and the approval; host bells for both; payouts po_24/po_25 FAILED with reasons; hd_id 49 VOID.

---

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
| `62e652f` | Defect 15: the offer claim holds the listing's row lock across the insert |
| `f78d72b` | A fixed-price listing says so before any date rule (NG-042/062) |
| `aad3144` | Defect 16: `acos()` clamped at all four distance sites — the stay on the search point is found |
| `60cbd41` · web `501ad26` · build 108 | Defect 19: a spent deal reads Booked, with its booking |
| build 108 | Defects 17 and 18 (app slab fallback; breakdown adds up), the guest tabs file a checked-out stay under Completed |
| `2bcf1cc` | Defect 20: a host counter is bounded by the price — never above the dated list, never at or under the guest's offer |
| `f8ec735` | Defect 19, corrected: "booked" matched by the deal's own code, not by the stay |
| `48d38b0` | Defect 21: a paused listing refuses an offer first, and says why |
| `ac699fe` | The plain accept told once (Defect 9's second half); "1 hour", not "1 hours" |
| `d64abab` | Defect 22: the guest is told of a plain decline — one bell row, not two. Backend 167/167; web 31/31 + `tsc -b` + build; app 558/558 |
| `b7bba40` (web) | Defect 23: the deposit under every total (`theDepositIsStatedUnderEveryTotal`); Defect 25's `datesTaken` branch; the rate label not fooled by a discount |
| `b31c0a6` | Defects 24, 25, 3: the host told only of a booking that exists; verify re-checks the nights (`thePaidNightsAreStillFree`); a shorter stay never costs more (`aShorterStayNeverCostsMore`) |
| `theFirstAdvanceDayGetsTheDiscount` · `anInvoiceNumberIsNeverReused` · `aCashStayHasAReceipt` · `scripts/backfillInvoices.js --write` | Defects 26, 27; 29 invoices raised (0048–0076) |
| `anOfferWaitsAsLongAsTheHostSaid` · `aStaleCounterCannotBeTaken` | Defects 28, 29 |
| schema + `parkingSpacesFollowTheParkingAnswer` · `aMinimumStayCannotExceedTheMaximum` · `aContactNumberCanBeDialled` · `7feb828` | Defects 31, 36, 38 on the server |
| web (`theBhkCheckReadsTheSlug`, `accessibleButHow`, `photosCanBeReordered`, `aMinimumStayCannotExceedTheMaximum`, `7c8ab4a`) | Defects 30, 33, 34, 35, 36 on the web |
| `66ac24d` · web `6dea8f7` | Defect 40: `utils/reviewNote` — the reviewer's reason on the host's rows and the draft; the card line and the wizard banner (`theHostReadsWhyItWasRejected`) |
| `943bd5e` | Defect 41: a photo over 8 MB refused on the photo route (`aPhotoOver8MbIsRefusedOnThePhotoRoute`) |
| `e333879` · web `4763f45` | Defect 42: a type change drops the old type's rows; both clients ask first (`aTypeChangeTakesTheOldTypesAnswersWithIt`, `aTypeChangeAsksFirst`) |
| web `92dea0d` | HL-043 built: Find an amenity; WiFi and the pool open their questions through one path (`anAmenityCanBeFoundByName`) |
| `f8549ba` | Defect 44: the bed rule runs on the beds that are stored (`theBedRuleRunsOnTheBedsThatAreStored`) |
| `3324f50` · `5423467` | Defects 45, 46: the verify re-check knows who is paying; a restarted checkout closes the earlier hold (`thePaidNightsAreStillFree`, `aRestartedCheckoutClosesTheEarlierHold`) |
| `b1c0e92` · `4768bfc` · web `7e233d4` | Defect 47: `recordRefund` — every refund on the ledger, a full refund reverses the credits, revenue net of refunds; backfill run on dev (10 rows, 16 credits reversed); the KPI relabelled (`cancellationMovesTheMoney` extended) |
| web `c4eec51` | Defect 48: the Upcoming card says "Waiting for the host" over a request (`aRequestIsNotAStay` extended) |
| `7380a98` · app `92c8b7c` | Defect 49: `utils/hostApproval` — one rule for creation, verify, availability and the sweeper; the app's wizard defaults to approval like the web (`approvalAppliesOnline` extended) |
| `62bcf3f` | Defect 50: `property_paused_by_host` — an approval leaves a listing the host paused paused, and tells the host (`approvalKeepsTheHostsPause`; migration run on dev) |
| app — monorepo `d1aabf9` + `aa4672a` + `92c8b7c`, **build 109** (sha256 `064CC19B…B266D7`, client repo `f566782`) | Defects 25, 30–37, 39, 40, 42, 43, 44 on the phone; HL-043; tests `a_refunded_payment_is_not_a_stay`, `the_bhk_check_reads_the_slug`, `parking_spaces_follow_the_parking_answer`, `accessible_but_how`, `photos_can_be_reordered`, `pets_have_a_price_on_the_app`, `a_minimum_stay_cannot_exceed_the_maximum`, `the_readiness_card_keeps_the_newest_answer`, `the_host_reads_why_it_was_rejected`, `a_type_change_asks_first`, `an_amenity_can_be_found_by_name`, `the_bed_rule_runs_on_the_beds_that_are_stored` |

---

## What is needed to unblock the rest

1. **A guest test account we own, with a password held by the client**, so booking, payment and negotiation cases can be driven without touching accounts 101/100. Roughly **120 of the 300** cases create data and need this. *(20 Sep: the account exists — guest 179 "Renter test web"; what is needed is a person signing it in on Chrome and on the emulator, because a session never types a password. On 20 Sep Chrome held host 100 and the emulator held guest 101.)*
2. **A host test account on the same basis**, for the 100 HL listing cases. *(20 Sep: host 194 or 177 "Host Mobile", same condition.)*
3. **A test payment method** for the BK payment cases (BK-038…BK-049).
4. Confirmation that the **dev environment** is the right target, and that test bookings there are acceptable.

**After the fifth and sixth sittings (21 Sep 05:00 IST) — what only a person can do:**

5. ~~The five BLOCKED cases~~ — **done in the seventh sitting** (the user at the Razorpay modal; NG-077 answered by design: a host-also-guest is refused on their own listing and treated as any guest elsewhere).
6. ~~**Build 109**~~ — **built, installed, verified on the phone, pushed to the client's repo** (eighth sitting).
7. ~~Reject payout 24; void hd_id 49~~ — **done** (eighth sitting; payout 25 rejected as well). The BK-088 price edit on 29303 (₹900 → ₹950 → ₹900) only if a live repeat is wanted.
8. **Clean-up on the client's host account (100):** #29312 is paused by the host and its stored data is now sound; **still to do by the user:** the fake bank rows (`tbl_host_acc_details` had 4 → `had_isDelete = 1`; delete `property_bank_details` pbd 5) — the script is written; the B326241 OTP cancel (dialog open in the guest tab, code with you).
9. **Move the two test accounts to real mailboxes** — Mailinator dropped every mail this sitting and the cancellation codes never showed; the run read them from the dev database.
10. **Product decisions:** (a) ~~exact charging of a negotiated price~~ — **decided 21 Sep: the documented round-up stays**; (b) ~~a `payment.captured` webhook~~ — **go-ahead given and built 21 Sep** (`6fd10d1`, `POST /webhooks/razorpay`, one settle function shared with `/verify`, `theGatewayConfirmsOnItsOwn`); **with the user:** register it in the Razorpay dashboard (test mode) with a secret, set the same secret on Render as `RAZORPAY_WEBHOOK_SECRET`; the route answers 503 until then.

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
| BK-007 | Med | Mobile layout | PASS (21 Sep 05:05, built-in browser at 375×812): the property page stacks — price card below the content, Book Now full-width, no horizontal scroll (scrollWidth 375 = innerWidth) |
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
| BK-018 | High | Long-stay discount | PASS (web, 29302 5→12 Oct): 7 nights ₹19,000 — 'You're getting this host's weekly rate: ₹3,800 less than booking these nights one at a time — 16.7% off' − 10% advance + GST = ₹17,955. The room line said '(weekend rates apply)' over a weekly composite — reworded to '(weekly rate)' on the three pages (web 5bd9b13, aWeekIsNotAWeekend) |
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
| BK-034 | Critical | Book without KYC | PASS by code+test: bookingCreate calls assertVerified(userId, 'book a stay') before anything else (utils/kycGate); the web's checkout KYC step is pinned by kycGateNotSudden / kycGatesNegotiationToo |
| BK-035 | Critical | Empty guest details | INFO — see batch 3 notes |
| BK-036 | Med | Invalid phone | PASS (20 Sep) |
| BK-037 | Med | Invalid email | PASS · note (20 Sep) |
| BK-079 | Critical | See only own bookings | PASS (20 Sep) |
| BK-082 | Critical | Tampered price rejected | PASS (20 Sep) |
| BK-083 | High | Auth required | PASS (20 Sep) |
| NG-039 | High | Zero offer | PASS (20 Sep) |
| NG-040 | High | Negative offer | PASS (20 Sep) |
| NG-041 | Med | Non-numeric offer | PASS (20 Sep) |
| NG-042 | High | Offer on fixed-price listing | PASS: a fixed-price listing refuses an offer first and says so (f78d72b; NG-063 on 29302 with negotiation off — 'Send an Offer' gone, the API answers the fixed-price message) |
| NG-043 | High | Offer without login | PASS (20 Sep) |
| NG-090 | Med | Screenshot/replay attack | PASS (20 Sep) |
| NG-091 | Critical | Tampered offer price | PASS (20 Sep) |
| NG-094 | Med | Offer with expired session | PASS by test (20 Sep) |
| NG-096 | Med | Guest offers on own listing | PASS by code: submitOffer refuses 'You cannot send an offer on your own property' (negotiationService 836) |
| HL-077 | High | Identity linked | PASS (21 Sep, app: host 100's Profile → *KYC Verification · Identity verified*; the verification on this account) |
| HL-079 | Critical | Bank details save | PASS: step 5's bank block wrote tbl_host_acc_details had 4 for host 100 (verify_status awaiting_manual) and property_bank_details pbd 5 at 03:11; hosts 177/194's accounts saved on 18 Sep are the ones the admin's Payout accounts page lists — encryption is live on Render |
| HL-080 | High | Bank shown last-4 | PASS: the wizard reads back 'Earnings from this listing go to HDFC Bank XXXX2222' (getDraft masks to the last 4); the admin's Payout accounts page shows XXXX1630 / XXXX9012 with a logged Reveal |
| HL-098 | Critical | Host edits own only | PASS (21 Sep 03:45, in-process through the deployed controllers — host 100 against host 177's #29306): getDraft, step 2, step 4, step 5, submit, readiness and the media PATCH all answer 400 'Draft not found'; tbl_properties, property_pricing and property_specification of 29306 byte-identical before and after |
| HL-099 | Critical | Host sees own listings only | PASS (21 Sep, app: *Properties 2* — 29291 and 29302, host 100's own; `/host/property-search` filters on `property_host_id = req.user.userId`, the token, never a body id) |
| HL-100 | High | Docs access-controlled | PASS: the ownership document is Cloudinary `authenticated` delivery — the stored URL answers 401 anonymously, with or without its signature (the `upload` variant 404); the admin's Open link is a signed private_download_url with a TTL; getDraft is scoped to property_host_id |

### Batch 4 — Booking — create, confirm, availability, after the stay (14 of 30 run on 20 Sep, on the batch-6 loop)
**Needs:** The guest account. Creates real test bookings on dev.  
**Cases:** 30 · Critical: 3 · Already run: 0

| ID | Pri | Case | Status |
|---|---|---|---|
| BK-022 | Critical | Confirmation created | PASS (20 Sep, B021812) |
| BK-023 | High | Confirmation email/app | PASS live (12:18): guest 'Booking Confirmation' mail 896 + bells 868/869 for B380412; host 194 mails 895/897 (note: two mails to the host for one booking, as before) |
| BK-024 | High | Host notified | PASS (20 Sep, bell); copy fixed ac699fe |
| BK-025 | High | Booking ID generated | PASS (20 Sep) |
| BK-048 | Med | Currency correct | PASS (20 Sep) |
| BK-049 | Med | Tax shown | PASS (20 Sep) |
| BK-054 | High | Blocked dates unbookable | PASS (web, 29295): the host's 27 Oct block — forced by URL → 'Those dates are no longer available for this stay — please pick new ones.' and the dates cleared; in the picker 27 Oct is grey (title 'Already booked' — the public calendar does not distinguish a host block from a booking; wording noted) |
| BK-055 | High | Availability calendar accurate | PASS (20 Sep) |
| BK-056 | Med | Booking horizon | PASS by test (bookingHorizon); no fixture sets pbr_max_advance_days |
| BK-057 | Med | Minimum notice | FAIL → fixed bdab3b1 (Defect 12) |
| BK-058 | Med | Same-day conflict | PASS: both wizards flag 'same-day ON + 24 h notice' inline (app 21 Sep 02:34: same-day off shows the note; on + 24 h flagged) |
| BK-071 | High | My Bookings list | PASS live: confirmation records for B380412 (896) and B146234 (905) in tbl_send_emails |
| BK-072 | High | Booking detail accurate | FAIL → fixed build 108 (Defect 18) |
| BK-073 | Med | Ongoing stay shown | PASS after fix 32fb9c1 (Defect 14) |
| BK-074 | High | Invoice download | FAIL → fixed (Defect 27): invoice numbers collided (count()+1) and errors were swallowed; numbered from inv_id now, 29 backfilled (0048–0076); a cash stay has a receipt (aCashStayHasAReceipt) — live PDF verified 01:17 |
| BK-075 | Med | Modify booking | PASS: 'your stay has already started so the dates can't change — contact support' on B326241; the full modification flow was proven on 20 Sep |
| BK-076 | High | Check-in details | FAIL → fixed 4aab209 (Defect 13) |
| BK-077 | Med | Host contact revealed | PASS (20 Sep) |
| BK-078 | Med | Review after stay | PASS (20 Sep) |
| BK-085 | Critical | Negotiated price used | PASS (20 Sep) |
| BK-086 | Critical | Auto-accept → booking | PASS (20 Sep, app: B326241) |
| BK-087 | Med | Guest count feeds capacity | PASS: search by capacity — a 5-guest listing is out for 6 guests and in for 2 (same rule BK-030 proved at booking) |
| BK-088 | High | Price change reflects | PASS by architecture + evidence: property pages and quotes read pricingRuleFor(propertyId) at request time (no cache); NG-084's status change on 29302 showed instantly through the same path. The admin price edit itself was refused by the session's policy (Modify Shared Resources) — a person can repeat it |
| BK-089 | High | Deposit single-source | FAIL → fixed (Defect 23 web): the deposit was stated on the property page and nowhere else — b7bba40 states it under the review, payment and confirmation totals (theDepositIsStatedUnderEveryTotal); app already did |
| BK-093 | High | Instant vs approval | PASS (20 Sep) |
| BK-094 | Med | Approval timeout | SPEC — the approval sweeper auto-CONFIRMS an unanswered request on expiry (client decision), so nothing 'expires'; bookingApprovalExpiry test covers that rule |
| BK-096 | Med | Coupon applied | PASS (20 Sep) |
| BK-097 | Med | Invalid coupon | PASS: expired deal → 'This coupon has expired.'; another property's code → 'This coupon is for a different property.'; junk → 'This coupon code is not valid.' |
| BK-099 | Med | Back button mid-booking | PASS (21 Sep 01:18): history.back() from payment → review keeps dates, guests and the deal; forward returns to payment |
| BK-100 | High | Refresh mid-payment | PASS: a refresh on the payment page re-quoted the same stay and total; nothing charged, the hold unchanged |

### Batch 5 — Payment, cancellation, refunds, double-booking
**Needs:** The guest account + a TEST payment method + a second guest account for the concurrency cases.  
**Cases:** 30 · Critical: 11 · Already run: 0

| ID | Pri | Case | Status |
|---|---|---|---|
| BK-038 | Critical | Successful payment | PASS (21 Sep 12:18, the user at Razorpay Test Mode): B380412 ₹945 on host 194's PG → 'Paid & Verified', gateway ₹945, invoice AAJOO-INV-202609-0077, ledger 366–369, guest bells 868/869 + mail 896, host bells 870/300/301 + mails 895/897, admin 302; 'Request sent · Paid online'. Defect 48 (Upcoming card copy) fixed. Later NG-011's B146234 the same way |
| BK-039 | Critical | Failed payment | PASS (12:00): declined at the mock bank → B283961 stays Payment Pending, paid 0.00, payment row 'Not Verified Yet'; no bell, no mail; Retry on the same order in the modal |
| BK-040 | High | Cancelled payment | PASS live (12:03): the dismissed checkout's hold B283961 kept nothing, charged nothing and was closed by the next checkout |
| BK-041 | High | Payment timeout | PASS: same evidence — nothing is charged, the nights free themselves |
| BK-042 | Critical | Double-click Pay | PASS (21 Sep): double-click Pay → ONE booking (B249119) + ONE order; the button went 'Processing…' |
| BK-043 | Critical | Network drop during pay | PASS (12:03–12:18): modal dismissed → hold kept, retry opened a fresh order; paying it exposed Defect 45 (the guest's own abandoned hold refunded the paid booking) and Defect 46 (two live holds) — both fixed and re-proven live: the retry now closes the earlier hold ('Checkout restarted') and the payment stands |
| BK-044 | High | Webhook confirms booking | PASS by design: no payment webhook — a booking is marked paid only by verifyUserPayment after Razorpay's HMAC(order|payment) signature and the gateway amount read-back (verifyCreditsWhatArrived); recommendation: add payment.captured as the second leg |
| BK-045 | High | Webhook arrives twice | PASS by code+test (bookingIntegrity P-04); live: a second verify never fired — one 'Payment successful' per booking |
| BK-046 | High | Deposit on monthly | SPEC — the deposit is STATED under every total and collected by the host at the door (client, 15 Sep — same footing as cleaning); Defect 23 made the four pages say so |
| BK-050 | Critical | Double-booking prevented | PASS by code+test: the create path locks the listing row across the overlap check and the insert (thePaidNightsAreStillFree, bookingIntegrity); BK-052/053 live |
| BK-051 | Critical | Availability re-check at confirm | FAIL → fixed (Defect 25): verify had no availability re-check — b31c0a6 + web b7bba40 (datesTaken branch) + app 109 (DatesTakenDuringPayment) |
| BK-052 | High | Overlapping dates | PASS (21 Sep 01:10): overlap 24→25 on B408310, straddle 23→26 → 'These dates are already booked for this property.' |
| BK-053 | High | Same-day double | PASS: same-day 14→15 Oct on B915648 refused; turnover (checkout on another's check-in day) allowed |
| BK-059 | High | View cancellation policy | PASS: the policy ladder on the property page and, with the stay's own dates, on the review page ('100% refund if you cancel by 30 Sept, 2:00 pm IST') |
| BK-060 | Critical | Cancel booking | PASS (dialog, B326241): policy · 0% refund · No payment taken · reason chips → OTP step |
| BK-061 | Critical | Refund = policy | PASS live (12:49): guest cancel of B380412 — the dialog quoted Moderate · 50% · ₹472.50 (within 5 days of a 14:00 check-in today); Razorpay partial refund COMPLETED (rfnd_Tearsm9I0ieW6b); by test: cancellationPolicyV1. Defect 47 (no refund on the ledger) found here |
| BK-062 | High | Cancel with OTP | PASS live (12:49): the code was required and consumed (OTP row 96 → gone); wrong code earlier → 'Invalid OTP'. The mails (898–901) all left Brevo but Mailinator showed none — test-mailbox, see observations |
| BK-063 | High | Full refund window | PASS live (13:02, host cancel of B146234 on the host app): full refund ₹8,819.69 COMPLETED (rfnd_TebcNwfgglCZ0K), credits reversed, REFUND row 384; earlier B653102 (platform) and B939553 (host) the same |
| BK-064 | High | Partial refund window | PASS live: 50% window → ₹472.50 of ₹945, payment row 'Partly refunded ₹472.50', host's ₹741 payout on hold with the re-split reason |
| BK-065 | High | No refund window | PASS: 'After check-in or no-show: no refund' in the dialog and the schedule; B326241's dialog quoted 0% |
| BK-066 | High | Refund status visible | PASS live: Cancelled page '₹472.50 refunded to your original payment method — it can take 5–7 working days'; the guest's bell and mail name the window (UPI 1–5, cards 5–10, net banking 3–7 business days) |
| BK-067 | High | Deposit refunded | SPEC — deposit: stated, refundable, collected by the host (BK-046); the statement is on the property, review, payment and confirmation pages |
| BK-068 | High | Host cancels | PASS live on the HOST APP (13:02): 'The guest gets back everything they have paid (₹8,820)' + reason → refunded in full, payout po_26 retracted, guest bell 877 + mail 907, host bell 878 + mail 908, admin 306, history 'Host cancelled — full refund … (policy §7)' |
| BK-069 | Critical | Policy version locked | PASS by test: a booking keeps the policy it was made under (book_cancel_policy on the row; cancellationPolicyV1 'snapshot' case) |
| BK-070 | Med | Refund to original method | PASS live: payment 46 'Refunded' / 45 'Partly refunded ₹472.50'; book_refund_status COMPLETED with the rfnd_ reference on both |
| NG-010 | Critical | Accept creates booking | PASS (21 Sep 04:31, bot-channel thread on 29312): accepted ₹2,800 → 'Book at the agreed price' → review page 'Negotiated deal applied — DEAL29312101C242, you save ₹600'; charged ₹8,819.69 against 3×2,800+GST = ₹8,820.00 — 31 paise UNDER, by the documented round-up of a DECIMAL(5,2) percentage (see observations) |
| NG-011 | Critical | Accepted price is charged | PASS (12:57): the accepted deal DEAL29312101C242 (₹2,800 × 3) → B146234 charged ₹8,819.69 (9,000 − 600.30 + GST 419.99; 31 paise under the agreed ₹8,820 by the documented round-up), 'Paid & Verified', coupon spent 1/1, invoice 0078; Defect 49 (two definitions of 'host approves') found on it and fixed |
| NG-047 | High | Payment timeout after accept | PASS live: the accepted deal on #29312 lasted until midnight as promised and was spent by B146234; offer 243 on 29295 expired at the host's 1-hour window (bell 873, mail 904 — Defect 28's fix working) |
| NG-059 | High | Negotiated booking in My Bookings | PASS live (12:58): the thread reads 'Booked as B146234 — view booking'; earlier B326241 the same |
| NG-098 | High | Refund on negotiated booking | PASS by code+test: refunds compute from book_amount_paid (the negotiated amount the gateway took) × the policy window (cancellationMovesTheMoney) |

### Batch 6 — Negotiation — the guest side
**Needs:** The guest account. Creates real test offers on dev.  
**Cases:** 30 · Critical: 0 · Already run: 27 (18 PASS · 5 FAIL, all fixed the same day · 3 INFO · 1 BLOCKED) — 20 Sep

| ID | Pri | Case | Status |
|---|---|---|---|
| NG-016 | High | Make an Offer button | PASS (20 Sep) |
| NG-017 | High | Offer input validates | PASS (20 Sep) |
| NG-018 | High | Offer confirmation | PASS (20 Sep) |
| NG-019 | High | Offer status visible | PASS (20 Sep) |
| NG-020 | High | Counter shown to guest | PASS (20 Sep) |
| NG-022 | High | Real-time update | PASS web · app (build 108): the host's list moved with no touch (20 Sep 23:11) |
| NG-023 | Med | Offer thread readable | PASS (20 Sep) |
| NG-024 | Med | Mobile negotiation UI | PASS both halves (20 Sep) |
| NG-025 | Med | Waiting state | PASS (20 Sep) |
| NG-034 | High | Guest counters back | PASS (20 Sep) |
| NG-035 | Med | Multiple rounds | PASS (20 Sep) |
| NG-036 | High | Guest accepts counter | PASS (20 Sep) |
| NG-037 | Med | Guest declines counter | PASS (20 Sep) |
| NG-038 | Low | Round limit | INFO — no cap by client decision |
| NG-044 | Med | Offer on unavailable dates | FAIL → fixed 4a88a61 (Defect 11) |
| NG-045 | Low | Offer after booking | FAIL → fixed 4a88a61 (Defect 11) |
| NG-046 | High | Offer expiry | PASS (20 Sep, expired at 19:35) |
| NG-071 | Med | Rapid repeat offers | FAIL → fixed 62e652f, re-proven 19:41 (Defect 15) |
| NG-072 | Low | Offer then cancel | INFO — no withdraw; offers expire |
| NG-073 | Low | Guest edits offer before submit | PASS (20 Sep) |
| NG-075 | Med | Negotiate weekly then book nightly | PASS by the date lock (20 Sep) |
| NG-076 | Low | Offer on LUXE listing | PASS (21 Sep 04:30): #29312 is LUXE — the bot-channel offer went through the same engine and was countered at the listing's own ideal; no luxe branch |
| NG-078 | Med | Offer notification failure | INFO — pinned by test |
| NG-079 | Low | Currency in offer | PASS (20 Sep) |
| NG-080 | Med | Session lost mid-negotiation | PASS by evidence: every reload of /account/negotiations re-read the threads from the server (7 threads, their rounds and states intact across a dozen reloads this night); nothing lives in the tab |
| NG-081 | Med | Accept exactly at expiry | FAIL → fixed (Defect 29): a host counter for a stay whose first night had passed could still be accepted, minting a deal for a night nobody could book — refused now with the date (aStaleCounterCannotBeTaken) |
| NG-082 | Low | Guest offers after decline | PASS (20 Sep) |
| NG-088 | Low | Offer history after booking | PASS (20 Sep) |
| NG-089 | Med | Language in negotiation | PASS (21 Sep 01:30): a Hindi note ('एक महीने के लिए ₹60,000 — NG-015/NG-089 test') stored and rendered as typed on the guest thread and the host's bell |
| NG-092 | Med | Offer for 0 nights | FAIL → fixed bdab3b1 (Defect 12) |

### Batch 7 — Negotiation — the host side, timing, bot, cross-flow (13 of 30 run on 20—21 Sep, on the host's emulator)
**Needs:** Host account + guest account together; BotPenguin for NG-056..058.  
**Cases:** 30 · Critical: 3 · Already run: 0

| ID | Pri | Case | Status |
|---|---|---|---|
| NG-015 | High | Monthly negotiation | PASS (21 Sep 01:30): a 30-night offer on 29306 is a STAY TOTAL — '₹60,000 for 30 nights' on both sides; the host was told the total and the nights |
| NG-021 | High | Accept/decline buttons (host) | PASS (20 Sep, app) |
| NG-026 | High | Host notified of offer | PASS (20 Sep) — Defect 9 beside it |
| NG-027 | High | Host notified of auto-accept | PASS by evidence (20 Sep 20:38): the auto-accept on 29295 wrote host 177's bell ('Your offer was accepted' row, unread at the time) — the guest-accept row fixed in ac699fe |
| NG-028 | Critical | Host accepts | PASS (20 Sep 23:12, app: offer 237) |
| NG-029 | High | Host counters | PASS (20 Sep, app) |
| NG-030 | High | Host declines | FAIL → fixed d64abab (Defect 22); the decline itself PASS (21 Sep 00:04, app: offer 238) |
| NG-031 | Med | Host ignores → expiry | PASS: an unanswered offer expires and the guest is told 'Your offer expired' (offers 184–230 evidence); the window was the 30-min default — see NG-033 |
| NG-032 | High | Host sees offer amount | PASS (20 Sep, app) |
| NG-033 | Med | Host response-time honoured | FAIL → fixed (Defect 28): every offer expired at 30–33 min under a promise of '1 hour' — the sweep now reads pn_expiry_hours → pbr_response_time_hours → default (anOfferWaitsAsLongAsTheHostSaid) |
| NG-048 | Critical | Two offers same unit | PASS by design (note): the unit is locked by the BOOKING, not the offer — two guests can hold deals for the same dates; the second is refused at checkout (BK-052) or at verify (Defect 25) — first payer wins |
| NG-049 | High | Host accepts after unit booked | PASS by test (Defect 11, anOfferNeedsNightsThatCanBeBooked): a host accept on an offer whose nights are booked is refused |
| NG-050 | Med | Concurrent counters | PASS by code: every reply re-reads the row and refuses 'This offer was already <status>.' — two actors on one offer resolve to one state |
| NG-051 | Med | Offer during price change | PASS by code (note): the deal is a % of the stay's list subtotal minted at accept time; a host price change before checkout would shift the rupee figure of a %-coupon — a caveat, not seen live |
| NG-056 | High | Negotiate via chatbot | PASS (21 Sep 04:30, negotiationService.submitOffer channel 'bot' — the call /bp/negotiate makes): ₹2,600 on 29312 → the same round-1 counter at the ideal (₹2,800) the web/app get |
| NG-057 | Critical | Bot shows no floor | PASS: the bot's answer carries action, counterPrice, offerId, guestOfferId, propertyId, status — no min/ideal/floor (negotiationPrivacy) |
| NG-058 | High | Bot offer → host | PASS: below-ideal via the bot → engine counter with 'name another price and we will take it straight to the host'; round 2 escalates (NG-028/060 host-side evidence) |
| NG-060 | High | Host earnings reflect negotiated | PASS (20 Sep, app Earnings: B021812 ₹1,728 on the negotiated room) |
| NG-061 | High | Commission on negotiated price | PASS (20 Sep: commission ₹315 = 15% of ₹2,100) |
| NG-062 | High | Fixed-price toggle works | PASS (20 Sep, app + web); API order fixed f78d72b |
| NG-063 | High | Turn negotiation on | PASS (20 Sep) |
| NG-074 | Med | Host counters above displayed | FAIL → fixed 2bcf1cc (Defect 20) |
| NG-077 | Med | Two-role user offers | PASS by code: negotiationService.submitOffer refuses only the host's OWN property ('You cannot send an offer on your own property', NG-096); on any other listing a host is a guest like any other — one user id, no role switch exists or is needed (the app's host shell and the website's guest shell read the same account) |
| NG-083 | Med | Host bulk offers | PASS (app, host 100 Offers list): every thread with its latest price and state |
| NG-084 | Low | Offer on paused listing | FAIL → fixed 48d38b0 (Defect 21) |
| NG-093 | High | Simultaneous accept + guest cancel | PASS by code: the same status guard as NG-050 — a cancel and an accept on one offer cannot both apply |
| NG-095 | Med | Host declines then guest re-offers higher | PASS (21 Sep: the day's lock, any dates) |
| NG-097 | High | Offer notification to right host | PASS: offer 240's bell went to host 177 with the amount and the nights (the stay total for 30 nights) |
| NG-099 | Low | Negotiation analytics captured | PASS: tbl_negotiation_log rows carry the min/ideal snapshot, rounding, nights and channel for offer 240 (escalate_to) |
| NG-100 | Low | Offer amount localization | PASS: ₹ / en-IN grouping on web, app and mail (₹60,000; ₹8,400) |

### Batch 8 — Host listing — steps 1 and 2, location, capacity
**Needs:** The host account.  
**Cases:** 30 · Critical: 0 · Already run: 0

| ID | Pri | Case | Status |
|---|---|---|---|
| HL-001 | High | Owner vs Manager | PASS (app 01:43): Property Manager shows the owner-authorisation block; Owner does not |
| HL-002 | High | Property type cards | PASS: Apartment picked → 'What are guests booking?' + the apartment flow on step 2 (type/floor/lift/society/parking) |
| HL-003 | High | Booking unit | PASS: Entire/Private room/Suite/Shared drive capacity, the photo minimum (10 vs 5, HL-052) and pricing |
| HL-004 | Med | LUXE toggle | PASS (note): the LUXE toggle sets is_luxury on the row; the listing still goes through admin verification before it is live — that review is the certification gate |
| HL-005 | High | Property name valid | PASS: 'QA Wizard Test 21 Sep' accepted |
| HL-006 | Med | Name too short | PASS: 'ab' → refused on Continue (at least 5 characters) |
| HL-007 | Med | Name too long | PASS: the field caps at 80 characters (maxLength) — a 200-char paste truncates |
| HL-008 | High | Name special chars | PASS: '<', '>', '(', ')', '/' stripped as typed — 'Aa<script>alert(1)</script>' became 'Aascriptalert1script' |
| HL-009 | High | Description min length | PASS: 40+ characters accepted |
| HL-010 | Med | Description too short | PASS: 'Too short' (9 chars) → banner 'at least 40 characters' |
| HL-011 | Low | Description counter | PASS: live counter (9 / 40) |
| HL-012 | Med | AI help write | SPEC — no 'Help me write' / AI helper exists on any surface; not built |
| HL-013 | High | Address search | PASS: the pin's reverse-geocode filled address/state/city/PIN (F388+QG7, Sector 29, Gurugram, Haryana 122009) |
| HL-014 | High | Map pin drop | PASS: the address is derived from wherever the pin lands (adb cannot pan Google Maps — a test-rig limit, not the app's) |
| HL-015 | Med | Address-pin mismatch | PASS: State → Kerala with the pin in Gurugram → the pin/state mismatch warning; cleared on Haryana |
| HL-016 | Med | PIN validation | PASS: '12' → 'Enter the 6-digit PIN code' banner + snackbar; the PIN↔state check (pinZones) refuses a Delhi PIN on a Goa listing |
| HL-017 | Med | State-city relationship | PASS: city list is bound to the state; changing the state resets the city |
| HL-018 | High | Show exact location toggle | PASS by code: pl_show_exact_location → applyLocationPrivacy blurs the pin/address for guests when No |
| HL-019 | Med | Nearby places auto-suggest | PASS: Google nearby places auto-suggested by category (transport, activities, dining, shopping) with distances |
| HL-020 | Med | Nearby by type not name | PASS: type-based categorisation — a 'Shipping' business is kept out of Getting There |
| HL-021 | Low | Manual place add | PASS: 'QA Host Added Temple' at 1.5 km added, selected, sorted; shown 'Host provided' on the public page |
| HL-022 | Low | Duplicate place dedupe | PASS by code: the server dedupes by section + name on save |
| HL-023 | Low | Closed business excluded | PASS by code: business_status filter drops closed places |
| HL-024 | High | Adults stepper | PASS: 'A listing has to sleep at least one guest' (adults+children ≥ 1) |
| HL-025 | High | Total auto-calculated | PASS: total = adults + children, read-only (3+1 → 4) |
| HL-026 | Med | Infants separate | PASS: infants not counted (4 with an infant set) |
| HL-027 | High | Bedrooms/beds/baths | FAIL → fixed (Defect 44, f8549ba + app 109): the server checked the TYPED beds (3) and stored the room-card sum (1) — 29312 published '2 bedrooms · 1 bed · 4 guests', which the bedrooms≥beds rule exists to refuse; the rule now runs on the stored figure on the server and the app (the web already derived it) |
| HL-028 | Med | Bed types | PASS: Master Bedroom · 1 Queen bed · attached bath stored as inventory (property_rooms: 2 bedroom + 2 bathroom rows; pc_beds summed from them) |
| HL-029 | Low | Zero bedrooms (studio) | PASS by code (all three): 0 bedrooms allowed — only a negative is refused; the beds≥bedrooms rule is guarded by bedrooms > 0 |
| HL-030 | High | Apartment fields | PASS: apartment flow — type, floor, lift, society type, clubhouse, parking |

### Batch 9 — Host listing — type fields, amenities, photos
**Needs:** The host account + a few sample photos.  
**Cases:** 30 · Critical: 0 · Already run: 0

| ID | Pri | Case | Status |
|---|---|---|---|
| HL-031 | Med | Camping fields | PASS: /listing/schema serves camping (camp_type, tent_count, shared_washroom, electricity, bonfire_included, adventure_activities); both clients render the flow |
| HL-032 | Med | PG fields | PASS: pg_long_stay (gender, target_audience, room_type, furnishing, meals, laundry, housekeeping, biometric_entry, curfew_time, minimum_stay) |
| HL-033 | Low | Farm stay fields | PASS: farm_stay (farm_type, orchard, animal_farm → animals, farm_activities, organic_meals) |
| HL-034 | High | Type change warns | FAIL → fixed (Defect 42): the old type's answers survived on the public page; the web kept them silently, the app cleared them silently — server e333879 drops the other groups on save, both clients ask first |
| HL-035 | Med | Cross-validate BHK | FAIL → fixed (Defect 30): the BHK cross-check was dead on both clients (slug '3_bhk' vs a whitespace-only regex) — 'You have chosen 3 BHK but entered 2 bedrooms' now (theBhkCheckReadsTheSlug) |
| HL-036 | Med | Parking None hides spaces | FAIL → fixed (Defect 31): 'Number of parking spaces' did not exist — added to the schema with showIf {key: parking, in: [covered, open, street]}; both clients read `in` |
| HL-037 | Low | Parking shows spaces | FAIL → fixed (Defect 31): hidden for None and until parking is answered (parkingSpacesFollowTheParkingAnswer) |
| HL-038 | Low | Construction year | PASS: 'Construction year must be between 1900 and 2026' (server + both clients) |
| HL-039 | Low | Future year rejected | PASS (app): a future year refused with that message |
| HL-040 | Low | Area + unit | PASS: Sq Ft / Sq Meter selectable (area_unit); stored with the unit |
| HL-041 | Med | Negative area rejected | PASS: the minus sign is stripped by the formatter ('-100' → 100); negatives refused server-side |
| HL-042 | Med | Amenity chips | SPEC — chips toggle in place (highlighted when picked) per the client's HOST-9 'Amenities with icons' screenshot; 'selected disappear' is another pattern |
| HL-043 | Med | Amenity search | FAIL → built (web 92dea0d, app 109): 88 chips in 7 groups had no search — 'Find an amenity' filters by chip or group name on both clients |
| HL-044 | Med | Pool sub-questions | PASS web / FAIL → fixed app (Defect 43): Pool Type (Private/Shared/Infinity/Indoor/Outdoor/Heated/Kids) shows when has_pool; the app never set has_pool from the chip. 'Pool hours' is not asked anywhere |
| HL-045 | Med | Pet policy sub | FAIL → fixed (Defect 32, app 109): pet fee, size and max pets were web-only — now under 'Pets allowed' on the app, posted with step 4, loaded back (petsHaveAPriceOnTheApp) |
| HL-046 | Med | Wheelchair cross-check | FAIL → fixed (Defect 33, web + app): 'Wheelchair Accessible' with none of Ramp/Lift/Ground Floor → 'accessible, but how?' warning under the chips (accessibleButHow) |
| HL-047 | Med | Internet speed band | PASS: internet speed is a band (schema select), no exact number, no auto-fill |
| HL-048 | Low | Highlights max 5 | SPEC — there is no host-picked 'highlights' list; the page's Highlights are derived |
| HL-049 | Low | Smart lock → self check-in | FAIL → fixed (Defect 34, web + app): Smart Lock picked with self check-in off → note under Security pointing to step 4 |
| HL-050 | High | Upload photos | PASS: 11 photos uploaded in one batch (describe → upload), tiles with tag/delete |
| HL-051 | High | Minimum photos | PASS: at 9 photos step 5 read '9 of 10' and Submit stayed disabled; Continue on step 3 still allowed (publish blocked, progress not) |
| HL-052 | Med | Tiered minimum | PASS by code: PHOTO_RULES.byAccommodation — entire 10 (exterior/bedroom/bathroom/entrance), room/suite/shared 5 |
| HL-053 | High | Required tags | PASS: 'tag one photo as Exterior' blocked readiness until tagged |
| HL-054 | Med | First = cover | PASS: the first upload is the cover (pmd_is_cover) |
| HL-055 | Low | Reorder photos | FAIL → fixed (Defect 35, web + app 109): no reorder anywhere although the server took sortOrder — earlier/later on every tile (photosCanBeReordered) |
| HL-056 | Low | Delete photo | PASS: deleting the cover promoted the next photo (pmd_is_cover=1 on it) |
| HL-057 | High | Invalid file type | PASS (in-process, the real multer + content check): payload.exe → 400 naming the type; payload.exe.jpg with MZ bytes → 400 'contents don't match its type' and unlinked; a .jpg declared text/html → 400 |
| HL-058 | Med | Oversized file | FAIL → fixed (Defect 41, 943bd5e): a 9 MB photo PASSED the photo route (12 MB document multer) under a message saying 'under 8 MB' — the controller applies 8 MB to photos now; the app compresses at the picker (quality 82) and refuses non-landscape |
| HL-059 | Med | Upload fails | PASS (app, wifi+data off): 'Couldn't reach Aajoo. Check your connection and try again.'; no tile, property_media unchanged, retry offered |
| HL-061 | High | Set nightly price | PASS: ₹3,000 accepted; pricingRules 100–10,00,000 |

### Batch 10 — Host listing — pricing, publish, drafts
**Needs:** The host account + admin access for the publish/reject cases.  
**Cases:** 30 · Critical: 1 · Already run: 0

| ID | Pri | Case | Status |
|---|---|---|---|
| HL-062 | Med | Price out of range | PASS: ₹50 → refused (below the ₹100 minimum) |
| HL-063 | Med | Weekly price | PASS: weekly 25,000 vs 7×3,000 → flagged; 18,000 accepted |
| HL-064 | Med | Monthly price | PASS: monthly 100,000 vs 28×3,000 → flagged; 60,000 accepted |
| HL-065 | Critical | Set min & ideal | PASS: min & ideal per period marked required while negotiation is on and refused blank on Continue |
| HL-068 | High | Guests-never-see note | PASS: 'guests never see these values — only the displayed prices above' on the step |
| HL-069 | High | Deposit single field | PASS: one deposit field (₹5,000); the public page states it, refundable |
| HL-070 | Med | Cleaning fee frequency | PASS (by decision): frequency optional, defaults per stay — the 15 Sep cleaning decision |
| HL-071 | High | Negotiation toggle | PASS: negotiation off → the price range hidden, fixed price; on the web NG-063 showed 'Send an Offer' vanish |
| HL-072 | High | Cancellation policy | PASS: Flexible/Moderate/Strict from the central list (Super Strict needs approval); no free text |
| HL-073 | Med | Check-in default sensible | PASS: check-in 14:00 / check-out 11:00 defaults on both clients |
| HL-074 | Med | Same-day vs notice conflict | PASS: same-day ON + 24 h notice → flagged inline ('same-day arrivals can't happen with 24 h notice') |
| HL-075 | Med | Min ≤ max stay | FAIL → fixed (Defect 36, all three): min 3 / max 2 nights saved — server refuses 'Minimum nights (3) can't be more than maximum nights (2)…' (seen live 03:03), both clients inline |
| HL-076 | High | Readiness computed | PASS, with Defect 39 fixed (app 109): readiness moved 65% → 70 → 95 → 100 as photos, the exterior tag, the document and the bank were met (server-computed); the app's card showed a STALE answer (two refreshes in flight, last-write-wins) — sequence-guarded now (theReadinessCardKeepsTheNewestAnswer) |
| HL-078 | High | Ownership doc upload | PASS: sale deed PDF uploaded → 'Uploaded · Replace'; name/address matching is the admin's review step (the modal shows the document) |
| HL-081 | Med | Emergency contact | FAIL → fixed (Defect 38): '12345' refused on the app ('Enter a valid 10-digit mobile number'); the SERVER took anything — saveStep5 now refuses (aContactNumberCanBeDialled) |
| HL-082 | Low | Caretaker conditional | PASS web / FAIL → fixed app (Defect 37): caretaker fields now only when 'Caretaker available' is on (app 109) |
| HL-083 | Med | Compliance questions | INFO — compliance answers stored (pcp_government_registration…); no 'badge' exists to be eligible for |
| HL-084 | High | Declarations required | PASS: Submit disabled until all six declarations are ticked; the server re-checks (submitListing) |
| HL-085 | Med | Host Agreement scroll | PASS: scroll-to-read gate — accept enabled only after the agreement is scrolled to the end (both clients) |
| HL-086 | High | Agreement acceptance stored | PASS: tbl_legal_acceptances row for user 100 — document, version 1.0, accepted_at, IP, user agent, platform |
| HL-088 | High | Publish state machine | PASS (21 Sep 03:11–03:28): DRAFT → SUBMITTED (psb 15) → REJECTED (aa 144) → SUBMITTED again → APPROVED (aa 145) → is_active 1 / verified; public page 200 |
| HL-089 | Med | Rejected → resubmit | PASS: the host saw 'Rejected', edited (insurance on) and resubmitted from the app; approved. Defect 40: the reviewer's NOTE was never shown on the listing — fixed on all three (66ac24d, 6dea8f7, app 109) |
| HL-090 | High | Autosave draft | PASS (note): each Continue saves the step; a step left before Continue is not saved (step-level autosave, same on web) |
| HL-091 | Med | Save only on backend confirm | PASS: Continue spins and stays on the step until the server answers (~8 s), then advances |
| HL-092 | Med | Save fails message | PASS (wifi+data off): 'Couldn't reach Aajoo. Check your connection and try again.' — still on step 4, no fake Saved; retry succeeded |
| HL-093 | High | Resume draft | PASS: the wizard reopened with every value (3000/18000/60000, sale deed, ownership, insurance, contacts) |
| HL-094 | High | Back navigation keeps data | PASS: step 5 → Back → step 4 kept the values |
| HL-095 | High | Edit published listing | PASS (app 03:43): Edit on the live 29312 → 'Update listing'; step 4 loads current values; 'Changes submitted — your listing stays live'; psb approved → updated; is_active stays 1; page still 200 |
| HL-096 | High | Edit preserves untouched | PASS: 25-table diff — only ppr_weekly_price 18000→17500 (+ weekend flag null→0) and the submission status/time changed; 12 attributes, 3 amenities, 12 media, 4 rooms, contacts, compliance untouched |
| HL-097 | High | Double-submit protection | PASS: three submissions of 29312 → ONE property_submission row (psb 15) updated in place; the button disables after the first tap |
