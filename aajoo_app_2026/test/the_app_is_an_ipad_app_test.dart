// iPhone and iPad, from build 125 (Sumit, 2026-10-15).
//
// Build 124 went the other way: TARGETED_DEVICE_FAMILY = 1 in all three
// configurations, and App Store Connect reported "Device Family: iPhone" on
// the uploaded build while the product page carried nine iPad screenshots.
// A listing that promises an iPad layout the binary cannot render is a 2.3.3
// rejection waiting to happen, so the two have to agree.
//
// The setting lives in the Xcode project, and ticking "iPad" in Xcode's
// General tab is enough to change it without anyone noticing in a diff.
// tool/verify_release_ipa.py checks the built Info.plist for the same thing;
// this holds the project that produces it, so the value cannot drift between
// builds.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every build configuration targets iPhone and iPad', () {
    final project =
        File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    final families = RegExp(r'TARGETED_DEVICE_FAMILY = ("?)([^;]*)\1;')
        .allMatches(project)
        .map((m) => m.group(2))
        .toList();
    // Debug, Release and Profile.
    expect(families.length, greaterThanOrEqualTo(3));
    expect(families, everyElement('1,2'));
  });
}
