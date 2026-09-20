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

  test('the ₹7,500 threshold itself is the HIGH band', () {
    // Client rule, 2026-09-10: "even equal to 7500 should be charged at
    // 18%". utils/gst.dart and the server have said so since; this pricer
    // still said 5% until 2026-09-15, when the emulator showed it
    // disagreeing with the server on a weekly stay.
    expect(priceStay(roomSubtotal: 7500, perNightTariff: 7500).taxPct, 18);
    expect(priceStay(roomSubtotal: 7499, perNightTariff: 7499).taxPct, 5);
  });

  test('THE EMULATOR CASE: 29309 for a week is banded per night, not on the average', () {
    // ₹45,000 weekly; nights list at 7,000 ×4, 8,000 ×2, 9,000 ×1 (₹53,000
    // at the nightly rates). The Sunday's share of ₹45,000 is ₹7,642 — over
    // the line — so the server charges 5% on six nights and 18% on one:
    // ₹3,243.40. Banding on the base tariff (7,000 → 5% on everything)
    // showed ₹47,250 for a stay the server charges ₹48,243.40 for.
    //
    // Build 92 (2026-09-15, morning) charged the ₹500 cleaning fee too and
    // the figure was ₹48,779.43; the fee is STATED, not charged, since the
    // same afternoon (client, §1.14), so the ₹500 is said under the total
    // and is not in it.
    final p = priceStay(
      roomSubtotal: 45000,
      perNightTariff: 7000,
      cleaningFee: 500,
      taxNights: const [7000, 7000, 7000, 8000, 8000, 9000, 7000],
    );
    expect(p.chargeable, 45000, reason: 'the cleaning fee is stated, not sent');
    expect(p.taxes, 3243.40);
    expect(p.total, 48243.40);
    expect(p.taxBands, [5, 5, 5, 5, 5, 18, 5]);
    expect(p.taxPct, 7.21, reason: 'blended, and never printed as a rate');
    expect(p.taxLabel, 'GST · 6 nights at 5% · 1 night at 18%');
    expect(p.cleaningFee, 500, reason: 'the statement still carries the figure');
  });

  test('one band prints as a rate; no weights falls back to the average night', () {
    final one = priceStay(roomSubtotal: 24000, perNightTariff: 12000, cleaningFee: 1000,
        taxNights: const [12000, 12000]);
    expect(one.taxLabel, 'GST (18%)');
    expect(one.taxes, 4320, reason: '18% of the room; the cleaning fee is not taxed');
    final none = priceStay(roomSubtotal: 45000, perNightTariff: 7000, cleaningFee: 500);
    expect(none.taxBands, isEmpty);
    expect(none.taxLabel, 'GST (5%)');
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

  test('the cleaning fee is stated, not charged — 29302, 18–20 Sep 2026', () {
    // Client decision, 2026-09-15 (§1.14): "it will only be stated in
    // Things to know… payments will be taken directly by the host." The
    // server quotes ₹6,660 for the room (after the 10% advance discount)
    // and says the host charges ₹500 for cleaning; 5% GST on the room →
    // ₹6,993. Builds 88–93 sent ₹7,160 and showed ₹7,518; the server now
    // recognises that figure and charges ₹6,993.
    final p = priceStay(
      roomSubtotal: 6660,
      perNightTariff: 3000,
      cleaningFee: 500,
    );
    expect(p.cleaningFee, 500, reason: 'the statement carries the figure');
    expect(p.chargeable, 6660,
        reason: 'the price sent includes the cleaning fee — the guest is charged for something the host collects directly');
    expect(p.taxes, 333, reason: 'GST is levied on the cleaning fee');
    expect(p.total, 6993);
  });

  test('no cleaning fee is no line and no charge', () {
    final p = priceStay(roomSubtotal: 6660, perNightTariff: 3000);
    expect(p.cleaningFee, 0);
    expect(p.chargeable, 6660);
  });

  test('the slab fallback is per night of THIS stay, not the flat tariff (2026-09-20)', () {
    // Listing 29295: flat Rs 7,000, Sunday Rs 9,500. Before the server quote
    // arrives the sheet only knows the dated room subtotal and the night
    // count. It banded on the flat 7,000 and printed GST (5%) Rs 475 /
    // Rs 9,975; the server (and the sticky bar) said 18% / Rs 11,210.
    final weekend = priceStay(roomSubtotal: 9500, perNightTariff: 7000, nights: 1);
    expect(weekend.taxPct, 18);
    expect(weekend.taxes, 1710);
    expect(weekend.total, 11210);
    // Two ordinary nights of that listing stay in the low band, as before.
    final weekdays = priceStay(roomSubtotal: 14000, perNightTariff: 7000, nights: 2);
    expect(weekdays.taxPct, 5);
    // ...and with the deal applied, the band follows the post-discount night.
    final deal = priceStay(roomSubtotal: 9500, perNightTariff: 7000, discount: 1100.10, nights: 1);
    expect(deal.taxPct, 18);
    expect(deal.total, closeTo(9911.88, 0.01));
    // No night count (an undated quote): the flat tariff decides, as it always did.
    expect(priceStay(roomSubtotal: 9500, perNightTariff: 7000).taxPct, 5);
  });
}
