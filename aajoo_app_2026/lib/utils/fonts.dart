// AajooHomes mobile — typography helpers.
//
// Design-system pairing (matches the web + the new mobile design):
//   Plus Jakarta Sans (display) → headings, hero copy, property titles, wordmark
//   Manrope (body)    → all body, UI text, captions, prices, meta
//
// The helper NAMES (fraunces/inter/interTextTheme) are kept for backwards-compat
// across the app; only the underlying faces changed. BR-2 pairs Plus Jakarta
// Sans for display with Manrope for UI.
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
// Both families now ship inside the APK (~340 KB for the pair) and are chosen
// with a weight axis, so typography is identical everywhere and needs nothing
// from the network. They are variable fonts, hence `fontVariations`: naming a
// weight alone would render every style at the default instance.
import 'package:flutter/material.dart';

const String _display = 'PlusJakartaSans';
const String _body = 'Manrope';

/// The `wght` axis value for a Flutter FontWeight (w400 → 400).
List<FontVariation> _wght(FontWeight w) => [FontVariation('wght', w.value.toDouble())];

/// Plus Jakarta Sans — headings and brand text. (Helper name kept for compat.)
TextStyle fraunces({
  double? fontSize,
  FontWeight fontWeight = FontWeight.w600,
  Color? color,
  double letterSpacing = -0.02,
  double? height,
  FontStyle? fontStyle,
}) {
  return TextStyle(
    fontFamily: _display,
    fontVariations: _wght(fontWeight),
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
