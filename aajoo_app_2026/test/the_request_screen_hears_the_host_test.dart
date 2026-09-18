// The app's booking-confirmed screen follows the host's answer, and holds
// back the map until there is one — the same two rules the website got on
// 2026-09-17, from the same client report:
//
//   "host confirmed the booking but the renter side still shows Request sent —
//    refresh this in real time with the host response."
//   "do not give the directions till the host confirms the booking."
//
// The screen was a StatelessWidget with `awaitingApproval` passed in once,
// and it drew the "Getting there" map whether or not the host had answered.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String codeOnly(String src) => src
    .replaceAll('\r\n', '\n')
    .split('\n')
    .where((l) => !l.trimLeft().startsWith('//') && !l.trimLeft().startsWith('///'))
    .join('\n');

void main() {
  final src = codeOnly(File(
          'lib/ui/screens_renter/property_details/components/booking_confirmed_screen.dart')
      .readAsStringSync());

  test('the decision is state, not a value passed in once', () {
    expect(src, contains('class BookingConfirmedScreen extends StatefulWidget'));
    expect(src, contains('enum _Decision { waiting, confirmed, declined }'));
    expect(src, contains('bool get awaitingApproval => _awaiting;'),
        reason: 'the headline must read the live decision, not the constructor arg');
  });

  test("it hears the host's confirmation on a foreground push", () {
    expect(src, contains('FirebaseMessaging.onMessage.listen('));
    expect(src, contains("if (type == 'booking_confirmed') _settle(_Decision.confirmed);"));
    expect(src, contains("if (d['bookingId']?.toString() != widget.bookingId) return;"),
        reason: 'a push about another booking must not flip this screen');
  });

  test('and polls booking history as the fallback', () {
    expect(src, contains('Timer.periodic(const Duration(seconds: 30)'));
    expect(src, contains('UserService().getBookingHistory()'));
    expect(src, contains("lifecycleLabel(r.bookingStatusBsTitle)"));
  });

  test('both stop once the answer is known, and on dispose', () {
    final settle = src.substring(src.indexOf('void _settle('));
    expect(settle.substring(0, settle.indexOf('}')), contains('_push?.cancel();'));
    expect(settle.substring(0, settle.indexOf('}')), contains('_poll?.cancel();'));
    final dispose = src.substring(src.indexOf('void dispose()'));
    expect(dispose.substring(0, dispose.indexOf('super.dispose()')), contains('_poll?.cancel();'));
  });

  test('the map waits for the host', () {
    // StayMap is drawn only on the confirmed branch.
    final i = src.indexOf('StayMap(lat: lat, lng: lng, label: propertyName');
    expect(i, greaterThan(-1));
    final before = src.substring(i - 900 < 0 ? 0 : i - 900, i);
    // Since 2026-09-18 the lock has two keys — the host's answer, or the
    // host's own "show exact location" setting. See the_clients_five_of_18_september.
    expect(before, contains('] else if (_locationLocked) ...['));
    expect(before, contains('Directions unlock once the host confirms'));
  });

  test('a decline is said, not shown as a confirmation', () {
    expect(src, contains("The host couldn't take this one"));
    expect(src, contains("if (type == 'booking_declined' || type == 'booking_rejected')"));
  });
}
