// The offer ceiling is the price of THESE NIGHTS.
//
// The app measured an offer against `property_price`, the flat nightly column,
// in the two places that stop a guest: the "Listed at ₹2,000 / night" line
// under the offer box, and the refusal that fires before anything is sent. On
// a listing whose 12 September is a weekend night at ₹2,500, a guest offering
// ₹2,400 — ₹100 UNDER what the stay costs, and above the host's accept line,
// so it should have been taken on the spot — was told "that is at or above the
// listed ₹2,000" and stopped by their own phone.
//
// The website carried the identical fault and fixed it on 12 September
// (src/redesign/lib/offerCeiling.ts). This is its twin.
//
//   flutter test test/offer_ceiling_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/utils/offer_ceiling.dart';

void main() {
  group('what a night lists at', () {
    test('a weekend night is the weekend rate, not the column', () {
      // 29291: nightly column ₹2,000; 12–13 September quotes at ₹2,500.
      expect(
        listedPerNight(roomSubtotal: 2500, nights: 1, basePrice: 2000),
        2500,
      );
    });

    test('a mixed stay averages the nights it actually covers', () {
      // 12–14 September: one weekend night at ₹2,500 and one at ₹2,000.
      expect(
        listedPerNight(roomSubtotal: 4500, nights: 2, basePrice: 2000),
        2250,
      );
    });

    test('no quote yet falls back to the column, never to a blank', () {
      // A stale figure beats an empty one, and the server refuses an
      // over-list offer regardless.
      expect(listedPerNight(roomSubtotal: null, nights: 1, basePrice: 2000), 2000);
      expect(listedPerNight(roomSubtotal: 0, nights: 1, basePrice: 2000), 2000);
      expect(listedPerNight(roomSubtotal: 2500, nights: 0, basePrice: 2000), 2000,
          reason: 'no dates chosen means no nights to divide by');
    });

    test('paise are kept, not rounded away', () {
      // A composite weekly rate divides unevenly; rounding here and again in
      // the comparison is how a ceiling drifts a rupee from the quote.
      expect(
        listedPerNight(roomSubtotal: 10000, nights: 3, basePrice: 2000),
        3333.33,
      );
    });
  });

  group('is there anything left to negotiate', () {
    test('under the price of the nights, yes', () {
      expect(offerIsPointless(2400, 2500), isFalse,
          reason: 'the offer that started all this');
      expect(offerIsPointless(1800, 2500), isFalse);
    });

    test('at or above it, no', () {
      expect(offerIsPointless(2500, 2500), isTrue);
      expect(offerIsPointless(2600, 2500), isTrue);
    });

    test('the comparison is on whole rupees', () {
      // 10,000 over 3 nights is ₹3,333.33 a night. A guest typing 3333 is
      // under it; one typing 3334 is not. Neither should be refused — or
      // accepted — on a third of a rupee.
      final ceiling = listedPerNight(roomSubtotal: 10000, nights: 3, basePrice: 2000);
      expect(offerIsPointless(3333, ceiling), isTrue,
          reason: '₹3,333 rounds to the same rupee as the ceiling');
      expect(offerIsPointless(3332, ceiling), isFalse);
    });

    test('an unknown ceiling refuses nothing', () {
      // Before the quote lands and with no base price, the client must not
      // invent a limit — the server is the real gate.
      expect(offerIsPointless(2400, 0), isFalse);
    });
  });
}
