// A PrettyDioLogger prints every request and response it sees — the request
// line, the headers, the bodies, and the body of any error — to the device
// log: Console on iOS, logcat on Android. Six of the app's nine were already
// switched off outside debug builds with `enabled: kDebugMode` (79e1dff,
// 2026-08-11). Three were missed, and printed in release on both platforms
// (found 2026-10-10, before iOS/Android 124):
//
//   service/user_service.dart          the session's bearer token on every
//                                      call, and a password change's current
//                                      and new password
//   service/forgot_password_service    the reset OTP, reset token and new
//                                      password
//   screens_renter/checkout/…page      the bearer token on the review upload
//
// They now use DioConfig.logger(). This holds every logger in lib/ to the same
// rule, so a new service copied from an old one cannot bring it back.
// kDebugMode is a compile-time constant and always true under `flutter test`,
// so the rule is checked in the source, where the constant is written.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The file with line comments removed, so the scan reads code, not prose.
String codeOnly(String src) => src
    .replaceAll('\r\n', '\n')
    .split('\n')
    .map((l) => l.trimLeft().startsWith('//') ? '' : l)
    .join('\n');

/// Every `Name(...)` construction in [code], with its 1-based line and its
/// argument list (parentheses balanced).
Iterable<(int, String)> constructions(String code, String name) sync* {
  final start = RegExp('\\b${RegExp.escape(name)}\\(');
  for (final m in start.allMatches(code)) {
    var depth = 0;
    var i = m.end - 1;
    for (; i < code.length; i++) {
      if (code[i] == '(') depth++;
      if (code[i] == ')' && --depth == 0) break;
    }
    final line = '\n'.allMatches(code.substring(0, m.start)).length + 1;
    yield (line, code.substring(m.end, i));
  }
}

void main() {
  final dartFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  test('every PrettyDioLogger is switched off outside debug builds', () {
    final loud = <String>[];
    var seen = 0;
    for (final f in dartFiles) {
      final code = codeOnly(f.readAsStringSync());
      for (final (line, args) in constructions(code, 'PrettyDioLogger')) {
        seen++;
        if (!RegExp(r'\benabled:\s*kDebugMode\b').hasMatch(args)) {
          loud.add('${f.path}:$line');
        }
      }
    }
    expect(seen, greaterThan(0), reason: 'the scan found no loggers at all');
    expect(loud, isEmpty,
        reason: 'these print headers and bodies in release builds — '
            'use DioConfig.logger()');
  });

  test('the three that printed in release use the shared logger', () {
    for (final path in [
      'lib/service/user_service.dart',
      'lib/service/forgot_password_service.dart',
      'lib/ui/screens_renter/checkout/checkout_page.dart',
    ]) {
      final code = codeOnly(File(path).readAsStringSync());
      expect(code.contains('DioConfig.logger()'), isTrue, reason: path);
    }
  });

  test("Dio's own LogInterceptor is not used — it logs bodies by default", () {
    final used = [
      for (final f in dartFiles)
        for (final (line, _)
            in constructions(codeOnly(f.readAsStringSync()), 'LogInterceptor'))
          '${f.path}:$line',
    ];
    expect(used, isEmpty);
  });
}
