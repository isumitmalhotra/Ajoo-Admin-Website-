// ============================================================================
//  AajooHomes — Sand & Indigo palette (MOBILE / Flutter)
//  Client-approved Option 3. Update lib/constants.dart during Phase B1.
//  Indigo 0xFF1B2447 replaces pink 0xffC14464 everywhere.
//  Because kprimaryColor is referenced by ~51 files, changing it once
//  propagates the new brand across most of the app instantly.
// ============================================================================

import 'package:flutter/material.dart';

// --- Existing constants, retargeted to Sand & Indigo ---
const kprimaryColor  = Color(0xFF1B2447); // indigo  (was 0xffC14464 pink)
const kscaffoldColor = Color(0xFFFFFAF0); // cream surface (was white) — verify readability
const kcontentColor  = Color(0xFFEFE7D6); // sand content bg (was 0xffF5F5F5)

// --- New canonical brand tokens ---
const kIndigo    = Color(0xFF1B2447); // PRIMARY
const kIndigo600 = Color(0xFF2A356B); // hover / pressed
const kSand      = Color(0xFFEFE7D6); // warm background
const kCream     = Color(0xFFFFFAF0); // card / sheet surface
const kClay      = Color(0xFFC16345); // ACCENT ONLY — one pop-CTA, "New" badges
const kClay600   = Color(0xFFA8512F); // clay pressed
const kInk       = Color(0xFF1B2447); // primary text
const kInk2      = Color(0xFF3D4670); // secondary text
const kMuted     = Color(0xFF6B7390); // captions, placeholders
const kLine      = Color(0xFFD9CFB8); // warm borders / dividers
const kSuccess   = Color(0xFF3F6B4E); // verified badges
const kDanger    = Color(0xFFC0392B); // errors only


/* ============================================================================
   THEME — update lib/service/theme_service.dart, BOTH light and dark.
   The M3 seed currently = 0xffBF5973 (pink). Change to 0xFF1B2447 (indigo)
   so the whole Material 3 scheme regenerates around the new brand.
   ============================================================================

   lightTheme:
     colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B2447)),
     primaryColor: kprimaryColor,                 // now indigo
     scaffoldBackgroundColor: kscaffoldColor,     // cream (or kSand on content screens)
     // keep fontFamily: 'Montserrat'

   darkTheme:
     colorScheme: ColorScheme.fromSeed(
       seedColor: const Color(0xFF1B2447),
       brightness: Brightness.dark,
     ),
     primaryColor: kprimaryColor,
     // IMPORTANT: old dark theme used the pink as bodyColor/displayColor.
     // Indigo is too dark on a dark background — switch dark-mode text to a
     // light tint so it stays readable:
     //   bodyColor: Colors.white,  displayColor: Colors.white,
     // Use indigo only for fills/accents in dark mode, not text.
   ============================================================================ */
