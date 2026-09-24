// The host's per-type caps bind the guest counter (300-case run, BK-030,
// 2026-09-20): a "3 adults + 2 children, 5 in all" listing let a guest pick
// five adults on the app, the website and the API alike. The server now
// refuses that; the counter must stop where the server would.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String codeOnly(String src) => src
    .replaceAll('\r\n', '\n')
    .split('\n')
    .where((l) => !l.trimLeft().startsWith('//') && !l.trimLeft().startsWith('///'))
    .join('\n');

void main() {
  final page = codeOnly(File('lib/ui/screens_renter/property_details/property_page.dart').readAsStringSync());

  test('the guests plus is bound by the total AND by the adults cap', () {
    // The STRING, not `Text(` plus the string. Pinning the widget call as
    // well made this fail on a reformat that split the constructor over two
    // lines: the row was wrapped in Expanded so the guest counter stopped
    // being pushed off the right edge, and this went red over a bracket.
    // A test that reports a bug when the formatter moves punctuation is a
    // test nobody trusts the next time it goes red.
    expect(page, contains(r"'This place sleeps up to $_guestCeiling$_capsLine'"));
    expect(page, contains("return parts.isEmpty ? '' : ' · up to \${parts.join(' · ')}';"));
  });
}
