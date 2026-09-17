# Aajoo — 300 Manual Test Cases: Execution Report

**Source:** `Aajoo-300-Manual-Test-Cases.docx` (client, v1.0) — BK-001…100 Booking · NG-001…100 Negotiation · HL-001…100 Host Listing
**Run started:** 17 September 2026 · **Environment:** `aajaodev.onrender.com` (dev API), `www.aajoohomes.com` (web), Android build 100 (emulator)
**This file is updated after every batch.** Nothing is marked PASS without a recorded actual value.

---

## Running totals

| | Cases | PASS | FAIL | SPEC CONFLICT | BLOCKED | Not yet run |
|---|---|---|---|---|---|---|
| **BK — Booking** | 100 | 4 | 3 | 0 | 1 | 92 |
| **NG — Negotiation** | 100 | 1 | 1 | 2 | 0 | 96 |
| **HL — Host Listing** | 100 | 0 | 0 | 0 | 0 | 100 |
| **Total** | **300** | **5** | **4** | **2** | **1** | **288** |

**Defects found: 3.** Two Critical security leaks (fixed, pinned). One money defect where a shorter stay can cost more than a longer one — reported, not silently changed, because it moves money.

**Spec conflicts: 2.** Two negotiation cases describe behaviour the client themselves changed after the document was written. The product is right; the document is stale.

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

## Batch 1 — Critical: price privacy and money integrity

**Run 17 September 2026.** Chosen because every case here is provable against the live API with no login and without writing anything to any account.

### Results

| ID | Area | Case | Result | Actual value seen |
|---|---|---|---|---|
| **BK-080** | Security | Host minimum/ideal price never visible | **FAIL → fixed** | `GET /properties/29291` returned `pricing.nightlyMin 1500`, `nightlyIdeal 1700`, `weekendIdeal 2300`, `weeklyIdeal 11000`, `monthlyIdeal 37000` — unauthenticated |
| **NG-003** | Privacy | Min/ideal not in API | **FAIL → fixed** | Same payload. Same root cause |
| **BK-081** | Security | No bank / KYC / internal data leak | **FAIL → fixed** | `POST /properties/search` returned `property_contact "9876543210"` — the host's phone, unauthenticated, on a lat/long endpoint |
| BK-011 | Logic | Book 1 night | BLOCKED | Quote endpoint rejected the harness payload (HTTP 422). Re-run in batch 2 against the real schema |
| BK-012 | Logic | Book 5 nights | BLOCKED | As above |
| BK-013 | Logic | Book a weekly stay | BLOCKED | As above |
| BK-014 | Logic | Book a monthly stay | BLOCKED | As above |
| BK-082 | Security | Tampered price rejected | BLOCKED | Harness used a wrong path (404). Needs an authenticated session to test properly |

> The four BLOCKED pricing cases and BK-082 are **harness faults, not product faults** — recorded honestly rather than counted as passes or failures. They move to batch 2.

---

## Batch 2 — Critical: the money maths and the negotiation engine's bands

**Run 17 September 2026.** Quotes taken from the live API and checked against ground truth read from `property_pricing` for property 29291: base ₹2,000/night, weekend pricing on (Fri/Sat/Sun ₹2,500), weekly package ₹12,000, monthly package ₹40,000, deposit ₹5,000.

*(Batch 1's five BLOCKED cases were my harness sending `from`/`to` instead of `bookFrom`/`bookTo`. Corrected and re-run here.)*

### Results

| ID | Case | Result | Actual value seen |
|---|---|---|---|
| **BK-011** | Book 1 night = 1 × nightly | **PASS** | ₹2,000 for one weekday night |
| **BK-012** | Book 5 nights = 5 × nightly | **PASS** | ₹10,500 — correctly 4 weekday × ₹2,000 + 1 weekend × ₹2,500, not 5 × ₹2,000 |
| **BK-013** | 7 nights charged as the weekly package | **PASS** | ₹12,000 (the package), not ₹15,500 (the per-night sum) |
| **BK-014** | 28 nights = monthly package + deposit shown | **FAIL** | ₹48,000, charged as 4 weekly packages. See defect 3 |
| **BK-021** | Charge = quote | **PASS** (partial) | Parts reconcile: subtotal ₹10,500 + taxes ₹525 = grandTotal ₹11,025. A full charge-equals-quote proof needs a real payment |
| **NG-006** | Offer ≥ ideal auto-accepts | **PASS** | ₹1,700 → `accept` at ₹1,700; ₹1,900 → `accept` at ₹1,900 |
| **NG-007** | Offer between min and ideal → host | **SPEC CONFLICT** | ₹1,600 → `auto_counter` at ₹1,700, not escalation |
| **NG-008** | Offer below minimum → host, flagged | **SPEC CONFLICT** | ₹1,200 → `auto_counter` at ₹1,750 with `belowFloor: true` |

Also confirmed in passing: an offer **above** the list price is rejected (`above_list_price`), which is correct.

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

## Spec conflicts — the case sheet is behind the product

Neither of these is a defect. Both describe behaviour the client **changed after the document was written**, and they are recorded so the document can be corrected rather than the code.

**NG-007 — "offer between min and ideal → sent to host".** The engine instead answers instantly with a counter at the host's target. That is the "instant counter" the client signed off: it fires on **round one only**, and a guest who counters the counter is escalated to a person. The case describes the design before that feature existed.

**NG-008 — "offer below minimum → reaches host marked below minimum".** The engine counters this too, at ₹1,750, flagging `belowFloor: true` internally. Also deliberate: *"an offer under the floor is countered too, not refused (client, 2026-09-09)"* — the floor is an internal number the guest was never shown, so the counter answers rather than refuses.

> **Both should be re-worded in the case document**, or the client should tell us the engine is wrong. Worth noting that NG-008's counter at ₹1,750 sits **above** the ideal of ₹1,700 — which is exactly the counter-pricing question already put to the client in `AAJOO_NEGOTIATION_DECISIONS_2026-09-17.pdf`.

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

## Fixes made in this run

| Commit | What |
|---|---|
| `656f6df` | `getProperty` strips the min/ideal tier grid for non-owners; `/properties/search` stops selecting `property_contact`; `tests/theHostsFloorIsNotPublic.test.js` adds 5 assertions pinning both doors, including that the host still sees their own figures. 148/148 backend tests pass |

---

## What is needed to unblock the rest

1. **A guest test account we own, with a password held by the client**, so booking, payment and negotiation cases can be driven without touching accounts 101/100. Roughly **120 of the 300** cases create data and need this.
2. **A host test account on the same basis**, for the 100 HL listing cases.
3. **A test payment method** for the BK payment cases (BK-038…BK-049).
4. Confirmation that the **dev environment** is the right target, and that test bookings there are acceptable.

---

## The ten batches

Thirty cases each, grouped by **what unblocks them** and ordered so the earliest batches need the least. Every one of the 300 is in exactly one batch (validated by script).

| Batch | Theme | Needs from the client | Cases | Critical |
|---|---|---|---|---|
| 1 | Booking — public page and pricing maths | **Nothing** | 30 | 8 |
| 2 | Negotiation — privacy and engine; backend price rules | **Nothing** | 30 | 10 |
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
**Cases:** 30 · Critical: 8 · Already run: 0

| ID | Pri | Case | Status |
|---|---|---|---|
| BK-026 | High | No dates selected |  |
| BK-027 | High | Check-out before check-in |  |
| BK-028 | High | Past date |  |
| BK-029 | Med | Zero guests |  |
| BK-030 | High | Guests over capacity |  |
| BK-031 | High | Below min stay |  |
| BK-032 | Med | Above max stay |  |
| BK-033 | High | Book without login |  |
| BK-034 | Critical | Book without KYC |  |
| BK-035 | Critical | Empty guest details |  |
| BK-036 | Med | Invalid phone |  |
| BK-037 | Med | Invalid email |  |
| BK-079 | Critical | See only own bookings |  |
| BK-082 | Critical | Tampered price rejected |  |
| BK-083 | High | Auth required |  |
| NG-039 | High | Zero offer |  |
| NG-040 | High | Negative offer |  |
| NG-041 | Med | Non-numeric offer |  |
| NG-042 | High | Offer on fixed-price listing |  |
| NG-043 | High | Offer without login |  |
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
