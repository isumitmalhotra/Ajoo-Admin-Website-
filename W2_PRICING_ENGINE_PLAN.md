# W2 — Pricing Engine Implementation Plan

For review before any code is written.
Source spec: `Aajoo Homes Pricing Architecture.pdf` · one approved deviation (yours):
**auto-accept threshold is IDEAL, not MINIMUM.**

---

## 1. What already exists vs the document

I read the pricing/negotiation code end to end and checked the live data. The honest
scorecard:

| Doc section | Requirement | Current state |
|---|---|---|
| §2/§3 three price levels | Min / Ideal / Max per period | **Partial.** Nightly tier exists: `property_price` (Max/list), `property_mini_price` (Min — set on 29,240 rows), `property_ideal_price` (**column exists, populated on 0 rows**). Weekly/monthly have ONE price each (`ppr_weekly_price` / `ppr_monthly_price`), no min/ideal tiers. |
| §4/§5 composite totals (12 nights = 1 week + 5 nights, per tier) | **Different by design.** Current code prices long stays as an *effective nightly rate* — a 9-night stay gets `weeklyPrice/7 × 9`, deliberately avoiding the price cliff at 7 nights. The doc's method is period + remainder at each tier. **Conflict — see Q1.** |
| §6 guest sees only Max | ✅ Already enforced. The service comment says it in words: "Never contains the minimum or the ideal price — spec rule 3." I'll add a test pinning it. |
| §7 auto-accept engine | ✅ Exists and is *good*: a pure, unit-tested `decideOffer()` (no DB, no clock), one shared `negotiationService.submitOffer` used by REST, socket chat **and** the BotPenguin bot — so all channels answer identically. Currently: `offer ≥ min → accept`. |
| §8 below-threshold → host Accept/Counter/Decline | ✅ Exists (escalate path, host respond endpoints, expiry service). |
| §9 negotiated price becomes the booking price | ✅ Exists via a high-precision percentage coupon minted on accept; checkout recomputes server-side. |
| §10–§12 Advance Booking (no negotiation, discount, 10% deposit) | ❌ **Does not exist at all.** (But the balance-payment infra it needs — `createPaymentOrderOngoingBooking` — already exists, which shrinks the work.) |
| §15 UI never computes the final price | **Partial.** Booking creation is server-authoritative (client price is clamped to the server quote). But the property page still *displays* a client-computed breakdown. |
| §16 validation list | Mostly present in `bookingCreate` (dates, availability, price clamp, party fee). |
| §17 rule 8 "no Minimum → negotiation OFF" | ✅ Exists (engine rule 5, `UNAVAILABLE`). |
| §17 rule 9 every event logged with pricing snapshot | ✅ Exists (`tbl_negotiation_log` carries min/ideal/max snapshot per event). |

**Two data facts that shape the plan:**
- `property_ideal_price` is empty everywhere → the engine already computes a fallback
  ideal = **midpoint(min, max)**. Under your new rule, that midpoint becomes the live
  auto-accept threshold wherever the host hasn't set an ideal. (Reasonable — flagging
  it so it's a decision, not a surprise.)
- Only 12 listings have wizard pricing rows (weekly/monthly prices); everything else
  is nightly-only, where composite = simple multiplication anyway.

---

## 2. The changes, in five phases

### Phase A — Schema: the 9-value grid `(migration, additive)`

Per period the doc wants Min/Ideal/Max. Mapping onto what exists rather than
rebuilding:

| | Night | Week | Month |
|---|---|---|---|
| **Max (list)** | `property_price` / `ppr_base_price` ✅ | `ppr_weekly_price` ✅ | `ppr_monthly_price` ✅ |
| **Min** | `property_mini_price` ✅ | `ppr_weekly_min` **new** | `ppr_monthly_min` **new** |
| **Ideal** | `property_ideal_price` ✅ | `ppr_weekly_ideal` **new** | `ppr_monthly_ideal` **new** |

- 4 new nullable DECIMAL columns on `property_pricing`. No backfill script:
  **when a weekly/monthly min or ideal is null, it is derived by scaling the period's
  Max by the nightly ratio** (`weeklyMin = weeklyMax × min/max`). Hosts who care set
  exact numbers; everyone else gets proportionally consistent tiers automatically.
- Wizard **Step 4** gains the four fields (shown only when negotiation is enabled,
  validated `min ≤ ideal ≤ max` per period — same rule the nightly tier already has).

### Phase B — One pricing engine `utils/pricingEngine.js` (new, pure)

The doc's §19 principle: *one engine, two experiences*. A single pure function:

```
quoteStay({ rule, from, to, guests }) →
  { nights,
    composition: [{ unit: month|week|night, count, ... }],
    totals: { min, ideal, max },        // internal
    list:   { subtotal, perNightAvg, extraGuestFee, breakdownLines },  // public
  }
```

- Composite decomposition **exactly as §5**: months first, then weeks, then remainder
  nights, each priced at that period's tier value (subject to Q1 below).
- Weekend pricing keeps applying to the *remainder nights only* (the week/month
  package price already prices its own days — charging weekend uplift inside a
  package would double-charge).
- Extra-guest fees, unchanged, applied on top of the list total (they are a fee, not
  a tier).
- Min/Ideal totals **never leave the server**. The public quote endpoint returns only
  the `list` block.
- Every existing consumer (`bookingCreate` clamp, negotiation, the new quote
  endpoint) calls this one function — deleting the current scattered math.

**New public endpoint** `POST /pricing/quote` `{propertyId, from, to, guests, mode}`
→ the list-price breakdown. This is §15: the property page and checkout render the
backend's numbers instead of computing their own.

### Phase C — Negotiation: your ideal-threshold rule `(the approved deviation)`

`decideOffer()` changes from the doc's rule to yours:

| Condition | Doc said | **Implemented (your correction)** |
|---|---|---|
| offer ≥ ideal | accept | **ACCEPT automatically** (at the offered price) |
| min ≤ offer < ideal | accept | **ESCALATE to host** (Accept / Counter / Decline) |
| offer < min | escalate | **ESCALATE to host** — same path; the host's card will show whether the offer clears their floor, so they can decide in one glance |
| no minimum set | negotiation off | unchanged — negotiation OFF (rule 8) |
| no ideal set | — | ideal = midpoint(min, max), as the engine already computes |

- **Dated offers** (offer carries check-in/out — the normal website flow) are compared
  against the **ideal TOTAL for those dates** from Phase B's engine, per the doc's
  worked example. Undated chat offers keep comparing per-night against the per-night
  ideal (nothing else is possible without dates).
- Applies to **new offers only** — the decision is made at submit time; the 38
  historical offers are untouched.
- Everything downstream is unchanged: acceptance → coupon → checkout; escalation →
  host inbox → respond; expiry; the full log snapshot (which already records ideal on
  every row — that history is about to become load-bearing, and it's already there).

### Phase D — Advance Booking `§10–§12 (the big new piece)`

A second booking *experience* on the same engine:

- `mode: "advance"` on quote + booking create. **No negotiation surface at all** in
  this mode.
- **Discount**: new `ppr_advance_discount` (percent) on `property_pricing`, with a
  platform-wide default in admin Global settings (so it works before hosts set one).
  Applied to the list total. *(Q3: who controls the % — see questions.)*
- **10% deposit, computed AFTER the discount** (the doc is explicit about the order).
  Booking is created in the existing payment-pending → deposit-paid flow;
  `book_wallet_amt` + the existing ongoing-payment order endpoint already handle
  balance collection, so the remaining 90% reuses `createPaymentOrderOngoingBooking`.
- UI per §12: Original price → discount line → final price → "Pay 10% now" →
  remaining. All five numbers from the quote endpoint, never computed client-side.
- Cancellation/refund of a deposit-stage booking follows the existing policy engine
  against the *deposit actually paid* (refund can never exceed money received).

### Phase E — Frontend + tests + verification

- **PropertyDetail / checkout**: replace the client-side breakdown with the quote
  endpoint (booking mode selector where advance is offered: real-time vs future
  dates). Falls back to current display if the endpoint errors — a quote outage must
  not blank the price.
- **Step 4 wizard**: the four new tier fields + advance discount field.
- **Tests**: the doc's own worked example becomes literal test vectors —
  `night 4000/5000/6000, week 25000/28000/32000, 12 nights → 45,000 / 53,000 / 62,000`
  — plus: ideal-threshold decision table (≥ideal, between, <min, no-min, no-ideal→midpoint);
  a pinned "min/ideal never appear in any guest-facing payload" test (greps every
  response builder); deposit = 10% of *discounted* total; composite + weekend
  interaction.
- **Live verification** like W4: quote a real listing, check the 12-night example on
  a seeded test property, submit above-ideal and between-min-and-ideal offers on a
  test property, prove the first auto-accepts and the second lands in the host inbox.

---

## 3. Questions to settle in your review

**Q1 — The pricing method conflict (only real design decision).**
The doc prices 12 nights as `1 week + 5 nights` (₹25,000 + ₹20,000 = ₹45,000 min).
The current code instead uses an effective nightly rate for the whole stay,
*specifically to avoid the cliff* where 7 nights (₹25,000) costs less than 6 nights
(₹24,000 at ₹4,000/night — fine) but e.g. weekly ₹25,000 vs 6×4,000=₹24,000 means
night 7 costs ₹1,000 — and depending on the host's numbers, a longer stay can cost
*less* than a shorter one.
**Plan default: doc-exact composite** (you said "exactly as mentioned"), and where a
host's numbers make N+1 nights cheaper than N, we charge the cheaper composition
(the guest never pays more for staying fewer nights — standard practice and surely
the doc's intent). Confirm, or keep the current smoothing.

**Q2 — Offers below the host's minimum.** Your rule sends everything below ideal to
the host. I'm treating below-min the same (host sees it, with a "below your floor"
marker) rather than auto-rejecting. `pn_auto_reject_below` exists in the wizard table
if you'd rather hard-reject below some bound — say the word.

**Q3 — Advance Booking discount ownership.** Per-property (host sets in Step 4) with
a platform default from admin Global settings is my plan. Alternative: platform-only.
Also confirm Advance Booking is in *this* release — it's the largest phase (D), and
striking it removes ~40% of the work without touching A–C.

**Q4 — Deposit percent.** Doc says 10%. Hardcoded constant, or admin-configurable?
Plan default: a config value seeded at 10%, changeable without a deploy.

**Q5 — Existing behaviour change to flag to your tester.** The moment Phase C ships,
offers between min and ideal stop auto-accepting and appear in host inboxes instead.
With ideal unset everywhere, threshold = midpoint(min, max). Any offer-flow test
scripts they have will see the new behaviour.

---

## 4. Order of work & scale

A (schema) → B (engine + quote endpoint) → C (threshold) → E-tests as I go → D
(advance) → E-frontend → live verification. B and C land together as one deploy so
the engine never half-exists. Roughly: A+B+C ≈ one solid session, D ≈ another,
E-frontend ≈ half. Each phase ships with its tests and the same live verification
discipline as W0/W1/W4.

**Nothing breaks in between:** until Phase E's frontend lands, guests keep seeing the
same client-rendered prices; the server clamp simply gets stricter and the
negotiation threshold changes (Q5). All schema is additive with null-fallbacks.
