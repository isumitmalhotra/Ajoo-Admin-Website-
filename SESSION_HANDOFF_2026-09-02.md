# Session handoff — 2026-09-02

Tester bug sheet closed out, then the search and maps work that came out of it.
**Everything below is live on production and was verified there**, not in a
local build.

Companion: `TESTER_BUGS_2026-09-01.md` (per-bug detail) and
`Aajoo - Tester Bug Sheet - fixes and verification (v2).xlsx` (21 rows, the
client-facing version).

---

## 1. The tester sheet — all 18 items closed

Sixteen were already fixed and verified in the previous session. This session
closed the last two and found three more defects while doing it.

| # | What it was | State |
|---|---|---|
| 1, 4, 5, 6, 7 | Nav hover, partial place names, guest counts, Uttarakhand, dates carrying | verified in real Chrome |
| 2 | Zoom re-ran the search | **re-fixed — the first fix was wrong, see §2** |
| 3 | Overlapping price markers | clustered; pills also had zero width, fixed |
| 8, 9, 13, 14, 18 | Share/Save, guest validation, admin contrast, offer dates, Show on map | verified |
| 11, 15, 16, 17 | Add-property 404, KYC return, Pool House, LUX exclusivity | verified at the API |
| 12 | Admin redirect | verified via the role claim; final click-through needs a human |
| **10** | **Incorrect India map** | **fixed — moved to Google Maps, see §4** |

---

## 2. Two of the previous session's fixes did not work

Worth reading before trusting a "fixed" line anywhere.

**#2 — zoom still re-ran the search, and panning had stopped searching.**
The guard compared the map centre against `lastCenter`, but only updated that
reference when a search actually fired. The programmatic `FitBounds` on load
returned early without updating it, so the reference went stale at the mount
position; the next real gesture — a zoom, which moves the centre 0 m — was
measured against a point hundreds of km away and sailed through. Measured on
production: idle 0 requests, one zoom-in = one `POST /properties/search`; a real
drag moved the centre 5,497 m and fired **nothing**.

Now listens for `dragend`, which Leaflet and Google both raise **only** for a
real drag — never for a zoom, never for a programmatic move. The `programmatic`
ref is gone with the guesswork.

**#18 — "Show on map" scrolled but the tab strip did not follow.** The first fix
relied on `scrollIntoView({behavior:"smooth"})` and an IntersectionObserver,
both of which are inert in some environments. It now falls back to an instant
jump if the page has not moved, and sets the tab explicitly.

---

## 3. Search defects found during verification

**Picking any destination from the dropdown returned no stays.** The list emits
a full label ("West Delhi, Delhi, India") and the results page geocoded that
string back, but the place index only ever scored `place.name` and only in the
direction name-startsWith-needle. Every composite label scored null, so the main
search path dead-ended on "No stays at this location yet" while the same area
browsed on the map showed 100 stays — with 824 listings in the Delhi box.
Exact-label matches now rank best, a comma-bearing query retries on its leading
segment, and the coordinates the suggestion already holds travel with the search
instead of being re-derived. "Nearby" was also passing lat/lng that nothing
read; that works now too.

**Every area reported "100 properties found".** The API returned only its capped
page and no count at all, so the page counted what it received. It now returns a
real `total` counted over the same conditions: West Delhi 1,473 / Kullu 1,025 /
Almora 297. Cross-checked against a direct database count (1,524 within 100 km —
exact) and confirmed independent of page size.

**Property type filtered the fetched page, not the search.** Asking for Villas
near Delhi searched only inside the nearest 100 stays *of any type*. Now filtered
in SQL, and the rail is multi-select so the API takes a list: Villas 87 + Resort
1 = 88, + Apartments 85 = 173.

> Trap: request validation runs with `stripUnknown: true`. A new field is dropped
> silently unless it is whitelisted in `schema/properties.schema.js`. This is also
> why `limit` is currently ignored — every search returns 100 rows whatever is
> asked for. Left alone deliberately; changing it would shrink what other
> surfaces fetch.

---

## 4. Maps and place search moved to Google

Client decision, for India-correct boundaries and better Indian place accuracy.

**Boundaries — the point of #10.** Verified on production: the solid
international boundary encloses **both Jammu & Kashmir and Ladakh** as Indian
territory, with the Line of Control only a faint internal dotted line. Arunachal
Pradesh shows as an Indian state. The OpenStreetMap tiles drew the LoC and Aksai
Chin *as* the international border and labelled Gilgit-Baltistan under Pakistani
administration — confirmed by pulling the raw tiles.

**Three live surfaces migrated.** Search results (clustered pills, drag-to-search),
the property location panel (privacy circle before booking, exact pin after), and
the host location picker. Three other Leaflet components — `ListingMap`,
`MapandFilter`, `PropDetailMap` — are **dead code**, unrouted, and were left alone.

**Every surface keeps Leaflet as an automatic fallback.** Not hedging: a maps
failure on the search page is a blank half-screen on the busiest surface we have,
and the failure modes are ordinary — key missing in an environment, billing
lapsed, allowance spent, a new domain outside the referrer list, an outage.

**Place search is three tiers:** our own inventory → Google Places → OpenStreetMap.
Google is the middle tier, not a replacement for the first, because a suggestion
we hold no stays for is the same dead end as §3. **The mobile app calls the same
`/public/geocode/search` endpoint, so it got all of this with no new build.**

**Host address lookup fixed on the way.** Reverse geocoding was the one lookup
still on Nominatim, which refuses datacenter IPs — so it failed every time and
the picker said "address lookup unavailable" under every pin, leaving hosts to
type addresses by hand. Now on Google: a dropped pin returns
"465, Sector 127, Shivalik City, Kharar, Sahibzada Ajit Singh Nagar, Punjab
140301, India".

### Google Cloud setup, as it stands

- Project `aajoo-bdb20`, billing account **now active** (was the blocker for a day)
- **Browser key** — Maps JavaScript API only, restricted to `aajoohomes.com`,
  `www.aajoohomes.com`, `*.vercel.app`. In Vercel as `VITE_GOOGLE_MAPS_KEY`,
  type **Config**, not Secret — a `VITE_` value is inlined into the bundle and
  is public by design; the referrer restriction is what protects it.
- **Server key** — Places + Geocoding. In Render as `GOOGLE_PLACES_KEY`.
- Budget alert: **set one if not already done.** Maps JS bills per map load and
  the search page loads a map on every visit, so this is the one ongoing cost
  that scales with traffic.
- Still open, unrelated: `API key 4` in that project is **unrestricted** and its
  usage should be checked before it is restricted or deleted. The app's Android
  Maps key is also hardcoded in `AndroidManifest.xml` and in git history — it
  belongs on the rotation list.

---

## 5. The lesson that cost the most time

**Both browsers this session can drive keep their tab hidden**, and a hidden tab
freezes `requestAnimationFrame` — measured at **zero callbacks per second**.
Google Maps builds itself inside rAF, so in an automated tab the map constructs,
holds its centre and zoom, renders only Google's static preview image, and never
initialises. No console error, no events, no projection, and the bootstrap script
returns a clean 200.

That is indistinguishable from a billing failure from the outside, and it sent a
long chase after a correctly-configured key. **Check `document.hidden` and rAF
before diagnosing anything visual.** A screenshot forces the tab visible, which
is the workaround for verifying map rendering at all.

Three more bugs of mine were only findable by looking at the rendered page:

- a `//` comment moved into JSX children by a later edit, **rendered as visible
  text to hosts** in the location picker
- the Google map drawing perfectly with **no pins at all**, because a `useMemo`
  depended on the `useReducer` dispatcher (stable) instead of its counter
- the picker asserting "address lookup unavailable" when **no lookup had been
  attempted**

---

## 6. Open items

1. **29,232 listings still have no photograph.** Unchanged, and still the largest
   launch risk. A content decision, not an engineering one.
2. **Credential rotation** — deferred by instruction until testing completes.
   Everything in `config/db.config.js` is in git history.
3. **#12 admin redirect** — the chain is verified (token carries `super_admin`,
   the frontend accepts it) but the final click-through needs a person to type
   the password.
4. **Seed data spells Uttarakhand as "Uttrakhand"** on its listings. Search works
   regardless; it just reads wrong to guests.
5. **Budget alert on Google Cloud**, per §4.

---

*Prepared 2026-09-02. All three repos clean and pushed at time of writing.*
