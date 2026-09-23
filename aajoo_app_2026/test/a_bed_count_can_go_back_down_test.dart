import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/models/listing_schema.dart';
import 'package:rent_home/ui/screens_host/listing/widgets/room_detail.dart';

/// A bed count you can raise and cannot lower is a trap.
///
/// Reported 2026-09-22: "here in app, I can only increase counts of beds like
/// king, queen on master bedroom details..I cannot go back and close it like
/// the web."
///
/// Removing was long-press only, which is no affordance at all -- nothing on
/// the screen said it existed. So a host who tapped Queen once too many had no
/// way back, and the website, which draws a visible control inside the pill,
/// behaved differently from the app on the same form.
///
/// Both platforms now carry one visible control that takes one bed off and
/// removes the type when the last one goes.
void main() {
  const vocab = RoomDetailVocab(
    bedroomTypes: [Option(value: 'master_bedroom', label: 'Master bedroom')],
    bedTypes: [
      Option(value: 'king', label: 'King'),
      Option(value: 'queen', label: 'Queen'),
    ],
    bathroomTypes: [Option(value: 'attached', label: 'Attached')],
    bedroomBathroom: [Option(value: 'attached', label: 'Attached')],
    limits: RoomLimits(),
  );

  /// The bedroom the host is editing, and every version of it the screen is
  /// handed back.
  late List<RoomEntry> written;

  Future<void> show(WidgetTester tester, RoomEntry bedroom) async {
    written = [];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: RoomDetailSection(
            vocab: vocab,
            bedroomCount: 1,
            bathroomCount: 0,
            bedrooms: [bedroom],
            bathrooms: const [],
            onBedroom: (_, r) => written.add(r),
            onBathroom: (_, __) {},
          ),
        ),
      ),
    ));
  }

  /// The visible remove control. There is one per chosen bed type.
  Finder removeControl(String label) =>
      find.bySemanticsLabel('Remove one $label bed');

  testWidgets('a chosen bed type shows a control that takes one off',
      (tester) async {
    await show(tester, const RoomEntry(
      index: 1,
      type: 'master_bedroom',
      beds: [BedEntry(type: 'queen', count: 3)],
    ));

    expect(removeControl('Queen'), findsOneWidget,
        reason: 'the only way back was a long-press, which nothing on the '
            'screen advertises');

    await tester.tap(removeControl('Queen'));
    await tester.pump();

    expect(written, hasLength(1));
    expect(written.single.beds.single.count, 2,
        reason: 'the control must remove ONE bed, not the whole type -- a host '
            'who tapped once too many should not have to start again');
  });

  testWidgets('taking the last one off removes the type', (tester) async {
    await show(tester, const RoomEntry(
      index: 1,
      type: 'master_bedroom',
      beds: [BedEntry(type: 'king', count: 1), BedEntry(type: 'queen', count: 2)],
    ));

    await tester.tap(removeControl('King'));
    await tester.pump();

    expect(written.single.beds.map((b) => b.type), ['queen'],
        reason: 'the last King is gone, so the type goes with it');
    expect(written.single.beds.single.count, 2,
        reason: 'the other type is untouched');
  });

  testWidgets('an untouched bed type shows no remove control', (tester) async {
    await show(tester, const RoomEntry(index: 1, type: 'master_bedroom'));

    expect(removeControl('King'), findsNothing);
    expect(removeControl('Queen'), findsNothing,
        reason: 'a row of unchosen types must stay as narrow as it was');
  });

  testWidgets('tapping the pill still adds one', (tester) async {
    await show(tester, const RoomEntry(
      index: 1,
      type: 'master_bedroom',
      beds: [BedEntry(type: 'queen', count: 1)],
    ));

    await tester.tap(find.textContaining('Queen'));
    await tester.pump();

    expect(written.single.beds.single.count, 2);
  });
}
