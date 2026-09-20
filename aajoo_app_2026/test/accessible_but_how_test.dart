// "Wheelchair accessible" with no way in is asked about. A host who ticked
// Wheelchair Accessible and none of Ramp, Lift or Ground Floor was not asked
// how a guest in a chair gets in (300-case run, HL-046, 2026-09-21). A
// warning beside the chips, on both clients.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/models/listing_schema.dart';
import 'package:rent_home/service/listing_service.dart';
import 'package:rent_home/ui/screens_host/listing/listing_wizard_controller.dart';

class _StubService extends ListingService {}

void main() {
  ListingWizardController wizard() {
    final c = ListingWizardController(service: _StubService());
    c.schema.value = ListingSchema.fromJson({
      'accessibility': {
        'key': 'accessibility',
        'label': 'Accessibility',
        'options': [
          {'value': 'wheelchair_accessible', 'label': 'Wheelchair Accessible'},
          {'value': 'ramp', 'label': 'Ramp'},
          {'value': 'lift', 'label': 'Lift'},
          {'value': 'ground_floor', 'label': 'Ground Floor'},
        ],
      },
    });
    return c;
  }

  group('accessible, but how?', () {
    test('wheelchair with no ramp, lift or ground floor asks how', () {
      final c = wizard();
      c.amenities['accessibility'] = ['wheelchair_accessible'];
      expect(c.wheelchairMismatch, contains('How do guests get in'));
    });

    test('any of the three ways in is enough; no wheelchair claim, no question', () {
      final c = wizard();
      for (final way in ['ramp', 'lift', 'ground_floor']) {
        c.amenities['accessibility'] = ['wheelchair_accessible', way];
        expect(c.wheelchairMismatch, isNull, reason: way);
      }
      c.amenities['accessibility'] = ['ramp'];
      expect(c.wheelchairMismatch, isNull);
    });

    test('a smart or digital lock without self check-in is asked about (HL-049)', () {
      final c = ListingWizardController(service: _StubService());
      c.schema.value = ListingSchema.fromJson({
        'safetyGroups': [
          {'key': 'security', 'label': 'Security', 'options': [
            {'value': 'smart_lock', 'label': 'Smart Lock'},
            {'value': 'cctv_entrance', 'label': 'CCTV Entrance'},
          ]},
        ],
      });
      c.amenities['security'] = ['smart_lock'];
      expect(c.smartLockNote, contains('self check-in'));
      c.p4['self_checkin'] = true;
      expect(c.smartLockNote, isNull, reason: 'already on: nothing to ask');
      c.p4['self_checkin'] = false;
      c.amenities['security'] = ['cctv_entrance'];
      expect(c.smartLockNote, isNull);
      final src = File('lib/ui/screens_host/listing/listing_wizard_screen.dart').readAsStringSync();
      expect(src, contains('if (c.smartLockNote != null) _warn(c.smartLockNote!),'));
    });

    test('and the screen renders it beside the chips', () {
      final src = File('lib/ui/screens_host/listing/listing_wizard_screen.dart').readAsStringSync();
      expect(src, contains('if (c.wheelchairMismatch != null) _warn(c.wheelchairMismatch!),'));
    });
  });
}
