# Mobile Redesign — Wiring & API-Gap Tracker

> Living doc for the teal/orange redesign (Path C: adopt the new design onto the
> working `rent_home` app). For **every re-skinned screen** it records whether the
> backend is fully wired, and flags anything that can't be wired yet so we finish
> it later. Update as each screen lands.
>
> **Rule:** a screen is only "done" when its components are wired to real data —
> no mock left behind. Anything blocked on a missing API goes in **§ Open API gaps**.

Legend: ✅ wired to live backend · 🟡 partial (some data mock/placeholder) · ⛔ needs API (see gaps) · — no backend needed

---

## Screen wiring status

| # | Screen | File | Backend wiring | Notes |
|---|--------|------|----------------|-------|
| P0 | Design system | `constants.dart` · `theme_service.dart` · `fonts.dart` | — | Global teal/orange + Poppins/Manrope. Commit `71c2cf6`. |
| 1 | Getting Started / Onboarding | `screens_common/onboarding/onboarding.dart` | — | Nav-only (`Get.offAllNamed('/login')`). No backend. Commit `35faee9`. Google/Mobile CTAs route to login (see gap G-1). |
| 2 | Login / Sign-up | `screens_common/auth/login_signup/auth_page.dart` | ✅ | All wiring preserved: `AuthController.login()` + isHost routing (/host/home vs /home), signup path (`checkEmailAlreadyExists` → InfoScreen), forgot-password route, OptionButton guest/host toggle, validators. `POST /user/login`. Only Google social is not wired (G-1). |
| 3a | Explore — property card | `screens_renter/home/components/curated_card.dart` | ✅ | Re-skinned to scaffold card (badge + heart, location · title · rating+price row). Real fields (propertyName/City/Address/Price/coverImage) + onTap/onFavoriteTap unchanged. Used across Explore, Saved, Search. |
| 3b | Explore — home | `screens_renter/home/homescreen.dart` (+ components) | ✅ | Cards ✅, search pill ✅, **category circles ✅** (icon-in-teal-circle + label, name→icon mapper; selectedIndex/onChanged filter wiring kept), **trust bar ✅** (Verified/Secure/Best Price/24-7). Map + `POST /properties/search` + draggable listings all ✅ wired. Branded header kept (already teal). Map-first structure retained. |
| 4 | Property Details | `screens_renter/property_details/property_page.dart` | ✅ | Hero rating badge + "Aajoo Verified Home" card + **specs row now wired** (guests/beds/baths from real data — see G-2). Booking bar teal/orange. Optional-only remaining: highlights icon-grid, two-button Book/Negotiate bar. ALL booking/deal/coupon/availability wiring ✅ working. |
| 5 | Checkout / Payment | (inside `property_page.dart` booking section) | ✅ | Mobile has no separate checkout screen — dates/coupon/availability/`POST /booking/create`/Razorpay/`/create/payment-verify` all live in Property Details, wired + teal. |
| 6 | Booking Confirmed | `property_details/components/booking_succes_dialog.dart` | ✅ | Re-skinned to scaffold design — green hero check, "Booking Confirmed!", teal-50 Booking ID card, Get Directions + Go Home. Real bookingId/paymentId/lat/long + DeviceService directions wiring unchanged. (Kept as a dialog, not promoted to a route, to avoid a flow change.) |
| 7 | Negotiate | `screens_common/price_negotiation/negotitaion_page.dart` | 🟡 | Teal + date-picker wired (Phase 2). It's a real-time **socket chat**, not the scaffold's single-page offer form — messaging feature kept; visual polish of chat bubbles/composer is optional. |

---

## Guest account (#2)

| # | Screen | File | Backend wiring | Notes |
|---|--------|------|----------------|-------|
| 8 | Bookings | `screens_renter/history/history_page.dart` | ✅ | Re-skinned to scaffold — teal app bar + **4 status tabs** (Upcoming/Ongoing/Completed/Cancelled) filtering the real `getUserHistory` data; BookingCard rows + refresh kept. |
| 9 | Saved Stays | `screens_renter/bookmark_properties/bookmark_properties_page.dart` | ✅ | Re-skinned — big custom card replaced with the shared **CuratedCard** in a 2-col grid + teal app bar + new empty state. Bookmark load/remove (`BookmarkService`) + property navigation wiring unchanged. |
| 10 | Dashboard | `screens_renter/dashboard/dashboard_screen.dart` | ✅ | Already built new-design (this session) — welcome banner, stat grid (Upcoming/Saved/Reviews/Total Spent), negotiated-deal banner, upcoming list, quick actions. Wired to UserController/DealsController/BookmarkService. |
| 11 | Profile | `screens_renter/profile/profile_screen.dart` | 🟡 | Functional + teal (KYC status, doc upload, edit profile all wired). The working profile is a full account+KYC screen (1.9k lines); collapsing it to the scaffold's simple menu would lose KYC/edit, so kept — optional visual polish only. |
| 12 | **Guest bottom-nav shell** | `screens_renter/guest_shell.dart` | ✅ | Built (option A). `GuestShell` = `IndexedStack` of the 5 wired screens (Home/Dashboard/Bookings/Saved/Profile) + a teal M3 `NavigationBar` (Poppins/Manrope labels, teal-50 indicator). Route `/home` now points here, so every post-login `Get.offAllNamed('/home')` lands on the shell. Home tab keeps its own Scaffold (drawer + floating header + draggable map sheet) nested inside — verified builds. Booking-Confirmed "Go Home" re-routed through `/home` so it lands on the shell too. Drawer still works (redundant with tabs). |

---

## Host portal (#3)

| # | Screen | File | Backend wiring | Notes |
|---|--------|------|----------------|-------|
| H-shell | **Host bottom-nav shell** | `screens_host/home/main_screen.dart` | ✅ | Re-skinned `MainScreen` to the scaffold `host_shell` — `BottomAppBar` with a raised **center "Add Property" FAB** + 4 tabs (Dashboard/Bookings/Support/Profile). Kept `HostTabProvider` as the tab backbone (so drawer + add-property `resetToHome()` still drive it) and the drawer. Provider tab-ids→slots: 2=Dashboard, 3=Bookings, 6=Support, 5=Profile, 7=Invoices (drawer-only). FAB pushes the Add-Property flow. `/host/home` unchanged (still → MainScreen). |
| H-1 | Host Dashboard | `screens_host/home/host_home_screen.dart` | ✅ | Re-skinned to scaffold `host_dashboard` — in-body header (menu→drawer, aajoo·Host wordmark, chat→support, bell→notifications), greeting + initials avatar, **Total Earnings card** (sum of real `payAmount` → taps to Payouts), **2×2 stat grid** (Total Bookings / Ongoing Stays / Properties / Transactions — all real counts), ongoing-stays list (real ongoing bookings → ViewOngoingBooking), "List a new property" banner, recent transactions (kept). Fetches ongoing+properties+booking-history+transactions on load. |
| H-2..n | Bookings · Support · Profile · Add-Property · Payout · Invoices | (existing wired screens) | 🟡 | Reachable + wired (they power the shell tabs / drawer), but still on the **old skin** — teal palette applies globally (P0) but layouts not yet redesigned to the scaffold. Re-skin next, one per commit. |

## Open API gaps (finish later)

Each row is a component whose design exists but whose data/endpoint isn't ready.
Until resolved it uses the fallback in "Interim".

| ID | Where | What's missing | Interim | Owner |
|----|-------|----------------|---------|-------|
| G-1 | Onboarding / Login — "Continue with Google" | No Google/Firebase OAuth wired on mobile (BE-7 was superseded, never built). | Button routes to mobile/email login. Hide or wire Firebase later. | BE + Mobile |
| ~~G-2~~ RESOLVED | Property Details — specs row | **False alarm** — `GET /properties/:id` ALREADY returns `bathrooms`, `propDetails.propDetail_no_of_beds`, `propDetail_no_of_guests` (verified on prod: 3/3/6). The mobile model just wasn't parsing them. | ✅ Fixed on mobile: `SinglePropertyData`/`SinglePropertyDetails` now parse them + Property Details renders a real specs row. No BE change. | — |

---

## Notes
- **Path C means most screens are already wired** — we re-skin the UI and keep the existing GetX controller + service underneath, so the backend connection is preserved by default. This tracker exists to catch the exceptions (new scaffold screens, or scaffold features the backend doesn't cover).
- All backend endpoints already deployed on `aajaodev.onrender.com`.
