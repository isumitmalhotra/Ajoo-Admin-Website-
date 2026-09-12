// The spinner has to close even when an error toast is sitting on top of it.
//
// `Get.back()` does not do that. GetX 4.6.6, extension_navigation.dart:820:
//
//   if (isSnackbarOpen && !closeOverlays) {
//     closeCurrentSnackbar();
//     return;                        // <- the dialog is still there
//   }
//
// A snackbar is a route, so one Get.back() closes the TOAST and returns. Any
// `barrierDismissible: false` spinner underneath stays up with nothing able to
// dismiss it — and the fetch behind these spinners toasts precisely when it
// fails, so the snackbar is open exactly when the spinner most needs closing.
//
// That is how listing 29303 became impossible to open from the negotiated-deal
// banner on 2026-09-12: its payload failed to parse, UserController.getProperty
// toasted the error, and the close that followed went to the toast.
//
// `closeOverlays: true` is not the answer either — it pops until no dialog or
// bottom sheet is left and then pops AGAIN, which takes the page with it.
//
// The helper's behaviour is tested here directly. The half that needs a live
// snackbar is tested as a rule about the call sites instead: GetX's snackbar
// cannot find an Overlay under flutter_test at all (it asks `Overlay.of` from
// the Overlay's own context and the assertion fires), so there is no way to put
// a real toast on screen in this harness — and a test that cannot fail for the
// right reason is worse than one that states the rule plainly.
//
//   flutter test test/spinner_closes_under_a_toast_test.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rent_home/utils/modal_spinner.dart';

/// The spinner every one of these screens puts up while it fetches.
Future<void> showSpinner(WidgetTester tester) async {
  Get.dialog(const Center(child: CircularProgressIndicator()),
      barrierDismissible: false);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  Future<void> app(WidgetTester tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: Text('home'))),
    );
    await tester.pumpAndSettle();
  }

  group('the helper', () {
    testWidgets('closes a blocking spinner', (t) async {
      await app(t);
      await showSpinner(t);

      closeModalSpinner();
      await t.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('with nothing open it does not pop the page', (t) async {
      // It runs on paths that may already have closed the dialog, and popping
      // the page underneath would send the guest back to wherever they came
      // from instead of showing them the listing.
      await app(t);

      closeModalSpinner();
      await t.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('twice is not two pops', (t) async {
      // The error path can reach it after the success path already has.
      await app(t);
      await showSpinner(t);

      closeModalSpinner();
      closeModalSpinner();
      await t.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('home'), findsOneWidget);
    });
  });

  group('the rule at the call sites', () {
    /// Every screen that puts a blocking spinner over a fetch that can toast.
    const sites = [
      'lib/ui/screens_renter/property_details/open_property.dart',
      'lib/service/notification_routing_service.dart',
    ];

    for (final site in sites) {
      test('$site closes its spinner through closeModalSpinner', () {
        // Comments stripped first: these files EXPLAIN why Get.back() is
        // wrong, and a scan that counted the explanation would fail on the
        // very files that got it right.
        final src = File(site)
            .readAsLinesSync()
            .map((l) {
              final i = l.indexOf('//');
              return i == -1 ? l : l.substring(0, i);
            })
            .join(' ');
        expect(src.contains('barrierDismissible: false'), isTrue,
            reason: '$site no longer puts up a blocking spinner — if that is '
                'deliberate, take it off this list');
        expect(src.contains('closeModalSpinner()'), isTrue,
            reason: '$site does not use the helper');
        expect(RegExp(r'Get\.back\(\)').hasMatch(src), isFalse,
            reason: 'a bare Get.back() is back in $site. With an error toast '
                'on screen it closes the TOAST and returns, and the '
                'barrierDismissible:false spinner stays up for the rest of '
                'the session — the 29303 deal-banner hang');
      });
    }
  });
}
