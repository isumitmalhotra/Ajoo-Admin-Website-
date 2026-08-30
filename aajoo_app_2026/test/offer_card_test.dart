// Does a discounted listing actually LOOK discounted on the card?
//
// This exists because the emulator's display pipeline broke while the offer
// work was being verified, so the three app surfaces could not be looked at.
// A widget test renders the real tree and asserts on what a guest would see,
// which is the durable version of that check anyway — a screenshot proves it
// once, this proves it on every run.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/models/properties_response_model.dart';
import 'package:rent_home/models/property_offer.dart';
import 'package:rent_home/ui/screens_renter/home/components/curated_card.dart';

Property _property({PropertyOffer? offer}) => Property(
      propertyId: 1,
      propertyName: 'E2E Verification Homestay',
      propertyAddress: '14 Old Manali Road',
      propertyDesc: 'A wood-and-stone homestay.',
      propertyPrice: '3200',
      propertyCity: 'Manali',
      propertyLongitude: '77.18',
      propertyLatitude: '32.24',
      propertyHostId: 100,
      propertyZip: '175131',
      images: const [],
      categoryTitles: const [],
      offer: offer,
    );

const _offer = PropertyOffer(
  id: 1,
  title: 'Limited time offer',
  was: 3200,
  now: 2560,
  percent: 20,
);

Future<void> _pump(WidgetTester tester, Property p) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SizedBox(width: 400, height: 420, child: CuratedCard(property: p)),
    ),
  ));
  // Images resolve over the network in this widget; one frame is enough for
  // the text, and pumpAndSettle would wait on them for ever.
  await tester.pump(const Duration(milliseconds: 100));
}

/// Every Text in the tree, flattened — RichText spans included, since the
/// price is built from spans rather than a plain Text.
List<String> _texts(WidgetTester tester) {
  final out = <String>[];
  for (final w in tester.allWidgets) {
    if (w is Text && w.data != null) out.add(w.data!);
    if (w is RichText) out.add(w.text.toPlainText());
  }
  return out;
}

void main() {
  testWidgets('a discounted card shows both prices and the % off chip', (tester) async {
    await _pump(tester, _property(offer: _offer));
    final all = _texts(tester).join(' | ');

    expect(all, contains('20% off'), reason: 'the chip is missing');
    expect(all, contains('2,560'), reason: 'the price being charged is missing');
    expect(all, contains('3,200'), reason: 'the struck-through original is missing');
  });

  testWidgets('the original price is actually struck through, not just shown', (tester) async {
    // Both numbers on a card with no line through one of them reads as a
    // price that cannot make its mind up.
    await _pump(tester, _property(offer: _offer));

    var struck = false;
    for (final w in tester.allWidgets) {
      if (w is! RichText) continue;
      w.text.visitChildren((span) {
        if (span is TextSpan &&
            (span.text ?? '').contains('3,200') &&
            span.style?.decoration == TextDecoration.lineThrough) {
          struck = true;
        }
        return true;
      });
    }
    expect(struck, isTrue, reason: 'the old price is shown but not struck through');
  });

  testWidgets('an undiscounted card shows one price and no chip', (tester) async {
    await _pump(tester, _property());
    final all = _texts(tester).join(' | ');

    expect(all, contains('3,200'));
    expect(all, isNot(contains('% off')), reason: 'a chip appeared with no offer running');
    expect(all, isNot(contains('2,560')));
  });
}
