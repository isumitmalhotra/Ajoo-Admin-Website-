# Negotiation journey — the client walkthrough, and how to rebuild it

`Aajoo-Negotiation-User-Journey.pdf` walks every scenario in the negotiation
engine, guest side and host side, with a photograph of the live site at each
step. It was built for client sign-off on 9 September 2026.

## Rebuilding it

```bash
bash negotiation-journey/build.sh
```

That renders `NEGOTIATION_JOURNEY.md` plus the PNGs in `shots/` into the PDF.
Edit the markdown, run it again.

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
node negotiation-journey/reset.mjs                    # clear the demo thread
node negotiation-journey/journey.mjs s2-counter       # one scenario
node negotiation-journey/journey.mjs                  # lists them all
```

Reset between scenarios: the engine refuses a second offer while one is
pending, so without it each run photographs the last run's leftovers.

## The demo listing

**29291**, owned by the test host *Sam Tao*. Chosen because both sides are
reachable — the prettier listing 29296 belongs to a host whose credentials we
do not have, and half a walkthrough is no walkthrough. Priced ₹2,000 list /
₹1,700 ideal / ₹1,500 minimum, which is where every figure in the document
comes from.

## Two things worth knowing

**`reset.mjs` deletes rows** — negotiation offers and `DEAL%` coupons on that
one listing. It reaches the backend's database through the backend's own
config by absolute path, so it is not a script living in the production repo.

**Photographing this found three defects**, all fixed the same day: the host's
thread said "You countered" above a counter the platform sent for them; the
acceptance notice told hosts their *minimum* had been met when the line is the
ideal; and the guest's counter-back screen reported "with the host" without
reading the answer. Driving a real screen is how they surfaced — none of them
failed a test.
