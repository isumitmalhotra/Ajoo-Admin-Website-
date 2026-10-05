# Play Store listing copy — draft for review

Replaces the listing last touched **28 Oct 2025**. Every feature named below was
checked against the Flutter app's own source, not assumed from the web product —
three of them (pay at property, safety, the luxury tier) I nearly left out
because my first search used the wrong names.

---

## App name — unchanged

```
Aajoo Homes: Real-Time Stays
```
28 / 30. It works, and renaming resets hard-won store indexing. Leave it.

---

## Short description

**Current:** `India’s extra-room marketplace — where travel meets local living.`

This is the single most valuable line in the listing — it sits under the title
before anyone taps "read more". "Extra-room marketplace" describes the business
model, which is a seller's way of seeing it; it never says what the person
holding the phone can do.

**Proposed:**
```
Find a stay across India, make the host an offer, and book in minutes.
```

Leading on **negotiation**, because it is the one thing here that competitors
do not offer and the one thing a traveller has never been able to do in a
booking app.

**Alternative, if you would rather lead on price certainty:**
```
Rooms across India. Negotiate the price, pay at the property, stay verified.
```

---

## Full description

**Current** (317 of 4000 characters, with a stray space before a comma):

> Aajoo is India's platform for travelers and hosts — making short stays simple.
> Guests can find affordable rooms instantly, while hosts earn from their unused
> spaces. Smart matching, secure payments, and verified profiles make Aajoo easy,
> safe, and community-driven. Wherever you go , Aajoo has a room waiting for you.

**Proposed:**

```
Aajoo Homes is where you find a room across India — and where, for the first
time, you can simply ask for a better price.

MAKE AN OFFER, NOT JUST A BOOKING
See a stay you like but not the price? Send the host an offer. They can accept
it, decline it, or come back with a counter — and you settle on a number that
works for both of you, in the app, before you book. No queueing, no phone call.

WAYS TO PAY THAT SUIT THE TRIP
Pay now by card, UPI or net banking, or choose Pay at Property on eligible
stays and settle when you arrive. Coupons and host deals apply automatically at
checkout, so the price you are shown is the price you pay — taxes included, no
surprise at the last screen.

FIND THE RIGHT KIND OF PLACE
Search by map or by category — homestays, villas, cottages, hotels, hostels,
farm stays and more. Filter by dates, guests, budget and amenities, or browse
the luxury tier when the trip deserves it.

KNOW WHO YOU ARE STAYING WITH
Hosts verify their identity with government ID before their listing goes live,
and reviews are two-sided: guest and host each write theirs privately, and both
publish together, so neither is written to influence the other. In-app safety
tools are there if you ever need them.

EVERYTHING ABOUT YOUR TRIP IN ONE PLACE
Message the host directly, track your booking from confirmation to check-out,
see exactly what was charged and what a cancellation would refund before you
commit.

HOSTING ON AAJOO
Have a room that sits empty? List it in a few guided steps — photos, pricing,
house rules, the calendar — and set the price you will accept so offers that
clear it can be approved in a tap. Block dates, take or decline requests, watch
your earnings, and boost a listing when you want it seen.

Sign in with your phone, Google or Apple. Aajoo Homes is built in India, for
travel in India.
```

Character count and the 80-char limit are checked by the script below; the draft
is kept well under 4000 so there is room to add without a rewrite.

---

## What I deliberately did NOT write

* **No superlatives** — no "best", "cheapest", "#1". Play's listing policy
  treats unverifiable ranking claims as a violation, and they read as noise.
* **No keyword stuffing.** A block of city names would lift nothing and risks a
  policy strike.
* **No feature that is web-only.** I checked each claim against
  `aajoo_app_2026/lib`, and only named what a person can actually do in the
  Android app.
* **Nothing about refunds beyond "see what a cancellation would refund"** —
  the policy is per-listing and a blanket promise in a store listing would be
  a promise we cannot keep on every stay.

---

## Also needs fixing, but needs a designer

The **feature graphic** reads *"Find Your Stay Few Steps Away"* — missing an
"a". It is a 1024×500 image, so it cannot be fixed from the console; it needs
re-exporting.

The **7 phone screenshots** are from 28 Oct 2025 and predate the redesign.
They need recapturing once there is a build to drive — which is blocked behind
the upload freeze anyway.
