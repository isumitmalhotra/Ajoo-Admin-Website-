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

  /// What tapping the card does.
  ///
  /// The card draws a north-east arrow next to "Showing stays around X" — the
  /// standard "this goes somewhere" affordance — but had no gesture handler of
  /// any kind, so every tap on the most prominent element of the home screen
  /// did nothing. Reported as "when we click on the near by button its not
  /// working"; the button was never wired, not broken.
  ///
  /// Optional so the card stays usable as a passive banner if it is ever
  /// placed somewhere with nothing to open.
  final VoidCallback? onTap;

  /// Widen the search when nothing was found. Without it the empty state is a
  /// dead end — see the headline below.
  final VoidCallback? onWiden;

  /// The last search never reached the server.
  ///
  /// Without this the card reported a timeout as "No stays here yet" — telling
  /// the guest something about the place that was really about the network.
  final bool unreachable;

  const WeeklyHeroCard({
    super.key,
    this.homesNearby = 0,
    this.region = '',
    this.onTap,
    this.onWiden,
    this.unreachable = false,
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
    final card = _card();
    // With no results, tapping should widen the search — expanding a sheet
    // that has nothing in it is the one thing that definitely does not help.
    final action = homesNearby == 0 ? (onWiden ?? onTap) : onTap;
    if (action == null) return card;
    // Ink splash rather than a bare GestureDetector so the tap is visibly
    // acknowledged; the card paints its own gradient, so the ripple has to go
    // in front of it rather than behind.
    return Stack(
      children: [
        card,
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: action,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _card() {
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
            homesNearby > 0
                // "1 homes near you" — the count is real, the noun was not.
                // "near you" was true only until the guest searched somewhere
                // else, after which the card counted stays in Karnal and told
                // them the stays were near them in California. Naming the place
                // is right in both cases — unsearched, the region IS where they
                // are.
                ? region.isEmpty
                    ? '$_formattedCount ${homesNearby == 1 ? 'home' : 'homes'} near you.'
                    : '$_formattedCount ${homesNearby == 1 ? 'home' : 'homes'} in $region.'
                : unreachable
                    ? "Couldn't load stays."
                    // Nothing found. Saying "Homes near you." over an empty
                    // list claims stays exist that do not, and offered no way
                    // on.
                    : 'No stays here yet.',
            style: fraunces(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: kCream,
              height: 1.2,
            ),
          ),
          Text(
            homesNearby > 0
                ? 'No booking fee.'
                : unreachable
                    ? 'Check your connection.'
                    : 'Try a wider search.',
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
                  homesNearby == 0
                      ? (unreachable
                          ? 'The server did not respond. Tap to try again.'
                          : region.isEmpty
                              ? 'Nothing matched. Widen the radius or clear your filters.'
                              : 'Nothing around $region matched. Widen the radius or clear your filters.')
                      : region.isEmpty
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
