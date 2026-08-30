// The offer payload the server actually sends, parsed by the model the app
// renders from. Captured verbatim from /pricing/quote on 2026-08-31.
//
// Field names are the risk: every one of them is a silent zero or a null if it
// drifts, and a discount that quietly reads zero shows the full price with a
// struck-through line beside it — worse than no offer at all.
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/models/property_offer.dart';

const _payload = r'''
{
  "id": 1,
  "title": "Limited time offer",
  "was": 3200,
  "now": 2560,
  "percent": 20,
  "endsAt": "2026-09-06T18:32:28.000Z",
  "slotsLeft": 2,
  "payModes": [
    "full"
  ]
}
''';

void main() {
  test('the real payload round-trips', () {
    final o = PropertyOffer.fromJson(jsonDecode(_payload));
    expect(o, isNotNull);
    expect(o!.percent, 20);
    expect(o.was, 3200);
    expect(o.now, 2560);
    expect(o.payModes, contains('full'));
  });

  test('the ratio is what a multi-night subtotal is scaled by', () {
    final o = PropertyOffer.fromJson(jsonDecode(_payload))!;
    // Two nights at the listed rate, discounted, must equal the stay total the
    // server quoted for the same dates.
    expect((o.was * 2 * o.ratio).round(), (o.now * 2).round());
  });

  test('anything that is not a real discount parses as null', () {
    // A struck-through price identical to the new one reads as a trick, so
    // these must not render at all.
    for (final bad in [
      null,
      'nonsense',
      {'was': 5000, 'now': 5000, 'percent': 0},
      {'was': 5000, 'now': 6000, 'percent': 20},
      {'was': 0, 'now': 0, 'percent': 20},
    ]) {
      expect(PropertyOffer.fromJson(bad), isNull, reason: '$bad');
    }
  });

  test('payment methods default to full-only when the server omits them', () {
    final o = PropertyOffer.fromJson({'was': 5000, 'now': 4000, 'percent': 20})!;
    expect(o.allowsCod, isFalse);
    expect(o.allowsDeposit, isFalse);
    expect(o.payModes, ['full']);
  });

  test('a widened offer reports what it allows', () {
    final o = PropertyOffer.fromJson({
      'was': 5000, 'now': 4000, 'percent': 20,
      'payModes': ['full', 'deposit', 'cod'],
    })!;
    expect(o.allowsCod, isTrue);
    expect(o.allowsDeposit, isTrue);
  });
}
