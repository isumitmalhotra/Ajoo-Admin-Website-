// The double-tax was a money bug that reached a real guest (B618787: quoted
// ₹23,020, ledger said ₹24,171, pay-on-arrival would have collected the
// difference), so the pricing rule gets tests rather than a careful read.
//
// The numbers below are the ones from that booking and from the GST threshold,
// checked against the backend's calculateBookingtax() and the web's summarize().
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/utils/booking_pricing.dart';

void main() {
  test('B618787 — the booking that was overbilled', () {
    // ₹19,500 room for the stay, listed at ₹19,500/night → 18% band.
    final p = priceStay(roomSubtotal: 19500, perNightTariff: 19500);
    expect(p.taxPct, 18);
    expect(p.taxes, 3510);
    expect(p.total, 23010);
    // The subtotal is what goes to the backend — never the total. Sending the
    // total is exactly what produced the ₹24,171 row.
    expect(p.roomSubtotal, 19500);
  });

  test('GST bands on the per-night tariff, not the stay total', () {
    // ₹4,000/night for two nights = ₹8,000 for the stay. Over ₹7,500 in total,
    // but the nightly tariff is under it, so it is 5% — the app used to read
    // the ₹8,000 and charge the guest 18% on screen.
    final p = priceStay(roomSubtotal: 8000, perNightTariff: 4000);
    expect(p.taxPct, 5);
    expect(p.taxes, 400);
    expect(p.total, 8400);
  });

  test('the ₹7,500 threshold itself is the lower band', () {
    expect(priceStay(roomSubtotal: 7500, perNightTariff: 7500).taxPct, 5);
    expect(priceStay(roomSubtotal: 7501, perNightTariff: 7501).taxPct, 18);
  });

  test('6,500 at 5% — matches the rate verified end to end', () {
    final p = priceStay(roomSubtotal: 6500, perNightTariff: 6500);
    expect(p.taxPct, 5);
    expect(p.taxes, 325);
    expect(p.total, 6825);
  });

  test('rounds tax to paise the way the backend does', () {
    // 1,999.99 × 5% = 99.9995 → 100.00, not 99.99 and not 99.9995.
    final p = priceStay(roomSubtotal: 1999.99, perNightTariff: 2000);
    expect(p.taxes, 100.0);
  });

  test('no platform fee — nothing collects one', () {
    final p = priceStay(roomSubtotal: 1000, perNightTariff: 1000);
    expect(p.total, p.roomSubtotal + p.taxes);
  });

  test('a nonsense subtotal prices as zero rather than NaN', () {
    expect(priceStay(roomSubtotal: -50, perNightTariff: 1000).total, 0);
    expect(priceStay(roomSubtotal: double.nan, perNightTariff: 1000).total, 0);
  });

  test('a coupon comes off the room BEFORE GST, like the backend', () {
    // ₹10,000 stay at ₹5,000/night (5% band), ₹1,000 off.
    final p = priceStay(
      roomSubtotal: 10000,
      perNightTariff: 5000,
      discount: 1000,
    );
    expect(p.discountedRoom, 9000);
    expect(p.taxes, 450); // 5% of 9,000, not of 10,000
    expect(p.total, 9450);
    // The undiscounted subtotal is still what gets sent — the backend
    // recomputes the discount from the code and would otherwise take it twice.
    expect(p.roomSubtotal, 10000);
  });

  test('a discount cannot drive the total below zero', () {
    final p = priceStay(roomSubtotal: 500, perNightTariff: 500, discount: 900);
    expect(p.discountedRoom, 0);
    expect(p.discount, 500);
    expect(p.total, 0);
  });

  test('no coupon leaves the room total untouched', () {
    final p = priceStay(roomSubtotal: 4000, perNightTariff: 2000);
    expect(p.discount, 0);
    expect(p.discountedRoom, 4000);
  });
}
