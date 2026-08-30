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
| ✅ `/host/property-search` paginated | Returned every listing a host owns — 29,230 rows and 38.1 MB for test host 100, 18.7 s against the live DB. Now 20 a page (100 cap) with `minimal`, `q`, `status` and account-wide `counts`. **Both clients had to change**, because the default is now a page rather than everything — see the client rows below. |
| ✅ `/host/properties/policy-pending` capped | 29,228 rows / 2.47 MB on every host page load. Returns a page plus `total`. Web only — mobile has no policy banner. |
| ✅ Cancelling a booking never retracted the host payout | Guest refunded in full, host still queued to be paid. Live data had ₹19,752 queued against cancelled booking B182882. Full refund withdraws the payout, partial refund freezes it. |
| ✅ `po_on_hold` was write-only | Admin hold set it; the finance dashboard, the host's "pending payout" and the per-host admin summary all ignored it and counted held money as payable. |
| ✅ Guest cancellation wrote outside its transaction | `{transaction}` as the 3rd arg to `update()` again, this time in `cancelBooking`. |

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
| Host property list paginated | ✅ 20 a page + status tabs + name search on My Properties; Performance paginated; Calendar/Boost use a searchable picker; Dashboard stopped fetching listings entirely | ✅ `getHostProperties(page:, limit:, q:)`, `loadMoreHostProperties()`, "Load more" on the host profile list |
| Property **count** must read the total, not the list length | ✅ server `counts` feed the stat cards | ✅ `hostPropertyCount` → `data.totalCount`; the home stat tile would have read 20 for a host owning 29,230 |
| No stock photo for a listing with no photo | ✅ My Properties + dashboard Top Performing now show "no photo uploaded" | ⚠️ **not checked on mobile** — worth a sweep for the same pattern |
| List errors must not render as "you have nothing" | ✅ My Properties distinguishes failure from empty | ⚠️ mobile still uses `catch { error.value = ... }` without a retry surface |

> Both `HostController` classes were updated. `lib/controller/host_controller.dart`
> and `lib/ui/screens_host/host_controller.dart` share a class name, and `Get.find`
> keys on the name — the screens all import the `screens_host` one. This is the
> same trap already recorded for `AuthController` below, and it is still worth
> deleting the dead tree rather than maintaining both.
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

## Property page — stacked, on both (2026-08-23)

The website moved its property page from a tab switcher to one stacked
scroller; the app kept the switcher for a day and has now followed. Both
platforms render the same seven sections in the same order — About, Amenities,
House Rules, Location, Guest experiences, Host, Things to know — with the row
above them acting as a jump nav rather than a switch.

Amenities and "What's nearby" are trimmed against the same budget of 8 on
both, with the same never-split-a-group rule, so a 42-amenity villa does not
bury the host and the reviews under it.

The one deliberate difference: the web jump nav is sticky, the app's scrolls
away with the content. The app page is a `CustomScrollView` whose body is a
single `SliverToBoxAdapter`, so making the nav sticky means splitting that
sliver — and Airbnb's own app has no sticky section nav on a phone either.

## 2026-08-24 — renter-flow parity sweep (matching the web's guest-errors fixes)

| Web fix | Mobile state after this pass |
|---|---|
| Search carries dates+guests to property & checkout | **Added** — search sheet records When/Who on MapController.setStay; sent as `guests`/`from`/`to` on /properties/search; property page seeds from it |
| Accepted deal books from negotiations | **Added** — "Book at the agreed price" via shared `openPropertyById` (open_property.dart); accepted-vs-pending explainer copy matches web |
| Blog post links to its stay | **Added** — BlogPost model carries propertyId/name; post ends with "The stay in this story" |
| Coupon validated vs room+party charge | **Fixed** — was room-only |
| Per-category photo minimums (flow editor) | **Fixed** — PhotoRules.byCategory + minimumFor(); wizard step quotes/enforces the category's own number |
| Booking survives ID verification | Already existed (PendingBookingStore); **extended** to record/restore the party size the price now depends on |
| Google-lockout login message | Pass-through already worked (server message shown verbatim) |
| Catalogue-driven wizard (flow editor) | Automatic — app fetches /listing/schema, which categoriesForWizard() serves |
| LUXE skin on non-lux listing | N/A — app property page never wears the lux skin |
| Session guard / tablet sticky bar / sidebar scroll / map z-index | N/A — no mobile equivalent |
| Also: "1 homes near you" pluralised; map pin prints ₹3,200 not ₹3200.00 |  |

Commit: `771ad19`. flutter analyze clean (pre-existing infos only); 36/36 tests pass.

## 2026-08-24 — the four known gaps, closed

1. ~~No messages inbox on mobile.~~ **Built.** `MessagesService` speaks the same
   socket contract as the web's `useChat.ts`; the inbox lists threads with
   unread counts and the conversation loads history and sends. Chat
   notifications without a property now deep-link into it instead of falling
   back to home. Logout disposes the socket. (`2d5f305`)
2. ~~Search empty state~~ **Fixed** — the hero card said "Homes near you" over
   zero results; it now says nothing matched and clears the filters on tap
   (the fetch already retries at 20,000km, so distance is not the cause).
   **Map recentring already existed** — `map_screen` animates the camera on
   every `currentPosition` change. (`ef80758`)
3. ~~Profile completion tracker web-only.~~ **Built**, mirroring the web's
   fields, weights and wording, unit-tested against them. (`ef80758`)
4. ~~Two classes named `AuthController`.~~ **Deleted, and it was four, not
   one** — `AuthController`, `MapController`, `BookingController` and
   `HostController` each existed twice. The legacy copies stayed compiled
   because two live files imported `widgets/negotitaion_page.dart` for a model
   that lives elsewhere. 33 dead files removed. (`e444d97`)

Reachability for that deletion was computed from `main.dart` across **both**
`package:` and relative imports — a first pass that handled only `package:`
wrongly reported `init_binding.dart` as dead, which would have broken startup.
Worth repeating if the dead-code question comes up again.

## Host-side walk, 2026-08-24 — what a device found that code review had not

Every host screen driven on the emulator turned up a defect the code read as fine:

- **Confirm was missing entirely.** 29,244 of 29,252 listings have no
  booking-rules row and default to "approval", so nearly every booking waits on
  a host — and the app had no button. Added, then found it did not appear:
  a waiting request carries the bare status "Booked" and "Awaiting approval" is
  a DERIVED label. Both host buttons now read `lifecycleLabel`. (`bd5dc37`,
  `26bc348`)
- **Host cancel** did not exist. (`f0ea886`)
- **Guest cancelled without seeing the refund** — `/user/cancel/quote` is now
  fetched before the dialog. (`f0ea886`)
- **The calendar offered to block the past** — 14 Aug selectable on the 24th.
  (`20aa9a9`)
- **A failed payout gave no reason** — `po_failure_reason` was written and
  returned to nobody, on web AND app. (`c09ec98`, `9232037`, `cab6ec6`)
- **The booking card contradicted itself** — "Payment pending" chip beside
  "Paid online", a duplicated chip, a clipped chip, and paise in the price.
  (`91af849`)
- **The wizard's name rule** said 3 characters while its own hint and the
  server said 5. (`59c31ca`)

Wizard verified end to end: all five steps, draft persisted as property 29264
with capacity, pricing, booking-rules and amenity rows written, and correctly
hidden from public search. Submit is gated on readiness (photos, ownership
document, bank details) — not completed, as that needs real documents.

## Known open parity gaps

Absent from the app, present on web — a client will read these as missing
features rather than bugs:

1. **Refer & Earn** (guest and host).
2. **Host Performance** screen.
3. **Host Boost** — paid placement cannot be bought from the phone.
4. **Host notifications list** (the guest side has one).
5. **State/City are free text** in the app wizard; the web picks from the
   reference tables, which are the canonical address vocabulary. The app can
   therefore write values that do not match them.

---

## W2–W7 parity sweep — 2026-08-30

Everything the backend changed across W2 to W7 was checked against the app.
Two of them were **live regressions the server changes had created**, which is
the case for doing this sweep at all rather than assuming.

### Fixed

| What | Why it mattered |
|---|---|
| **Cancellation OTP** (W4) | The server began requiring an emailed code before a cancellation triggers a refund. The app sent only `bookingId` and `reason`, so **every app-side cancellation was being refused**. It now asks for the code first, using the same sheet the password change uses; backing out abandons the cancellation. |
| **Prebooking charged 10% by understating the price** (W2) | The app sent the deposit AS the room price, because the backend had no deposit concept — so a prebooked stay was recorded as costing a tenth of what the guest agreed to, and the host was owed that tenth. It now sends the true subtotal plus `payMode: "deposit"`, and the server computes the 10% itself. Verified live: a ₹19,000 room + tax = ₹19,950, gateway charged ₹1,995, and the row records ₹19,000 — not ₹1,995. |
| **Balance display + pay-remaining** (W2) | A deposit booking now carries `balanceDue`/`amountPaid` on the model, the pay-now action is offered for an outstanding balance as well as pay-at-property, and the button names the figure — "Pay the remaining ₹25,488" — rather than telling somebody who has paid 10% to "pay online instead". |
| **Capacity + seasonal rules** (W5) | The server began refusing adults + children over the total, a bedroom with no bed, and a seasonal property naming no months. The app sent all of it and got one unattached error back. Same rules client-side now, so the wrong field is the one that gets marked. |
| **Nine-value pricing grid** (W2) | Already done — commit `390f085`, the same day. |
| **Release builds could ship the TEST Razorpay key** (W8 · P0-02) | With no `--dart-define` the app fell back to the bundled test key, which does not fail — it succeeds and collects nothing, exactly the failure the backend carried for months. All five checkout paths now refuse to open a sheet that would take no money. `--dart-define=ALLOW_TEST_PAYMENTS=true` is the same explicit escape hatch the backend uses. |
| **`ApiConstants` had three constants holding one string** (W8 · P0-01) | `baseUrl` was wired to the one named `_dev` — the appearance of a prod/dev split with none of the substance. One value now, overridable with `--dart-define=API_BASE_URL=…`. |
| **Invented booking details** (W8 · P0-10, FE-10) | The checkout screen showed "Deluxe Suite" and "1 Adults" to every guest on every booking. Room type now comes from the listing's category; the party size is not on that screen's model, so the row does not render rather than lying. |

### Checked, and already correct

- **Negotiation guards (W3).** The app's offer service surfaces the server's own
  message on failure, so the new 409 ("you already have an offer waiting") and
  429 ("you have used all 3 offers") responses read correctly with no change.
- **Token storage (FE-11).** Already `FlutterSecureStorage`, not SharedPreferences.
- **W6 (SEO) and W7 (admin control plane)** have no app surface.

- **Pay-at-property settlements (W10) — shipped on both, same day.** Web
  `/host/settlements` and the app's host menu → Settlements. The app was not left
  behind on this one deliberately: a host who works from their phone would still
  have met Aajoo's share of a cash booking for the first time as a smaller payout,
  which is precisely the outcome the screen exists to prevent. Payment reuses the
  Boost screen's order → checkout → verify path, so there is one payment sequence
  on the platform rather than two that drift. `test/host_dues_test.dart` pins the
  model against the payload the server actually sent.
- **The settlement payment is proven on BOTH platforms.** Web on 2026-08-30
  (`pay_TW1vgIgPR2Ogw4`, ten dues, ₹11,896.25) and then the app, on an Android
  emulator, from a debug build signed in as the real test host: order
  `order_TW2kKbQzAcQJP6` → **`pay_TW2l6qSeY3Rddl`, netbanking, captured**, due
  B794077 settled for ₹1,453. The screen fell to ₹0 payable and the booking moved
  into "Settled · Paid by you". The `razorpay_flutter` leg — native checkout →
  `PaymentSuccessResponse` → `/host/dues/verify` — is a different SDK with a
  different callback shape from `checkout.js`, so this could not be inferred from
  the web run and had to be driven separately.
- **The test needed a payable due, and making one exercised the raise hook.** Every
  outstanding due belonged to a stay starting weeks out, so nothing was payable.
  A fresh cash booking dated today (`B794077`, ₹6,400 + ₹320 GST) produced one —
  which also proved `hostDues.raiseFor` fires on booking creation: ₹960 + ₹173 +
  ₹320 = ₹1,453, host keeps ₹5,267, identical to the online split.
- **Prefill was missing on web and present on the app** — the reverse of the usual
  direction. The Flutter screen passed `prefill` from `AuthController` from the start;
  the web screen passed none, so Razorpay interrupted every host with a "Contact
  details" step before they could pay. Fixed on web. Worth remembering that parity
  gaps run both ways: the app is not always the one behind.
- **`--dart-define=API_BASE_URL` now reaches the app.** W8 made `ApiConstants`
  overridable, but sixteen services each carried their own hardcoded copy of the
  host, so the flag moved a constant nobody read. All sixteen now refer to it.

- **Offers (2026-08-31) — shipped on both, same day.** A host/admin discount the
  guest never types a code for. The app carries `PropertyOffer`, the struck-through
  price and "% off" chip on the stay card, the discounted headline on the property
  page, and the checkout gate that withdraws *Pay at property* when the offer does
  not allow it — with a sentence saying why, rather than letting the server refuse
  it at the last step. `test/property_offer_test.dart` pins the model against the
  payload the server actually sent.
  **Verified by widget test rather than by eye.** The emulator's display pipeline
  broke mid-verification — the app runs and adb responds, but the framebuffer never
  updates, and a fresh boot restored the same frozen frame from a Quick Boot
  snapshot. `test/offer_card_test.dart` renders the real card instead and asserts
  what a guest would see: both prices, the "% off" chip, the original actually
  struck through, and none of it on an undiscounted card. That is the durable
  version of the check — a screenshot proves it once, this proves it every run.
  Still worth one look on a working device before release, for the property page
  and the checkout gate, which have no widget test yet.

### Still open on the app

- **API path/versioning reconciliation with the spec** (P1-11).
- **A full pass on FE-13…FE-18** (no-op buttons, stock imagery) — spot-checked
  only; the guest flows named in P0-10 are done.
- The five long-standing gaps listed above this section.
