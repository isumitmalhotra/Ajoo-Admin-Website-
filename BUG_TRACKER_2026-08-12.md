# Task tracker — client bug sheets + engineering backlog

**Created 2026-08-12.** Source: `_Web App Bugs.xlsx` (7 sheets) plus the
engineering backlog carried from `SESSION_HANDOFF_2026-08-12.md`.

Item text below is **verbatim from the workbook** — generated from it rather
than retyped, so nothing is reworded or lost. IDs are stable; cite them in
commits.

| Block | Source sheet | Items | Priority |
|---|---|---|---|
| **W** | `Aug 08-26` | 20 | 🔴 **NOW** — web/admin |
| **A** | `Aug 08-26  App` | 83 | 🔴 **NOW** — mobile |
| U | `User` | 63 | after W and A |
| H | `Host` | 5 | after W and A |
| C | `Common` | 21 | after W and A |
| — | `Post 25 release` | ~200 | already tracked as Section-0 in [`AAJOO_SECTION0_TASKLIST.md`](AAJOO_SECTION0_TASKLIST.md) — **separate SOW** |
| E | engineering backlog | 12 | interleaved |

**192 items in the five bug sheets.** Read §0 before planning: a large share of
block A is redesign work, not defects.

---

## 0. What this actually is — read before scheduling

The two priority sheets are not the same kind of work.

**`Aug 08-26` (W, 20 items) is a defect list.** Concrete, reproducible,
mostly small. Six of them are already root-caused below. This is the block to
clear first, and most of it is achievable quickly.

**`Aug 08-26  App` (A, 83 items) is mostly a redesign brief.** Items like
"change the loader", "add ringtone/bell tone", "Make it feel like LUX
experience", "show properties in the slider", "Change all the tabs as per the
current theme" are new design and build, not bug fixes. Perhaps 15 of the 83
are defects; the rest is a UI programme that **substantially overlaps the
Section-0 redo**, which `MASTER_PENDING_TASKS.md` §F records as *outside the
₹1,60,000 contract and needing a signed change order*.

That is not a reason to refuse it — it is a reason to price it before starting,
so the same work is not delivered twice under two names. **Flagging this for a
commercial decision.** The defects inside block A are being done regardless.

Blocks U (63) and C (21) are the same shape as A: mostly redesign.

---

## 1. 🔴 Block W — web/admin defects (`Aug 08-26`)

Investigated against the live database and the deployed code on 2026-08-12.
Where a cause is stated, it was verified, not guessed.

### Payouts

| ID | Item | Diagnosis | Status |
|---|---|---|---|
| **W-4** | Payout is not working — cannot pay a host | 🔴 **ROOT-CAUSED.** The client sends `PUT /admin/finance/payout/approve/{id}`; the server serves `PUT /admin/finance/payout/{id}/approve`. **The id and the verb are the wrong way round, so it 404s.** `rejectPayout` has the identical fault. `FINANCE_PAYOUT_APPROVE`/`_REJECT` in `services/endpoints.ts`. | **FIXED** |
| **W-5** | Invoice download not working | 🔴 **ROOT-CAUSED, two faults.** The backend PDF generator works fine (PDFKit, `downloadInvoice`). But (a) the button only renders `if (inv.pdf_url)` and `inv_pdf_url` is **NULL on all 10 live invoices** — nothing populates it — so the button never appears; and (b) `FINANCE_INVOICE_DOWNLOAD` is `/invoice/download`, the same inversion as W-4, and is referenced nowhere. The working endpoint has never been called. | **FIXED** |
| **W-1** | Host name not appearing on payout detail | ✅ **Confirmed.** `searchPayouts` returns raw `tbl_payouts` rows with no join, so `host_name` is absent and the UI falls back to `Host #100`. The host lookup exists and works in `getPayout` — verified against live data, returns "Aajoo Test Host". | **FIXED** |
| **W-3** | Period shows invalid data | ✅ **Confirmed against live data.** `po_period_start`/`po_period_end` are NULL on 6 of 8 payouts, and `initiatePayout` — the admin "pay this host" path — never sets them at all. | **FIXED** |
| **W-2** | Add a payout detail view (host, booking, user, host bank details) | **BUILT.** *(Correcting an earlier note: `tbl_host_acc_details` did exist — it lacked holder name, bank name and UPI, and had **zero rows** because the host form posted bank details to an endpoint that discarded them.)* Migration `20260811090000` applied to production; new `/admin/finance/payouts/:payoutId` screen; host profile now saves to the endpoint that stores it. Account numbers masked everywhere. Verified end-to-end against live data. | **FIXED** |
| **W-6** | Finance exports must show the period they cover | Exports opened straight onto column headers — nothing in the saved file said which filter produced it. Each now begins with report name, period and generation time. Verified against live data. | **FIXED** |

### User

| ID | Item | Diagnosis | Status |
|---|---|---|---|
| **W-7** | Active/Inactive toggle not working properly | 🔴 **ROOT-CAUSED.** `overrideStatus ?? status` — `null` means "no filter" here, but `??` treats it as "not supplied" and fell back to the *stale* `status`. Switching a filter ON worked; switching it OFF re-sent the filter already applied. | **FIXED** |
| **W-8** | Document number validation should depend on document type | 🔴 **ROOT-CAUSED.** The server validates format by type (Aadhaar 12 digits, DL `MH0123456789012`, Passport `A1234567`); the client had a bare `required()`, so anything passed the form and the server rejected it. Client now mirrors the server. | **FIXED** |
| **W-9** | Error messages should name the actual error | 🔴 **ROOT-CAUSED.** The 422 reply carries `message` as an **array** of field messages; the thunk passed the array through as a string and the modal read `.message` on it — undefined — so it always printed the generic fallback. New shared `apiErrorMessage()`, flattened at the thunk boundary. | **FIXED** |
| **W-10** | Sent a negotiation message to a host — where can it be read? | 🔴 **ROOT-CAUSED.** Nowhere — `tbl_nagotiate_messages` is written by the socket handler and read by nothing else; **no REST endpoint had ever existed**. Added `/admin/negotiations/messages`; each row opens its thread inline. Verified against the one real message on production. | **FIXED** |

### Host

| ID | Item | Diagnosis | Status |
|---|---|---|---|
| **W-12** | Add host form is not working | 🔴 **ROOT-CAUSED.** The server requires `cred_user_password` when there is no `userId` (8+ chars, letter+digit+symbol). The client's rule was **commented out**, so the form posted a blank password and the server 422'd — while W-9 hid the reason. *(The referenced screenshot is not actually embedded in this sheet — `drawing2.xml` has no image refs.)* | **FIXED** |
| **W-11** | Rename the form to "Add New Host" | The modal ignored its own `context` prop — adding a host opened a form headed "Add New User". | **FIXED** |
| **W-13** | Fix the "Update / Host-update" form title | Same cause as W-11. Also: the host branch showed **no success message at all**. | **FIXED** |

### Property

| ID | Item | Diagnosis | Status |
|---|---|---|---|
| **W-14** | Description points vanish after save and reload | 🔴 **ROOT-CAUSED.** Not a persistence bug — the submit handler **never sends `extra`**. Thirty-odd FormData entries, and the field the points live in is omitted, so the server wrote `undefined` every save. | **FIXED** |
| **W-15** | Same for property document image upload | 🔴 **ROOT-CAUSED, different cause.** Documents are **written to `tbl_attachments`** and **read from `tbl_property_documents`** — two tables. 7 live docs the form could never show; the 6 it did return were in a shape the mapper can't read. | **FIXED** |
| **W-16** | Pet-friendly / Smoking-free dropdowns unchanged after save | 🔴 Same cause as W-14 — `isPetFriendly` and `isSmoke` were never sent either, so both wrote 0 on every save. | **FIXED** |
| **W-17** | After deleting a host, the property still shows their name — clear it and mark the listing inactive | ✅ **"Mark inactive" was already done** in an earlier session. The name now carries a *deleted* badge. **`property_host_id` deliberately kept** — booking and finance history reaches the host through it, so nulling it orphans real records. Flagging rather than blanking; say if you want it nulled anyway. | **FIXED (partial by design)** |
| **W-18** | Logo does not appear in email | 🔴 **ROOT-CAUSED.** Templates pointed at `https://yourcompanylogo.com/logo.png` — a placeholder domain that has never resolved. A second used via.placeholder.com. Now the real logo, from `public/` so the URL has no build hash and survives deploys. | **FIXED** |

### Host dashboard · Login

| ID | Item | Diagnosis | Status |
|---|---|---|---|
| **W-19** | Host's full information (phone, city, address) missing from profile | The server has always returned *and accepted* `address`; the form simply had no field, so a host could neither see nor set it. | **FIXED** |
| **W-20** | Cannot log in as a user when the user is unverified | 🔴 **ROOT-CAUSED.** The login lookup required `user_isVerified = 1`, so an unverified account returned "No record found" — the same words as a non-existent one. Now sends a fresh code and returns `{needsVerification, userId}`; **no token issued**. Password is checked *before* any state is disclosed, so it can't be used as an account-existence oracle. Mobile parity: the branch existed but read the wrong key. | **FIXED** |

---

## 2. 🔴 Block A — mobile (`Aug 08-26  App`)

Full verbatim list in §5. Triage of the **defects** inside it, which are being
treated as block-W-equivalent priority:

| ID | Item | Note |
|---|---|---|
| A-8 | Phone number verification missing | Also web — matches S0-AUTH-1, needs an SMS provider (🔒 client) |
| A-9 | Google sign-in broken on the login page | Also reported on web as "Google sign button is not working — firebase connection" |
| A-11 | Account created without OTP, but returns an error | 🔴 **Security-adjacent.** An account that exists while the client is told it failed |
| A-15 | Forgot-password screen asks for 4 digits; the email sends 6 | 🔴 **Clean defect, fixable immediately** |
| A-20 | Shows Goa instead of the user's current location | |
| A-62 | Booking confirmation page missing; no email to either side | 🔴 Contradicts the backend, which does send booking mail — needs verifying end to end |
| A-66 | KYC loses the booking the user was part-way through | 🔴 Real user-facing data loss |
| A-77 | Host dashboard: total bookings not working | Same class as the admin tile bugs already fixed |
| A-78 | Host dashboard: ongoing stays / property buttons not working | |

**A-80..A-83 (KYC restructure)** — ✅ **DONE 2026-08-13.** It turned out to be
a small, surgical change rather than the re-plumbing this note feared: the
booking gate already existed and already blocked on both platforms, so the work
was only deciding *who* meets the check *when*. Hosts verify at signup; renters
verify at checkout. The one genuine surprise was that **web hosts had never
been verified at all** — see A-80.

---

## 3. Engineering backlog (block E)

Carried from `SESSION_HANDOFF_2026-08-12.md`. These are not in the client's
sheets but several block the sheet items.

| ID | Item | Status |
|---|---|---|
| **E-1** | 🔴 **Render environment is wrong and armed** — 5 `DB_*` incorrect, 4 vars missing, `OTP_DEV_BYPASS` still `true`. Blocks the secrets cutover. [`RENDER_ENV_CHECKLIST.md`](RENDER_ENV_CHECKLIST.md) | **Blocked on client** |
| **E-2** | Rotate every credential in git history | After E-1 |
| **E-3** | ~4,260 junk city labels; needs a licensed geocoder | Deferred on cost |
| **E-4** | Refund decision on BPTEST04 (₹9,440) | Awaiting decision |
| **E-5** | Prebooking needs a backend `advanceAmount` | Awaiting decision |
| **E-6** | Host portal at 29k listings — **unverified in a browser** | Needs a signed-in pass |
| **E-7** | Auth fix from 2026-08-11 — unverified in a browser | Needs a signed-in pass |
| **E-8** | Mobile not swept for stock photos / errors-as-empty-states | Open |
| **E-9** | `/admin/properties/form` and `/admin/status` still on the old shell | Open |
| **E-10** | No admin notifications endpoint — the bell has no count | Open |
| **E-11** | Monorepo holds **stale copies** of the backend and frontend; editing them ships nothing | Open |
| **E-12** | Contract deliverables B-2…B-9 (Swagger, architecture, FMS/HMS specs, RBAC matrix, test suite >80%, runbook, UAT) | Not started |
| **E-13** | 🔴 **Safety copy claimed features that do not exist** — an in-app emergency button "connecting to local authorities", Aajoo host insurance, opt-in user protection programs, a report-suspicious-behaviour flow, and "every host rigorously verified". Live in the app until 2026-08-13; removed from both platforms rather than published to the new web page. **Decide per claim: build the feature, or leave it out.** The report flow and an SOS path are the two worth costing — everything else was marketing. Restoring a claim is a CMS edit, no deploy. | **Needs a product decision** |
| **E-14** | Backend deploy pending: `PAGES` whitelist now includes `safety` (commit `16307f8`). Until Render redeploys, `public/cms/safety` 404s and both platforms render shipped defaults — correct, but not yet editable from admin. | Ready to deploy |

---

## 4. Working rule for every item here

**Web and app get fixed in the same pass**, per the standing parity rule in
[`WEB_MOBILE_PARITY.md`](WEB_MOBILE_PARITY.md). An item that exists on both
platforms is not done when one side ships.

---

## 5. Full verbatim item list


### Sheet: `Aug 08-26`


**Admin Dashboard**


**Payouts**

- [ ] **W-1** Host name is not appearing in payout detail page
- [ ] **W-2** add a option to see detail of payout like host detail, booking detail, user detail , host bank detail of host etc,
- [ ] **W-3** period show invalid data
- [ ] **W-4** Payout is not working (if i try to pay to the host its not working please fix the then need to be restest as its payment related critical thing it should not hold any error and operation should be smooth
- [ ] **W-5** In Invoice section, Download invoice is not working (due to this we are nto able to see the format and other info of invoice
- [ ] **W-6** all exported report related to finance, should show the period on top of export file to show for which period this report belong to (eg. i generated cashflow report and its name say 08-08-2026 but i applied the filter for different report)

**User**

- [ ] **W-7** Actice/Inactive on off button is not working properly
- [ ] **W-8** Document number validation is not working as expected it should be based on document type
- [ ] **W-9** error message should be belong to error like i did not upload the image so its show failed to add user, if its say image is required its look more user friendly
- [ ] **W-10** i send a negtiation message to host, where can i check the message

**HOST**

- [ ] **W-11** Chage the name of for to add New Host
- [ ] **W-12** Add host form is not working see SS (Screenshot 2026-08-08 230857.png)
- [ ] **W-13** Update, Host-update form title

**PROPERTY**

- [ ] **W-14** Description points are not comming after saving the form, if you leave the page and come back the Description Points disapear
- [ ] **W-15** Same problem with property document image upload
- [ ] **W-16** Pet friendly and Smoking free dropdown remain unchanged after save
- [ ] **W-17** After deleting Host, property still show the host name, please also delete the host from that property and mark status as inactive
- [ ] **W-18** Logo is not show up on email

**Host Dashboard (different from Admin Dashboard)**


**Settings**

- [ ] **W-19** Host full information is not pop up on profile like phone number, city, address

**Login**

- [ ] **W-20** i am not able to LOGIN as user when user is not verified


### Sheet: `Aug 08-26  App`


**Findings**


**When open app**

- [ ] **A-1** change the loader
- [ ] **A-2** add ringtone/bell tone provided by us / sharing on whatsapp
- [ ] **A-3** Change the logo from the app icon / inside and outside the app
- [ ] **A-4** Landing Page add slide instead of single image

**Sign up**

- [ ] **A-5** Phone number verification missing
- [~] **A-6** Fix the google sign in the login page — *⚠️ NO DEFECT FOUND. Package name, BOTH keystore SHA-1s, serverClientId and the backend all verified correct 2026-08-11. Errors are now named instead of showing raw PlatformException codes. Most likely remaining cause: a **Play Store build**, whose App Signing SHA-1 must be added to Firebase separately.*
- [x] **A-7** ✅ signup with google is missing when new account create — *I was wrong to call this blocked. `/user/auth/google` already CREATES the account and marks it verified; the button was just not rendered on the sign-up tab. Now on both, labelled "Sign up with Google". Web already had it on both.*
- [x] **A-8** ✅ account generated without OTP but gave an error — *🔴 REAL CAUSE (found 2026-08-11): the **Google** path. "Without OTP" was the tell. googleSignIn created the user AND sent the welcome email BEFORE running its account gates, so a later refusal left an account that existed, an email that had landed, and an error on screen. Email now sent after every gate, only on genuine creation.*
- [x] **A-9** ✅ signup not done but I received the "account created / complete the profile" email — *same cause as A-8: welcome email fired before the gates. Fixed together.*

**Forget**

- [x] **A-10** ✅ Forgot password shows 4 digits, email sends 6 — *🔴 ROOT CAUSE. Server raised generateOtp to 6 digits; app never updated. Four call sites had `length: 4` + validation demanding exactly 4. Signup verification was broken the same way.*
- [~] **A-11** 🟡 Phone No forgot Password — *BUILT. The platform had **no SMS capability at all**, so this was absent rather than broken. New provider-agnostic `sms.service` (msg91/twilio/fast2sms) + `POST /user/forget-password/sms`, sharing the same OTP row, expiry and lockout as email. App accepts a phone number too. **Needs `SMS_PROVIDER` + credentials to actually send** — until then it says so honestly and points at email.*
- [x] **A-12** ✅ Fix all the Forgot System — *🔴 Audit found the reset OTP was WEAKER than the signup OTP, which is backwards since it grants a password change: **no expiry, unlimited guesses**. Both now enforced from the same constants. Also: `sendEmail` was never awaited so the failure branch could never fire (it reported success on bounced mail); an unknown address answered "No record found" (membership oracle); no deleted-account filter.*

**Renter**

- [x] **A-13** ✅ Show Properties in maps as per current location — *🔴 The map's fallback camera was `LatLng(37.427961, -122.085749)` — **Mountain View, California**, the emulator default — while properties were fetched around the controller's coordinates, so map and pins could differ by 12,000 km. Also found: declining location **returned early so no properties were fetched at all**, and `getCurrentPosition()` was neither time-boxed nor caught, hanging the loader forever. All three fixed. The booking-detail map was centred on California too — `_moveCameraToProperty()` had been deleted with its call sites left commented out.*
- [x] **A-14** ✅ Show Current Location instead of Goa — *search pill hardcoded to "Goa" while listings were already fetched around real coordinates. Now resolved via the platform geocoder; "Nearby" until it answers.*
- [x] **A-15** ✅ Add notification icon on the top right instead of profile icon — *was a person icon, tooltipped "Profile", on a callback named onProfileTap, that opened NotificationsScreen.*

**This week tab**

- [x] **A-16** ✅ Show current real data in the tab — *card rendered hardcoded "1,240 verified homes"; now the real nearby count and place.*
- [x] **A-17** ✅ 18 new property also in real time — *"18 new in Goa this week" was a hardcoded default. Nothing reports it, so it is removed rather than guessed.*
- [x] **A-18** ✅ remove the relocator button — *a standalone 50×50 `my_location` button sat mid-feed whose only job was to re-run the property fetch. That is what pull-to-refresh and the map's own controls do.*

**Browser by cat.**

- [x] **A-19** ✅ one category row, not two — *🔴 The two rows were NOT duplicates: the top was a **hardcoded** list (incl. 'Beach'/'Hills', which aren't categories) that **filtered nothing**; the bottom had the real API categories and did the work. Top row now takes the API list and filters; bottom deleted along with its helpers and a parallel `_selectedHotelIndex`.*
- [x] **A-20** ✅ Fix all the cat. icons — *there were **two icon maps** that disagreed (cottage→cabin vs cottage; boutique→hotel vs storefront), so one category drew two different icons on one screen. Consolidated to one, ordered so the nine real categories match before looser keywords. **Note:** three icons will still look wrong until `Resort`/`couple`/`party` are purged — that is A-52, a data fix.*
- [ ] **A-21** Fix the Pre Booking & Lux Buttoon Below the Browse by Cat.

**Properties in your current locations**

- [ ] **A-22** show Properties in the slider and gave the see all button top right / Show 10-12 properties
- [ ] **A-23** Then show Curated For you
- [ ] **A-24** show Properties in the slider and gave the see all button top right / Show 10-12 properties
- [x] **A-25** Show Blogs 4-5 and top right add see all and go to blog page — **blog list + post screens built on app AND web (`/blog`, `/blog/:id`); "See all" and cards now go somewhere**
- [x] **A-26** Show the FAQ and end the page. — **`HomeFaqStrip` at the foot of the home screen, "See all" → /faq**

**Property Detail page**

- [x] **A-27** Property namse show the verified badage — **beside the name, driven by `verification_status`, not the meaningless `is_verify`**
- [x] **A-28** in the app show all the properties deteilas like website — **+ map and policies, which the app never had**
- [x] **A-29** About /aminities / hose rule / location/ reviews/ host/ ploices in diffrent tables like webiste
- [x] **A-30** do not show all of the above in long page add these of above in listing like: — **real tab panels on both platforms; the web ones were jump links**
- [x] **A-31** if user clkick on the about shoe property dicption only, if user click on amanties shows aminties only and show on
- [x] **A-32** Instead of reviews mention customer/user experinces — **"Guest experiences"**
- [x] **A-33** Then show gallary into
- [x] **A-34** show near by attaraction places — **from `property_nearby_places`; admin can now enter them (Admin → Properties → Nearby)**
- [x] **A-35** Show distance from / near airport/ near hospital/ near park/ bus stand — **same source; sub-km shows in metres. Added Park and Beach to the vocabulary**
- [x] **A-36** show property blog pages — **blog strip on the property page, links to the blog**

### Reserve sheet (Aug 08-26 App, batch of 2026-08-12) — mobile only; the web rail already did all of this
- [x] **A-37** Booking shows Daily/Weekly/Monthly → **"Per night" / "Monthly"; Weekly removed**
- [x] **A-38** Check-in/out is fixed by the host, remove the edit icon → **chevron gone; reads "set by the host"**
- [x] **A-39** Below the Total Price show no price → **"Weekly Min/Max Price" removed. That is the host's negotiating band; a guest could see the least the host would accept, right under what they were being asked to pay**
- [x] **A-40** Selecting Monthly must not change the price → **it multiplied the stay by 30. A one-night stay picked as Monthly quoted ₹96,000 for ₹3,200 of accommodation. The stay type is a label now; dates × the host's rate set the price**
- [x] **A-41** Min/Ideal/Max/monthly/weekly are host-side only → **none of them reach the guest; the guest sees the price for their own dates**
- [x] **A-42** "Reserve" → **"Negotiate & Reserve"** (and "Offer Your Price" → "Negotiate")
- [x] **A-43** Negotiate button shows a loader that never clears → **`loadNegotiationChat` set `isLoading` and only a chat-history socket event cleared it, which never arrives on a first-time negotiation. Fixed + 12s watchdog**
- [x] **A-44** *(found while fixing A-40)* **Hand-picked dates billed one night too many** — `.inDays + 1`, while the negotiated-deal path in the same file and the whole website used the plain difference. Same dates cost more if you picked them yourself than if you arrived from an accepted offer. Scanned the 24 live bookings: the only match is the synthetic BPTEST03 seed row, so no real guest paid it.

### KYC & booking confirmation (Aug 08-26 App, batch of 2026-08-12) — app only; the web already had all of this
- [x] **A-45** After KYC the guest didn't get back to their booking → **DIDIT runs in the system browser and Android may destroy the app while they're in it, so Flutter restarts with an empty stack. The booking intent is now saved to disk before handing over, and a "Finish your booking" banner on the home screen reopens that property with the same dates. Both gates: the reserve sheet and accept-offer.**
- [x] **A-46** New user wrongly shown the one-Pay-on-Arrival limit → **not a policy problem. The app decided what counted as an "active" booking by comparing the status TITLE to "Cancelled" and "Completed" — and there is no Completed status (the real titles are Payment Pending, Cancelled, Paid, Booked, `Check In `, `Check Out ` with trailing spaces, Booking Confirmed, Payment Received, Running). So it excluded one status and counted everything else forever, including abandoned card checkouts, which the app creates *before* opening Razorpay. Verified on production: user 101 had 4 "active" bookings, all 4 abandoned pending rows, one flagged COD — that user was locked out of booking entirely and saw both the max-3 wall and the POA message with no real bookings at all. Now keyed on status ids, matching the backend guard including its 30-minute hold. The POA message now only appears when the guest genuinely has one active pay-on-arrival booking and starts a second, which is what was asked for.**
- [x] **A-47** Confirmation emails to guest and host → **`sendBookingNotifications` had one caller, inside `if (isCod)`. Every online-paid booking completed silently: no guest confirmation, no invoice, and the host got only a push. Added at payment verification, plus a host email — no host had ever received one. (Emails live in `tbl_user_creds.cred_user_email`; `tbl_users` has no email column.)**
- [x] **A-48** Booking confirmed page missing on real-time booking → **it was a dialog needing the property page's BuildContext still mounted when Razorpay handed back, which is why it could fail to appear on a card payment. Now a route.**
- [x] **A-49** Confirmed page: Get Directions icon + map in the app → **new `BookingConfirmedScreen` with stay dates, amount, paid-vs-due, and an in-app map with Get Directions. Coordinates now come from the detail payload — the widget's string params are empty on some callers, which is how Get Directions launched Maps at 0,0.**
- [x] **A-50** Ongoing page missing the map → **same `StayMap` widget inline. It had a button that made a second request just to fetch coordinates and then threw the guest out to Google Maps; the coordinates were in the payload all along and the model was discarding them.**

### LUX mode & Pre-booking (Aug 08-26 App, batch of 2026-08-12) — app only
- [x] **A-51** LUX needs its own colours, icons and animations → **`lux_theme.dart`: near-black + gold against standard's Warm Ivory + teal, gold section rules, filled-icon swap, slower motion curve, gold-edged cards. Kept off the global `k*` tokens on purpose — ~88 files read those.**
- [x] **A-52** A loader that shows LUX → **gold LUX wordmark under a sweeping arc with a sheen crossing the letters; replaces the grey shimmer whenever LUX is on.**
- [x] **A-53** LUX page felt identical to standard → **the switch dialog is now dressed for the direction of travel, and entering LUX holds the LUX loader over the screen until the luxury listings land, so it never flashes the standard page mid-switch. Both screens used a bare Material AlertDialog before.**
- [x] **A-54** Pre-booking: current location editable, like home → **was a FutureBuilder that reverse-geocoded on every rebuild and could not be changed. Now the home screen's pill + destination search.**
- [x] **A-55** Browse by category → homestays/villas, drop single/couple → **real property types from the API, same source as home. Was five hardcoded tiles (Family/Sharing/Couple/Party/Single) whose filter matched category titles three of them didn't correspond to. `couple`/`party`/`Resort` hidden from browse on BOTH screens via one shared set — hidden, not deleted: 10 live properties are tagged with them.**
- [x] **A-56** LUX button top right with the search → **the home screen's animated toggle. Was a hand-rolled pill on `theme.primaryColor` using an asset literally named `diamond .png`.**
- [x] **A-57/A-58** Area sliders, 10–12 properties each → **Shimla, Kufri, Mohali, Panchkula, Kharar, Chandigarh; loaded in parallel. Filtered on `area` (address) not `city` — exact city match returns 1 for Mohali and 0 for Chandigarh, vs 48 and 51 by address. Verified on production: five rails return a full twelve. ⚠️ **Kufri has no listings on the platform**, so its rail hides itself until it does.**
- [x] **A-59** Check-in / check-out on pre-booking → **there was no date input at all. Dates carry into the property page via its existing dealFrom/dealTo input, so the stay is priced on arrival.**

> ⚠️ **Id drift, resolved 2026-08-13.** The batch sections above renumbered as
> they went and ran up to +2 ahead of this list from the KYC group onward, so
> the same item had two ids. **This verbatim list is the id of record** — it is
> what the client's sheet says and what they quote back. Each item below now
> carries the batch id it shipped under, in brackets.

**Reserve Page**

- [x] **A-37** *(shipped as batch A-37)* View Details: Booking shows Daily weekly monthly/// Mention instead of daily, pernight and monthly remove weekly
- [x] **A-38** *(batch A-38)* Check in- out time is fixed by host remove the edit icon only/ its fixed already
- [x] **A-39** *(batch A-39)* Below the Total Price don't show any price nothing
- [x] **A-40** *(batch A-40)* if user select the monthly do not chnage the price below, price change according to the dates and set by host
- [x] **A-41** *(batch A-41)* Price various on the Minmun price, Ideal price, Maximun Price/ monthly Price / weekly price only for host not for user show accordngy of user booking stay for 7 days
- [x] **A-42** *(batch A-42)* instead of reserve show the negotiate & Reserve
- [x] **A-43** *(batch A-43)* Then shows the Book now and negotiate button Fix the negoatition buttion do n't show loader of negoation

**KYC**

- [x] **A-44** *(batch A-45)* When I click on book now or Negotiate Asking for KYC I Have done with the KYC from the app i didn't get my previous page where i left my booking before booked a property
- [x] **A-45** *(batch A-46)* When I'm a new user why it shows one time POA Beacuse I'm only booked i property, if user book more than 1 property then at that time show the POA policy
- [x] **A-46** *(batch A-47)* When i'm done with the booking , booking confrim page in missing in real time booking and send email once the booking is done for both the ends user and host
- [x] **A-47** *(batch A-48/A-49)* Booking confrimed page is missing show the get direction icon and the maps inside the app as per the refrence image
- [x] **A-48** *(batch A-50)* When i done with the booking ongooing page missing on the maps

**LUX Mode**

- [x] **A-49** *(batch A-51/A-52)* Lux Mode Make some diffrence in colors and icons and animations some diffrenteant from the standrad / fix a loader like it show lux
- [x] **A-50** *(batch A-53)* LUX Page same as the standard PAge only/ make it feel like LUX experince

**Prebooking : Page** — *all seven shipped in app commit `05696a3`; re-verified in code 2026-08-13 (see the file/line receipts in `SESSION_HANDOFF_2026-08-13.md` §3 batch 4).*

- [x] **A-51** *(batch A-54)* Current location is editable and show same like fic the home page and Browse by category. — **`showSearchSheet` on the location pill; was a `FutureBuilder` that re-geocoded every rebuild and could not be changed**
- [x] **A-52** *(batch A-55)* Chnage the Browser by catgeory into homestay villas remove single couple etc — **real API property types via `TextCategoryPills`; `couple`/`party`/`single`/`sharing`/`resort` hidden through the shared `kHiddenBrowseCategories`**
- [x] **A-53** *(batch A-56)* Fix the LUX button Top Right with the search that chnage of mode from there — **the home screen's animated `LuxToggleButton`, top right beside the search**
- [x] **A-54** *(batch A-57)* In the prebooking show the properties in slider by areas — **`AreaRail`, one per area, each loading independently**
- [x] **A-55** *(batch A-57)* Shimla/ Kufri / Mohali, panchkula/ mohali/ Kharar — **`kPreBookingAreas` = Shimla, Kufri, Mohali, Panchkula, Kharar, Chandigarh. ⚠️ Kufri has no listings, so its rail hides itself until it does**
- [x] **A-56** *(batch A-58)* show all the areas types in the slider and show 10-12 properties in slide — **`perArea: 12`; filtered on `area` (address LIKE) not `city`, which returns 1 for Mohali and 0 for Chandigarh**
- [x] **A-57** *(batch A-59)* in the prebooking gave the check in check out dates select to the user — **`StayDatesBar`, carried into the property page as `dealFrom`/`dealTo` so the stay is priced on arrival**

**My booking Page**

- [x] **A-58** Chnage the all the tabs as per the current theme — **app only; the web has no tabbed bookings page (separate `/account/upcoming` and `/account/past-stays` routes). The header was a solid `kIndigo` slab with white-on-teal tabs, the pre-redesign skin. Now Warm Ivory + ink text with a short teal rule under the selected label — the same treatment as `PropertyTabBar`, so the app's two tab rows read as one idea. Tabs distribute evenly instead of bunching left. Bucketing logic untouched.**
- [x] **A-59** Upcoming stay / Ongoing page / Completed / Cancelled — **already correct; no change needed. The four tabs existed and `_bucket()` reads the stay DATES, not just the status title, which matters because a paid stay keeps the status "Paid" for its whole life — bucketing on the title alone left finished stays under Upcoming forever.**
- [x] **A-60** User click on the view on the details page — **works: "View Details" on each card opens the booking with its own `bookPropId`. Verified, not changed.**
- [x] **A-61** Show the support button and host chat button and host details below the booking if TAB but not in the cancelled Show there book now button only do not show the Host details — **Support + "Chat with host" + a host card under the booking. Host chat opens the existing negotiation thread for that property. On a Cancelled booking: no host card, no chat, no host phone number, the Host tab is removed from the panels below, and the bottom bar becomes a single "Book now". ⚠️ Support is kept on Cancelled — a refund is a support question, and that is when a guest most needs it. Say the word if you want it gone there too.**
- [x] **A-62** Show the all property page below all of the above mentioned — **the same seven tab panels the property page uses. Extracted from ~240 lines of private methods on `_PropertyPageState` into a shared `PropertyDetailPanels`; both screens now render one implementation, so the "empty means hidden, never zero" rules cannot drift between them.**
- [x] **A-63** Show property photos instead of maps — **swipeable gallery with counter and dots. The map is not lost: it is still under the Location tab below, and the confirmed and ongoing screens still lead with it (that was asked for last batch). No photos means no gallery, not a stock photo of somewhere they did not stay.**

**Menu**

- [x] **A-64** Remove right side menu and fix this menu below the profile page where all pages exits — **`CustomDrawer` deleted. Its entries (Dashboard, Bookmarks, Safety, Settings, About) joined the profile screen's list, which already had Edit Profile / History / Notifications / Support / Logout. 🔴 The drawer had no menu button: it opened by tapping the unlabelled aajoohomes logo, so those five pages were reachable only by guessing. The logo is branding now.**
- [x] **A-65** Safety, about us pages same as the website — **DONE, both. Safety resolved by building the missing web page: `/safety`, in the footer under Support, CMS-editable, and the app reads the same `public/cms/safety` over the same defaults. Backend `PAGES` whitelist extended (needs a Render deploy; until then the CMS 404s and both platforms render the shipped defaults, which is correct). 🔴 The old safety copy was NOT carried over — it claimed an in-app emergency button "that connects them to local authorities", Aajoo host insurance, user protection programs, a reporting flow, and that every host is rigorously verified. None exist: there is no report endpoint at all, `pcp_insurance` is a host's own checkbox, and 10 of 29,232 listings are verified. Those claims were already live in the app and are now gone from both. See §6.** — *original note follows:* **About: DONE and properly. The app was rendering `common/about-us`, an older copy deck the website no longer uses — the site says "More Than a Stay. A Place to Belong." with Our Story / Vision / Mission / 5 values / 6 differentiators, the app still said "AAJOO – AAJAO AAJOO MEIN" and "Walking Distance Optimization". The app now reads the same CMS page the website reads (`public/cms/about`) over the same spec defaults, so they match today and an admin edit lands on both. ⚠️ Safety: NOT possible as asked — **the website has no Safety page** (only `/about` and `/state-regulation`; there is no `safety` key in the web CMS schema). The app page was brought onto the current theme and its re-fetch-on-every-rebuild bug fixed, but its content still comes from `common/safety`. **Needs a decision: build the web Safety page, or treat the app's as the source of truth.**

**Prolie Page**

- [x] **A-66** When USer want to Update the documents do KYC again FIX Diddit — **🔴 ROOT CAUSE FOUND, and it was server-side. `createSession` calls `shouldSkipVerification()`, a 90-day skip that exists so a renter who verified at signup is not re-asked at checkout. It has no opt-out, so a verified user asking to redo their KYC got back `sessionUrl: null` — and the app reads a missing URL as "DIDIT is not configured" and showed **"Identity verification is temporarily unavailable"**. Re-verification was impossible, and the message blamed an outage that was not happening. Now: `force` on the request skips the skip (declared in the yup schema — verified it survives `stripUnknown`, the trap that killed `bookingType`); the app tells "already verified" apart from "stub/unavailable" instead of collapsing both into a null URL; and **Profile → Update documents runs DIDIT** rather than the old manual upload sheet, then refreshes so the badge reflects the new decision. The 381-line manual sheet it replaced is deleted. Also fixed: the green **"Verified"** chip was shown to anyone who had uploaded a file — uploading is not verifying, the same mistake as the `is_verify` listing badge. It reads the DIDIT decision now and says "Under review" until there is one.**
- [x] **A-67** give location to auto fill the current location / or by Zip easy for user reduce time to fill the info. — **Two buttons above the address fields: "Use my location" (GPS → reverse geocode → address, city, PIN) and "Fill from PIN" (PIN → city). Shared helper `lib/utils/address_autofill.dart` rather than a fourth copy of the reverse-geocode block. Uses the platform geocoder already in the app — no new service, no API key, nothing to bill. Time-boxed at 12s with a last-known-position fallback and named errors (permission denied / blocked / not found), because `getCurrentPosition` hangs indoors and fails outright with GPS off — unguarded, that is what left the map screen's loader up forever. **A PIN deliberately does not fill the street**: it covers a whole area, so guessing an address into the user's own address field is worse than leaving it. PIN lookups are scoped to India — a bare 6-digit string matches postcodes in several countries.**

**Host**


**My booking page**

- [x] **A-68** Upcoming/ ongoing/Completed/ Cancelled in these of when User click on the view details tabs (Same as user where gave the property details and Support button and all ) — **The four tabs already existed and already bucketed on dates (verified). What was missing was the way in: the card was the end of the road. New `HostBookingDetailPage` behind a "View Details" button, with the same seven property panels the guest sees, from the same `PropertyDetailPanels`. Screen also brought onto the current theme, matching the guest's Bookings.**
- [x] **A-69** In this gave the user details and Support and User chat button below that show the property details ( ongoing page like user side) — **🔴 This needed a BACKEND fix first. `/host/booking-history` selected six booking columns and returned **neither `book_prop_id` nor `book_user_id`** — so there was no property to show and no guest to message; the host's own list could not answer "what was booked". (The renter's list has carried `book_prop_id` all along.) Query widened to include both ids, totals, guest count and a `bookingProperty` join — with `required: false`, or an INNER JOIN would drop every booking whose listing has since been removed. **Verified against production before building on it**: returns prop_id, user_id, guest and property name for real rows. Detail page now shows guest details, Support, "Chat with guest" (the same negotiation thread, from the host's side), then the full property below. Cancelled hides the guest block, mirroring the guest side.**

**Dashboard**

- [x] **A-70** Instaed of Transacation show negaoation tab where user can find all the negioataion — **🔵 `GET /host/negotiations/list` has existed since negotiation shipped and **nothing in the app ever called it** — a host's only sight of an offer was its push notification, so a missed notification meant a missed offer. Now: Negotiations section on the dashboard (3 shown, pending first) and a full `HostNegotiationsScreen` with "Awaiting you" / "All". Cards lead with the offer, what was being asked, how far below, and the requested dates. Production has 13 offers across 2 hosts, 7 pending.**
- [x] **A-71** Show 4-5 trancation only below show the FAQ — **transactions capped at 5 with a "View all" into Payouts, and the guest home's `HomeFaqStrip` closes the page.**
- [x] **A-72** ✅ total booking + weekly/monthly graph — *count loads fine; the tile was inert (A-73). New BookingsTrendCard built from booking history already loaded — no new endpoint.*
- [x] **A-73** ✅ ongoing stays / property / buttons not working — *all four dashboard tiles were plain Containers with no tap handler. Each now opens the screen it describes.*
- [~] **A-74** Check more nesscary points that we can show in the host dashboard — **Done one, proposed the rest. The 4th stat tile counted *Transactions* — a number a host can neither act on nor change, sitting directly above the transaction list that shows them anyway. It is now **"Offers to review"**, the only number on the dashboard with a decision attached. Further candidates, all computable from data the screen already loads (no new endpoint): **check-ins in the next 7 days**, **nights booked this month vs last**, **average nightly rate achieved after negotiation vs asking**, **listings that are unverified or inactive** (a host cannot currently see that a listing is invisible to guests), and **reviews awaiting a reply**. Awaiting the client's pick rather than piling all five on.**
- [x] **A-75** Support //// Messeages insetad of the support — **tab renamed and rebuilt as `HostMessagesScreen`. Support was the entire tab: a phone number, an email and an FAQ.**
- [x] **A-76** In the messeage show the aajoo support button on top and other user cionverstaion below — **Aajoo Support pinned at the top (a host in trouble should not scroll past their guests to find us), guest conversations below. The conversations ARE the negotiation threads — `/host/negotiations/list` already returns one row per property/guest pair, which is exactly a conversation list, so no second messaging system and nothing new on the server. Pending threads are flagged "Awaiting you"; tapping opens the same chat the guest sees.**
- [~] **A-77** List your property page as per the Website fixed in the app, Then we have gave the final look for the Property form as per SEO we have to add the Property Form — **🔴 NOT STARTED — deliberately, and it is bigger than it looks. The two platforms are on different backends. The app's wizard (6 steps: Property Type / Location / Photos / Pricing / Preferences / Publish, 1,409 lines) posts once to the legacy monolithic `POST properties/add`. The website's (5 steps: Property Foundation / Property Details / Amenities & Location / Pricing & Booking / Verify & Publish, 1,234 lines) is schema-driven off the **Listing Engine**: `GET /listing/schema` then `/listing/step1..step5`, `/listing/media/upload|patch|delete`, `/listing/draft/:id`, `/listing/readiness/:id`, `/listing/submit` — ~15 endpoints writing ~24 modular tables. Matching the website means porting the app onto that, not restyling the existing form. **Verified the engine is live on production**: `/listing/schema` returns 200 with 29 top-level groups, including per-category flows (11), conditional visibility rules, photo/pricing/booking rule sets and 10 house-rule toggles — so the port is viable, it is just a feature-sized piece of work (schema-driven field rendering, conditional visibility, draft resume, a new media pipeline). **Also blocked on an input:** "we have gave the final look for the Property form as per SEO" refers to a design that has not been shared. Needs the design + a decision on whether to schedule the port.**

**Menu**

- [x] **A-78** All the menu pages show in the Host Profile page — **every host destination now lists on the profile. These lived only in the home drawer, which opens from the Dashboard tab's header — so a host sitting on Profile could not reach Payouts, Bank Account, Terms, Privacy or Logout at all. Declared once in `host_menu.dart` and rendered by both the profile and the drawer, so they cannot drift the way the guest drawer and guest profile did.**
- [x] **A-79** In the host profile gave the menu on the top of the right side — **menu button top-right of the host profile, opening the same list as a right-hand `endDrawer`. ⚠️ Note this is the opposite of A-64, where the client asked for the guest's right-side drawer to be *removed*; here they asked for one on the host profile. Implemented as asked — say the word if the inline list alone is enough and the drawer should go.**

**Host KYC Break down**

- [x] **A-80** Host KYC done at the point of the Signup (IT WILL REDUCE THE TIME OF THE HOST WHEN HE LISTING THE PROPERTY INTO THE PLATFORM ) — **App: already true, hosts got `host_kyc` straight after OTP; unchanged. 🔴 Web: it was the exact opposite, and worse than expected. Hosts were sent straight to the dashboard with a comment saying they "verify identity inside the property-listing wizard" — **they do not**. The wizard's step-5 "Identity verification" is a manual form (document type, number, and a file-URL box whose placeholder reads "Upload arrives with the media step"). It never calls DIDIT. So **no web host has ever been through identity verification anywhere on the platform.** Web hosts now run DIDIT at signup, same as the app.**
- [x] **A-81** Only left with the Property Listing — **follows from A-80: with identity verified at signup on both platforms, the listing wizard is the only thing between a host and a live property. Nothing gates the wizard on identity, so it no longer front-loads a check onto the longest form on the platform at the moment a host is trying to publish.**

**USER KYC**

- [x] **A-82** User can Login and Register without KYC (IT WILL REDUCE TIME TO USER EXPLORE THE APP AND THE PROPERTIES NEAR BY.) — **The identity step is off the renter signup path on both platforms. App: after OTP a renter lands on `/home` instead of `/kyc`. Web: straight to `/user-dashboard`. It was skippable before, but a full-screen "Verify your identity" between OTP and the app reads as required — and it asked someone to prove who they are before they had seen a single property. The renter profile keeps a "Verify your identity" row so it can still be done ahead of time; that row now runs DIDIT rather than the legacy manual upload, which produced a document nothing ever verified. The 341-line manual sheet is deleted.**
- [x] **A-83** At the time before booking user can be do KYC before Booking — **already true and verified rather than assumed. App: the reserve sheet and the accept-offer path both run the gate (`property_page.dart`, `negotitaion_page.dart`) and block when unverified. Web: `UserCheckoutPage` disables the pay button on `kycRequired && !kycApproved`. The backend's 90-day skip means a renter who verified earlier is not re-asked. Also confirmed the web's `VerifyButton` already handled the already-verified/null-session case correctly — that was the A-66 bug the app had alone, so the app now matches the web.**


### Sheet: `User`

- [ ] **U-1** Status
- [ ] **U-2** Dditt KYC
- [ ] **U-3** Loader On app Opening ( Castle Image is appearing )
- [ ] **U-4** Change Price button chip on map in Homepage
- [ ] **U-5** Change Map Desgin acc to current app trend
- [ ] **U-6** Fix City and State Id Management in DB
- [ ] **U-7** Break Down Sign up Process
- [ ] **U-8** Swap cat. and find your stay section, fix category on top on home page  _ss_
- [ ] **U-9** Re design the property cart on homepage (optmize)also add neccesary info in cart/ tags cat
- [ ] **U-10** Change catergory icon, Name also in admin  _Cat. Listing_
- [ ] **U-11** Change Filter according to current trend remove weekly and montly filter (re-design)
- [ ] **U-12** Fix re-center button on map
- [ ] **U-13** Check notificaation all across Platform
- [ ] **U-14** whishlist
- [ ] **U-15** Re desgin nav bar, add Hii messeage with user Name
- [ ] **U-16** Use relatable SVG , illustrations
- [ ] **U-17** Side Bar
- [ ] **U-18** Fix social Media Section In bottom according to every device ( SS in Device)
- [ ] **U-19** Change icon
- [ ] **U-20** In top section show users profile details, Like Number Host/user edit icon
- [ ] **U-21** Dicussion on sidebar listing
- [ ] **U-22** help & support contact Dicussion
- [ ] **U-23** Social Media Icon issue in help and support page

**About US**

- [ ] **U-24** Re desgin about US page

**Settings**

- [ ] **U-25** Remove about us
- [ ] **U-26** Add Changes According
- [ ] **U-27** Fix rate app Button

**Common Issues**

- [ ] **U-28** improve document uploading system
- [ ] **U-29** Specifiy image should be in landscape or make in land scape

**Properties Details**

- [ ] **U-30** Set the font and icon, Button size (its too Big)
- [ ] **U-31** When Scroll Up catergortyy and rating section disappear
- [ ] **U-32** replace the save button with whish list icon
- [ ] **U-33** Make gallary on little top when click on the image image should be open
- [ ] **U-34** add attarction points
- [ ] **U-35** Add cancallation policy button
- [ ] **U-36** Fix the bottom price section , Its overlapping with mobile back button screen

**Booking Detail Page**

- [ ] **U-37** dicussion on booking change

**Sockets**

- [ ] **U-38** Change loader display when click on offer your price

**Razor Pay**

- [ ] **U-39** As per current market

**On going**

- [ ] **U-40** On going page
- [ ] **U-41** Only one, current ongoing booking should be applicable for pay on arrival, when on pay on arrival booking is active otrher bookings should not be applicable for pay on arrival
- [ ] **U-42** if user want to choose multiple POA ask user to swtich on Subscprtion model
- [ ] **U-43** fix on goining pop on homepage add view all button

**Cancel Booking Page**

- [ ] **U-44** As per current market
- [ ] **U-45** Show location on map nearest booking
- [ ] **U-46** Avoid Multipple booking /
- [ ] **U-47** Add Block calender for current booking for all other OTA as well

**Pre Booking -**

- [ ] **U-48** Improve listing Icons text, Font
- [ ] **U-49** Use the same icon as on Home page
- [ ] **U-50** Use same card design as on home page
- [ ] **U-51** make filter section small
- [ ] **U-52** Show loader when scroll listing
- [ ] **U-53** Add state listing according to user current loaction (make small chips of states also user and filter property according to selection
- [ ] **U-54** Improve filter button

**LUX**

- [ ] **U-55** Make Chnages in Desgin when user is in LUX Mode Change UI Accordingly
- [ ] **U-56** Sign Up User / Host
- [ ] **U-57** Forget Password
- [ ] **U-58** Menu Icons According to current market
- [ ] **U-59** History Page Map current Market
- [ ] **U-60** Safety Page Design
- [ ] **U-61** About Page Design
- [ ] **U-62** Same for Host

**Sockets**

- [ ] **U-63** Duplicate Pages


### Sheet: `Host`


**Homepage**

- [ ] **H-1** Welcome First Name messeage should be appear on top
- [ ] **H-2** Improve slider
- [ ] **H-3** Show Illustraion on No on going booking
- [ ] **H-4** Dicuss Home page
- [ ] **H-5** Fix Support Button


### Sheet: `Common`

- [ ] **C-1** When app Open Flash app logo with tag line with music  _Provided by US_
- [ ] **C-2** Change the background picture of get starting page
- [ ] **C-3** Use the same Font for aajoo name across all the platforms
- [ ] **C-4** Same for Login Page
- [ ] **C-5** Forget Password (contactus@aajoohomes.com)
- [ ] **C-6** In home page Put aajoo logo and name mentioned aajoo only
- [ ] **C-7** Change the icon for notification
- [ ] **C-8** In search bar show current location and remove any week or guest
- [ ] **C-9** When we slide the map to another area properties are not Apperaing
- [ ] **C-10** Set the re center button on map
- [ ] **C-11** In filter when we select number of guest make it same like airbnb
- [ ] **C-12** In advanced Filter
- [ ] **C-13** Make a Common Filter For Price
- [ ] **C-14** Make a chip filter property by monthly, per night
- [ ] **C-15** When be Click on the search bar Shows our service loaction areas, (Take example From Air Bnb
- [ ] **C-16** when we click on the near by button its not working
- [ ] **C-17** When we enter any other place map will not redirect inton another page (acc to current selection)
- [ ] **C-18** Make slider for the on the home page for announcements in diffrent colors 4-5 sliders
- [ ] **C-19** Show cat, from admin dashboard add icon also
- [ ] **C-20** add find your stay header after cat, listing ng
- [ ] **C-21** Need advise for Browse by cat, section
