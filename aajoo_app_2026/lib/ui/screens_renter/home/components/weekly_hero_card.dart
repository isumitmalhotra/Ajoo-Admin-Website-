import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/utils/fonts.dart';

/// AajooHomes home hero card.
///
///   ┌───────────────────────────────────────────────────┐
///   │  NEARBY                                           │
///   │  128 homes near you.                              │
///   │  No booking fee.                                  │
///   │                                                   │
///   │  ↗  Showing stays around Kharar                   │
///   └───────────────────────────────────────────────────┘
///
/// This card used to read "1,240 verified homes" and "18 new in Goa this week"
/// — both hardcoded defaults, rendered on every device regardless of where the
/// user was or what was actually listed. Its own comment admitted it: "V1 takes
/// hard-coded values; later this can be wired to a stats API."
///
/// There is no stats API. So it shows the two things that ARE real — how many
/// homes the search actually returned, and where the user actually is — and the
/// invented "new this week" figure is gone rather than guessed. Nothing reports
/// it, and a number nobody can source is worse than no number.
class WeeklyHeroCard extends StatelessWidget {
  /// How many homes the nearby search returned. 0 while it is still loading.
  final int homesNearby;

  /// Resolved place name; empty until the geocoder answers.
  final String region;

  const WeeklyHeroCard({
    super.key,
    this.homesNearby = 0,
    this.region = '',
  });

  String get _formattedCount {
    final s = homesNearby.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kIndigo, kIndigo600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: kInk.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overline
          Text(
            region.isEmpty ? 'NEARBY' : region.toUpperCase(),
            style: inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: kCream.withOpacity(0.7),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          // Headline — two lines, Fraunces
          Text(
            homesNearby > 0 ? '$_formattedCount homes near you.' : 'Homes near you.',
            style: fraunces(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: kCream,
              height: 1.2,
            ),
          ),
          Text(
            'No booking fee.',
            style: fraunces(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: kCream,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          // Stat row
          Row(
            children: [
              Icon(
                Icons.north_east,
                size: 16,
                color: kCream.withOpacity(0.85),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  region.isEmpty
                      ? 'Finding stays around you…'
                      : 'Showing stays around $region',
                  style: inter(
                    fontSize: 13,
                    color: kCream.withOpacity(0.85),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
