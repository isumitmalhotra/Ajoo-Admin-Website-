// AajooHomes mobile — typography helpers.
//
// Design-system pairing — the client's reference app:
//   Poppins (display) → headings, hero copy, property titles, wordmark
//   Manrope (body)    → all body, UI text, captions, prices, meta
//
// The display face was Plus Jakarta Sans. The reference app the client shared
// sets Poppins for display and Manrope for body (its core/app_theme.dart), and
// asked for its typography rather than ours; Manrope already matched, so only
// the display face moved. Both are geometric sans, so this is a change of
// voice, not of metrics — nothing reflows.
//
// The helper NAMES (fraunces/inter/interTextTheme) are kept for backwards-compat
// across the ~130 files that call them; only the underlying faces change, so
// the whole app re-sets from this one file rather than 130 edits that can
// drift.
//
// THE FONTS ARE BUNDLED, NOT DOWNLOADED.
//
// These used to come from the `google_fonts` package, which fetches the .ttf
// from fonts.gstatic.com at runtime and caches it. That put a network request
// between the app and its own text on every fresh install: on a slow or
// filtered connection the first screens rendered in a fallback face and then
// reflowed, and with no connection at all the logs filled with unhandled
// "Failed host lookup: fonts.gstatic.com" exceptions. On older handsets with
// stale root certificates the request can fail outright, every time.
//
// Both families now ship inside the APK (~800 KB all told) and are chosen
// with a weight axis, so typography is identical everywhere and needs nothing
// from the network. Manrope is a variable font, hence `fontVariations` on the
// body helper: naming a weight alone would render every style at the default
// instance. Poppins is static and takes plain `fontWeight` — see below.
import 'package:flutter/material.dart';

const String _display = 'Poppins';
const String _body = 'Manrope';

/// The `wght` axis value for a Flutter FontWeight (w400 → 400).
List<FontVariation> _wght(FontWeight w) => [FontVariation('wght', w.value.toDouble())];

/// Poppins — headings and brand text. (Helper name kept for compat.)
///
/// Poppins ships as static weights, so there is no `fontVariations` here:
/// naming a wght axis on a font that has none is silently ignored, and the
/// weight has to come from `fontWeight` picking the registered file. Passing
/// both is how you end up with every heading rendering at 400.
TextStyle fraunces({
  double? fontSize,
  FontWeight fontWeight = FontWeight.w600,
  Color? color,
  double letterSpacing = 0,
  double? height,
  FontStyle? fontStyle,
}) {
  return TextStyle(
    fontFamily: _display,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
    fontStyle: fontStyle,
  );
}

/// Manrope — body, UI, and meta text. (Helper kept named `inter` for compat.)
TextStyle inter({
  double? fontSize,
  FontWeight fontWeight = FontWeight.w400,
  Color? color,
  double? letterSpacing,
  double? height,
}) {
  return TextStyle(
    fontFamily: _body,
    fontVariations: _wght(fontWeight),
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );
}

/// Manrope text theme — base text theme inside ThemeData.
/// (Helper kept named `interTextTheme` for compat.)
TextTheme interTextTheme([TextTheme? base]) {
  final theme = base ?? ThemeData.light().textTheme;
  return theme.apply(fontFamily: _body);
}
