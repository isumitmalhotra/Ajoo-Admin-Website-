// The heart on every home-rail card (Featured, Stays near you, Trending) was
// drawn and wired to nothing: PropertySlider passed CuratedCard an onTap and
// never an onFavoriteTap, so tapping it did nothing — found on the iOS
// Simulator, 2026-10-09, and the same on Android. Only Saved Stays, which
// passes its own remove handler, had a live heart.
//
// A tap on one device proves it once. This proves, on every run, that the
// heart saves the stay it sits on, that it does not open the listing as well,
// and that with no override it is wired to BookmarkService rather than null.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/models/properties_response_model.dart';
import 'package:rent_home/ui/screens_renter/home/components/property_slider.dart';
import 'package:rent_home/utils/fonts.dart';

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

final _kasauli = Property.fromJson({
  'property_id': 5,
  'property_name': 'Green Hills Kasauli',
  'property_city': 'Kasauli',
  'property_price': '100',
  'property_cancellation_policy': 'flexible',
  'coverImage': '',
  'images': <String>[],
});

Widget _rail({
  required ValueChanged<Property> onOpen,
  Future<bool> Function(Property)? onToggleSaved,
}) =>
    MaterialApp(
      theme: ThemeData(textTheme: interTextTheme()),
      home: Scaffold(
        body: PropertySlider(
          title: 'Stays near you',
          properties: [_kasauli],
          onOpen: onOpen,
          onToggleSaved: onToggleSaved,
        ),
      ),
    );

void main() {
  setUpAll(_loadFonts);

  testWidgets('the heart saves the stay it sits on, and does not open it',
      (tester) async {
    final saved = <int>[];
    var opened = 0;
    await tester.pumpWidget(_rail(
      onOpen: (_) => opened++,
      onToggleSaved: (p) async {
        saved.add(p.propertyId);
        return true;
      },
    ));

    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pump();

    expect(saved, [5], reason: 'the heart must save the stay it is drawn on');
    expect(opened, 0, reason: 'saving must not also open the listing');
  });

  testWidgets('with no override the heart is wired, not null', (tester) async {
    await tester.pumpWidget(_rail(onOpen: (_) {}));

    final heart = tester.widget<InkWell>(find.ancestor(
      of: find.byIcon(Icons.favorite_border),
      matching: find.byType(InkWell),
    ).first);
    expect(heart.onTap, isNotNull,
        reason: 'a heart with no handler is drawn but dead — the D4 bug');
  });
}
