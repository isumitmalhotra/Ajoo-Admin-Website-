import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/ui/screens_host/home/components/bookings_trend_card.dart';

/// The dashboard's bookings chart counts the bookings that were made.
///
/// It drew "No bookings in this period yet." for a host with five bookings
/// that month (2026-09-11). It had been built from the booking list the
/// dashboard loaded; the dashboard later stopped loading that list — it only
/// needed the count — and the chart, still reading it, went empty for every
/// host and stayed that way. It now takes the dates themselves.
void main() {
  final now = DateTime(2026, 9, 11, 7, 0);

  test('five bookings this month land in September', () {
    final dates = [
      DateTime.utc(2026, 9, 6, 13, 35),
      DateTime.utc(2026, 9, 8, 22, 27),
      DateTime.utc(2026, 9, 9, 1, 8),
      DateTime.utc(2026, 9, 9, 1, 45),
      DateTime.utc(2026, 9, 10, 18, 33),
    ];
    final m = bucketBookingDates(dates, monthly: true, now: now);
    expect(m.map((e) => e.key), ['Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep']);
    expect(m.last.value, 5, reason: 'the chart says there are no bookings');
    expect(m.take(5).map((e) => e.value), everyElement(0));
  });

  test('no dates is an honest empty chart, not a crash', () {
    final m = bucketBookingDates(const [], monthly: true, now: now);
    expect(m.fold<int>(0, (s, e) => s + e.value), 0);
  });

  test('weekly: eight weeks ending today, a booking in each of the last two',
      () {
    final w = bucketBookingDates(
      [DateTime(2026, 9, 10), DateTime(2026, 9, 2)],
      monthly: false,
      now: now,
    );
    expect(w.length, 8);
    expect(w[7].value, 1, reason: 'a booking yesterday is not this week');
    expect(w[6].value, 1);
    expect(w.take(6).map((e) => e.value), everyElement(0));
  });

  test('a booking from seven months ago is outside the window', () {
    final m =
        bucketBookingDates([DateTime(2026, 2, 1)], monthly: true, now: now);
    expect(m.fold<int>(0, (s, e) => s + e.value), 0);
  });
}
