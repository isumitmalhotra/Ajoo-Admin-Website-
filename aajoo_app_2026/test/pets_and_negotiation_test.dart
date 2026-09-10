import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Two client reports from 2026-09-10, fixed on web and app in the same pass.
///
/// 1. "Pets allowed?" was asked TWICE — step 3 under "Pet policy" and step 4
///    under "House rules" — writing to two different records. Only the step 4
///    copy is read: it decides the guest-facing rule, the pet fee and the
///    `pets=1` search filter. Of the six listings that had answered both,
///    THREE disagreed, including one whose host said pets were welcome and
///    whose guests were told they were not.
///
/// 2. A host who chose "Fixed price only" still got a negotiate button, and a
///    guest could only find out by sending an offer and having it refused.
///
/// Source assertions: both live inside a 5-step wizard and a property page
/// that need a logged-in host, a draft and a live backend to reach. The rules
/// themselves are pinned server-side by tests/petsAskedOnce.test.js, which is
/// where the schema they both read is decided.
void main() {
  final screen = File(
    'lib/ui/screens_host/listing/listing_wizard_screen.dart',
  ).readAsStringSync();
  final controller = File(
    'lib/ui/screens_host/listing/listing_wizard_controller.dart',
  ).readAsStringSync();
  final schema = File('lib/models/listing_schema.dart').readAsStringSync();
  final property = File(
    'lib/ui/screens_renter/property_details/property_page.dart',
  ).readAsStringSync();
  final model = File('lib/models/single_property_response.dart').readAsStringSync();

  group('the pet question is asked once', () {
    test('step 3 no longer has a Pet policy section', () {
      expect(screen.contains("title: 'Pet policy'"), isFalse,
          reason: 'the same question is being asked on two steps again, '
              'writing to two records of which only one is read');
      expect(screen.contains('s.petPolicyFields'), isFalse,
          reason: 'step 3 still renders the old pet field list');
    });

    test('the details moved to step 4 and are gated on the surviving answer', () {
      expect(screen.contains('s.petDetailFields'), isTrue,
          reason: 'the pet details vanished instead of moving');
      expect(screen.contains("if (c.houseRules['pets_allowed'] == true)"), isTrue,
          reason: 'pet beds/food/area are asked even when pets are not allowed');
      expect(schema.contains('petDetailFields'), isTrue);
    });

    test('an existing draft restores them', () {
      // They live in property_attributes, not on the house-rules row, so they
      // arrive in their own bucket — without this a host editing a listing
      // found the answers blank and the save wrote them back empty.
      expect(controller.contains("d['step4Details']"), isTrue,
          reason: 'saved pet details are not read back into the form');
    });
  });

  group('a host who does not negotiate is not advertised as one who does', () {
    test('the page reads the switch', () {
      expect(model.contains('negotiationEnabled'), isTrue,
          reason: 'the model drops the flag, so the page cannot act on it');
      expect(property.contains('bool get ownerNegotiates'), isTrue);
    });

    test('the button is gated on it', () {
      expect(property.contains('visible: !isPrebooking && ownerNegotiates'), isTrue,
          reason: 'the negotiate button ignores the host setting, so the only '
              'way to learn it is to send an offer and be refused');
    });

    test('and the absence is explained, not just left blank', () {
      expect(property.contains('taking offers on this stay'), isTrue,
          reason: 'the control just vanishes, which reads as a broken feature '
              'rather than a rule the host set');
    });

    test('an absent flag is not read as a refusal', () {
      // Fails OPEN: the server is still the real gate, so failing closed would
      // hide a working feature on a transient error.
      expect(model.contains('negotiationEnabled = true'), isTrue,
          reason: 'the default must be "not stated", not "refused"');
    });
  });
}
