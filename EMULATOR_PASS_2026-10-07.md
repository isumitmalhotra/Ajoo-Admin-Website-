# Emulator pass — 2026-10-07 (build 121, profile, against production)

Pixel_10_Pro_2, API 36. JDK 21. Emulator clock matched the host to the second
throughout. Built 1.0.0+121 with `--dart-define=API_BASE_URL=https://api.aajoohomes.com`
and drove it signed in as the guest (user 13) and then the host (user 12) who
own B871634 between them.

## The headline finding: the clock was approving bookings

B871634 — paid ₹3.15, never approved, check-in 2 PM. At 00:30 both platforms
read "Awaiting approval". By 14:18 the app's Ongoing tab badged it **"Staying
now"** and the website said **"Stays you're checked into right now"**, with a
Check-out button. Nobody approved anything; the clock moved.

Two guards carried the same blind spot, and both state the right principle in
their own comments — *a request the host has not answered is not a stay in
progress, however the clock reads*:

    lifecycleLabel()   s.includes("book") && !s.includes("confirm")
    useOngoing()       rawStatus.includes("book") && … && !checkedIn

Both were written for status 5 "Booked", so both test for the word **"book"**.
An online booking awaiting the same approval sits at "Payment Pending" with
`book_is_paid = 1` and contains no such word, so it fell past the guard to the
date check. The paid case now sits in the same expression, ABOVE the clock.

A real check-in event still outranks it. An approved stay still reads "Staying
now". A finished one still reads "Completed".

Fixed on web (`fba17c5`) and app (`8daf8d3`), as one pass.

## Also found and fixed

- **The app lacked the paid-awaiting-approval rule entirely.** The Dart helper
  had only the UNPAID branch; the paid companion line did not exist, and 7 of 8
  callers passed no payment facts. (`722486d`)
- **The debug fallback pointed at a dead host.** `aajaodev.onrender.com` has
  answered 503 since the cutover. Verified: aajaodev 503, api.aajoohomes.com
  200. (`722486d`)
- **"2 homes in Gurugram"** over stays in Ramnagar and Kasauli. The log shows
  the search widened 50km → 500km, which is deliberate; asserting "in" was not.
  The card's own subtitle said "around" one line below. (`bcc670e`)

## Verified on screen after the fixes

| Screen | Reads |
|---|---|
| Guest → Bookings → Ongoing | **Awaiting approval** · ₹3 · Paid |
| Host → Bookings → Ongoing | **Awaiting approval** + **Paid**, ₹3, online |
| Host → booking detail | Awaiting approval + Paid, **Confirm this booking** / Decline, guest contact |
| Host → Dashboard | Collected ₹3 · Total Bookings 1 · **Ongoing Stays 0** · Properties 1 · Offers 0 |
| Host → Profile | H.Ashish Kumar, phone 9882498033 — matches the DB |

The host detail screen is the one that matters most: "Awaiting approval" beside
a **Confirm** button is the pairing the original defect broke.

## Checked and cleared, not reported as defects

- **The ANR was debug-build overhead.** The debug build ANR'd repeatedly on the
  home screen (`ClientParamsBlocking` on the main thread inside
  `MapView.onCreate`, a 1s binder call to the maps auth service — no
  authorisation failure). The **profile** build shows none. A debug build on an
  emulator is not a fair performance test and this was not reported as a
  product fault.
- The referral code "AJD" is correct by design: `"AJ" + base36(userId)`.

## Not individually driven
Host Messages and Calendar were opened but not inspected screen by screen;
no crashes were logged throughout. The guest-side payment flow was deliberately
not exercised: this build carries no live Razorpay key, so checkout cannot open
— which removes any chance of a real transaction on production.
