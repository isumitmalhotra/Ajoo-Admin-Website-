import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A saved listing must come back the way it went in.
///
/// Bug 25, reported and RE-OPENED on 2026-09-10: "manager details such as email
/// and contact information are not retained, and some house rule toggles that
/// were enabled are reset to off". Both were genuine data loss, and both had
/// the same shape — the draft comes back as DATABASE ROWS (`pm_email`,
/// `phr_smoking`) and the form reads different names (`manager_email`,
/// `smoking`). A value that lands under a key nothing reads renders blank, and
/// because saving posts the WHOLE form back, the next save wrote that blank
/// over a real record.
///
/// The fix is a pair of explicit maps in listing_wizard_controller. This file
/// pins them, and pins the thing that would quietly undo them:
///
/// THE APP'S HOUSE-RULE LIST IS HARDCODED. The backend decides which toggles
/// exist (config/listingSchema.js HOUSE_RULE_TOGGLES) and the app copies ten
/// of them by name. Add an eleventh on the server and this app will not
/// restore it — it will render off, and the next save will write it off. That
/// is bug 25 all over again, for one new switch, and nothing would go red.
void main() {
  final controller = File(
    'lib/ui/screens_host/listing/listing_wizard_controller.dart',
  ).readAsStringSync();

  group('manager details survive a save', () {
    test('every manager column maps to the key the form reads', () {
      // pm_* is what /listing/draft returns; manager_* is what step 1 posts.
      // They were merged with the wrong prefix, so the form never saw them.
      const pairs = {
        'pm_full_name': 'manager_full_name',
        'pm_mobile': 'manager_mobile',
        'pm_email': 'manager_email',
        'pm_owner_name': 'manager_owner_name',
        'pm_owner_contact': 'manager_owner_contact',
        'pm_authorization_available': 'manager_authorization_available',
      };
      pairs.forEach((column, formKey) {
        expect(controller.contains("'$column': '$formKey'"), isTrue,
            reason: '$column no longer maps to $formKey, so it loads blank — '
                'and saving then writes that blank over the record');
      });
    });

    test('a missing value never overwrites one on file', () {
      // The guard that makes the difference between "not sent" and "cleared".
      expect(controller.contains('if (v != null) f[formKey] = v;'), isTrue,
          reason: 'a null from the server is copied into the form, which is '
              'how an absent manager became an erased one');
    });
  });

  group('house-rule toggles survive a save', () {
    test('the ten switches load from their phr_ columns', () {
      expect(controller.contains("rules['phr_\$key']"), isTrue,
          reason: 'the toggles are read from the wrong key again, so every '
              'switch renders off whatever was saved');
      // MySQL hands booleans back as 1/0; `== true` alone rendered them off.
      expect(controller.contains("v == 1 || v == true || v == '1'"), isTrue,
          reason: '1/0 from MySQL is not coerced, so a saved ON reads as off');
    });

    test('THE ONE THAT MATTERS: the list matches the server', () {
      // The backend owns the vocabulary. This test is the only thing that
      // would notice it growing.
      final schema = File(
        '../../aajaoBackend-render/config/listingSchema.js',
      );
      if (!schema.existsSync()) {
        markTestSkipped('backend checkout not beside this one');
        return;
      }
      final src = schema.readAsStringSync();
      final block = src.substring(
        src.indexOf('const HOUSE_RULE_TOGGLES'),
        src.indexOf('];', src.indexOf('const HOUSE_RULE_TOGGLES')),
      );
      final serverKeys = RegExp(r'key:\s*"([a-z_]+)"')
          .allMatches(block)
          .map((m) => m.group(1)!)
          .toSet();

      final appBlock = controller.substring(
        controller.indexOf("'pets_allowed', 'smoking'"),
        controller.indexOf("]) {", controller.indexOf("'pets_allowed', 'smoking'")),
      );
      final appKeys = RegExp(r"'([a-z_]+)'")
          .allMatches(appBlock)
          .map((m) => m.group(1)!)
          .toSet();

      expect(appKeys, equals(serverKeys),
          reason: 'the app restores a different set of house rules than the '
              'server stores. Anything the server has and the app does not '
              'renders OFF and is written off on the next save — which is '
              'exactly bug 25, one new switch at a time.\n'
              'server: ${(serverKeys.toList()..sort())}\n'
              'app:    ${(appKeys.toList()..sort())}');
    });
  });

  group('step 5 comes back too', () {
    test('the four tables the server used not to return are merged', () {
      // A host who left the wizard and came back found the last step empty and
      // retyped their identity details, their bank and their GST number.
      for (final prefix in ['pvf_', 'pcn_']) {
        expect(controller.contains("'$prefix'"), isTrue,
            reason: 'step 5 no longer restores $prefix rows');
      }
    });
  });

  test('the draft payload shape this all assumes is documented', () {
    // Not decoration: the mapping above is only correct for THIS shape, and
    // the comment is where the next person learns why the prefixes differ.
    expect(controller.contains('pm_ manager'), isTrue);
    expect(jsonEncode({'ok': true}), isNotEmpty); // dart:convert kept in use
  });
}
