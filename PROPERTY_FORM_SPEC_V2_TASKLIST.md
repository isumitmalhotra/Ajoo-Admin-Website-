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
| B14 | Bank details encrypted at rest, `FIELD_ENCRYPTION_KEY` or save fails | ✅ Code correct, and the key is set — confirmed from `/health/env` on 2026-09-11 |

---

## C. Gaps — re-verified against the code on 10 Sep 2026

Every row below was re-checked, not carried forward. Three turned out to be
already done — one of them was never a gap at all and my first audit was wrong
about it.

### DONE

| # | Task | What was actually found |
|---|---|---|
| ~~C5~~ | Backend validation of `min ≤ ideal ≤ displayed` | **Already existed at audit time — my audit was wrong.** `utils/pricingGrid.validateGrid` is called by `listingEngine.controller.js:894` AND `adminProperty.controller.js:683`. I reported it missing because I searched the controller for the arithmetic instead of for the helper that holds it. |
| ~~C6~~ | Response time required | Already required — `listingEngine.controller` rejects a save without it, from the schema's own list. |
| ~~C4~~ | "Advanced limits — saved, but not applied yet" | **Done 10 Sep.** The label was true when written, over three thresholds the engine ignored — those were removed on 9 Sep, and both settings still inside are live (the expiry drives `negotiationExpiry`, the attempt cap is passed to `claimNextRound`). It had become the lie it was written to prevent. Now "Offer timing & attempts". |
| ~~C10~~ | Duplicate ownership question | **Done 10 Sep, web AND app.** `is_owner` is derived from `host_type` on save and on draft load; the second question is gone from both wizards. Nothing had reconciled them: a host could answer Owner at the top and No further down, and the listing carried both. |
| ~~C11~~ | Manager → authorisation document | **Done 10 Sep, web AND app.** `pvf_authorization_doc` on the verification row; a manager's submission is REFUSED without it — a hard gate, not a score weighting, because the 70% readiness bar is a completeness heuristic a manager can clear with everything else filled in. The checklist names it, and only for managers. The unused `pf_authorization_doc` write on step 1 was removed so the document has one home. Migration live. |
| ~~C2~~ | The second deposit question | **Done 10 Sep.** The damage-policy yes/no is gone; `phr_damage_deposit` is derived from the Step-4 amount. Nothing had reconciled them — a host could enter ₹5,000 above and tick No below, and the property page told the guest no deposit applies while the host expected ₹5,000 at the door. The app never had the question. |
| ~~C9~~ | Tiered photo minimum | **Done 10 Sep, web AND app.** `photoRulesFor(accommodationType, categoryMinimum)`: 10 + exterior for an entire property, 5 and no exterior for a room or PG bed. Precedence is asymmetric — an admin's per-category floor stacks on a whole property and is ignored for a room. Unknown type gets the strict default, so no existing listing is quietly halved. Both enforcement points use it. |
| ~~C7~~ | Same-day ON + notice ≥ 24 h | **Done 10 Sep, web AND app.** The GUEST side was never broken — `bookingWindow` already returns "This host needs 24 hours notice before check-in" and both calendars print it. The gap was the host: they tick same-day Yes, set 24 hours' notice, and have silently switched their own setting off. Now warned on both forms. The app could not set *either* field before this, so it also gained the notice box and the same-day toggle. |
| ~~C8~~ | Max stay "unlimited" stores NULL | **Done 10 Sep, web AND app.** Storage was always right (`asInt("")` is null; booking treats null and 0 alike as unlimited, and 5 of 6 live listings store NULL). Only the forms were silent — now placeholder "No limit" plus a line saying what blank does. |
| ~~C12~~ | Nearby: drop non-operational places | **Done 10 Sep.** Google keeps closed businesses in nearbysearch and they rank WELL — a restaurant shut last year keeps every rating it earned, so the prominence sort actively promoted it over its replacement. Filtered in both passes. Absent `business_status` means OPERATIONAL, so a missing value must pass or the section empties. |
| ~~C13~~ | Nearby: mark manual entries | **Done 10 Sep, web AND app.** `pnp_source` has recorded the difference since the table was built and the guest was never shown it. Typed entries now read "· Host provided". "manual" is the cautious default everywhere. |
| ~~C14~~ | "2BHK but 1 bedroom" warning | **Done 10 Sep, web AND app.** Apartment Type names a bedroom count; step 1 asks for one separately, on another screen. Studio covered too; Penthouse/Duplex left alone (no count in the name). A warning — neither number is knowably the wrong one. |
| ~~C15~~ | Address vs pin disagreement | **Done 10 Sep, web AND app.** Resolved from the COORDINATES, not remembered from the pick, so it survives a draft reopened days later. The picker already replaced the whole address block on a pin *move*; this catches a host typing over the city afterwards. |
| ~~C16~~ | Seasonal/festival rates | **Done 10 Sep.** The FORM was already right — type, name, date range, price — my audit was wrong about that. What was wrong is that `property_rate_periods` was never queried: a host who priced Diwali at 3× was paid their usual rate. Now loaded and applied; a dated period beats the weekend rate, and the narrowest of overlapping periods wins. |
| ~~C17~~ | Internet speed as bands | **Done 10 Sep.** Download was already a band; upload was a free-text Mbps box and is now a band too. |
| ~~C18~~ | Cleaning fee | **Done 10 Sep.** It was collected and **charged nowhere** — the frequency was the smaller half of the problem. Now charged in the quote, the shared pricer AND the booking price clamp (a fee in the quote but not the clamp would reject every booking), with an escape for app builds that predate it. Frequency required in the form and on the server. |
| ~~C19~~ | Payout "Custom" needs approval | **Done 10 Sep.** The option said "admin approval" and picking it simply wrote Custom. The request is recorded, the cycle in force does not change until granted, and re-saving cannot re-open an approval already given. |
| ~~C3~~ | Check-in default 02:01 → 14:00 | **Code was already right**: `DEFAULT_CHECKIN_TIME = "14:00"` in `utils/cancellationPolicy.js`, and NULL falls back to it. Only the DATA was stale, and only barely — **1 live listing** carries 02:01 (the rest: two at 14:00, two NULL, one at 12:00). A one-row fix, not a code change. |

### P0 — one thing, and it is not code

| # | Task | Status |
|---|---|---|
| ~~**C1**~~ | ~~**Set `FIELD_ENCRYPTION_KEY` on Render**~~ **CLOSED 2026-09-11 — it was already set.** `/health/env`, run by the client with the health token, reports `FIELD_ENCRYPTION_KEY: true`. Hosts can save payout details. The row below is kept for the record of what was asked. | **Only you can do this** — it is an environment variable on the Render dashboard, and the code has been correct throughout (`hostV2.controller.js` refuses to write a bank account without it, rather than storing one in plaintext). Hosts cannot save payout details until it is set. **Generate the value yourself** so it never passes through a chat log: `node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"` → Render → Environment → Add `FIELD_ENCRYPTION_KEY` → Save (the service restarts). **Never rotate it** without re-encrypting the stored accounts. |

**Why it stayed open unnoticed, and what changed 10 Sep.** The question "is
the thing blocking payouts still blocking it?" had no answer outside the
Render dashboard: `/health/env` returns `{ready:true}` in public and the
per-variable detail was closed off under BE-15, behind a token that is itself
unset. An unanswerable question is one nobody asks. Admin → Settings now
leads with any capability that is missing, naming what it blocks in plain
terms — and only when something is actually missing, because a card of green
ticks is a card nobody reads. So once C1 is done it will visibly disappear,
and the next gap of this kind surfaces on its own.

### P1 — still open

| # | Task | Status |
|---|---|---|

### P2 — all closed

C16, C17, C18 and C19 are in the DONE table above.

---

## E. Beyond the document — shipped 9–10 Sep

Client instructions that arrived after the audit and are now live:

- **Negotiation ladder settled** (§A1) — round one auto-counters AND notifies
  the host; round two escalates saying "below the minimum you set".
- **"Prices are tax exclusive?" removed** from Step 4 — it was never the
  host's to answer.
- **GST per night**, banded AT ₹7,500 (not above it), on the final
  post-discount price. Was one band for a whole stay, taken from the base
  rate, so a ₹9,000 weekend night on a ₹7,500 listing was taxed at 5%.
- **Weekend Minimum and Ideal** added to the form (web AND app) so negotiation
  works on a weekend night. The app had no weekend pricing at all.
- **Negotiated price now actually charged** — the deal's percentage was
  computed off the base nightly rate, so a guest who agreed ₹8,000 on a
  weekend got no coupon and paid ₹9,000.
- **Minimum stay blocked at the calendar**, not at the payment screen.

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
