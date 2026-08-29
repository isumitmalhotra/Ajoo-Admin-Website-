# The nine-value pricing grid is now required — everywhere

Shipped 2026-08-30. Follows on from W2 (`W2_PRICING_ENGINE_COMPLETION_2026-08-29.md`).

---

## What changed

Every surface that sets a listing's price now asks for the same nine numbers,
and refuses to save without them.

| | Night | Week | Month |
|---|---|---|---|
| **Max — the list price, the only figure a guest sees** | required | required | required |
| **Ideal — offers at or above it are accepted automatically** | required | required | required |
| **Min — the floor; offers below it still reach the host, flagged** | required | required | required |

Plus one optional field: **pre-booking discount (%)**. Left optional on purpose —
0 is a real answer there, and requiring it would only make every host type a
zero for a mode that is not switched on yet. Say the word and it becomes
required too.

### The rules, enforced identically on every surface

- All nine present and greater than zero.
- Per period: **min ≤ ideal ≤ price**.
- A package must beat its nights bought singly: a weekly price above 7 × the
  nightly rate is refused, and a monthly price above 28 × the nightly rate.

One validator, `utils/pricingGrid.js`, is called by all of them. A rule
enforced on two surfaces out of three is not a rule.

---

## Where it now applies

| Surface | Route | Before | Now |
|---|---|---|---|
| **Host wizard, Step 4** (web) | `/host/list-property` | base price required; the rest optional | all nine required |
| **Admin driving the wizard** (web) | `/admin/properties/new` | same as above | all nine required |
| **Admin's own property form** (web) | `/admin/properties/form[/:id]` | **wrote two of nine**, and never touched `property_pricing` at all | all nine required, and persisted |
| **Host wizard, Step 4** (Android/iOS) | listing wizard | base price required | all nine required |

The admin form was the real gap. A listing created there had no ideal price and
no weekly or monthly package whatsoever — so the pricing engine quoted it on
derived guesses and the negotiation engine auto-accepted against a midpoint
nobody chose.

### One UI decision worth knowing

The six min/ideal fields used to live **inside** the "Allow negotiation" toggle,
on both web and app. Left there, a host who chose *Fixed price only* would have
been blocked by six required fields they could not see. They now sit in their
own always-visible section, **Your price range**, above the negotiation toggle —
they are pricing data, not a negotiation setting.

---

## Two bugs found while doing it

**1. `property_ideal_price` was never stored — on any surface.**
The column exists and both forms set it, but `models/tbl_properties.js` never
declared it, and **Sequelize silently drops undeclared fields** from `create()`
and `update()`. So the auto-accept threshold the whole negotiation engine runs
on read back null on every listing, and the engine fell through to the midpoint
every time. Found live: an admin save with an ideal of ₹4,750 persisted every
other field on the same request and left that one null. Now declared, and a test
pins the declaration.

**2. The app's Step 4 opened empty when editing.**
The pricing row was merged with a `pp_` prefix, but its columns are `ppr_*`, so
nothing matched and a host editing a listing re-typed every price they had
already set. Booking rules had the identical fault (`pbr_*`). Both fixed — which
matters far more now that the fields are mandatory.

---

## What this means for the listings you already have

Measured on the live database today:

| | Count |
|---|---|
| Live listings | 29,245 |
| …with a nightly minimum | 29,232 |
| …with a nightly **ideal** | **0** |
| Listings with any `property_pricing` row at all | 12 |
| …with a weekly price | 1 |
| …with a monthly price | 1 |

**So: essentially every existing listing is missing 7 of the 9 values, and can
no longer be saved from either form until someone fills them in.** That is
exactly what "nobody can skip those fields" means, and it is worth being
deliberate about, because it lands in two places:

- A **host** editing Step 4 of an existing listing must complete the grid before
  that step will save. Steps 1, 2, 3 and 5 are unaffected.
- An **admin** editing *anything* on the property form — even fixing a typo in
  the name — must complete the grid, because the form saves as one payload.

The large majority of those 29,245 are the seeded CSV listings under host 100,
not real hosts' properties. But the admin friction is real either way.

### The backfill — run 2026-08-30

`scripts/backfillPricingGrid.js`, run against production at your request.

| | |
|---|---|
| Listings examined | 29,245 |
| Already complete, untouched | 1 |
| **Filled** | **29,239** — of which 681 had a broken minimum repaired |
| Skipped, still need a human | 5 |

**Derivation.** `min` = 80% of the nightly price · `ideal` = the midpoint of
min and price · `weekly` = 7 nights less 10% · `monthly` = 28 nights less 25% ·
each period's own min and ideal = that period's price scaled by the nightly
ratio. That last one is the same fallback the pricing engine already applied at
quote time — the backfill just makes it explicit and stores it.

**What it did not touch.** Only missing values were filled; a number a host
actually set was left exactly as it was. The one exception is deliberate: 681
seeded listings carried a minimum *above* their list price, which is not a floor
but broken data, and those rows would have stayed unsaveable forever. Their
minimum was re-derived. Every one belongs to host 100 (the seeded CSV corpus) —
the script refuses to repair such a row for any other host and reports it
instead, because that would be somebody's real number.

**Two properties worth knowing:**

- Every computed grid went through `validateGrid` *before* being written, so the
  backfill could not produce a listing the forms would then reject.
- Every touched row was copied to `tbl_pricing_grid_backfill` first.
  `node scripts/backfillPricingGrid.js --rollback` puts all of them back —
  verified on three rows before the full run, byte for byte, including deleting
  the pricing rows the script had created.

**The five that were skipped** have no nightly price at all, so nothing could be
derived from them. All five are inactive drafts: #28, #30, #29258, #29268
(host 100) and #29261 (host 133). They stay unsaveable until somebody gives them
a price — which is the correct outcome, not a gap.

**One behaviour change to be aware of.** Eight listings previously had no
minimum, and under spec rule 5 a listing with no floor does not negotiate at
all. They have one now, so they accept offers where before they refused them.
If any of those should stay fixed-price, turn negotiation off on the listing
itself rather than clearing the minimum.

---

## How to check it

```bash
cd /path/to/aajaoBackend-render && node tests/pricingGrid.test.js
```

Expect 17/17: the rule itself, plus source-level checks that no write path
skips it and that the model still declares the ideal price.

Live, against production (admin token required):

- Saving a property with only a nightly price and minimum comes back
  `"Ideal price is required", "Weekly price is required", …` — verified.
- Saving with an out-of-order grid comes back
  `"Weekly ideal price can't be below your weekly minimum."` — verified.
- Saving a complete grid persists all nine and reads back through
  `POST /admin/property` — verified.

**On the site:** open `/admin/properties/form/29262`, and the price fields
should load populated and refuse to save if you clear any of them. In the host
wizard, Step 4 should show *Weekly & monthly price* and *Your price range* as
required, above the negotiation toggle.
