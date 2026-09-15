// A negotiated deal shows on the cards outside the listing.
//
// Client, 2026-09-16: "I negotiated on a property but did not book. Back on
// the home page I should see the changed price — the one I last accepted,
// with the discount and all, should show outside too." Every card priced at
// the list rate, because a deal is per-guest and the card never asked for
// one; the home banner named the deal but the card under it still said
// ₹2,000. The card now wears it the way it wears a host's running discount:
// struck price, deal price, "% off" pill.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String codeOnly(String src) => src
    .replaceAll('\r\n', '\n')
    .split('\n')
    .where((l) => !l.trimLeft().startsWith('//') && !l.trimLeft().startsWith('///'))
    .join('\n');

void main() {
  final card = codeOnly(
      File('lib/ui/screens_renter/home/components/curated_card.dart')
          .readAsStringSync());

  test('the card asks for the guest\'s own deal', () {
    expect(card, contains('PropertyOffer? get _shownOffer'));
    expect(card, contains('Get.find<DealsController>().forProperty(property.propertyId)'));
    expect(card, contains('if (property.offer != null) return property.offer;'),
        reason: "a host's running offer must still win — it is the price everyone pays");
  });

  test('percentage deals only, and never below the server\'s figure', () {
    expect(card, contains("deal.type != 'percent'"));
    expect(card, contains('deal.percent <= 0'));
    expect(card, contains('.ceilToDouble()'),
        reason: 'rounding down would advertise a nightly price under the quote');
  });

  test('every place the card prints a price uses it', () {
    expect(card, contains('if (_shownOffer != null)'));
    expect(card, contains(r"Text('${_shownOffer!.percent}% off'"));
    expect(card, contains(r"text: '${rupees(_shownOffer!.was)} '"));
    expect(card, contains('text: _shownOffer != null'));
    expect(card, isNot(contains('property.offer!.now')),
        reason: 'a price span still reads the host offer directly, so a deal is ignored there');
  });

  test('no controller, no crash — the card is used on screens that have none', () {
    expect(card, contains('if (!Get.isRegistered<DealsController>()) return null;'));
  });
}
