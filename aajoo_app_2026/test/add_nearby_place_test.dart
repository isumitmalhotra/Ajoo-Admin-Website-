import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/service/geocode_service.dart';
import 'package:rent_home/ui/screens_host/listing/widgets/add_nearby_place.dart';

/// A picked position must survive an edit to the name.
///
/// Found by driving the wizard on the emulator on 2026-09-10: typing
/// "Gurdwara Nada Sahib", picking the match, then touching the name again
/// detached the coordinates while leaving the MEASURED distance sitting in the
/// box. Pressing Add then saved 11.0 km with no position behind it — a
/// distance that looks measured, a guest with no directions, and nothing on
/// screen saying anything had changed.
///
/// The rule these tests pin down: picking a match is an explicit act, typing
/// is not. Only emptying the name, picking another match, or "Not this place"
/// detaches a position.
void main() {
  // Nada Sahib, as Google labels it — the hamlet first, which is exactly why
  // the name must stay the host's and why the label has to be on screen.
  const nadaSahib = GeoPlace(
    label: 'Chaunki, Panchkula, Nada Sahib, Punjab 134116',
    lat: 30.6942094,
    lng: 76.8809476,
  );
  const otherPlace = GeoPlace(
    label: 'Sukhna Lake, Chandigarh',
    lat: 30.7421,
    lng: 76.8188,
  );

  /// Sector 17, Chandigarh — the property in the emulator run.
  const propLat = 30.74105162;
  const propLng = 76.77901492;

  late List<Map<String, dynamic>> added;

  Future<void> pump(WidgetTester tester, {List<GeoPlace> hits = const [nadaSahib]}) async {
    added = [];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: AddNearbyPlace(
            propertyLat: propLat,
            propertyLng: propLng,
            onAdd: added.add,
            search: (_) async => hits,
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Add a place'));
    await tester.pumpAndSettle();
  }

  /// Type into the name box and let the 450ms debounce fire.
  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField).first, text);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
  }

  Finder attachedLabel() => find.textContaining('Found on the map:');

  testWidgets('picking a match measures the distance and keeps the host name',
      (tester) async {
    await pump(tester);
    await type(tester, 'Gurdwara Nada Sahib');
    await tester.tap(find.text(nadaSahib.label));
    await tester.pumpAndSettle();

    // The name is the host's, never the geocoder's first comma-part.
    final name = tester.widget<TextField>(find.byType(TextField).first);
    expect(name.controller!.text, 'Gurdwara Nada Sahib');

    // Measured, and it matches the real distance to Nada Sahib.
    final km = tester.widget<TextField>(find.byType(TextField).last);
    expect(double.parse(km.controller!.text), closeTo(11.0, 0.3));

    // The position is NAMED, so a wrong one is visible.
    expect(attachedLabel(), findsOneWidget);
    expect(find.textContaining('Chaunki'), findsOneWidget);
  });

  testWidgets('THE REGRESSION: editing the name keeps the position',
      (tester) async {
    await pump(tester);
    await type(tester, 'Gurdwara Nada Sahib');
    await tester.tap(find.text(nadaSahib.label));
    await tester.pumpAndSettle();
    expect(attachedLabel(), findsOneWidget);

    // The host adds a word — the same place, said slightly differently.
    await type(tester, 'Gurdwara Nada Sahib Ji');
    expect(attachedLabel(), findsOneWidget,
        reason: 'typing detached the position, so the measured distance below '
            'it is now a claim with nothing behind it');

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(added, hasLength(1));
    expect(added.first['name'], 'Gurdwara Nada Sahib Ji');
    expect(added.first['lat'], nadaSahib.lat);
    expect(added.first['lng'], nadaSahib.lng);
  });

  testWidgets('emptying the name detaches — an unambiguous start over',
      (tester) async {
    await pump(tester);
    await type(tester, 'Gurdwara Nada Sahib');
    await tester.tap(find.text(nadaSahib.label));
    await tester.pumpAndSettle();
    expect(attachedLabel(), findsOneWidget);

    await type(tester, '');
    expect(attachedLabel(), findsNothing);
  });

  testWidgets('"Not this place" detaches but keeps the distance',
      (tester) async {
    await pump(tester);
    await type(tester, 'Gurdwara Nada Sahib');
    await tester.tap(find.text(nadaSahib.label));
    await tester.pumpAndSettle();
    final measured =
        tester.widget<TextField>(find.byType(TextField).last).controller!.text;

    await tester.tap(find.text('Not this place'));
    await tester.pumpAndSettle();

    expect(attachedLabel(), findsNothing);
    // The number may still be right; throwing it away to prove a point would
    // just destroy the host's work.
    expect(tester.widget<TextField>(find.byType(TextField).last).controller!.text,
        measured);

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(added.first['lat'], isNull,
        reason: 'a detached entry must not still carry coordinates');
    expect(added.first['km'], closeTo(11.0, 0.3));
  });

  testWidgets('searching resumes after a pick, so a wrong one can be corrected',
      (tester) async {
    await pump(tester, hits: const [nadaSahib, otherPlace]);
    await type(tester, 'Nada Sahib');
    await tester.tap(find.text(nadaSahib.label));
    await tester.pumpAndSettle();
    // The list closes over the choice just made rather than reopening on it.
    expect(find.text(otherPlace.label), findsNothing);

    // Typing anything else brings the list back — no need to detach first.
    await type(tester, 'Sukhna');
    expect(find.text(otherPlace.label), findsOneWidget);

    await tester.tap(find.text(otherPlace.label));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(added.first['lat'], otherPlace.lat,
        reason: 'picking a second match must replace the first position');
  });
}
