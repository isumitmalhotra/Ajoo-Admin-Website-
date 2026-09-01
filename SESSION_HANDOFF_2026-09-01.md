# Session handoff — 2026-09-01

A full **API + visual sweep of every web screen and most of the app**, plus the
fixes it turned up. All three repos are clean and pushed; everything below was
verified on production or on the device, not merely shipped.

Coverage detail lives in **`SWEEP_COVERAGE.md`** (one row per screen).
Cross-platform notes are in **`WEB_MOBILE_PARITY.md`**.

---

## 1. Where things stand

| | |
|---|---|
| Web | **112 / 112 screens** — admin 56, host 18, guest 18, public 20 |
| App | ~33 screens — launch, guest side, the whole host portal |
| Repos | frontend `ee96399`, backend `d43b847`, monorepo `cf6508f` — 0 unpushed |
| Tester APK | **build 8** (`1.0.0+8`), signed, launched and logged in before handover |

---

## 2. The findings that mattered most

### Names were being corrupted on both platforms
`nameOnly`/`placeOnly` (web) and `name`/`place` (app) allowed `\p{L}` only. In
Devanagari a vowel sign is a combining **mark**, so **सुमित saved as समत** —
still letters, passes every validator, saves cleanly to utf8mb4, renders with no
mojibake. A *different name*, visible only to someone who reads the script. Now
`\p{L}\p{M}` on both. Found by writing a test with a real Devanagari name.

### Hosts were billed for stays that never happened
`hostDues.voidFor` ran on the guest's cancel path only. A host cancelling, or
marking a no-show, left the due PENDING, so Settlements demanded commission
against a check-in that will never arrive. **9 rows, ₹21,361, 2 hosts.** Code
fixed **and the data corrected** — see §4.

### Five working public pages answered HTTP 404
`/terms-condition`, `/Privacy-Policy`, `/state-regulation`, `/help-center` and
`/become-a-host/register` rendered perfectly and returned **404 + noindex**.
The SPA draws them client-side whatever the status line says, so they looked
fine to anyone opening them. Terms and Privacy returning 404 fails the checks
payment providers and app stores run.

### And the inverse: private areas told crawlers to index them
`index.html` declares `index, follow` and the edge served that shell unmodified
for `/admin/*`, `/account/*`, `/host/*`, `/booking/*`, `/checkout/*`. The
backend has always answered `noindex, nofollow` for those prefixes — it is never
asked, because not asking is the point of skipping.

### The app would not start
`main()` already guards `Firebase.initializeApp()` with a timeout and a catch.
It opened and died one screen later: `FirebaseMessaging.instance` sat in **field
initializers** on `AuthController` and `NotificationService` and throws when
Firebase is absent. Guarding the start and not the callers left the user just as
stuck.

### A guest in the property counted as zero ongoing stays
`getOngoingBook` filtered `book_status IN (4,5,6)` and missed **8 = "Booking
Confirmed"**, the most common live state. Status 4 has never been used by a
single booking. Found by cross-checking platforms: the guest app and the web
host dashboard both showed the stay; only the app's host dashboard said zero.

### The listing wizard took names the server refuses
**The original complaint, reproduced.** The field prints its rule above itself
and accepted `Test@#Villa123-Pine\&Co`. Fixed on both platforms, held to exactly
the server's `/^[A-Za-z0-9 &-]+$/`.

---

## 3. Everything else fixed

**Web** — admin login never redirected a `super_admin` (the frontend did not
know the role the backend issues); two sidebar rows lit at once (duplicate nav
key); all 56 admin screens shared the marketing `<title>`; three guest screens
and the listing wizard could not name themselves; the host "Upcoming Stays"
badge ignored approval; a payout column that could never fill; a payout failure
reason that reached the component and was dropped; keystroke filtering across
the listing wizard, offers, and payout bank fields.

**App** — money printed raw on **nine** host sites including the downloadable
PDF invoice; the booking list showed unpadded dates; the IFSC field would not
upper-case; the traveller form had no input filters at all; the counter-offer
price had only a keyboard hint.

**Backend** — schema text fields now declare their `kind`; admin property search
returns `coverImage`; payouts report the period they settle.

---

## 4. Production data changed

Only one thing, on explicit instruction:

```
node scripts/voidDuesForCancelledBookings.js --apply
```

9 host dues voided, ₹21,361, hosts 100 and 151. Host 100 went from 7 rows /
₹10,465 to **1 row / ₹1,135**. Zero PENDING dues now sit on a cancelled booking.
Verified by querying the table, not by trusting the script — its own count
printed `[object Object]` (a raw UPDATE returns a driver object, not a number).

---

## 5. Open — needs a decision

1. **29,232 live listings have no photograph.** 18 of 29,248 have an image.
   The biggest launch risk on the list, and a **content** decision. Do **not**
   solve it with a stock-photo fallback: that was removed deliberately, and the
   last attempt to attach images to this corpus published a real person's CV.
2. **The app reports a hardcoded "Version 1.0.0."** Build 8 looks identical to
   build 7 in-app, so support cannot ask which build a tester is on. Needs
   `package_info_plus`; do it as its own change, not beside an APK cut.
3. **KYC deep link.** An unverified guest is correctly refused at booking and
   correctly told why, but the app ignores the `verificationRequired` flag, so
   they must find Profile themselves. Friction at the moment of purchase.
4. Smaller: `aajoolive@gmail.com` on host support; the property-detail header
   collides with the status bar when scrolled; "continue to your stays" shows
   with **Host** selected; a missing bracket in the CMS privacy copy
   (`/admin/cms`, not a build); the repo owner's own photo on the test guest
   account.

Unchanged from before: live Razorpay credentials, the four RazorpayX env vars,
and credential rotation (still deferred until after testing, per instruction).

---

## 6. Traps this session taught

- **Appearance is not status.** Five pages rendered perfectly and answered 404.
  Check `curl -o /dev/null -w "%{http_code}"`, not the screen.
- **The CDN will lie to you about your own fix.** Three of those pages read as
  still-broken until a cache-busting query. Twice more, a deploy served an
  `index.html` pointing at an asset that 404'd — once taking the whole site
  down, once making a live fix look inert. **Compare the hash the page loaded
  against the hash the live HTML references** before concluding anything.
- **A blank page may be an outage, not a bug.** `/admin/property-analytics`
  looked like a perfect white-screen defect; it was the deploy. It re-tests fine.
- **Cross-check platforms.** The ongoing-stays bug was invisible from any single
  surface.
- **Grep the class, not the instance.** Fixing one raw-money screen found eight
  more; diffing routes against the title map found two title bugs that looked
  perfect on screen.
