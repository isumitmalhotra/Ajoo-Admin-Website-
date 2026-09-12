# Negotiation journey — the client walkthrough, and how to rebuild it

`Aajoo-Negotiation-User-Journey.pdf` walks every scenario in the negotiation
engine, guest side and host side, with a photograph of the live site at each
step.

The current edition is **12 September 2026**, rebuilt after the engine changed:
unlimited rounds, an answer written under every offer, a one-hour parting price
after a decline, a same-day lockout, dated prices everywhere, and the live
notification layer. The 9 September edition it replaces was built from
`journey.mjs`; that file is kept because its scenarios still describe the old
behaviour and the two documents are meant to be readable against each other.

## Rebuilding the PDF

```bash
bash negotiation-journey/build.sh
```

That renders `NEGOTIATION_JOURNEY.md` plus the PNGs in `shots/` into the PDF
(and an HTML twin beside it). Edit the markdown, run it again.

To check the result before it goes out:

```bash
node negotiation-journey/pdfshot.mjs 12 17 31
```

Chrome's own viewer renders the pages you name into `shots/pdf-pNN.png`. They
are proofs, not document images — **delete them before committing**.

## Retaking the photographs

The shots are taken by a Chrome this repo drives, against the live site, with
two persistent profiles under `.chrome/` (git-ignored) — one signed in as a
guest, one as the host who owns the demo listing.

**Signing in is a human step, on purpose.** Nothing here ever handles a
password. The first time, open the profile yourself and log in:

```bash
"C:\Program Files\Google\Chrome\Application\chrome.exe" --user-data-dir="<repo>\negotiation-journey\.chrome\renter" https://www.aajoohomes.com/login
```

Sign in, close the window (Chrome will not share a profile with the script),
and the session is in the profile from then on. Same for `.chrome\host`.

Then:

```bash
node negotiation-journey/journey2.mjs                 # lists every scenario
node negotiation-journey/journey2.mjs n7-above-list   # one of them
node negotiation-journey/journey2.mjs x1-live-decline # two browsers at once
node negotiation-journey/probe.mjs 29291 1990 p1-below-floor
node negotiation-journey/email.mjs "last price" n13-email
```

**Clear the thread between scenarios.** Several of the photographs are only
true of a fresh negotiation — round one is answered by the platform, round two
by a person, and a held deal bars another offer for those nights altogether:

```bash
node scripts/clearNegotiation.js 29291 101 --apply    # in the BACKEND repo
```

That script is narrower than `resetTestNegotiations_2026-09-12.js` on purpose:
the other one empties two whole accounts including their bookings, which is the
wrong tool to reach for between two screenshots.

### The two-browser scenarios

`x1-live-decline` opens both profiles at once, because part of what shipped
only exists BETWEEN two windows: the host declines in one and a popup lands in
the other, on whatever page the guest happens to be reading. Three things had
to be true before that could be photographed at all:

- **Chrome throttles a window without focus.** Its timers drop to about a tick
  a minute, and an eight-second popup opened and closed between two polls. The
  socket was up the whole time — verified over CDP, handshake 101 on
  `wss://…/socket.io/`. `rig.mjs` now launches with the backgrounding flags off.
- **A websocket is not a request.** `page.on("request")` never fires for a WS
  upgrade, so a first attempt at diagnosing this reported "no socket traffic"
  about a live connection. `socketcheck.mjs` uses CDP instead.
- **A clip that runs past the bottom of the viewport renders white**, which
  sliced the parting-price explanation in half. Rail shots raise the viewport
  first.

## The demo listing

**29291 "Aajoo Homes"**, owned by the test host *Sam Tao* (user 100); the guest
is *Aajoo Renter* (user 101). Chosen because both sides are reachable — the
prettier listing 29296 belongs to a host whose credentials we do not have, and
half a walkthrough is no walkthrough.

| | Nightly column | 12–13 September |
|---|---|---|
| List | ₹2,000 | **₹2,500** |
| Ideal | ₹1,700 | **₹2,300** |
| Minimum | ₹1,500 | **₹2,000** |

The right-hand column is where every figure in the document comes from. The
dates matter: 12–13 September is a weekend night, and the whole point of the
rebuild is that the engine now works from the price of the nights being argued
over rather than from the flat column.

`n11-calendar` is the exception — it is taken on **29302 "QA Sunrise Villa"**,
which is the listing with a two-night minimum, and that rule is what it shows.

## The email shot

`email.mjs` opens ONE message in the test renter's public mailbox, by subject,
and never renders the inbox list. That address also receives sign-in codes, and
a one-time code must not end up in a document, a log or a screen recording.

## What photographing it found

Every edition of this document has found defects that the test suites did not,
because driving a real screen asks questions a test does not think to ask.

**9 September:** the host's thread said "You countered" above a counter the
platform sent for them; the acceptance notice told hosts their *minimum* had
been met when the line is the ideal; the guest's counter-back screen reported
"with the host" without reading the answer.

**12 September**, while taking these photographs:

- the parting-price sentence quoted 8% off the flat ₹2,000 column as ₹1,840,
  on a rail that was charging ₹2,300 — one of **six** places a dated price was
  being read from an undated column, all fixed the same day;
- the host's card read "Guest offered ₹2,400 — Your price ₹2,000", showing an
  offer ₹100 *under* the asking price as ₹400 over it;
- "for your dates · listed at ₹2,000/night" sat beside a struck-through ₹2,500,
  naming the one price that was not the list price for those dates;
- "they have 1 hours to answer";
- "accepting sanctions these dates + price" on the host's card — *sanctions*
  reads as a penalty, in the sentence that says what Accept commits them to;
- a notification category switch wrote the `push` map alone, so a guest who
  turned offers off went on receiving an email for every counter.
