// A held deal bars its own nights, and a decline bars the day.
//
// The website has greyed its offer button since 12 September and said which of
// three things is true. The app read `negotiation.enabled` out of the same
// payload and ignored the rest of the block, so it went on showing a live
// button and letting the server refuse the filled-in form afterwards — the
// dead end the client asked us to remove, still present on the phone.
//
// These are the same rules the web screen applies, asserted against the same
// wire shape.
//
//   flutter test test/negotiation_lock_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/models/single_property_response.dart';

/// The `negotiation` block as property.controller sends it.
Map<String, dynamic> wire({
  bool enabled = true,
  String? until,
  String? reason,
  num? price,
  String? from,
  String? to,
}) =>
    {
      'enabled': enabled,
      'lockedUntil': until,
      'lockReason': reason,
      'lockPrice': price,
      'lockFrom': from,
      'lockTo': to,
    };

void main() {
  group('reading the block', () {
    test('nothing barred reads as no lock', () {
      final lock = NegotiationLock.fromJson(wire());
      expect(lock.locked, isFalse);
      expect(lock.barsDates('12-09-2026', '13-09-2026'), isFalse);
    });

    test('an absent negotiation block leaves the button alone', () {
      // Older servers, and the signed-out case the server never asks about.
      final p = SinglePropertyData.fromJson({'property_id': 1});
      expect(p.negotiationEnabled, isTrue,
          reason: 'silence is not a refusal — the server is still the gate');
      expect(p.negotiationLock, isNull);
    });

    test('the lock rides on the same block as the switch', () {
      final p = SinglePropertyData.fromJson({
        'property_id': 1,
        'negotiation': wire(
          until: '2026-09-12T18:29:59.000Z',
          reason: 'parting',
          price: 2300,
          from: '12-09-2026',
          to: '13-09-2026',
        ),
      });
      expect(p.negotiationEnabled, isTrue);
      expect(p.negotiationLock?.locked, isTrue);
      expect(p.negotiationLock?.price, 2300);
    });
  });

  group('which nights it bars', () {
    final deal = NegotiationLock.fromJson(wire(
      until: '2026-09-12T18:29:59.000Z',
      reason: 'accepted',
      price: 2400,
      from: '12-09-2026',
      to: '13-09-2026',
    ));

    test('a held deal bars exactly its own nights', () {
      expect(deal.barsDates('12-09-2026', '13-09-2026'), isTrue);
    });

    test('...and leaves other nights open', () {
      // A guest who agreed a price for this weekend may still negotiate next
      // weekend on the same property. Scoped to the stay, not the listing.
      expect(deal.barsDates('20-09-2026', '22-09-2026'), isFalse);
      expect(deal.barsDates('12-09-2026', '14-09-2026'), isFalse,
          reason: 'a 12-14 stay is not the 12-13 stay the deal was struck for');
    });

    test('before any dates are picked, a held deal is still worth saying', () {
      expect(deal.barsDates(null, null), isTrue);
    });

    test('a decline bars the whole listing for the day', () {
      final declined = NegotiationLock.fromJson(
          wire(until: '2026-09-12T18:29:59.000Z', reason: 'declined'));
      expect(declined.barsDates('12-09-2026', '13-09-2026'), isTrue);
      expect(declined.barsDates('20-09-2026', '22-09-2026'), isTrue,
          reason: 'the day-scoped lock is about the listing, not a stay');
      expect(declined.price, 0,
          reason: 'a host who declined an opening offer never named a price');
    });
  });

  group('what it says', () {
    test('each reason gets its own words, matching the website', () {
      String label(String? reason) =>
          NegotiationLock.fromJson(wire(until: 'x', reason: reason)).shortLabel;
      expect(label('accepted'), 'Already agreed for these dates');
      expect(label('parting'), 'This negotiation has ended');
      expect(label('declined'), 'Available again tomorrow');
      // An unknown reason must not print the word "null" on a button.
      expect(label(null), 'Available again tomorrow');
    });

    test('the parting clock counts down and floors at zero', () {
      final soon = NegotiationLock.fromJson(wire(
        until: DateTime.now().add(const Duration(minutes: 42)).toIso8601String(),
        reason: 'parting',
      ));
      expect(soon.minutesLeft, inInclusiveRange(40, 42));

      final gone = NegotiationLock.fromJson(wire(
        until: DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        reason: 'parting',
      ));
      expect(gone.minutesLeft, 0,
          reason: 'a negative countdown would read as "-118 minutes left"');
    });
  });
}
