# `_Web App Bugs.xlsx` — Full Status (all 4 sheets) — for marking the sheet

> **Purpose:** go through the workbook row-by-row and mark each. Verified against the current codebase on **2026-07-12** — web (`aajao-frontend-vercel`, live), backend (`aajaoBackend-render`, live), mobile (`aajoo_app_2026` Flutter, source-verified).
>
> **Status key:** ✅ **Done** (mark complete) · 🔷 **Pending** (in-scope, not done) · 🔒 **Blocked** (needs client input) · 🟣 **Section-0** (part of the rebrand SOW — out of the current contract) · 💬 **Discussion/subjective** (not a checkable deliverable).
> **Platform:** **[W]** web · **[M]** mobile · **[Both]**.
>
> **Row refs:** the sheets have no ID column — rows are sequential under each **page/section** heading (and `rN` = spreadsheet row for User/Host/Common). Quoted text is verbatim (typos preserved) so you can match.

---
---

# SHEET 1 — "Post 25 release"  (WEB app)

### Page 1 — Get Started Page
- ✅ [W] "Current location is not correct in the search bar but correct in the map"
- 🟣 **Everything else on Page 1** = the Get-Started **rebrand** (remove floating tags/"12k properties", logo bg, font change, getting-started entry point + role routing, nav-on-scroll, remove FAQ/footer/find-your-stay, category dropdown→calendar, "content provided by us"). → **Section-0.**

### Page 2 — Explore Stays / User Home
- ✅ [W] "Pre booking button IS not working…"
- ✅ [W] "Show 4 -5 listing in the… home page and right side map same as it is"
- 🔷 [W] "Show support button on the home page only" (support-widget scoping — done for dashboard; home-only toggle is a small tweak)
- 🟣 rest (nav "find your stay/blog/about", slider spacing, support-UI restyle) → Section-0.

### Page 3 — About Us  → 🟣 **all Section-0** (redesign, images, mission/vision animation, content).

### Page 4 — Contact Us
- ✅ [W] "in contact us page remove suport call icon and add address" (office address added)
- 🟣 "Fix this form" (full redesign) → Section-0.

### Page 5 — Menu / Sidebar
- 🔷 [W] "Remove Support Button From here" / "Sho Sate regulations in Footer" (minor)
- 🟣 "Rename Home → Prebooking", move items to footer → Section-0.

### Page 6 — Login  → 🟣 **all Section-0** (image/animation, content, "looks cheap" restyle).

### Page 7 — Sign Up
- ✅ [W] "Find lternative way when user go for KYC it wil directlyy re direct to the kYC" (DIDIT auto-redirect)
- 🟣 "Google sign button is not working" (BE-7), "Phone number sign up is missing" (BE-8), "looks cheap" restyle, "choose journey first", personal-info step → **Section-0** (OTP-first + social auth + rebrand).

### Page 8 — Renter Dashboard
- ✅ [W] "remove below from nav bar" + "About us" + "Contact" + "Becomee a host" + "Add" (nav cleanup)
- ✅ [W] "renter profile update also profile picure not update"
- ✅ [W] "When it verifred from Diddit Remove the choose file"
- ✅ [W] "Current Location is not working" + "auto fill the address as per current loaction"
- 🔒 [W] "Show Current Weather as per current loaction" (needs weather API)
- 🟣 "Form as per current market" / "User and Host Registation from can be same" → Section-0 / 💬 discussion.

### Page 9 — Host Dashboard (largest section)
- ✅ [W] "What are you listing / Booking Prefence / Catergory / tags / …show these with Icons and name"
- ✅ [W] "Give current loaction to th user top of the section / Current loaction is not working here"
- ✅ [W] "max Price… / Monthly Price / Suggest Price in example / Weekly Price"
- ✅ [W] "Aminities with Icons"
- ✅ [W] "Put this below of property details / check in check ou time / Change the check out check in time"
- ✅ [W] "Remove Cuople Freindly / Remove this party ana group Booking"
- ✅ [W] "Diddit Scaaner redirect it auto maticaly / KYC auto matically / then it show the aadhar card"
- ✅ [W] "Property is nott submiitted"
- ✅ [W] "When User select the Pg change it accordingly / whole form should be change"
- ✅ [W] "Property edit is not avialable whole dash board"
- ✅ [W] "ongoing page is missing from Host Side"
- ✅ [W] "Host Poperty List Is missing"
- ✅ [W] "When user find an error show them immediatly not the end of the form"
- ✅ [W] "These buttons are not working"
- ✅ [W] "Once the KYC is done show Verified"
- ✅ [W] "Check All the field and validations all across playfrom and here"
- ✅ [W] "Also Bot Penguin is not the part of admin dashboard"
- ✅ [W] "PRebooking button is nto working in homepage"
- ✅ [W] "FIlter are not working on the map"
- ✅ [W] "Add property Form is not as provided in document also add same form in Admin dashboard"
- ✅ [W] "Host Work Space … in nav bar remove tis"
- ✅ [W] "Show State Regulations pages here"
- 🔷 [W] "Host Name is mission / add below Whatapp Number" (name shown; WhatsApp needs a BE column)
- 🔷 [W] "Bot Pengiun support inbox should not open automatically" (BotPenguin dashboard setting)
- 🟣 "Guest Form Must be Mordenn / it looks cheap", "all icons premium", "Make these slider small", "Add Support UI Here", "Color of host and USer inerface are same", "Add Blog…", "for luxury add more desing", "change filter desing", "Move CTA…", "redesing Become a host/FAQ/review", "the booking modal right side … design correctly" → **Section-0**.

### Property Detail Page
- ✅ [W] "in top show one big image and replace the slider with Grid"
- ✅ [W] "also show no of guest availability / No of beds / Show rating (AVG with star) / Show more details"
- ✅ [W] "Meet you host is not Dynamic…" + "show host number post booking"
- ✅ [W] "In property Detail page, Set Map section after Review section"
- ✅ [W] "Show property Availibility Calender Before property Gallery"
- 🔒 [W] "Make near by places Dynamic abd redesign" (needs data source)

### Critical — double booking
- ✅ [Both] "double booking… functionality" (BE-1 overlap guard — backend, both apps)

### Property Booking Page
- ✅ [W] "IMage slider is not correct, not dynamic"
- ✅ [W] "Add host detail in booking page"
- ✅ [W] "Show Cancelation policy button in booking page also"
- ✅ [W] "Remove Footer from Property booking final page"
- 🟣 "Please Redesign the booking page" → Section-0.

### Side Bar Menu bar  → 🔷/🟣 (rename Home→Prebooking, move items to footer) → Section-0.

### Others
- ✅ [W] "Need to work on the Modal for Booking in on going page"
- ✅ [W] "In Transaction page add a download icon… invoice pdf"
- ✅ [W] "Welcome back with name in Dashboard"
- ✅ [W] "add loader and skeleton loader"
- ✅ [W] "make calender same in whole webapp"
- ✅ [Both] "no notification generated" (BE-3)
- ✅ [W] "I havn't seen Sockets messaging work" (BE-4 backend verified + hardened)
- ✅ [W] "Host daash board is not dynamic… real data" (BE-2)
- ✅ [W] "In Host dashboard Replace Totalspent box…" (host KPIs = Occupancy Rate, no Total Spent)
- ✅ [W] "Support Bot Icon… only user dashboard/profile" (widget scoped to renter area)
- 🟣 "Please redesign the About us page and contact us page" → Section-0.

**Post 25 release tally: ~50 ✅ done · a few 🔷 pending (HOST-17 WhatsApp, BE-10 dashboard toggle, home-support toggle) · 2 🔒 blocked (weather, nearby) · rest 🟣 Section-0.**

---
---

# SHEET 2 — "User"  (Renter — Web + Mobile)

- ✅ [Both] **r2** "Dditt KYC" — web VerifyButton + mobile DIDIT screens
- 🔷 [M] **r3** "Loader On app Opening (Castle Image is appearing)" — mobile splash asset swap pending (web has skeletons ✅)
- 🔷 [W] **r4** "Change Price button chip on map in Homepage" — review
- ✅ [Both] **r5** "Change Map Desgin acc to current app trend" — redesign
- 🔷 **r6** "Fix City and State Id Management in DB" — backend, pending
- 🟣 **r7** "Break Down Sign up Process" — Section-0
- ✅ [Both] **r8** "Swap cat. and find your stay… category on top on home page"
- ✅ [Both] **r9** "Re design the property cart on homepage… add info/tags/cat"
- 🟣 **r10** "Change catergory icon, Name also in admin" — Section-0 (Lucide icons + category set)
- ✅ [Both] **r11** "Change Filter… remove weekly and montly filter (re-design)"
- ✅ [W] **r12** "Fix re-center button on map"
- ✅ [W] **r13** "Check notificaation all across Platform" (BE-3)
- ✅ [Both] **r14** "whishlist"
- ✅ [W]+[M-host] **r15** "Re desgin nav bar, add Hii messeage with user Name" (web renter+host ✅; mobile host ✅, mobile renter 🔷)
- 🟡 [Both] **r16** "Use relatable SVG, illustrations" — redesign (partial)
- ✅ [Both] **r17** "Side Bar" — redesigned drawer/sidebar
- 🔷 [M] **r18** "Fix social Media Section In bottom… every device" — responsive, pending
- 💬 **r19** "Change icon" — vague
- 🔷 **r20** "In top section show users profile details… edit icon" — pending
- 💬 **r21** "Dicussion on sidebar listing"
- 💬 **r22** "help & support contact Dicussion"
- 🔷 **r23** "Social Media Icon issue in help and support page"
- 🟣 **r25/26** "About US / Re desgin about US page" — Section-0 (web About restyled 🟡)
- ✅ [Both] **r29** "Settings" — settings screen exists
- 🔷 **r30** "Remove about us" — pending decision
- 💬 **r31** "Add Changes According"
- 🔷 [M] **r32** "Fix rate app Button" — mobile, pending
- 🔷 **r35** "improve document uploading system"
- 🔷 **r36** "Specifiy image should be in landscape…"
- ✅ [Both] **r40** "Set the font and icon, Button size (too Big)" — redesign
- 🔷 [M] **r41** "When Scroll Up catergortyy and rating section disappear" — mobile detail, pending
- ✅ [Both] **r42** "replace the save button with whish list icon"
- ✅ [W] **r43** "Make gallary on little top… click image should open" (hero+grid+lightbox)
- 🔒 **r44** "add attarction points" (nearby data — blocked)
- ✅ [Both] **r45** "Add cancallation policy button"
- 🔷 [M] **r46** "Fix the bottom price section… overlapping with mobile back button"
- 💬 **r49** "dicussion on booking change"
- 🟡 [W] **r51** "Sockets" — backend verified (BE-4); web has no chat client (mobile has negotiation)
- ✅ [Both] **r52** "Change loader display when click on offer your price"
- ✅ [Both] **r55** "Razor Pay" — checkout live (test mode)
- 💬 **r56/64** "As per current market"
- ✅ [Both] **r59** "On going page" — exists
- 🔷 **r60/61** "Only one current ongoing booking for pay-on-arrival… subscription model" — logic, pending
- 🔷 **r62** "fix on goining pop on homepage add view all button"
- ✅ [Both] **r63** "Cancel Booking Page" — exists (web CancelBookResult, mobile)
- ✅ [Both] **r66** "Show location on map nearest booking"
- ✅ [Both] **r67** "Avoid Multipple booking" (BE-1)
- ✅ [W] **r70** "Add Block calender for current booking…" (BOOK-3 availability; OTA sync 🔷)
- ✅ [Both] **r73** "Pre Booking"
- ✅ [Both] **r74/75/76** "Improve listing Icons/text/Font / same icon & card as Home page"
- ✅ [Both] **r77** "make filter section small"
- ✅ [Both] **r78** "Show loader when scroll listing" (skeleton/shimmer)
- 🔷 **r79** "Add state listing… chips of states… filter by selection" — pending
- ✅ [Both] **r80** "Improve filter button"
- ✅ [Both] **r82/83** "LUX / Change UI in LUX Mode"
- 🟣 **r88** "Forget Password" (restyle) — Section-0 (functional exists ✅)
- ✅ [Both] **r89** "Menu Icons According to current market" — redesigned icons
- ✅ [M] **r90** "History Page Map current Market"
- ✅ [M] **r91** "Safety Page Design"
- ✅ [Both] **r92** "About Page Design" — restyled
- ✅ [M] **r95** "Duplicate Pages" — dead screens moved to unused_screens

---
---

# SHEET 3 — "Host"

- ✅ [Both] **r2** "Welcome First Name messeage should be appear on top"
- ✅ [Both] **r3** "Improve slider" — redesigned
- ✅ [Both] **r4** "Show Illustraion on No on going booking"
- 💬 **r5** "Dicuss Home page"
- 🔷 **r6** "Fix Support Button" — pending

---
---

# SHEET 4 — "Common"  (shared)

- 🔷 [M] **r1** "When app Open Flash app logo with tag line with music" — mobile splash, pending
- 🟣 **r2** "Change the background picture of get starting page" — Section-0
- ✅ [Both] **r3/4/6** "Same Font for aajoo name across platforms + Login + home logo/name"
- ✅ [Both] **r5** "Forget Password (contactus@aajoohomes.com)"
- 🔷 **r7** "Change the icon for notification" — minor
- ✅ [Both] **r8** "In search bar show current location and remove any week or guest"
- ✅ [W] **r9** "When we slide the map… properties are not Apperaing" (search-on-move/bounds)
- ✅ [W] **r10** "Set the re center button on map"
- ✅ [Both] **r11** "In filter… number of guest make it same like airbnb"
- ✅ [Both] **r18** "Make a Common Filter For Price"
- ✅ [Both] **r19** "Make a chip filter property by monthly, per night"
- 🔷 **r20** "When Click on the search bar Shows our service loaction areas (Air Bnb style)" — pending
- 🔷 **r21** "when we click on the near by button its not working" — pending
- ✅ [W] **r22** "When we enter any other place map will… redirect (acc to current selection)"
- ✅ [W] **r23** "Make slider for… announcements in diffrent colors 4-5 sliders" (AnnouncementSlider)
- 🟣/✅ **r24** "Show cat, from admin dashboard add icon also" — categories from admin ✅; premium icons → Section-0
- ✅ [Both] **r25** "add find your stay header after cat, listing"
- 💬 **r26** "Need advise for Browse by cat, section"

---
---

## Grand summary — what to mark ✅
- **Post 25 release (web):** ~50 rows done (all Host-dashboard fixes, property-detail + booking, notifications, sockets-backend, invoice, welcome-name, skeletons, calendar, contact address, footer, support-scoping, KPI). Pending: HOST-17 WhatsApp, BE-10 auto-open, home-support toggle. Blocked: weather, nearby. Rest: Section-0.
- **User (renter, web+mobile):** ~30 rows done (KYC, wishlist, cards, filters, map re-center, notifications, welcome-name, cancellation, availability, LUX, loaders, history, safety, settings, gallery, prebooking…). Pending: renter greeting (mobile), splash, some detail/responsive, POA rules, city/state IDs. Blocked: attraction points. Section-0: signup breakdown, admin icons/category.
- **Host:** r2, r3, r4 done. r6 pending, r5 discussion.
- **Common:** ~14 done (map pan/recenter/redirect, filters, announcement slider, search location, category header, fonts, forgot-password). Pending: splash logo+music, notification icon, "service areas" search, "nearby" button.

**Legend recap:** ✅ mark complete · 🔷 pending (in-scope) · 🔒 blocked (client input) · 🟣 Section-0 (rebrand SOW) · 💬 discussion. Mobile ✅ = verified in Flutter source (not a live-device run) for map/splash/sockets items.
