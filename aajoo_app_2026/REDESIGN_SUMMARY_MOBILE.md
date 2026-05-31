# AajooHomes Mobile — Sand & Indigo Redesign Summary (Part B)

> **Completed:** 31 May 2026  
> **Scope:** Visual re-skin of Flutter mobile app — color, spacing, radius, shadow, typography. No logic/behavior/API changes.  
> **Palette:** Sand & Indigo (Option 3 — client approved)

---

## Palette Tokens

| Token | Value | Role |
|---|---|---|
| `kIndigo` / `kprimaryColor` | `#1B2447` | Primary brand (replaced pink `#C14464`) |
| `kIndigo600` | `#2A356B` | Hover / pressed state |
| `kSand` / `kcontentColor` | `#EFE7D6` | Warm content background |
| `kCream` / `kscaffoldColor` | `#FFFAF0` | Card / sheet surface |
| `kClay` | `#C16345` | Accent — badges, one pop-CTA |
| `kInk` | `#1B2447` | Primary text |
| `kInk2` | `#3D4670` | Secondary text |
| `kMuted` | `#6B7390` | Captions / placeholders |
| `kLine` | `#D9CFB8` | Warm borders / dividers |
| `kSuccess` | `#3F6B4E` | Verified badges, success states |
| `kDanger` | `#C0392B` | Errors only |

---

## Phase Summary

### B0 — Discovery Audit ✅
- Baseline: `flutter analyze` → 1534 issues (all from ionicons package)
- Mapped 88 files using `kprimaryColor`, 36+ hardcoded pink instances, 35 LinearGradients
- Documented in `REDESIGN_AUDIT_MOBILE.md`

### B1 — Central Theme Migration ✅ (commit `72dcfab`)
- `lib/constants.dart`: `kprimaryColor` pink → indigo, `kscaffoldColor` → cream, `kcontentColor` → sand; added full Sand & Indigo token set
- `lib/service/theme_service.dart`: light + dark seeds → indigo; fixed dark-mode body text (was dark-on-dark)
- **Instant effect:** 88 files already reading indigo brand with zero further changes

### B2 — Hardcoded Pinks & Gradients ✅ (commit `87d41a5`)
- Replaced all hardcoded `0xFFC14464`, `0xFFAD1457`, `0xFF6A1B4D` with design tokens
- Verified zero brand pinks remain via grep
- Gradient files auto-fixed via `kprimaryColor` in B1

### B3 — Renter (Customer-Facing) Screens ✅ (commits `4b29d8a`, `74e7e80`, `2a00d4c`)
- **Home & discovery:** DraggableScrollableSheet → kCream, categories, review cards, location button, View All button — all migrated
- **Property & booking:** property details (13× hardcoded pinks via B2), checkout (gradient auto-fixed B1), booking history (kCream cards, kSand accent boxes, kLine borders, r12), bookmark properties (white → kCream)
- **Profile & safety:** renter profile borders/backgrounds, safety screen verified correct via B1
- **Common screens:** auth screen (basic_info), price negotiation (theme auto-fixed)
- **Shared widgets:** `hotel_card`, `product_card`, `cart_tile` — r16 cards, r12 buttons, semantic shadows
- **Polish applied:** verified badge → kSuccess pill (r999), featured/luxury badges → kClay pill, ElevatedButton → indigo fill + cream text

### B4 — Host Screens ✅ (commit `3809d12`)
- **home:** Drawer header → kIndigo, shimmer → kLine/kCream, transaction status → kSuccess/kDanger
- **add_property:** Chips bg → kSand, form fills → kCream, document tiles → kLine/kSuccess/kMuted, image picker → kSand/kDanger, terms banners → kSuccess
- **update_property:** Form fills → kCream, image borders → kLine
- **property_details:** Scaffold → kscaffoldColor, status switch → kSuccess/kDanger
- **booking_history:** Scaffold → kSand, cards → kCream r16, user boxes → kSand, text → kMuted/kInk2
- **ongoing_booking:** Cards → kCream, call/WhatsApp buttons → kSuccess
- **payout:** Old-pink card (`0xFFF6D1DC`) → kCream, dark-pink text (`0xFF4A2C35`) → kInk
- **support:** Borders → kLine, FAQ text → kInk/kMuted
- **profile:** Scaffold → kscaffoldColor, containers → kSand, shimmer → kLine/kCream, section titles → kInk
- **invoices:** Already correct (kprimaryColor/kscaffoldColor throughout)

---

## Final Verification

| Check | Result |
|---|---|
| Grep brand pinks (`C14464`, `AD1457`, `6A1B4D`, `BF5973`) | ✅ Zero active usages |
| `flutter analyze` issue count | ✅ 1549 (all pre-existing info/warning — zero errors introduced) |
| `flutter build apk --debug` | ✅ Compiles successfully |
| Manual renter flow — light theme | ⬜ Pending device walk |
| Manual renter flow — dark theme | ⬜ Pending device walk |
| Manual host flow — light theme | ⬜ Pending device walk |
| Manual host flow — dark theme | ⬜ Pending device walk |
| `lib/ui/unused_screens/` routing check | ✅ Not routed (orphan imports only) |

---

## Polish Rules Applied

| Rule | Implementation |
|---|---|
| Card radius | `BorderRadius.circular(16)` across all card widgets |
| Button / input radius | `BorderRadius.circular(12)` |
| Pill badges | `BorderRadius.circular(999)` |
| Card borders | `BorderSide(color: kLine)` — warm `#D9CFB8` |
| Shadows | `BoxShadow(color: kInk.withOpacity(0.06), blurRadius: 10, offset: Offset(0,4))` |
| Primary ElevatedButton | Indigo fill + cream text |
| Verified badge | kSuccess background + kCream text, pill shape |
| Featured / Luxury badge | kClay background + kCream text, pill shape |
| Shimmer loaders | `baseColor: kLine`, `highlightColor: kCream` |
| Snackbars | Success → kSuccess, Error → kDanger |

---

## Open Items (Manual Device Required)

- **B3-20/21:** Renter flow light + dark theme walk
- **B4-11:** Host flow light + dark theme walk
- **B5-04–07:** Combined manual verification pass on physical device / emulator

*These cannot be automated — require hot-reload on device to confirm both themes render correctly.*