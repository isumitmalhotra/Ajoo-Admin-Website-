# AajooHomes — Mobile App (Flutter) Parity & Sync Task List

> **Goal:** bring the Flutter app (`aajoo_app_2026/`, pkg `rent_home`) to **full feature + content parity with the web app**, so anything published/controlled on web (by admin or host) is accessible and behaves identically on mobile, and every user/host account stays **synced** across web ↔ mobile.
>
> **Architecture note:** the app already talks to the **same backend** (`https://aajaodev.onrender.com`) and stores the session in `flutter_secure_storage`, so accounts/data are inherently shared. There is **no admin panel on mobile** (admin stays web-only) — "admin parity" here means *admin-published content + controls reflect on mobile*, not rebuilding the admin UI.
>
> Source of gaps: code audit of `aajoo_app_2026/lib` on 2026-06-27 + the web work completed in recent sprints. Stack: **GetX**, Dio, Razorpay, Google Maps, Geolocator.

---

## Current state (what mobile already has) ✅
- **Renter:** home + map, property details, search/filter, checkout/booking, booking history + reviews, bookmarks, ongoing booking, prebooking, price negotiation, safety, profile.
- **Host:** home dashboard, add/update property (**old form**), booking history, invoices, payouts, property details, support, ongoing booking.
- **Common:** auth (login/signup/basic-info/govt-ID/verify-OTP/forgot-password/house-agreement/emergency-number/referral), onboarding, notifications (FCM), settings, change-password, about/FAQ/privacy/terms/safety (pulled from `common/*`), location picker, splash.
- **Done recently:** Sand & Indigo redesign (Part B complete), profile-update fix, FCM token cleanup, auth "Skip" flow, duplicate-controller crash fix.

---

## Pending tasks (grouped, prioritized)

Legend — **P0** = blocks parity/go-live · **P1** = important · **P2** = polish. Effort in person-days (needs a human device-tester for QA items).

### M1 · Host onboarding wizard parity 🔴 P0  — **DONE (code; on-device test in M9)**
Earlier audit said it posts to `/host/add` — **correction:** `property_service.addProperties` already posts to **`/properties/add`** (the web endpoint). So the gaps were the missing fields, not the endpoint.
- [x] Endpoint already correct (`/properties/add`, multipart `property_img` + `property_doc`).
- [x] **22 H1 fields wired into the data layer** — `new_property_controller_legacy.dart` `_buildBaseFormData` now sends `property_type, category_tier, booking_pref, area_locality, landmark, floor_no, bathrooms, security_deposit, weekend_price, extra_guest_charge, cleaning_fee, min_booking_amount, video_url, couple_friendly, local_id_allowed, quiet_hours, ownership_type, self_declaration` + conditional `pg_settings_json` / `party_settings_json`. Controller fields + `_numOrNull` helper added. 0 analyzer errors.
- [x] **Typed documents** — `saveProperty` now builds `property_doc_types` (fire_safety_noc/ownership/noc/police_verification/party_license) + `property_doc_states` JSON arrays aligned to the uploaded `property_doc` files.
- [x] **Pending-approval message** — success now reads "Listing submitted — pending admin approval" (backend sets `is_active=0`).
- [x] `property_type` wired from the existing type chips (`tempSelected`).
- [x] **UI inputs for all new fields** added to `host_property_listing_screen.dart`: new sections **Listing Details** (area/locality, landmark, floor, bathrooms, booking-pref chips, ownership chips, quiet hours, video URL), **Additional Charges** (security deposit, weekend/cleaning/extra-guest/min-booking prices), **Stay Preferences** (couple-friendly, local-ID switches), conditional **PG / Sharing** sub-form (room type, gender, rent/deposit/lock-in/curfew/visitor/food), conditional **Party / Group** sub-form (max people, charges, end time, loud music). `self_declaration` mapped from terms acceptance. All wired into `_saveProperty` + disposed. 0 analyzer errors.
- [x] **Category linkage** — selected type chips now map to `catId`s → posted as `property_category[]` (was an empty string before, so listings never linked to categories/filters).
- [x] **`property_amenities_json`** now posted (what the detail page renders, like web).
- [ ] **Tags**: no tag selector in the mobile form yet (web has one) → `property_tag[]` not posted. *(M4 — needs a tag picker)*
- [ ] **Amenities from admin catalog**: mobile still uses a hardcoded 6-option list, not `/common/amenties` (with qty). *(M4 content sync)*
- [ ] Pending-status chip in host listings + property **edit** parity (the new fields in `update_property_page`). *(M3)*

### M2 · DIDIT KYC integration 🔴 P0  — **DONE (code; on-device test pending in M9)**
**Zero DIDIT references in the app today** — it uses legacy OTP + govt-ID OCR. Web uses DIDIT for all identity.
- [x] **Renter `renter_kyc` + host `host_kyc` at registration** — wired after OTP. New: `service/verify_service.dart`, `ui/screens_common/auth/kyc/{kyc_controller,didit_kyc_screen}.dart`, `/kyc` route, `verify_controller` now routes to `/kyc` post-OTP. Compiles clean (`flutter analyze`).
- [x] `POST /verify/create-session` → open `sessionUrl` in the **system browser** (camera works natively — webview camera was the R191/R192 problem) → user returns → poll `check-session` then `status`.
- [x] **Booking-time KYC gate** — unverified guests are routed to DIDIT before a booking is created, then return & retry. Wired on **both** entry points: direct booking (`property_details/property_page.dart`) and post-negotiation booking (`price_negotiation/negotitaion_page.dart`). Uses user-level `renter_kyc` (no bookingId) via the reusable `/kyc` screen with `returnResult:true` (controller `_finish` returns a bool to the caller instead of navigating to a dashboard).
- [x] **Verification status on the model** — added `verification_status` + `isKycVerified` to `UserDetail` (`models/user_models.dart`); refreshed via `getUserDetails` after KYC.
- [x] **"Verified" badge** on profile (KYC section shows "Identity verified" when `isKycVerified`).
- [x] Keep the **dev OTP bypass** aligned (`0000`) — unchanged; still active for test builds.
- [x] Retire the legacy `government_id_upload` screen — it was already **orphaned** (ID collection consolidated into `basic_info_screen`, which has a Skip path; real verification is now DIDIT). Deleted the dead screen + empty dir; 0 references, 0 analyzer errors project-wide. *(Manual doc-upload UX cleanup in basic_info per post-25 R216 "remove choose file when DIDIT verified" is a separate redesign item → M8.)*
- [ ] **On-device test** the browser-return + camera flow (Android — needs device, M9).
- [ ] *(later)* optional seamless in-app webview (`flutter_inappwebview` w/ camera permission) instead of system browser.

### M3 · Property verification & status surfacing 🟠 P1  — **DONE (core)**
- [x] Host "My Listings" (`host_profile.dart`) now shows a per-property **status chip — Approved / Pending review / Rejected** computed from `verification_status` + `is_active`/`is_verify`. Added `verificationStatus` to the host `Property` model. The Active/Paused chip now shows only once approved.
- [x] **Removed the fake hard-coded amenity defaults** (`['Pool','4 BR','Wi-Fi','AC']`) on the renter property-detail preview — now shows real amenities only (the full Amenities section already handled real data + an empty state). 0 analyzer errors.
- [ ] Display the new **H1 fields** (bathrooms, deposit, cleaning fee, check-in/out, couple-friendly) on the property detail — needs single-property model parsing + UI; **overlaps the post-25 detail-page redesign (R445–R458)** → fold into M8.
- [x] Property **edit-form parity** — `update_property_page` now **prefills + edits** all H1 fields (property type, area/locality, landmark, floor, bathrooms, security deposit, weekend/cleaning/extra-guest/min-booking, video, quiet hours, booking-pref chips, ownership chips, couple-friendly/local-ID switches). Host `Property` model now parses these from `/host/property-search` (returns all cols). Paired with the `updateProperty` **edit-safety fix** (strips blanks so untouched fields aren't wiped). 0 errors. *(amenities/tags editing still preserved-if-untouched; a picker in edit is a minor follow-up.)*
- [ ] "Verified stay" badge on the booking screen (minor). *(M8)*

### M4 · Admin-driven content sync 🟠 P1  — **DONE (core)**
- [x] **Amenities from the admin catalog** — host form now loads `/common/amenties` (via `CommonController.amenities`) instead of the hardcoded 6; selected amenity **IDs** post as `property_amenities[]` (join table → detail page populates) + `property_amenities_json` for labels.
- [x] **Tags picker** — new Tags section loads `/common/tags`; selected tag IDs post as `property_tag[]`. (Closes the M1-deferred tags + amenities items.)
- [x] **Categories** — already linked via the type chips → `property_category[]` (M1).
- [x] **Terms & Conditions + Host Agreement** — already backend-driven (`static_page_service` → `common/term-condition-host` / `-user`). No work needed.
- [x] **FAQ / about / privacy / safety** — already pulled from `common/*`. Confirmed synced.
- [ ] **Coupons at checkout** — the active booking flow has **no** coupon entry (the only discount field is in `unused_screens/cart`, a dead widget). Deferred: needs a product decision (does renter checkout apply coupons on web?) + a backend validate endpoint + price-recalc in the booking flow.
- [ ] **CMS homepage sections** — mobile home is a bespoke native layout, not a mirror of the web CMS sections; rendering admin CMS on mobile is a larger feature, not a 1:1 sync. Deferred pending a decision on whether mobile should mirror web CMS.

### M5 · Booking & payment parity 🟠 P1  — **DONE (core)**
- [x] **Booking date format** — the **active** booking flows (`property_page`, `negotitaion_page`) already send **`dd-MM-yyyy`** (correct). The `yyyy-MM-dd` flagged earlier was the misnamed review page, not booking. No change needed.
- [x] **GST is now tariff-based** — was wrongly `<₹7500 → 5% : 12%`; fixed to **`≤₹7500 → 5%, >₹7500 → 18%`** (matches backend `calculateBookingtax`) across **all 9 spots** (active property/negotiation/checkout + legacy screens). This mis-charged/mis-displayed tax on stays over ₹7500/night.
- [x] **Abandoned-booking filter** — handled **backend-side** (`userBookingList` excludes payment-pending/unpaid, BE 152d09c); mobile consumes the already-filtered list, no client change needed.
- [ ] **Razorpay test mode** — doc note only (use **UPI `success@razorpay`** for UAT; already in `CLIENT_TEST_HANDOFF`). No code change.
- [ ] Double-booking / single-COD safeguards — client-side limits already in `booking_controller` (max 3 active, 1 COD) + backend 400s surfaced via snackbar. *(verify messaging on device — M9)*

### M6 · Chatbot / support parity 🟡 P2  (~1 d)
- [ ] **BotPenguin** is on web but absent on mobile — decide: embed the BotPenguin webview (with SSO token, like web) **or** keep native support. Per post-25 feedback, bot should **not auto-open** and should appear only on user dashboard/profile.
- [ ] Wire **real support contact** (WhatsApp/phone/email) behind Support / "Chat with host" — placeholders today (shared P0 blocker: needs real numbers).

### M7 · Account / session sync & RBAC 🟠 P1  — **DONE (core)**
- [x] **Host dual-role** — already correct: `auth_controller` (login) + `verify_controller` (post-OTP) route by `isHost` (host → `/host/home`, renter → `/home`). Mobile has no admin panel/dual-token, so it's simpler than web.
- [x] **Deleted-account / expired session** — added a **default 401 handler** in `api_error_handler.dart`: when a call 401s (backend "Account no longer exists" / "token expired") and the caller gives no `onUnauthorized`, it clears the token + user data and `Get.offAllNamed('/login')` (guarded against loops). Mirrors the web axios interceptor.
- [x] **Cross-device sync** — inherent (same backend + secure-storage token); `logout` already clears per-user caches (bookmarks). No stale local sources.
- [ ] **Forgot-password** test-mode caveat (no mail server) — same as web; doc note, no code.

### M8 · Post-25-release items that apply to mobile 🟡 P2  (~2–3 d)
From `POST_25_RELEASE_TASKLIST.md` — the content/UX requests that should also land on mobile (the team said "same on app"):
- [ ] Current-location accuracy in search (geolocator) — matches web R21/R230.
- [ ] Check-in/check-out **calendar** in search instead of category dropdown (R22).
- [x] **"Verified" after KYC** — profile shows "Identity verified" (M2); + a **"Verified stay" trust badge** added to the booking/checkout screen.
- [x] **Aadhaar spelling** — the mobile occurrences are case-match logic against admin doc-type titles, **not** display strings; the fix belongs in the admin/back-office doc-type data, not the app.
- [x] **Immediate field validation (R383)** — `autovalidateMode: onUserInteraction` added to the 8 key forms (add-property, edit-property, the 3 signup steps, login/signup, profile-update, change-password) so errors show as the user types, not only on submit.
- [x] **Unified calendar (R489)** — the 6 `showDatePicker` calls (3 files) use **no custom theme overrides**, so they already inherit the app's Sand & Indigo theme (effectively consistent). A shared wrapper would be marginal + risk the active booking picker → not changed.
- [ ] Skeleton loaders — app already shimmers on host-home + history; extending to more screens is optional polish. *(low priority)*
- [ ] Amenities/tags **picker in the edit form** — deferred (prefill needs the current-selection join data; existing selections are preserved-if-untouched by the update safety fix).
- [ ] Pricing labels (max/night, weekly, monthly, suggested) + amenities-with-icons in host form (R275–R285).
- [ ] Loaders / skeleton loaders, consistent calendar widget app-wide (R488/R489).
- [ ] *(Most pure-web layout items — Get Started splash, nav scroll — are web-only; flag any the client also wants on mobile.)*

### M9 · On-device QA & release 🔴 P0 (for go-live)  (~3–4 d, human tester)
- [ ] Full renter flow on real Android + iOS (browse → negotiate → book → pay → review).
- [ ] Full host flow (DIDIT KYC → list with docs → pending → see approval → bookings → payout).
- [ ] Push notifications (FCM) end-to-end; deep-link routing.
- [ ] Build + sign release (Android `appBundle`, iOS), store metadata, version bump (`pubspec` `1.0.0+2`).

---

## Recommended sequencing
1. **M2 DIDIT KYC** + **M1 Host onboarding** — the two true feature gaps that block "do the same as web". (Do M2 first; M1's listing flow depends on host KYC.)
2. **M3 + M4** — surface verification status + make all admin content dynamic (sync).
3. **M5 + M7** — booking/payment correctness + account/session robustness.
4. **M6 + M8** — chatbot/support + post-25 UX polish.
5. **M9** — device QA + release.

**Rough total: ≈ 16–21 person-days** (vs the old high-level MA-1/2/3 ≈ 11–14). The increase is the host-onboarding wizard parity + content-sync detail that weren't itemized before.

---

## Decisions (locked 2026-06-30)
1. **Start order:** M2 (DIDIT KYC) first → then M1 host wizard. ✅
2. **Platform:** **Android first**; iOS later.
3. **Chatbot:** embed **BotPenguin webview** (parity) when M6 comes up — no auto-open, user dashboard/profile only.

## Still open
- **Post-25 scope on mobile:** which web redesign items must also ship on mobile vs web-only? (revisit at M8)
