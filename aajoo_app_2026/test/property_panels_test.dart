import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/models/single_property_response.dart';
import 'package:rent_home/ui/screens_renter/property_details/components/property_tabs.dart';

/// The property page used to draw ONE section at a time behind a tab switcher.
/// A host who had filled in amenities, house rules, distances and a full
/// specification opened their own live listing and saw a heading, a sentence
/// and the price — everything else sat behind a tab nobody taps.
///
/// These tests pin the two halves of the fix: every section is on the page at
/// once, and the long lists still open trimmed so the sections underneath stay
/// reachable.
void main() {
  /// A listing with more amenities and landmarks than fit on one screen.
  SinglePropertyData listing() => SinglePropertyData.fromJson({
        'property_id': 1,
        'property_name': 'Test villa',
        'property_desc': 'A quiet villa with a view of the valley.',
        'property_address': 'Kasauli, Himachal Pradesh',
        // No coordinates: GoogleMap needs a platform view a widget test has no
        // way to provide, and the map is not what these tests are about — the
        // area card falls back to its placeholder.
        'amenityGroups': [
          for (var g = 0; g < 4; g++)
            {
              'key': 'group$g',
              'label': 'Group $g',
              'items': [
                for (var i = 0; i < 5; i++)
                  {'key': 'a${g}_$i', 'label': 'Amenity ${g}_$i'},
              ],
            },
        ],
        'nearby': [
          for (var g = 0; g < 3; g++)
            {
              'key': 'n$g',
              'label': 'Nearby $g',
              'places': [
                for (var i = 0; i < 5; i++)
                  {'place': 'Place ${g}_$i', 'distance': '${i + 1}'},
              ],
            },
        ],
        'houseRules': {'petsAllowed': true, 'smokingAllowed': false},
      });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: PropertyDetailPanels(single: listing()),
        ),
      ),
    ));
    await tester.pump();
  }

  testWidgets('every section is on the page at once, not one per tab',
      (tester) async {
    await pump(tester);

    // All four headings exist in the tree simultaneously. Under the old tab
    // switcher exactly one of these could ever be found.
    expect(find.text('What this place offers'), findsOneWidget);
    expect(find.text('House rules'), findsOneWidget);
    expect(find.text("Where you'll be"), findsOneWidget);
    expect(find.text("What's nearby"), findsOneWidget);
  });

  testWidgets('long lists open trimmed and expand on Show all', (tester) async {
    await pump(tester);

    // 20 amenities across 4 groups of 5, against a budget of 8. Groups are
    // never split — a heading with nothing under it reads as a bug — so the
    // second group would take the total to 10 and is held back entirely.
    expect(find.text('Amenity 0_0'), findsOneWidget);
    expect(find.text('Amenity 0_4'), findsOneWidget);
    expect(find.text('Amenity 1_0'), findsNothing);

    final showAll = find.text('Show all 20 amenities');
    expect(showAll, findsOneWidget);

    await tester.tap(showAll);
    await tester.pump();

    expect(find.text('Amenity 3_4'), findsOneWidget);
    expect(find.text('Show less'), findsWidgets);
  });

  testWidgets("what's nearby trims too", (tester) async {
    await pump(tester);

    // 15 places across 3 groups of 5, budget 6 → one group.
    expect(find.text('Place 0_0'), findsOneWidget);
    expect(find.text('Place 1_0'), findsNothing);
    expect(find.text('Show all 15 places'), findsOneWidget);
  });

  testWidgets('the section row is a jump nav, not a switch', (tester) async {
    await pump(tester);

    // Tapping a chip must NOT hide the others: that was the whole bug.
    await tester.tap(find.text('House rules').first);
    await tester.pumpAndSettle();

    expect(find.text('What this place offers'), findsOneWidget);
    expect(find.text("What's nearby"), findsOneWidget);
  });
}
