# Property Form — "Final Business Logic v2" vs what we have

**Source:** `Aajoo-Property-Form-Final-Business-Logic.docx` (client, 9 Sep 2026)
**Audited against:** live code + live API, 9 Sep 2026

Every row below was checked against the code or the running API, not assumed.
Where I could not verify something without live data I have said so.

---

## A. The negotiation ladder — settled, and now built

### A1 — RESOLVED 9 Sep 2026, and shipped

The document put every offer below the ideal in front of the host. What was
running put round one in front of nobody. Neither was right; the answer is
the two of them joined up, and it is now the code:

| Guest offers | Round 1 | Round 2 (they argue back) |
|---|---|---|
| At or above **ideal** | Auto-accept, booking completes | n/a |
| Below **ideal** | Auto-counter once, host **notified** | Goes to the host |
| Below **minimum** | Auto-counter once, host **notified** | Goes to the host, **flagged "below your minimum"** |

Three things follow from that, and all three are live:

1. **The auto-counter fires once, on round one only.** A guest who takes it
   is booked immediately. A guest who argues gets a person.
2. **The host is told when the platform quotes in their name.** This was the
   real gap the document was pointing at. Round one used to be silent — the
   reasoning being that nobody had asked the host anything — which meant a
   host could not tell a negotiation had opened on their listing at all. If
   the guest simply accepted the counter, the first they ever heard of a
   stay sold under list price was the booking.
3. **Below the minimum reads differently at round two.** The host now sees
   "below the minimum you set" in the notification and the email.

**One bug came out of building it.** `emailHostAboutOffer` has carried two
sentences since it was written — one for an offer under the floor, one for an
offer merely under the target — and the counter-back path passed neither, so
it always printed the second. A guest countering at half the floor produced
an email to the host reading *"below your target price (but above your
minimum)"*. Not vague — false, in the one message the host decides from.

Round one deliberately stays quiet about the floor. It is the host's own
number so there is nothing leaked, but "below your minimum" on an offer that
has already been handled reads as something needing attention when nothing
is being asked. Those words earn their place on the escalation.

**Still open, if you want it:** the host's Negotiations *screen* does not
show the below-minimum flag — only the email and the push do. Closing that
needs a field on the host thread payload plus both host screens (web and
app). Small, but three files in two repos, so I have left it for your call.

## B. Already done — no work needed

Checked and confirmed live.

| # | Document asks for | Status |
|---|---|---|
| B1 | `min ≤ ideal ≤ displayed`, per period, all three periods | ✅ Enforced in the wizard for nightly, weekly and monthly |
| B2 | Weekly/monthly package sanity (weekly < 7×nightly) | ✅ Enforced — currently a hard block, doc asks for a *warning* (see D1) |
| B3 | No 4th "maximum" field; displayed price is the ceiling | ✅ That is exactly the model |
| B4 | Min + ideal per period explicit, never derived | ✅ Six fields collected |
| B5 | Guests never see min/ideal — no API, no screen | ✅ **Verified on the live API** — the public detail response carries neither |
| B6 | Cancellation policy central + versioned, version stored on booking | ✅ Shipped 5 Sep |
| B7 | Publish state machine, backend is final authority | ✅ Shipped (listing lifecycle) |
| B8 | Host agreement stored with host, property, version, time, IP/device | ✅ Shipped 6 Sep |
| B9 | Capacity total auto-calculated, infants separate | ✅ Total is derived, infants excluded |
| B10 | Availability: All Year / Seasonal / Weekends / Custom + date ranges | ✅ Built, and the engine enforces it |
| B11 | Booking type Instant / Approval Required | ✅ Built |
| B12 | Nearby places categorised by Google **type**, not name | ✅ Queried per section by type; dedupes by `place_id`; excludes bad types |
| B13 | House-rule chips + quiet hours | ✅ Built |
| B14 | Bank details encrypted at rest, `FIELD_ENCRYPTION_KEY` or save fails | ✅ Code correct — but see C1, the key is still unset |

---

## C. Gaps — real work, in priority order

### P0 — blocks listing or leaks money/trust

| # | Task | Detail |
|---|---|---|
| **C1** | **Set `FIELD_ENCRYPTION_KEY` on Render** | The doc names this as "the current live blocker" and it is right. The code refuses to store payout bank details without it. This is an env-var change, not a code change — 5 minutes, and hosts cannot be paid until it is done. |
| **C2** | **Remove the second deposit field** | The wizard collects `security_deposit` (Step 4) **and** `damage_deposit` (damage policy). Two numbers for one thing, and nothing reconciles them. The damage section must *read* the Step-4 deposit, not collect its own. |
| **C3** | **Fix the check-in default: 02:01 → 14:00** | The doc spotted this and it is real — it is visible in the live cancellation-policy text ("measured from the property's check-in time (02:01)"). Default check-in 2:00 PM, check-out 11:00 AM. Existing listings carrying 02:01 need a data fix too, not just a new default. |
| **C4** | **Remove the "Advanced limits — saved, but not applied yet" label** | Still on the form at Step 4. Since this morning the engine *does* read min/ideal, so the label now tells the host the opposite of the truth. |

### P1 — important, not blocking

| # | Task | Detail |
|---|---|---|
| C5 | Backend validation of `min ≤ ideal ≤ displayed` | The wizard enforces it; **the API does not**. The doc asks for both, and it is right: a direct API call can still save a nonsense ladder. |
| C6 | Response time required when negotiation is ON or booking = Approval Required | Currently optional. No longer blocked by A1: with the ladder settled, the host's figure is what the guest is shown after the 90-second wait on a round-two escalation, so a listing that negotiates and has no figure shows the guest nothing. |
| C7 | Conflict check: same-day booking ON **and** minimum notice ≥ 24 h | Not implemented. The two settings contradict each other and the guest sees the result as a calendar that refuses today for no stated reason. |
| C8 | Max stay "unlimited" must store NULL | Currently a plain number field with no unlimited option. |
| C9 | Tiered photo minimum: 5 for a room / PG bed, 10 for an entire property | Currently a flat 10 for everything. Also: skip the **Exterior** requirement for room-only listings — today it is required of every listing. |
| C10 | Owner vs Manager: hide the duplicate "Do you own this property?" | When host type is already Owner, the second question is redundant — visible in the client's video. |
| C11 | Manager → collect authorisation document at verification | Not collected today. |
| C12 | Nearby: drop non-operational places (`business_status != OPERATIONAL`) | We filter by type and rating but not by whether the business still exists. |
| C13 | Nearby: mark manual entries "Host provided" | Manual adds are not distinguished from Google-verified ones on the property page. |
| C14 | Cross-field warning: "2BHK but 1 bedroom" | Not implemented. Warning, not a block. |
| C15 | Address vs pin disagreement warning | Not implemented. |

### P2 — polish

| # | Task | Detail |
|---|---|---|
| C16 | Seasonal/festival rates as a repeatable list (type, name, range, price) | We have a season **month picker**, not named festival periods with their own price. |
| C17 | Internet speed as **bands**, not an exact Mbps number | I could not find a speed field at all in the current wizard — may already be gone, worth confirming with the client that it is not wanted. |
| C18 | Cleaning-fee frequency must have a value when a fee is set | The field exists (`cleaning_fee_type`) but is unused — cleaning fee is never actually charged anywhere. Bigger than a validation fix. |
| C19 | Payout settlement: Custom requires admin approval | Field exists (`payout_cycle`), read by nothing. |

---

## D. Places the document and the product disagree, where I think we are right

Raise these rather than change them silently.

| # | Document | What we do, and why |
|---|---|---|
| D1 | Weekly/monthly over-price is a **warning** | We **block** it. A weekly price above 7× the nightly is not a package, and letting it save produces a listing where the "discount" costs more. Recommend keeping the block. |
| D2 | "Response time applies only to the middle band" | We also use it for the "host is away — usually replies within X" notice after 90 seconds. That is a superset, not a conflict, but worth naming. |
| D3 | Photo tiers by **booking unit** | Our photo minimum is per **category** (admin-configurable). The doc's tiering is by entire-place vs room. These can coexist; the tier should be the floor. |

---

## E. Notes for whoever picks this up

- **C1 is the only one you can finish today** and it unblocks host payouts.
- **C2, C3, C4 are small and visible** — a duplicate field, a wrong default and
  a label that lies. Good first batch.
- **C5 matters more than it looks.** Every guardrail in section B1 is currently
  a front-end guardrail. The document is right that the backend must hold the
  line too, and this codebase has been bitten three times this week by exactly
  that pattern — a rule enforced in the client and nowhere else.
- The document's own framing is worth keeping: *never derive a host's money,
  never leak min/ideal, never let two screens disagree on price, deposit or
  cancellation.* C2 and C5 are both instances of that principle.
