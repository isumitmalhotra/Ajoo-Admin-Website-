/// An escaped dollar turns a diagnostic into a literal.
///
/// In Dart, `'\$foo'` is an ESCAPED dollar: the string contains the characters
/// `$foo`, not the value of `foo`. It compiles, it runs, the analyzer says
/// nothing, and the log line written specifically to explain a failure in the
/// field carries no information at all.
///
/// Found 2026-09-28 while diagnosing the client's "app stuck here not going
/// forward" report. The Apple sign-in handler had:
///
///     appLog('Apple sign-in failed: code=\${e.code} message=\${e.message}');
///
/// so every Apple failure on every handset had been logging the literal text
/// `${e.code}` since it was written. The one line meant to say WHY said nothing,
/// and the same mistake was about to be introduced into the phone-capture
/// dialog in the same session.
///
/// This is worth a test rather than a note because it is invisible three ways:
/// it is valid Dart, the analyzer is silent, and the damage only shows up when
/// somebody is already trying to debug something else.
///
///   flutter test test/a_log_line_that_logs_nothing_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no log line contains an escaped \$ where interpolation was meant', () {
    final lib = Directory('lib');
    expect(lib.existsSync(), isTrue, reason: 'run this from the app root');

    // `\$` immediately followed by `{` or an identifier is always a mistake in
    // a log line: nobody wants to print the literal characters "${e.code}".
    // A lone `\$` before a space or a digit (a price, "US\$") is legitimate and
    // is deliberately not matched.
    final escapedInterpolation = RegExp(r'\\\$[{A-Za-z_]');

    final offenders = <String>[];
    for (final f in lib
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        // Only the lines whose whole job is to report something. A `\$` in
        // ordinary display copy is far more likely to be a real currency sign.
        final isDiagnostic = line.contains('appLog(') ||
            line.contains('debugPrint(') ||
            line.contains('log(') && line.contains("'");
        if (!isDiagnostic) continue;
        if (escapedInterpolation.hasMatch(line)) {
          offenders.add('${f.path}:${i + 1}: ${line.trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'These log lines escape the dollar, so they print the literal '
          'text instead of the value and say nothing when read:\n  '
          '${offenders.join('\n  ')}',
    );
  });

  test('the phone-capture dialog keeps the session on a failed save', () {
    // The client's report was a loop: the dialog closed, the save failed, a
    // three-second snackbar carried the reason, and the session was torn down —
    // so signing in again re-created the same dialog with the explanation gone.
    // A failed save is recoverable and must not cost the session.
    final src =
        File('lib/ui/screens_common/auth/auth_controller.dart').readAsStringSync();
    final start = src.indexOf('Future<bool> _requirePhone');
    expect(start, greaterThan(0), reason: '_requirePhone is gone');
    final body = src.substring(start, src.indexOf('Future<void> getUserDetails'));

    expect(body.contains('StatefulBuilder'), isTrue,
        reason: 'the dialog cannot show an error without local state');
    expect(body.contains('saveError'), isTrue,
        reason: "the server's message is not shown in the dialog");
    expect(body.contains('saved.message'), isTrue,
        reason: 'the failure is reported in words of our own, not the server\'s');

    // The save must happen while the dialog is still up: if Get.back() runs
    // before updateUserProfile, the reason has nowhere to land.
    final backOnSuccess = body.indexOf('Get.back(result: true)');
    final save = body.indexOf('updateUserProfile(');
    expect(save, greaterThan(0), reason: 'the dialog no longer saves anything');
    expect(save, lessThan(backOnSuccess),
        reason: 'the dialog closes before the save, which is the original bug');
  });
}
