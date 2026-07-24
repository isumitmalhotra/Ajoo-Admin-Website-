// AajooHomes mobile — typography helpers.
//
// Design-system pairing (matches the web + the new mobile design):
//   Poppins (display) → headings, hero copy, property titles, brand wordmark
//   Manrope (body)    → all body, UI text, captions, prices, meta
//
// The helper NAMES (fraunces/inter/interTextTheme) are kept for backwards-compat
// across the app; only the underlying faces changed to Poppins/Manrope.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Poppins — headings and brand text. (Helper kept named `fraunces` for compat.)
TextStyle fraunces({
  double? fontSize,
  FontWeight fontWeight = FontWeight.w600,
  Color? color,
  double letterSpacing = -0.02,
  double? height,
  FontStyle? fontStyle,
}) {
  return GoogleFonts.poppins(
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
  return GoogleFonts.manrope(
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
  return GoogleFonts.manropeTextTheme(base);
}
