import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/utils/nightly_rates.dart';
import 'package:rent_home/utils/booking_pricing.dart';

void main() {
  const rule = PricingRule(
    base: 5000, weekendPricing: true, friday: 6000, saturday: 6500, sunday: 6500,
    chargeExtraGuests: true, guestsIncluded: 8, extraGuestPrice: 1000, maxExtraGuests: 4,
  );

  test('party charge matches the server and the web', () {
    // Fri 28 -> Mon 31 Aug 2026: 6000 + 6500 + 6500 = 19000
    expect(rule.quote(DateTime(2026, 8, 28), DateTime(2026, 8, 31)), 19000);
    expect(rule.extraGuestFee(4, 3), 0);
    expect(rule.extraGuestFee(8, 3), 0);
    expect(rule.extraGuestFee(9, 3), 3000);
    expect(rule.extraGuestFee(10, 3), 6000);
    expect(rule.extraGuestFee(14, 3), 12000);
    expect(rule.extraGuestFee(20, 3), 12000); // capped at 4 extras
  });

  test('chargeable is what gets sent as price', () {
    final p = priceStay(
      roomSubtotal: 19000, perNightTariff: 5000, extraGuestFee: 6000,
    );
    expect(p.roomSubtotal, 19000);
    expect(p.extraGuestFee, 6000);
    expect(p.chargeable, 25000);
    expect(p.taxPct, 5);
    expect(p.taxes, 1250);
    expect(p.total, 26250);
  });

  test('a host who charges nothing extra is unaffected', () {
    const flat = PricingRule(base: 5000, weekendPricing: false);
    expect(flat.extraGuestFee(20, 3), 0);
    final p = priceStay(roomSubtotal: 15000, perNightTariff: 5000);
    expect(p.chargeable, 15000);
  });
}
