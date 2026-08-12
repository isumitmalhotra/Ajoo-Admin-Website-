# Session Handoff — 2026-08-13

Successor to `SESSION_HANDOFF_2026-08-12.md`. That one is still accurate for
everything before this session; this file covers what changed since and what
comes next.

**State at handoff: all three repos clean and pushed. Nothing half-finished in
the working tree.** The next batch (My Bookings + Menu) was explored but no
code was written for it — findings are in §5 so you don't have to re-derive them.

---

## 1. What this project is

Aajoo Homes — a negotiation-first stay marketplace for India. Guests browse
stays, can **negotiate the price with the host** before booking, and book
either online (Razorpay) or pay-on-arrival. Hosts list properties and get paid
out after checkout, minus commission. Admins verify listings, moderate, and run
finance.

### Three repos, three deploy targets

| Path | Repo | Deploys to | Branch → push |
|---|---|---|---|
| `D:\Projects\aajao-frontend-vercel` | `nameeshPatiyal100/Aajao-Admin-WebSIite` | **Vercel** → `www.aajoohomes.com` | local branch is `redesign/aajoo-2026`; push with **`git push origin HEAD:main`** |
| `D:\Projects\aajaoBackend-render` | `nameeshPatiyal100/aajaoBackend` (private) | **Render** → `aajaodev.onrender.com` | `git push origin HEAD:main` |
| `D:\Projects\ajoo admin website` | monorepo — contains `aajoo_app_2026/` (Flutter) + all docs/trackers | not deployed; app ships via build | `git commit` (no push configured this session) |

> ⚠️ **The frontend push trap.** The local branch is `redesign/aajoo-2026`, not
> `main`. A plain `git push origin main` pushes the stale local `main` and gets
> rejected non-fast-forward. Always `git push origin HEAD:main`.

### Stack

- **Web**: React + Vite + TypeScript, Redux Toolkit. Redesigned surfaces live
  under `src/redesign/`; legacy pages under `src/pages/`.
- **Backend**: Node/Express/Sequelize/MySQL.
- **Mobile**: Flutter + GetX, in `aajoo_app_2026/`.

### Commands that matter

```bash
cd "D:/Projects/aajao-frontend-vercel" && npm run build
```
```bash
cd "D:/Projects/ajoo admin website/aajoo_app_2026" && flutter analyze lib/ui/screens_renter/
```
```bash
cd "D:/Projects/ajoo admin website/aajoo_app_2026" && flutter build apk --debug
```

**Never** run bare `npx tsc --noEmit -p tsconfig.json` on the web — use
`npm run build`.

---

## 2. How the work is organised

The client sent `_Web App Bugs.xlsx`. Two sheets matter: **"Aug 08-26"**
(web/admin, 20 items → **Block W**) and **"Aug 08-26 App"** (mobile, 83 items →
**Block A**). All 192 items were transcribed with stable ids into:

- **`BUG_TRACKER_2026-08-12.md`** ← the live tracker. Check items off here.
- `MASTER_PENDING_TASKS.md` — the older cross-cutting backlog.

**Block W: all 20 done.** Block A: A-1 through A-59 done (see §3). The user
feeds the rest in batches, in their own words, several items per message.

### Working rhythm the user expects

1. They paste a batch of terse requirements.
2. You investigate the actual code and **the production database** before
   changing anything — several "cosmetic" items in this session turned out to
   be money or lockout bugs, and several turned out to be already-correct.
3. Fix on **both platforms** where both are affected (standing rule; ledger
   `WEB_MOBILE_PARITY.md`). Say explicitly when only one platform is affected.
4. Verify: `flutter analyze` + `flutter build apk --debug` for the app,
   `npm run build` for the web, and a real query/controller call against
   production for backend changes.
5. Commit per batch with a message that explains *what was actually wrong*.
6. Update `BUG_TRACKER_2026-08-12.md`, commit that separately as `docs:`.
7. Report back plainly — including anything you found that they didn't ask about.

They value being told when the premise of a request was wrong (e.g. the "POA"
item below), and they don't want padding.

---

## 3. What shipped this session

Six batches. Every one is committed and deployed.

### Batch 1 — Blog control + Property Detail (A-25 → A-36)

Backend `3b648cd`, `33343fe` · Web `21c4ef4`, `6877f3c`, `7784ff6` · App `f3b2926`, `98ff4e7`

- **Admin blog screen** (`/admin/blogs`): create/edit/publish/delete + cover image.
- **Public blog on the web** (`/blog`, `/blog/:id`) and **in the app**
  (`blog_screens.dart`). Neither existed — the admin could publish to nowhere.
- 🚨 **`/blog/create` had no auth middleware at all.** Verified against
  production: posting with no token reached validation. Anyone could publish
  posts, upload files, and (it accepts `blogId`) rewrite existing ones. Now
  `adminAuthToken`. Also deleted `/blog/test-img`, an unauthenticated
  file-upload endpoint whose handler only `console.log`ged.
- **Property detail → real tabs** on both platforms (About / Amenities / House
  Rules / Location / Guest experiences / Host / Policies). Web had jump links
  down one long page; the app rendered everything at once.
- **Verified badge driven by `verification_status`**, not `is_verify`.
  `is_verify` is `1` on **29,229 of 29,232** live listings, so the "Aajoo
  Verified Home" card claiming a stay was checked for quality/safety/hygiene
  showed on all 29,219 that had not been. Ten listings are genuinely verified.
- **Nearby distances (A-34/A-35) — was tracked as blocked on a places API; it
  wasn't.** `property_nearby_places` has existed since the listing wizard
  shipped and nothing ever read it; the legacy add-property form never wrote to
  it, so it held 0 rows. Now: `GET /properties/:id` returns it, both platforms
  render it, and **Admin → Properties → Nearby** fills it in for existing
  listings. Added Park + Beach to the vocabulary.
- Removed invented content shown on every listing: the "Entire Place / High
  Speed WiFi / Free Parking" strip, an eight-amenity fallback for hosts who
  selected none, five fixed house rules, and a hardcoded 2:00 PM / 11:00 AM
  check-in (those columns held real per-property values all along).

### Batch 2 — Reserve sheet (A-37 → A-44)

App `25e212a`

- 💰 **Selecting "Monthly" multiplied the price by 30.** `_updatePriceString`
  did `rate * 30 * ceil(days/30)` for Monthly and `* 7` for Weekly, and that
  figure became the `price` on the booking. A two-night stay booked as
  "Monthly" charged thirty nights. The stay type was never anything but a
  label: `bookingType` isn't declared in the backend's `createBooking` schema
  and validation runs with `stripUnknown`, so the server has **never** received
  it. Now: `Per night` / `Monthly` (Weekly gone), price is always
  `nightly rate × nights`.
- 💰 **The same screen counted nights two different ways.** Hand-picked dates
  used `.inDays + 1` (a 12th→13th stay billed as two nights); the
  negotiated-deal path and the website used the plain difference. Same dates,
  different totals depending on how you got there. Both now use the difference.
- Host price bands (weekly min/max) removed from the guest's breakdown — that's
  the floor the host will negotiate down to, shown directly under what the
  guest is being asked to pay.
- Check-in/out row lost its fake chevron (it opened nothing). "Reserve" →
  "Negotiate & Reserve". "Offer Your Price" → "Negotiate".
- **Negotiation loader that never cleared**: `loadNegotiationChat` set
  `isLoading = true` and its `.then()` never unset it — only the chat-history
  socket event did, and on a first-time negotiation there is no history to
  send. Fixed, plus a 12-second watchdog.

### Batch 3 — KYC, confirmation, maps (A-45 → A-50)

Backend `7986ba5`, `8531aaf` · App `2097435`

- **KYC no longer loses the booking.** DIDIT opens in the system browser
  (camera is unreliable in a webview — deliberate), Android may destroy the
  activity, and Flutter restarts with an empty stack. The booking intent is now
  written to disk before handing over (`lib/service/pending_booking.dart`), and
  a **"Finish your booking"** banner on the home screen reopens that property
  with the same dates. Both gates: reserve sheet and accept-offer.
- 📧 **Paid bookings emailed nobody.** `sendBookingNotifications` had exactly
  one caller — inside `if (isCod)`. Every online-paid booking completed
  silently: no guest confirmation, no invoice, host got only a push. Now sent at
  payment verification, plus a **host email** (no host had ever received one).
- 🔒 **Emails live in `tbl_user_creds.cred_user_email`.** `tbl_users` has **no
  email column**. A `findUser` for one throws "Unknown column", which the
  try/catch would swallow into a warning and silently send nothing. Caught by
  testing, not by reading.
- **Booking confirmed is a route now**, not a dialog — the dialog needed the
  property page's `BuildContext` still mounted when Razorpay handed back, which
  is why it could fail to appear on a card payment. Has the map + Get Directions.
- **Ongoing booking screen got the map inline.** It had a button that made a
  *second* request just to fetch coordinates and then threw the guest out to
  Google Maps. The coordinates were in the payload all along — the model was
  discarding `property_latitude/longitude/city/address`.
- 🚫 **The "new user sees the one-POA limit" report was not the policy.** The
  app decided what counts as an "active" booking by comparing the status
  **title** against `"Cancelled"` and `"Completed"`. There is no Completed
  status — the real titles are `Payment Pending`, `Cancelled`, `Paid`,
  `Booked`, `"Check In "`, `"Check Out "` (trailing spaces), `Booking
  Confirmed`, `Payment Received`, `Running`. So it excluded one status and
  counted everything else forever, including abandoned card checkouts (the app
  creates the booking *before* opening Razorpay). **Production evidence: user
  101 had 4 "active" bookings, all 4 abandoned pending rows, one flagged COD —
  that account was locked out of booking entirely.** Now keyed on status ids,
  matching the backend guard including its 30-minute hold.

### Batch 4 — LUX + Pre-booking (A-51 → A-59)

App `05696a3`

- **`lib/ui/screens_renter/home/components/lux_theme.dart`** — LUX's own look:
  near-black + gold vs standard's Warm Ivory + teal, gold section rules, filled
  icon swap, slower motion curve, gold-edged cards. **Deliberately not overrides
  of the `k*` tokens in `constants.dart`** — ~88 files read those; repainting
  the app from a mode toggle gives you a teal button on a black sheet. Screens
  opt in.
- **`LuxLoader`** — gold LUX wordmark under a sweeping arc. Replaces the grey
  shimmer whenever LUX is on.
- **`showLuxSwitchDialog`** — the switch was a bare Material `AlertDialog`, the
  same grey box in both directions. Now dressed for the direction of travel, and
  entering LUX holds the loader until the luxury listings land so it never
  flashes the standard page.
- **Pre-booking**: editable location (was a `FutureBuilder` that reverse-geocoded
  on every rebuild and couldn't be changed); real category pills (was five
  hardcoded occupancy tiles whose filter matched titles three of them didn't
  correspond to); the animated LUX toggle top-right (was a hand-rolled pill
  using an asset named **`diamond .png`** — with a space); **area rails**
  (Shimla / Kufri / Mohali / Panchkula / Kharar / Chandigarh, 12 each, loaded in
  parallel); **check-in/check-out** (there was no date input at all).
- Area rails filter on **`filters.area`** (address LIKE), **not `filters.city`**
  — exact city match returns **1** property for Mohali and **0** for
  Chandigarh, vs **48** and **51** by address. Cards show the address for the
  same reason (a Chandigarh property comes back with city "Karol Bagh").

---

## 4. Decisions you must not silently reverse

- **Empty means hidden, never zero.** Nearby distances, area rails, blog
  strips, house rules and amenities all render *nothing* when the host entered
  nothing. An invented "0 km to the airport" or a stock amenity list is worse
  than an absent section. This principle drove a lot of this session.
- **`verification_status`, never `is_verify`.**
- **`filters.area`, not `filters.city`** for anything geographic on the
  imported dataset.
- **Blog bodies render as text, never `dangerouslySetInnerHTML`** (web) or an
  HTML renderer (app). They're admin-authored; that's stored XSS on a page
  every visitor reads.
- **`kHiddenBrowseCategories`** (in `area_rails.dart`) is shared by the home and
  pre-booking browse rows so they can't drift. `couple`/`party`/`Resort` are
  **hidden, not deleted** — 10 live properties are tagged with them and
  dropping the rows leaves those uncategorised. See §6.
- **Don't duplicate backend business rules in the client with string matching.**
  That's what broke the booking limits.

---

## 5. NEXT UP — My Bookings + Menu (not started)

The user's most recent batch, verbatim:

> **My booking Page**
> Change all the tabs as per the current theme
> Upcoming stay / Ongoing page / Completed / Cancelled
> User click on the view on the details page
> Show the support button and host chat button and host details below the
> booking if TAB but not in the cancelled — Show there book now button only, do
> not show the Host details
> Show the all property page below all of the above mentioned
> Show property photos instead of maps
>
> **Menu**
> Remove right side menu and fix this menu below the profile page where all
> pages exist
> Safety, about us pages same as the website

### What I found before the session ended (saves you the dig)

| Thing | File | State |
|---|---|---|
| Bookings tabs | `lib/ui/screens_renter/history/history_page.dart` (179 lines) | Tabs **already exist and bucket correctly** (`Upcoming/Ongoing/Completed/Cancelled`, `_bucket()` at line ~40 uses dates not just titles). What's off-theme: `AppBar` is solid `kIndigo` with white-on-teal tabs, while the rest of the redesign uses `kCream` surfaces with teal accents. That's the "as per the current theme" ask. |
| Booking detail | `.../history_description/history_description_page.dart` (391 lines) | Has a **`HistoryMapSection`** (Google Map) at line ~93. **No support button, no host chat button, no host details block, no property gallery.** All four need adding. |
| Map → photos | `.../history_description/components/property_details_map_section.dart` | This is the map to replace with a photo gallery. Note: I *added* maps to the **confirmed** and **ongoing** screens last batch (that was asked for) — this request is specifically about the **booking-history detail** page. Don't undo the other two. |
| Right-side menu | `lib/ui/screens_renter/home/components/custom_drawer.dart`, used at `homescreen.dart:146` (`drawer: CustomDrawer()`) | Contains: Dashboard, Profile, History, Bookmarks, **Safety**, Settings, Help & Support, **About**, Logout. Needs removing and its entries folded into the profile screen. |
| Profile screen | `lib/ui/screens_renter/profile/profile_screen.dart` | Where the menu should land. Already has `ListTile` sections around lines 1232–1250 and 1530–1637. |
| Safety page | app: `lib/ui/screens_renter/safety/safety_page.dart` · web: **does not exist** | ⚠️ The web has **no Safety page** — only `/about` (`src/redesign/pages/About.tsx`) and `/state-regulation`. "Same as the website" can't be satisfied for Safety without building the web page too, or picking a different source of truth. **Ask the user which they want.** |
| About page | app: `lib/ui/screens_common/about/about_page.dart` · web: `src/redesign/pages/About.tsx` (route `/about`) | Both exist; align the app's to the web's content. |

Also note there are **dead twins** of several of these under `lib/screens/`
(`about_page.dart`, `safety_page.dart`, `property_page.dart`, …). See §7.

### Suggested order

1. Retheme the bookings tabs (small, visible, low risk).
2. Booking detail: swap map → photo gallery; add support / host chat / host
   details, gated so **Cancelled shows a "Book now" button and no host block**.
3. Append the full property detail below (the tabbed panels from batch 1 are
   already componentised — reuse, don't copy).
4. Menu: delete `CustomDrawer`, fold entries into the profile screen.
5. Safety/About — **check with the user about the missing web Safety page first.**

---

## 6. Blocked on the user

| Item | Detail |
|---|---|
| 🔴 **Render env** | `RENDER_ENV_CHECKLIST.md`. 5 `DB_*` wrong, 4 vars missing, and **`OTP_DEV_BYPASS` is still `true` in production**. Needs their Render dashboard. This has been open for several sessions. |
| 🔴 **RazorpayX + `FIELD_ENCRYPTION_KEY`** | `PAYOUTS_SETUP.md`. Payouts are built and tested but cannot move money without these 4 vars. |
| 🟡 **SMS provider** | `SMS_PROVIDER_REQUIREMENTS.md` (client-facing, MSG91 recommended, DLT process explained). Unblocks A-5 and A-11. |
| 🟡 **`couple`/`party`/`Resort` categories** | Hidden from browse; the rows still exist with **10 properties tagged**. To actually delete them, those 10 need recategorising first. Asked; no answer yet. |
| 🟡 **Kufri** | Named as a pre-booking area but has **zero listings**. Its rail hides itself until listings exist. |
| 🟡 **Confirmed-page reference image** | They mentioned one; it never arrived. Built to the web's pattern. Offered to adjust. |
| ⚠️ **Backend repo hygiene** | A `git add -A` swept `logs/` into commit `3b648cd`. Those request logs contained a test account's plaintext password (`HostTest@123`) and live FCM device tokens. Untracked + gitignored in `03ee8b0`. Repo is private, so exposure is limited to collaborators — **but treat those FCM tokens as known.** |

Also flagged in memory but not re-verified this session: the **Cloudinary
account is shared/polluted (704 assets)** and may hold more PII after the
seed-image incident.

---

## 7. Landmines

- **Duplicate class names across `lib/`.** Flutter has no compile error for
  this and `Get.find` keys on the name. Confirmed twins: `AuthController`,
  `HostController`, `VerifyController`, `MapController`, `PropertyPage`,
  `PriceNegotiationPage`, `BookingController`. **The live one is under
  `lib/ui/`; the dead twin is under `lib/screens/`, `lib/widgets/` or
  `lib/controller/`.** I edited a dead `MapController` once and the analyzer
  only caught it via a missing getter. Always `grep` the import in the screen
  that uses it before editing.
- **yup `stripUnknown: true`** silently drops any field the schema doesn't
  declare. This is why `bookingType` never reached the server. If you add a
  field to a request, add it to the schema.
- **Validation middleware returns `message` as an ARRAY at HTTP 422.** Web has
  `src/services/apiError.ts` → `apiErrorMessage()` to flatten it.
- **Sequelize**: `undefined` in a `where` throws; includes with `where` default
  to `required: true` (INNER JOIN) — this is what made `/blog/search` return an
  empty list while five posts were published; `raw: true` flattens joins to
  dotted keys (`"blogImg.afile_path"`).
- **Booking dates are `DD-MM-YYYY`** everywhere in the API.
- **Render free tier sleeps after ~15 min.** A keep-alive workflow runs from the
  public monorepo (`.github/workflows/keep-alive.yml`); the app also has
  cold-start retry in `lib/data/source/remote/dio_config.dart`.
- **Don't boot `app.js` in a test script** — it starts campaign schedulers that
  keep the process alive forever (cost me a 4-minute timeout). Call the
  controller directly with a fake `req`/`res`, as
  `scripts/_tmp_*.js` did. Delete those scratch scripts before committing.
- **Dart strings**: apostrophes in single-quoted strings break compilation.
  Use `"..."` or reword.
- **Git commit messages with backticks/quotes**: use `git commit -F -` with a
  heredoc. Inline `-m` with backticks gets mangled by the shell into pathspec
  errors.
- **Test data on production**: user 101 and host 100 are test accounts; ~28,918
  CSV-imported listings sit under host 100 with **swapped source lat/long** and
  ~4,260 junk CITY labels. Never let that dataset validate itself.

---

## 8. Verification habits that paid off this session

Every significant finding this session came from checking production rather
than reading code:

- Counting `verification_status` → found the badge was false on 29,219 listings.
- Counting per-user ongoing bookings → found user 101 locked out.
- Querying `property_city` vs `property_address` → found `filters.city` would
  have shipped near-empty rails.
- Running the email templates → found `tbl_users` has no email column, which
  the try/catch would have hidden.
- `curl`ing `/blog/create` with no token → confirmed the auth hole was real
  and not just missing-looking.

Keep doing this. A one-off script against the live DB takes two minutes and has
repeatedly changed what the right fix was.

---

## 9. Docs index

| File | What it is |
|---|---|
| `BUG_TRACKER_2026-08-12.md` | **Live tracker** — the 192 xlsx items, W-* and A-* ids |
| `MASTER_PENDING_TASKS.md` | Older cross-cutting backlog |
| `WEB_MOBILE_PARITY.md` | Web ⇄ mobile parity ledger |
| `RENDER_ENV_CHECKLIST.md` | Env vars the user must set — **open** |
| `PAYOUTS_SETUP.md` | RazorpayX credentials — **open** |
| `SMS_PROVIDER_REQUIREMENTS.md` | Client-facing SMS/DLT doc — **open** |
| `SESSION_HANDOFF_2026-08-12.md` | Previous session |
| `_archive/HOST_ONBOARDING_AND_CHATBOT_PLAN.md`, `DIDIT_WORKFLOW_SETUP_GUIDE.md` | Host onboarding + KYC background |
