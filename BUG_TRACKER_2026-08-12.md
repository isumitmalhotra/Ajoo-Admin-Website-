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

**A-81/82/83 (KYC restructure)** — moving host KYC to signup and user KYC to
first booking is a **flow change, not a fix**. It affects the DIDIT integration,
the host onboarding wizard and the booking path on both platforms. It needs its
own plan; it is not a checklist item.

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
- [~] **A-7** signup with google is missing when new account create — *⚠️ NOT A BUG — deliberately omitted (signup collects KYC Google can't supply). Becomes possible only if A-82/A-83 land. **Blocked on that decision.***
- [x] **A-8** ✅ When i signup my account without OTP my account is generated / but gave me error — *same root cause as A-10: the verify screen only accepted 4 digits, so the emailed 6-digit code could never be entered. Account created, code sent, screen unusable.*
- [x] **A-9** ✅ Signup is not done i recieved the email that my account is created — *same cause as A-8/A-10.*

**Forget**

- [x] **A-10** ✅ Forgot password shows 4 digits, email sends 6 — *🔴 ROOT CAUSE. Server raised generateOtp to 6 digits; app never updated. Four call sites had `length: 4` + validation demanding exactly 4. Signup verification was broken the same way.*
- [ ] **A-11** Phone No forgot Password is missing
- [ ] **A-12** Fix all the Forgot System

**Renter**

- [ ] **A-13** Show Properties in maps as per current location
- [x] **A-14** ✅ Show Current Location instead of Goa — *search pill hardcoded to "Goa" while listings were already fetched around real coordinates. Now resolved via the platform geocoder; "Nearby" until it answers.*
- [x] **A-15** ✅ Add notification icon on the top right instead of profile icon — *was a person icon, tooltipped "Profile", on a callback named onProfileTap, that opened NotificationsScreen.*

**This week tab**

- [x] **A-16** ✅ Show current real data in the tab — *card rendered hardcoded "1,240 verified homes"; now the real nearby count and place.*
- [x] **A-17** ✅ 18 new property also in real time — *"18 new in Goa this week" was a hardcoded default. Nothing reports it, so it is removed rather than guessed.*
- [ ] **A-18** remove the reloctor button and fix into the app

**Browser by cat.**

- [ ] **A-19** Show all the icon that show below and only 1 time remove from below and add these into one where 1st fix
- [ ] **A-20** Fix all the cat. icons a
- [ ] **A-21** Fix the Pre Booking & Lux Buttoon Below the Browse by Cat.

**Properties in your current locations**

- [ ] **A-22** show Properties in the slider and gave the see all button top right / Show 10-12 properties
- [ ] **A-23** Then show Curated For you
- [ ] **A-24** show Properties in the slider and gave the see all button top right / Show 10-12 properties
- [ ] **A-25** Show Blogs 4-5 and top right add see all and go to blog page
- [ ] **A-26** Show the FAQ and end the page.

**Property Detail page**

- [ ] **A-27** Property namse show the verified badage
- [ ] **A-28** in the app show all the properties deteilas like website
- [ ] **A-29** About /aminities / hose rule / location/ reviews/ host/ ploices in diffrent tables like webiste
- [ ] **A-30** do not show all of the above in long page add these of above in listing like:
- [ ] **A-31** if user clkick on the about shoe property dicption only, if user click on amanties shows aminties only and show on
- [ ] **A-32** Instead of reviews mention customer/user experinces
- [ ] **A-33** Then show gallary into
- [ ] **A-34** show near by attaraction places
- [ ] **A-35** Show distance from / near airport/ near hospital/ near park/ bus stand
- [ ] **A-36** show property blog pages

**Reserve Page**

- [ ] **A-37** View Details: Booking shows Daily weekly monthly/// Mention instead of daily, pernight and monthly remove weekly
- [ ] **A-38** Check in- out time is fixed by host remove the edit icon only/ its fixed already
- [ ] **A-39** Below the Total Price don't show any price nothing
- [ ] **A-40** if user select the monthly do not chnage the price below, price change according to the dates and set by host
- [ ] **A-41** Price various on the Minmun price, Ideal price, Maximun Price/ monthly Price / weekly price only for host not for user show accordngy of user booking stay for 7 days
- [ ] **A-42** instead of reserve show the negotiate & Reserve
- [ ] **A-43** Then shows the Book now and negotiate button Fix the negoatition buttion do n't show loader of negoation

**KYC**

- [ ] **A-44** When I click on book now or Negotiate Asking for KYC I Have done with the KYC from the app i didn't get my previous page where i left my booking before booked a property
- [ ] **A-45** When I'm a new user why it shows one time POA Beacuse I'm only booked i property, if user book more than 1 property then at that time show the POA policy
- [ ] **A-46** When i'm done with the booking , booking confrim page in missing in real time booking and send email once the booking is done for both the ends user and host
- [ ] **A-47** Booking confrimed page is missing show the get direction icon and the maps inside the app as per the refrence image
- [ ] **A-48** When i done with the booking ongooing page missing on the maps

**LUX Mode**

- [ ] **A-49** Lux Mode Make some diffrence in colors and icons and animations some diffrenteant from the standrad / fix a loader like it show lux
- [ ] **A-50** LUX Page same as the standard PAge only/ make it feel like LUX experince

**Prebooking : Page**

- [ ] **A-51** Current location is editable and show same like fic the home page and Browse by category.
- [ ] **A-52** Chnage the Browser by catgeory into homestay villas remove single couple etc
- [ ] **A-53** Fix the LUX button Top Right with the search that chnage of mode from there
- [ ] **A-54** In the prebooking show the properties in slider by areas
- [ ] **A-55** Shimla/ Kufri / Mohali, panchkula/ mohali/ Kharar
- [ ] **A-56** show all the areas types in the slider and show 10-12 properties in slide
- [ ] **A-57** in the prebooking gave the check in check out dates select to the user

**My booking Page**

- [ ] **A-58** Chnage the all the tabs as per the current theme
- [ ] **A-59** Upcoming stay / Ongoing page / Completed / Cancelled
- [ ] **A-60** User click on the view on the details page
- [ ] **A-61** Show the support button and host chat button and host details below the booking if TAB but not in the cancelled Show there book now button only do not show the Host details
- [ ] **A-62** Show the all property page below all of the above mentioned
- [ ] **A-63** Show property photos instead of maps

**Menu**

- [ ] **A-64** Remove right side menu and fix this menu below the profile page where all pages exits
- [ ] **A-65** Safety, about us pages same as the website

**Prolie Page**

- [ ] **A-66** When USer want to Update the documents do KYC again FIX Diddit
- [ ] **A-67** give location to auto fill the current location / or by Zip easy for user reduce time to fill the info.

**Host**


**My booking page**

- [ ] **A-68** Upcoming/ ongoing/Completed/ Cancelled in these of when User click on the view details tabs (Same as user where gave the property details and Support button and all )
- [ ] **A-69** In this gave the user details and Support and User chat button below that show the property details ( ongoing page like user side)

**Dashboard**

- [ ] **A-70** Instaed of Transacation show negaoation tab where user can find all the negioataion
- [ ] **A-71** Show 4-5 trancation only below show the FAQ
- [x] **A-72** ✅ total booking + weekly/monthly graph — *count loads fine; the tile was inert (A-73). New BookingsTrendCard built from booking history already loaded — no new endpoint.*
- [x] **A-73** ✅ ongoing stays / property / buttons not working — *all four dashboard tiles were plain Containers with no tap handler. Each now opens the screen it describes.*
- [ ] **A-74** Check more nesscary points that we can show in the host dashboard
- [ ] **A-75** Support //// Messeages insetad of the support
- [ ] **A-76** In the messeage show the aajoo support button on top and other user cionverstaion below
- [ ] **A-77** List your property page as per the Website fixed in the app, Then we have gave the final look for the Property form as per SEO we have to add the Property Form

**Menu**

- [ ] **A-78** All the menu pages show in the Host Profile page
- [ ] **A-79** In the host profile gave the menu on the top of the right side

**Host KYC Break down**

- [ ] **A-80** Host KYC done at the point of the Signup (IT WILL REDUCE THE TIME OF THE HOST WHEN HE LISTING THE PROPERTY INTO THE PLATFORM )
- [ ] **A-81** Only left with the Property Listing

**USER KYC**

- [ ] **A-82** User can Login and Register without KYC (IT WILL REDUCE TIME TO USER EXPLORE THE APP AND THE PROPERTIES NEAR BY.)
- [ ] **A-83** At the time before booking user can be do KYC before Booking


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
