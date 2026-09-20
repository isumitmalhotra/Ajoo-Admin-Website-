// Two readiness refreshes are often in flight at once (a step change and a
// document upload), and the SLOWER answer landed last: step 5 read "9 of 10
// photos" over a listing the server already had at 10 (300-case run,
// 2026-09-21). Only the newest request's answer is kept.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/service/listing_service.dart';
import 'package:rent_home/ui/screens_host/listing/listing_wizard_controller.dart';

class _SlowThenFast extends ListingService {
  final answers = <Completer<Map<String, dynamic>>>[];
  @override
  Future<Map<String, dynamic>> getReadiness(int propertyId) {
    final c = Completer<Map<String, dynamic>>();
    answers.add(c);
    return c.future;
  }
}

void main() {
  test('a stale answer that arrives after a newer one is dropped', () async {
    final svc = _SlowThenFast();
    final c = ListingWizardController(propertyId: 29312, service: svc);
    c.propertyId.value = 29312;
    final first = c.refreshReadiness();   // fired on the step change
    final second = c.refreshReadiness();  // fired by the document upload
    // The newer request answers first...
    svc.answers[1].complete({'percent': 95, 'photoCount': 10});
    await second;
    expect(c.readiness['percent'], 95);
    // ...and the older one lands afterwards, with yesterday's numbers.
    svc.answers[0].complete({'percent': 70, 'photoCount': 9});
    await first;
    expect(c.readiness['percent'], 95, reason: 'the stale answer must not overwrite the newer one');
  });
}
