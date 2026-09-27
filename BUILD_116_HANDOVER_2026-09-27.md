# Build 116 — please install this before any further app testing

**27 September 2026.** For Nameesh and the tester.

---

## The file

| | |
|---|---|
| Filename | `aajoo-homes-1.0.0-build116-release.apk` |
| sha256 | `0afb73e2f18cc6c4eb617f13473a6d0ed67a1d981db5ca84f4799ec83c8eac57` |
| Size | 100,477,287 bytes (95.8 MB) |
| Package | `com.aajoo.aajoohomes` |
| versionName / versionCode | 1.0.0 / **116** |
| Points at | `https://api.aajoohomes.com` — verified inside the artifact |
| Payments | **Test mode** (`rzp_test_…`). No real money can move. |

---

## Why this matters more than a normal update

**Any build numbered 112 or lower is talking to a different server *and* a
different database.**

We confirmed this by reading the compiled apps themselves, not from notes:
build 112 contains `aajaodev.onrender.com`; builds 113 and 116 contain
`api.aajoohomes.com`. Build 113 was the first one ever pointed at a production
host.

And those two servers do not share data. The old one is still connected to the
original Clever Cloud database; the live platform moved to PlanetScale on
24 September.

**So an older build does not fail. It works perfectly — against a copy of the
world that nobody else can see.** Sign-ups, listings, bookings and
negotiations made there are invisible to the website and to anyone on a newer
build. Nothing errors, nothing warns.

That is worth knowing for two reasons:

1. **Testing done on an old build proves nothing** about the live platform, in
   either direction.
2. **Any "it didn't save" or "my booking vanished" report since 24 September
   may not be a defect at all** — it may simply have happened in the other
   database.

---

## How to install

**Please uninstall the existing Aajoo Homes app first, then install this
file.** Installing over the top would technically work, but the old app may be
holding a saved login issued by the old server against the old database — and
a stale session is exactly the kind of thing that produces a confusing failure
an hour later. There is nothing worth keeping in the old install.

1. Uninstall **Aajoo Homes** from the phone
2. Install `aajoo-homes-1.0.0-build116-release.apk`
3. Sign in again

---

## How to confirm you are on the right build

**The app itself will not tell you.** Settings shows only "Version 1.0.0" —
the build number is deliberately not shown to users, so 112 and 116 look
identical from inside the app.

Check it from Android instead:

> **Settings → Apps → Aajoo Homes → scroll to the bottom**
> It should read **1.0.0 (116)**. The number in brackets is the one that
> matters.

If you want to be certain the downloaded file is the right one before
installing, its sha256 is above.

---

## What is in 116

The two items from the 26 September screenshots:

* **The weekend price headline.** A one-night Saturday stay showed
  "₹5,000/night" above a "₹10,620 total". The total was correct — the host had
  set ₹9,000 for Saturdays, plus 18% GST. The headline was reading the flat
  price column instead of what those particular nights cost. It now shows the
  real nightly figure.
* **Minimum stay.** A 1-night stay could be priced on a listing that says
  "Minimum stay 3 nights". It is now refused, with the host's own rule quoted.

Both were present on Android as well — it is one codebase, so this was never
an iOS-specific fault. The real gap was between the app and the **website**,
which had already fixed both.

Also: one widget that rendered differently on iOS and Android was replaced, so
the two platforms now draw the same control.

**Not yet driven by us:** both fixes are on the guest-facing property page,
and we have not been able to exercise them on a device because the new database
had no guest account at the time of the build. Worth a look when you are in
there.

---

## After everyone is on 116

Once you both confirm the install, we will switch off the old Oregon server.
It is the last thing keeping the abandoned database reachable, and leaving it
running is what allows an old build to quietly write to nowhere.
