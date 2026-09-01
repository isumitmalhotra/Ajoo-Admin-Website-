# Tester bug sheet — verification pass
**Source:** `Aajoo Homes (1).xlsx` · verified 2026-09-01 against production and the code.

> **The "Bugs App" sheet is empty** — a template with row numbers and two rows of
> severity metadata, but no titles, descriptions or steps. No app bugs have been
> filed. Everything below is from **Bugs Web**: 18 items.

## Summary

| Verdict | Count | Items |
|---|---|---|
| **Confirmed — reproduced, root cause found** | 6 | #2, #8, #9, #15, #16, #18 |
| **Already fixed** (by us, after the sheet was written) | 1 | #12 |
| **Product decision — client ruled LUX must be exclusive** | 1 | #17 |
| **Could not reproduce** | 1 | #11 |
| **Previously resolved** (our earlier fixes, per the sheet's own comments) | 5 | #1, #4, #5, #6, #7 |
| **Needs a visual pass** | 4 | #3, #10, #13, #14 |

---

## Shipped and verified live — 2026-09-01

All seven confirmed items are fixed, deployed and **checked against production**,
not just against the code.

| # | Fix | How it was verified live |
|---|---|---|
| **#16** | Step 1 validates against the same merged catalogue `/listing/schema` serves | `POST /listing/step1` `pool_house` → **200**; a bogus `space_station` → **400**, so the door did not open |
| **#15** | `/verify/complete` registered (noindex); KYC `returnUrl` falls back to the live site, not `localhost:5173` | `GET /verify/complete` → **200** (was 404) |
| **#17** | Three-state `isLuxury` on `/properties/search` *and* `/properties/list` (the latter used truthiness, so `0` was ignored); web + app send `0` | `isLuxury=1` → **7 stays, all luxury**; `isLuxury=0` → **23, none luxury**; 7+23 = the full 30 — mutually exclusive and exhaustive |
| **#9** | Guest name/phone/email validated before Proceed to Pay | Empty name → *"Enter the name this stay is for."*; 1-char → *"Enter the full name."*; `12345` → *"Enter a valid 10-digit mobile number."*; `not-an-email` → *"Enter a valid email address."*; all four stayed on `/booking/review`. Valid details still reach `/booking/payment` — no booking created, no money moved |
| **#8** | Share and Save wired (they had no `onClick` at all) | Save while logged out → *"Log in to save this stay"*; Share produces feedback and copies the canonical slug URL |
| **#18** | "Show on map" scrolls **and** sets the tab | Fresh load: About / scrollY 0 → click → **scrollY 2535**, section pinned at 132px under the sticky header, tab highlighted |
| **#2** | Zoom no longer re-searches (~200 m centre-movement guard) | Guard confirmed in the shipped bundle. See the caveat below |

### Two things this browser could not show me

Worth knowing, because both looked at first like fresh bugs and neither was:

1. **`scrollIntoView({behavior:"smooth"})` is a silent no-op** in the test
   browser — proven against an isolated scroll container with no app code in it.
   The #18 handler fired correctly and the page still did not move. Rather than
   leave it environment-dependent, `scrollToSection()` now asks for smooth and
   falls back to an instant jump if the page has not moved 250 ms later. This
   also covers the seven jump-nav tabs and the House Rules link.
2. **IntersectionObserver never fires** there either — not even a plain
   observer's guaranteed first callback. That is what drives the jump-nav
   highlight, so the tab strip looked broken and is not. The section links now
   set the tab explicitly rather than depending on that observer alone.

**#2's request-level check is the one thing not directly observed:** the test
browser records no XHR/fetch to the API at all, so "zero searches fired" could
not be distinguished from "the instrument is blind". The guard is confirmed
present in the deployed bundle and the logic is exact — a zoom leaves the centre
unchanged, so the distance test short-circuits; a real pan moves far more than
200 m and still searches.

**#11** is with the client to re-check; it is most likely the same root cause as #16.

---

## Confirmed, with root cause

### #16 · Blocker · "Pool House" category rejected
`/listing/schema` serves **12** categories including `pool_house`, but `step1`
validates against the static `CATEGORY_VALUES`, which has **11**. Proven:

```
POST /listing/step1  category=homestay   → 200  {"propertyId":29272}
POST /listing/step1  category=pool_house → 400  "Invalid property category"
```

`listingEngine.controller.js` folds admin-maintained categories over the code
constants on purpose — its own comment says *"adding Pool House in the panel
produced a filter nobody could list a property under"*. The wizard was fixed to
offer them; **the validator was not**.
**Fix:** validate against the same merged catalogue the schema serves.

### #15 · Page Not Found after submitting ID verification
`/verify/complete` — the DIDIT return URL — answers **HTTP 404, "Page not
found"**. It was never registered in `STATIC_PAGES`, exactly like the five
public pages fixed earlier today. A host finishing verification is redirected
straight into a 404.
**Fix:** register `/verify/complete` (noindex — it is a callback landing, not an
indexable page). *Also check `APP_VERIFY_RETURN_URL` is set on Render; it falls
back to `http://localhost:5173/verify/complete`.*
I swept all 114 declared routes: only `/auth`, `/user-dashboard` and
`/verify/complete` 404, and only this one is a real user destination.

### #8 · Share and Save buttons do nothing
`PropertyDetail.tsx` lines 918–919. Both buttons have **no `onClick` at all** —
they are decoration:
```tsx
<button className="btn btn-outline-gray btn-sm"><Icon name="share-2" /> Share</button>
<button className="btn btn-outline-gray btn-sm"><Icon name="heart" /> Save</button>
```

### #9 · Can reach payment with no guest details
`BookingReview.tsx` line 348 — the only guard is `disabled={verifyingDates}`.
Nothing validates name, phone or email before `proceed()` navigates to payment.

### #18 · "Show on map" does not scroll
`PropertyDetail.tsx` line 952 — `onClick={() => setTab("location")}` and nothing
else. The tab changes; the page never scrolls to the map.

### #2 · Map zoom triggers a new search
`ResultsMap.tsx` line 101 — `map.on("moveend", handler)`. Leaflet fires
`moveend` on **zoom** as well as pan, so every zoom re-searches (380 ms debounce,
and the `programmatic` guard does not apply to a user zoom).
Note: "search as you move the map" is a deliberate pattern; what makes this a bug
is that it overrides the location the guest typed.

---

## Already fixed

### #12 · Blocker · Admin portal does not redirect after login
**Fixed earlier today**, before this sheet was reviewed. Two causes: `submittedHere`
was declared and read but never assigned, so every login took the "prove your role"
branch — which accepted `admin`/`finance`/`support` and **not `super_admin`**, the
role the backend actually issues. Verified on production: login now lands on
`/admin/dashboard` and the header reads "Super Admin".

---

## Not a defect

### #17 · Luxe properties shown when Luxe mode is off
Reproducible — a plain search returns 30 stays, 7 flagged `is_luxury`. But this is
the **designed** behaviour: `customerApi.searchProperties` documents
`isLuxury: 1 = only listings the host marked as luxury`, and `PreBooking.tsx:52`
sends `undefined` when LUX is off. There is no "exclude luxury" mode.
**Needs a product call:** should normal browsing hide LUXE stays, or is LUXE a
curated *view* of the same catalogue?

---

## Could not reproduce

### #11 · Blocker · "404 Bad Request" on Add Property step 1
`POST /listing/step1` returns **200** with a valid payload. The only failure I can
produce on that endpoint is **#16's 400 "Invalid property category"**.
Likely the same event reported twice — the tester's wording ("404 Bad Request")
mixes two status codes. **Please confirm which category was selected**; if it was
Pool House, #11 closes with #16.

---

## Needs a visual pass

| # | Item | Note |
|---|---|---|
| 3 | Map price markers overlap | Needs clustering/collision handling; confirm at the reported zoom |
| 10 | Incorrect India map outline | Almost certainly the **tile provider's** boundary rendering, not our code. If so the fix is a provider/tile choice, and it matters — an incorrect India boundary is a legal and credibility issue |
| 13 | Admin login unreadable text | Confirm which element; the login page was otherwise reworked today |
| 14 | Send Offer date/offer UI misaligned | Reproduce on the guest offer sheet |

---

## Housekeeping

Verifying #16 created a **draft** listing, property **29272** ("QA Verify Homestay",
host 100), via `POST /listing/step1`. It is a step-1 draft, unpublished and
invisible to guests. Delete it when convenient.
