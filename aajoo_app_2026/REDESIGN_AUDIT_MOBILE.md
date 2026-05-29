# AajooHomes Mobile — Redesign Audit (Phase B0)

> **Date:** 30 May 2026  
> **App:** Flutter / Dart (`aajoo_app_2026/`)  
> **Palette target:** Sand & Indigo — replace pink `0xffC14464` with indigo `0xFF1B2447`

---

## 1. Baseline (`flutter analyze`)

**Pre-existing issues: 1534** (all `info` level — almost entirely naming conventions in `packages/ionicons/lib/ionicons.dart`; none in `lib/`).  
**Our rule:** We must not increase this count. Zero new errors or warnings introduced by redesign.

---

## 2. Color Inventory

### 2a. `kprimaryColor` — 86 files inherit this automatically

Changing `kprimaryColor` in `lib/constants.dart` once flips all 86 files.

**Current value:** `const kprimaryColor = Color(0xffC14464);`  
**Target value:** `const kprimaryColor = Color(0xFF1B2447);` (indigo)

### 2b. Hardcoded brand pinks (bypass `kprimaryColor` — must fix manually)

| File | Hex | Occurrences | Action |
|---|---|---|---|
| `lib/screens/property_page.dart` | `0xFFAD1457` | 13 | → `kIndigo` (legacy screen, duplicate of ui version) |
| `lib/screens/sample_homepage.dart` | `0xffC14464` | 1 | → `kIndigo` (legacy screen) |
| `lib/ui/screens_host/payout/components/plan_overview_card.dart` | `0xFF6A1B4D` | 1 | → `kIndigo` |
| `lib/ui/screens_host/payout/payout_page.dart` | `0xFF6A1B4D` | 3 | → `kIndigo600` (shadow/gradient accent) |
| `lib/ui/screens_renter/property_details/property_page.dart` | `0xFFAD1457` | 13 | → `kIndigo` |
| `lib/ui/unused_screens/sample_homepage.dart` | `0xffC14464` | 1 | Commented out — skip |

### 2c. Theme seed hardcodes (in `lib/service/theme_service.dart`)

| Location | Current | Target |
|---|---|---|
| `lightTheme.colorScheme.seedColor` | `0xffBF5973` | `0xFF1B2447` |
| `lightTheme.primaryColor` | `0xffC14464` | `kprimaryColor` |
| `darkTheme.colorScheme.seedColor` | `0xffBF5973` | `0xFF1B2447` |
| `darkTheme bodyLarge/Medium/Small color` | `kprimaryColor` (pink) | `Colors.white` ⚠️ |

> **⚠️ Dark mode risk:** Dark theme currently sets body text to `kprimaryColor` (pink). With indigo, that would render dark-on-dark (unreadable). Must switch to `Colors.white` or a cream tint.

---

## 3. Gradient Inventory

20 active files contain `LinearGradient`. Those using brand pinks:

| File | Lines | Action |
|---|---|---|
| `lib/screens/Home/view_ongoing_booking.dart` | 82, 116 | Re-cast to `kIndigo → kIndigo600` |
| `lib/screens/Host/payout_page.dart` | 133, 391 | Re-cast to `kIndigo → kIndigo600` |
| `lib/screens/Host/view_ongoing_booking_page.dart` | 63 | Re-cast |
| `lib/screens/profile_screen.dart` | 1223 | Re-cast |
| `lib/screens/checkout_page.dart` | 314 | Chrome only — re-cast, don't touch payment logic |
| `lib/screens/property_page.dart` | 1867 | Re-cast |
| `lib/ui/screens_common/price_negotiation/negotitaion_page.dart` | 504, 1014 | Re-cast |
| `lib/ui/screens_host/ongoing_booking/view_ongoing_booking_page.dart` | 63 | Re-cast |
| `lib/ui/screens_host/payout/payout_page.dart` | 109, 378 | Re-cast |
| `lib/ui/screens_renter/checkout/checkout_page.dart` | 314 | Chrome only |
| `lib/ui/screens_renter/home/view_ongoing_booking.dart` | 87, 118 | Re-cast |
| `lib/ui/screens_renter/profile/profile_screen.dart` | 1250 | Re-cast |
| `lib/ui/screens_renter/property_details/property_page.dart` | 1941 | Re-cast |
| `lib/widgets/negotitaion_page.dart` | 506, 965, 1363 | Re-cast |

*Map screen gradients (`map_screen.dart`) are shader/canvas paints — chrome only, keep as-is unless brand pink.*

---

## 4. Theme Wiring Confirmed

```
main.dart
  └─ Get.put(ThemeService())
       └─ lib/service/theme_service.dart
            ├─ lightTheme  (seed: 0xffBF5973 → needs 0xFF1B2447)
            └─ darkTheme   (seed: 0xffBF5973 → needs 0xFF1B2447; body text pink → white)

lib/constants.dart
  ├─ kprimaryColor  (referenced by 86 files)
  ├─ kscaffoldColor (white → cream 0xFFFFFAF0)
  └─ kcontentColor  (light gray → sand 0xFFEFE7D6)
```

---

## 5. Risk Register

| Risk | Files | Severity | Mitigation |
|---|---|---|---|
| Dark mode body text (pink on dark bg) | `theme_service.dart` | **HIGH** | Switch darkTheme body text to `Colors.white` in B1 |
| `kprimaryColor` in conditionals | `notification_screen.dart`, `profile_screen.dart`, `view_ongoing_booking.dart`, `update_profile_screen.dart`, `terms_condition_user_page.dart` | LOW | Safe — changing the color value, not the condition logic |
| Checkout page gradients | `checkout_page.dart` (screens + ui) | MEDIUM | Restyle chrome only; payment handler lines untouched |
| Map screen shader paints | `map_screen.dart` (screens + ui) | LOW | Verify colors used aren't brand pink; keep shader logic untouched |
| `lib/screens/` legacy folder | Multiple files | LOW | These are old duplicates of `lib/ui/` screens. Update for completeness but they may not be routed. |

---

## 6. Summary — What B1 Fixes for Free

Changing **2 files** (`constants.dart` + `theme_service.dart`) propagates the new brand to **86 files** instantly. Remaining manual work (B2) covers ~5 active files with hardcoded pinks.

**Audit complete. Ready for Phase B1.**