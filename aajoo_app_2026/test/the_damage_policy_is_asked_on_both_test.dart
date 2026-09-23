import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The two property forms are one form.
///
/// Client, 2026-09-22: "make sure the porpperty registration form is exactly
/// same on both sides."
///
/// Comparing the section titles of the two wizards turned up one whole section
/// the website has and this app did not: Damage policy. The server has always
/// read its three fields in saveStep4 -- ppr_deposit_refundable,
/// phr_damage_reporting, phr_compensation_rules -- and the app sent none of
/// them, so a listing created on a phone had no damage policy at all and the
/// host discovered that at the door.
///
/// Two halves have to hold, and the second is the one this repository keeps
/// getting wrong: a step-4 control must READ the map the draft loader writes
/// the column into. `phr_*` merges into p5, these controls read p4, and step 4
/// posts the whole of p4 -- so a missing bridge does not merely show an empty
/// box, it writes NULL over what the host saved. That has happened with
/// self_checkin_method, pet_fee and pet_size already.
void main() {
  final screen = File('lib/ui/screens_host/listing/listing_wizard_screen.dart')
      .readAsStringSync();
  final controller =
      File('lib/ui/screens_host/listing/listing_wizard_controller.dart')
          .readAsStringSync();

  group('the app asks the damage-policy questions', () {
    test('there is a Damage policy section', () {
      expect(screen, contains("title: 'Damage policy'"));
    });

    test('the deposit says whether it comes back', () {
      expect(screen, contains("setP4('deposit_refundable'"),
          reason: 'the website has asked this since the wizard shipped; '
              'without it the guest is told the wrong thing');
    });

    test('both free-text answers are asked, and write to p4', () {
      for (final key in ['damage_reporting', 'compensation_rules']) {
        expect(screen, contains("_p4Area('$key'"),
            reason: '$key is read by saveStep4 and asked for by the website');
      }
    });
  });

  group('and reads back what it saved', () {
    test('the phr_ columns are bridged into the map the controls read', () {
      // The bridge is a literal list in the draft loader. Both keys must be in
      // it, or step 4's next save posts p4 with these empty and wipes the row.
      final at = controller.indexOf("if (rules['phr_\$key'] != null)");
      expect(at, greaterThan(0), reason: 'the phr_ bridge has moved or gone');
      final block = controller.substring(
          controller.lastIndexOf('for (final key in const [', at), at);
      for (final key in ['damage_reporting', 'compensation_rules']) {
        expect(block, contains("'$key'"),
            reason: "$key lands in p5 and is read from p4 — the fourth time "
                "this exact fault would have shipped");
      }
    });

    test('the whole of p4 is posted, so the fields need no wiring of their own',
        () {
      expect(controller, contains('...p4,'),
          reason: 'if step 4 stopped posting p4 wholesale, every field added '
              'this way would go silently unsent');
    });
  });
}
