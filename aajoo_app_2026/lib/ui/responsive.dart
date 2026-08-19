// Making the app usable on a tablet, not just tolerable.
//
// Every screen here was laid out for a phone: a single column that fills the
// width. On a 10" tablet that column is ~1300px wide, so a booking card
// stretches its photo into a letterbox strip, a line of body text runs past
// 150 characters, and the "View details" button ends up a hand's width from
// the price it belongs to. Nothing is broken, exactly — it just reads like a
// blown-up phone screen, which is what the client saw.
//
// Two ideas cover almost all of it:
//   * cap the reading width and centre it, so a column stays a column;
//   * let grids ask how many columns actually fit instead of assuming one.
//
// Both are no-ops on a phone: below the tablet breakpoint every helper returns
// exactly what the phone layout already did, so this cannot regress the
// handset experience it is meant to leave alone.
import 'package:flutter/material.dart';

/// Layout breakpoints, by shortest side.
///
/// Shortest side, not width — otherwise a phone in landscape claims to be a
/// tablet and gets the wide layout on a 400px-tall screen.
abstract class Breakpoints {
  static const double tablet = 600;
  static const double desktop = 1000;
}

extension ResponsiveContext on BuildContext {
  double get _shortest => MediaQuery.of(this).size.shortestSide;

  bool get isTablet => _shortest >= Breakpoints.tablet;
  bool get isDesktop => _shortest >= Breakpoints.desktop;
  bool get isPhone => !isTablet;

  /// How many cards fit comfortably across, given a target card width.
  ///
  /// Phones always get 1: a two-up grid on a 360px screen gives each card
  /// 170px, which is narrower than the text inside them needs.
  int gridColumns({double target = 380, int max = 3}) {
    if (isPhone) return 1;
    final width = MediaQuery.of(this).size.width;
    final fits = (width / target).floor();
    return fits.clamp(1, max);
  }
}

/// Centres content and caps how wide it is allowed to grow.
///
/// [maxWidth] defaults to 720 — wide enough for two cards side by side at a
/// comfortable size, narrow enough that a paragraph does not run away.
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({
    super.key,
    required this.child,
    this.maxWidth = 720,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    // On a phone this adds nothing — no extra widget in the tree, no change
    // in layout, so the handset path is exactly what it was.
    if (context.isPhone) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
