# Session handoff — 10 October 2026 — iOS UI pass, store screenshots, build 124

For Sumit, the morning after. Written by the Claude Code session on the Mac
that ran the night of 9–10 October. Account ids only; no keys, passwords,
document numbers or contact details appear here or in the commit.

The single list of open work is still `MASTER_PENDING_TASKS.md`; §5 below is
what this session leaves open, for adding there.

---

## 1. At a glance

| | |
|---|---|
| Commit | the commit that adds this file — `git log -1 --format=%H -- SESSION_HANDOFF_2026-10-10_IOS.md`. Its parent is `0c73c7a` (the 123 bump). |
| Version | `pubspec.yaml` → `1.0.0+124`, both platforms, one commit. |
| iPhone only | From 124 (Sumit's decision, 10 October): `TARGETED_DEVICE_FAMILY = 1` in all three build configurations of `ios/Runner.xcodeproj/project.pbxproj` (was `"1,2"`), in this same commit, so the 124 binary no longer advertises iPad. `tool/verify_release_ipa.py` now fails any build whose `UIDeviceFamily` is not `[1]` (it flags 123's `[1, 2]`), and `test/the_app_is_iphone_only_test.dart` holds the project file to it. Allowed because no build was ever released on the App Store with iPad support. |
| iOS 124 | built from this commit with the live Razorpay key, no `--allow-test-payments`, archived and left in the Xcode Organizer. Not uploaded by the session (the CLI upload has no App Store Connect access; the Organizer upload works). A commit cannot describe a build of itself, so the archive's path and the verifier's result (which must include `UIDeviceFamily` `[1]` and version `1.0.0+124`) are reported in the session, not here. |
| Android 124 | **Build it on Windows** from this same commit (`tool/build_release.ps1`). This Mac has the Android SDK but not the Play upload key (`android/key.properties` is absent), so a release AAB from here would be unsigned and Play would refuse it. Play upload stays Sumit's call. |
| Earlier builds | iOS 115 (client repo `eaa258b`, test key — retired, cannot ship), iOS 122 (`c0a1016`, test key — cannot be submitted), iOS 123 (`0c73c7a`, live key — on TestFlight, has none of the fixes below). Android 121 is in Play review and lacks the bathroom fix (`adaf5b4`); Android 123 was deliberately not shipped. |
| App Store | nothing submitted for review; the listing was not touched by the session. |
| Tests | 745 pass, 0 fail, 0 skipped — full `flutter test`, run before the commit (728 before this session's last 17). Eleven new test files: ten listed against their defects in §2, plus the iPhone-only test above. |

## 2. Defects found in the UI pass, and what happened to each

Found on the iOS Simulator (iPhone 18 Pro Max, iOS 27, debug build, test
Razorpay key, renter session), guest flow first. Every fix is in shared Dart,
so each one applies to Android too, and each was checked at narrow widths
(down to a 320-wide phone) as well as on the iPhone. No colours or design
language were changed.

Each fix's test was shown to **fail with the old code put back** and pass
with the fix, then the file was restored byte for byte. "Re-checked on the
device" means the same screen was looked at again on the Simulator after the
fix was running there.

| # | What was wrong | What changed | How it was verified | Status |
|---|---|---|---|---|
| D1 | `CuratedCard` overflowed its fixed 268 height on the home rails — the cancellation badge used the last spare pixel, and any larger text size broke it. Same in the Saved grid (aspect ratio 0.72). | `CuratedCard.extentFor()` measures the card's height from the real fonts, theme and text size, plus 8 px headroom; `property_slider.dart` and `bookmark_properties_page.dart` use it. Price and rating scale down rather than overflow sideways. | `test/a_card_fits_the_height_it_asks_for_test.dart` — 36 cases, text ×1.0/1.3/2.0 at card widths 140/160/200, real fonts loaded; fails with the old 268. Re-checked on the device on the rail and the Saved grid. | Fixed |
| D2 | Property 6's four photos are AVIF, and a client without an AVIF decoder shows its "not supported" placeholder for them. | `lib/utils/cloudinary_url.dart`: `deliverableImageUrl()` inserts `f_auto` into Cloudinary image URLs, applied in every model that carries photos. Cloudinary then serves a format the client can decode (curl from the Mac confirmed JPEG for Dart's HttpClient). | `test/a_cloudinary_image_is_always_decodable_test.dart` — 6 cases. **On iOS 27 the original AVIF also decoded**: iOS has decoded AVIF natively since iOS 16. So on iOS this matters for iOS 15 (the minimum) only; on Android it matters below Android 12. | Fixed |
| D3 | Kharar and Kasauli show the same cover photo. | Nothing in code: the two cover files are byte-identical (SHA-256 `f5451b8c…`), i.e. the same photo was uploaded to both. | Hashes compared. | **Open — content** |
| D4 | The save heart on home-rail cards (Featured, Stays near you, Trending) did nothing: `PropertySlider` never passed `onFavoriteTap`. | The rail now calls `BookmarkService().toggleBookmark`, the call the pre-booking card already used (`onToggleSaved` is a seam for tests). | `test/a_rail_heart_saves_the_stay_test.dart` — 2 cases. Re-checked on the device: Kasauli saved from the rail, then listed in Saved Stays. | Fixed |
| D5 | Every `Get.snackbar` threw "No Overlay" on Flutter 3.44: GetX 4.6.6's `overlayContext` returns the `_Theater` element, which 3.44's `Overlay.maybeOf` no longer accepts. | `get: ^4.7.3` (it uses `Get.key.currentState?.overlay`). `pubspec.lock` changes `get` only. | `test/a_getx_snackbar_actually_shows_test.dart` fails on 4.6.6 with "No Overlay". Because GetX is not a leaf dependency here, `test/an_obx_panel_opens_when_its_page_rebuilds_test.dart` pins the booking panel's Obx-inside-setState shape with a real tap. Re-checked on the device: an async snackbar shows. | Fixed — see §5 residual risk |
| D6 | The ongoing-booking parser threw a cast exception when `book_price` arrived as text — `(json["book_price"] as num?)` — so the renter's ongoing stay did not show. | `_money(json["book_price"])?.round() ?? 0`. | `test/an_ongoing_booking_with_a_text_price_still_parses_test.dart` — 2 cases. Re-checked on the device: the "Staying now" banner and the Ongoing tab show the Kasauli booking. | Fixed |
| D7 | Saved Stays shows no photos. Backend: `UserSavedProperties` (`controllers/user.controller.js:1184`, backend `main` at `9dbb4bf`) skips `methods.getAttchedProperties`, which every other listing endpoint calls. | Nothing — backend not touched without approval. | Traced in the backend source. | **Open — backend** |
| D8 | Four-up amenity labels were cut at one line and 64 wide: "Fire exting…", "Dining tab…". | `lib/widgets/amenity_row.dart`: two lines, the label's quarter of the row (56–84), and at large text sizes the label grows only as far as its longest word still fits. | `test/an_amenity_label_is_not_cut_test.dart` — 7 cases (the old layout failed 6 with "was cut"). Re-checked on the device ("Fire extinguisher" on two lines). | Fixed |
| D9 | Content under the status bar looked unprotected. | — | It is the intended frosted effect. | Withdrawn |
| D10 | The default check-in date is taken once and goes stale after midnight in a long-running session, which wrongly puts the page into pre-booking and hides the offer button. | Nothing yet. | Seen on the device; a restart clears it. | **Open** |
| D11 | The cancellation policy states a refund deadline already in the past for a same-day stay. | Nothing yet. | Seen on the device. | **Open** |
| D12 | The home screen's FAQ cards hid their own tap ripple: the tile painted it on the page beneath the card's white fill. Flutter flagged it ("ListTile background color or ink splashes may be invisible"). | `home_faq_strip.dart`: the tile gets its own transparent Material inside the card, clipped to its corners. The support screens' FAQ cards were already fine (an `ExpansionTile` given a `shape` makes its own Material) and are unchanged. | `test/a_faq_tap_shows_its_ripple_test.dart` — all three FAQ cards; the home card fails with the fix removed. Re-checked on the device: five cards, no warning, look unchanged. | Fixed |
| D13 | `liteModeEnabled: true` on the listing's area map and the booking's stay map. google_maps_flutter asserts lite mode is Android-only, so every iOS **debug** build drew an error box there. Release iOS ignored it; Android was unaffected. | `liteModeEnabled: Platform.isAndroid` in `property_tabs.dart` and `stay_map.dart`. | `test/a_lite_map_is_android_only_test.dart` (fails on the old code, naming both sites). Re-checked on the device: the Location tab map draws, no exception. The stay map was not reachable on the device once the test booking ended; the test covers it. | Fixed |
| S1 | **Security.** Three network loggers printed in **release** builds, to the device log (Console on iOS, logcat on Android): `user_service.dart` (the bearer token on every call; a password change's current and new password), `forgot_password_service.dart` (the reset OTP, reset token and new password), `checkout_page.dart` (the bearer token). The other six already had `enabled: kDebugMode` (`79e1dff`). In every build shipped so far, both platforms. | All three use `DioConfig.logger()`. | `test/a_request_is_never_logged_in_a_release_build_test.dart` holds every `PrettyDioLogger` in `lib/` to `enabled: kDebugMode` and bans Dio's `LogInterceptor`; it named exactly those three sites on the old code. | Fixed in 124 |

Kept **out** of the commit on purpose: `view_ongoing_booking_page.dart`,
`booking_controller.dart` and `map_screen.dart` differ from `HEAD` in line
endings only (CRLF), not in code; and the five deleted `.apk` files in
`aajoo_app_2026/`.

## 3. Store screenshots (1.0.0, build 124 code)

Green Hills Kasauli (property 5) is the only listing in any shot; Kharar (7)
and Ramnagar (6) were kept out of frame. Simulator location 30.90129,
76.96488; status bar 9:41; debug build, test key, no payment completed.
RGB PNG, no alpha.

On the Mac:

- iPhone 6.9" (1320 × 2868): `~/Desktop/Aajoo-AppStore-Screenshots-1.0.0-124/iPhone-6.9in/`
  - `01-home-kasauli.png`, `02-property-green-hills-kasauli.png`,
    `04-checkout-total-and-payment.png`, `05-my-trips-completed.png`
  - `06-host-calendar.png` — Kasauli's host calendar, November, signed in as
    its host (user 12). October and the host Bookings list were not used:
    both show the guest's name, and the Bookings list their phone number.
  - `03-make-an-offer.png` — the real Send an Offer sheet, opened by the
    listing's own Negotiate button once negotiation was switched on for
    Kasauli (and to be switched off again afterwards). Nothing was sent.
  - 01 and 05 were retaken on 10 October after the 9–10 October Kasauli
    stay ended: the first versions showed its "Staying now" state. If those
    were already uploaded, replace them.
- Alternate: `~/Desktop/Aajoo-AppStore-Screenshots-1.0.0-124/alternates/iPhone-02b-property-rooms.png`
- No iPad set: the app is iPhone only from 124.

For Windows, the same files are on the throwaway branch **`shots-124`**
(history of its own, images only, never to be merged). Delete the branch once
the upload is done.

## 4. Secrets — how they were handled

- `ios/Runner/Info.plist` keeps its placeholders in git. The Maps key and
  Google client ID are filled at build time by `tool/ios_local_secrets.sh`
  from `~/.aajoo/ios.env` and the git-ignored `ios/Runner/GoogleService-Info.plist`,
  then restored; `git status` was checked to not list `Info.plist` before the commit.
- The live Razorpay key was read from the production web bundle and passed to
  the build script only. It is in no file in the repository.
- Simulator work used the test key only.

## 5. Open — for `MASTER_PENDING_TASKS.md`

1. **D7 (backend):** add `getAttchedProperties` to `UserSavedProperties` so
   Saved Stays has photos. Needs a go-ahead; then the backend repo.
2. **D3 (content):** upload Kasauli's or Kharar's own cover photo.
3. **D10:** take the default check-in date fresh when the listing opens,
   not once per session.
4. **D11:** for a same-day stay, do not state a refund deadline that has passed.
5. **N1:** in-app API calls took ~20 s on the Simulator where curl from the
   same Mac took ~0.5 s (TTFB 0.24–0.43 s). Suspect Dart `HttpClient`
   connection reuse (one `Dio()` per service, each with its own pool, after
   idle). Investigate after the store work.
6. **GetX residual risk (D5):** if a snackbar ever throws, GetX's snackbar
   queue stays blocked until the app restarts, so later snackbars silently
   do not show. If GetX 4.7.3 ever proves a real regression, the agreed
   fallback is to revert to 4.6.6 and reopen D5.
7. **Debug-only logging to tidy:** `profile_screen.dart:794` logs the user's
   KYC record (document number included) and `checkout_page.dart:199` logs
   the bearer token. Both are debug-only (`appLog` and the `logger` package's
   default filter), so neither reaches a release build, but neither should be
   printed at all.
8. `flutter test` prints "unable to find directory entry in pubspec.yaml:
   assets/images/" — pre-existing and harmless; the directory is listed but absent.

## 6. Notes for the next session on this Mac

- **8 GB RAM.** Run one simulator at a time; two at once is what hung
  CoreSimulator on 9 October. Never erase the iPhone simulator — its keychain
  holds the sign-in.
- **A relaunched debug app runs the installed bundle, not the working tree.**
  After `xcrun simctl launch` + `flutter attach`, do a hot **restart** (a hot
  reload can report "0 libraries" and change nothing), then confirm the
  running sources match disk.
- The Simulator was driven through the Dart VM service (expression
  evaluation over the WebSocket), not injected gestures: open listings with
  `openPropertyById`, switch tabs through the page's own state, schedule any
  `setState`/`jumpTo` with `Future.delayed` so it does not land mid-frame.
  Store captures are `xcrun simctl io <device> screenshot`, flattened to RGB.
- zsh does not word-split an unquoted `$VAR`; run multi-file shell loops
  under bash with arrays.
