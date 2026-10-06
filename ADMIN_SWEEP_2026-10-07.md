# Admin dashboard sweep — 2026-10-07 (live production, Super Admin)

Baseline from the live DB: 7 users (4 host / 3 renter flags, 7 user_isVerified,
KYC: 4 verified · 2 pending · 1 unverified) · 2 properties (both active+verified)
· 3 bookings (B871634 status1 paid ₹3.15 · B923140 status2 unpaid ₹210 ·
B935518 status1 unpaid ₹210) · 3 payments ₹223 · 15 categories · 7 blogs ·
0 reviews · 0 support tickets · 2 negotiation offers · 2 coupons.

## Screen 1 — Dashboard  (8 API calls, all 200)

Correct: Total Users 7, Total Hosts 4, Total Properties 2, Total Bookings 3,
Active/Verified properties 2/2, Active hosts 4, Pending Approvals 0.

### A1. "Verified Users 7 — KYC complete" counts the wrong column   [DEFECT]
`verifiedUserCount` = COUNT(user_isVerified=1) = 7, which is the ACCOUNT/OTP
flag. The tile labels it "KYC complete". Real KYC (`verification_status`):
4 verified, 2 pending, 1 unverified. The dashboard tells an admin everyone has
passed KYC when 3 of 7 have not — and KYC gates payouts and booking.
  web Dashboard.tsx:278 · backend admin.controller.js ~911

### A2. "Avg booking value ₹1" divides money received by ALL bookings [DEFECT]
`avgBooking = fin.totalRevenue / d.BookingCount` = 3.15 / 3 = ₹1. The numerator
counts only paid bookings, the denominator counts every booking. Both live
bookings are ₹210. Either divide by the bookings that produced the revenue, or
use total booking value.
  web Dashboard.tsx:206-207

### A3. "Cancellation rate 100.0% — 1 of 1 this year" reads as catastrophe [COPY]
Formula is cancelled / (successful + cancelled) — resolved bookings only, which
is a defensible definition. The caption is not: "1 of 1 this year" implies one
booking exists this year, when three do. Say "of 1 resolved".
  web Dashboard.tsx:215

### A4. B871634 still Confirmed + paid, refund NULL            [DATA, known]
The gateway refund from 2026-10-05 was never replayed, so the booking still
reads paid ₹3.15 with book_refund_amount NULL. The webhook handler fix is live;
the three Razorpay dashboard actions are still outstanding with the client.

## Screens 2–5 — Analytics · Booking Analytics · Property Analytics · Financial Overview
All API calls 200. Analytics counts all match the DB (7/4/2/3, paid 1 unpaid 2).
Property Analytics correct (2 properties with bookings, 3 bookings, 1 Luxe).
Booking Analytics "By status" is correct and honestly labelled (Payment
Pending 2, Cancelled 1).

### B1. A PAID booking reports ₹0 revenue — and two screens disagree  [DEFECT]
Same booking, same day, two answers:
  Financial Overview   Total Revenue  ₹3.15   (sums the LEDGER — real money)
  Booking Analytics    Revenue/180d   ₹0      (sums book_total_amt WHERE
                                               book_status IN REVENUE_STATUSES)
  Property performance both properties ₹0
B871634 is `book_status = 1` with `book_is_paid = 1, book_amount_paid = 3.15`.

utils/bookingStatus.js excludes status 1 with the reason:
    //   1  Payment Pending — an abandoned checkout is not income
That rationale is wrong for this platform. With `pbr_booking_type = approval`,
a guest who HAS PAID sits at status 1 until the host confirms — the same pair
(`book_status = 1 AND book_is_paid = 1`) that availabilityRules.js was taught
to hold nights for earlier this week. So every paid-awaiting-approval booking
is ₹0 on the analytics screens while Finance counts the money.

Status 1 is "not income" only when `book_is_paid = 0`. The fix belongs in the
one shared list, which is exactly where the file says such a rule should live.

### B2. Platform Commission ₹0 on a ₹3.15 booking            [DATA, known]
Ledger for B871634: guest payment ₹3.15 · commission ₹0 · host earning ₹3 ·
tax ₹0.15. Written before the round2() fix; the historical row stands.
Open decision with the user: correct it or leave it.

### B3. A payout of ₹3 is still pending on a REFUNDED booking   [RISK]
Finance shows Pending Payouts ₹3 for B871634 — the booking whose money was
returned to the guest at the gateway on 05 Oct. Until the refund webhook is
replayed, the platform is queued to pay a host for a stay it refunded.
Depends on the three Razorpay dashboard actions, still outstanding.

### B4. Reconciliation reads 0% matched / 0 / 0 / 0            [CHECK]
With one real payment, "Share of records matched 0%" may be honest (nothing
imported to match against) or an empty screen. Verified on its own screen below.

## Screens 6–9 — Users · Hosts · Properties · Bookings · Payments

Users 3 + Hosts 4 = 7 ✓. Their KYC counts (2 + 2 = 4) match the DB and so
CONTRADICT the dashboard's "7 — KYC complete" (see A1).
Properties "All properties" tab correct (2 total, 2 active, both listed) — the
default tab is "Pending review", which is legitimately empty.
Bookings list: 3 total, 1 Unpaid, 1 Cancelled — all correct.

### C1. Every ADMIN screen calls lifecycleLabel() without the paid flag [DEFECT]
`lifecycleLabel(raw, opts)` in redesign/lib/bookingStatus.ts gets this right:

    if (opts.paid !== undefined && !isPaid && !isCod && s.includes("payment pending"))
        return "Payment pending";
    if (isPaid && s.includes("payment pending")) return "Awaiting approval";
    if (!s || PAYMENT_TITLES.includes(s)) return "Confirmed";   // the fold

Both guards need `opts`. The admin callers pass NONE, so `opts.paid` is
undefined, both guards are skipped, and every status-1 booking falls through to
the PAYMENT_TITLES fold and prints **"Confirmed"**. Live, right now:

    B935518  status 1, book_is_paid 0  -> "Confirmed"   should be "Payment pending"
    B871634  status 1, book_is_paid 1  -> "Confirmed"   should be "Awaiting approval"

So an admin sees an abandoned, unpaid checkout as a confirmed booking, and
cannot see that a PAID guest is stuck waiting on a host. The "Confirmed (page)"
counter is `rows.length - cancelled`, so it inherits the error (reads 2).

The row already carries what the function needs: `book_is_paid` / `book_is_cod`
are used by paymentBadge() on the very next column (Bookings.tsx:214).

The host side was fixed on 2026-10-06; these callers were missed:
    admin/Bookings.tsx:130      the list column
    admin/Bookings.tsx:550      the detail drawer
    admin/Dashboard.tsx:316     Recent Bookings
    admin/PropertyAnalytics.tsx:147
    guest/BookingConfirmed.tsx:127
    PropertyDetail.tsx:444
(Bookings.tsx:71 is the filter-group builder and has no booking row — correct
as-is.)

This is the trap of a guard that exists but never RUNS: the function is right,
the callers starve it. Exactly the "three surfaces, three answers" the file's
own comment set out to end.

### C2. Payments & Payouts — ₹3 QUEUED to the host of the refunded booking
Total GMV ₹3.15 · Platform Revenue ₹0 · Host Payouts ₹0 · Pending ₹3, one row:
B871634 -> H.Ashish Kumar ₹3 QUEUED. Same exposure as B3.

## Screens 10–15 — Negotiations · Reviews · Disputes · Ledgers · Payouts · Reconciliation

Negotiations 2 offers ✓, Reviews 0 ✓, Payout Queue 1 row ✓.
Reconciliation's 0% is an HONEST empty state ("Nothing has been compared yet —
press Run reconciliation"). B4 withdrawn, not a defect.

### D1. Four open compliance holds on a user that no longer exists  [DEFECT/DATA]
tbl_admin_flags holds af_id 1–4, ALL `af_user_id = 8`, all KYC_IN_REVIEW/HOST,
all `af_resolved = 0`. Existing users are 11–17 — **user 8 was removed in the
test-data purge and its flags were left behind.**

Consequences: the compliance queue reads "4 Total · 4 Open" and renders the
party as "#8" (the no-name fallback), and no admin can ever meaningfully
resolve a hold on an account that is gone. It also inflates `complianceOpen`.

Two things to fix: purge the orphans, and note that FOUR identical flags exist
for one user — the verification flow appears to write a fresh hold per attempt
with no dedupe. (Same family as the purge rule already recorded: delete
children first; tbl_admin_flags was missed.)

### D2. Ledger CREDITS/NET double-count the same money          [DEFECT]
Ledgers shows: CREDITS ₹6.30 · DEBITS ₹0 · NET ₹6.30, over 4 entries —
  guest payment ₹3.15 · platform commission ₹0 · host earning ₹3 · tax ₹0.15
But commission + host earning + tax = ₹3.15 = the guest payment. They are the
SPLIT of that one payment, not four separate credits. Totalling all four
reports ₹6.30 when ₹3.15 is all the money that ever moved — exactly double.
An admin reading NET ₹6.30 sees twice the revenue that exists.
("Balance after" was checked and is fine — it is a per-party running balance.)

### D3. Payout Queue row has an empty period ("— → —")          [MINOR]
B871634 / H.Ashish Kumar / ₹3 QUEUED shows no payout period.

### D4. Negotiations summary omits "Countered"                   [MINOR]
Header reads 2 Total · 1 Pending · 0 Accepted · 0 Declined, but the second
offer's status is "Countered" — a state the summary has no tile for, so
1 + 0 + 0 never reconciles with the 2 total.

## Screens 16–18 — Invoices · Settlements · Finance Reports
Invoices correct (AAJOO-INV-202610-0005, ₹3 + ₹0.15 GST = ₹3.15).
Settlements correct and honestly empty (no pay-at-property bookings exist).

### E1. Revenue Report contradicts itself on one screen          [DEFECT]
Same screen, same period (verified in a screenshot, not just text):
    header cards   Total revenue ₹3.15 · Bookings 1 · Average booking value ₹3.15
    table row      2026-10 · Revenue ₹0 · Bookings 1 · Average value ₹3.15
Revenue ₹0 over 1 booking cannot give an average of ₹3.15. The per-period row
is reading a different (empty) field from the one the header and the average
use. The chart draws flat at zero for the same reason.

Worth noting the contrast: THIS screen computes the average correctly
(revenue ÷ the bookings that produced it = ₹3.15), which is exactly what the
Dashboard's "Avg booking value ₹1" gets wrong in A2.

### E2. The report's default period ends YESTERDAY               [MINOR]
Default range is 12/31/2025 → 10/06/2026; today is 2026-10-07. A report opened
with the default silently excludes anything booked today.

## Screens 19–24 — Categories · Amenities · Help Center · Offers · Coupons · Blog
Categories 15/15 active ✓ · Amenities 39 (37 active, 2 hidden) ✓ · Help Center
35 published ✓ · Offers 0 ✓ · Blog 7 (6 live, 1 draft) ✓.

### F1. "Active" coupons are expired AND fully used              [DEFECT]
The screen reads "2 Total · 2 Active (page)", both shown Active — including
DEAL220C8 at **80% off**. In the data both are dead twice over:
    cpn_valid_to   2026-09-29 13:00   (expired 8 days ago)
    cpn_usage_limit 1 / cpn_used_count 1   (exhausted)
    cpn_property_id 1 and 2, cpn_user_id 2 — property and user all purged
The status column renders `cpn_status = 1` alone and ignores validity dates and
usage, so an admin is told two discounts are live, one of them 80%.
Checked before reporting: they are NOT redeemable, so this is a reporting
defect, not a money leak. "Active" should mean enabled AND in-date AND not
exhausted, or the column should say "Enabled".

Also orphans from the purge, same family as D1: both coupons point at a
property id and a user id that no longer exist.

## Screens 25–33 — Support · Safety · Contact · SEO · Settings · Roles · Logs
Support / Safety / Contact Messages correctly empty with honest empty states.
SEO Health: 26 pages, 23 findings, ALL copy quality (6 long titles, 1 very
short, 12 descriptions out of range, 2 duplicate titles, 2 duplicate
descriptions) and ZERO structural errors — work for the SEO team, not defects.
Redirects: 0 rules, honest empty state.

### G1. The "what's broken" screen is itself broken — twice     [DEFECT, worst]
Settings lists three capabilities as "Not configured on this server". Two of
the three are FALSE ALARMS, and I only caught it by reading the Render env.

**media (Photo uploads)** — adminCapabilities.controller.js:41
    const cloudinary = safely(() => require("../utils/cloudinary").isConfigured);
but utils/cloudinary ends with `module.exports = { CloudinaryManager };` and
`isConfigured` is an INSTANCE property set in the constructor. So the
expression is `undefined` -> false **on every deployment, whatever is set**.
Proven locally:
    module exports: CloudinaryManager
    mod.isConfigured = undefined  -> Boolean: false
Every other caller does it correctly: `const { CloudinaryManager } = require(...)`.
Render HAS all three: CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY,
CLOUDINARY_API_SECRET. Photo uploads are fine; the screen says they are not.

**maps** — the probe reads `GOOGLE_MAPS_API_KEY`, a name that appears NOWHERE
else in the codebase. The real key is `GOOGLE_PLACES_KEY` (utils/googlePlaces.js,
nearbySuggest.controller.js, its own test) and it IS set on Render.

**sms** is the only honest one (deliberate, pending a provider).

Why this is the worst finding: the screen exists to tell an operator what is
silently broken, and it cries wolf on 2 of 3. Its message — "listing photos
vanish on the next deploy" — is alarming, specific and wrong, and it had me
chasing an infrastructure blocker that does not exist. Once a monitor is known
to lie, a real failure will be ignored.

Good news from the same check: **FIELD_ENCRYPTION_KEY and
RAZORPAY_WEBHOOK_SECRET are both present on Render** — two long-standing open
items, now closed.

### G2. "Last Login: Never" for the admin who is signed in       [DEFECT]
Roles & Permissions lists 4 team members, ALL with Last Login "Never" —
including the account driving this session. Activity Logs on the next screen
shows "Ashish Rahi · Signed in · 34 min ago", so sign-ins ARE recorded; the
Roles screen reads a field nothing writes. An admin cannot use it to spot a
dormant or compromised account, which is the only reason the column exists.

### G3. Failed sign-ins render as "Admin #null"                  [MINOR]
Activity Logs shows repeated `Admin #null · Failed sign-in` with an IP. A
failed login for an unknown address has no admin id, so the id is printed raw.
Say "Unknown account" and keep the IP. (Same family: the SEO change log prints
"admin 0" for a null actor.)

### G4. My own test writes are in the client's SEO change log    [MY MESS]
SEO change log carries rows I created last night while verifying the save fix:
    blog:999999, blog:999998  (actor "probe (super_admin)")
    blog:999996 x2, blog:999995  (actor "admin 0")
The page_seo rows were deleted; these audit rows are append-only and remain,
visible to the SEO team. Ask before purging — it is an audit table.

## Screens 34–40 — Global SEO · Image SEO · Bulk Import · Homepage · Terms · Boost · Refer · Title templates · Bulk metadata
All render correctly with real data and honest empty states. Image SEO reports
0 of 20 images missing a description. Homepage CMS correctly notes that only
active, verified listings can be featured and the server enforces it.

---

# Summary

40 admin screens driven live as Super Admin. **Every API call returned 200 —
there is not a single 4xx or 5xx anywhere in the console**, and the core counts
(users, hosts, properties, bookings, payments, categories, blogs, coupons) all
reconcile against the production database.

What is wrong is not plumbing. It is **numbers and labels that disagree with
each other and with the data**, which on a money platform is worse than an
error page: nothing looks broken.

## Fix first
| # | Screen | What it says | What is true |
|---|---|---|---|
| G1 | Settings | "Photo uploads not configured — photos vanish on next deploy"; "Maps not configured" | Both FALSE. The probe reads `.isConfigured` off a module that exports a class (always undefined), and checks `GOOGLE_MAPS_API_KEY`, which does not exist — the real `GOOGLE_PLACES_KEY` and all 3 Cloudinary vars ARE set |
| C1 | Bookings, Dashboard, Property Analytics (+2 guest) | Unpaid and awaiting-approval bookings both read "Confirmed" | 6 call sites pass no `paid` flag, so both guards in lifecycleLabel() are skipped. The data is already on the row |
| E1 | Revenue Report | Revenue ₹0 and ₹3.15 on the same screen, average ₹3.15 over ₹0 | The per-period row reads a different, empty field |
| B1 | Booking Analytics vs Finance | ₹0 revenue vs ₹3.15 for the same booking | REVENUE_STATUSES excludes status 1 as "abandoned checkout", but a PAID booking legitimately sits there awaiting host approval |
| A1 | Dashboard | "7 Verified Users — KYC complete" | 4 verified, 2 pending, 1 unverified. Counts `user_isVerified` (OTP), labels it KYC. The Users and Hosts screens get it right, so the console contradicts itself |
| D2 | Ledgers | CREDITS ₹6.30 · NET ₹6.30 | ₹3.15 is all the money there is; the other three rows are its split, counted again |
| A2 | Dashboard | "Avg booking value ₹1" | Paid-only revenue ÷ all bookings. Live bookings are ₹210 each |
| G2 | Roles | "Last Login: Never" for all 4, incl. the signed-in admin | Sign-ins are recorded — Activity Logs shows them. The column reads a field nothing writes |
| D1 | Disputes | 4 open compliance holds on "#8" | User 8 was purged; its flags were not. Unresolvable by design |
| F1 | Coupons | 2 Active, one at 80% | Both expired 8 days ago AND usage-exhausted. Not redeemable — a reporting defect, not a leak |

## Smaller
A3 cancellation-rate caption ("1 of 1 this year" when 3 bookings exist) ·
D3 blank payout period · D4 Negotiations summary has no tile for "Countered" ·
E2 revenue report defaults to a range ending yesterday · G3 "Admin #null" /
"admin 0" for a null actor.

## Not defects (checked, then cleared)
Reconciliation 0% — honest empty state. Properties "0 Active" — the default tab
is Pending review; All properties is correct. Monthly bookings showing 1 of 3 —
the backend deliberately counts resolved bookings and says so. SEO Health's 23
findings — all copy quality, zero structural errors.

## Live data, needs the client
B871634 (₹3.15, refunded at the gateway on 05 Oct) still reads Paid/Confirmed
with `book_refund_amount` NULL, and **₹3 is QUEUED to pay its host**. The
webhook handler is live; the three Razorpay dashboard actions are not done.
Its ledger also carries the historical ₹0 commission row.

## Good news
`FIELD_ENCRYPTION_KEY` and `RAZORPAY_WEBHOOK_SECRET` are both present on the
live service — two long-standing open items, now closed.

---

# Fixes — all shipped 2026-10-07

backend `c6ef130` + `3d7cdf3` · web `132530f`

| # | Fix | Where |
|---|---|---|
| G1 | Capability probe constructs CloudinaryManager instead of reading `.isConfigured` off the module (always undefined), and reads `GOOGLE_PLACES_KEY` instead of a name nothing sets | adminCapabilities.controller.js |
| C1 | `paid`/`cod` passed at all six lifecycleLabel call sites — the row already carried them | 6 web files |
| B1 | `countsAsRevenue()` + `REVENUE_SQL`: status 1 earns when paid. Applied to the monthly chart (grouped by `book_is_paid`), both analytics sums, and property analytics — where paid-pending also leaves "pending" so it is not counted twice | bookingStatus.js + 2 controllers |
| E1 | `revenue` alias added to the per-period items, as the totals already had | adminFinance.controller.js |
| A1 | `kycVerifiedUserCount` (verification_status) added and used by the tile; the account flag stays, renamed "Account verified" | admin.controller.js + Dashboard.tsx |
| D2 | Ledger panel reads MONEY IN / MONEY OUT / NET with ALLOCATED separate; backend classifies by transaction type | adminFinance.controller.js + Ledgers.tsx |
| A2 | `revenueBookings` added; the average divides money by the bookings that produced it | adminFinance.controller.js + Dashboard.tsx |
| G2 | `admin_last_login` is now WRITTEN at sign-in (two readers, no writer) | admin.controller.js |
| D1 | Holds on deleted users dropped from the queue and counted separately — dropped, not deleted, because a regulatory record should not be erased to fix a display | admin.controller.js |
| F1 | "Redeemable" counts enabled AND in-date AND not exhausted; a switched-on coupon nobody can use says why | Coupons.tsx |
| A3 | Cancellation caption says "of N resolved this year" | Dashboard.tsx |
| D3 | A payout with no period reads "Per booking" | Payouts.tsx |
| D4 | Negotiations gained a "Countered" tile, so the tiles reconcile | Negotiations.tsx |
| E2 | Report default range built from LOCAL date parts — `toISOString()` is UTC, so at 00:45 IST it opened on 31/12/2025 → 06/10/2026 | reportConfig.ts |
| G3 | A null actor reads "Unknown account" / "system", not "Admin #null" / "admin 0" | 2 controllers |

## One flaw caught in my own fix
D1 originally filtered on `nameById[id]` — `user_fullName` is NULLABLE, so a
real account with a blank name would have had its compliance holds silently
dropped. Re-keyed on a Set of ids the users query returned, and demonstrated:
with users 9 (no name) and 11 and flags on 8, 9, 11, the name-keyed filter
drops 8 AND 9; the existence-keyed one drops only 8. Shipped as `3d7cdf3`.

## Verification
- 12 assertions across `bookingStatus.test.js` and the new
  `theCapabilityProbeTellsTheTruth.test.js`; every guard removed in turn fails
  the suite, and reverting the capability fix fails two.
- `tsc -b` caught six type errors on the first build (missing
  `kycVerifiedUserCount`, `book_is_cod`, `book_is_paid` on three payload types,
  and one now-unused variable) — all fixed before shipping.
- Against production data: Booking Analytics revenue **₹0 → ₹3.15**, matching
  Financial Overview; KYC count **7 → 4**, matching the Users and Hosts
  screens; report default range **31/12/2025 → 06/10/2026** becomes
  **01/01/2026 → 07/10/2026**.

---

# Verified on screen, live, 2026-10-07

Driven as Super Admin after the deploy. Every row below was read off the
production screen, not inferred from the code.

| # | Was | Now |
|---|---|---|
| G1 | "Photo uploads not configured — photos vanish on next deploy" + "Maps not configured" | only **SMS** listed |
| C1 | B935518 "Confirmed", B871634 "Confirmed" | **"Payment pending"** · **"Awaiting approval" / Paid** |
| B1 | Booking Analytics revenue ₹0, Green Hills ₹0 | **₹3.15**, Green Hills **₹3.15** |
| D2 | CREDITS ₹6.30 / NET ₹6.30 | MONEY IN ₹3.15 · OUT ₹0 · **NET ₹3.15** · ALLOCATED ₹3.15 |
| E1 | row "Revenue ₹0" beside header ₹3.15 | row **₹3.15 \| 1 \| ₹3.15** |
| E2 | 31/12/2025 → 06/10/2026 | **01/01/2026 → 07/10/2026** |
| A1 | "7 Verified Users — KYC complete" | **4 KYC verified** · Account verified 7, kept separate |
| A2 | Avg booking value ₹1 | **₹3** ("Revenue ÷ bookings paid") |
| A3 | 100.0% "1 of 1 this year" | **50.0% "1 of 2 resolved this year"** |
| D1 | 4 Open holds on purged user #8 | **0 — "No compliance holds recorded"** |
| F1 | "2 Active", one at 80% | **0 Redeemable** · 2 × "expired — no guest can redeem it" |
| D4 | 2 total vs 1 + 0 + 0 | **1 Pending · 1 Countered · 0 · 0** |
| G2 | "Never" for the signed-in admin | **07 Oct 2026** |
| D3 | "— → —" | **"Per booking"** |
| G3 | "Admin #null" × 8 | **0** · "Unknown account" × 8 |

## Three defects the on-screen pass found in my OWN fixes

Shipping is not verifying. Driving the screens caught three things that the
tests, the type-checker and the deploy all passed:

1. **The KYC tile still read 7 of 7.** adminDashboard destructures a
   Promise.all POSITIONALLY. The new name went in after `userCount` while the
   new query went in after the `user_isVerified` count, so the two were
   swapped and the tile reported the account flag again — the exact figure the
   change existed to correct. (`0eff099`)
2. **The coupon guard could not run.** `couponListing` selected seven columns
   and none of the four the redeemability check reads, so it saw `undefined`
   for every input and passed both coupons. The screen still said
   "2 Redeemable". (`0eff099`)
3. **A tile no row supported.** With the rows finally reading "Payment
   pending" and "Awaiting approval", the counter above still said
   "Confirmed 2" — it was `rows − cancelled`. Now it counts the label it
   names, with an "Awaiting approval" tile beside it. (`2c40c47`)

Plus one labelling wrinkle: the tile called two switched-on coupons "Inactive"
while their toggles read "Active". Renamed "Not redeemable". (`22de132`)

**Final commits:** backend `c6ef130` → `3d7cdf3` → `0eff099` → `40d535f` ·
web `132530f` → `2c40c47` → `22de132`
