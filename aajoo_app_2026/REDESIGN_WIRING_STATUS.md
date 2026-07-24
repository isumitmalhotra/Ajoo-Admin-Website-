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

---

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
