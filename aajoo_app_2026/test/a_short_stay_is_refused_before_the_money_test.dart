// "Minimum stay 3 nights" sat directly above a priced 1-night stay.
//
// Photographed by the client on 26 September 2026. The View Details sheet
// showed 26/09/2026 → 27/09/2026, the line "Minimum stay 3 nights. Up to 40
// nights.", and a Booking Price of ₹10,620 for "Nights: 1".
//
// The date PICKER was never the problem — `_checkoutAllowed` already refuses a
// check-out before `firstCheckout(from)`. What it cannot police is the range
// the screen opens with: the default dates come from the guest's search, and
// `_checkInWindow` arrives from the server afterwards. So a default that
// breaks the rule is priced, offered, and then refused by the booking endpoint
// with the total already on screen.
//
// The fix deliberately does NOT move the guest's dates. Silently rewriting
// somebody's stay to fit a rule they have not read yet is worse than refusing:
// they came for those nights. The website settled it the same way, and the
// wording here matches `stayRuleError` in redesign/pages/PropertyDetail.tsx
// word for word — one rule must not be described two ways on two platforms.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _codeOnly(String src) => src
    .replaceAll('\r\n', '\n')
    .split('\n')
    .where((l) =>
        !l.trimLeft().startsWith('//') && !l.trimLeft().startsWith('///'))
    .join('\n');

void main() {
  final page = _codeOnly(File(
          'lib/ui/screens_renter/property_details/property_page.dart')
      .readAsStringSync());

  test('the rule is read from the host window, not invented', () {
    expect(page, contains('String? get _stayRuleError'));
    expect(page, contains('w.minNights > 1 && totalDays < w.minNights'),
        reason: 'the minimum is not compared against the chosen nights');
    expect(page, contains('w.maxNights > 0 && totalDays > w.maxNights'),
        reason: 'the maximum is not checked at all');
  });

  test('it says nothing until there is something to say', () {
    // No window yet, no dates yet, or a zero-night range: silence. An error
    // shown while the server has not answered would flash on every open.
    expect(
      page,
      contains('if (w == null || selectedDateTo == null || totalDays <= 0) return null;'),
      reason: 'the error can fire before the window or the dates exist',
    );
  });

  test('the wording matches the website, word for word', () {
    // Same rule, same sentence. The web reads:
    //   `This host asks for a minimum stay of ${minN} night${...}.`
    //   `This host accepts stays of up to ${maxN} nights.`
    expect(page,
        contains("'This host asks for a minimum stay of \${w.minNights} nights.'"));
    expect(page,
        contains("'This host accepts stays of up to \${w.maxNights} nights.'"));
  });

  test('booking is refused BEFORE the money, not by the server after it', () {
    final gate = page.indexOf('final stayProblem = _stayRuleError;');
    final policy = page.indexOf('if (!_policyOk) {');
    final booking = page.indexOf('await bookingController.createBooking');
    expect(gate, greaterThan(-1), reason: 'nothing checks the stay rule on the way to booking');
    expect(booking, greaterThan(-1), reason: 'the booking call has moved');
    expect(gate, lessThan(booking),
        reason: 'the stay rule is checked after the booking is created');
    expect(gate, lessThan(policy),
        reason: 'the dates should be settled before the cancellation policy is asked about');
  });

  test('the dates are NOT silently rewritten to fit', () {
    // The tempting fix is to extend the checkout to firstCheckout(). It is the
    // wrong one: the guest asked for those nights.
    // Bounded at the getter's OWN closing brace, not by a character count.
    // A fixed window ran past the end of it into _loadAvailability, which
    // calls setState perfectly legitimately, and this test failed on correct
    // code. Second time that trap has caught me in this file's tests.
    final at = page.indexOf('String? get _stayRuleError');
    // Bounded at the getter's OWN end, not by a character count. A fixed
    // window ran past it into _loadAvailability, which calls setState
    // perfectly legitimately, and this test failed on correct code.
    final nextMember = page.indexOf('Future<void> _loadAvailability', at);
    expect(nextMember, greaterThan(at),
        reason: 'the getter is no longer where this test expects it');
    final body = page.substring(at, nextMember);
    // An ASSIGNMENT, not a comparison: 'selectedDateTo == null' contains
    // 'selectedDateTo =' as a prefix, and this test failed on the guard
    // that makes the getter safe in the first place.
    expect(RegExp(r'selectedDateTo\s*=(?!=)').hasMatch(body), isFalse,
        reason: 'the rule getter is moving the guest\'s dates');
    expect(body.contains('setState'), isFalse,
        reason: 'a getter read during build is calling setState');
  });

  test('the problem is shown on the screen, not only on a tap', () {
    // A guest who never presses the button should still see why the stay is
    // not bookable, next to the dates that cause it.
    expect(page, contains('if (_stayRuleError != null)'),
        reason: 'the violation is never rendered — only raised on a tap');
    expect(page, contains('Icons.error_outline_rounded'),
        reason: 'the violation is not distinguished from the neutral rule line');
  });
}
