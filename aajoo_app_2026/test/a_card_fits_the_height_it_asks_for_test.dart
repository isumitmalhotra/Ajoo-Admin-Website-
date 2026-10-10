// The home rail and the Saved grid fix a card's height before it is built,
// and both guessed: the rail said 268, the grid an aspect ratio of 0.72.
// The image is a fixed 150 and the text does not shrink with the tile, so a
// property with a cancellation policy — its badge adds ~21 — overflowed by 5
// on an iPhone 18 Pro Max (Kasauli and Kharar, 2026-10-09), and any larger
// accessibility text size overflowed every card.
//
// CuratedCard.extentFor now measures the lines it is about to draw. This
// renders the card at exactly that height across text sizes and widths down
// to a two-column grid on a 320-wide Android phone, and fails on ANY overflow,
// downward or sideways.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/models/properties_response_model.dart';
import 'package:rent_home/ui/screens_renter/home/components/curated_card.dart';
import 'package:rent_home/utils/fonts.dart';

/// The app's real faces. The test font draws every glyph as a square as wide
/// as it is tall, which overflows any row sideways; the question here is
/// whether the card fits on a phone, so it is asked in the fonts a phone uses.
Future<void> _loadFonts() async {
  Future<ByteData> bytes(String path) async =>
      ByteData.sublistView(Uint8List.fromList(await File(path).readAsBytes()));
  final manrope = FontLoader('Manrope')
    ..addFont(bytes('assets/google_fonts/Manrope-VF.ttf'));
  final poppins = FontLoader('Poppins');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    poppins.addFont(bytes('assets/google_fonts/Poppins-$w.ttf'));
  }
  await manrope.load();
  await poppins.load();
}

Property _property({String? policy, bool rated = true, bool deal = false}) =>
    Property.fromJson({
      'property_id': 5,
      'property_name': 'Green Hills Kasauli with a name long enough to ellipsize',
      'property_city': 'Kasauli',
      'property_price': '12500',
      'property_cancellation_policy': policy,
      'coverImage': '',
      'images': <String>[],
      if (rated) 'rating': 4.8,
      if (rated) 'review_count': 124,
      if (deal) 'offer': {'id': 1, 'title': 'Monsoon', 'was': 15000, 'now': 12500, 'percent': 17},
    });

void main() {
  setUpAll(_loadFonts);

  for (final scale in [1.0, 1.3, 2.0]) {
    for (final width in [140.0, 160.0, 200.0]) {
      for (final variant in [
        (name: 'no policy', policy: null, rated: true, deal: false),
        (name: 'flexible policy', policy: 'flexible', rated: true, deal: false),
        (name: 'policy + deal, rated', policy: 'super_strict', rated: true, deal: true),
        (name: 'policy + deal, unrated', policy: 'moderate', rated: false, deal: true),
      ]) {
        testWidgets(
            'fits at text ×$scale, width $width, ${variant.name}', (tester) async {
          final p = _property(policy: variant.policy, rated: variant.rated, deal: variant.deal);
          await tester.pumpWidget(MaterialApp(
            theme: ThemeData(textTheme: interTextTheme()),
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: Builder(
                builder: (context) => Center(
                  child: SizedBox(
                    width: width,
                    height: CuratedCard.extentFor(context,
                        withCancellationBadge: variant.policy != null),
                    child: CuratedCard(property: p),
                  ),
                ),
              ),
            ),
          ));
          expect(tester.takeException(), isNull,
              reason: 'the card overflowed the height extentFor gave it');
        });
      }
    }
  }
}
