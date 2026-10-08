// Every bathroom on one line, and the app reads what the server actually sends.
//
// The screen used to map each bathroom into its own card, so a listing with
// five rendered five boxes saying one word each — and a listing may state up
// to thirty rooms. Client, 2026-10-08: "we don't have to share each bathroom
// in separate card, that will make issue for houses and rooms which have more
// rooms and bathrooms".
//
// The renter property screen cannot be opened on the emulator without a
// renter password, so this covers the half that can be: that the model reads
// the real payload, and that the three cases the card branches on behave.
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/models/single_property_response.dart';

void main() {
  group('BathroomSummary', () {
    test('parses the payload /properties/5 returns', () {
      // Copied verbatim from the live API.
      final raw = jsonDecode('{"count": 5, "heading": "5 bathrooms", '
          '"detail": "1 Attached \u00b7 2 Ensuite \u00b7 1 Common \u00b7 1 Shared"}');
      final s = BathroomSummary.fromJson(raw);
      expect(s, isNotNull);
      expect(s!.count, 5);
      expect(s.heading, '5 bathrooms');
      expect(s.detail, '1 Attached \u00b7 2 Ensuite \u00b7 1 Common \u00b7 1 Shared');
    });

    test('a listing with no types keeps the heading and drops the line', () {
      // Listing 6's shape: bathrooms exist, the host typed no types. The card
      // hides its second line on exactly this condition rather than printing
      // a blank one under the heading.
      final s = BathroomSummary.fromJson(
          jsonDecode('{"count": 3, "heading": "3 bathrooms", "detail": ""}'));
      expect(s!.heading, '3 bathrooms');
      expect(s.detail.isEmpty, isTrue);
    });

    test('null when there is nothing to say, so no card is drawn', () {
      expect(BathroomSummary.fromJson(null), isNull);
      expect(BathroomSummary.fromJson(<String, dynamic>{}), isNull);
    });
  });

  group('PropertyRooms', () {
    test('reads the summary WITHOUT losing the per-bathroom list', () {
      final rooms = PropertyRooms.fromJson(jsonDecode(
          '{"bedrooms": [{"index":1,"heading":"Master Bedroom",'
          '"beds":"1 King bed","bathroom":"Attached bathroom"}],'
          '"bathrooms": [{"index":1,"heading":"Bathroom 1","type":"Shared"},'
          '{"index":2,"heading":"Bathroom 2","type":"Common"}],'
          '"bathroomSummary": {"count":2,"heading":"2 bathrooms",'
          '"detail":"1 Common \u00b7 1 Shared"},"hasDetail": true}'));
      expect(rooms.bathroomSummary!.heading, '2 bathrooms');
      // The presentation collapses; the data does not.
      expect(rooms.bathrooms.length, 2);
      expect(rooms.bedrooms.single.beds, '1 King bed');
      expect(rooms.hasDetail, isTrue);
    });

    test('a payload from before the summary still parses', () {
      final rooms = PropertyRooms.fromJson(
          jsonDecode('{"bedrooms": [], "bathrooms": [], "hasDetail": false}'));
      expect(rooms.bathroomSummary, isNull);
    });
  });
}
