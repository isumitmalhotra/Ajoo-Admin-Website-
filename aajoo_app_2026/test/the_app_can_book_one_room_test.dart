// A guest on the app can book a room, and the app does not do the sums.
//
// Room-level booking, phase 2. The host wizard has been able to list a
// property room by room since build 128; until this the app had no renter
// side at all, so a host could create inventory on their phone that an app
// guest could not buy. The web could. That is the parity gap this closes.
//
// ── What is actually being guarded ─────────────────────────────────────────
//
// The arithmetic lives on the server and must stay there. GST on
// accommodation is banded per room per night, so two ₹2,400 rooms are two 5%
// supplies while their ₹9,600 sum would look like an 18% one. This app
// already carries utils/gst.dart because a client that reinvents the slab
// rule gets it wrong, and booking_pricing.dart records the bill: a guest
// quoted ₹23,020 and charged ₹24,171.
//
// So these tests check that the model READS what the server sent, that a
// figure it cannot read never becomes a zero, and that the widget never
// multiplies anything.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/models/room_quote_model.dart';

/// The shape POST /pricing/rooms actually answers with — two ₹2,400 Deluxe
/// rooms and one ₹9,000 Suite, priced by the server for two nights.
Map<String, dynamic> serverAnswer({Map<String, dynamic>? selection}) => {
      'rentalMode': 'by_room',
      'rooms': [
        {
          'roomTypeId': 31,
          'name': 'Deluxe Garden Room',
          'description': 'Ground floor, opens onto the lawn.',
          'beds': [
            {'type': 'Double', 'count': 1}
          ],
          'photos': ['a.jpg', 'b.jpg', 'c.jpg'],
          'totalGuests': 3,
          'guestsIncluded': 2,
          'extraGuestPrice': 500,
          'quantity': 4,
          'free': 3,
          'soldOut': false,
          'priced': true,
          'nightCount': 2,
          // ₹4,800 of room plus 5% — the slab the SERVER chose.
          'perUnit': {'grandTotal': 5040, 'longStayLabel': null},
        },
        {
          'roomTypeId': 32,
          'name': 'Family Suite',
          'beds': [],
          'photos': [],
          'totalGuests': 4,
          'quantity': 1,
          'free': 0,
          'soldOut': true,
          'priced': true,
          'nightCount': 2,
          'perUnit': {'grandTotal': 21240, 'longStayLabel': 'Weekly rate'},
        },
      ],
      'buyout': {
        'enabled': true,
        'available': false,
        'reason': 'Some rooms are already booked for those nights.',
        'priced': true,
        'grandTotal': 35400,
      },
      'petsAllowed': true,
      'securityDeposit': 5000,
      'depositRefundable': true,
      'selection': selection,
    };

void main() {
  group('the app reads the server\'s room quote', () {
    test('a room carries the price the SERVER worked out, tax included', () {
      final q = RoomQuote.fromJson(serverAnswer());
      expect(q.byRoom, isTrue);
      expect(q.rooms, hasLength(2));

      final deluxe = q.rooms.first;
      expect(deluxe.name, 'Deluxe Garden Room');
      // 5,040, not 4,800 and not anything this app multiplied out.
      expect(deluxe.perUnitGrandTotal, 5040);
      expect(deluxe.nightCount, 2);
    });

    test('free is a COUNT, which is the whole point of the feature', () {
      final q = RoomQuote.fromJson(serverAnswer());
      expect(q.rooms.first.free, 3);
      expect(q.rooms.first.quantity, 4);
      // "Only 1 left" is what makes a guest decide now; a yes/no does not.
      expect(q.rooms.last.free, 0);
      expect(q.rooms.last.soldOut, isTrue);
    });

    test('a sold-out room keeps its price, so a guest sees what they missed',
        () {
      final q = RoomQuote.fromJson(serverAnswer());
      final suite = q.rooms.last;
      expect(suite.soldOut, isTrue);
      expect(suite.priced, isTrue);
      expect(suite.perUnitGrandTotal, 21240);
    });

    test('the two slabs survive the hop, unblended', () {
      // A ₹2,400 room at 5% beside a ₹9,000 room at 18%. If anything in this
      // app ever averaged them, one of the two would be misstated.
      final q = RoomQuote.fromJson(serverAnswer());
      expect(q.rooms.first.perUnitGrandTotal, 5040); // 4,800 + 5%
      expect(q.rooms.last.perUnitGrandTotal, 21240); // 18,000 + 18%
    });

    test('the buyout is the host\'s own price, never the sum of the rooms',
        () {
      // Client decision 1, 2026-10-20. Three rooms at the figures above come
      // to far more than 35,400, which is exactly why it is read, not added.
      final q = RoomQuote.fromJson(serverAnswer());
      expect(q.buyout.grandTotal, 35400);
      expect(q.buyout.available, isFalse);
      expect(q.buyout.reason, contains('already booked'));
    });

    test('the booking-level charges are read, and stated apart', () {
      final q = RoomQuote.fromJson(serverAnswer());
      expect(q.securityDeposit, 5000);
      expect(q.depositRefundable, isTrue);
      expect(q.petsAllowed, isTrue);
    });

    test('a whole-let property answers "whole" and shows nothing', () {
      // Almost the entire catalogue. The widget returns a SizedBox.shrink()
      // on this, and the page prices the stay the way it always has.
      final q = RoomQuote.fromJson({'rentalMode': 'whole', 'rooms': []});
      expect(q.byRoom, isFalse);
      expect(q.rooms, isEmpty);
    });
  });

  group('a selection', () {
    test('is read line by line, with the total the server charged', () {
      final q = RoomQuote.fromJson(serverAnswer(selection: {
        'problem': null,
        'lines': [
          {
            'roomTypeId': 31,
            'name': 'Deluxe Garden Room',
            'units': 2,
            'nightCount': 2,
            'roomSubtotal': 9600,
            'extraGuestFee': 0,
            'total': 10080,
          },
        ],
        'roomsTotal': 9600,
        'petFee': 600,
        'cleaningFee': 800,
        'tax': 480,
        'grandTotal': 10680,
      }));

      final sel = q.selection!;
      expect(sel.ok, isTrue);
      expect(sel.lines.single.units, 2);
      expect(sel.lines.single.roomSubtotal, 9600);
      // 5% on each of two ₹2,400 rooms, NOT 18% on their ₹9,600 sum.
      expect(sel.tax, 480);
      expect(sel.grandTotal, 10680);
    });

    test('a refusal carries the server\'s own words and no total', () {
      // "Only 2 Deluxe room left" tells a guest what to do; a client that
      // rewrites it ends up saying "unavailable".
      final q = RoomQuote.fromJson(serverAnswer(selection: {
        'problem': 'Only 2 Deluxe Garden Room left for those dates.',
        'lines': [],
        'grandTotal': 0,
      }));
      final sel = q.selection!;
      expect(sel.ok, isFalse);
      expect(sel.problem, contains('Only 2'));
      expect(sel.lines, isEmpty);
    });

    test('the cleaning fee is read but is NOT in the total', () {
      // Stated, not charged — client decision, 2026-09-15.
      final q = RoomQuote.fromJson(serverAnswer(selection: {
        'problem': null,
        'lines': [
          {'roomTypeId': 31, 'name': 'Deluxe', 'units': 1, 'total': 5040}
        ],
        'roomsTotal': 4800,
        'cleaningFee': 800,
        'tax': 240,
        'grandTotal': 5040,
      }));
      final sel = q.selection!;
      expect(sel.cleaningFee, 800);
      // 4,800 + 240 = 5,040. The 800 is beside it, not inside it.
      expect(sel.grandTotal, 5040);
    });
  });

  group('what must never happen', () {
    test('a price the app cannot read does not become zero', () {
      /**
       * `priced: false` is the server saying the host has no rate for these
       * dates. It is NOT sold out and it is NOT free. A ₹0 on a room is the
       * one unforgivable answer, so the widget reads `priced` and shows no
       * figure at all.
       */
      final q = RoomQuote.fromJson({
        'rentalMode': 'by_room',
        'rooms': [
          {
            'roomTypeId': 40,
            'name': 'Annexe',
            'quantity': 2,
            'free': 2,
            'priced': false,
            // No perUnit block at all, which is what the server sends.
          }
        ],
      });
      final room = q.rooms.single;
      expect(room.priced, isFalse);
      expect(room.free, 2, reason: 'free and priced are different questions');
    });

    test('a string price from a looser backend still parses', () {
      // Money has arrived as a string from this backend before — see
      // an_ongoing_booking_with_a_text_price_still_parses_test.dart.
      final q = RoomQuote.fromJson({
        'rentalMode': 'by_room',
        'rooms': [
          {
            'roomTypeId': 41,
            'name': 'Deluxe',
            'quantity': '4',
            'free': '3',
            'priced': true,
            'perUnit': {'grandTotal': '5040.00'},
          }
        ],
      });
      final room = q.rooms.single;
      expect(room.quantity, 4);
      expect(room.free, 3);
      expect(room.perUnitGrandTotal, 5040);
    });

    test('a missing rooms list is an empty list, never a crash', () {
      // "Empty Data Is an Array" — this backend has answered `data: {}` where
      // a list was expected, and two app screens stopped opening at all.
      final q = RoomQuote.fromJson({'rentalMode': 'by_room'});
      expect(q.rooms, isEmpty);
      expect(q.selection, isNull);
    });

    test('THE WIDGET MULTIPLIES NOTHING', () {
      /**
       * The rule this whole feature rests on. Read as source because the
       * failure is an expression that should not exist — a widget that
       * computes `units * price` would pass every test above and still
       * charge the wrong tax.
       *
       * The web half holds the same line for the same reason.
       */
      final src = File(
        'lib/ui/screens_renter/property_details/widgets/room_type_table.dart',
      ).readAsStringSync();

      /**
       * A `*` next to a price or a count, in EITHER order.
       *
       * The first version of this only matched `count * price`, so the
       * mutation `perUnitGrandTotal * units` sailed through — found by
       * running the mutation rather than by reading the regex, which is the
       * only way these are ever found.
       */
      // Written out as four raw literals rather than built by interpolation:
      // a regex assembled from pieces is one more place for an escape to be
      // lost, and losing one here turns this guard off in silence.
      for (final pattern in [
        RegExp(r'(units|quantity|free)\s*\*'),
        RegExp(r'\*\s*(units|quantity|free)'),
        RegExp(r'(perUnitGrandTotal|roomSubtotal|grandTotal|extraGuestFee|petFee|tax)\s*\*'),
        RegExp(r'\*\s*(perUnitGrandTotal|roomSubtotal|grandTotal|extraGuestFee|petFee|tax)'),
      ]) {
        expect(
          pattern.hasMatch(src),
          isFalse,
          reason: 'the widget multiplies a price or a count ($pattern) — '
              'GST is banded per room per night and the server owns that sum',
        );
      }
      // And it renders the server's own refusal rather than its own words.
      expect(src.contains('sel.problem!'), isTrue,
          reason: 'the widget invents its own refusal text');
    });

    test('the booking payload sends the picks, and only when there are some',
        () {
      /**
       * Dropping `rooms` silently is the failure to fear: the booking would
       * be created as a BUYOUT of the whole guesthouse at whatever `price`
       * said. An empty list asks a different question of the server and comes
       * back refused, so it is omitted rather than sent empty.
       */
      final src = File(
        'lib/ui/screens_renter/property_details/property_page.dart',
      ).readAsStringSync();

      expect(src.contains('"rooms": _roomChoice!.picks'), isTrue,
          reason: 'the chosen rooms never reach /booking/create');
      expect(src.contains('_roomChoice?.picks.isNotEmpty'), isTrue,
          reason: 'an empty selection would be sent as a selection');
      // And a by-room stay with no rooms is turned back rather than becoming
      // a buyout at the top of the sheet.
      expect(src.contains('Choose your rooms'), isTrue,
          reason: 'a by-room property can be booked with no rooms chosen');
    });
  });
}
