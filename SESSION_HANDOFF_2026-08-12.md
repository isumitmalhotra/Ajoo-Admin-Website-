# Session handoff — 2026-08-12

Supersedes `SESSION_HANDOFF_2026-08-11.md` for what changed; that document is
still the reference for the CSV import, the finance backfill, the auth fix and
the search fix, none of which are revisited here.

This session ran the five checks §10 of that handoff asked for, and did the
four things they turned up.

---

## 0. Live state

| | |
|---|---|
| Web bundle at handoff | pushed `6865c64`, verify with the curl below |
| Backend | `054917e` on Render, `/health` 200 |
| Properties (host 100) | 29,230 not deleted · 29,227 active · 3 inactive · 8 deleted |
| Payable payout queue | **₹1,555** (was ₹79,312) |
| Distinct state labels | **37**, all correctly spelled (was 41 with 9 variants) |

```
curl -s https://www.aajoohomes.com/ | grep -oE 'assets/index-[A-Za-z0-9_-]+\.js'
curl -s https://aajaodev.onrender.com/health/env
```

**The two checks from the last handoff both passed before any work started.**
The bundle was `index-vBwe-f9w.js` as recorded, and searching Kharar returns
Kharar listings — §5 of that document is closed.

---

## 1. The host portal at 29,230 listings — it was broken, and measurably

`/host/property-search` had no limit. Measured against the live database:

| | Before | After |
|---|---|---|
| Response | **38.1 MB** | 0.03 MB |
| Time | **18.7 s** | ~1.2 s |
| Rows | 29,230 | 20 |

That is from a local machine on a good connection; Render's CPU is slower and
it has to serialise the whole thing. **Five host screens called it on mount** —
My Properties, Dashboard, Calendar, Boost, Performance — and My Properties then
rendered all 29,230 rows into the DOM with no virtualisation.

The endpoint now takes `page`, `limit` (default 20, hard cap 100), `minimal`
for pickers, `q` for name search and `status` for the tabs, and returns
account-wide `counts` alongside the page.

`/host/properties/policy-pending` was the same shape — 29,228 rows, 2.47 MB, on
**every host page load**, feeding a banner that renders a dropdown and a button
per row. Capped at 20 with the true total; confirming a batch pulls the next.

Other things that only showed up at this size:

- **"Active Listings" counted deleted listings.** 29,238 against 29,227 truly
  active. Same fault as the admin tiles fixed last session.
- **"Under Review" could never appear.** `statusOf` read `property_status`,
  `status` and `pending_verification`; the column is `property_kyc_status`.
- **Stock photography, again.** My Properties gave every photo-less listing one
  of six stock images by row index — 29,230 photographs of somewhere else,
  shown to the person who owns the places. The dashboard's Top Performing list
  did the same with a stock cottage. Both show "no photo uploaded" now.
- **My Properties swallowed its errors** into an empty catch and fell through
  to "No properties yet" — a timeout told a host with 29,230 listings they
  owned nothing.
- The dashboard pulled all 29,230 listings to find **thumbnails for three
  rows**. That fetch is gone.
- A dropdown cannot hold 29,230 options, so `PropertyPicker` searches
  server-side once the account doesn't fit one page.

**Mobile landed in the same pass** (parity rule): `getHostProperties(page:,
limit:, q:)`, `loadMoreHostProperties()`, `hostPropertyCount` reading
`totalCount` — the home stat tile would otherwise have read 20 — and a "Load
more" on the host profile list. Both `HostController` classes were updated;
they share a name and `Get.find` keys on it.

### Left open

- **Occupancy on the host dashboard reads 0%** and is arithmetically correct:
  booked nights ÷ (days × 29,227 listings) rounds to zero. Not a defect, but it
  will be reported as one.
- Mobile was **not swept** for the stock-photo pattern or for list errors
  rendering as empty states. Web-only so far.

---

## 2. Payouts: ₹77,757 cleared, and the bug that made one of them

`tbl_payouts` held 8 QUEUED rows, ₹79,312. Seven were not money anyone is owed
and are now FAILED with the reason recorded (the enum has no "cancelled";
every payable total filters on QUEUED/PROCESSING, so this removes them
everywhere while keeping the row). `scripts/clearTestPayouts.js`, user approved
with the numbers in front of them.

**Only ₹1,555 remains queued** — po_id 6, host 133 "Ashish Rahi", the one host
who is not the test account. Deliberately left.

Two of those rows were worse than test data:

- **po_id 3, ₹19,752, against booking B182882 — which is cancelled.** Nothing
  in the cancellation path touched `tbl_payouts`. The guest was refunded in
  full and the host stayed queued to be paid: the money was lost twice.
  Cancellation now withdraws the payout on a full refund and **freezes** it on
  a partial one, because re-splitting a partly-refunded booking is a pricing
  decision, not a bugfix.
- **po_id 4, ₹4,000, to host id 12 — a user that does not exist.** Raised by an
  admin with the note "testing purpose".

**`po_on_hold` was write-only.** The admin hold endpoint set it, and the
finance dashboard's pending total, the host's own "pending payout" and the
per-host admin summary all filtered on `po_status` alone and counted held money
as payable regardless. Holding a payout changed one number on one screen. All
three honour it now, and the admin's "pending" and "on hold" figures stopped
double-counting the same money.

Also fixed in passing: **guest cancellation was writing outside its own
transaction** — `{ transaction }` passed as a third argument to `update()`,
which Sequelize silently drops. The identical fault was already fixed in
`hostCancelBooking`; this was the other half.

### Left open

Refunds on cancelled-but-paid bookings (BPTEST04, ₹9,440) — still a decision
nobody has made, unchanged from the last handoff.

---

## 3. The "5,123 wrong cities" was two different problems

The last handoff recorded "~5,123 properties have wrong city/state text, needs
reverse-geocoding, and nobody has decided whether the label or the coordinate
is authoritative." Measured, that splits cleanly.

**The state column was not geographically wrong.** 28,272 of 29,230 carried a
state both valid and consistent with their coordinates. What it carried was
nine **spelling** variants across 5,736 rows — and the coordinates confirm the
labels were right and merely misspelled: the "Uttrakhand" rows are Tehri
Garhwal and Haridwar at ~30.3N 78.0E, which is Uttarakhand; "Andaman and
Nicobar" is Port Blair at 11.67N 92.74E.

| Was | Now | Rows |
|---|---|---|
| Tamilnadu | Tamil Nadu | 1,871 |
| Orissa | Odisha | 1,486 |
| Chattisgarh | Chhattisgarh | 851 |
| Uttrakhand | Uttarakhand | 648 |
| Jammu & Kashmir | Jammu and Kashmir | 560 |
| Daman & Diu | Daman and Diu | 171 |
| Andaman and Nicobar | Andaman and Nicobar Islands | 50 |
| Dadar & Nagar Havali | Dadra and Nagar Haveli | 50 |
| Pondicherry | Puducherry | 49 |

Plus **12 rows whose state was a digit or NULL** — and those turned out to be
the *old seed* properties (ids 7–32), not CSV imports at all. Nine had usable
coordinates and were reverse-geocoded one request per second, which is ordinary
use rather than the bulk geocoding Nominatim's policy forbids: Mohali→Punjab,
Gurugram→Haryana, Noida→Uttar Pradesh, New Delhi→Delhi, Faridabad→Haryana. The
remaining 3 have null or (0,0) coordinates and were left alone.

`scripts/normaliseStateLabels.js`, dry-run by default. 37 distinct state values
now, all spelled correctly.

**Daman & Diu and Dadra & Nagar Haveli merged into one union territory in 2020.**
They are kept as the two district names people actually search for; the official
"Dadra and Nagar Haveli and Daman and Diu" is correct and unusable in a UI.
Change it if the client disagrees.

### The city labels are the real problem, and are NOT fixed

"Karol Bagh" is stamped on **4,512 listings spanning 1,568 km across six
states**; only the 252 in Delhi are actually Karol Bagh. But their *states and
coordinates are correct* — Bihar rows average 25.59N 85.78E, Assam rows 26.37N
92.33E. It is purely the city text.

**Deriving cities from the coordinates using this dataset as its own reference
was tried and makes it worse.** A nearest-neighbour relabel renames "Kharar" to
"Shivalik City" (a locality 100 m away), "Mohali" to "Chaper chiri", and "New
Delhi" to "MEERUT". Replacing a correct, searchable city name with a hamlet is
a regression, so nothing was written.

The same self-referential method also got the 12 broken states wrong — it
proposed Gurugram→Delhi and Noida→Haryana, where real geocoding said Haryana
and Uttar Pradesh. Worth remembering: **this dataset cannot be used as its own
ground truth.**

Fixing ~4,260 city labels needs a licensed geocoder. Nominatim's public
instance forbids bulk geocoding, and our own live search proxy depends on that
same service — hammering it risks an IP ban that would break search. **The user
chose to defer the spend decision.** Coordinates already drive search, so the
damage is display-only.

---

## 4. Render environment — still the blocker, still needs you

`GET /health/env` on production, measured this session:

```
"ready": false,
"missingRequired": ["JWT_SECRET","CLOUDINARY_CLOUD_NAME","CLOUDINARY_API_KEY","CLOUDINARY_API_SECRET"],
"dbCutoverSafe": false,
"dbChecks": {"DB_USER":"DIFFERS","DB_PASSWORD":"DIFFERS","DB_NAME":"DIFFERS","DB_HOST":"DIFFERS","DB_PORT":"DIFFERS"}
```

Unchanged since 2026-08-03. All five `DB_*` are wrong, four required vars are
missing, and `OTP_DEV_BYPASS` is still set to `true`. Production only survives
because `db.config.js` ignores the environment entirely.

**This is the one task that cannot be done from here** — it needs the Render
dashboard. Step-by-step instructions, including which file holds each correct
value and the trap of the non-standard DB port, are in
[`RENDER_ENV_CHECKLIST.md`](RENDER_ENV_CHECKLIST.md). When `/health/env` reads
`ready: true` **and** `dbCutoverSafe: true`, the code cutover is small.

---

## 5. Working practices — unchanged and re-confirmed

- **Measure against the live database, not the source.** Every number in this
  document came from a query. The 38 MB, the 29,230, the nine spellings and the
  cancelled-booking payout were all invisible in the code.
- **Do not let a dataset validate itself.** Section 3 is the cautionary tale.
- **Web ⇄ mobile parity in the same pass**, recorded in `WEB_MOBILE_PARITY.md`.
- Confirm before production writes, with the numbers. Both writes this session
  (₹77,757 of payouts, 5,745 state labels) were put to the user first as dry
  runs.
- Never type passwords. The auth fix from the last session is **still**
  unverified by hand for that reason, and still worth one manual check.

---

## 6. First five minutes of the next session

1. Confirm the deploys landed — bundle hash, and `/health` 200.
2. Sign in as host 100 and open **My Properties**. It should page 20 at a time
   over 29,230 with working tabs and search. Nothing about it has been seen in
   a browser; every measurement here is server-side.
3. Same for the host **Calendar** and **Boost** pickers, which now search.
4. `RENDER_ENV_CHECKLIST.md` — the env is still wrong and still armed.
5. Decide the city-label question (§3) and the BPTEST04 refund (§2).
