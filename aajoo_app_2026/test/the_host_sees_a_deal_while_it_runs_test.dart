// Client decision, 2026-09-18: "Show in the Upcoming tab till the deal is
// running." An agreed price rides at the top of the host's Upcoming tab while
// its coupon is live, says in words that it is not a booking, and leaves the
// moment it expires.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/data/models/host_running_deal.dart';

String codeOnly(String src) => src
    .replaceAll('\r\n', '\n')
    .split('\n')
    .where((l) => !l.trimLeft().startsWith('//') && !l.trimLeft().startsWith('///'))
    .join('\n');

void main() {
  final screen = codeOnly(File('lib/ui/screens_host/booking_history/booking_history_screen.dart').readAsStringSync());
  final controller = codeOnly(File('lib/ui/screens_host/booking_history/host_booking_history_controller.dart').readAsStringSync());
  final service = codeOnly(File('lib/service/host_service.dart').readAsStringSync());

  group('the model', () {
    test('reads the row the server sends, money as number or string', () {
      final d = HostRunningDeal.fromJson({
        'dealId': 7, 'propertyId': 29291, 'propertyName': 'Aajoo Homes',
        'guestId': 179, 'guestName': 'Renter test web',
        'bookFrom': '20-09-2026', 'bookTo': '22-09-2026', 'nights': 2,
        'discountPercent': 10, 'agreedPerNight': '1800.00', 'agreedTotal': 3600,
        'agreedAt': '2026-09-18T06:00:00.000Z',
        'expiresAt': DateTime.now().add(const Duration(hours: 2)).toUtc().toIso8601String(),
        'note': 'Price agreed, not booked yet.',
      });
      expect(d.agreedPerNight, 1800);
      expect(d.agreedTotal, 3600);
      expect(d.isRunning, isTrue);
      expect(d.timeLeft(), matches(RegExp(r'^expires in (1h 59m|2h 00m)$')));
    });

    test('an older deal without a rupee figure still carries the percentage', () {
      final d = HostRunningDeal.fromJson({
        'dealId': 8, 'propertyId': 1, 'propertyName': 'P', 'guestId': 2, 'guestName': 'G',
        'discountPercent': 8, 'expiresAt': DateTime.now().add(const Duration(minutes: 40)).toIso8601String(),
      });
      expect(d.agreedPerNight, isNull);
      expect(d.nights, isNull);
      expect(d.discountPercent, 8);
      expect(d.timeLeft(), matches(RegExp(r'^expires in (39|40)m$')));
    });

    test('an unparseable deadline counts as expired, never as forever', () {
      final d = HostRunningDeal.fromJson({'dealId': 9, 'propertyId': 1, 'propertyName': 'P', 'guestId': 2, 'guestName': 'G', 'expiresAt': 'soon'});
      expect(d.isRunning, isFalse);
      expect(d.timeLeft(), 'expired');
    });
  });

  group('the screen', () {
    test('deals ride at the top of Upcoming only, and an Upcoming tab with only deals is not empty', () {
      expect(screen, contains('final deals = bucket == 0 ? controller.liveDeals : const <HostRunningDeal>[];'));
      expect(screen, contains('child: items.isEmpty && deals.isEmpty'));
      expect(screen, contains('itemCount: deals.length + items.length,'));
      expect(screen, contains('? _DealCard(deals[index], now: controller.now.value)'));
    });

    test('the card says it is a price, not a stay', () {
      expect(screen, contains("Text('Price agreed',"));
      expect(screen, contains("'Not booked yet · \${deal.timeLeft(now)}'"));
      expect(screen, contains('Text(deal.note,'));
    });

    test('the controller re-reads every minute, ticks the clock, and drops expired deals itself', () {
      expect(controller, contains('Timer.periodic(const Duration(seconds: 60), (_) => getRunningDeals());'));
      expect(controller, contains('runningDeals.where((d) => d.expiresAt.isAfter(now.value))'));
      expect(controller, contains('_dealsTimer?.cancel();'));
      expect(service, contains('_dio.get("/host/deals/running")'));
      expect(service, contains('return const [];'), reason: 'a deals failure must not take the bookings list with it');
    });
  });
}
