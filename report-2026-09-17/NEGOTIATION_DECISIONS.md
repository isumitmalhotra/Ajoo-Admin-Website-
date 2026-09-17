# Two Decisions We Need From You — Negotiation Pricing and the Host's Upcoming Tab

**Prepared 17 September 2026** · in response to the six items reported on 17 September

---

## Why we are asking

Of the six items you sent on 17 September, four are ours to fix and are in hand. **Two are not bugs — they are business decisions**, and we would rather you made them than have us guess and call it a fix.

Both are small changes to build. Both change what your hosts earn or what they see, which is why they belong with you.

A short status on the other four is at the end, so you have the whole batch in one place.

---

# Decision 1 — What price should the automatic counter-offer quote?

## What happens today

When a guest offers below a host's target price, Aajoo answers **instantly on the host's behalf** rather than emailing the host and leaving the guest watching a spinner. The question is **which number it quotes back**.

Every listing carries three prices, set by the host when they list:

| | Meaning | On "Aajoo Homes" (property 29291) |
|---|---|---|
| **List price** | What any guest pays without negotiating | **₹2,000** |
| **Ideal** | The host's target. At or above this, Aajoo accepts on the spot | set per dates |
| **Floor** | Never go below this | **₹1,500** |

Today the automatic counter is **not** simply the ideal. It slides between the ideal and just under the list price, and **where it lands depends on how close the guest's offer was**.

Using a worked example — list ₹2,000, ideal ₹1,800, floor ₹1,500:

| The guest offers | Aajoo counters with | Why |
|---|---|---|
| ₹100 | **₹1,900** | Nowhere near. Quoted close to the list price |
| ₹1,000 | **₹1,850** | Half-hearted. Asked to come up |
| ₹1,400 | **₹1,800** | A serious bid. Quoted the host's target |
| ₹1,600 | **₹1,800** | A serious bid. Quoted the host's target |
| ₹1,800 or more | **Accepted immediately** | At or above the target |

The thinking behind it: quoting the target price to a one-rupee lowball answers a silly offer with the host's best price. A guest who bids seriously gets the target; a guest who lowballs is asked to come up.

## Your choice

**Option A — leave it as it is.** Serious bidders get the host's target. Lowballers get quoted higher and have to move.

**Option B — always quote the host's ideal, exactly.** Every guest, every time, sees the host's published target as the counter.

## What each option costs and gains

**Option B gives you predictability.** One number, always the host's real target. Nobody wonders how the figure was reached, and it is simpler to explain to both hosts and guests. It is also, we think, what you expected when you tested it.

**Option B has a price, and it is the part worth pausing on.** Under Option B a host can **never earn more than their target from a negotiation**. Today a half-hearted offer might be answered at ₹1,850 and accepted, when the host would have settled for ₹1,800 — ₹50 a night more for the host. In this example the most the current design can earn above target is **₹150 a night**.

There is a second effect. Because the ideal is also the price Aajoo accepts at, quoting it means the guest can simply say yes — so **every negotiation would settle at exactly the target and never above it**. The room to haggle disappears. That is cleaner for the guest, and it is less money for the host.

**A middle option exists** if you want it: quote the ideal whenever the guest has bid seriously, and quote higher only for genuine lowballs. That is close to today's behaviour with a sharper, easier-to-explain cutoff.

> ### What we need
> **Option A (keep it), Option B (always the target), or the middle option?**
> One line is enough. It is a one-line change in the code either way.

---

# Decision 2 — Should an agreed price appear in the host's Upcoming tab?

## What you asked for

> *"If user book it or not but limited offer apply then show till the time in upcoming tab."*

Entirely reasonable: a host who has agreed a price should be able to see it coming, and see how long it lasts.

## The thing that makes it delicate — and you spotted it first

You raised this yourself a day earlier:

> *"If two renters negotiated for same property for same dates and agrees, it becomes unavailable for both the renters."*

We tested that against the live system and it does **not** happen. But the reason it does not is exactly what makes this decision a decision:

> **An agreed price is a price, not a reservation. It does not block the calendar.**

Two different guests can both hold an agreed price for the same nights on the same property. **Whichever of them books first gets the nights**; the other one's agreed price simply expires unused. Nobody is blocked, and nothing is double-booked.

That is deliberate and we believe it is right — holding the room every time somebody agreed a price would let a guest freeze a host's calendar for free. But it means:

> If agreed prices are dropped into **Upcoming**, a host may open that tab and see **two entries for the same nights**, and reasonably conclude they have been double-booked.

Which is the very confusion you flagged. So the question is not *whether* to show agreed prices — it is **where**, so they cannot be mistaken for confirmed bookings.

## Your choice

**Option A — mix them into Upcoming, each clearly marked.** Simplest. Each entry carries a badge such as *"Price agreed — not booked yet, expires 6:30 pm"*. Honest, but two same-date entries will still look alarming at a glance.

**Option B — a separate section (our recommendation).** *Upcoming* keeps its plain meaning: confirmed and paid. Agreed-but-unbooked prices sit in their own strip just above it — *"Agreed prices waiting to be booked (2)"* — each with its expiry countdown. The host sees everything, nothing is confused with a real booking, and two agreed prices on one date read naturally, because that section is about prices rather than reservations.

**Option C — a count only.** A number on the Negotiations tab and nothing in Bookings. Least intrusive, and least useful to the host.

## One smaller question, whichever you pick

**When an agreed price expires without the guest booking, should the host still see it?**

We suggest showing it briefly as *"expired — not booked"* rather than letting it vanish. A host who agreed to a discount deserves to know it lapsed. Silent disappearance is how several notification gaps went unnoticed until now.

> ### What we need
> **Option A, B or C — and whether an expired unbooked price should be shown or hidden.**
> Roughly half a day of work once decided.

---

# The other four items from 17 September

Included so you have the full batch in one place.

| What you reported | Where it stands |
|---|---|
| **"If you decline the host offer, the host didn't have the notification for rejection — only it shows in the chat."** | **Fixed.** And it was broader than reported: *all three* guest replies — accept, decline and counter — only ever reached the host as a live screen update. The host learned the answer to their counter only if they happened to have the Negotiations page open at that moment. Accept looked fine because you were watching; decline was reported because you were not. All three now send a real notification: the host's bell, their phone, the portal and an email |
| **"My offer is still active, why is the amount not changed on the homepage."** | **Working correctly — the deal was already used.** We read the record: your agreed 15.01% discount on Aajoo Homes was applied to the booking you made, and a discount can be used once. The ₹1,900 you expected to see was a counter you **declined**, and a declined counter is not a discount. So the card correctly shows ₹2,000 |
| **"Accept / reject highlights different."** | **Agreed, and this is the real cause of the item above.** The negotiation thread does not make it clear enough which offers are live, accepted, declined or expired — which is why a used discount and a declined counter read as "still active". We are giving each state its own clear treatment, and adding a line that says *why* there is no discount: used on your booking, declined, or expired |
| **"I again tried to book and didn't receive a counter offer at the host's ideal price."** | **This is Decision 1 above.** The counter is working, but by design it does not always quote the ideal — that is the choice we are asking you to make |

---

# In short

Two answers, and we can finish the rest:

1. **Counter price** — Option A (keep the sliding price), Option B (always the host's target), or the middle option.
2. **Upcoming tab** — Option A (mixed in), B (separate section), or C (count only); and show or hide an expired unbooked price.

The four items above need nothing from you. If you would rather not settle the pricing question immediately, tell us the Upcoming answer and we will build that first — the two are independent.
