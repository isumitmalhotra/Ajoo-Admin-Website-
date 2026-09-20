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
    expect(page, contains('bool get _canAddGuest {'));
    expect(page, contains('if (ma != null && (_guests + 1 - _children) > ma) return false;'), reason: 'one more guest with the same children is one more adult');
    expect(page, contains('onPressed: _canAddGuest'));
  });

  test('the children plus is bound by the party AND by the children cap', () {
    expect(page, contains('bool get _canAddChild {'));
    expect(page, contains('return mc == null || _children < mc;'));
    expect(page, contains('onPressed: _canAddChild'));
  });

  test('0 or absent means the host stated no cap, as it does for pets', () {
    expect(page, contains("int? get _maxAdults { final v = _single?.capacity?.adults; return (v != null && v > 0) ? v : null; }"));
  });

  test('the caps are said on screen, so a stopped button has its reason', () {
    expect(page, contains("Text('This place sleeps up to \$_guestCeiling\$_capsLine'"));
    expect(page, contains("return parts.isEmpty ? '' : ' · up to \${parts.join(' · ')}';"));
  });
}
