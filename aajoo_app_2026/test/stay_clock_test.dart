// The checkout-hour rule is the bug that was reported on the web ("still shows
// Currently Staying after an 11 AM checkout"), so it gets a test rather than a
// glance. Times below are IST converted to UTC (IST = UTC+5:30).
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/utils/stay_clock.dart';

void main() {
  // 10 Aug 2026, 10:00 IST  ->  04:30 UTC
  final beforeCheckout = DateTime.utc(2026, 8, 10, 4, 30);
  // 10 Aug 2026, 12:00 IST  ->  06:30 UTC  (checkout was 11:00 IST)
  final afterCheckout = DateTime.utc(2026, 8, 10, 6, 30);

  test('parses the DD-MM-YYYY the API returns', () {
    expect(parseStayDate('10-08-2026'), DateTime.utc(2026, 8, 10));
    expect(parseStayDate('1-8-2026'), DateTime.utc(2026, 8, 1));
    expect(parseStayDate(''), isNull);
    expect(parseStayDate(null), isNull);
  });

  test('still staying at 10 AM on the checkout day', () {
    expect(isStaying('08-08-2026', '10-08-2026', now: beforeCheckout), isTrue);
    expect(hasEnded('10-08-2026', now: beforeCheckout), isFalse);
  });

  test('NOT staying at 12 PM on the checkout day — the reported bug', () {
    expect(hasEnded('10-08-2026', now: afterCheckout), isTrue);
    expect(isStaying('08-08-2026', '10-08-2026', now: afterCheckout), isFalse);
  });

  test('a stay that has not begun is upcoming, not ongoing', () {
    expect(isUpcoming('20-08-2026', now: beforeCheckout), isTrue);
    expect(isStaying('20-08-2026', '25-08-2026', now: beforeCheckout), isFalse);
  });

  test('check-in is 2 PM, so the morning of arrival is not yet staying', () {
    // 08 Aug 2026, 09:00 IST -> 03:30 UTC
    final arrivalMorning = DateTime.utc(2026, 8, 8, 3, 30);
    expect(isStaying('08-08-2026', '10-08-2026', now: arrivalMorning), isFalse);
    // 08 Aug 2026, 15:00 IST -> 09:30 UTC
    final arrivalAfternoon = DateTime.utc(2026, 8, 8, 9, 30);
    expect(isStaying('08-08-2026', '10-08-2026', now: arrivalAfternoon), isTrue);
  });

  test('unparseable dates never claim a stay is active', () {
    expect(isStaying('not-a-date', 'nonsense'), isFalse);
  });
}
