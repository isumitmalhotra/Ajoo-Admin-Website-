# Proactive findings — 2026-09-05

A sweep of all three repos for the **classes** of defect that produced this week's
tester bugs, run before anyone reports the next instance. Each class below has
already bitten at least once; the counts are what is still exposed.

Ordered by how likely the next tester report is to come from it.

| # | Class | Exposed | Effort | Priority |
|---|---|---|---|---|
| 1 | Silent-empty catches (app) | ~~26 sites~~ **0 silent** — all 27 log; empty-vs-broken pattern shipped on notifications, 3 screens to follow | 1 day | **DONE 2026-09-05** (follow-up: 3 screens) |
| 2 | `.nullable()` numerics with no empty-string transform | ~~34 fields~~ **0** — 38 sites on `nullableNumber()`, guard test fails the build if the shape returns | 3 h | **DONE 2026-09-05** |
| 3 | `.catch(() => {})` (web) | 18 sites | 3 h | P2 |
| 4 | Hardcoded status allowlists that define "money" | 2 arrays | 1 h review | P2 |
| 5 | Admin form validates fields the user did not touch | 1 form | 2 h | P2 |

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

**Fix (as applied).** `nullableNumber()` now lives in `schema/yupHelpers.js` — hoist it
to `schema/_helpers.js` and apply it to every form-bound field above. Keep the
refusal tests: the transform accepts *absence*, never bad input.

## 3. `.catch(() => {})` — web

**What it is.** Same failure as class 1, on the website. A swallowed 401 on the
reviews call is how "this property has no reviews" hid for months.

**Where.** 18 sites. `PropertyDetail.tsx` alone has 4; `NotificationBell.tsx` 2;
`auth.ts` 2; one each in `Settlements`, `Offers` (host and admin), `ListProperty`,
`PolicyConfirmBanner`, `googleAuth.ts`, `customerApi.ts`.

**Fix.** Replace with `.catch((e) => console.warn("<what failed>", e))` at minimum.
Where the screen has an empty state, add a distinct error state.

## 4. Hardcoded status allowlists that define "money" — backend

**What it is.** `admin.controller.js` carries two arrays that decide which booking
statuses count as revenue:

- `SUCCESS_STATUSES = [3, 5, 6, 7, 8, 9, 10, 13]`
- `REVENUE_STATUSES = [3, 5, 6, 7, 8, 9, 10]`

They differ by status 13. Two definitions of "a booking that counts" is the
**two-ledgers** problem already recorded in memory — host money figures that
disagree across screens. A status added to `tbl_book_statuses` reaches neither
unless someone remembers both.

**Fix.** One exported definition in `utils/bookingStatus.js`, with a comment on
why 13 is in one and not the other (or make them agree). One hour to review,
and it prevents a class of "the dashboard and the ledger show different totals".

## 5. Admin form validates fields the user did not touch

**What it is.** The admin **Edit property** form refuses to save with *"Enter a
valid 10-digit mobile number"* when the **already-stored** contact number fails
the rule (`1425369807`, `5869471230` — ten digits, but Indian mobiles start 6–9).
Two of today's four listing renames were blocked by it. Any edit to those listings
is blocked until someone changes a phone number they were not editing.

**Fix.** Validate a field only when it changed from its loaded value (`dirty`), or
on the server accept an unchanged value as-is. Separately, a one-off report of
listings whose stored contact fails the rule (host-entered junk) is worth having.

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
