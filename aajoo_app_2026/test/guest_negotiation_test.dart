// The host's stated response time, on the guest's thread.
//
// The platform answers a guest's first offer within ninety seconds using the
// host's own ideal price (server: services/negotiationAutoCounter.js). Past
// that the thread belongs to the two people in it, so "Waiting on host" is a
// real wait — and with no number attached it reads as "possibly for ever".
//
// The one rule worth pinning is what happens when the host never gave a
// figure: nothing is shown. A duration nobody promised is worse than silence,
// and "0 hours" or "24 hours" would both be inventions.
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/models/guest_negotiation.dart';

Map<String, dynamic> thread(Object? responseHours) => {
      'propertyId': 29279,
      'propertyName': 'Delhi Green Farm Stay',
      'listedPrice': 3000,
      'hostId': 169,
      'hostName': 'Aajoo Test Host',
      'messages': const [],
      'latestPrice': 2200,
      'status': 'awaiting_host',
      'awaitingYou': false,
      if (responseHours != null) 'hostResponseHours': responseHours,
    };

void main() {
  group('hostResponseHours', () {
    test('is read when the host gave one', () {
      expect(GuestNegotiation.fromJson(thread(6)).hostResponseHours, 6);
      // The API sends JSON numbers; a string must not break it either.
      expect(GuestNegotiation.fromJson(thread('12')).hostResponseHours, 12);
    });

    test('stays null when the host never said', () {
      // Absent from the payload…
      expect(GuestNegotiation.fromJson(thread(null)).hostResponseHours, isNull);
      // …explicitly null…
      expect(GuestNegotiation.fromJson({...thread(null), 'hostResponseHours': null})
          .hostResponseHours, isNull);
      // …or a zero, which is the column's "unset", not "instant".
      expect(GuestNegotiation.fromJson(thread(0)).hostResponseHours, isNull);
    });

    test('nonsense is treated as unsaid, not as a crash', () {
      expect(GuestNegotiation.fromJson(thread('soon')).hostResponseHours, isNull);
      expect(GuestNegotiation.fromJson(thread(-3)).hostResponseHours, isNull);
    });

    test('the rest of the thread still parses around it', () {
      final n = GuestNegotiation.fromJson(thread(6));
      expect(n.propertyId, 29279);
      expect(n.hostName, 'Aajoo Test Host');
      expect(n.status, 'awaiting_host');
      expect(n.listedPrice, 3000);
    });
  });
}
