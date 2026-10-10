// iPhone only, from build 124 (Sumit, 2026-10-10). Builds 115-123 carried
// TARGETED_DEVICE_FAMILY = "1,2", so every binary advertised iPad and App
// Store Connect asked for iPad screenshots and an iPad review. The setting
// lives in the Xcode project — Xcode writes it into the built Info.plist as
// UIDeviceFamily, which tool/verify_release_ipa.py checks on each build. This
// holds the project itself, so iPad cannot come back between builds (ticking
// "iPad" in Xcode's General tab is enough to do it).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every build configuration targets iPhone only', () {
    final project =
        File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    final families = RegExp(r'TARGETED_DEVICE_FAMILY = ("?)([^;]*)\1;')
        .allMatches(project)
        .map((m) => m.group(2))
        .toList();
    // Debug, Release and Profile.
    expect(families.length, greaterThanOrEqualTo(3));
    expect(families, everyElement('1'));
  });
}
