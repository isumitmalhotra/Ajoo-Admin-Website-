// A listing whose host chose "approximate location" must not break the list.
//
// The coordinate types are not a data-era accident. `blurProperty` in the
// backend's utils/approximateLocation.js replaces property_latitude/longitude
// with the JS numbers it computes:
//
//   out.property_latitude = point.lat;      // a number
//
// and leaves the DECIMAL column's string in place otherwise. So the JSON type
// of a coordinate is decided by a HOST SETTING — "Guests will only see an
// approximate area until they book" — and both shapes come back from the same
// endpoint in the same response. Two of the eight listings in the live search
// response on 2026-09-12 were approximate.
//
// Three models declared those fields String and assigned them raw, so a single
// approximate listing threw a TypeError out of fromJson. In the search/map
// path that is not one missing card: PropertiesResponse.fromJson maps the whole
// array, so the throw took the ENTIRE result list, and map_service catches
// `on Exception` — which a TypeError is not — so the app showed "No stays here
// yet. Try a wider search." over a response that had eight stays in it.
//
// The rows below are verbatim from the live endpoint, trimmed to the keys the
// models read.
//
//   flutter test test/an_approximate_listing_still_parses_test.dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/models/properties_response_model.dart';
import 'package:rent_home/models/search_property_model.dart';
import 'package:rent_home/models/host_properties_reponse.dart' as host;

/// 29303 — the host asked for an approximate location, so the coordinates are
/// numbers and the address is trimmed to an area.
const approximate = '''
{
  "property_id": 29303,
  "property_name": "QA Metro PG Gurugram",
  "property_address": "Opposite MGF Metropolitan Mall, Sector 28",
  "property_desc": "Shared room in a quiet PG for working professionals.",
  "property_price": "900.00",
  "property_city": "Gurugram",
  "property_longitude": 77.07762,
  "property_latitude": 28.47938,
  "property_host_id": 194,
  "property_zip": "122009",
  "property_contact": "9811122233",
  "property_cancellation_policy": "moderate",
  "distance": 1.4722342322158948,
  "coverImage": "https://res.cloudinary.com/due5czusf/image/upload/v1/a.jpg",
  "images": ["https://res.cloudinary.com/due5czusf/image/upload/v1/a.jpg"],
  "category_titles": null,
  "tags": null,
  "rating": null,
  "review_count": 0,
  "isBoosted": false,
  "offer": null,
  "pets": {"petsAllowed": false, "petFeePerNight": 0, "petSize": null, "maxPets": 0},
  "location_is_approximate": true
}
''';

/// 29302 — exact location, so the DECIMAL column's string comes straight
/// through. The shape that always worked, and has to keep working.
const exact = '''
{
  "property_id": 29302,
  "property_name": "Aajoo Homes",
  "property_address": "Local Rd, Near Christ Church",
  "property_desc": "A quiet cottage.",
  "property_price": "3000.00",
  "property_city": "Kasauli",
  "property_longitude": "76.96376000",
  "property_latitude": "30.90129002",
  "property_host_id": 194,
  "property_zip": "173204",
  "property_contact": "9811122233",
  "property_cancellation_policy": "moderate",
  "distance": 210.4,
  "coverImage": "https://res.cloudinary.com/due5czusf/image/upload/v1/b.jpg",
  "images": ["https://res.cloudinary.com/due5czusf/image/upload/v1/b.jpg"],
  "category_titles": null,
  "tags": null,
  "rating": null,
  "review_count": 0,
  "isBoosted": false,
  "offer": null,
  "pets": {"petsAllowed": false, "petFeePerNight": 0, "petSize": null, "maxPets": 0},
  "location_is_approximate": false
}
''';

Map<String, dynamic> row(String s) => json.decode(s) as Map<String, dynamic>;

void main() {
  group('the search and map model', () {
    test('parses an approximate listing', () {
      final p = Property.fromJson(row(approximate));
      expect(p.propertyId, 29303);
      expect(p.propertyLatitude, '28.47938');
      expect(p.propertyLongitude, '77.07762');
    });

    test('parses an exact listing unchanged', () {
      final p = Property.fromJson(row(exact));
      expect(p.propertyLatitude, '30.90129002',
          reason: 'the string form must pass through untouched — reformatting '
              'it would move the map pin');
    });

    test('ONE approximate listing does not take the whole result list', () {
      // The failure that mattered. map_service parses the array in one go, so
      // a throw on any row emptied the list — and it catches `on Exception`,
      // which a TypeError is not.
      final payload = {
        'success': true,
        'message': 'successful',
        'data': {
          'property': [row(exact), row(approximate), row(exact)],
        },
      };
      final r = PropertiesResponse.fromJson(payload);
      expect(r.data.property.length, 3,
          reason: 'a search that returned three stays showed none of them');
    });
  });

  group('the search-screen model', () {
    /// SearchPropertyModel reads /properties/list, not /properties/search, and
    /// that query selects every column (`attributes: { include: [...] }`, no
    /// exclude) -- so these five arrive as well and the model's non-nullable
    /// fields are fed. They are added here rather than left out so the test
    /// fails for the coordinate reason and no other.
    Map<String, dynamic> listRow(String s) => row(s)
      ..addAll({
        'is_active': true,
        'is_deleted': 0,
        'is_luxury': 0,
        'created_at': '2026-09-11T06:12:00.000Z',
        'updated_at': '2026-09-12T04:30:00.000Z',
      });

    test('parses both shapes', () {
      expect(SearchPropertyModel.fromJson(listRow(approximate)).propertyLatitude,
          '28.47938');
      expect(SearchPropertyModel.fromJson(listRow(exact)).propertyLatitude,
          '30.90129002');
    });
  });

  group("the host's own listings model", () {
    test('parses both shapes', () {
      // A host sees their own exact location, so this model met the numeric
      // form less often — but `json[...] ?? ""` only answers for null, and a
      // number walks straight past it into a String field.
      expect(host.Property.fromJson(row(approximate)).propertyLatitude,
          '28.47938');
      expect(host.Property.fromJson(row(exact)).propertyLatitude,
          '30.90129002');
    });
  });

  group('what a missing field must not do', () {
    test('a listing with no description still parses', () {
      // property_desc is nullable in the database and was assigned into a
      // non-nullable String. Nothing to do with coordinates — the same raw
      // assignment, one field over.
      final r = row(approximate)..['property_desc'] = null;
      expect(Property.fromJson(r).propertyDesc, '');
    });
  });
}
