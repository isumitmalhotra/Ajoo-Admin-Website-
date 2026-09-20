# Aajoo — 300 Manual Test Cases: Execution Report

**Source:** `Aajoo-300-Manual-Test-Cases.docx` (client, v1.0) — BK-001…100 Booking · NG-001…100 Negotiation · HL-001…100 Host Listing
**Run started:** 17 September 2026 · **Environment:** `aajaodev.onrender.com` (dev API), `www.aajoohomes.com` (web), Android build 100 (emulator; **build 106 from 20 September**)
**This file is updated after every batch.** Nothing is marked PASS without a recorded actual value.

---

## Running totals

| | Cases | PASS | FAIL | SPEC CONFLICT | BLOCKED | INFO | Not yet run |
|---|---|---|---|---|---|---|---|
| **BK — Booking** | 100 | 23 | 5 | 1 | 2 | 1 | 68 |
| **NG — Negotiation** | 100 | 23 | 2 | 2 | 0 | 0 | 73 |
| **HL — Host Listing** | 100 | 4 | 0 | 0 | 0 | 0 | 96 |
| **Total** | **300** | **50** | **7** | **3** | **2** | **1** | **237** |

**Batches 1 and 2 are complete; batch 3 is in progress: 63 of 300 run.** Batches 3–10 are blocked on sign-ins — see *What is needed to unblock the rest*.

**Defects found: 5.** Four fixed and pinned by tests (two Critical security leaks, a festival rate silently dropped, an accepted negotiation missing from the ledger). One reported for the client's decision because it moves money (the 28–31 night pricing cliff).

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

## Batch 3 — IN PROGRESS (3/30) · Security, ownership and rejected input

**Run 20 September 2026** against the live dev API, by direct request. Only the cases that need **no account** were run: every other case in this batch needs a guest or host token, and the two sessions available on this machine that day were the client's own — host 100 in Chrome, guest 101 on the emulator — which rule §9 says are never to be driven, even for a refusal (a validation case that unexpectedly *succeeds* would create data on the client's account, which is how the earlier "test deal on 101" report happened).

| ID | Case | What was sent | Actual | Verdict |
|---|---|---|---|---|
| BK-033 | Book without login | `POST /booking/create` with a body that passes validation (property 29306, 25→26 Sep, ₹2,000, 2 guests), **no token** | `401 {"success":false,"message":"Authorization token is required"}` — nothing created | **PASS** |
| BK-083 | Auth required | `GET /user/booking-history` with no token; and `POST /booking/create` with a garbage bearer token | `401 "Authorization token is required"`; `401 "invalid token"` | **PASS** |
| NG-043 | Offer without login | `POST /user/negotiations/offer` (property 29306, ₹1,500, 25→26 Sep), **no token** | `401 "Authorization token is required"` — nothing created | **PASS** |

**Observation (not a defect, recorded):** `/booking/create` validates the body *before* checking the token, so an unauthenticated call with an incomplete body is answered `422` with the missing fields rather than `401`. No data is created either way and a complete body meets the auth wall; the order only means an anonymous caller can learn the field names, which the public API documentation already shows.

**The remaining 27** (BK-026…032, 034…037, 079, 082; NG-039…042, 090, 091, 094, 096; HL-077, 079, 080, 098…100) run the moment a guest we own (179 "Renter test web") and a host we own (194, or 177 "Host Mobile") are signed in — web in Chrome, app on the emulator (build 106 installed 20 Sep).

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
**Cases:** 30 · Critical: 8 · Already run: 3

| ID | Pri | Case | Status |
|---|---|---|---|
| BK-026 | High | No dates selected |  |
| BK-027 | High | Check-out before check-in |  |
| BK-028 | High | Past date |  |
| BK-029 | Med | Zero guests |  |
| BK-030 | High | Guests over capacity |  |
| BK-031 | High | Below min stay |  |
| BK-032 | Med | Above max stay |  |
| BK-033 | High | Book without login | PASS (20 Sep) |
| BK-034 | Critical | Book without KYC |  |
| BK-035 | Critical | Empty guest details |  |
| BK-036 | Med | Invalid phone |  |
| BK-037 | Med | Invalid email |  |
| BK-079 | Critical | See only own bookings |  |
| BK-082 | Critical | Tampered price rejected |  |
| BK-083 | High | Auth required | PASS (20 Sep) |
| NG-039 | High | Zero offer |  |
| NG-040 | High | Negative offer |  |
| NG-041 | Med | Non-numeric offer |  |
| NG-042 | High | Offer on fixed-price listing |  |
| NG-043 | High | Offer without login | PASS (20 Sep) |
| NG-090 | Med | Screenshot/replay attack |  |
| NG-091 | Critical | Tampered offer price |  |
| NG-094 | Med | Offer with expired session |  |
| NG-096 | Med | Guest offers on own listing |  |
| HL-077 | High | Identity linked |  |
| HL-079 | Critical | Bank details save |  |
| HL-080 | High | Bank shown last-4 |  |
| HL-098 | Critical | Host edits own only |  |
| HL-099 | Critical | Host sees own listings only |  |
| HL-100 | High | Docs access-controlled |  |

### Batch 4 — Booking — create, confirm, availability, after the stay
**Needs:** The guest account. Creates real test bookings on dev.  
**Cases:** 30 · Critical: 3 · Already run: 0

| ID | Pri | Case | Status |
|---|---|---|---|
| BK-022 | Critical | Confirmation created |  |
| BK-023 | High | Confirmation email/app |  |
| BK-024 | High | Host notified |  |
| BK-025 | High | Booking ID generated |  |
| BK-048 | Med | Currency correct |  |
| BK-049 | Med | Tax shown |  |
| BK-054 | High | Blocked dates unbookable |  |
| BK-055 | High | Availability calendar accurate |  |
| BK-056 | Med | Booking horizon |  |
| BK-057 | Med | Minimum notice |  |
| BK-058 | Med | Same-day conflict |  |
| BK-071 | High | My Bookings list |  |
| BK-072 | High | Booking detail accurate |  |
| BK-073 | Med | Ongoing stay shown |  |
| BK-074 | High | Invoice download |  |
| BK-075 | Med | Modify booking |  |
| BK-076 | High | Check-in details |  |
| BK-077 | Med | Host contact revealed |  |
| BK-078 | Med | Review after stay |  |
| BK-085 | Critical | Negotiated price used |  |
| BK-086 | Critical | Auto-accept → booking |  |
| BK-087 | Med | Guest count feeds capacity |  |
| BK-088 | High | Price change reflects |  |
| BK-089 | High | Deposit single-source |  |
| BK-093 | High | Instant vs approval |  |
| BK-094 | Med | Approval timeout |  |
| BK-096 | Med | Coupon applied |  |
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
**Cases:** 30 · Critical: 0 · Already run: 0

| ID | Pri | Case | Status |
|---|---|---|---|
| NG-016 | High | Make an Offer button |  |
| NG-017 | High | Offer input validates |  |
| NG-018 | High | Offer confirmation |  |
| NG-019 | High | Offer status visible |  |
| NG-020 | High | Counter shown to guest |  |
| NG-022 | High | Real-time update |  |
| NG-023 | Med | Offer thread readable |  |
| NG-024 | Med | Mobile negotiation UI |  |
| NG-025 | Med | Waiting state |  |
| NG-034 | High | Guest counters back |  |
| NG-035 | Med | Multiple rounds |  |
| NG-036 | High | Guest accepts counter |  |
| NG-037 | Med | Guest declines counter |  |
| NG-038 | Low | Round limit |  |
| NG-044 | Med | Offer on unavailable dates |  |
| NG-045 | Low | Offer after booking |  |
| NG-046 | High | Offer expiry |  |
| NG-071 | Med | Rapid repeat offers |  |
| NG-072 | Low | Offer then cancel |  |
| NG-073 | Low | Guest edits offer before submit |  |
| NG-075 | Med | Negotiate weekly then book nightly |  |
| NG-076 | Low | Offer on LUXE listing |  |
| NG-078 | Med | Offer notification failure |  |
| NG-079 | Low | Currency in offer |  |
| NG-080 | Med | Session lost mid-negotiation |  |
| NG-081 | Med | Accept exactly at expiry |  |
| NG-082 | Low | Guest offers after decline |  |
| NG-088 | Low | Offer history after booking |  |
| NG-089 | Med | Language in negotiation |  |
| NG-092 | Med | Offer for 0 nights |  |

### Batch 7 — Negotiation — the host side, timing, bot, cross-flow
**Needs:** Host account + guest account together; BotPenguin for NG-056..058.  
**Cases:** 30 · Critical: 3 · Already run: 0

| ID | Pri | Case | Status |
|---|---|---|---|
| NG-015 | High | Monthly negotiation |  |
| NG-021 | High | Accept/decline buttons (host) |  |
| NG-026 | High | Host notified of offer |  |
| NG-027 | High | Host notified of auto-accept |  |
| NG-028 | Critical | Host accepts |  |
| NG-029 | High | Host counters |  |
| NG-030 | High | Host declines |  |
| NG-031 | Med | Host ignores → expiry |  |
| NG-032 | High | Host sees offer amount |  |
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
