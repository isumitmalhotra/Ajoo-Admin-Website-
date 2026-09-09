import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A checkout day is not a night.
///
/// Reported from the live site: nights 10 and 11 were sold, and a guest trying
/// to book the 9th found NO selectable checkout. The 10th was struck through,
/// so a one-night stay on the 9th — a stay that takes nobody else's room —
/// could not be expressed at all. The guest leaves on the morning of the 10th;
/// the next one arrives that afternoon.
///
/// The picker was stricter than the server it was protecting. The server's
/// overlap guard is half-open on both ends:
///
///     bt_book_from < :to AND bt_book_to > :from
///
/// which accepts 9 → 10 against a booking of [10, 12).
///
/// The two ends of the range ask DIFFERENT questions, and that is the whole
/// fix:
///
///   check-in  — is this day itself a night somebody has?   `_isBookedDay`
///   check-out — would a stay ENDING here run through one?  `_checkoutBlocked`
///
/// Reverting either one brings the symptom straight back and nothing else in
/// the suite notices, so it is pinned here.
void main() {
  final source = File(
    'lib/ui/screens_renter/property_details/property_page.dart',
  ).readAsStringSync();

  test('the two pickers ask different questions', () {
    // Substrings, not patterns: the escapes in a regex written into this file
    // have been mangled before, and a broken pattern here fails OPEN.
    expect(
      source.contains('!_isBookedDay(d) &&'),
      isTrue,
      reason: 'the check-in picker no longer refuses booked nights',
    );
    expect(
      source.contains('!_checkoutBlocked(selectedDate, d) &&'),
      isTrue,
      reason: 'the checkout picker is back to greying out any booked day, so a '
          'stay ending on the first night of the next booking cannot be chosen',
    );
  });

  test('the checkout rule is half-open on both ends', () {
    final at = source.indexOf('bool _checkoutBlocked(');
    expect(at, greaterThan(0), reason: '_checkoutBlocked is gone');
    final body = source.substring(at, at + 420);
    expect(
      body.contains('a.isBefore(r.end) && b.isAfter(r.start)'),
      isTrue,
      reason: "this must mirror the server's guard exactly; anything with <= or "
          '>= on either end refuses a same-day turnover the server allows',
    );
    expect(
      body.contains('if (!b.isAfter(a)) return _isBookedDay(d);'),
      isTrue,
      reason: 'a day on or before the arrival restarts the range, so it must '
          'keep the plain test and never land on a night somebody has',
    );
  });

  test('the picker cannot open on a checkout it would reject', () {
    // showDatePicker ASSERTS that initialDate satisfies the predicate, so a
    // remembered checkout that is no longer valid crashes rather than being
    // corrected. _safeInitialDate cannot do this job — it only skips days that
    // are themselves booked, and this rule also rejects days that merely run
    // THROUGH a booking.
    expect(
      source.contains('_safeCheckoutDate(selectedDateTo, selectedDate)'),
      isTrue,
      reason: 'the checkout picker opens on a date its own predicate may refuse',
    );
    final at = source.indexOf('DateTime _safeCheckoutDate(');
    expect(at, greaterThan(0), reason: '_safeCheckoutDate is gone');
    expect(
      source.substring(at, at + 700).contains('_checkoutBlocked(from, d)'),
      isTrue,
      reason: 'the safe date is chosen with the wrong rule',
    );
  });

  /// The arithmetic itself, so the comparison above is not merely present but
  /// correct. Mirrors _checkoutBlocked; if that changes, change this.
  test('9 to 10 is allowed against a booking of 10 to 12', () {
    bool crosses(DateTime a, DateTime b, List<DateTimeRange> booked) =>
        booked.any((r) => a.isBefore(r.end) && b.isAfter(r.start));

    DateTime d(int n) => DateTime(2026, 9, n);
    final booked = [DateTimeRange(start: d(10), end: d(12))];

    expect(crosses(d(9), d(10), booked), isFalse,
        reason: 'the one-night stay the live site refused');
    expect(crosses(d(9), d(11), booked), isTrue,
        reason: 'that would take the night of the 10th');
    expect(crosses(d(12), d(14), booked), isFalse,
        reason: 'arriving the morning they leave is a turnover, not a clash');
    expect(crosses(d(8), d(13), booked), isTrue,
        reason: 'a range cannot swallow a stay whole');
  });
}
