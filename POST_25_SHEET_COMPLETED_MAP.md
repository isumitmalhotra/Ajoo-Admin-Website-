# Post-25 sheet — COMPLETED rows to mark ✅

> Maps our finished work to the **exact row text** in the `_Web App Bugs.xlsx` → "Post 25 release" sheet (the sheet has no row numbers; rows are sequential under each **page/section** heading, so use the section + quoted text to find each row). Text is quoted **as written in the sheet** (typos preserved) so you can match/Ctrl-F.
>
> ✅ = mark Done. Rows not listed under a section are **not** done (Section-0 rebrand, P2, or client-blocked) — see the bottom note.

---

### Page No 1 — Get Started Page
- ✅ "Current location is not correct in the search bar but correct in the map" *(RENT-3)*

*(All other Page-1 rows = Section-0 rebrand → leave unchecked.)*

### Page No 2 — Explore Stays / User Home page
- ✅ "Pre booking button IS not working…" *(RENT-2)*
- ✅ "Show 4 -5 listing in the in the home page and right side map same as it is" *(RENT-5)*

### Page No 7 — Signup account
- ✅ "Find lternative way when user go for KYC it wil directlyy re direct to the kYC" *(DIDIT auto-redirect — HOST-12 / VerifyButton)*

*(Google sign-in, phone signup, KYC-in-signup redesign = Section-0 → leave unchecked.)*

### Page No 8 — Renter Dashboard
- ✅ "remove below from nav bar" + "About us" + "Contact" + "Becomee a host" + "Add" *(RENT-6 — the nav-cleanup rows)*
- ✅ "renter profile update also profile picure not update" *(RENT-1)*
- ✅ "When it verifred from Diddit Remove the choose file" *(RENT-8)*
- ✅ "Current Location is not working" *(RENT-3)*
- ✅ "auto fill the address as per current loaction" *(RENT-3)*

### Page No 9 — Host Dashboard
- ✅ "What are you listing" / "Booking Prefence" / "Catergory" / "tags" / "all of the above do not show these in list" / "show these with Icons and name" *(HOST-5)*
- ✅ "Give current loaction to th user top of the section" / "it will easy to fill the form" / "Current loaction is not working here" *(HOST-7)*
- ✅ "max Price pe night/ in price per nigh / ideal Price" / "Monthly Price Same" / "Suggest Price in example" / "Weekly Price" *(HOST-8)*
- ✅ "Aminities with Icons" *(HOST-9)*
- ✅ "Put this below of property details" / "check in check ou time" / "Change the check out check in time" *(HOST-10)*
- ✅ "Remove Cuople Freindly" / "Remove this party ana group Booking" *(HOST-11)*
- ✅ "Compre these 2 scrren shots when i upload the document" / "then it show the aadhar card" / "Diddit Scaaner redirect it auto maticaly" / "KYC auto matically" *(HOST-12)*
- ✅ "Property is nott submiitted" *(HOST-1)*
- ✅ "When User select the Pg change it accordingly" / "whole form should be change" *(HOST-6)*
- ✅ "Property edit is not avialable whole dash board" *(HOST-2)*
- ✅ "ongoing page is missing from Host Side" *(HOST-3)*
- ✅ "Host Poperty List Is missing" *(HOST-4)*
- ✅ "When user find an error show them immediatly not the end of the form" *(HOST-14)*
- ✅ "These buttons are not working" *(HOST-13)*
- ✅ "Once the KYC is done show Verified" *(HOST-12)*
- ✅ "Check All the field and validations all across playfrom and here" *(BE-9 / CC-5)*
- ✅ "Also Bot Penguin is not the part of admin dashboard" *(ADM-2)*
- ✅ "PRebooking button is nto working in homepage" *(RENT-2)*
- ✅ "FIlter are not working on the map" *(RENT-4)*
- ✅ "Add property Form is not as provided in document also add same form in Admin dashboard to add property" *(HOST wizard + ADM-1)*

### Property Detail Page
- ✅ "In Property Detail page, in top show one big image and replace the slider with Grid to show property images" *(BOOK-8)*
- ✅ "also show no of guest availability" / "No of beds" / "Show rating (in AVG with star)" / "Show more details on Property Detail page from Property Form/Db" *(BOOK-1)*
- ✅ "Meet you host is not Dynamic…" *(BOOK-2)*
- ✅ "show host number post booking" *(BOOK-2)*
- ✅ "In property Detail page, Set Map section after Review section" *(BOOK-9)*
- ✅ "Show property Availibility Calender Before property Gallery" *(BOOK-3)*

### Critical — double booking
- ✅ "Also i haveb't seen something for double booking that functionality has been built or in working" *(BE-1)*

### Property Booking Page
- ✅ "IMage slider is not correct, not dynamic" *(BOOK-5)*
- ✅ "Add host detail in booking page" *(BOOK-6 — host detail + policy)*
- ✅ "Show Cancelation policy button in booking page also" *(BOOK-6)*

### Others
- ✅ "Need to work on the Modal for Booking in on going page" *(BOOK-7)*
- ✅ "In Transaction page add a download icon in the listing to downlaod invoice pdf" *(BE-5)*
- ✅ "Welcome back with name in Dashboard" *(CC-3)*
- ✅ "add loader and skeleton loader" *(CC-1)*
- ✅ "make calender same in whole webapp" *(CC-2)*
- ✅ "no notification generated" *(BE-3)*
- ✅ "I havn't seen Sockets messaging work" *(BE-4)*
- ✅ "Host daash board is not dynamic, please make htings working on real data…" *(BE-2)*

---

## Leave UNCHECKED (not done) — reason
**P2 / minor (in scope, not started):**
- Page 9: "Host Name is mission" + "add below Whatapp Number" *(HOST-17)* · "Host Work Space … in nav bar remove tis" *(HOST-15)* · "Add Blog and find your liting button…" *(HOST-15)* · "Show State Regulations pages here" *(HOST-19)* · "Color of host and USer inerface are same" *(HOST-18)* · "Bot Pengiun support inbox should not open automatically" *(BE-10)*
- Others: "In Host dashboard Replace Totalspent box…" *(HOST-16)* · "Support Bot Icon should be shown in only user dashboard…" *(RENT-9)* · Page 2 "Show support button on the home page only" *(RENT-9)*

**Blocked on client input:**
- Page 8: "Show Current Weather…" *(RENT-7 — weather API)*
- Property Detail: "Make near by places Dynamic…" *(BOOK-4 — data source)*

**Section-0 rebrand SOW (all remaining Page 1 / 3 / 4 / 5 / 6 / 7 redesign rows, luxury/filter redesign, side-bar rename, About/Contact/Login/Signup restyle, "premium icons all across", category-list, Google/phone auth):** these are the visual-overhaul + new-auth items — mark them as **Section-0** rather than pending bug-fixes.
