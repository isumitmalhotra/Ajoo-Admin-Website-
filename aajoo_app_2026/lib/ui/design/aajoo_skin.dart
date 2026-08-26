// The app's colour tokens, resolved for the mode that is on.
//
// WHY A RESOLVER AND NOT MORE CONSTANTS
//
// The website skins LUXE by re-pointing the same CSS variables the classic
// skin uses (`html[data-lux]{--ink:…;--line:…}`), so every component built on
// tokens re-dresses without being touched. Dart has no cascade to re-point:
// kInk and kLine are `const`, ~130 files read them directly, and a mode switch
// cannot change what a const means.
//
// So the tokens become a lookup instead. A surface asks `AajooSkin.of(lux)`
// and paints from the answer; classic returns the constants it already used,
// LUXE returns the website's LUXE values — the SAME hexes, read out of
// styles/aajoo-system.css, so the two platforms are the same near-black and
// the same gold rather than two designers' idea of "dark and gold".
//
// Screens opt in, deliberately. The portals (host, admin) keep the classic
// skin whatever the preference says, exactly as the site suspends `data-lux`
// inside a dashboard.
import 'package:flutter/material.dart';

import 'package:rent_home/constants.dart';
import 'package:rent_home/utils/lux_mode.dart';

@immutable
class AajooSkin {
  const AajooSkin({
    required this.isLux,
    required this.page,
    required this.sheet,
    required this.surface,
    required this.surfaceHigh,
    required this.ink,
    required this.muted,
    required this.mutedLight,
    required this.line,
    required this.lineSoft,
    required this.primary,
    required this.onPrimary,
    required this.primaryWash,
    required this.accent,
    required this.onAccent,
    required this.placeholder,
    required this.shadow,
  });

  final bool isLux;

  /// The ground the screen sits on.
  final Color page;

  /// The draggable sheet / bottom surface over the map.
  final Color sheet;

  /// A raised card.
  final Color surface;

  /// A control sitting on a card.
  final Color surfaceHigh;

  final Color ink;
  final Color muted;
  final Color mutedLight;
  final Color line;
  final Color lineSoft;

  /// Carries actions and links. Teal in classic, gold in LUXE.
  final Color primary;

  /// What is legible ON [primary] — white on teal, near-black on gold. Gold
  /// with white text is 1.9:1; this is the token that stops that happening.
  final Color onPrimary;

  /// The lightest tint of [primary] — chips, selected pills, icon wells.
  final Color primaryWash;

  final Color accent;
  final Color onAccent;

  /// Hint text inside inputs.
  final Color placeholder;

  final List<BoxShadow> shadow;

  /// Classic — Evergreen Teal on Warm Ivory. These are the same constants the
  /// app has always drawn with, just reachable by name.
  static const AajooSkin classic = AajooSkin(
    isLux: false,
    page: kSand,
    sheet: kCream,
    surface: kSurface,
    surfaceHigh: kCream,
    ink: kInk,
    muted: kMuted,
    mutedLight: Color(0xFF94A3B8),
    line: kLine,
    lineSoft: Color(0xFFF1ECE3),
    primary: kIndigo,
    onPrimary: Colors.white,
    primaryWash: kIndigo50,
    accent: kClay,
    onAccent: kInk,
    placeholder: kMuted,
    shadow: kSoftShadow,
  );

  /// LUXE — the website's `html[data-lux]` block, value for value.
  ///
  /// Note `page` is #0A0A0C and `surface` #141416, NOT the warm browns this
  /// app used before (#12100C / #1C1813). The site tried warm and the comment
  /// in aajoo-system.css records why it moved: against gold the browns read
  /// muddy rather than luxe. Matching it here is the point of this batch.
  static const AajooSkin lux = AajooSkin(
    isLux: true,
    page: Color(0xFF0A0A0C),
    sheet: Color(0xFF0F0F11),
    surface: Color(0xFF141416),
    surfaceHigh: Color(0xFF1A1A1D),
    ink: Color(0xFFF2F0EA),
    muted: Color(0xFFA6A39C),
    mutedLight: Color(0xFF77746D),
    // rgba(212,175,55,.24) and .11 — gold hairlines, quiet enough not to tint
    // the surface they sit on.
    line: Color(0x3DD4AF37),
    lineSoft: Color(0x1CD4AF37),
    primary: Color(0xFFD4AF37),
    onPrimary: Color(0xFF1A1508),
    primaryWash: Color(0x1FD4AF37),
    accent: Color(0xFFD4AF37),
    onAccent: Color(0xFF1A1508),
    placeholder: Color(0xFF6E6656),
    shadow: [
      BoxShadow(color: Color(0x8C000000), blurRadius: 34, offset: Offset(0, 10)),
    ],
  );

  static AajooSkin of(bool isLux) => isLux ? lux : classic;

  /// A card's fill.
  ///
  /// In LUXE the site does not paint cards a solid colour — it lays a faint
  /// lift of light over the black ground (`rgba(255,255,255,.055)` →
  /// `.028`), which is what keeps a card from reading as a brown box. Same
  /// gradient here; classic gets its flat white.
  Gradient? get cardGradient => isLux
      ? const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x0EFFFFFF), Color(0x07FFFFFF)],
        )
      : null;

  /// Everything a card needs, in the mode that is on.
  BoxDecoration card({double radius = 18, bool shadowed = true}) =>
      BoxDecoration(
        color: isLux ? null : surface,
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: isLux ? line : lineSoft),
        boxShadow: shadowed ? shadow : null,
      );
}

/// Rebuilds its child whenever the LUXE preference changes, handing down the
/// resolved skin.
///
/// This is the app's `useLux()`. Wrapping a screen in one means the mode
/// switch re-dresses it immediately, from anywhere — which is the whole
/// difference between a preference and the per-screen booleans this replaced.
class LuxBuilder extends StatelessWidget {
  const LuxBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, AajooSkin skin) builder;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: LuxMode.instance.on,
        builder: (context, on, _) => builder(context, AajooSkin.of(on)),
      );
}
