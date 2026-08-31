// The checkout-hour rule is the bug that was reported on the web ("still shows
// Currently Staying after an 11 AM checkout"), so it gets a test rather than a
// glance. Times below are IST converted to UTC (IST = UTC+5:30).
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/utils/stay_clock.dart';

void main() {
  _stayRangeTests();
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

/// How a stay's dates are written, on both portals.
///
/// The host booking list printed the raw server strings, and those are not
/// consistently padded — the same card read "06-10-2026 → 7-10-2026". The
/// guest list had a formatter privately all along. They are the same app and
/// should not disagree about what a date looks like, so it lives in
/// stay_clock.dart and both call it.
void _stayRangeTests() {
  group('stayRange', () {
    test('an unpadded day formats the same as a padded one', () {
      // The pair that made the bug visible on the host booking card.
      expect(stayRange('06-10-2026', '7-10-2026'), '6 – 7 Oct 2026');
    });

    test('a range inside one month names the month once', () {
      expect(stayRange('20-10-2026', '24-10-2026'), '20 – 24 Oct 2026');
    });

    test('a range crossing a month names both', () {
      expect(stayRange('30-08-2026', '01-09-2026'), '30 Aug – 1 Sep 2026');
    });

    test('a range crossing a year carries the year on both sides', () {
      expect(stayRange('30-12-2026', '02-01-2027'), '30 Dec 2026 – 2 Jan 2027');
    });

    test('an unparseable date falls back to what the server sent', () {
      // A date the reader can see beats a tidy blank.
      // The fallback path formats each side with shortStayDate, which is
      // 'd MMM' — no year, because it is used for single dates too.
      expect(stayRange('not-a-date', '01-09-2026'), 'not-a-date – 1 Sep');
    });

    test('a null pair does not throw', () {
      expect(stayRange(null, null), '— – —');
    });
  });
}
