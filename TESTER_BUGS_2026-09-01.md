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
| **Not a defect — product decision** | 1 | #17 |
| **Could not reproduce** | 1 | #11 |
| **Previously resolved** (our earlier fixes, per the sheet's own comments) | 5 | #1, #4, #5, #6, #7 |
| **Needs a visual pass** | 4 | #3, #10, #13, #14 |

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
