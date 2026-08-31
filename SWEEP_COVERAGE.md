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

## Web — Admin (0 / 56)

| # | Route | API | VIS | Notes |
|---|---|---|---|---|

---

## Findings

_Recorded as they are found, with the fix and the platforms it landed on._
