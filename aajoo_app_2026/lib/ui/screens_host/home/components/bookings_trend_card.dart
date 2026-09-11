import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/utils/fonts.dart';

/// Bookings over time, for the host dashboard.
///
/// A-72 asked for "the graph weekly and monthly bookings to the host".
///
/// It is drawn from one timestamp per booking (`/host/booking-dates`), not
/// from the booking list. It USED to read the list the dashboard loaded; the
/// dashboard then stopped loading the list — it only needed the count — and
/// this card, still reading it, drew "No bookings in this period yet." for
/// every host from then on. Found 2026-09-11 on a host with five bookings
/// that month. The dates are the only thing the chart needs, and they are
/// a few hundred bytes for any host.
///
/// It draws nothing when there is nothing to draw. An empty chart with invented
/// bars would be the same fabrication as the "1,240 verified homes" card this
/// dashboard used to carry; a host with no bookings gets told they have no
/// bookings.
class BookingsTrendCard extends StatefulWidget {
  /// When each booking was made.
  final List<DateTime> dates;
  const BookingsTrendCard({super.key, required this.dates});

  @override
  State<BookingsTrendCard> createState() => _BookingsTrendCardState();
}

enum _Range { weekly, monthly }

class _BookingsTrendCardState extends State<BookingsTrendCard> {
  _Range _range = _Range.monthly;

  List<MapEntry<String, int>> get _buckets =>
      bucketBookingDates(widget.dates, monthly: _range == _Range.monthly);

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

/// Buckets, oldest → newest, each as (label, count).
///
/// Weekly is the last 8 weeks, monthly the last 6 months. Both are anchored
/// to [now] and include empty periods, because a gap IS the information — a
/// chart that silently skips quiet weeks makes a bad month look busy.
///
/// Timestamps arrive in UTC from the server and are bucketed in the device's
/// local day, which is what "this month" means to the person holding it.
List<MapEntry<String, int>> bucketBookingDates(
  List<DateTime> raw, {
  required bool monthly,
  DateTime? now,
}) {
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  final at = now ?? DateTime.now();
  final dates = raw.map((d) => d.toLocal()).toList();

  if (monthly) {
    return List.generate(6, (i) {
      final m = DateTime(at.year, at.month - (5 - i), 1);
      final next = DateTime(m.year, m.month + 1, 1);
      final n = dates.where((d) => !d.isBefore(m) && d.isBefore(next)).length;
      return MapEntry(months[m.month - 1], n);
    });
  }

  // Weeks run back from the start of today, seven days at a time.
  final today = DateTime(at.year, at.month, at.day);
  return List.generate(8, (i) {
    final start = today.subtract(Duration(days: 7 * (7 - i) + 6));
    final end = start.add(const Duration(days: 7));
    final n = dates.where((d) => !d.isBefore(start) && d.isBefore(end)).length;
    return MapEntry('${start.day}/${start.month}', n);
  });
}
