import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Two things the host booking page got wrong on B434315 (2026-09-11).
///
/// A request the host has not approved yet is DECLINED, not cancelled —
/// the page offered "Cancel this booking" directly under "Confirm this
/// booking", on a stay that was not yet one, and its dialog promised a
/// refund "under the property policy" when a host cancellation refunds
/// everything the guest paid. And the chips row was a Row: "Invoice …
/// Awaiting approval · Deposit paid · ₹1,890 due" is wider than a phone,
/// and the last chip was cut to "₹1,890 du".
void main() {
  final src = File(
    'lib/ui/screens_host/booking_history/host_booking_detail_page.dart',
  ).readAsStringSync();

  test('a request is declined; a booking is cancelled', () {
    expect(src, contains("'Decline this request'"));
    expect(src, contains("'Cancel this booking'"));
    expect(src, contains("_needsApproval ? 'Decline this request?' : 'Cancel this booking?'"));
    expect(src, contains("_needsApproval ? 'Keep request' : 'Keep booking'"));
    expect(src, contains("_needsApproval ? 'Decline request' : 'Cancel booking'"));
  });

  test('the dialog says what the guest gets back, not "the property policy"', () {
    expect(src, isNot(contains('refunded under the property policy')),
        reason: 'a host cancellation refunds everything paid; the policy '
            'ladder is for the guest calling off');
    expect(src, contains('gets back everything they have paid'));
    expect(src, contains('rupees(b.bookAmountPaid)'));
  });

  test('the chips wrap instead of clipping', () {
    final chips = src.substring(src.indexOf("Text('Invoice \${b.bookInvoice}'"));
    final before = src.substring(0, src.indexOf("Text('Invoice \${b.bookInvoice}'"));
    final opener = before.substring(before.lastIndexOf('const SizedBox(height: 14),'));
    expect(opener, contains('Wrap('),
        reason: 'the invoice / lifecycle / payment chips sit in a Row again, '
            'and the third chip is cut off on a phone');
    expect(opener, isNot(contains('Row(')));
    expect(chips, isNot(contains('const Spacer(),')),
        reason: 'a Spacer inside a Wrap has no meaning');
  });
}
