import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/ui/screens_host/listing/widgets/add_nearby_place.dart';

/// The app wizard asks in ONE voice, and in one place — like the website.
///
/// Three faults reported off a desktop screenshot on 2026-09-10 and fixed on
/// the website the same day. The app had every one of them:
///
///   1. A category question opened somewhere else to be answered — a bottom
///      sheet here, a native dropdown there — while every other choice on the
///      form is a pill row. A sheet also HIDES its options until it is opened,
///      so a host cannot see that "Village Homestay" exists without going
///      looking.
///
///   2. Only the sections Google returned something for were shown, so the
///      section that most needs a human answer was the one most likely to be
///      missing entirely.
///
///   3. Everything else went into a grid of bare kilometre boxes further down
///      the step: no name, no position, no connection to the heading a guest
///      reads it under.
void main() {
  final screen = File(
    'lib/ui/screens_host/listing/listing_wizard_screen.dart',
  ).readAsStringSync();
  final field = File(
    'lib/ui/screens_host/listing/widgets/schema_field_input.dart',
  ).readAsStringSync();
  final controller = File(
    'lib/ui/screens_host/listing/listing_wizard_controller.dart',
  ).readAsStringSync();
  final add = File(
    'lib/ui/screens_host/listing/widgets/add_nearby_place.dart',
  ).readAsStringSync();

  group('one voice', () {
    test('a short schema choice is pills, not a sheet', () {
      expect(field.contains('static const int _pillLimit'), isTrue,
          reason: 'there is no threshold, so every list renders the same way');
      expect(field.contains('if (field.options.length <= _pillLimit)'), isTrue,
          reason: 'a short select still sends the host to a bottom sheet');
      // Re-tapping clears. The sheet could be dismissed without choosing;
      // pills otherwise cannot un-answer an optional field.
      expect(field.contains('_set(selected == o.value ? null : o.value)'), isTrue,
          reason: 'a chosen option cannot be cleared');
    });

    test('the sheet survives for a list long enough to need it', () {
      // Nothing in the schema is close today (the longest is six), but a Wrap
      // of thirty buttons is a paragraph, and a searchable sheet is genuinely
      // better there.
      expect(field.contains('Widget _select(BuildContext context)'), isTrue);
      expect(field.contains('_openPicker(context)'), isTrue,
          reason: 'the long-list path was deleted rather than kept as a fallback');
    });
  });

  group('what is around this property', () {
    test('THE ONE THAT MATTERS: every section renders, empty or not', () {
      expect(screen.contains('if (rows.isEmpty) return const [];'), isFalse,
          reason: 'a section with no Google results is hidden, so the host '
              'never learns it exists');
    });

    test('every section can take a place Google has never heard of', () {
      expect(screen.contains('AddNearbyPlace('), isTrue,
          reason: 'there is no way to add a place by hand');
      expect(controller.contains('void addNearbyPlace('), isTrue);
      expect(controller.contains("'source': 'manual'"), isTrue,
          reason: 'a host-typed place would be stored as a Google result, '
              "making the guest page's marker a lie");
    });

    test('the position is asked for, and the name is left alone', () {
      expect(add.contains('GeocodeService.instance.search('), isTrue,
          reason: 'the name is never looked up');
      expect(add.contains('nearbyDistanceKm(lat, lng, p.lat, p.lng)'), isTrue,
          reason: 'the distance is typed even when both ends are known');
      // The website briefly rewrote the box with the geocoder's first
      // comma-part, so "Gurdwara Nada Sahib" became "Chaunki" — the hamlet it
      // stands in.
      final pick = add.substring(add.indexOf('void _pick('), add.indexOf('void _reset('));
      expect(pick.contains('_name.text ='), isFalse,
          reason: 'picking a match overwrites the name the host typed');
      // Debounced: a billed lookup on every keystroke otherwise.
      expect(add.contains('Duration(milliseconds: 450)'), isTrue);
    });

    test('the disconnected grid is gone, and its values are not stranded', () {
      expect(screen.contains('for (final g in s.nearbyGroups)'), isFalse,
          reason: 'two ways to answer one question again');
      // A listing saved before this still HAS those values and still shows
      // them to a guest. Dropping them would make them invisible and
      // uneditable while remaining live — the worst of both.
      expect(controller.contains('groupSection['), isTrue,
          reason: 'old by-hand distances are not carried into their sections');
      expect(controller.contains("d['nearby'] is Map"), isTrue);
    });
  });

  group('the distance is real', () {
    test('a measured kilometre matches a known one', () {
      // Kharar to Chandigarh, about 12 km apart.
      final km = nearbyDistanceKm(30.7460, 76.6469, 30.7333, 76.7794);
      expect(km, greaterThan(11));
      expect(km, lessThan(14));
    });

    test('a point measured against itself is zero', () {
      expect(nearbyDistanceKm(30.7460, 76.6469, 30.7460, 76.6469), 0);
    });
  });
}
