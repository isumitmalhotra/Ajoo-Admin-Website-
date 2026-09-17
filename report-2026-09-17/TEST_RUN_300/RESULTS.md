# Aajoo — 300 Manual Test Cases: Execution Report

**Source:** `Aajoo-300-Manual-Test-Cases.docx` (client, v1.0) — BK-001…100 Booking · NG-001…100 Negotiation · HL-001…100 Host Listing
**Run started:** 17 September 2026 · **Environment:** `aajaodev.onrender.com` (dev API), `www.aajoohomes.com` (web), Android build 100 (emulator)
**This file is updated after every batch.** Nothing is marked PASS without a recorded actual value.

---

## Running totals

| | Cases | PASS | FAIL | BLOCKED | Not yet run |
|---|---|---|---|---|---|
| **BK — Booking** | 100 | 0 | 2 | 5 | 93 |
| **NG — Negotiation** | 100 | 0 | 1 | 0 | 99 |
| **HL — Host Listing** | 100 | 0 | 0 | 0 | 100 |
| **Total** | **300** | **0** | **3** | **5** | **292** |

Three cases were run to a verdict and all three **failed** — which is the point of running the Critical set first. Five more were attempted and are BLOCKED on my own harness, not on the product. The two defects behind the three failures are fixed.

**Defects found so far: 2 — both Critical, both security, both now fixed and pinned by tests.**

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

## Batch plan

| Batch | Contents | Status |
|---|---|---|
| **1** | Critical price privacy + money integrity, no login | **Done** — 2 Critical defects found and fixed |
| 2 | Pricing maths BK-011…014, BK-021 against the real quote schema; NG engine bands NG-006/007/008 by API | Next |
| 3 | Security and ownership: BK-079, HL-098, HL-099, NG-091, BK-082 | Needs a token |
| 4 | Booking and payment flow, web + app | Needs test accounts |
| 5 | Host listing wizard HL-001…100 | Needs a host account |
| 6 | The remaining High / Med / Low across all three suites | After the above |
