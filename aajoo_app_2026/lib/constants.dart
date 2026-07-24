import 'package:flutter/material.dart';

// --- Brand palette: Ocean Teal & Sunset Orange (matches the web design system:
//     --primary #0D9488 / --accent #FF7A00 / cream #FDF7F0). Token NAMES are kept
//     (kIndigo/kClay/kSand) for backwards-compat across ~88 files — only the
//     VALUES changed from the old Sand & Indigo. kIndigo == teal, kClay == orange.
const kprimaryColor  = Color(0xFF0D9488); // Ocean Teal (was indigo #1B2447)
const kscaffoldColor = Color(0xFFFDF7F0); // warm ivory / cream surface
const kcontentColor  = Color(0xFFF1ECE3); // soft warm content background

// --- Teal & Orange brand tokens (names legacy, values current) ---
const kIndigo    = Color(0xFF0D9488); // PRIMARY brand — Ocean Teal
const kIndigo600 = Color(0xFF0A6E63); // hover / pressed — deep teal
const kSand      = Color(0xFFF1ECE3); // warm background
const kCream     = Color(0xFFFDF7F0); // card / sheet surface (cream)
const kClay      = Color(0xFFFF7A00); // ACCENT — Sunset Orange, one pop-CTA / "New" badges
const kClay600   = Color(0xFFE4670A); // orange pressed
const kInk       = Color(0xFF0F172A); // primary text — Navy
const kInk2      = Color(0xFF334155); // secondary text — slate
const kMuted     = Color(0xFF64748B); // captions, placeholders
const kLine      = Color(0xFFEAE4DA); // warm borders / dividers
const kSuccess   = Color(0xFF15803D); // verified badges / success text
const kDanger    = Color(0xFFDC2626); // errors only

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
