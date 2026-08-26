import 'package:flutter/material.dart';

import 'package:rent_home/constants.dart';
import 'package:rent_home/data/models/ongoing_reponse.dart';
import 'package:rent_home/ui/design/aajoo_skin.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/utils/stay_clock.dart';

/// The guest's own stay, on the home screen.
///
/// WHY THIS EXISTS
///
/// The slot beside the search bar showed a stay only while the guest was
/// physically in it — OngoingBookingWidget filters on `isStaying`, which is
/// true between 2 PM on the arrival day and 11 AM on the departure day and
/// false every other minute. So a guest who had just booked somewhere for next
/// month saw nothing there at all: the single most personal thing the app
/// knows about them, invisible until the day they arrived. "When I booked the
/// property, show the ongoing booking here."
///
/// This shows the stay that is happening OR the next one coming, and says
/// which — "Staying now" against "In 12 days". A booking made ten seconds ago
/// appears immediately.
///
/// It is also on the design system rather than the old card's grey shadows and
/// 24pt bold, because it sits over the map next to the search pill and has to
/// belong to the same screen.
class StayBanner extends StatelessWidget {
  const StayBanner({super.key, required this.booking, required this.onTap});

  final Booking booking;
  final VoidCallback onTap;

  /// The stay that deserves the slot: the one in progress, else the soonest
  /// one still to come. Null when the guest has neither.
  static Booking? pick(List<Booking> all) {
    final live = all.where((b) => isStaying(
          b.bookDetails?.btBookFrom,
          b.bookDetails?.btBookTo,
        ));
    if (live.isNotEmpty) return live.first;

    final upcoming = all
        .where((b) =>
            isUpcoming(b.bookDetails?.btBookFrom) &&
            !(b.bookingStatusBsTitle.toLowerCase().contains('cancel')))
        .toList()
      ..sort((a, b) {
        final x = _start(a), y = _start(b);
        if (x == null) return 1;
        if (y == null) return -1;
        return x.compareTo(y);
      });
    return upcoming.isEmpty ? null : upcoming.first;
  }

  static DateTime? _start(Booking b) => checkInAt(b.bookDetails?.btBookFrom);

  bool get _live => isStaying(
        booking.bookDetails?.btBookFrom,
        booking.bookDetails?.btBookTo,
      );

  /// "Staying now", "Tomorrow", "In 12 days" — never a bare date, because the
  /// question a guest asks of this card is "how soon?", not "what date?".
  String get _when {
    if (_live) return 'Staying now';
    final start = _start(booking);
    if (start == null) return 'Upcoming stay';
    final days = start.difference(DateTime.now().toUtc()).inDays;
    if (days <= 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    return 'In $days days';
  }

  @override
  Widget build(BuildContext context) {
    return LuxBuilder(
      builder: (context, skin) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: skin.isLux ? skin.surface : kSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: skin.line),
              boxShadow: skin.shadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: skin.primaryWash,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _live ? Icons.hotel_outlined : Icons.event_available_outlined,
                    size: 19,
                    color: skin.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: _live ? kSuccess : skin.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _when,
                              style: inter(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: _live
                                      ? Colors.white
                                      : skin.onPrimary),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              booking.bookingPropertyPropertyName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: fraunces(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: skin.ink),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if ((booking.bookDetails?.btBookFrom ?? '').isNotEmpty)
                            '${booking.bookDetails!.btBookFrom} → '
                                '${booking.bookDetails!.btBookTo}',
                          if (booking.bookIsCod && !booking.bookIsPaid)
                            'Pay at property',
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: inter(fontSize: 11.5, color: skin.muted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: skin.muted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
