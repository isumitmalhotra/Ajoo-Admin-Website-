// A stay runs for at most one MONTH — the real length of the month it starts
// in (client rule, 2026-09-05). The server refuses anything longer, so the
// picker has to stop the guest before they choose it and the price has to be
// worked out against the same month, or the app quotes a figure the booking
// endpoint will not accept.
//
// The same arithmetic exists in the backend's utils/preBooking.js and the
// website's redesign/lib/stayLength.ts. Three copies, one behaviour: this
// pins the app's.
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/utils/nightly_rates.dart';
import 'package:rent_home/utils/stay_length.dart';

void main() {
  group('how long a month is', () {
    test('follows the month the stay starts in', () {
      expect(maxNightsFrom(DateTime(2026, 1, 5)), 31, reason: 'January');
      expect(maxNightsFrom(DateTime(2026, 4, 5)), 30, reason: 'April');
      expect(maxNightsFrom(DateTime(2026, 2, 5)), 28, reason: 'February');
      expect(maxNightsFrom(DateTime(2024, 2, 5)), 29, reason: 'a leap year');
    });

    test('gets the century rule right', () {
      // Divisible by 100 is not a leap year unless it is also divisible by 400.
      expect(isLeapYear(2000), isTrue);
      expect(isLeapYear(1900), isFalse);
      expect(isLeapYear(2024), isTrue);
      expect(isLeapYear(2026), isFalse);
    });

    test('the last checkout is the check-in plus that month', () {
      expect(latestCheckout(DateTime(2026, 1, 1)), DateTime(2026, 2, 1));
      expect(latestCheckout(DateTime(2026, 2, 1)), DateTime(2026, 3, 1));
      expect(latestCheckout(DateTime(2024, 2, 1)), DateTime(2024, 3, 1));
      // Mid-month check-ins run a month from where they start, not to a
      // month boundary.
      expect(latestCheckout(DateTime(2026, 1, 20)), DateTime(2026, 2, 20));
    });
  });

  group('the host long-stay rate uses that same month', () {
    // A rate card with both long-stay prices set.
    final rule = PricingRule(
      base: 5000,
      weekendPricing: false,
      weeklyPrice: 30000,
      monthlyPrice: 105000,
    );

    test('a full month gets the monthly rate, one night short does not', () {
      // January needs 31.
      expect(rule.longStayFor(31, from: DateTime(2026, 1, 1))?.label, 'Monthly rate');
      expect(rule.longStayFor(30, from: DateTime(2026, 1, 1))?.label, 'Weekly rate');
      // April needs 30.
      expect(rule.longStayFor(30, from: DateTime(2026, 4, 1))?.label, 'Monthly rate');
      // February needs 28, and 29 in a leap year.
      expect(rule.longStayFor(28, from: DateTime(2026, 2, 1))?.label, 'Monthly rate');
      expect(rule.longStayFor(28, from: DateTime(2024, 2, 1))?.label, 'Weekly rate');
      expect(rule.longStayFor(29, from: DateTime(2024, 2, 1))?.label, 'Monthly rate');
    });

    test('the monthly price is divided by that month, not by a constant', () {
      // 105,000 over 31 nights in January…
      final jan = rule.longStayFor(31, from: DateTime(2026, 1, 1))!;
      expect(jan.nightlyRate, closeTo(105000 / 31, 0.001));
      // …and over 28 in February.
      final feb = rule.longStayFor(28, from: DateTime(2026, 2, 1))!;
      expect(feb.nightlyRate, closeTo(105000 / 28, 0.001));
    });

    test('with no start date it falls back, exactly as the server does', () {
      // Some callers have a night count and no dates. 28 is the fallback on
      // both sides, so neither invents a month it cannot know.
      expect(rule.longStayFor(28)?.label, 'Monthly rate');
    });

    test('a week still needs seven nights, and no long-stay price means none', () {
      expect(rule.longStayFor(7, from: DateTime(2026, 1, 1))?.label, 'Weekly rate');
      expect(rule.longStayFor(6, from: DateTime(2026, 1, 1)), isNull);
      final bare = PricingRule(base: 5000, weekendPricing: false);
      expect(bare.longStayFor(31, from: DateTime(2026, 1, 1)), isNull);
    });
  });
}
