// The FAQ cards — on the home screen, the support screen and the host's
// support screen — are a coloured, bordered box around an ExpansionTile. A
// tile's ripple paints on the nearest Material; on the home screen that was
// the page beneath the box, so the box's own fill hid it. Flutter flags
// exactly this ("ListTile background color or ink splashes may be
// invisible"), and did on the iOS Simulator on 2026-10-10 for the home
// screen's five FAQ cards; the same Dart runs on Android. The home card now
// gives the tile its own transparent Material inside the box.
//
// The two support cards were never affected: they pass the ExpansionTile a
// `shape`, and an ExpansionTile given a shape wraps itself in a Material.
// They are held here too, so dropping that shape cannot quietly bring the
// hidden ripple to them. For all three: no warning when built, nothing
// filled between the tile and its Material, and a press puts ink on it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rent_home/models/faq_reponse_model.dart';
import 'package:rent_home/ui/screens_common/support/support_screen.dart';
import 'package:rent_home/ui/screens_host/support/host_support_screen.dart';
import 'package:rent_home/ui/screens_renter/home/components/home_faq_strip.dart';

const _q = 'How do I cancel a booking?';
const _a = 'Open the booking and choose Cancel.';

Future<void> _pump(WidgetTester tester, Widget card) async {
  await tester.pumpWidget(GetMaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: card)),
  ));
  await tester.pumpAndSettle();
}

/// Presses the tile and returns the ink drawn on the Material it paints on.
Future<List<Object?>> _inkOnPress(WidgetTester tester) async {
  final tile = find.text(_q);
  expect(tile, findsOneWidget);
  final gesture = await tester.startGesture(tester.getCenter(tile));
  await tester.pump(const Duration(milliseconds: 100));
  final ink = Material.of(tester.element(tile));
  final features = (ink as dynamic).debugInkFeatures as List<Object?>?;
  await gesture.up();
  await tester.pumpAndSettle();
  return features ?? const [];
}

/// The Material the tile paints its ink on must sit inside the card's
/// coloured box, not under it.
void _inkIsAboveTheFill(WidgetTester tester) {
  final tileElement = tester.element(find.text(_q));
  Element? material;
  var fillBetween = false;
  tileElement.visitAncestorElements((e) {
    if (e.widget is Material) {
      material = e;
      return false;
    }
    final w = e.widget;
    if (w is DecoratedBox &&
        w.decoration is BoxDecoration &&
        ((w.decoration as BoxDecoration).color?.a ?? 0) > 0) {
      fillBetween = true;
    }
    return true;
  });
  expect(material, isNotNull);
  expect(fillBetween, isFalse,
      reason: 'a filled box between the tile and its Material hides the ripple');
}

void main() {
  testWidgets('support screen FAQ card', (tester) async {
    await _pump(tester, const FAQTile(question: _q, answer: _a));
    expect(tester.takeException(), isNull);
    _inkIsAboveTheFill(tester);
    expect(await _inkOnPress(tester), isNotEmpty);
  });

  testWidgets("host support screen FAQ card", (tester) async {
    await _pump(tester, const HostFAQTile(question: _q, answer: _a));
    expect(tester.takeException(), isNull);
    _inkIsAboveTheFill(tester);
    expect(await _inkOnPress(tester), isNotEmpty);
  });

  testWidgets('home screen FAQ strip', (tester) async {
    await _pump(
      tester,
      HomeFaqStrip(
        load: () async => [FaqDatum(title: _q, description: _a)],
      ),
    );
    expect(tester.takeException(), isNull);
    _inkIsAboveTheFill(tester);
    expect(await _inkOnPress(tester), isNotEmpty);
  });
}
