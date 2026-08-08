import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/utils/fonts.dart';

/// AajooHomes weekly hero card — matches the POC mobile "this week" block.
///
///   ┌───────────────────────────────────────────────────┐
///   │  THIS WEEK                                        │
///   │  1,240 verified homes.                            │
///   │  No booking fee.                                  │
///   │                                                   │
///   │  ↗  18 new in Goa this week                       │
///   └───────────────────────────────────────────────────┘
///
/// Dark indigo gradient (kIndigo → kIndigo600), cream typography.
/// V1 takes hard-coded values; later this can be wired to
/// `commonController` / a stats API.
class WeeklyHeroCard extends StatelessWidget {
  final int verifiedCount;
  final int newThisWeek;
  final String region;

  const WeeklyHeroCard({
    super.key,
    this.verifiedCount = 1240,
    this.newThisWeek = 18,
    this.region = 'Goa',
  });

  String get _formattedVerified {
    final s = verifiedCount.toString();
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
            'THIS WEEK',
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
            '$_formattedVerified verified homes.',
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
                  '$newThisWeek new in $region this week',
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
