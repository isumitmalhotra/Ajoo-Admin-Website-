# Session handoff — 2026-08-11

Read this first. It is written for a fresh session with no memory of the work.
It supersedes `SESSION_HANDOFF_2026-08-10.md`, which is still worth skimming for
the pre-existing context (§0 deploy paths, §7 working practices, §8 accounts).

---

## 0. The three repos and how they deploy

| Repo | Path | Deploys to | Push with |
|---|---|---|---|
| Web frontend | `D:/Projects/aajao-frontend-vercel` | Vercel → `www.aajoohomes.com` | branch is `redesign/aajoo-2026`, so `git push origin HEAD:main` |
| Backend | `D:/Projects/aajaoBackend-render` | Render → `aajaodev.onrender.com` | `git push origin main` |
| Monorepo (mobile lives here) | `D:/Projects/ajoo admin website` | not deployed | `git push origin main` |

**Build rule, unchanged and still true:** run `npm run build`, never a bare
`npx tsc --noEmit -p tsconfig.json`. The bare tsconfig does not resolve project
references. `npx tsc -b` is fine.

**Verify deploys by artefact, not by hope.** Vercel: fetch the page, grep the
bundle name, then grep the bundle itself for a string only your change
introduces. Render: call the endpoint and check the behaviour changed. Both
took 2–5 minutes this session.

```
curl -s https://www.aajoohomes.com/ | grep -oE 'assets/index-[A-Za-z0-9_-]+\.js'
```

**Live state at handoff**

| | |
|---|---|
| Web bundle | `assets/index-vBwe-f9w.js` |
| Backend | HTTP 200 on `/health` |
| Properties | **29,232** (29,228 public) |
| …owned by test host 100 | **29,230** |
| Users | 10 · Bookings 21 |
| Ledger revenue (COMPLETED) | ₹1,02,180.02 |
| Payouts QUEUED | ₹79,312.00 |

---

## 1. The big thing that happened: 28,918 properties went live

Imported from the user's `Properties Data - Data.csv` (29,232 rows) under **test
host 100 "Aajoo Test Host"**, published immediately at the user's explicit
instruction. Script: `scripts/importPropertiesCsv.js` in the backend repo.
Idempotent on host + name + coordinates, so re-running is safe.

```
node scripts/importPropertiesCsv.js --file "<csv>"                    # dry run
node scripts/importPropertiesCsv.js --file "<csv>" --apply --live     # write
```

### 1a. THE CSV'S LATITUDE AND LONGITUDE ARE SWAPPED

Read as labelled, **0 of 29,232 rows** fall inside India. Read crosswise,
**29,222** do. The column headed `property_longitude` holds the latitude. The
importer reads them crosswise. **Anything else loaded from this file or its
siblings must do the same** or every listing lands in the wrong country.

### 1b. Known-bad data that is now in production

- **City/state text labels are wrong for ~5,123 rows.** 22 of 513 city labels
  span >50 km internally. "Bilaspur / Himachal Pradesh" spans **6,501 km**.
  "Karol Bagh" — a Delhi neighbourhood, 4,512 rows — is labelled Assam,
  Chattisgarh and Bihar. 49 rows labelled Pondicherry carry Chennai's
  coordinates. **Coordinates are correct and drive map search; the text is not.**
  Unresolved: needs reverse-geocoding to fix, and nobody has decided whether the
  label or the coordinate is authoritative.
- One description, one phone (`987654321`) and **no photos** across all of it.
  Names are human first names ("Michael" ×163). It reads as demo data on a
  public site.
- **Emails deliberately not imported** — 493 real-looking personal addresses in
  the file. Same risk class as the seeded-CV incident. `--emails` opts in.
- **beds / guests are NULL.** Nothing in the file supports a capacity, and an
  invented one decides how many people can book. Existing live listings already
  carry NULL, so nothing breaks.
- 12 rows skipped (coordinates outside India even after the swap), 1 row
  repaired (SITAPUR/"Ahmed" — country held the zip, contact held the state).

---

## 2. Fixed this session — do not re-fix

### Web (`aajao-frontend-vercel`)

| Commit | What |
|---|---|
| `5b78bf6` | **Admin portal was reachable signed-out.** All 23 `/redesign/admin/*` routes were bare `<Route>`s outside `AdminProtectedRoute` — the same hole as `/account/dashboard`, on the admin tree. |
| `5ea05a5` `daada9a` | **All 15 Finance screens ported** into the redesign, and Finance added to the admin nav — it had **no entry at all**, so every money screen was reachable only by typing a URL. Reskin only: same Redux slices, thunks, types, GST helpers. |
| `a538fea` | **Route restructure.** `/redesign/host/*` → `/host/*`, `/redesign/admin/*` → `/admin/*`; legacy names redirect. |
| `befc94b` | Deleted the retired host portal and legacy FMS screens — **12,020 lines**. |
| `32488d4` | **Replaced the invented numbers** — see §3. |
| `43faf3d` | Row actions that looked clickable and did nothing. Coupons' **delete button** was inert, which reads as "deleted". |
| `2ad6f5f` | Tile captions, Analytics bars, Approvals link target. |
| `6bda4ac` | **Login session bug** — see §4. |
| `506aad5` | **Admin sign-out + "View site"** — the redesigned panel had neither. |
| `1d1ab54` | **Search now searches the place you typed** — see §5. |

### Backend (`aajaoBackend-render`)

| Commit | What |
|---|---|
| `e830f6b` | Dashboard "Recent Bookings" printed `—` for Property and Guest on every row; the query never selected them. |
| `850bbfd` | **Dashboard tiles contradicted their own drill-downs** — see §3. |
| `c0443b1` | **Pay-on-arrival bookings never reached the finance tables** — see §6. |
| `6ea1e38` `6c8f2b3` | The CSV importer, then batched (2.3/s → 298/s). |
| `cbb70c0` `6921850` | **Geo search had no result cap**, then the cap returned the wrong rows — see §5. |

### Mobile (`aajoo_app_2026`, in the monorepo)

| Commit | What |
|---|---|
| `9a1101c` | **Pricing double-tax.** The app sent an already-taxed total; the backend taxed it again. Fixed with `lib/utils/booking_pricing.dart` + 10 tests. **It was a mobile bug, not a backend one** — the 2026-08-10 handoff blamed `bookingCreate` wrongly. |
| `32f7e1d` | Host **"Total Earnings" counted money never collected** — summed every payment row including "Not Verified Yet". Read ₹1,77,723 where the host had been paid ₹74,829. |

---

## 3. The admin data-integrity work (what "wrong numbers" meant)

The user reported the dashboard saying "Total Users 3" while `/admin/users`
listed 10. It was **four of six tiles**, each counting a narrower population
than the screen it links to. Verified against the live DB:

| Tile | Was | Now | Why |
|---|---|---|---|
| Total Users | 3 | **10** | also required `isUser=1 AND isActive=1` |
| Total Properties | 10 | **14** | also required `isVerify=1 AND isActive=1` — hid 4 listings |
| Total Bookings | 15 | **21** | excluded status 2 while labelled "All time" — hid 6 cancelled |
| Verified Users | 3 | **9** | read a differently-scoped stat |

(Those "now" figures predate the CSV import; properties are 29,232 today.)

**Also fixed, and worth knowing about:** `getUserStats` / `getHostStats` /
`getPropStats` each computed `other = total − (active + inactive + verified)`.
Active and inactive already partition the set, so that expression is
arithmetically **`−verified`** — Analytics drew a **negative** "Other" bar.
Replaced with `unverified`.

Fabrications removed from the redesigned admin, all of which were live:

- Both Dashboard "overview" charts were **fixed SVG paths** — the same upward
  squiggle every deploy, under an axis hardcoded to "01 May … 31 May" and a dead
  "Daily" dropdown. The backend had returned `getMonthlyBookingsData` all along.
- **Platform Summary was six literals** ("Conversion Rate 3.42%", "Average
  Rating 4.6 / 5", "Active Properties 3,218"). Now six figures the API can
  answer. Conversion rate, repeat rate and average rating are **gone rather than
  guessed** — nothing reports them, and there are still **zero reviews** in the
  database.
- Every stat tile rendered `{label} vs Apr` under a green up-arrow — literally
  "Platform vs Apr".
- Header bell hardcoded `12`; sidebar disputes badge hardcoded `5`. The user
  chip said "Admin / Super Admin" for everyone including finance/support.
- Users, Hosts and Reviews gave **every real person one of two stock
  photographs**, alternating by row index. There is no avatar column; it renders
  initials now.
- A listing with no cover photo **borrowed a stock cottage** — on the
  verification queue, so an admin could approve a photo-less listing believing
  they had seen its photo.
- `DataTable` read **"Showing 1–10 of 248"** above dead page buttons on every
  list. Real counts and working pagination now.
- **Twelve screens swallowed their errors** into an empty `catch` and fell
  through to their empty state, so a 500 or a 401 asserted the platform was
  empty. They now say which happened, with a retry.

---

## 4. Auth: signing in as someone else kept the previous session in charge

Reported as "logged in as host from the normal login while signed in as admin,
and it took me to admin".

There are **two token slots**: the customer token (`storage`) and the admin
token (`adminSession`). `authGaurd.sessionRole()` resolves identity from the
**admin token first**. The redesigned login called `storage.setToken()` and
nothing else, so whoever was signed in before stayed in charge of routing:

- host login with an admin session open → guard answered `"admin"` → host sent
  to `/admin/dashboard` (the reported symptom);
- host login with **no** admin session → guard answered `"renter"` → host bounced
  to `/account/dashboard`. **The host portal was unreachable either way;**
- renter login after an admin used the browser → renter lands in the admin panel
  **on the previous admin's token**. Privilege escalation.

`services/session.ts` now owns "establish a customer session" and all four entry
points go through it — password login, signup-OTP verification, Google sign-in,
admin login. Admin login also clears the customer slot (it had the mirror hole).
Logout was already correct.

**Not verified in a browser:** signing in is the user's to do. The exact
sequence — admin, then normal login as host — is still worth one manual check.

---

## 5. Search: the properties were live, search never asked for them

Reported as "searched Kharar, 0 properties found" with 339 Kharar listings in
the database. Two independent bugs.

**The search page geocoded the typed place only to move the MAP** and kept
fetching stays around the *visitor's* browser location, then text-filtered those
for the word. Now the geocode drives the fetch. Text matching is skipped once a
place resolves — around Kharar the neighbours are "Shivalik City" and "Sawraj
Enclave", which do not contain "Kharar" and would otherwise be dropped.

**`/properties/search` had no result cap.** It orders by distance and returned
everything in radius. Harmless at 12 listings; not at 29,000:

| | Before | After |
|---|---|---|
| 100 km from Delhi | 1,320 rows / 1.07 MB | 100 rows |
| Client's "nothing nearby" fallback (r=20000) | **29,228 rows / 23.6 MB / 45 s** | **100 rows / 82 KB / 2.5 s** |

The frontend's widen-if-empty retry also went 20000 km → 500 km.

**A trap worth remembering.** The first cap attempt (`cbb70c0`) made it *worse*
— a Delhi search returned 8 rows, all old seed listings. The `hasMany` includes
make Sequelize wrap the model in a subquery to apply LIMIT, but the distance
filter is a `Sequelize.where` over a literal and stays on the **outer** query, so
the subquery took an arbitrary 100 by id and only then filtered by distance.
`6921850` resolves the nearest ids in a plain include-free query first, then
loads those with relations. **A local test that used only a belongsTo include
did not reproduce it — test with the real include set.**

---

## 6. Finance: the ledger was missing most of the platform

Reported as "revenue report shows ₹77,400 but the host account shows ~₹1.7 lakh".
Both numbers were wrong, in opposite directions.

`recordBookingFinance()` had exactly **one caller** — Razorpay payment
verification. Any booking confirmed another way wrote nothing: no ledger row, no
invoice, no payout. The ledger held **5 of 21 bookings** — ₹77,400.02 of
₹1,96,448.60 in booking value, with ₹1,19,048.58 unrecorded.

Fixed in `c0443b1`:
- COD bookings record at confirmation as **PENDING** — visible in the ledger,
  not counted as revenue (every report filters `COMPLETED`), and **no payout
  queued**, because `po_status` has no on-hold state and a QUEUED payout invites
  paying a host out of money never received. Verification promotes them.
- `recordBookingFinance` is now **idempotent** — it had no guard, so a second
  call wrote four more ledger rows, another invoice and another payout.
- The four finance reports **no longer mask DB errors as ₹0**.

**Backfill applied to production** (`scripts/backfillFinanceLedger.js`, user
approved): 2 bookings → COMPLETED (₹24,780, queuing ₹17,283 of host payouts),
3 confirmed COD → PENDING (₹13,104.28). Cancelled and never-paid bookings
skipped — they are not revenue. Ledger revenue went ₹77,400.02 → **₹1,02,180.02**.

Reconciliation of the whole platform:

```
₹1,96,448.60  all booking value
 − ₹63,048.80  cancelled
 − ₹18,115.50  never paid for
= ₹1,15,284.30  genuinely committed
      ₹1,02,180.02  collected  (= ledger revenue)
       ₹13,104.28  confirmed COD, not yet collected
```

**Still open:** refunds on cancelled-but-paid bookings (BPTEST04, ₹9,440) are a
separate decision the backfill deliberately does not make. And the ₹17,283 of
queued payouts is against **seeded test bookings** — do not approve them
believing they are real money owed.

---

## 7. Known gaps and open decisions

1. **Prebooking's 10% deposit needs a backend `advanceAmount` field.** It is
   deliberately untouched: sending the subtotal would charge a deposit guest the
   full stay, sending the deposit records the room as costing 10% of its price.
   Choosing between them is not a bugfix.
2. **`/admin/properties/form` and `/admin/status`** are the last two screens on
   the pre-redesign `AdminLayout`. Kept because nothing replaces them and
   deleting them removes working capability. They have the *old* navbar, so they
   look different and have their own logout.
3. **~5,123 properties have wrong city/state text** (§1b). Needs reverse-geocoding
   and a decision on which field is authoritative.
4. No detail view for bookings, reviews or payouts; no create/edit form for
   coupons. Dead buttons were removed rather than faked.
5. No admin notifications endpoint, so the bell has no count.
6. Zero reviews exist in the database, so every listing legitimately shows
   "New". Correct, not a bug — but tell the client or it gets reported.
7. Host 100 now owns 29,230 listings. **Nobody has checked how the host
   dashboard, earnings or properties screens behave at that size.**

---

## 8. Working practices

- **Web ⇄ mobile parity is a standing rule.** Every renter/host fix on the web
  lands on mobile in the same pass, recorded in `WEB_MOBILE_PARITY.md`.
- Push to production when done; don't leave work uncommitted.
- **Verify against the live database or the deployed artefact, not the source.**
  Several bugs this session only showed up that way, and one "fix" was wrong
  until tested against real data.

**Boundaries respected all session, keep respecting them:**
- Never type passwords into login forms — ask the user to sign in. This is why
  the auth fix (§4) and the admin sign-out click are still unverified by hand.
- Never enter card numbers, even test cards.
- Confirm before anything outward-facing or hard to reverse. The CSV publish and
  the finance backfill were both put to the user first, with the numbers.

---

## 9. Test accounts and state

| Role | Credentials |
|---|---|
| Renter | `aajoo.renter1@mailinator.com` / `Renter@12345` |
| Host | `aajoo.host1@mailinator.com` / `Host@12345` (host **100**, owns the 29,230 listings) |
| Admin | `admin@mailinator.com` / `Admin@123` — sign in at `/admin/login`, then `/admin/dashboard` |

Note the admin routes are now `/admin/*`, not `/redesign/admin/*`.

There is a **dev-only** admin auth bypass for local visual checks: add
`VITE_DISABLE_ADMIN_AUTH=true` to `.env.local` (gitignored) and restart Vite.
Remove it afterwards. It only renders the shell — the page's own API calls still
401 and the interceptor bounces to login, so it is good for markup, not flows.

OTP is real: six digits, emailed via Brevo from `contactus@aajoohomes.com`,
valid 10 minutes. Health checks: `/health/mail` and `/health/push`.

---

## 10. First five minutes of the next session

1. Confirm the bundle: `curl -s https://www.aajoohomes.com/ | grep -oE 'assets/index-[A-Za-z0-9_-]+\.js'` — expect `index-vBwe-f9w.js` or newer.
2. Search **Kharar** on the site. It should return results now (§5). If not,
   that is the first thing to chase.
3. Ask the user whether to reverse-geocode the ~5,123 mislabelled cities (§1b/§7.3).
4. Ask whether the ₹17,283 of queued payouts against test bookings should be
   cleared out (§6).
5. Look at the host portal as host 100 — 29,230 listings is a load nobody has
   exercised (§7.7).
