// A coupon is a percentage of the ROOM — not of the cleaning fee, the pets,
// or the extra-guest charge — and this app takes it off the same number the
// web and the server do.
//
// Client, 2026-09-14, listing 29310 (₹12,000 a night, ₹1,000 cleaning, two
// nights, a negotiated deal at ₹11,100 a night): "it should be 27376 not
// 26196 … discount and gst showing different on different pages … please
// check pricing engine all across platform."
//
//   7.5% of the room     1,800   → 23,200 with cleaning → ×1.18 = 27,376  ✓
//   7.5% of room+party           what this app's property page computed
//   7.5% of everything   1,875   what the web and the booking charged
//   room only, no fee            26,196 — the chat page's one-night booking
//
// The server mints a deal as a percentage of the room subtotal, so it only
// reproduces the agreed per-night price when applied to that same figure.
//
// Postscript, 2026-09-15: the client then decided the cleaning fee is
// STATED, not charged (§1.14), so the same stay is now 22,200 × 1.18 =
// 26,196 with the ₹1,000 said under the total rather than added to it. The
// coupon base — the point of this file — is unchanged: 7.5% of the ROOM.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/utils/booking_pricing.dart';

/// The file with comments removed, so the assertions read code, not prose.
String codeOnly(String src) => src
    .replaceAll('\r\n', '\n')
    .split('\n')
    .where((l) => !l.trimLeft().startsWith('//'))
    .join('\n');

void main() {
  group('the reported stay', () {
    test('7.5% off the room; cleaning stated, not added — 26,196', () {
      // The percentage is worked out on the room by the caller, the way the
      // property page does it, and handed in as an amount.
      final p = priceStay(
        roomSubtotal: 24000,
        perNightTariff: 12000,
        discount: 24000 * 7.5 / 100,
        cleaningFee: 1000,
      );
      expect(p.discount, 1800, reason: 'the cleaning fee is not discounted');
      expect(p.discountedRoom, 22200);
      expect(p.taxes, 3996, reason: '18% of 22,200');
      expect(p.total, 26196,
          reason: 'with the fee stated (2026-09-15) the stay is 26,196');
      expect(p.cleaningFee, 1000, reason: 'the statement still carries the figure');
    });

    test('the discount reproduces the price the host agreed to', () {
      final p = priceStay(
        roomSubtotal: 24000,
        perNightTariff: 12000,
        discount: 1800,
        cleaningFee: 1000,
      );
      expect((p.roomSubtotal - p.discount) / 2, 11100,
          reason: 'the host said yes to ₹11,100 a night');
    });
  });

  group('the fees ride through', () {
    test('every fee is outside the discount and inside the tax', () {
      final p = priceStay(
        roomSubtotal: 24000,
        perNightTariff: 12000,
        discount: 2400,
        extraGuestFee: 800,
        petFee: 600,
        cleaningFee: 1000,
      );
      expect(p.discount, 2400);
      expect(p.discountedRoom, 24000 - 2400 + 800 + 600,
          reason: 'party and pets ride through; cleaning is stated, not charged');
      expect(p.chargeable, 25400, reason: 'the price sent carries the party and the pets, not cleaning');
    });

    test('a discount is capped at the room — the fees are still owed', () {
      final p = priceStay(
        roomSubtotal: 5000,
        perNightTariff: 5000,
        discount: 99999,
        cleaningFee: 500,
      );
      expect(p.discount, 5000);
      expect(p.discountedRoom, 0,
          reason: 'nothing else is owed through the platform — cleaning is paid to the host');
    });
  });

  group('the property page asks the server about the room', () {
    final src = codeOnly(File(
            'lib/ui/screens_renter/property_details/property_page.dart')
        .readAsStringSync());

    test('the percentage is taken of _roomCharge, not room + party', () {
      final getter = src.substring(src.indexOf('double get _discountOnRoom {'));
      final body = getter.substring(0, getter.indexOf('\n  }\n'));
      expect(body, contains('final base = _roomCharge;'));
      expect(body, isNot(contains('+ _partyFee')),
          reason: 'the party charge is back in the coupon base');
      expect(body, isNot(contains('currentPriceString')),
          reason: 'the local nightly total is not what the server discounts');
    });

    test('a coupon is validated against the room', () {
      final fn = src.substring(src.indexOf('Future<void> _applyCoupon() async {'));
      final body = fn.substring(0, fn.indexOf('\n  }\n'));
      expect(body, contains('final base = _roomCharge;'));
      expect(body, isNot(contains('+ _partyFee')));
    });
  });

  group('the chat page is gone', () {
    // It used to post price x (1 + GST) for tonight with no coupon, and
    // carried its own thirty-second countdown and quick-price chips beside a
    // second implementation of one engine. The listing stopped opening it on
    // 2026-09-12; notifications kept leading back into it until 2026-09-16
    // ("Which negotiation page it is taking me from notifications??"), when
    // the page, its wrapper and its controller were deleted outright.
    test('lib/ui/screens_common/price_negotiation is not in the tree', () {
      expect(Directory('lib/ui/screens_common/price_negotiation').existsSync(),
          isFalse,
          reason: 'the pre-rebuild negotiation chat is back');
    });

    test('nothing imports it', () {
      final offenders = <String>[];
      for (final f in Directory('lib').listSync(recursive: true)) {
        if (f is! File || !f.path.endsWith('.dart')) continue;
        if (f.readAsStringSync().contains('price_negotiation/')) {
          offenders.add(f.path);
        }
      }
      expect(offenders, isEmpty);
    });

    test('a negotiation notification opens My Negotiations', () {
      final routing = codeOnly(
          File('lib/service/notification_routing_service.dart').readAsStringSync());
      expect(routing, contains('kind == NotifKind.offer'));
      expect(routing, contains('const HostNegotiationsScreen()'));
      expect(routing, contains('const GuestNegotiationsScreen()'));
      final list = codeOnly(
          File('lib/ui/screens_common/notifications/notification_screen.dart')
              .readAsStringSync());
      expect(list, contains('const GuestNegotiationsScreen()'),
          reason: 'the in-app list still assembles the old thread by hand');
    });
  });
}
