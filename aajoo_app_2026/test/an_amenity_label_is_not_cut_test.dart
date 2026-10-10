// The four-up amenity row on a listing gave each label a fixed 64 wide and
// one line, so "Fire extinguisher" read "Fire exting…" and "Dining table"
// read "Dining tab…" on Green Hills Kasauli (iOS Simulator, 2026-10-09; the
// same Dart draws the same on Android). Labels now get two lines and their
// quarter of the row. This holds them to: no overflow, nothing cut, and no
// word split across lines — from a 320-wide Android phone to an iPhone 18
// Pro Max.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/widgets/amenity_row.dart';

Future<void> _loadFonts() async {
  Future<ByteData> bytes(String path) async =>
      ByteData.sublistView(Uint8List.fromList(await File(path).readAsBytes()));
  final manrope = FontLoader('Manrope')
    ..addFont(bytes('assets/google_fonts/Manrope-VF.ttf'));
  await manrope.load();
}

const _labels = ['Bathtub', 'Fire extinguisher', 'Dining table', 'Microwave'];

Future<void> _pump(WidgetTester tester, double width, double scale) =>
    tester.pumpWidget(MaterialApp(
      theme: ThemeData(textTheme: interTextTheme()),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Scaffold(
          body: Center(
            child: SizedBox(width: width, child: const AmenityRow(amenities: _labels)),
          ),
        ),
      ),
    ));

void main() {
  setUpAll(_loadFonts);

  // Content widths: a 320 Android phone, a 375 phone, and this iPhone's 440,
  // each less the page's 16 + 16 padding.
  for (final width in [288.0, 343.0, 408.0]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('every label whole at width $width, text ×$scale', (tester) async {
        await _pump(tester, width, scale);
        expect(tester.takeException(), isNull);
        for (final label in _labels) {
          final p = tester.renderObject<RenderParagraph>(find.text(label));
          expect(p.didExceedMaxLines, isFalse, reason: '"$label" was cut');
          for (final word in label.split(' ')) {
            final painter = TextPainter(
              text: TextSpan(text: word, style: (p.text as TextSpan).style),
              textDirection: TextDirection.ltr,
              textScaler: p.textScaler,
            )..layout();
            expect(painter.width, lessThanOrEqualTo(p.size.width + 0.5),
                reason: '"$word" would be split across lines at width $width');
          }
        }
      });
    }
  }

  testWidgets('nothing overflows at text ×2.0 on a 320 phone', (tester) async {
    await _pump(tester, 288, 2.0);
    expect(tester.takeException(), isNull);
  });
}
