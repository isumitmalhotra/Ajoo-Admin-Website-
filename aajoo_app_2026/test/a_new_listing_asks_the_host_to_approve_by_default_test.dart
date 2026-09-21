// The website's step 4 defaults the booking type to "approval"; the app left
// it unset, the server stored NULL, and the listing booked as instant while
// its confirmation page said "request sent" (300-case run, NG-011 on #29312,
// 2026-09-21). Same default on both clients; a saved value still wins.
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/ui/screens_host/listing/listing_wizard_controller.dart';

void main() {
  test('a fresh draft asks the host to approve, like the website', () {
    final c = ListingWizardController();
    expect(c.p4['booking_type'], 'approval');
  });

  test('the host can still choose instant', () {
    final c = ListingWizardController();
    c.setP4('booking_type', 'instant');
    expect(c.p4['booking_type'], 'instant');
  });
}
