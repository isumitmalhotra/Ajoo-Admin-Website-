// A listing whose coordinates came back as NUMBERS could not be opened at all.
//
// Found on 2026-09-12: tapping the negotiated-deal banner for listing 29303
// left a spinner on screen and the listing never opened, while the same build
// opened 29302 from the same banner in a couple of seconds. It was never the
// network — the endpoint answered 29303 in 2.5s from the same machine — and it
// was never the id. It was the payload.
//
//   29302  "property_latitude": "28.45936"     <- a string
//   29303  "property_latitude": 28.47938       <- a number
//
// `property_latitude` is a floating-point column. Whether the driver hands it
// back as a string or a number depends on how the row was written, so BOTH
// shapes are live in the same table right now. The model declared
// `final String? propertyLatitude` and assigned `json['property_latitude']`
// straight into it, so the numeric form threw a TypeError inside fromJson.
//
// What made it a spinner rather than an error message is that a TypeError is
// an Error, not an Exception: `on Exception catch` in PropertyService walked
// straight past it, and UserController.getProperty caught it but leaves
// `property.value` at whatever it held before — so the caller reads a stale
// value, or null, and the failure surfaced as nothing happening.
//
// The rule this pins: a field that is a NUMBER in the database is never typed
// as String in the model without a conversion. Two of them were.
//
//   flutter test test/coordinates_are_not_always_strings_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/models/single_property_response.dart';

/// The payload shape `GET /properties/:id` returns, cut down to the fields
/// this defect turns on. Everything else in the real body is either absent or
/// null on 29303, and the model already tolerated all of it.
Map<String, dynamic> wire({required Object? lat, required Object? lng}) => {
      'success': true,
      'message': 'Property found',
      'data': {
        'property_id': 29303,
        'property_host_id': 194,
        'property_name': 'QA Metro PG Gurugram',
        'property_address': 'Sector 44, Gurugram',
        'property_latitude': lat,
        'property_longitude': lng,
        'property_price': '900.00',
        'property_city': 'Gurugram',
        // Null on 29303 and a list on 29302 — the other difference between the
        // two, and one the model already handled. Here so that a change which
        // "fixes" the coordinates by loosening the whole parse still has to
        // keep this working.
        'categories': null,
        'images': <dynamic>[],
      },
    };

void main() {
  group('coordinates arrive in both shapes', () {
    test('a listing whose coordinates are numbers still parses', () {
      // 29303, verbatim. Before the fix this threw:
      //   type 'double' is not a subtype of type 'String?'
      final r = SinglePropertyResponse.fromJson(wire(lat: 28.47938, lng: 77.07762));
      expect(r.data, isNotNull,
          reason: 'a numeric latitude must not stop the listing loading');
      expect(r.data!.propertyId, 29303);
      expect(r.data!.propertyLatitude, '28.47938');
      expect(r.data!.propertyLongitude, '77.07762');
    });

    test('a listing whose coordinates are strings is unchanged', () {
      // 29302. The shape that always worked has to keep working, exactly:
      // the property page parses these with double.tryParse and a reformatted
      // string would move the map pin.
      final r = SinglePropertyResponse.fromJson(
          wire(lat: '28.45936', lng: '77.02638'));
      expect(r.data!.propertyLatitude, '28.45936');
      expect(r.data!.propertyLongitude, '77.02638');
    });

    test('an integer latitude is not truncated or rejected', () {
      // Whole-number coordinates come back as ints, not doubles — the same
      // trap one rung down, and the one that bit the nearby-places list.
      final r = SinglePropertyResponse.fromJson(wire(lat: 28, lng: 77));
      expect(r.data!.propertyLatitude, '28');
      expect(r.data!.propertyLongitude, '77');
    });

    test('a listing with no coordinates yet still opens', () {
      // Every field is null until the host finishes the wizard. No pin is a
      // fact about the listing, not a failure to load it.
      final r = SinglePropertyResponse.fromJson(wire(lat: null, lng: null));
      expect(r.data, isNotNull);
      expect(r.data!.propertyLatitude, isNull);
      expect(r.data!.propertyLongitude, isNull);
    });
  });

  group('the value the page actually uses', () {
    test('both shapes parse to the same map position', () {
      // The property page does double.tryParse on whatever it is given. That
      // has to land on the same coordinate either way, or a listing would open
      // in the sea depending on how its row happened to be written.
      final numeric = SinglePropertyResponse.fromJson(
          wire(lat: 28.47938, lng: 77.07762)).data!;
      final textual = SinglePropertyResponse.fromJson(
          wire(lat: '28.47938', lng: '77.07762')).data!;
      expect(double.tryParse('${numeric.propertyLatitude}'),
          double.tryParse('${textual.propertyLatitude}'));
      expect(double.tryParse('${numeric.propertyLongitude}'),
          double.tryParse('${textual.propertyLongitude}'));
    });
  });
}
