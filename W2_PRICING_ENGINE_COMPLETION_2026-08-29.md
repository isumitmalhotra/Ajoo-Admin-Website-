# W2 — Pricing Engine & Booking Payments: what shipped

Source spec: `Aajoo Homes Pricing Architecture.pdf`
Two approved deviations from the document, both yours:

1. **Auto-accept threshold is the IDEAL, not the minimum.**
2. **Every booking offers both payment options** — pay in full, or pay 10% now
   and settle the balance before check-in. (The document scoped the deposit to
   Advance Booking only.)

Status: **A, B, C and D shipped and live.** 19/19 backend test files pass;
frontend `tsc -b` and production build clean. Two migrations applied to the
live database.

---

## 1. The nine-value pricing grid (Phase A)

Per period the host now has three figures: what they will not go below, what
they want, and what a guest is shown.

| | Night | Week | Month |
|---|---|---|---|
| **Max (the list price — the only one a guest ever sees)** | `property_price` | `ppr_weekly_price` | `ppr_monthly_price` |
| **Ideal (the auto-accept threshold)** | `property_ideal_price` | `ppr_weekly_ideal` *(new)* | `ppr_monthly_ideal` *(new)* |
| **Min (the floor)** | `property_mini_price` | `ppr_weekly_min` *(new)* | `ppr_monthly_min` *(new)* |

Plus `ppr_advance_discount` for a per-property pre-booking discount.

**Nothing needed a backfill.** A weekly or monthly Min/Ideal that a host has not
set is derived at quote time by scaling that period's Max by the nightly ratio
(`weeklyMin = weeklyMax × nightlyMin / nightlyMax`). Every listing gets
proportionally consistent tiers the moment this shipped; a host who wants exact
control sets them in Step 4.

`property_ideal_price` is empty on every listing today, so the live auto-accept
threshold is **the midpoint of the minimum and the list price** — the same
default the engine has recorded on every log row since the feature existed.

---

## 2. Composite pricing (Phase B)

**What changed:** long stays used to be smoothed — a 9-night stay was charged
`weeklyPrice ÷ 7 × 9`. The document prices them as packages plus remainder, and
that is now what happens.

A stay decomposes greedily: months (28 nights), then weeks (7), then the
nights left over, each priced at the host's figure for that period.

**The document's own worked example, now computed exactly:**

> night 4,000 / 5,000 / 6,000 · week 25,000 / 28,000 / 32,000 · **12 nights**
> → 1 week + 5 nights
> → Min **₹45,000** · Ideal **₹53,000** · Max **₹62,000**

Those three numbers are a literal test vector in `tests/pricingEngine.test.js`.

**Guards that survive:**

- A stay is never quoted more than pricing every night at the plain nightly
  rate. A host whose weekly price exceeds seven nights' worth has made a
  mistake, not set a premium — the wizard refuses it now, but legacy rows exist.
  When that guard bites, Min and Ideal scale down with it, so `min ≤ ideal ≤ max`
  cannot invert.
- Weekend uplift applies to the **remainder nights only**. A week package
  already prices its own days; upliftng inside it would charge the same
  Saturday twice.
- Extra-guest fees ride on top of the list total. They are a fee, not a tier.

**Min and Ideal never leave the server.** They come back from the engine under
an `internal` block that no response builder touches, and
`tests/pricingQuote.test.js` fails the build if the quote controller ever
mentions it.

### New endpoint — `POST /pricing/quote`

Public, rate-limited, validated. Body: `{ propertyId, bookFrom, bookTo, guests }`
with dates as **DD-MM-YYYY** (the same format the booking endpoint enforces).

Live response for property 29262, 12 nights:

```json
{ "nightCount": 12,
  "composition": { "months": 0, "weeks": 1, "nights": 5 },
  "lines": [ { "unit": "week",  "count": 1, "each": 30000, "amount": 30000 },
             { "unit": "night", "count": 5, "amount": 29000 } ],
  "subtotal": 59000, "nightlyTotal": 68000, "saving": 9000,
  "extraGuestFee": 0, "total": 59000 }
```

This is §15 of the document — "the UI never computes the final price". The
figures come from the same `quoteRange` that `bookingCreate` later insists on,
so what a guest is shown and what the server will accept cannot be two
different numbers.

---

## 3. Negotiation: the ideal threshold (Phase C)

| What the guest offers | Before | **Now** |
|---|---|---|
| Above the list price | accepted at the offer | **Refused** — "that is above the listed price, you can simply book" |
| At or above the **ideal** | accepted (if ≥ min) | **Accepted automatically**, at the offered price |
| Between min and ideal | accepted automatically | **Goes to the host** — accept / counter / decline |
| Below the minimum | goes to the host | **Goes to the host**, flagged as below their floor |
| No minimum set | negotiation off | unchanged — negotiation off |

**The above-list refusal is now enforced server-side.** The web form had the
same check, but only in the browser; an API call skipped it entirely.

**Dated offers are judged against the composite tiers for those exact dates.**
A per-night offer on a 12-night stay competes with the week-plus-nights price
divided back to per-night, not with the flat nightly column — the document's
own example. An undated chat offer keeps using the flat columns, because
nothing else exists without dates. The negotiation ledger snapshots the tiers
the decision actually used, so a row can never explain itself with figures the
engine did not see.

The host's escalation email now distinguishes the two cases: "below your target
price (but above your minimum)" reads differently from "below the minimum you
set", and the host sees which before deciding.

**One behaviour change for your tester:** offers between the minimum and the
ideal used to auto-accept and now appear in host inboxes. With no host having
set an ideal, that threshold is the midpoint of their minimum and their nightly
rate.

---

## 4. Pay 10% now, or pay in full (Phase D)

Both options on **every** booking, as you specified.

### What the guest sees

At checkout, three tiles:

- **Pay in full — ₹X** · confirmed outright, as today.
- **Pay 10% now — ₹Y** · confirms the booking; the remaining ₹Z is due any time
  before check-in.
- **Pay at property** · unchanged.

The deposit tile's price summary states *Due now* and *Due before check-in*
separately, and says plainly: *"Your host can only check you in once it's
settled."*

After booking, the balance follows them: a notice on their next stay and their
in-progress stay, a **Pay remaining ₹Z** action in the upcoming list, and
reminder emails at **7 days, 3 days and 1 day** before check-in — once each,
never repeated, with the booking's own history row as the receipt so a restart
cannot re-send.

### What the platform does

- **`book_amount_paid`** records money actually received (wallet credit plus
  every verified gateway payment). **`book_pay_mode`** is `deposit` while
  anything is owed, `full` once settled.
- A balance is **only ever derived for a `deposit` row**. Every historical,
  pay-at-property and paid-in-full booking reports zero, whatever else is in the
  row — so no existing stay can suddenly appear to owe money.
- **The host's payout waits for the money.** A deposit payment writes the
  finance ledger as PENDING and queues **no payout**; the balance payment
  promotes the same rows to COMPLETED and queues it then. The platform never
  pays out on money it has not collected.
- **Check-in is refused while a balance is outstanding.** The host is told the
  amount and where the guest can pay it.
- **Refunds are computed against money received, not the price of the stay.**
  Without this a 100% cancellation refund on a ₹28,320 stay paid ₹2,832 would
  have returned ₹28,320.
- The existing balance endpoint now serves both kinds of outstanding money —
  pay-at-property and deposit — charging the **balance**, never the total again.

### One subtlety worth knowing

`pay_amount` on the payments table has always held the **pre-tax room
subtotal**, while the Razorpay order is for the tax-inclusive total, and host
earnings are credited from `pay_amount`. That column is left exactly as it is;
the gateway figure got its own column (`pay_gateway_amount`), which is the only
honest thing to count a balance against.

---

## 5. Where the host sets all this — Step 4 of the wizard

- **Long-stay discounts are gone.** They were percentage fields the pricing
  engine never read. In their place: **Weekly price** and **Monthly price**, the
  package figures the engine actually uses, each validated against the nightly
  rate (a weekly price above seven nights' worth is refused).
- **Negotiation** now says what really happens: the minimum is a floor whose
  breaches still reach the host, and the ideal is what auto-accepts.
- **Per-period tiers** (weekly/monthly minimum and ideal) appear only when that
  package has a price — a tier for a package that does not exist would never
  take effect.

---

## 6. How to check it yourself

```bash
curl -s -X POST https://aajaodev.onrender.com/pricing/quote \
  -H "Content-Type: application/json" \
  -d '{"propertyId":29262,"bookFrom":"01-10-2026","bookTo":"13-10-2026"}'
```

Expect `composition: {months:0, weeks:1, nights:5}` and a `subtotal` of 59,000
against a `nightlyTotal` of 68,000 — a 9,000 saving, and no `min`/`ideal`
anywhere in the payload.

```bash
cd /path/to/aajaoBackend-render && npm test
```

Expect **19/19 test files**, including `pricingEngine` (the document's worked
example), `negotiationEngine` (the full decision table), `pricingQuote` (the
no-leak guard) and `bookingDeposit` (balance, payout hold, check-in gate,
refund base).

**On the site:** book any stay, choose *Pay 10% now*, and check that the
booking confirms, the balance appears on My Bookings with a Pay remaining
button, and the host's Check in action refuses until it is paid.

---

## 7. Not in this release

- **Advance Booking as a separate discounted mode** (§10). The schema column
  (`ppr_advance_discount`) and the Step 4 field ship now; nothing reads it yet.
  Every future-dated booking already gets the deposit option, which is the part
  of that section you asked for.
- **The property page still renders its own price breakdown.** The quote
  endpoint is live and the checkout figures are server-authoritative, but
  swapping the property page's display over to it is a separate change — one
  that must not blank a price if the endpoint hiccups.
