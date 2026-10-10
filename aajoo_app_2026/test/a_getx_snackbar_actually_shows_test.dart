// Every Get.snackbar in the app threw "No Overlay widget found" and showed
// nothing, on iOS and Android alike: GetX 4.6.6 found the overlay from the
// navigator's _Theater element, and Flutter 3.44's Overlay.maybeOf looks up
// a marker that sits BELOW _Theater, so the lookup could never succeed.
// Users got no error and no confirmation messages at all — found on the iOS
// Simulator, 2026-10-09. GetX 4.7.3 ("Fix Snackbar in Flutter 3.38") takes
// the navigator's OverlayState directly.
//
// This runs the app's own shape — GetMaterialApp — and requires the message
// to be on screen, so a GetX or Flutter upgrade that breaks it again fails
// here rather than on a phone.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  testWidgets('Get.snackbar shows its message in a GetMaterialApp',
      (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));

    Get.snackbar('Negotiation', 'Your offer was sent to the host',
        duration: const Duration(seconds: 2));
    await tester.pump(); // the queue starts the snackbar
    await tester.pump(const Duration(milliseconds: 600)); // and it animates in

    expect(tester.takeException(), isNull,
        reason: 'the snackbar must not throw (No Overlay widget found)');
    expect(find.text('Your offer was sent to the host'), findsOneWidget);

    // Let it time out and close so no timer outlives the test.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
