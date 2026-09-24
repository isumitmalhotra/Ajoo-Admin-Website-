import 'dart:math' as math;

import 'package:flutter/material.dart';

/// How much room a bottom sheet must leave below its last control.
///
/// Two different things can cover the bottom of a modal sheet and they are
/// reported separately:
///
///   * `viewInsets.bottom`  — the **keyboard**. Zero when it is closed.
///   * `viewPadding.bottom` — the **system navigation bar** (and the home
///     indicator on a gesture-navigation phone). Constant, keyboard or not.
///
/// Handling only the first is the trap. It looks correct while a text field
/// has focus and drops the sheet's button underneath the navigation bar the
/// moment the keyboard closes — which is how "Save guest" on the traveller
/// sheet and "Apply" on the search sheet became unreachable (tester,
/// 2026-09-23), and how five other sheets in this app were one screenshot
/// away from the same report.
///
/// `max` rather than a sum: when the keyboard is up it already covers the
/// navigation bar, so adding them would leave a visible gap above the
/// keyboard. When it is down, `viewInsets.bottom` is 0 and the navigation bar
/// is what matters.
double sheetBottomInset(BuildContext context) {
  final mq = MediaQuery.of(context);
  return math.max(mq.viewInsets.bottom, mq.viewPadding.bottom);
}

/// [sheetBottomInset] with a little breathing room, for a sheet whose last
/// control would otherwise sit flush against the navigation bar.
double sheetBottomInsetWith(BuildContext context, {double extra = 12}) =>
    sheetBottomInset(context) + extra;
