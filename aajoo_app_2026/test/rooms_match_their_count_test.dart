import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/models/listing_schema.dart';

/// The bedroom count and the bedroom detail cannot disagree — the app's half.
///
/// Client, 2026-09-13: "add bedrooms class / bed classs / bathroom class / like
/// master bedroom / queen sized bed / shared bathroom / attached etc".
///
/// The server enforces the rule (utils/propertyRooms.js) and the website
/// enforces it (components/RoomDetail.tsx). This file pins the two pieces of
/// it that live in Dart and would otherwise rot quietly:
///
///   1. `copyWith` must be able to CLEAR a nullable field. Re-tapping the
///      chosen pill unsets it, and the obvious `type ?? this.type` makes that
///      impossible — the host would find a room type they picked by accident
///      permanent.
///
///   2. the vocabulary is the backend's. A client held against an older API
///      gets NULL and draws no repeater, rather than guessing at bed types and
///      leaving the two platforms disagreeing about what a "Double" is after
///      hosts have answered.
void main() {
  group('a room can be un-answered', () {
    const room = RoomEntry(
      index: 1,
      type: 'master_bedroom',
      name: 'Garden Room',
      bathroom: 'attached',
      beds: [BedEntry(type: 'queen', count: 2)],
    );

    test('clearing the type actually clears it', () {
      expect(room.copyWith(type: null).type, isNull,
          reason: 're-tapping the chosen pill has to unset it; `type ?? '
              'this.type` would make an accidental tap permanent');
    });

    test('clearing one field leaves the others alone', () {
      final cleared = room.copyWith(bathroom: null);
      expect(cleared.bathroom, isNull);
      expect(cleared.type, 'master_bedroom');
      expect(cleared.name, 'Garden Room');
      expect(cleared.beds.single.count, 2);
    });

    test('an untouched field survives a copy', () {
      final renumbered = room.copyWith(index: 3);
      expect(renumbered.index, 3);
      expect(renumbered.type, 'master_bedroom');
      expect(renumbered.bathroom, 'attached');
      expect(renumbered.name, 'Garden Room');
    });
  });

  group('what the wire gives us', () {
    test('a room round-trips through JSON', () {
      const room = RoomEntry(
        index: 2,
        type: 'guest_bedroom',
        name: 'Attic',
        bathroom: 'shared',
        beds: [BedEntry(type: 'single', count: 2)],
      );
      final back = RoomEntry.fromJson(room.toJson());
      expect(back.index, 2);
      expect(back.type, 'guest_bedroom');
      expect(back.name, 'Attic');
      expect(back.bathroom, 'shared');
      expect(back.beds.single.type, 'single');
      expect(back.beds.single.count, 2);
    });

    test('beds are always a list, whatever arrives', () {
      // "no record" answering with a different SHAPE from "here is the record"
      // is what stopped two app screens opening at all.
      expect(RoomEntry.fromJson(const {'index': 1}).beds, isEmpty);
      expect(RoomEntry.fromJson(const {'index': 1, 'beds': null}).beds, isEmpty);
      expect(RoomEntry.fromJson(const {'index': 1, 'beds': 'queen'}).beds, isEmpty);
      expect(BedEntry.listFrom(const [null, 7, 'x']), isEmpty);
    });

    test('a bed with no type is dropped rather than stored empty', () {
      expect(BedEntry.listFrom(const [
        {'type': '', 'count': 2},
        {'type': 'queen', 'count': 1},
      ]).length, 1);
    });

    test('an index that is missing or the wrong type does not throw', () {
      expect(RoomEntry.fromJson(const {}).index, 1);
      expect(RoomEntry.fromJson(const {'index': '4'}).index, 1);
      expect(RoomEntry.listFrom('nonsense'), isEmpty);
      expect(RoomEntry.listFrom(null), isEmpty);
    });
  });

  group('the vocabulary is the backend\'s, never a guess', () {
    test('no bed types means no repeater at all', () {
      expect(RoomDetailVocab.fromJson(null), isNull);
      expect(RoomDetailVocab.fromJson(const {}), isNull);
      expect(RoomDetailVocab.fromJson(const {'bedTypes': []}), isNull,
          reason: 'an older backend must disable the section, not make one up — '
              'two clients disagreeing about what a "Double" is, after hosts '
              'have answered, cannot be undone');
    });

    test('a served vocabulary is read whole', () {
      final v = RoomDetailVocab.fromJson(const {
        'bedroomTypes': [
          {'value': 'master_bedroom', 'label': 'Master Bedroom'}
        ],
        'bedTypes': [
          {'value': 'queen', 'label': 'Queen'}
        ],
        'bathroomTypes': [
          {'value': 'attached', 'label': 'Attached'}
        ],
        'bedroomBathroom': [
          {'value': 'shared', 'label': 'Shared bathroom'}
        ],
        'limits': {'maxRooms': 12, 'maxBedCount': 5},
      });
      expect(v, isNotNull);
      expect(v!.bedTypes.single.label, 'Queen');
      expect(v.bedroomBathroom.single.value, 'shared');
      expect(v.limits.maxRooms, 12);
      expect(v.limits.maxBedCount, 5);
      // Absent limits fall back to the documented defaults rather than zero —
      // a maxRooms of 0 would silently draw no cards at all.
      expect(v.limits.maxBedsPerRoom, 8);
      expect(v.limits.maxNameLength, 60);
    });
  });
}
