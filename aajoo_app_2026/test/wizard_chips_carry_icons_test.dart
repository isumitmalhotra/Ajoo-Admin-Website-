import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/ui/screens_host/listing/listing_icons.dart';

/// The category-specific questions draw icons, and two of them deliberately
/// do not.
///
/// Client, 2026-09-13, photographing the Homestay block on the website: "give
/// some icon for looks attached and see all identifi for categories releated
/// to". On that screen the Outdoor amenities carried icons and Homestay Type,
/// Local Experience and Shared Spaces carried none — they come from
/// CATEGORY_FLOWS and went through a renderer that never looked one up. The
/// app was worse: no wizard chip had an icon at all, amenities included.
///
/// What this file protects is the RULE rather than the artwork, because the
/// rule is the part that breaks quietly:
///
///   1. a question either draws icons on all of its chips or on none, so a
///      row never has one chip shorter than its neighbours
///   2. the two scales stay bare — a picture repeated down High / Medium / Low
///      is decoration standing where meaning should be
///   3. an option that genuinely differs from its siblings beats the field's
///      own icon (a chef is not a driver)
///   4. an unknown field gets nothing, rather than a fallback, because a
///      fallback here would silently decorate the next scale somebody adds
void main() {
  group('a category question draws icons on all of its chips, or none', () {
    // One per shape of question, not one per field: enough to fail if the
    // table is emptied or the fallback stops working.
    const withIcons = <String, List<String>>{
      'homestay_type': ['family_homestay', 'village_homestay', 'eco_homestay'],
      'local_experience': ['home_cooked_food', 'village_walk', 'bonfire'],
      'shared_spaces': ['shared_kitchen', 'shared_living_room'],
      'staff': ['chef', 'driver', 'caretaker'],
      'meals': ['breakfast', 'no_meals'],
      'pool_type': ['private', 'shared', 'infinity'],
      'animals': ['cow', 'horse', 'rabbit'],
      'room_type': ['single', 'dormitory'],
      'parking': ['covered', 'none'],
    };

    withIcons.forEach((field, values) {
      test('$field — every option', () {
        for (final v in values) {
          expect(
            iconForSchemaOption(field, v),
            isNotNull,
            reason: '$field.$v has no icon while its siblings do, which '
                'leaves one chip shorter than the rest of the row',
          );
        }
      });
    });
  });

  group('the scales stay bare', () {
    test('host_interaction_level is High / Medium / Low', () {
      for (final v in ['high', 'medium', 'low']) {
        expect(iconForSchemaOption('host_interaction_level', v), isNull,
            reason: 'an icon repeated down a scale says nothing');
      }
    });

    test('height is three measurements', () {
      for (final v in ['below_10_ft', '10_20_ft', '20_ft']) {
        expect(iconForSchemaOption('height', v), isNull);
      }
    });
  });

  test('an option that differs from its siblings beats the field icon', () {
    final chef = iconForSchemaOption('staff', 'chef');
    final driver = iconForSchemaOption('staff', 'driver');
    final caretaker = iconForSchemaOption('staff', 'caretaker');
    expect(chef, isNot(equals(driver)),
        reason: 'a chef and a driver are not the same job');
    expect(caretaker, isNot(equals(driver)));
  });

  test('an option with no entry of its own falls back to the field', () {
    // `animals` has no per-option icons — cow, goat and sheep have no distinct
    // Material glyph — so all of them take the field's paw print.
    expect(iconForSchemaOption('animals', 'cow'),
        equals(iconForSchemaOption('animals', 'goat')));
    expect(iconForSchemaOption('animals', 'cow'), equals(Icons.pets_outlined));
  });

  test('an unknown field gets nothing rather than a fallback', () {
    expect(iconForSchemaOption('something_added_next_month', 'anything'), isNull,
        reason: 'a fallback here would silently decorate the next scale');
    expect(iconForSchemaOption(null, 'x'), isNull);
    expect(iconForSchemaOption('', 'x'), isNull);
  });

  group('amenity labels always resolve to something', () {
    test('a keyword in the label wins', () {
      expect(iconForAmenity('Coffee Machine'), equals(Icons.local_cafe_outlined));
      expect(iconForAmenity('Smoke Alarm'),
          equals(Icons.notifications_active_outlined));
    });

    test('"AC" is matched whole, not as a substring', () {
      // It sits inside "terrace", "backup" and half a dozen other words.
      expect(iconForAmenity('AC'), equals(Icons.ac_unit));
      expect(iconForAmenity('Terrace'), equals(Icons.wb_sunny_outlined));
      expect(iconForAmenity('Power Backup'), equals(Icons.bolt_outlined));
    });

    test('a label that says nothing takes its group', () {
      // "Attached" and "Shared" mean nothing alone and everything under the
      // heading Bathroom.
      expect(iconForAmenity('Attached', 'bathroom'),
          equals(Icons.bathtub_outlined));
      expect(iconForAmenity('Shared', 'bathroom'),
          equals(Icons.bathtub_outlined));
    });

    test('and something nobody anticipated still gets a chip', () {
      expect(iconForAmenity('Palanquin Service'), equals(kAmenityFallback));
      expect(iconForAmenity(''), equals(kAmenityFallback));
      expect(iconForAmenity(null), equals(kAmenityFallback));
    });
  });
}
