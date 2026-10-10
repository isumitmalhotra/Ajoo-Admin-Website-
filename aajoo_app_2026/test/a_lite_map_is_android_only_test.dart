// google_maps_flutter has a lite mode on Android only, and asserts
// `!liteModeEnabled || Platform.isAndroid` when a map is built. The listing's
// area map and the booking's stay map both set it to `true`, so on the iOS
// Simulator (2026-10-10) every debug build drew an error box in their place —
// the Location tab, the ongoing booking and the booking-confirmed screen. A
// release build strips the assert and the iOS plugin ignores the flag, so
// users never saw it, but every iOS check of those screens did.
//
// kDebugMode and Platform are fixed under `flutter test`, so the rule is held
// in the source: lite mode is asked for on Android only.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every liteModeEnabled is Android-only', () {
    final wrong = <String>[];
    var seen = 0;
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final l = lines[i].trimLeft();
        if (l.startsWith('//') || !l.contains('liteModeEnabled:')) continue;
        seen++;
        if (!RegExp(r'liteModeEnabled:\s*Platform\.isAndroid\b').hasMatch(l)) {
          wrong.add('${f.path}:${i + 1}  $l');
        }
      }
    }
    expect(seen, greaterThan(0), reason: 'the scan found no maps at all');
    expect(wrong, isEmpty);
  });
}
