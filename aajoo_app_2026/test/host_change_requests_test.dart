import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/service/booking_modification_service.dart';
import 'package:rent_home/ui/screens_host/booking_history/host_change_requests.dart';

/// Change requests reach the host on the phone.
///
/// Reported 2026-09-10 (bug 28): a guest's request to move their dates was
/// "visible in the booking on the web, but not shown or notified anywhere in
/// the Host app". It was not a display fault — the app had no idea the feature
/// existed. No model, no service, no screen, and nothing calling
/// /host/booking/modifications, which had been serving the website all along.
///
/// Driven here rather than on a device because the populated state needs a
/// PENDING request belonging to the logged-in host, and the emulator's host
/// has no changeable booking. Manufacturing one would mean writing a booking
/// and a request into the live database to look at a widget.
void main() {
  BookingChangeRequest req({
    int id = 1,
    String oldFrom = '07-10-2026',
    String oldTo = '08-10-2026',
    int oldGuests = 2,
    String newFrom = '14-10-2026',
    String newTo = '15-10-2026',
    int newGuests = 2,
    double difference = 0,
    String? note,
  }) =>
      BookingChangeRequest(
        id: id,
        bookingId: 931569,
        status: 'pending',
        oldFrom: oldFrom,
        oldTo: oldTo,
        oldGuests: oldGuests,
        newFrom: newFrom,
        newTo: newTo,
        newGuests: newGuests,
        difference: difference,
        guestNote: note,
      );

  // A unique key per pump. Pumping the same widget type twice in one test
  // REUSES the State, so initState never re-runs and the second case asserts
  // against the first case's data — which is exactly what happened here.
  var pumpSeq = 0;

  Future<void> pump(
    WidgetTester tester, {
    required Future<List<BookingChangeRequest>?> Function() loader,
    Future<({bool ok, String message})> Function({
      required int id,
      required bool approve,
      String? note,
    })? responder,
    VoidCallback? onApplied,
  }) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: HostChangeRequests(
            key: ValueKey('pump-${pumpSeq++}'),
            loader: loader,
            responder: responder,
            onApplied: onApplied,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('a waiting request is shown, with the decision on it',
      (tester) async {
    await pump(tester, loader: () async => [req(difference: 2400)]);

    expect(find.text('1 change request'), findsOneWidget);
    // The three facts a host decides on.
    expect(find.textContaining('07-10-2026 → 08-10-2026'), findsOneWidget,
        reason: 'the dates being replaced are not shown, so there is nothing '
            'to compare the request against');
    expect(find.textContaining('14-10-2026 → 15-10-2026'), findsOneWidget);
    expect(find.text('The guest pays ₹2400 more.'), findsOneWidget);
    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
  });

  testWidgets('the money is said in words, in both directions', (tester) async {
    await pump(tester, loader: () async => [req(difference: -900)]);
    // "-900" beside a request reads as either direction depending on who is
    // looking; a host needs to know which way it goes without working it out.
    expect(find.text('You refund ₹900.'), findsOneWidget);

    await pump(tester, loader: () async => [req(difference: 0)]);
    expect(find.text('No change to the total.'), findsOneWidget);
  });

  testWidgets('a guest count change is shown even when the dates hold',
      (tester) async {
    // This is the case the bug report was actually about: the guest raised the
    // party size, not the dates.
    await pump(tester,
        loader: () async => [
              req(
                newFrom: '07-10-2026',
                newTo: '08-10-2026',
                oldGuests: 2,
                newGuests: 8,
              )
            ]);
    expect(find.textContaining('2 guests'), findsOneWidget);
    expect(find.textContaining('8 guests'), findsOneWidget);
  });

  testWidgets('NOTHING is drawn when nothing is waiting', (tester) async {
    await pump(tester, loader: () async => const []);
    expect(find.text('Approve'), findsNothing);
    // A permanent empty panel above the bookings list would train a host to
    // scroll past the one place the urgent thing appears.
    expect(find.byType(Divider), findsNothing);
    expect(find.textContaining('change request'), findsNothing);
  });

  testWidgets('THE ONE THAT MATTERS: a failed ask is not silence',
      (tester) async {
    // null is "we could not ask", which is not "nothing waiting". Rendering
    // both as an empty screen tells a host there is nothing to do when there
    // may be a request expiring.
    await pump(tester, loader: () async => null);
    expect(find.textContaining("Couldn't check"), findsOneWidget,
        reason: 'an unreachable server renders as "nothing waiting"');
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('answering reloads the list and tells the screen behind',
      (tester) async {
    var calls = 0;
    var applied = 0;
    await pump(
      tester,
      loader: () async {
        calls += 1;
        return calls == 1 ? [req()] : const [];
      },
      responder: ({required int id, required bool approve, String? note}) async =>
          (ok: true, message: 'Approved.'),
      onApplied: () => applied += 1,
    );

    expect(find.text('Approve'), findsOneWidget);
    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();

    expect(applied, 1,
        reason: 'the bookings list behind is not reloaded, so an approved '
            'change leaves the old dates on screen');
    expect(find.text('Approve'), findsNothing, reason: 'the answered request stayed');
  });

  testWidgets("a refusal shows the server's own sentence", (tester) async {
    // The server knows what this screen does not — that the price moved, that
    // the nights went while the host was deciding.
    await pump(
      tester,
      loader: () async => [req()],
      responder: ({required int id, required bool approve, String? note}) async =>
          (ok: false, message: 'The price for those dates has changed.'),
    );
    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();
    expect(find.text('The price for those dates has changed.'), findsOneWidget,
        reason: 'the real reason was replaced with a generic failure');
  });
}
