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

## Web — Admin (9 / 56)

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
| 10 | /admin/property-analytics | ? | ? | **RE-TEST NEEDED** - read as blank, but the whole site was down at that moment (see below) |

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
