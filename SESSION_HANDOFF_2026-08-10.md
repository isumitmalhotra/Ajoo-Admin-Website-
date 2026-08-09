# Session handoff — 2026-08-10

Read this first. It is written for a fresh session with no memory of the work.

---

## 0. The three repos and how they deploy

| Repo | Path | Deploys to | Push with |
|---|---|---|---|
| Web frontend | `D:/Projects/aajao-frontend-vercel` | Vercel → `www.aajoohomes.com` | branch is `redesign/aajoo-2026`, so `git push origin HEAD:main` |
| Backend | `D:/Projects/aajaoBackend-render` | Render → `aajaodev.onrender.com` | `git push origin main` |
| Monorepo (mobile lives here) | `D:/Projects/ajoo admin website` | not deployed | `git push origin main` |

The Flutter app is `aajoo_app_2026/` inside the monorepo. Package
`com.aajoo.aajoohomes`, internal Dart package name `rent_home`.

**Two hard-won build rules:**

1. **Web: always run `npm run build`, never just `npx tsc --noEmit -p tsconfig.json`.**
   The bare tsconfig does not resolve the app's project references. A real type
   error in `Search.tsx` passed `tsc --noEmit`, failed `tsc -b`, and silently
   broke **every Vercel deploy for a full day** while three pushes looked
   successful locally. Always confirm the deployed bundle hash actually changes
   at `https://www.aajoohomes.com/` (`grep -oE 'assets/index-[A-Za-z0-9_-]+\.js'`).
2. **`adb` is not on PATH.** Use
   `$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe`. The emulator is
   `emulator-5554`, API 37.

---

## 1. What must be decided before coding — ask the user

### 1a. The pricing double-tax (MONEY BUG — top priority)

`controllers/booking.controller.js`, in `bookingCreate`:

```js
let totalBookingAmt = reqData.price + tax;
```

The mobile app sends `price` as the **already-taxed total**, so the backend
taxes it a second time. Verified on a real booking (**B618787**):

| Value | Amount |
|---|---|
| App quoted, and what was actually charged | ₹23,020 |
| Stored in `book_price` | ₹23,020 |
| Stored in `book_total_amt` | **₹24,171** (= 23,020 × 1.05) |

Three consequences: the Razorpay order is created from the inflated figure, the
ledger's two totals disagree, and **`createPaymentOrderOngoingBooking` charges
`book_total_amt`** — so a pay-on-arrival guest is billed ~₹1,151 more than the
app quoted.

Options put to the user, still unanswered:
- **(a)** app sends the room subtotal (₹19,500), backend owns all tax —
  recommended, but needs a decision on where the ₹10 platform fee lives
- **(b)** backend stops re-taxing and trusts the client total — smaller change,
  but the client then controls pricing
- **(c)** review with product/finance first

**Do not guess.** This changes what customers are charged.

### 1b. Are the legacy Finance pages functionally correct?

User said "yes they are for now, but check those as well". So: port them, and
verify as you go (totals reconcile, filters apply, payout actions fire).

---

## 2. The current task: admin redesign + route restructure

The user's ask, in their words: build the missing redesigned admin screens so
admin looks like renter and host, redo all Finance screens the same way, then
discard the old portal and finish the route restructure.

### 2a. Audit already done — use this, don't redo it

| Namespace | State |
|---|---|
| `/redesign/admin/*` | 23 redesigned pages exist |
| `/redesign/host/*` | 16 redesigned pages exist |
| **`/host/*`** | **empty** — no legacy routes, safe to rename into |
| **`/admin/*`** | **occupied** by the live legacy portal |

Only `/admin/login` appears as a literal `path="/admin/..."` in `App.tsx`. The
rest of the legacy admin tree is **nested children with relative paths** under
`AdminProtectedRoute` + `AdminLayout` — a plain grep for `path="/admin/` will
miss them. The legacy Finance components are imported around `src/App.tsx:45-49`
(`FinanceDashboard`, `LedgerList`, `HostLedger`, `GuestLedger`, `PayoutQueue`).

### 2b. Finance pages to port (reskin, do NOT rebuild)

They are wired and working against real data — the user's screenshot showed
₹75,171 revenue, ₹10,293 commission, ₹60,474 pending payouts. Keep the data
layer, change the presentation:

Financial Overview · Ledger List · Host Ledger · Guest Ledger · Payout Queue ·
Invoices (and check whether Reports is already covered by
`/redesign/admin/reports`).

### 2c. Design language — inherit, do not invent

Same system the other 23 redesigned admin pages use:

- Evergreen Teal `#0F766E` primary, deep teal `#115E59` pressed, tint `#EFFAF8`
- Golden Amber `#E8A317` accent (white text on it), pressed `#D4930F`
- Warm Ivory `#FAF8F4` surfaces, warm line `#EAE4DA`
- Ink `#1F2937`, secondary `#334155`, muted `#64748B`
- Fraunces for headings, Inter for body
- Reuse the existing redesigned admin shell + table/card components

The legacy FMS purple gradient is **not** the target.

### 2d. Suggested order

1. **Host rename** — `/redesign/host/*` → `/host/*`. 16 routes, empty
   namespace, low risk, proves the pattern. Caveat: `src/App.tsx` has a
   redirect map where `"/host": "/become-a-host"` — adjust it.
2. **Port + verify Finance.**
3. **Gap-fill** any other admin page with no redesigned equivalent.
4. **Swap admin** onto `/admin/*`, redirect legacy paths rather than 404ing
   bookmarks.
5. **Delete** legacy components, sweep internal links.
6. **Verify every route** signed-out, as renter, as host, as admin.

**Trap:** `/become-a-host` and `/become-a-host/register` sit in the *middle* of
the host route block and must stay **public**. Guarding them locks everyone out
of host registration. The host block is deliberately wrapped in two
`<Route element={<HostRoute />}>` blocks with those two routes outside; there is
a comment in `App.tsx` saying so. Do not "tidy" it into one.

---

## 3. Fixed this session — do not re-fix

### Backend (`aajaoBackend-render`)

| Commit | What |
|---|---|
| `8b55b55` | **Real ratings.** `utils/propertyRatings.js` aggregates avg + count from `tbl_reviews` in one grouped query per page; attached to `/properties/search`, `/properties/:id`, listing endpoint; `sort_by=rating` now actually sorts. Unrated returns `rating: null`, not `0.0`. Also `utils/hostVisibility.js`: admin delete now deactivates the host's listings, and `withLiveHosts()` filters listings whose owner is deleted. |
| `4b9a31c` | **Duplicate payment rows.** Paying later inserted a *second* payment row with the same invoice; verification updated only the newer one, so hosts saw one invoice twice with contradictory statuses. Now reuses the pending row. `hostTransactionHistory` also de-dupes on read (historical rows kept — never delete payment records to tidy a list). |
| `e98ef59` | **Host wizard could not submit.** `schema/properties.schema.js`: a multipart form sends ONE value for a single selection, so `property_category: "1"` failed `yup.array()` — the wizard only worked if you picked 2+ categories. Added an `asArray()` transform. Also `property_contry` was validated as `yup.number()` but the column is `STRING(20)` holding names like "India". |

**Data fixes applied to the live DB** via `scripts/fixPropertyData.js` (dry-run
by default, `--apply` to write):
- 8 stay-time rows normalised. The column held `"14:00"`, `"12:00"`,
  `"05:05"/"05:58"` (nonsense), `"2:00 PM"` 12-hour text and nulls, all at once.
  Unreadable/implausible now carry the platform policy 14:00 / 11:00; plausible
  host-set values left alone.
- Property 4 taken offline — owner `user_isDelete = 1`.

### Web (`aajao-frontend-vercel`)

| Commit | What |
|---|---|
| `a8ac1cd` | Unverified signup can resume — backend returns `{needsVerification, userId}` and neither client read it. |
| `f04cae0` | Cards show the real rating or **"New"**; removed the `\|\| 4.6` fallback. |
| `821aa25` | **Auth guards.** 33 routes (17 `/account/*` + booking flow, 16 `/redesign/host/*`) had **no guard** — an anonymous visitor could open `/account/dashboard`, which rendered and fell back to the label "Guest". Now wrapped in `RenterRoute` / `HostRoute`. |
| `1855d94` | Fixed the `Search.tsx` null errors that had been failing every Vercel build. |
| `cbb31e4` | Guard redirects were pointing at **legacy** pages (`/auth/login`, `/user-dashboard`, `/host/dashboard`) → now `/login`, `/account/dashboard`, `/redesign/host/dashboard`. |

### Mobile (`aajoo_app_2026`)

Highlights (see `WEB_MOBILE_PARITY.md` for the full ledger):
- **Logout did nothing** when `_firebaseMessaging.deleteToken()` threw — it sat
  in the same `try` as the navigation, so the session cleared but the app stayed
  put. Cleanup is now best-effort; navigation moved to `finally`. Host Profile
  had **no logout at all** — added.
- **`Reveal` was hiding real content.** It attached to `Scrollable.maybeOf`,
  which inside a shrink-wrapped grid is the inner non-scrolling list — anything
  below the fold stayed at opacity 0 forever. "Curated for you" was a
  screen-high blank gap. Now uses `ScrollNotificationObserver`.
- **Host block was fiction** — `'Aajoo Host'` was a literal and
  `'Superhost · Replies in 1 hr'` a default parameter; "Host Details" showed the
  phone number as the name over a stock photo hotlinked from Google. Now uses
  `/properties/host/:hostId` (which the web always used). Note it returns
  `success:true` with `data: []` — a **list** — for a non-host owner.
- **Ratings**: `"4.5"` was hardcoded in ~13 places incl. a literal `· 164`
  review count and a second badge on the hero image. All real or "New".
- Bookings tabs (renter **and** host) bucket by the stay clock, not the status
  word — a paid booking keeps status "Paid" forever, so finished stays sat under
  Upcoming.
- Dead controls removed/wired: heart button was `onPressed: () {}`,
  "Guest Favorite" on every card, "Free Cancellation" on every card, a
  "Confirm Booking" FAB behind a flag never set true, host rating `4.8/5`,
  a support email whose `mailto:` differed from the displayed address.
- Wizard now has a `PopScope` back-guard — system back used to discard a
  half-written listing silently.
- `lib/utils/stay_clock.dart` and `lib/utils/notification_link.dart` are Dart
  ports of the web's `stayClock.ts` / `notificationLink.ts`, both with tests.
  **19 tests, all passing** (`flutter test`).

---

## 4. Verified working end-to-end (don't re-test unless something changes)

- **Booking → payment → invoice.** B618787, ₹23,020, one payment row, correct
  invoice, lands under **Ongoing** (check-in 2 PM had passed).
- GST banding: 5% at ₹6,500, 18% at ₹19,500 — correct at the ₹7,500 threshold.
- Host wizard **submit** — `#32 "QA End ToEnd Villa"`, `active=false`,
  `status=unverified`, correctly pending approval.
- Property detail: real host block, brand-teal chips, "New listing", stay times
  14:00 / 11:00.
- Renter + host dashboards, bookings tabs, profiles, logout.

---

## 5. Still untested

1. **Admin approval of `#32`** → then verify it appears in app search
2. **Negotiation → offer → host accepts → coupon → book**
3. **Signup start-to-finish with the real emailed OTP**
4. Search filters / sort / date range
5. Cancellation from mobile
6. Push notifications (needs a real handset, not the emulator)

---

## 6. Known gaps, deliberately not fixed

- **Zero reviews exist in the database**, so every listing legitimately shows
  "New". This is correct, not a bug — but tell the client, or it gets reported.
- **`switchMode()` is dead code** — exists in both auth controllers with no UI
  call site. A host cannot browse as a guest. Web has the switch.
- **No messages inbox on mobile** — only the per-property negotiation thread.
- Stay clock enforces 2 PM / 11 AM from constants on both clients, so a
  per-property check-in time is *displayed but never honoured*. Product
  decision: either the clock reads it, or the page stops showing it.
- **Two classes named `AuthController`** (`lib/controller/` and
  `lib/ui/screens_common/auth/`). `Get.find` keys on the class *name*, so
  importing the wrong one hands back the live instance typed as a class it is
  not. One file was already doing this. The legacy tree is dead — delete it.
- Requested but not started: **Indian states + cities**, backend-served
  (`/common/states`, `/common/cities?stateId=`), cascading dropdowns, country
  locked to India, and a **map search that autofills** address/city/state from
  the same IDs. Evidence it's needed: listing `#32` stored `state=1` when the
  host typed "HARYANA" (Haryana is `5`), city `gurugram`, country `india`.

---

## 7. Working practices the user has asked for

- **Web ⇄ mobile parity is a standing rule.** Every renter/host fix on the web
  must land on mobile in the same pass, recorded in `WEB_MOBILE_PARITY.md`.
- Push everything to production when done; don't leave work uncommitted.
- The QA guide artifact covers **both** platforms and should be kept current:
  `https://claude.ai/code/artifact/f7c3128d-9854-45e7-9476-ca3b4f2cb3d3`

**Boundaries respected all session, keep respecting them:**
- Never type passwords into login forms — ask the user to sign in. This is why
  negotiation and signup are still untested.
- Never enter card numbers, even Razorpay test cards — drive up to the payment
  sheet and hand over.
- Never paste secrets/tokens into chat, email or documents.

---

## 8. Test accounts and current device state

| Role | Credentials |
|---|---|
| Renter | `aajoo.renter1@mailinator.com` / `Renter@12345` |
| Host | `aajoo.host1@mailinator.com` / `Host@12345` (host 100, "Aajoo Test Host") |
| Admin | `admin@mailinator.com` / `Admin@123` — sign in at `/admin/login`, then go to `/redesign/admin/properties` |

Emulator `emulator-5554` has `Aajoo-Homes-20260810-release.apk` installed. A
stale `com.example.aajoo_homes` package may still be present — it looks
identical and shows months-old screens; `adb uninstall com.example.aajoo_homes`.

OTP is real: six digits, emailed via Brevo from `contactus@aajoohomes.com`,
valid 10 minutes, destroyed after 5 wrong attempts. `0000` no longer works.
Health checks: `/health/mail` and `/health/push`.

---

## 9. First five minutes of the next session

1. `curl -s https://www.aajoohomes.com/ | grep -oE 'assets/index-[A-Za-z0-9_-]+\.js'`
   — if it still says `index-B8r5BsHq.js`, the Vercel build is failing again and
   **none of today's web fixes are live**, including the auth guards. Fix that
   before anything else.
2. Ask for the **pricing double-tax** decision (§1a).
3. Ask whether the Finance pages need any functional fixes (§1b).
4. Start with the **host route rename** (§2d step 1).
