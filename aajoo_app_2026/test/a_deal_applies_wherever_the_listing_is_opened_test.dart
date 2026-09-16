// A price already agreed applies whichever way the listing is opened.
//
// Client, 2026-09-16: "if negotiations are already done for these dates but
// if I go outside and try to book again for the same dates, it is allowing me
// to book at new original rates — it must send to same negotiated rate for
// same dates."
//
// They were right, and the cause was narrow: hasDeal read widget.dealCode,
// which is only set when the listing is opened THROUGH the deal — the home
// banner or My Negotiations. Opened from search, or come back to later, the
// page knew nothing about the price the guest had agreed, sent no coupon
// code, and /booking/create charged the list price.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String codeOnly(String src) => src
    .replaceAll('\r\n', '\n')
    .split('\n')
    .where((l) => !l.trimLeft().startsWith('//') && !l.trimLeft().startsWith('///'))
    .join('\n');

void main() {
  final page = codeOnly(
      File('lib/ui/screens_renter/property_details/property_page.dart')
          .readAsStringSync());

  test('the page looks for the deal instead of waiting to be handed one', () {
    expect(page, contains('Future<void> _adoptLiveDeal() async {'));
    expect(page, contains('_adoptLiveDeal();'),
        reason: 'it is defined and never called');
    expect(page, contains('deals.forProperty(widget.id)'));
    expect(page, contains('_appliedCoupon = deal.code;'),
        reason: 'the coupon code is not applied, so the booking goes at full price');
  });

  test('hasDeal and the date lock see a deal found this way', () {
    expect(page, contains("((widget.dealCode?.isNotEmpty ?? false) || _adoptedDeal != null)"));
    expect(page, contains('String? get _dealFrom => widget.dealFrom ?? _adoptedDeal?.bookFrom;'));
    expect(page, contains('hasDeal && (_dealFrom?.isNotEmpty ?? false) && (_dealTo?.isNotEmpty ?? false)'),
        reason: 'the lock still reads only the dates passed in, so a found deal leaves the pickers open');
  });

  test('percentage deals only, and it never throws on the way', () {
    expect(page, contains("if (deal.type != 'percent' || deal.percent <= 0) return;"));
    expect(page, contains('if (hasDeal) return;'),
        reason: 'a listing opened through the deal would fetch again');
  });

  test('a deal does not overwrite dates the guest chose', () {
    expect(page, contains('final untouched ='),
        reason: 'the agreed nights are forced over whatever the guest picked');
  });
}
