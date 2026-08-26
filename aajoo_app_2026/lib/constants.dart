import 'package:flutter/material.dart';

// --- Brand palette: BR-4, matching the web design system.
//     Evergreen Teal #0F766E / Golden Amber #E8A317 / Warm Ivory #FAF8F4 /
//     Charcoal Navy #1F2937.
//     Token NAMES are kept (kIndigo/kClay/kSand) for backwards-compat across
//     ~88 files — only the VALUES change. kIndigo == teal, kClay == amber.
//     Anything drawn ON kClay must use kAccentInk: white on Golden Amber is
//     2.17:1 and unreadable, where the navy is 6.77:1.
const kprimaryColor  = Color(0xFF0F766E); // Evergreen Teal
const kscaffoldColor = Color(0xFFFAF8F4); // Warm Ivory
const kcontentColor  = Color(0xFFF2EFE9); // soft warm content background

// --- Teal & Orange brand tokens (names legacy, values current) ---
const kIndigo    = Color(0xFF0F766E); // PRIMARY brand — Evergreen Teal
const kIndigo600 = Color(0xFF115E59); // hover / pressed — deep teal
// Lightest teal wash — chips, callouts, selected pills. This replaced the
// pre-migration 0xFFE6F5F3, which was the OLD palette's tint and survived the
// brand change hardcoded in eight screens.
const kIndigo50  = Color(0xFFEFFAF8);
const kSand      = Color(0xFFFAF8F4); // Warm Ivory background
const kCream     = Color(0xFFFAF8F4); // card / sheet surface (Warm Ivory)
const kClay      = Color(0xFFE8A317); // ACCENT — Golden Amber, one pop-CTA / "New" badges
const kClay600   = Color(0xFFD4930F); // amber pressed
/// What is legible ON kClay. White on Golden Amber is 2.17:1 — unreadable in
/// daylight — where this navy is 6.77:1. The note above has always said so;
/// the token itself was missing, so every amber button used white regardless.
const kAccentInk = Color(0xFF1F2937);
const kInk       = Color(0xFF1F2937); // primary text — Charcoal Navy
const kInk2      = Color(0xFF334155); // secondary text — slate
const kMuted     = Color(0xFF64748B); // captions, placeholders
const kLine      = Color(0xFFEAE4DA); // warm borders / dividers
const kSuccess   = Color(0xFF15803D); // verified badges / success text
const kDanger    = Color(0xFFDC2626); // errors only

// --- Status tints ---
// The pale ground a status message sits on. Named so a screen never reaches
// for Colors.red[50] again: the negotiation screens carried 97 raw Material
// colours, including a BLUE panel on a teal-and-amber product, because there
// was no token to reach for instead.
const kSuccessBg = Color(0xFFEAF6EE);
const kDangerBg  = Color(0xFFFDECEC);
const kWarningBg = Color(0xFFFDF3E2);
/// Readable amber text — the raw Golden Amber is too light on white.
const kWarningText = Color(0xFF92650F);

// --- Elevation / surface system (premium depth) ---
// Cards use a WHITE surface so they lift off the cream background, with a soft
// 2-layer navy-tinted shadow.
const Color kSurface = Color(0xFFFFFFFF); // elevated card / sheet surface
const List<BoxShadow> kCardShadow = [
  BoxShadow(color: Color(0x140F172A), blurRadius: 22, offset: Offset(0, 10)),
  BoxShadow(color: Color(0x0A0F172A), blurRadius: 4, offset: Offset(0, 2)),
];
const List<BoxShadow> kSoftShadow = [
  BoxShadow(color: Color(0x0F0F172A), blurRadius: 12, offset: Offset(0, 4)),
];
