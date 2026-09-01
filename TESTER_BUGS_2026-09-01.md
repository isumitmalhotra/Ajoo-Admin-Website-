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
| **Fixed in the visual pass** | 3 | #3, #13, #14 |
| **Needs a provider decision (not a code fix)** | 1 | #10 |

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

## The visual pass — #3, #13, #14 fixed and verified; #10 is a decision

### #3 · Map price markers overlap — FIXED
Every point drew its own chip with no collision handling, so a dense area became
a wall of unreadable pills. Pins are now grouped in projected pixel space at the
current zoom; a group draws one "N stays" bubble and clicking it zooms to its
bounds. Chips are also centred on their coordinate — with a 0x0 icon and a 0,0
anchor they hung off to the bottom-right of the point they marked.

Verified live by driving the map through four zoom levels:

| Zoom | Markers | What is drawn |
|---|---|---|
| 9 | 3 | "50 stays", "49 stays", one price |
| 12 | 4 | "49", "38", "12 stays", one price |
| 15 | 18 | mostly "5 stays" |
| 18 | **100** | every stay showing its own price |

Nothing overlaps at any level, and all 100 results resolve individually at
street zoom.

**Follow-up — the pins themselves were rendering wrong, and had been all
along.** A `divIcon` with `iconSize [0,0]` gets an inline `width:0` on its
wrapper, and a `display:block` child of a zero-width parent resolves to zero
width too. Every marker's inner div measured **offsetWidth 0** on production, so
the pill's background and border collapsed to nothing and the label painted
straight onto the map beside it. The price chips had this too; clustering only
made it obvious, because a dark teal fill showed "5" in a blob with the word
"stays" hanging off it.

`width:max-content` sizes each pill to its own text and ignores the wrapper.
Verified live at the zoom from the report: pills measure 60–71px wide by 28px
tall, sized to their text, and **every label is contained inside its own pill**
(`anyZeroWidth: false`, `allContained: true` across every marker at z12, z15 and
the default view).

> Measuring this needs care: when the Browser pane is hidden the whole Leaflet
> container reports 0x0 and *every* marker measures zero regardless. Check
> `.leaflet-container` has a non-zero rect before trusting any marker geometry. The counts are real clustering, not coincidence: the corpus holds
**29,232 listings across 28,657 distinct coordinates**, at most 4 on any single
point — so a group of 50 is genuinely 50 separate places too close to draw apart
at that zoom.

### #13 · Admin login unreadable text — FIXED
`index.css` carries a bare element rule, `h1..h5 { color: var(--dark) }`. A
direct rule beats an inherited one, so **"Admin Console" rendered near-black on
the navy panel that sets `color:#fff` — about 1.03:1**, which is what the tester
read as unreadable. That panel's headings now inherit its colour.

Separately, "Admin Login" painted a **solid** colour through
`background-clip:text` with a transparent text-fill. Clipping a solid colour
cannot look different from simply setting it, but it can fail — and the failure
mode is an invisible heading. Property Verification had the same transparent
fill with no fallback colour; it has one now.

Verified live: both headings measure **15.11:1**, comfortably past WCAG AAA, and
the text-fill is a real colour rather than transparent.

> Worth knowing: that global heading rule means **any** heading placed on a dark
> background anywhere in the app will render dark-on-dark unless it opts out.

### #14 · Send Offer date UI misaligned — FIXED
The calendar is 560px wide and its two month grids have a 250px floor each —
528px that cannot shrink — inside a modal whose content box is
**480 − 2×26 = 428px**. It spilled out of the modal.

Added an opt-in `fitParent` for callers that render the calendar in normal flow
inside a narrow container, and let the month row wrap rather than overflow.
Absolutely-positioned popovers keep the old behaviour deliberately: their
containing block is the field they hang off, and 100% of that is far too narrow.

Verified live in the modal: calendar **413px inside the 480px modal**, 26px and
41px clear of the edges, no sideways scroll, and the second month now sits
*below* the first instead of outside the box. The admin Bookings calendar got
the same treatment — its card is 720px so it does not overflow today, but it is
`width:100%` and would on a narrower screen.

### #10 · Incorrect India map — NOT a code fix
Confirmed by pulling the raw tiles and looking at them, rather than inferring:
at **z7 around Ladakh** (`tile.openstreetmap.org/7/91/51.png`) the standard OSM
raster style draws dashed Line-of-Control and Aksai Chin lines, and labels
Gilgit-Baltistan under Pakistani administration. That is painted into the
imagery — no CSS or code change can alter it.

The fix is a different tile provider, and every India-compliant option needs an
account, so it is a decision rather than something to pick unilaterally:

| Option | Boundaries | Cost | Notes |
|---|---|---|---|
| **Mappls / MapmyIndia** | Compliant by law | Free tier | Indian provider; the natural fit for an India-only product |
| **Mapbox** (`worldview=IN`) | Compliant | Paid above free tier | `mapbox-gl` + `react-map-gl` are **already in package.json**, unused |
| **Google Maps** (`region=IN`) | Compliant | Needs billing | `@react-google-maps/api` is **already installed**, unused |

The tile URL had been copy-pasted into **six** components. All six now read one
definition in `src/redesign/lib/basemap.ts`, so the switch is a one-line change
plus a key once the provider is chosen.

---

## Housekeeping

Verifying #16 created a **draft** listing, property **29272** ("QA Verify Homestay",
host 100), via `POST /listing/step1`. It is a step-1 draft, unpublished and
invisible to guests. Delete it when convenient.
