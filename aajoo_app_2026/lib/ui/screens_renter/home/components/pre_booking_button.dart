import 'package:flutter/material.dart';

import 'package:rent_home/ui/design/aajoo_skin.dart';
import 'package:rent_home/utils/fonts.dart';

/// The way in to Pre-Booking, from the home screen.
///
/// WHAT WAS WRONG WITH IT
///
/// It was a full-width teal slab: a top-left-to-bottom-right gradient, a 14px
/// radius, and a coloured drop shadow of its own — sitting immediately beside
/// the LUX switch, which is a glowing gold pill with a sheen that sweeps
/// across it twice a second. Two controls at maximum weight, side by side,
/// with nothing between them to say which one matters. On a screen that
/// already carries a search bar, a category row and a trust bar above the
/// fold, it read as noise.
///
/// The client's reference app has one button shape (its `BrandButton`): a
/// 12px radius, a 1.5px brand rule, Manrope 14.5/w600, no gradient and no
/// shadow — filled when it is the page's main action, outlined when it is a
/// way to somewhere else. Pre-Booking is the second kind: it opens another
/// screen, it is not the thing this screen is for. So it is the outlined one,
/// and the row now has exactly one loud control in it — the mode switch,
/// which earns it by changing the whole screen.
///
/// It also takes the skin. The slab stayed teal in LUX while the sheet behind
/// it, the trust bar beside it and every rail below it had gone to black and
/// gold, which is the single most visible piece of "LUX changes nothing".
class PreBookingButton extends StatelessWidget {
  const PreBookingButton({super.key, required this.skin, required this.onTap});

  final AajooSkin skin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            // A surface, not a fill. In LUX that is the same faint lift of
            // light the site lays over its cards rather than a painted panel.
            color: skin.isLux ? null : skin.surface,
            gradient: skin.cardGradient,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: skin.primary, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_available_outlined,
                  size: 18, color: skin.primary),
              const SizedBox(width: 8),
              Text(
                'Pre-Booking',
                style: inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: skin.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
