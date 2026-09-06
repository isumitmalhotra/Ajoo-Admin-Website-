import 'package:flutter/material.dart';

/// The room a bottom-anchored control needs to clear the device's navigation.
///
/// Three separate bugs came from the same shape — a button at the bottom of a
/// sheet or a scroll view with a hardcoded bottom padding:
///
///   * "Use this location" on the map picker
///   * "Upload N photos" on the photo description sheet
///   * "Delete My Account" at the end of Settings
///
/// All three sat under the gesture pill or the three-button bar and could not
/// be tapped. A fixed 16 or 18 is right on a phone with no navigation inset and
/// wrong on every phone that has one, which is most of them.
///
/// `MediaQuery.paddingOf` rather than `viewPaddingOf`, deliberately: `padding`
/// is what is left AFTER any enclosing SafeArea has taken its share, so calling
/// this inside a widget that is already inset adds nothing instead of insetting
/// twice. `viewPadding` reports the physical inset whether or not somebody has
/// already handled it, and using it here would push the button up by the height
/// of the navigation bar on the screens that were already correct.
double safeBottom(BuildContext context, {double base = 0}) =>
    base + MediaQuery.paddingOf(context).bottom;

/// [EdgeInsets] with the device's bottom inset added to [bottom].
EdgeInsets safeBottomInsets(
  BuildContext context, {
  double left = 0,
  double top = 0,
  double right = 0,
  double bottom = 0,
}) =>
    EdgeInsets.fromLTRB(left, top, right, safeBottom(context, base: bottom));
