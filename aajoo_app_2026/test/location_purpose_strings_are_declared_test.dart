// Both iOS location purpose strings, from build 128 (2026-10-20).
//
// Build 127 was delivered on 17 October and Apple answered ITMS-90683: the
// Info.plist had NSLocationWhenInUseUsageDescription but not
// NSLocationAlwaysAndWhenInUseUsageDescription. geolocator_apple LINKS
// requestAlwaysAuthorization, and Apple's upload scan wants a purpose string
// for a linked sensitive API whether or not the app ever calls it — this app
// does not. safety_page.dart only READS LocationPermission.always as a state
// iOS might already have granted; nothing asks for it.
//
// Why a test rather than trusting the plist: the warning did NOT block the
// delivery. The build uploaded, processed, reached TestFlight and went into
// review, and the only sign anything was wrong was an email nobody read for
// three days. Nothing in the build fails loudly on this, so it needs
// something that does.
//
// tool/verify_release_ipa.py checks the BUILT Info.plist for the same keys,
// but that only runs on the Mac at release time. This reads the source on
// every `flutter test`, which is where a dropped key would actually be caught.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS declares a purpose string for every location API it links', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();

    for (final key in const [
      'NSLocationWhenInUseUsageDescription',
      'NSLocationAlwaysAndWhenInUseUsageDescription',
    ]) {
      // The key, and a non-empty string after it. A bare <key> with an empty
      // <string/> satisfies a grep and still earns ITMS-90683.
      final declared = RegExp(
        '<key>$key</key>\\s*<string>([^<]+)</string>',
      ).firstMatch(plist);

      expect(declared, isNotNull,
          reason: '$key is missing from ios/Runner/Info.plist — '
              'the upload will come back ITMS-90683');
      expect(declared!.group(1)!.trim(), isNotEmpty,
          reason: '$key is declared but empty — Apple reads that as missing');
    }
  });
}
