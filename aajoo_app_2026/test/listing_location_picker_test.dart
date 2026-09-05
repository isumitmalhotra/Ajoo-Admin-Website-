// The app's listing wizard had no map at all.
//
// It asked hosts to type the whole address and never captured a coordinate, so
// a listing created on the app had no pin — and a property with no pin is
// returned by no location search. It sat in the catalogue and was invisible in
// the one place guests look. Six of the catalogue's listings are in that state.
//
// These pin the parts that are pure logic; the sheet itself is exercised on a
// device.
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/service/geocode_service.dart';

void main() {
  group('PickedAddress', () {
    test('reads every field the wizard asks for', () {
      // The backend's own field names — see toAddressFields in the geocode
      // controller. Reading only city and state, which is all the guest-side
      // search needed, would leave four boxes on the form empty.
      final a = PickedAddress.fromJson(31.62, 74.8765, {
        'label': '255, Golden Temple Rd, Katra Ahluwalia, Amritsar, Punjab 143006, India',
        'address': {
          'state': 'Punjab',
          'district': 'Amritsar',
          'city': 'Amritsar',
          'village': 'Katra Ahluwalia',
          'pincode': '143006',
          'street': '255 Golden Temple Rd, Katra Ahluwalia',
        },
      });
      expect(a.lat, 31.62);
      expect(a.lng, 74.8765);
      expect(a.state, 'Punjab');
      expect(a.district, 'Amritsar');
      expect(a.city, 'Amritsar');
      expect(a.village, 'Katra Ahluwalia');
      expect(a.pincode, '143006');
      expect(a.street, '255 Golden Temple Rd, Katra Ahluwalia');
      expect(a.isEmpty, isFalse);
    });

    test('a lookup that found nothing is empty, not a crash', () {
      // The pin still counts — coordinates are the one thing the form cannot
      // do without — so a bare response must produce a usable object.
      final a = PickedAddress.fromJson(28.6, 77.2, const {});
      expect(a.isEmpty, isTrue);
      expect(a.lat, 28.6);
      expect(a.street, '');
    });

    test('missing pieces come back as empty strings, never null', () {
      final a = PickedAddress.fromJson(28.6, 77.2, {
        'address': {'city': 'Karnal'}
      });
      expect(a.city, 'Karnal');
      expect(a.state, '');
      expect(a.street, '');
      expect(a.isEmpty, isFalse, reason: 'a city alone is still an address');
    });
  });

  group('applying a pin to the form', () {
    // The rule the wizard uses, stated once here so it can be checked without
    // building the screen: nudging the pin inside one town fills only what was
    // found, and MOVING it to another town replaces the block outright.
    //
    // Merging across a move is what left "Karnal Division" in District under an
    // Amritsar address on the website, with nothing on screen to say which half
    // was stale.
    String take(String next, String current, {required bool moved}) =>
        moved ? next : (next.isNotEmpty ? next : current);

    test('a nudge keeps what the lookup could not find', () {
      expect(take('', 'Mall Road, Karnal', moved: false), 'Mall Road, Karnal');
      expect(take('1, Chaura', 'Mall Road', moved: false), '1, Chaura');
    });

    test('a move clears what the new place has no answer for', () {
      expect(take('', 'Karnal Division', moved: true), '');
      expect(take('Jalandhar Division', 'Karnal Division', moved: true),
          'Jalandhar Division');
    });
  });
}
