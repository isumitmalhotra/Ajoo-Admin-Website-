# Proactive findings — 2026-09-05

A sweep of all three repos for the **classes** of defect that produced this week's
tester bugs, run before anyone reports the next instance. Each class below has
already bitten at least once; the counts are what is still exposed.

Ordered by how likely the next tester report is to come from it.

| # | Class | Exposed | Effort | Priority |
|---|---|---|---|---|
| 1 | Silent-empty catches (app) | ~~26 sites~~ **0 silent** — all 27 log; empty-vs-broken pattern on notifications, guest negotiations and host properties (guest bookings already had its own) | 1 day | **DONE 2026-09-05** (follow-up done, build 16) |
| 2 | `.nullable()` numerics with no empty-string transform | ~~34 fields~~ **0** — 38 sites on `nullableNumber()`, guard test fails the build if the shape returns | 3 h | **DONE 2026-09-05** |
| 3 | `.catch(() => {})` (web) | ~~18 sites~~ **37 found, 0 left** — every site names what failed; Book Now, the notification bell and both offer pickers got a real error state; ESLint refuses the shape | 3 h | **DONE 2026-09-05** |
| 4 | Hardcoded status allowlists that define "money" | ~~2 arrays~~ (3, counting the complement) **1** — `utils/bookingStatus.js`; guard test fails the build on a private list | 1 h review | **DONE 2026-09-05** |
| 5 | Admin form validates fields the user did not touch | ~~1 form~~ **0** — only changed fields are validated and sent; both blocked renames went through | 2 h | **DONE 2026-09-05** |

---

## 1. Silent-empty catches — app services

**What it is.** A service method catches every error and returns an empty list,
`null`, `false` or `0` with no log. The screen then renders its empty state — which
looks identical to "you have nothing here". This is exactly how APP #19 hid: the
host notifications screen showed a blank list, and nothing anywhere recorded why.

**Where.** 26 sites in `aajoo_app_2026/lib/service/`. Worst offenders:
`host_service.dart` (5), `booking_service.dart` (4), `growth_service.dart` (4),
`deals_service.dart` (3).

**Status 2026-09-05.** Done for logging on all 27 sites (`utils/service_log.dart`); the empty-vs-broken pattern (`ServiceErrors` + `LoadFailed`) is live on host notifications. **Follow-up:** apply the same key/clear + `LoadFailed` to guest bookings, guest negotiations and host properties — each is a controller-backed list, ~30 min apiece.

**Fix.** Do not change the return type. Log the error and expose a `lastError`
(or return a small `Result`) so the screen can show "Couldn't load — tap to retry"
instead of an empty state. Start with the four screens where "empty" is a
plausible real answer: notifications, bookings, deals, host properties.

**Rule going forward.** An empty result is a finding, not a pass. A `catch` that
returns empty must at minimum log.

## 2. `.nullable()` numeric fields with no empty-string transform — backend

**What it is.** `yup.number().nullable()` accepts `null` but not `""`. An empty
form input sends `""`, yup casts it to `NaN`, and the type error fires. This is the
defect that made **Page SEO unsaveable for its whole life** (found 2026-09-04).

**Where.** 34 fields across `schema/*.js`. The ones bound to real admin forms are
the risk; ids and filters from JSON never arrive as `""`:

- `adminProperties.schema.js` — `noOfBeds`, `noOfGuests`, `weeklyMiniPrice`,
  `weeklyMaxPrice`, `monthlySecurity` (the admin **Edit property** form)
- `adminSeo.schema.js` — `sitemap_default_priority`, `analytics_enabled`,
  `robots_sitemap_enabled`, `sitemap_include_images`
- `adminBooking.schema.js` — `guests`, `beds`
- `adminFinance.schema.js` — `amount`, `minPayoutAmount`
- `adminCoupons.schema.js` — `cpn_dsctn_type`
- `properties.schema.js` — `no_of_beds`
- `hostV2.schema.js` — `year`, `month`

**Status 2026-09-05.** Done. `nullableNumber()` lives in `schema/yupHelpers.js`; 38 sites converted, zero remain, and `tests/nullableNumberSweep.test.js` re-scans every schema on each run.

**Fix (as applied).** `nullableNumber()` is the bare primitive — the transform only —
so every site keeps its own `.integer()/.positive()/.min()/.typeError()` chain and
wrong input is still refused. The transform accepts *absence*, never bad input.

## 3. `.catch(() => {})` — web

**What it is.** Same failure as class 1, on the website. A swallowed 401 on the
reviews call is how "this property has no reviews" hid for months.

**Where.** 18 sites. `PropertyDetail.tsx` alone has 4; `NotificationBell.tsx` 2;
`auth.ts` 2; one each in `Settlements`, `Offers` (host and admin), `ListProperty`,
`PolicyConfirmBanner`, `googleAuth.ts`, `customerApi.ts`.

**Status 2026-09-05.** Done — and the count above was wrong. The 18 were the
sites with a literal `{}`; the ESLint rule added at the end of the pass found
**19 more** written as `.catch(() => { /* what the screen does instead */ })`,
which a grep for the literal could not see. All 37 (plus the `try { } catch {
/* stay hidden */ }` beside one of them) log a labelled `console.warn`. Four had
a visible dead end behind the silence and now have an error state:

- The **notification bell** showed *"No notifications yet"* after a failed
  request — the web twin of APP #19. It now says it couldn't load, with a retry.
- **Book Now** on the listing page said *"Just checking these dates are still
  free — one moment"* forever when the availability call failed. It now says the
  check failed and asks for a reload.
- The **host and admin offer pickers** rendered an empty dropdown after a failed
  listings fetch / search, which read as "you have no listings". They now say the
  request failed.

`eslint.config.js` carries a `no-restricted-syntax` rule that refuses
`.catch(() => {})` outright (verified to fire on a probe file).

**Fix (as applied).** `.catch((e) => console.warn("<what failed>", e))` at
minimum; where the screen had an empty state, a distinct error state.

## 4. Hardcoded status allowlists that define "money" — backend

**What it is.** `admin.controller.js` carries two arrays that decide which booking
statuses count as revenue:

- `SUCCESS_STATUSES = [3, 5, 6, 7, 8, 9, 10, 13]`
- `REVENUE_STATUSES = [3, 5, 6, 7, 8, 9, 10]`

They differ by status 13. Two definitions of "a booking that counts" is the
**two-ledgers** problem already recorded in memory — host money figures that
disagree across screens. A status added to `tbl_book_statuses` reaches neither
unless someone remembers both.

**Status 2026-09-05.** Done. `utils/bookingStatus.js` exports the one list
(`REVENUE_STATUSES` = 3, 5, 6, 7, 8, 9, 10, 13), `isRevenueStatus()` (fails
closed on NaN/null/junk) and the pending/cancelled ids. `admin.controller.js`
(monthly chart + booking analytics) and `adminPropAnalytics.controller.js`
(per-property revenue + chart) all import it; the latter had a **third**
definition written as its complement, which silently counted statuses 4 and 12
as income.

**Decision on 13.** "Successful" is a completed, paid-out stay and counts as
revenue — it was the one id the two lists disagreed on. No real booking sits at
13 today (or at 4 / 12), so no live figure moved; the change settles what
happens when one does. `tests/bookingStatus.test.js` scans controllers,
services and utils and fails on any `*_STATUSES =` or literal ids inside
`book_status IN (...)`.

## 5. Admin form validates fields the user did not touch

**What it is.** The admin **Edit property** form refuses to save with *"Enter a
valid 10-digit mobile number"* when the **already-stored** contact number fails
the rule (`1425369807`, `5869471230` — ten digits, but Indian mobiles start 6–9).
Two of today's four listing renames were blocked by it. Any edit to those listings
is blocked until someone changes a phone number they were not editing.

**Status 2026-09-05.** Done. `PropertyForm.tsx` keeps the loaded draft and
validates `propContact` / `propEmail` only when they differ from it; unchanged
values are left out of the payload, so the server never re-validates them.
Listings 29277 and 29279 — the two renames this had blocked — were renamed
straight after. The one-off report of stored contacts that fail the rule is
still worth running before hosts are asked to edit those listings.

**Fix (as applied).** Validate a field only when it changed from its loaded
value; omit unchanged fields from the update.

---

## Checked and clean

- **Wizard key mismatches (app → server).** The `id_document` / `ownership_document`
  class that caused APP #18 and the admin "Ownership document missing" error. A
  scripted diff of every key the app sends in steps 1–5 against every `b.<key>`
  the server reads found **no remaining mismatch**.
- **`req.user` reads under admin auth.** The class that left `psb_reviewed_by`
  null on every approval ever made. One remaining hit (`deleteProperty`) was a
  function-name collision with a host-only controller — the admin route binds its
  own. Clean.

## Not verifiable from here (needs a host/guest session)

- APP #19 merged feed and the guest-count round trip both deploy cleanly and are
  covered by tests, but exercising them end-to-end needs a signed-in host and
  guest respectively. Please have the tester confirm on build 14 and the live
  site.
