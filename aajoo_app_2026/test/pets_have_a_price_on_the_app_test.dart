// The website has asked the pet fee, the allowed size and the limit under
// "Pets allowed" since the pet policy moved to step 4; the app showed only
// the three amenity switches, so a host on the phone could welcome pets and
// never name a price (300-case run, HL-045, 2026-09-21). The three fields
// now sit under the switch, are posted with step 4 (`...p4`) and load back
// from the draft's house-rules row and capacity.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String codeOnly(String src) => src
    .replaceAll('\r\n', '\n')
    .split('\n')
    .where((l) => !l.trimLeft().startsWith('//') && !l.trimLeft().startsWith('///'))
    .join('\n');

void main() {
  group('the caretaker is asked for only when there is one', () {
    test('step 5 gates the caretaker fields on the house-rule switch', () {
      final screen = codeOnly(File('lib/ui/screens_host/listing/listing_wizard_screen.dart').readAsStringSync());
      final block = screen.substring(screen.indexOf("title: 'Caretaker',"), screen.indexOf("title: 'Caretaker',") + 900);
      expect(block, contains("if (c.houseRules['caretaker_available'] == true) ...["));
      expect(block, contains("_p5Text('caretaker_name', 'Caretaker name',"));
      expect(block, contains('No caretaker on this listing.'));
    });
  });

  group('pets have a price on the app', () {
    test('the three fields are asked under Pets allowed, on step 4', () {
      final screen = codeOnly(File('lib/ui/screens_host/listing/listing_wizard_screen.dart').readAsStringSync());
      final block = screen.substring(screen.indexOf("if (c.houseRules['pets_allowed'] == true) ...["), screen.indexOf("title: 'Payouts'"));
      expect(block, contains("_p4Text('pet_fee', 'Pet fee (₹ per pet, per night)'"));
      expect(block, contains("_p4Text('pet_size', 'Allowed pet size'"));
      expect(block, contains("_p4Text('max_pets', 'Maximum pets (optional)'"));
    });

    test('and load back from the draft, into the map the fields read', () {
      final ctrl = codeOnly(File('lib/ui/screens_host/listing/listing_wizard_controller.dart').readAsStringSync());
      // Membership, not the list's exact spelling. This asserted the whole
      // literal and failed the moment the damage-policy texts joined the same
      // bridge on 2026-09-23 -- a test about pets breaking over a change that
      // had nothing to do with pets.
      final bridge = ctrl.substring(
          ctrl.lastIndexOf('for (final key in const [',
              ctrl.indexOf("if (rules['phr_\$key'] != null)")),
          ctrl.indexOf("if (rules['phr_\$key'] != null)"));
      expect(bridge, contains("'pet_fee'"));
      expect(bridge, contains("'pet_size'"));
      expect(ctrl, contains("if (rules['phr_\$key'] != null) p4[key] = rules['phr_\$key'];"));
      expect(ctrl, contains("if (cap is Map && cap['pc_max_pets'] != null) p4['max_pets'] = cap['pc_max_pets'];"));
      // Step 4 posts the whole of p4, which is how the server receives them.
      expect(ctrl, contains("'property_id': propertyId.value,\n              ...p4,\n              ...houseRules,"));
    });
  });
}
