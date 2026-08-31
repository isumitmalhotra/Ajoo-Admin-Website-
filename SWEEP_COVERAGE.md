# Full sweep — API + visual, web and mobile

Started 2026-09-01. One row per screen. A row is only marked done when the page
was **opened**, its **network payload read**, and its **layout checked** — not
when the code was read.

Bugs found in a module shared by both platforms (host dashboard, renter
dashboard, bookings, profile) are fixed on **web and app in the same pass**,
per the standing parity rule.

## Legend

- `[ ]` not visited
- `[~]` visited, issues open
- `[x]` visited, clean or fixed
- **API** = network payload inspected, not just "the page rendered"
- **VIS** = layout, overflow, truncation, broken images

## Surface area

| Area | Screens |
|---|---|
| Web admin | 56 |
| Web host | 23 |
| Web guest/account | 18 |
| Web public | 42 |
| App (renter / host / common) | 64 / 46 / 36 |
| Backend endpoints declared | 351 |

---

## Web — Admin (56 / 56) — COMPLETE

| # | Route | API | VIS | Notes |
|---|---|---|---|---|
| 1 | /admin/login | x | x | Fixed earlier: super_admin was never redirected |
| 2 | /admin/dashboard | x | x | Finance card failed once on first paint, not reproducible (3 further logins clean) |
| 3 | /admin/users | x | x | 20 rows. "NaN" alert was a false positive - names containing "nan" |
| 4 | /admin/hosts | x | x | 10 rows. Wide table is inside the overflow-x container, correctly contained |
| 5 | /admin/properties | x | ~ | **FIXED**: /admin/properties/search returned no image field, so all 29,248 rows drew a placeholder |
| 6 | /admin/bookings | x | x | 20 rows, counts reconcile |
| 7 | /admin/listing-queue | x | x | 1 row |
| 8 | /admin/analytics | x | x | 12 rows |
| 9 | /admin/booking-analytics | x | x | 12 rows |
| 11 | /admin/payments | x | x | 13 rows |
| 12 | /admin/negotiations | x | x | 24 rows |
| 13 | /admin/reviews | x | x | 2 rows |
| 14 | /admin/disputes | x | x | 19 rows |
| 15 | /admin/finance | x | x | Revenue matches the DB exactly |
| 16 | /admin/finance/host-dues | x | ~ | Shows the 21,361 of bad dues; backfill script written, not run |
| 17 | /admin/finance/ledgers | x | x | 10 rows |
| 18 | /admin/finance/payouts | x | x | 10 rows |
| 19 | /admin/finance/invoices | x | x | 10 rows |
| 20 | /admin/finance/reconciliation | x | x | 10 rows |
| 21 | /admin/finance/reports/revenue | x | x | 3 rows |
| 22 | /admin/categories | x | x | 14 rows |
| 23 | /admin/amenities | x | x | 39 rows |
| 24 | /admin/tags | x | x | 4 rows |
| 25 | /admin/offers | x | x | 4 rows |
| 26 | /admin/coupons | x | x | 20 rows |
| 27 | /admin/blogs | x | x | 8 rows |
| 28 | /admin/support | x | x | 0 tickets |
| 29 | /admin/contact-messages | x | x | 0 messages |
| 30 | /admin/settings | x | x | renders |
| 10 | /admin/property-analytics | x | x | **Re-tested: fine, 20 rows.** The earlier blank was the outage |
| 31 | /admin/reports | x | x | |
| 32 | /admin/faqs | x | x | 35 rows |
| 33 | /admin/seo | x | ~ | **FIXED**: sidebar lit Global SEO AND Redirects together (duplicate nav key) |
| 34 | /admin/seo/redirects | x | ~ | same fix; now exactly one active row per page |
| 35 | /admin/seo/page | x | x | Correct empty state - tells you to open it from a Properties/Blog row |
| 36 | /admin/boost | x | x | 4 rows |
| 37 | /admin/refer | x | x | 2 rows |
| 38 | /admin/cms-home | x | x | 54 inputs |
| 39 | /admin/cms | x | x | 34 inputs |
| 40 | /admin/terms | x | x | |
| 41 | /admin/roles | x | x | 2 rows |
| 42 | /admin/logs | x | x | |
| 43 | /admin/status | x | ~ | **Legacy pre-redesign shell**, documented as deliberate. See note below |
| 44 | /admin/finance/payouts/history | x | ~ | **FIXED** title (was "Payout Queue") |
| 45 | /admin/finance/payouts/schedules | x | x | Empty state correct; **validation verified live** in the New-schedule form |
| 46 | /admin/finance/reconciliation/records | x | x | 20 rows |
| 47 | /admin/finance/reports/commission | x | ~ | **FIXED** title (was "Financial Overview") |
| 48 | /admin/finance/reports/tax | x | ~ | same |
| 49 | /admin/finance/reports/cashflow | x | ~ | same |
| 50 | /admin/properties/new | x | x | |
| 51 | /admin/properties/form | x | ~ | **FIXED** title |
| 52 | /admin/properties/form/:id | x | x | 13 of 23 inputs hydrate from the listing |
| 53 | /admin/finance/ledgers/host/:hostId | x | x | 10 rows |
| 54 | /admin/finance/ledgers/guest/:userId | x | x | 10 rows |
| 55 | /admin/finance/invoices/:invoiceId | x | x | reached by clicking a row |
| 56 | /admin/finance/payouts/:payoutId | x | x | reached by clicking a row |

---

## Findings

_Recorded as they are found, with the fix and the platforms it landed on._

### 2026-09-01

**Page titles — all 56 admin screens shared the marketing `<title>`.** `HostShell`
and `GuestShell` each call `useDocumentMeta`; `AdminShell` never did. With a
dozen admin tabs open they were indistinguishable. Now derived from the
sidebar's own nav label, reusing the longest-prefix match already computed for
the active item. Also `"statements"` was missing from `HostShell`'s
`SCREEN_TITLES`, so `/host/statements` read the bare "Host".

**The listing-approval screen could not show the listing's photo.**
`/admin/properties/search` returned no image field at all while the table has a
thumbnail slot, so every one of 29,248 rows drew the same placeholder — on the
screen where an admin decides whether to publish a listing. Second slot-that-
can-never-fill found this week, after the host payout table's "Booking" column.
Fixed with the existing `coverImagesFor` helper, named `coverImage` because
that is what the table already reads, so no client change was needed.

**Production went down mid-sweep, and it was mine.** After the title deploy the
live `index.html` referenced `/assets/index-CHODQ3UE.js`, which 404d — no
JavaScript loaded and *every* page on the site rendered an empty
`<div id="root">`, public pages included. Not a cache artefact:
`X-Vercel-Cache: MISS`, `Age: 0`, and a cache-busting query returned the same
stale reference. The asset hash from a local build of the same commit served
200, so the assets were fine and the HTML was wrong — a Vercel deployment that
published a mismatched pair. An empty commit forced a clean rebuild and the
site recovered ~80s later.

**Lesson recorded:** `/admin/property-analytics` was probed during that window
and read as a blank page. It looked exactly like a real white-screen bug. It
was the outage. Any "blank page" reading has to be checked against whether the
bundle actually loaded before it is written down as a defect.

---

## The finding that outranks everything else in this sweep

**29,230 of 29,248 listings have no photograph. 29,232 of them are ACTIVE.**

| | |
|---|---|
| Properties (not deleted) | 29,248 |
| Active, visible to guests | 29,232 |
| With any photo | **18** (0.062%) |
| Without | **29,230** |

Confirmed guest-side, not just in the tables: `POST /properties/search` returns
`coverImage: null, images: []` for seeded listings. (That endpoint requires
latitude and longitude — it 400s without them.)

Found while checking why the admin listing table drew a placeholder on every
row. The missing `coverImage` field was real and is fixed, but it turned out to
be the smaller half: the field is now returned and there is almost nothing to
put in it.

This is a **content** blocker, not an engineering one, and it is the single
biggest launch risk on the list. It should not be "fixed" by reinstating a
stock-photo fallback — that was removed deliberately, because a stock image on
a real listing is a lie and it made every listing look like the same cottage.
The honest placeholder is what makes the gap visible.

Note for whoever sources the images: the last attempt to attach photos to the
seeded corpus published a real person's CV as a property photo.

---

## Admin sweep complete — what it turned up

**Two sidebar rows lit at once.** Global SEO and Redirects shared the nav key
`"seo"`, and the sidebar marks active every item whose key equals `activeId` —
so both highlighted on both pages and neither told you where you were. The only
duplicate among the 40 entries.

**Page titles.** All 56 shared the marketing `<title>`; now derived from the
sidebar's own nav label. Four sub-routes needed explicit overrides: the
commission, tax and cashflow reports were all titled "Financial Overview",
because the nav links the reports section at its `/revenue` path and the other
three do not start with it.

**The listing-approval screen could not show the listing's photo** — and behind
that, the finding that matters most: **18 of 29,248 properties have a photo**.

**`/admin/status` is the last legacy screen.** Old wordmark, old sidebar, old
header, outside `AdminShell` — and the code documents it as deliberate ("no
redesigned equivalent yet"). It edits `tbl_book_statuses` titles, which every
booking badge on web and app string-matches on. Not a defect today: all the
matching is tolerant (`.trim().toLowerCase().includes(...)`), which is why the
trailing space in the live value `"Check In "` is absorbed. It is a latent risk
— renaming a status there would silently change badges platform-wide — and it
is unreachable from the redesigned sidebar, so an admin cannot find it anyway.

**Verified live, not just shipped:** the account-number and IFSC filtering added
in the validation pass was driven on the real New-schedule form —
`12 34-ab#56` became `123456`, `hdfc-0001@23` became `HDFC000123`.

**Clean:** no horizontal overflow on any of the 56, no broken images, no
`NaN` / `undefined` / `[object Object]` / `Invalid Date` reaching the UI, and
finance figures matching the database exactly.

---

## Web — Host (18 / 18) — COMPLETE

| # | Route | API | VIS | Notes |
|---|---|---|---|---|
| 1 | /host/dashboard | x | ~ | **FIXED**: Upcoming Stays badged from dates alone, ignoring approval |
| 2 | /host/bookings | x | x | 30 rows; tabs reconcile 5+7+18 |
| 3 | /host/earnings | x | ~ | **FIXED**: "Booking" column that could never fill; failure reason now shown |
| 4 | /host/settlements | x | ~ | Shows the bad dues; backfill written, not run |
| 5 | /host/statements | x | ~ | **FIXED** title (was the bare "Host"); totals reconcile with Earnings |
| 6 | /host/properties | x | x | 29,237 = 29,227 active + 10 inactive. Prices real on active listings |
| 7 | /host/calendar | x | x | |
| 8 | /host/messages | x | x | 2 threads |
| 9 | /host/negotiations | x | x | |
| 10 | /host/offers | x | x | **Validation verified live**: -50 to 50, 999 to 90, 1e5 to 15 |
| 11 | /host/payouts | x | x | 10 rows |
| 12 | /host/performance | x | x | |
| 13 | /host/profile | x | x | 15 inputs |
| 14 | /host/settings | x | x | |
| 15 | /host/support | x | x | 4 inputs |
| 16 | /host/boost | x | x | |
| 17 | /host/refer | x | x | |
| 18 | /host/list-property | x | ~ | **FIXED** title (called itself "Your properties"); resumes a draft correctly |

### Host sweep notes

**The wizard called itself "Your properties".** HostShell derives the title from
`active`, which also drives the sidebar highlight. The wizard passes
`active="properties"` because that is where a host looks for it — and inherited
the wrong title. The two answer different questions; `title` is now an optional
override that moves one without the other.

**Checked, not a bug:** two listings showed "₹0/night" on the Properties list.
They are unpriced *inactive* test entries — 0 of 20 active listings are
zero-priced.

**Verified live rather than assumed:** the offer-percent clamp added in the
validation pass. Typing `-50` now yields `50`, so the live preview can no
longer show guests paying MORE than list price, which is what a negative
discount produced before.

**Clean:** no horizontal overflow on any of the 18, no broken images, no
`NaN` / `undefined` / `[object Object]` / `Invalid Date`.

---

## Web — Guest (18 / 18) — COMPLETE

Signed in as user 101, the same guest whose bookings appear on the host side,
so the screens had real data rather than empty states.

| # | Route | API | VIS | Notes |
|---|---|---|---|---|
| 1 | /account/dashboard | x | x | |
| 2 | /account/upcoming | x | x | |
| 3 | /account/ongoing | x | x | |
| 4 | /account/past-stays | x | x | |
| 5 | /account/cancelled | x | x | |
| 6 | /account/next-booking | x | x | |
| 7 | /account/transactions | x | x | 14 rows |
| 8 | /account/saved-stays | x | x | |
| 9 | /account/messages | x | x | |
| 10 | /account/negotiations | x | ~ | **FIXED**: the one guest screen still titled "Your account" |
| 11 | /account/notifications | x | x | |
| 12 | /account/reviews | x | x | |
| 13 | /account/review | x | ~ | **FIXED**: titled "Your reviews" |
| 14 | /account/profile | x | x | |
| 15 | /account/settings | x | x | 11 inputs |
| 16 | /account/support | x | x | |
| 17 | /account/refer | x | x | |
| 18 | /account/directions | x | ~ | **FIXED**: titled "Upcoming stays" |

### Guest sweep notes

**Three screens could not say what they were.** `"negotiations"` was missing
from `GuestShell`'s `SCREEN_TITLES` outright. Directions and Write-a-review
deliberately borrow another entry's `active` so the sidebar points where a
guest expects — Directions under Upcoming stays, Write a review under Your
reviews — and inherited that entry's *title* along with it.

The highlight answers "where does this live"; the title answers "what is
this". They are not the same question, so `GuestShell` now takes the same
optional `title` override `HostShell` got for the listing wizard. Verified
live: `/account/directions` now reads "Directions" while the sidebar still
highlights Upcoming Stays.

**Found by comparison, not by looking.** Only the negotiations one was visible
from opening pages. Diffing all 18 routes against the title map turned up the
other two, which looked perfectly fine on screen.

**Clean:** no horizontal overflow on any of the 18, no broken images, no
`NaN` / `undefined` / `[object Object]` / `Invalid Date`.

### Deployment race, twice now

Verifying a fix by fetching the bundle can catch an asset mid-swap. The first
time it produced a total outage (HTML pointing at a 404ing asset); this time a
bundle that served 200, contained the fix, and then 404d minutes later while
the browser tab held it cached — so the pages read as unfixed when they were
not. **Check the hash the page actually loaded against the hash the live HTML
references before concluding anything about a deploy.**

---

## Web — Public (20 / 20 reachable) — COMPLETE

Swept logged out, and checked by **HTTP status and robots directive**, not by
whether the page looked right. That distinction is the whole story of this
block.

| path | HTTP | robots | was |
|---|---|---|---|
| / | 200 | index, follow | ok |
| /explore | 200 | index, follow | ok |
| /search | 200 | index, follow | ok (no H1 — noted) |
| /getting-started | 200 | index, follow | ok |
| /about | 200 | index, follow | ok |
| /contact | 200 | index, follow | ok |
| /faq | 200 | index, follow | ok |
| /safety | 200 | index, follow | ok |
| /blog | 200 | index, follow | ok |
| /pre-booking | 200 | index, follow | ok |
| /become-a-host | 200 | index, follow | ok |
| /login /register | 200 | noindex, follow | ok |
| /forgot-password | 200 | noindex, nofollow | ok |
| **/terms-condition** | 200 | index, follow | **was 404 + noindex** |
| **/Privacy-Policy** | 200 | index, follow | **was 404 + noindex** |
| **/state-regulation** | 200 | index, follow | **was 404 + noindex** |
| **/help-center** | 200 | index, follow | **was 404 + noindex** |
| **/become-a-host/register** | 200 | noindex, follow | **was 404** |
| **/privacy-policy** | 301 → /Privacy-Policy | — | **was 404** |

### Five working pages were answering HTTP 404

`/terms-condition`, `/Privacy-Policy`, `/state-regulation`, `/help-center` and
`/become-a-host/register` all rendered perfectly and all returned **HTTP 404
with `noindex, follow`** and the title "Page not found | Aajoo".

They were never registered in `config/seoDefaults.js` `STATIC_PAGES`, so the
resolver classified them `unknown` and the edge turned that into a 404.

**The SPA draws these client-side whatever the status line says**, so to anyone
opening them they looked completely fine. Only checking the status code showed
it. Terms and Privacy matter beyond ranking: payment providers and app stores
verify those URLs, and a 404 fails that check. `/become-a-host/register` is the
host signup form, which `App.tsx` explicitly marks "must stay PUBLIC".

The site links both casings of the privacy page — the redesigned footer uses
`/Privacy-Policy`, the pre-redesign layout's footer uses the lowercase form —
so the lowercase path is now a 301 to the capitalised one rather than a second
copy competing for the same ranking.

### And the inverse: private areas were telling crawlers to index them

`index.html` declares `index, follow`, because it is the head every public page
starts from, and the edge serves that shell unmodified for signed-in paths. So
`/admin/*`, `/account/*`, `/host/*`, `/booking/*`, `/payment/*` and
`/checkout/*` all went out marked **indexable**.

The backend has always answered `noindex, nofollow` for exactly those prefixes
(`NOINDEX_PREFIXES`). It is never asked — not calling it is the entire point of
skipping — so that answer reached nobody. Two correct pieces of code with the
wrong directive on the wire between them. All five private prefixes now verify
as `noindex, nofollow`.

### Noted, not changed

- `/search` has no `<h1>`.
- `/auth` and `/user-dashboard` still 404 at the edge. `/auth` is an orphan
  parent route with no index child; `/user-dashboard` is renter-gated legacy.
  A 404 to a crawler is defensible for both.
- `/` resolves to `/explore` client-side. The served HTML canonicalises `/` to
  itself and the client then rewrites it to `/explore` — a mixed signal, but
  the routing is deliberate (IntentGate documents the history), so it is a
  product decision rather than a defect.

---

## App — started (guest 5 screens, host dashboard)

Emulator, fresh debug build of current `main` — the installed APK predated
today's app commits by three hours, so sweeping it would have tested old code.

| screen | result |
|---|---|
| launch | **FIXED — the app did not start at all** |
| guest Home (map + search) | ok; loads 100 homes near Mountain View |
| guest Dashboard | ok; Total Spent ₹26,760 matches the web's transactions |
| guest Bookings — Upcoming | ok, correctly empty |
| guest Bookings — Ongoing | ok; ₹6,720 matches host web exactly for B794077 |
| guest Profile | ok |
| host Dashboard | **FIXED — "Ongoing Stays 0" with a guest in residence** |

### The app would not start

`No Firebase App '[DEFAULT]' has been created` — a red error screen instead of
the app.

`main()` already wraps `Firebase.initializeApp()` in a timeout and a catch,
with a note explaining that it throws or hangs on handsets with old or absent
Play Services and the app must open anyway. It opened, and died one screen
later: `FirebaseMessaging.instance` throws when Firebase did not initialise,
and it sat in **field initializers** on `AuthController` and
`NotificationService`, so constructing either threw during build. Guarding the
start and not the consumers left the user exactly as stuck, slightly further
in.

Both are resolved on use now and return null when Firebase is absent; the call
sites already tolerated that. The listener setup in both notification services
is wrapped too.

Honest scope: the trigger was the emulator, where init timed out after 10s. On
a device with working Play Services none of this is reached. But the timeout
`main()` defends against is real, and this is what happened when it fired.

### A guest in the property counted as zero ongoing stays

`getOngoingBook` filtered `book_status IN (4, 5, 6)` and missed **8 = "Booking
Confirmed"** — what a booking becomes when a host approves it, and the most
common live state. Of every booking whose window contained today, the only live
one was status 8. Status 4 has never been used by a single booking.

`5` ("Booked") dropped deliberately: awaiting approval is not a guest in
residence — the same rule both badge paths already apply. Third place this
week that this definition was wrong.

**Found by cross-checking platforms**, not by reading one: the guest app showed
the stay under Ongoing with "Staying now", the web host dashboard agreed, and
only the app's host dashboard said zero. Verified on the device after deploy —
the tile now reads 1.

### Reconciles

"Collected from guests" ₹1,10,678 against the web's Total Earnings
₹1,04,814.16 — a ₹5,864 gap, which is the commission between gross collected
and the host's share. Different quantities, both correct. Total Bookings 30 and
Properties 29,237 match the web exactly.

### Noted

- The test guest account's avatar is a real photo of the repo owner, filename
  and all. Not the third-party PII of the CV incident, but it is visible to
  anyone testing.
- The login screen reads "Log in to continue to your stays" even with **Host**
  selected.
- The emulator's Settings app steals focus after every install; a reboot clears
  the stuck task, and force-stopping Settings in a loop during launch holds it
  off.

### Host portal on the app

| screen | result |
|---|---|
| host Dashboard | **FIXED** — Ongoing Stays 0 with a guest in residence; now 1 |
| host Bookings — Upcoming | ok; B104657 dates match the settlements data |
| host Bookings — Ongoing | ok; B794077 "Staying now" at ₹6,720 |
| host Profile | ok |
| host Menu | ok — 15 destinations, matching the web's host areas |
| host Settlements | ok; ₹0 payable, ₹10,465 due, same 7 rows as the web |

**₹6,720 now agrees on all three surfaces** — guest app, host app, host web.
Settlements agrees line for line with the web, including the 6 dues on
cancelled bookings that the backfill still has to clear.

**The host booking list printed raw dates.** One card read
"06-10-2026 → 7-10-2026" — the two halves of one range written differently,
because it interpolated the API strings and those are not consistently padded.
The guest list had a formatter privately all along; it now lives in
utils/stay_clock.dart and both portals call it. 105/105 app tests pass.

| host Calendar | ok; 1 Sep 2026 lands on Tuesday, legend and empty state correct |
| host Invoices | **FIXED** — amounts printed raw |
| host Performance | ok; every figure reconciles with the web |
| host Offers | ok; discount arithmetic verifies exactly |

**Performance reconciles with the web to the rupee**: Revenue ₹1,04,814 against
the web Earnings page's ₹1,04,814.16, Cancellations 18 against the bookings
tab's 18, and the booking-source total of 12 is the 30 bookings minus those 18.

**Offers**: ₹2,250 from ₹2,500 is 10%, ₹2,560 from ₹3,200 is 20% — all four
cards' arithmetic checks out, and admin-created offers are correctly marked
"Run by Aajoo on your listing".

### Host screens printed money raw where the guest side formats it

`pay_amount`, `property_price`, `security_deposit` and the rest arrive as
**strings** — "67200.00" — and nine sites interpolated them straight into a
label. The host saw "Amount: ₹67200.00" and "Price / night ₹3200.00" while
every other screen, and the guest side reading the very same field, shows
₹67,200.

The one that matters most is the **downloadable PDF invoice**, whose total read
"Total: ₹67200.00". That is the single artefact a host may forward to a guest
or hand to an accountant.

Found by scanning for raw interpolation across the app rather than screen by
screen, after the invoice list showed it. Most other hits were already fine.

| host Payouts | ok; ₹30,333 pending and ₹1,04,814 earned match the web |
| host Bank Account | **FIXED** — IFSC would not upper-case |
| host Notifications | ok; 68 unread, real booking events |
| host Support | ok — see the Gmail note below |
| host Add Property (wizard) | **FIXED** — took names the server refuses |
| guest Saved | ok, correct empty state |
| guest Search + results | ok; autocomplete, LUX toggle, category rail |
| guest Property detail | ok; **₹3,200/night, ₹3,360 total incl. taxes** — the money rule exactly |

### The listing wizard took names the server would refuse

**This is the original complaint, reproduced.** The field prints its rule
directly above itself — "Use 5-80 characters. Letters, numbers, spaces and only
& or -" — and accepted `Test@#Villa123-Pine\&Co` on the device, backslash
included. The host found out on submit that the sentence above the box had been
true all along.

Nothing bad was ever stored: `listingEngine.controller validatePropertyName()`
is the real gate. Fixed on **both platforms in the same pass**, held to exactly
the server's `/^[A-Za-z0-9 &-]+$/`. Deliberately ASCII, unlike the human-name
filter — filtering to something the server will REJECT would be worse than not
filtering, and both comments say to widen them together if that rule moves.

### The IFSC field would not look like an IFSC

It relied on `TextCapitalization.characters`, which only asks the keyboard to
show capitals and does not transform what arrives. A host typing their code
watched "hdfc0001234" appear in a field whose own hint reads "HDFC0001234".
Never a data fault — the value is upper-cased on submit — just a field that
refused to look like the thing it wanted. It also fixes the formatter ORDER:
the length limit ran before the character filter, so punctuation counted
against the eleven characters an IFSC is allowed.

The two fields either side of it were already correct: "Sumit123@#Malhotra"
became "SumitMalhotra" and the account number took digits only.

### Noted, not changed

- Host Support lists **aajoolive@gmail.com** as "Property management support".
  A Gmail address is a trust signal on a marketplace hosts entrust money to.
- The property-detail header collides with the status-bar clock when scrolled.
- The login screen reads "Log in to continue to your stays" with **Host**
  selected.
- The test guest avatar is a real photo of the repo owner.

### Still to sweep on the app

Host: boost, settings, refer. Guest: messages, negotiations, checkout,
reviews, blog, safety. Common: about, faq, refer, settings, terms, privacy,
update-profile.
