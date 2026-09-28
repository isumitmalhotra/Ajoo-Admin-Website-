/// "Where you'll sleep" must have something to say before it appears.
///
/// Client, 2026-09-28, with a screenshot of listing #1: eight boxes reading
/// "Bedroom 1 … Bathroom 3" and nothing else. The server writes one row per
/// room from the COUNTS, so a listing stating five bedrooms and three
/// bathrooms and describing none of them has eight rows — and this model's
/// `hasDetail` asked `bedrooms.isNotEmpty || bathrooms.isNotEmpty`, which is
/// ROWS, not detail. The section rendered, and told the guest strictly less
/// than the "5 bedrooms · 3 baths" chip already above it.
///
/// The server answers it now (utils/propertyRooms.js) and sends `hasDetail`,
/// because the website had its own spelling of the same mistake and the
/// 300-case run has already caught these two pages disagreeing about this very
/// section once (2026-09-20).
///
///   flutter test test/where_youll_sleep_needs_something_to_say_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/models/single_property_response.dart';

/// A room the host created by typing a COUNT and nothing else, as the server
/// renders it: the heading always falls back, the lines are empty.
Map<String, dynamic> bare(String kind, int i) =>
    {'index': i, 'heading': '$kind $i', 'beds': '', 'bathroom': null};

void main() {
  test('the server\'s answer is the one used', () {
    final rooms = PropertyRooms.fromJson({
      'bedrooms': [1, 2, 3, 4, 5].map((i) => bare('Bedroom', i)).toList(),
      'bathrooms': [1, 2, 3].map((i) => bare('Bathroom', i)).toList(),
      'hasDetail': false,
    });
    expect(rooms.bedrooms.length, 5, reason: 'the rooms themselves must still arrive');
    expect(rooms.bathrooms.length, 3);
    expect(rooms.hasDetail, isFalse,
        reason: 'eight empty rows were counted as detail — the reported bug');
  });

  test('a described listing still shows', () {
    final rooms = PropertyRooms.fromJson({
      'bedrooms': [
        {'index': 1, 'heading': 'Master Bedroom', 'beds': '1 King bed', 'bathroom': null},
        bare('Bedroom', 2),
      ],
      'bathrooms': [bare('Bathroom', 1)],
      'hasDetail': true,
    });
    expect(rooms.hasDetail, isTrue);
    // Every bedroom, described or not: a two-bedroom listing with one described
    // must not read as a one-bedroom stay.
    expect(rooms.bedrooms.length, 2, reason: 'an undescribed bedroom was dropped');
    expect(rooms.bedrooms[1].beds, isEmpty,
        reason: 'an undescribed room invented a bed line');
  });

  group('a payload from a server that predates the flag', () {
    test('bare rows do not count', () {
      final rooms = PropertyRooms.fromJson({
        'bedrooms': [1, 2, 3].map((i) => bare('Bedroom', i)).toList(),
        'bathrooms': [1, 2].map((i) => bare('Bathroom', i)).toList(),
      });
      expect(rooms.hasDetail, isFalse,
          reason: 'the fallback fell back to counting rows, which is the bug');
    });

    test('a bed line does', () {
      final rooms = PropertyRooms.fromJson({
        'bedrooms': [
          {'index': 1, 'heading': 'Bedroom 1', 'beds': '1 Queen bed', 'bathroom': null},
        ],
        'bathrooms': [],
      });
      expect(rooms.hasDetail, isTrue);
    });

    test('so does a bathroom line', () {
      final rooms = PropertyRooms.fromJson({
        'bedrooms': [
          {'index': 1, 'heading': 'Bedroom 1', 'beds': '', 'bathroom': 'Attached bathroom'},
        ],
        'bathrooms': [],
      });
      expect(rooms.hasDetail, isTrue);
    });

    test('a HEADING never does — it is never empty', () {
      // The heading falls back to "Bedroom 2", so any guard that consults it
      // is always true. This is exactly what made the website's filter inert.
      final rooms = PropertyRooms.fromJson({
        'bedrooms': [
          {'index': 2, 'heading': 'Bedroom 2', 'beds': '', 'bathroom': null},
        ],
        'bathrooms': [],
      });
      expect(rooms.bedrooms.single.heading, isNotEmpty,
          reason: 'the premise: a heading always has something in it');
      expect(rooms.hasDetail, isFalse,
          reason: 'a fallback heading was mistaken for something the host said');
    });
  });

  test('nothing at all is not detail, and does not throw', () {
    expect(PropertyRooms.fromJson({'bedrooms': [], 'bathrooms': []}).hasDetail, isFalse);
    expect(PropertyRooms.fromJson(null).hasDetail, isFalse);
    expect(PropertyRooms.fromJson('not a map').hasDetail, isFalse);
  });
}
