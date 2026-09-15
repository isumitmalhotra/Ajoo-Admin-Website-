// The host's minimum and maximum stay are applied in the picker, and said.
//
// Client, 2026-09-15, on QA Sunrise Villa (their own listing, minimum stay
// 2 nights): "I'm checking in on the 16th, the 17th is blocked, so I choose
// check-out on the 18th — but that's not possible, right? From the host's
// side there is no booking and nothing blocked on the 17th." There was no
// block: the website's calendar had greyed the 17th as a CHECK-OUT because
// 16→17 is one night and the host asks for two, and said so under the
// calendar. This app read neither limit from checkInWindow — a guest could
// pick 16→17 here and be refused at booking — so the two platforms
// described one rule two ways.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/service/booking_service.dart';

void main() {
  final win = CheckInWindow(minNights: 2, maxNights: 14);
  final in16 = DateTime(2026, 9, 16);

  test("THE CLIENT'S CASE: after a 16th check-in the earliest check-out is the 18th", () {
    expect(win.firstCheckout(in16), DateTime(2026, 9, 18));
    expect(win.lastCheckout(in16), DateTime(2026, 9, 30));
  });

  test('no limits set means no limits', () {
    const none = CheckInWindow();
    expect(none.firstCheckout(in16), isNull);
    expect(none.lastCheckout(in16), isNull);
    expect(none.stayRule, '');
  });

  test('the rule is said in the same words as the website', () {
    expect(win.stayRule, 'Minimum stay 2 nights. Up to 14 nights.');
    expect(const CheckInWindow(minNights: 2).stayRule, 'Minimum stay 2 nights.');
    expect(const CheckInWindow(maxNights: 5).stayRule, 'Up to 5 nights.');
  });

  test('the page reads both limits and applies them to the check-out picker', () {
    final page = File('lib/ui/screens_renter/property_details/property_page.dart')
        .readAsStringSync();
    expect(page, contains('selectableDayPredicate: (d) =>\n                        _checkoutAllowed(selectedDate, d)'),
        reason: 'the check-out picker no longer applies the stay limits');
    expect(page, contains('firstCheckout(from)'));
    expect(page, contains('lastCheckout(from)'));
    expect(page, contains('_checkInWindow!.stayRule'),
        reason: 'the rule is enforced but never said — a greyed day teaches nothing');
    final svc = File('lib/service/booking_service.dart').readAsStringSync();
    expect(svc, contains("minNights: int.tryParse('\${w['minNights'] ?? 0}')"));
    expect(svc, contains("maxNights: int.tryParse('\${w['maxNights'] ?? 0}')"));
  });
}
