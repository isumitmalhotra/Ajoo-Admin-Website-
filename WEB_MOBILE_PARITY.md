# Web ⇄ Mobile Parity

Every renter/host fix on the web has to land on mobile too, or the same bug
gets found twice and fixed twice. This is the ledger for that.

**The rule:** when you fix something in `aajao-frontend-vercel` that touches
renter or host behaviour, add a row here and close it on `aajoo_app_2026`
before calling the fix done. Backend fixes are shared automatically — they
only need a row if the *client* has to change to benefit.

Legend: ✅ done both sides · ⚠️ web only · — not applicable to mobile

---

## Shared backend (both clients benefit automatically)

| Fix | Notes |
|---|---|
| ✅ Host cancel threw `validate` undefined | Wrong schema module; also broke `/host/booking/no-show`. |
| ✅ Cancellation writes ran outside the transaction | `{transaction}` passed as the 3rd arg to `Model.update`, which ignores it. |
| ✅ Cancellation notice + refund narrative | In-app notification + email, both clients. |
| ✅ `un_payload` double-encoded JSON | Readers unwrap up to 3×; fixing only the writer would have regressed the listing endpoint. |
| ✅ OTP: bypass removed, 6 digits, 5-attempt lockout, 10-min expiry | Same `/user/verify-otp` for web and mobile. |
| ✅ Unverified signup can resume instead of "User already exists" | Backend returns `{needsVerification, userId}`. **Neither client read it** — both showed the raw message as an error while a fresh code sat in the inbox. Fixed on both. |
| ✅ Email via Brevo (OTP, welcome, booking, cancellation, invoice) | Transport-level, both clients. |
| ✅ A14 category re-seed to the spec's 9 | Both read `tbl_categories`. |
| ✅ `/user/switch-mode` | Added so mobile could stop storing the password. |

## Client-side logic — must be ported deliberately

| Fix | Web | Mobile |
|---|---|---|
| **Stay clock** — 2 PM check-in / 11 AM IST check-out | ✅ `redesign/lib/stayClock.ts` | ✅ `lib/utils/stay_clock.dart` + unit tests |
| "Currently Staying" after checkout had passed | ✅ | ✅ ongoing widget + dashboard count now filter on the real window |
| Property search: wide-radius fallback when nothing is nearby | ✅ `useProperties` | ✅ `getProperties` retries at 20000 |
| Radius sent as a number, omitted when blank | — | ✅ mobile-only bug (string radius failed the request) |
| Category row driven by the API, not a hardcoded list | ✅ | ✅ |
| Google Sign-In | ✅ | ✅ |
| Password never persisted on the device | — | ✅ |
| Notification tap opens the right screen | ✅ `notificationLink.ts` | ✅ `lib/utils/notification_link.dart` + unit tests |
| Resume an unverified signup instead of erroring | ✅ `signupUser` returns `resumed` | ✅ `SignupResponse.needsVerification` → the code screen |
| Signup requires a real ID type + number | ✅ | ✅ the "Skip for now (dev)" button that wrote a fake Aadhaar is gone |
| Referral code the user typed is actually sent | ✅ | ✅ was hardcoded to `"0000"`, discarding every real code |
| Profile completion tracker | ✅ | ⚠️ not on mobile |
| Search empty state names the place + suggests real cities | ✅ | ⚠️ mobile search has no equivalent |
| Map recentres on the searched place | ✅ | ⚠️ mobile map not audited |
| Scroll reveal / motion vocabulary | ✅ `motion.ts` | ✅ `lib/ui/motion/aajoo_motion.dart` — guest screens **and** host dashboard + bookings |

## Web-only by nature (no mobile equivalent needed)

CMS editor · SEO meta / JSON-LD / canonicals · Newsletter signup ·
Knowledge Center page · admin portal · Getting Started marketing page.

---

## What the first full audit turned up (2026-08-09)

Four defects that existed only on mobile, plus one that turned out to be on
both. Each is closed; they are listed because they show the shape of what this
ledger is for.

1. **A stay stayed "current" past checkout.** `/booking/ongoing` returns stays
   at date granularity and its own comment says the client derives the rest.
   The web does. Mobile did not → `lib/utils/stay_clock.dart` + tests.
2. **A "Skip for now (dev)" button on signup step 3** submitted
   `doc_number: 000000000000` as an Aadhaar number. Real accounts were being
   created with fabricated government-ID data. Removed; the type and number are
   required and format-checked, exactly as on the web. The ID *scan* stays
   optional on both.
3. **Every signup sent `user_ref: "0000"`** — a hardcoded placeholder that
   overwrote whatever the referral screen collected. No mobile signup has ever
   been attributed to a referrer, and the screen asking for the code was
   decorative.
4. **Notifications went nowhere.** The in-app list navigated only for rows with
   "negotiation" in the title *and* a propertyId; everything else was marked
   read and dropped. Push taps returned early unless the payload carried both
   `route` and `type` (most carry neither), routed on `type` alone — the field
   the web proved lies — and otherwise handed the stored path to `Get.toNamed`.
   Those paths are the web's (`/messages`, `/bookings`) and are not routes here,
   so a tap landed on the unknown-route page.
5. **Neither client read `needsVerification`.** Fixed on both — see above. The
   ledger previously claimed the web handled it; it did not.

## Screen-by-screen pass, renter side (2026-08-09)

Walking the app tapping every control, against the guide's verified web list.

| Found | Status |
|---|---|
| **No way to log out.** The Profile tab's settings `SliverList` was commented out during the redesign, and the bottom-nav shell replaced the drawer that held the other copy | ✅ restored |
| `Reveal` hid content below the fold inside shrink-wrapped lists — "Curated for you" was a screen-high blank gap | ✅ fixed (my regression) |
| "Hosted by Aajoo Host" / "Superhost · Replies in 1 hr" were a literal and a default parameter; Host Details showed the phone as the name over a hotlinked stock photo | ✅ uses `/properties/host/:hostId` |
| "Aajoo Verified Home" shown on every listing | ✅ gated on `is_verify` |
| "Guest Favorite" on every card; heart button `onPressed: () {}` | ✅ real category; wired to `BookmarkService` |
| Dead "Confirm Booking" FAB behind a flag never set true | ✅ removed |
| Amenity chips Material blue, tag chips Material purple; "Amenities" printed twice | ✅ brand tokens, one heading |
| Back arrow on the Profile root tab did nothing | ✅ only shown when it can pop |
| Bookings tabs bucketed on status text, so finished stays stayed under Upcoming | ✅ uses the stay clock |

**Ratings — fixed properly (backend + both clients).** `utils/propertyRatings.js`
aggregates avg + count from `tbl_reviews` in one grouped query per page and
attaches them to `/properties/search`, `/properties/:id` and the listing
endpoint; `sort_by=rating` now actually sorts. Unrated returns `null`, not
`0.0`, and both clients render **"New"**. The app's twelve hardcoded `"4.5"`s,
its literal `· 164` review count, and "Free Cancellation" on every card are
gone; the web's `|| 4.6` fallback is gone. **With real data flowing every
listing reads "New" — there are zero reviews in the database.** The invented
number was hiding that.

**Data problems — fixed.** `scripts/fixPropertyData.js` (dry-run by default)
normalised 8 stay-time rows: the column held `"14:00"`, `"12:00"`,
`"05:05"/"05:58"` (nonsense, and what the app displayed), `"2:00 PM"` 12-hour
text and nulls, all at once. Unreadable/implausible values now carry the
platform policy 14:00 / 11:00; plausible host-set values are left alone. And
property 4 ("Kasauli Homes") was taken offline — its owner had
`user_isDelete = 1`. Root cause: admin delete flagged the user and touched
nothing else, and unlike self-serve delete it did not even refuse hosts. It now
deactivates the host's listings, and `withLiveHosts()` is the read-side
backstop.

**Still open:** the stay clock enforces 2 PM / 11 AM from constants on both
clients, so a per-property check-in time is displayed but never honoured —
either the clock should read it or the page should stop showing it.

**Host portal untested.** Requires signing in as a host, which means entering a
password. Needs a human pass.

## Pricing — the app was quoting one number and the backend charging another

**The double-tax was a mobile bug, not a backend one.** `/booking/create` reads
`price` as the **pre-tax room subtotal** and adds GST itself. Both web callers
(`redesign/pages/guest/Payment.tsx`, `pages/user/FinalBookingPage.tsx`) send the
subtotal and always have. The app sent the already-taxed total, so the backend
taxed the tax: booking **B618787** was quoted and charged ₹23,020 while the row
stored `book_total_amt` **₹24,171** — and pay-on-arrival collects
`book_total_amt`, so that guest was in line to be billed ₹1,151 over the quote.
The app's own coupon branch already sent the subtotal; every booking now does
what that branch did.

Three more faults in the same arithmetic, which lived inline **three times** in
`property_page.dart` (header, breakdown, submit) and is now one shared
`lib/utils/booking_pricing.dart` — the Dart counterpart of the web's
`summarize()`, with **10 tests**:

- **GST banded on the stay total, not the nightly tariff.** A ₹4,000/night room
  booked two nights is ₹8,000 for the stay but still 5%. The backend bands on
  `property_price` and the web on `perNight`; only the app banded on the total,
  showing 18% where the guest was charged 5%.
- **A ₹10 "Platform Fee" nothing collects.** Not in the backend, and dropped
  deliberately on the web. It was a line item in the UI and nowhere else.
- **The coupon discount was never shown.** `_couponDiscount`/`_couponPercent`
  were written and never read, so the app said "Applied — 10% off" and then
  quoted an undiscounted price while the backend applied the discount anyway.
  The quote was wrong in the guest's favour, which is still wrong.

**Razorpay amounts now come from the order** the backend just created, in both
the property page and the negotiation page. With `order_id` set Razorpay charges
the *order's* amount whatever the client passes, so a locally-computed figure
could only ever disagree with what is really taken.

**Left alone on purpose — prebooking.** It charges a 10% deposit, but the
backend has no notion of one: it reads `price` as the room subtotal whatever it
is given. Sending the subtotal would charge a deposit guest the full stay;
sending the deposit records the room as costing 10% of its real price, which is
what it does today. Choosing between those is not a bugfix — it needs an
`advanceAmount` the backend understands. The path keeps its existing behaviour
rather than silently changing what a guest is charged.

## Known open parity gaps

1. **No messages inbox on mobile.** The only conversation surface is the
   per-property negotiation thread, so a chat notification can only be opened
   when the payload names a property. Without one it lands on home rather than
   a route that does not exist.
2. **Search empty state and map recentring** have no mobile equivalent.
3. **Profile completion tracker** is web-only.
4. **Two classes named `AuthController`** (`lib/controller/` and
   `lib/ui/screens_common/auth/`). `Get.find` keys on the name, so importing the
   wrong one hands back the live instance typed as a class it is not — one file
   was already doing this. The legacy tree is dead and should be deleted.
