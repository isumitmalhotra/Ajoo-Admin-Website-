import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/models/host_booking_history_model.dart';
import 'package:rent_home/utils/fonts.dart';

/// Bookings over time, for the host dashboard.
///
/// A-72 asked for "the graph weekly and monthly bookings to the host". This is
/// built entirely from the booking history the dashboard ALREADY loads —
/// `book_added_at` is parsed into a DateTime on every row — so it needs no new
/// endpoint and no new request.
///
/// It draws nothing when there is nothing to draw. An empty chart with invented
/// bars would be the same fabrication as the "1,240 verified homes" card this
/// dashboard used to carry; a host with no bookings gets told they have no
/// bookings.
class BookingsTrendCard extends StatefulWidget {
  final List<HostBookingHistory> bookings;
  const BookingsTrendCard({super.key, required this.bookings});

  @override
  State<BookingsTrendCard> createState() => _BookingsTrendCardState();
}

enum _Range { weekly, monthly }

class _BookingsTrendCardState extends State<BookingsTrendCard> {
  _Range _range = _Range.monthly;

  /// Buckets, oldest → newest, each as (label, count).
  ///
  /// Weekly is the last 8 weeks, monthly the last 6 months. Both are anchored
  /// to today and include empty periods, because a gap IS the information — a
  /// chart that silently skips quiet weeks makes a bad month look busy.
  List<MapEntry<String, int>> get _buckets {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final now = DateTime.now();
    final dates = widget.bookings
        .map((b) => b.bookAddedAt)
        .whereType<DateTime>()
        .toList();

    if (_range == _Range.monthly) {
      return List.generate(6, (i) {
        final m = DateTime(now.year, now.month - (5 - i), 1);
        final next = DateTime(m.year, m.month + 1, 1);
        final n = dates.where((d) => !d.isBefore(m) && d.isBefore(next)).length;
        return MapEntry(months[m.month - 1], n);
      });
    }

    // Weeks run back from the start of today, seven days at a time.
    final today = DateTime(now.year, now.month, now.day);
    return List.generate(8, (i) {
      final start = today.subtract(Duration(days: 7 * (7 - i) + 6));
      final end = start.add(const Duration(days: 7));
      final n = dates.where((d) => !d.isBefore(start) && d.isBefore(end)).length;
      return MapEntry('${start.day}/${start.month}', n);
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = _buckets;
    final total = data.fold<int>(0, (s, e) => s + e.value);
    final max = data.fold<int>(0, (m, e) => e.value > m ? e.value : m);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Bookings',
                  style: fraunces(
                      fontSize: 16, fontWeight: FontWeight.w700, color: kInk)),
              const Spacer(),
              _toggle('Weekly', _Range.weekly),
              const SizedBox(width: 6),
              _toggle('Monthly', _Range.monthly),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            total == 0
                ? 'No bookings in this period yet.'
                : '$total booking${total == 1 ? '' : 's'} in the last '
                    '${_range == _Range.monthly ? '6 months' : '8 weeks'}',
            style: inter(fontSize: 12, color: kMuted),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 132,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((e) {
                // The bar takes whatever vertical space the two labels leave,
                // as a fraction of the tallest month. It used to be a fixed
                // 92px inside a 120px box, so the tallest column — count
                // label + bar + month label — came to about 126px and Flutter
                // painted "BOTTOM OVERFLOWED BY 10 PIXELS" across the chart on
                // any host whose busiest month set the scale. Proportional
                // means it cannot overflow at any text scale.
                final factor = max == 0
                    ? 0.04
                    : (e.value == 0 ? 0.04 : (e.value / max).clamp(0.08, 1.0));
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (e.value > 0)
                        Text('${e.value}',
                            style: inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: kInk2)),
                      const SizedBox(height: 3),
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: factor,
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: e.value == 0 ? kLine : kIndigo600,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(e.key,
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: inter(fontSize: 9.5, color: kMuted)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggle(String label, _Range value) {
    final on = _range == value;
    return GestureDetector(
      onTap: () => setState(() => _range = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: on ? kIndigo50 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: on ? kIndigo600 : kLine),
        ),
        child: Text(label,
            style: inter(
                fontSize: 11,
                fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                color: on ? kIndigo600 : kMuted)),
      ),
    );
  }
}
