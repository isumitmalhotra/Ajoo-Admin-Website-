import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Choosing a bathroom stored the answer and never drew it.
///
/// Reported 2026-09-22 with a screen recording: "on app it stopped working to
/// select bathroom during listing". Frame by frame, Bathroom 1 and Bathroom 2
/// hold a selection and Bathroom 3, 4 and 5 never show one. Nothing is wrong
/// with the storage — `setRoom` grows the list and writes the entry, and
/// `RoomEntry.copyWith` keeps the other fields. What was wrong is that nothing
/// ever repainted.
///
/// The rooms section read `c.bedroomDetail` and `c.bathroomDetail` inside
/// `Builder(builder: ...)`, nested in the screen's own `Obx`. Obx subscribes to
/// the observables read WHILE ITS OWN builder runs; a Builder's callback runs
/// later, when the child element builds, by which time the collection window
/// has closed. So the section listened to neither list and only caught up when
/// some other observable fired — which is exactly why the first two cards, set
/// before the count was last changed, looked fine.
///
/// Two tests, because one alone is not enough:
///
///   1. the GetX rule itself, so the trap is written down and would be caught
///      if the framework's behaviour ever changed under us;
///   2. the wizard's own source, which is what actually regressed.
void main() {
  group('an Rx read inside a nested Builder is never subscribed', () {
    testWidgets('Obx repaints when the list it read changes', (tester) async {
      final rooms = <String>[].obs;
      var builds = 0;

      await tester.pumpWidget(MaterialApp(
        home: Obx(() {
          builds += 1;
          return Text('${rooms.length} rooms', textDirection: TextDirection.ltr);
        }),
      ));
      expect(builds, 1);
      expect(find.text('0 rooms'), findsOneWidget);

      rooms.add('bathroom 3');
      await tester.pump();

      expect(builds, 2, reason: 'a read made directly inside the Obx builder '
          'must subscribe to the list');
      expect(find.text('1 rooms'), findsOneWidget);
    });

    testWidgets('a Builder in between silently breaks the subscription',
        (tester) async {
      final rooms = <String>[].obs;
      // Stands in for the other observables the wizard's own Obx reads. Without
      // one, GetX throws "the improper use of a GetX has been detected" for an
      // Obx that subscribed to nothing -- which is the same fact this test is
      // about, seen from the other side: the screen never got that warning
      // BECAUSE its outer Obx had plenty of other things to listen to, so the
      // two lists went missing in silence.
      final step = 2.obs;

      await tester.pumpWidget(MaterialApp(
        home: Obx(() => Column(children: [
              Text('step ${step.value}', textDirection: TextDirection.ltr),
              Builder(builder: (_) {
                // The read happens here, in the Builder's own build. The Obx
                // has already finished collecting.
                return Text('${rooms.length} rooms',
                    textDirection: TextDirection.ltr);
              }),
            ])),
      ));
      expect(find.text('0 rooms'), findsOneWidget);

      rooms.add('bathroom 3');
      await tester.pump();

      expect(find.text('0 rooms'), findsOneWidget,
          reason: 'THIS is the defect: the entry is in the list and the screen '
              'still shows the old one. If this ever starts failing, GetX has '
              'changed and the comment on the fix should be revisited.');

      // ...and it catches up the moment something ELSE fires, which is how the
      // first two bathroom cards came to look correct.
      step.value = 3;
      await tester.pump();
      expect(find.text('1 rooms'), findsOneWidget);
    });
  });

  group('the listing wizard reads its room lists where they are heard', () {
    // Source, because the structure is the bug. Comments are stripped first:
    // prose explaining a fix must not be what satisfies the check.
    final src = File('lib/ui/screens_host/listing/listing_wizard_screen.dart')
        .readAsLinesSync()
        .where((l) => !l.trimLeft().startsWith('//'))
        .join('\n');

    test('the rooms section is built by Obx, not by a plain Builder', () {
      final at = src.indexOf('RoomDetailSection(');
      expect(at, greaterThan(0), reason: 'the rooms section has moved or gone');

      // Walk back to whichever builder opens the block this call sits in.
      final before = src.substring(0, at);
      final obx = before.lastIndexOf('Obx(');
      final plain = before.lastIndexOf('Builder(builder:');

      expect(obx, greaterThan(plain),
          reason: 'the room lists are read inside Builder(builder: ...), which '
              'runs outside the enclosing Obx\'s dependency-collection window — '
              'so choosing a bathroom stores the answer and never repaints it');
    });

    test('both lists are read in that same block', () {
      final at = src.indexOf('RoomDetailSection(');
      final obx = src.lastIndexOf('Obx(', at);
      final block = src.substring(obx, at);
      expect(block, contains('c.bathroomDetail'),
          reason: 'the bathroom list must be READ under the Obx or nothing '
              'subscribes to it');
      expect(block, contains('c.bedroomDetail'),
          reason: 'the bedroom list must be READ under the Obx or nothing '
              'subscribes to it');
    });
  });
}
