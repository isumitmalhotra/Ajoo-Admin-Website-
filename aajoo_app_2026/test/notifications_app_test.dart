import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The renter's notifications, on the app side.
///
/// The client's report was that a renter has no way to see notifications
/// without going looking in the profile menu, that the count should show and
/// go down once they are opened, and that opening one should land on the thing
/// it was about. Each was a separate fault:
///
///   the home bell opened the list and showed no sign there was anything in it
///   the count was the LENGTH of the fetched list, which counts a page
///   the list asked for unread rows only, so reading one erased it
///   the model dropped un_bookingId, so a notification about one stay could
///     only ever open a list of stays
///   "You're checked in" matched neither "check-in" nor "checkin" and fell
///     through to the home screen
///
/// Read as source because these are wiring facts across widgets, services and
/// a GetX controller; pumping them would need the whole app and a live API.
void main() {
  String read(String p) => File(p).readAsStringSync();

  final header = read('lib/ui/screens_renter/home/components/branded_header.dart');
  final home = read('lib/ui/screens_renter/home/homescreen.dart');
  final profile = read('lib/ui/screens_renter/profile/profile_screen.dart');
  final controller = read('lib/ui/screens_common/notifications/notication_controller.dart');
  final service = read('lib/service/notification_service.dart');
  final model = read('lib/models/notification_response_model.dart');
  final link = read('lib/utils/notification_link.dart');
  final screen = read('lib/ui/screens_common/notifications/notification_screen.dart');
  final history = read('lib/ui/screens_renter/history/history_page.dart');
  final card = read('lib/ui/screens_renter/history/components/booking_cart.dart');

  group('you can see there is something to read', () {
    test('the home bell carries a count', () {
      expect(header.contains('final int unreadCount'), isTrue,
          reason: 'the bell gave no sign there was anything behind it');
      expect(home.contains('unreadCount: notificationController.notificationCount.value'), isTrue,
          reason: 'and the home screen has to feed it the live number');
      expect(home.contains('Obx(() => BrandedHeader('), isTrue,
          reason: 'without Obx the badge is whatever it was when the screen built');
    });

    test('the profile entry carries one too', () {
      expect(profile.contains('badge: _notifications.notificationCount.value'), isTrue,
          reason: 'the menu is the other way in, and it was silent as well');
    });
  });

  group('the number is true, and it comes down', () {
    test('it is the server COUNT, not the length of what was fetched', () {
      expect(controller.contains('response.data.unreadCount'), isTrue);
      expect(controller.contains('notifications.length'), isFalse,
          reason: 'the list is the history now — counting it would badge rows '
              'the guest has already read');
      expect(model.contains("json['unreadCount']"), isTrue);
    });

    test('opening one drops the badge immediately, and puts it back on failure', () {
      expect(controller.contains('notificationCount.value -= 1'), isTrue,
          reason: 'the badge is on the bell they are looking at');
      expect(controller.contains('notificationCount.value += 1'), isTrue,
          reason: 'a rejected mark-read must not leave a badge that is too low');
    });

    test('there is a one-tap way to clear it', () {
      expect(service.contains('/user/notification/read-all'), isTrue);
      expect(controller.contains('Future<void> markAllAsRead'), isTrue);
      expect(screen.contains('markAllAsRead'), isTrue,
          reason: 'and it has to be reachable from the screen');
    });

    test('coming back from the list re-asks the server', () {
      expect(controller.contains('Future<void> refreshCount'), isTrue);
      expect(home.contains('notificationController.refreshCount()'), isTrue);
    });
  });

  group('history', () {
    test('the list asks for read and unread', () {
      expect(service.contains('"scope": "all"'), isTrue,
          reason: 'reading a notification used to remove it from the only '
              'screen that listed it');
      expect(service.contains('bool history = true'), isTrue,
          reason: 'and a caller that only wants the count can skip it');
    });
  });

  group('the host side', () {
    final hostHome = read('lib/ui/screens_host/home/host_home_screen.dart');
    final hostMenu = read('lib/ui/screens_host/profile/host_menu.dart');
    final count = read('lib/ui/screens_host/notifications/host_notification_count.dart');

    // The host notifications SCREEN has always counted unread and shown it at
    // the top. Both ways IN to that screen were silent, so a host had no reason
    // to open it — and since hosts are now pushed to their phones, a silent
    // bell is worse than it was: the push arrives and the app looks empty.
    test('the host home bell carries a count', () {
      expect(hostHome.contains('_notifCount.unread.value'), isTrue);
      expect(hostHome.contains('Obx(() {'), isTrue,
          reason: 'without Obx the badge is frozen at whatever it was on build');
      expect(hostHome.contains('_notifCount.reload()'), isTrue,
          reason: 'and it needs a number before the host looks, not after');
    });

    test('the host menu row carries the same one', () {
      expect(hostMenu.contains('badge: Get.isRegistered<HostNotificationCount>()'), isTrue);
      expect(hostMenu.contains('return Obx(() {'), isTrue,
          reason: 'the entries read the count as they are built, so the list '
              'itself has to be the reactive scope');
    });

    test('one owner for the number', () {
      expect(hostHome.contains('Get.put(HostNotificationCount(), permanent: true)'), isTrue,
          reason: 'two owners would disagree about how many are waiting');
      expect(count.contains('Future<void> reload()'), isTrue);
      expect(count.contains('Future<void> refresh()'), isFalse,
          reason: 'GetxController.refresh() is its own thing, used internally '
              'to rebuild — shadowing it is asking for trouble');
    });

    test('a failed count keeps the last figure', () {
      expect(count.contains('// Signed out, offline, or the endpoint is unwell.'), isTrue,
          reason: 'flashing a zero claims all-clear on a request that never '
              'answered');
    });
  });

  group('it lands on the right thing', () {
    test('a check-in notice is a booking, not an unknown', () {
      // Anchored between the previous rule and this one, so the captured list
      // is the booking needles and nothing else.
      // Capture INSIDE has([...]), not from the comment above it: an
      // apostrophe in prose ("website's") pairs with the next quote and shifts
      // every needle by one, so the extracted list becomes the gaps between
      // the strings rather than the strings.
      final m = RegExp(r'NotifKind\.account;[\s\S]*?if \(has\(\[([\s\S]*?)\]\)\)')
          .firstMatch(link);
      expect(m, isNotNull, reason: 'the booking classifier is gone');
      final needles = RegExp("'([^']+)'")
          .allMatches(m!.group(1)!)
          .map((x) => x.group(1)!)
          .toList();
      expect(needles, isNotEmpty, reason: 'no needles were captured');
      bool has(String t) => needles.any((n) => t.contains(n));
      expect(has("you're checked in your host confirmed your arrival."), isTrue,
          reason: 'the title says "checked in" — it matches neither "check-in" '
              'nor "checkin", so this landed on the home screen');
      expect(has('check_in'), isTrue, reason: 'and the payload type uses an underscore');
    });

    test('the booking reference survives the model and reaches the destination', () {
      expect(model.contains('unBookingId'), isTrue,
          reason: 'the server has always sent un_bookingId and this dropped it');
      expect(screen.contains('bookingId: notification.unBookingId'), isTrue);
      expect(link.contains("'highlight': bookingId"), isTrue);
    });

    test('the bookings list points at the row rather than the top', () {
      expect(history.contains('_highlightId'), isTrue);
      expect(history.contains('Scrollable.ensureVisible'), isTrue,
          reason: 'flashing a card below the fold helps nobody');
      expect(history.contains('GuestShellScope.maybeOf(context) != null'), isTrue,
          reason: 'as the shell tab, Get.arguments belongs to the shell — an '
              'unrelated argument would flash a card nobody asked about');
    });

    test('the highlight is an arrival, not a permanent state', () {
      expect(card.contains('tween: Tween(begin: highlight ? 1 : 0, end: 0)'), isTrue,
          reason: 'it fades OUT, so the card ends up looking like every other '
              'card instead of staying marked');
    });
  });
}
