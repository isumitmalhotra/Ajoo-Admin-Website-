// The settlement payload the server actually sends, parsed by the model the
// screen uses.
//
// Captured verbatim from GET /host/dues on 2026-08-30 (host 100). The risk
// this pins is field names: every one of them is a silent 0 or an empty string
// if it drifts, and a settlement screen that quietly reads zero is worse than
// one that fails.
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/service/host_dues_service.dart';

const _payload = r'''
{
  "items": [
    {
      "dueId": 23,
      "bookingCode": "B170383",
      "property": "Jerry",
      "stay": {
        "from": "26-08-2026",
        "to": "27-08-2026"
      },
      "collectedFromGuest": 1365,
      "breakdown": {
        "commission": 195,
        "gstOnCommission": 35,
        "accommodationGst": 65
      },
      "amount": 295,
      "payableNow": true
    },
    {
      "dueId": 22,
      "bookingCode": "B780678",
      "property": "Aajoo Homes",
      "stay": {
        "from": "26-08-2026",
        "to": "28-08-2026"
      },
      "collectedFromGuest": 4200,
      "breakdown": {
        "commission": 600,
        "gstOnCommission": 108,
        "accommodationGst": 200
      },
      "amount": 908,
      "payableNow": true
    }
  ],
  "totals": {
    "payableNow": 11896.25,
    "upcoming": 10465,
    "all": 22361.25,
    "count": 17,
    "payableCount": 10
  },
  "settled": [],
  "note": "Anything left unpaid is deducted from your next payout."
}
''';

void main() {
  final dues = HostDues.fromJson(
      Map<String, dynamic>.from(jsonDecode(_payload) as Map));

  test('the totals survive the round trip', () {
    expect(dues.payableNow, 11896.25);
    expect(dues.upcoming, 10465);
    expect(dues.items.length, 2);
    expect(dues.note.isNotEmpty, isTrue);
  });

  test('a due keeps its three parts, and they add up to the total', () {
    final d = dues.items.first;
    expect(d.bookingCode, 'B170383');
    expect(d.commission, 195);
    expect(d.gstOnCommission, 35);
    expect(d.accommodationGst, 65);
    expect(d.commission + d.gstOnCommission + d.accommodationGst, d.amount);
  });

  test('what the host keeps is what they collected minus what they owe', () {
    for (final d in dues.items) {
      expect(d.hostKeeps, d.collectedFromGuest - d.amount);
      expect(d.hostKeeps >= 0, isTrue);
    }
  });

  test('the stay dates are read, not dropped', () {
    expect(dues.items.first.stayFrom.isNotEmpty, isTrue);
    expect(dues.items.first.property.isNotEmpty, isTrue);
  });

  test('a payload with nothing in it is empty, not a crash', () {
    final empty = HostDues.fromJson(const {});
    expect(empty.items, isEmpty);
    expect(empty.payableNow, 0);
    expect(empty.hasAnything, isFalse);
    // The consequence still gets said even when the server says nothing.
    expect(empty.note.contains('payout'), isTrue);
  });
}
