// The 300-case run (batch 6, 2026-09-20, NG-022) watched a host's
// Negotiations list on this app while the guest countered from the website:
// nothing moved until pull-to-refresh. The website flips its card the moment
// the server emits; the app had two sockets and neither was open on that
// screen nor subscribed to any `negotiation:*` / `notification:new` event.
//
// One socket per signed-in person now (LiveChannel), connected at sign-in and
// on a restored session, dropped at sign-out; the screens that show what the
// server announces reload on its events.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/service/live_channel.dart';

String codeOnly(String src) => src
    .replaceAll('\r\n', '\n')
    .split('\n')
    .where((l) => !l.trimLeft().startsWith('//') && !l.trimLeft().startsWith('///'))
    .join('\n');

String read(String p) => codeOnly(File(p).readAsStringSync());

void main() {
  group('the live channel', () {
    test('names every event the server emits to a person', () {
      expect(LiveChannel.negotiationEvents, containsAll(['negotiation:new_offer', 'negotiation:guest_reply', 'negotiation:host_reply', 'negotiation:auto_countered', 'negotiation:auto_booked']));
      expect(LiveChannel.notificationEvent, 'notification:new');
      expect(LiveChannel.allEvents.length, 6);
    });

    test('is one per person: connected at sign-in and on a restored session, dropped at sign-out', () {
      final auth = read('lib/ui/screens_common/auth/auth_controller.dart');
      expect(auth, contains('unawaited(LiveChannel.instance.connect());'), reason: 'a fresh sign-in must open the room');
      expect(auth, contains('LiveChannel.instance.dispose();'), reason: 'the room is the person\'s — the next account must not inherit it');
      expect(auth.indexOf('MessagesService.instance.dispose();') < auth.indexOf('LiveChannel.instance.dispose();'), isTrue, reason: 'both sockets go at sign-out, together');
      final splash = read('lib/ui/screens_common/splash/splash_screen.dart');
      expect(splash, contains('unawaited(LiveChannel.instance.connect()'), reason: 'a session restored on launch must hear the room too');
    });

    test('a second reload within the gap is one reload', () async {
      var reloads = 0;
      final r = LiveReload(() async { reloads += 1; }, gap: const Duration(milliseconds: 30));
      r.poke(); r.poke(); r.poke();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(reloads, 1, reason: 'a counter-back emits for the row and for the bell; that is one change on screen');
      r.poke();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(reloads, 2);
      r.cancel();
    });
  });

  group('the screens that show what the server announces reload on it', () {
    test('the host Negotiations list', () {
      final s = read('lib/ui/screens_host/negotiations/host_negotiations_screen.dart');
      expect(s, contains('.on(LiveChannel.negotiationEvents)'));
      expect(s, contains('.listen((_) => _reload.poke());'));
      expect(s, contains('LiveReload(() => hostController.getNegotiations())'));
      expect(s, contains('_live?.cancel();'), reason: 'a subscription that outlives the screen reloads a dead widget');
    });

    test('the guest Negotiations list', () {
      final s = read('lib/ui/screens_renter/negotiations/guest_negotiations_screen.dart');
      expect(s, contains('.on(LiveChannel.negotiationEvents)'));
      expect(s, contains('LiveReload(() => c.loadNegotiations())'));
      expect(s, contains('_live?.cancel();'));
    });

    test('the host bell — the badge and the list', () {
      final count = read('lib/ui/screens_host/notifications/host_notification_count.dart');
      expect(count, contains('.on(const [LiveChannel.notificationEvent])'));
      expect(count, contains('.listen((_) => reload());'));
      final list = read('lib/ui/screens_host/notifications/host_notifications_screen.dart');
      expect(list, contains('.on(const [LiveChannel.notificationEvent])'));
      expect(list, contains('.listen((_) => _load());'));
    });

    test('the host dashboard\'s "Offers to review" tile', () {
      final s = read('lib/ui/screens_host/home/host_home_screen.dart');
      expect(s, contains('.on(LiveChannel.negotiationEvents)'));
      expect(s, contains('LiveReload(() => hostController.getNegotiations())'));
    });
  });

  group('the guest checks out of a stay that is running, not a request', () {
    // The website's Next Booking page offered Check out on a request the host
    // had an hour left to answer (Defect 14, 2026-09-20); the app's ongoing
    // view keyed its Checkout on "paid" alone and had the same hole.
    test('Checkout waits for the host and the clock', () {
      final s = read('lib/ui/screens_renter/home/view_ongoing_booking.dart');
      expect(s, contains('] else if (_stayIsRunning) ...['), reason: 'Checkout is shown on paid alone again');
      final g = s.substring(s.indexOf('bool get _stayIsRunning {'), s.indexOf('Widget build(BuildContext context)'));
      expect(g, contains("if (label == 'Awaiting approval'"), reason: 'a request is not a stay');
      expect(g, contains("if (label == 'Staying now') return true;"), reason: "the host's check-in outranks the clock");
      expect(g, contains('return isStaying(d.btBookFrom, d.btBookTo, hours: b.stayHours);'), reason: "otherwise the listing's own hours decide");
    });
  });

  group('a deal that has been booked reads Booked', () {
    // After B326241 was booked on its deal (2026-09-20) the card still read
    // "Accepted / Book at the agreed price" over a spent coupon.
    test('the model carries the booking and the screen renders the state', () {
      final m = read('lib/models/guest_negotiation.dart');
      expect(m, contains("bookingId: _s(j['bookingId']),"));
      final s = read('lib/ui/screens_renter/negotiations/guest_negotiations_screen.dart');
      expect(s.indexOf("] else if (n.status == 'booked') ...[") < s.indexOf("] else if (n.status == 'accepted') ...["), isTrue,
          reason: 'booked must be checked before accepted');
      expect(s, contains("case 'booked':"));
      expect(s, contains("'highlight': n.bookingId,"), reason: 'the button must open the booking');
      expect(s, contains("n.status == 'accepted' || n.status == 'booked'"), reason: 'the Accepted tab keeps a booked deal');
    });
  });

  group('a checked-out stay is filed under Completed', () {
    // B021812 (20-21 Sep) was checked out on the 20th and sat under Ongoing,
    // badged "Completed", with no review link: the tab read the calendar and
    // only the calendar. The explicit event beats the clock, both ways.
    test('the explicit check-out beats the dates', () {
      final s = read('lib/ui/screens_host/booking_history/booking_history_screen.dart');
      final bucket = s.substring(s.indexOf('int _bucket('), s.indexOf('return 0; // Upcoming'));
      expect(bucket, contains('if (checkedOut) return 2; // Completed'));
      expect(bucket.indexOf('if (checkedOut) return 2;') < bucket.indexOf('if (hasEnded(to, hours: hours)) return 2;'), isTrue,
          reason: 'the check-out must be read before the calendar decides');
      expect(bucket.indexOf("if (s.contains('cancel')) return 3;") < bucket.indexOf('if (checkedOut) return 2;'), isTrue,
          reason: 'cancelled still wins over everything');
    });
  });
}
