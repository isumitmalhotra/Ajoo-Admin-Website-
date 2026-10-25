import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// The app half of room-level booking.
///
/// Client, 2026-10-20: a guesthouse with twelve rooms at four prices cannot be
/// listed today, because a listing is one bookable thing. The host wizard now
/// carries the switch and the room editor on both platforms.
///
/// Three properties have to hold, and each one fails SILENTLY if it breaks —
/// nothing throws, the form simply does the wrong thing:
///
///   1. ABSENT MEANS WHOLE. Every build already in the stores sends no
///      rental_mode, and every listing saved before this existed has none.
///      If the app ever defaults to by_room, or stops sending the field, a
///      listing changes how it sells without anyone touching it.
///
///   2. MySQL HANDS BACK 1 AND 0, not true and false. The buyout checkbox
///      tests `!= false`. Left unconverted, every by-room property reopens
///      with "also let guests book the whole property" unticked, and a host
///      who presses Continue turns off their own buyout without being asked.
///
///   3. THE LAST ROOM CARD CANNOT BE REMOVED. A by-room property with no
///      rooms is a state the server refuses anyway, and an empty screen
///      leaves the host nothing to type into.
///
/// Read from source rather than by driving the controller: instantiating it
/// pulls in GetX bindings and a Dio client, and a test that needs a network
/// stack to check a default is a test nobody runs.
void main() {
  final controller = File(
    'lib/ui/screens_host/listing/listing_wizard_controller.dart',
  ).readAsStringSync();
  final screen = File(
    'lib/ui/screens_host/listing/listing_wizard_screen.dart',
  ).readAsStringSync();
  final editor = File(
    'lib/ui/screens_host/listing/widgets/room_types_editor.dart',
  ).readAsStringSync();
  final schema = File('lib/models/listing_schema.dart').readAsStringSync();
  final service = File('lib/service/listing_service.dart').readAsStringSync();

  group('absent means whole', () {
    test('the form starts on whole, not by_room', () {
      expect(controller.contains("'rental_mode': 'whole'"), isTrue,
          reason: 'a new listing must behave exactly as every listing does today');
    });

    test('buyout starts on', () {
      expect(controller.contains("'buyout_enabled': true"), isTrue,
          reason: 'a host switching to by-room still wants the full-house '
              'booking they were taking yesterday');
    });

    test('the switch is only drawn when the server offers the modes', () {
      expect(screen.contains('s.rentalModes.isNotEmpty'), isTrue,
          reason: 'a build held against an older backend must show the form '
              'it shows today');
    });

    test('rentalModes defaults to empty rather than throwing', () {
      expect(schema.contains('this.rentalModes = const []'), isTrue);
    });
  });

  group('the 1/0 that would turn off a buyout', () {
    test('buyout_enabled is coerced to a bool when the draft loads', () {
      expect(controller.contains("f['buyout_enabled'] ="), isTrue,
          reason: 'MySQL returns TINYINT as 1/0 and the checkbox tests != false');
      expect(controller.contains("== '1'"), isTrue,
          reason: 'the coercion has to accept the number MySQL actually sends');
    });

    test('the checkbox reads != false, so an unknown value stays ticked', () {
      // Deliberately not `== true`: a value the coercion missed would then
      // read as off, which is the damaging direction.
      expect(screen.contains("c.f['buyout_enabled'] != false"), isTrue);
    });
  });

  group('the room editor', () {
    test('the last room card cannot be removed', () {
      expect(controller.contains('roomTypes.length <= 1'), isTrue);
    });

    test('a blank room card carries no price', () {
      final blank = controller.substring(
        controller.indexOf('Map<String, dynamic> blankRoomType()'),
        controller.indexOf('/// Load the rooms this property already has'),
      );
      for (final key in ['nightlyPrice', 'weeklyPrice', 'monthlyPrice']) {
        expect(blank.contains("'$key': ''"), isTrue,
            reason: '$key must start empty — a guessed rate is somebody\'s revenue');
      }
    });

    test('room types save through their own endpoint, not a step', () {
      expect(service.contains("_post('listing/room-types'"), isTrue);
      expect(service.contains("listing/room-types/\$propertyId"), isTrue);
    });

    test('getRoomTypes always answers with a list, never null', () {
      expect(service.contains('<Map<String, dynamic>>[]'), isTrue,
          reason: 'a shape that varies with whether there is a record is what '
              'stopped two screens in this app from opening at all');
    });

    test("the server's refusal is shown as written", () {
      expect(controller.contains('e.message'), isTrue,
          reason: 'ListingException carries a sentence composed for the host');
    });

    test('the quantity field warns against one card per room', () {
      expect(editor.contains('not four room types'), isTrue,
          reason: 'the migration tool groups BY NAME, so four cards called '
              '"Deluxe Room" read as four room types — and quantity is the '
              'number availability counts against');
    });
  });

  group('the pricing step', () {
    test('the rooms editor only appears once a draft exists', () {
      expect(screen.contains('c.propertyId.value != null'), isTrue,
          reason: 'rooms are saved against a property id');
    });

    test('a by-room property relabels its own price as the buyout', () {
      expect(screen.contains("'Whole-property price'"), isTrue);
      expect(screen.contains('not the '), isTrue,
          reason: 'the client was explicit that a buyout is set by the host '
              'and is never the sum of the rooms');
    });
  });
}
