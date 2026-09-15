// Without a verified identity: no booking AND no negotiation.
//
// Client, 2026-09-16: "I logged in with a new account and did not do KYC —
// without KYC neither negotiation nor booking should happen." Booking has
// been gated on this app since the checkout KYC step; the offer sheet was
// not, so an unverified guest could open a negotiation, put a host through
// a round of offers, agree a price, and be refused at the end. The server
// now refuses the offer itself (user.controller createNegotiationOffer);
// this app says so first, the way it already does for a decline lock.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String codeOnly(String src) => src
    .replaceAll('\r\n', '\n')
    .split('\n')
    .where((l) => !l.trimLeft().startsWith('//'))
    .join('\n');

void main() {
  final page = codeOnly(
      File('lib/ui/screens_renter/property_details/property_page.dart')
          .readAsStringSync());

  test('the page knows whether this guest is verified', () {
    expect(page, contains('bool get _needsVerification'));
    expect(page, contains('return !user.isKycVerified;'),
        reason: 'the gate reads something other than the booking gate does');
    expect(page, contains('if (user == null) return false;'),
        reason: 'a signed-out guest would be told to verify instead of to log in');
  });

  test('the offer button is disabled — and explained — until then', () {
    expect(page, contains("Text('Verify your identity first'"));
    expect(page, contains('_verifyLine'));
    expect(page, contains("Get.toNamed('/kyc'"),
        reason: 'the disabled button gives no way to fix it');
  });

  test('…and the live button is hidden while verification is needed', () {
    expect(
      page.replaceAll(RegExp(r'\s+'), ' '),
      contains('visible: !isPrebooking && ownerNegotiates && _negotiationLock == null && !_needsVerification'),
      reason: 'the live Send an Offer button is shown to an unverified guest — '
          'the server will refuse the offer',
    );
  });

  test('every state has its own sentence: pending is not in review', () {
    expect(page, contains("if (st == 'in_review')"));
    expect(page, contains("if (st == 'declined')"));
    expect(page, contains("if (st == 'pending' || st == 'partial')"));
  });
}
