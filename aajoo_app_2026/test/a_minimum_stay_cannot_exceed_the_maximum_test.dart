// A minimum stay above the maximum is a listing nobody can book. Neither
// client nor the server checked it, so 3 minimum / 2 maximum nights saved on
// the app (300-case run, HL-075, 2026-09-21). Said on the maximum field.
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/service/listing_service.dart';
import 'package:rent_home/ui/screens_host/listing/listing_wizard_controller.dart';

class _StubService extends ListingService {}

void main() {
  test('3 minimum over 2 maximum is refused on the maximum field', () {
    final c = ListingWizardController(service: _StubService());
    c.p4['cancellation_policy'] = 'moderate';
    c.p4['min_stay_nights'] = '3';
    c.p4['max_stay_nights'] = '2';
    final errs = c.validateStep4();
    expect(errs['max_stay_nights'], "Maximum nights (2) can't be below minimum nights (3).");
  });

  test('blank means no limit and is never compared; equal is fine', () {
    final c = ListingWizardController(service: _StubService());
    c.p4['cancellation_policy'] = 'moderate';
    c.p4['min_stay_nights'] = '3';
    expect(c.validateStep4()['max_stay_nights'], isNull);
    c.p4['max_stay_nights'] = '3';
    expect(c.validateStep4()['max_stay_nights'], isNull);
  });
}
