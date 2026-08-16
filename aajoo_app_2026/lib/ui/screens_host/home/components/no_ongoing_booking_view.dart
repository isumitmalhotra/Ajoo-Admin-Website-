import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/utils/fonts.dart';

/// Host home — shown in place of the ongoing-booking card when there is none.
///
/// Was a 30px grey [Icon] above one line of muted text, which read as a
/// rendering failure rather than a deliberate empty state: the largest thing
/// on a host's dashboard, on the day they have no guests, was a tiny grey
/// glyph.
///
/// Uses `assets/hotel.json` — a travel animation already bundled and already
/// paid for, but not referenced anywhere until now. Preferred over the
/// existing empty-state PNGs because those are not interchangeable:
/// `noProperty.png` has "No properties found" baked into the artwork, and
/// `noreview.png` is explicitly about reviews. Reusing either would have put a
/// caption on screen that contradicts the one below it.
///
/// The second line matters as much as the picture — an empty dashboard should
/// say what to do next, not just that it is empty.
class NoOngoingBookingView extends StatelessWidget {
  const NoOngoingBookingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/hotel.json',
              height: 150,
              repeat: true,
              // A still first frame if the animation cannot be decoded, so the
              // block degrades to a gap rather than to a red error box.
              errorBuilder: (_, __, ___) => const SizedBox(height: 150),
            ),
            const SizedBox(height: 12),
            Text(
              "No ongoing bookings",
              style: inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: kInk,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "When a guest checks in, their stay shows up here.",
              textAlign: TextAlign.center,
              style: inter(fontSize: 13, color: kMuted),
            ),
          ],
        ),
      ),
    );
  }
}
