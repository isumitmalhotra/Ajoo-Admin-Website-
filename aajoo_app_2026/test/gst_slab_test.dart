import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/utils/gst.dart';

/// The GST slab, and the two ways the app had it wrong.
///
/// Three screens carried their own copy of the rule as
/// `price <= 7500 ? 0.05 : 0.18`, and both halves of that were wrong once the
/// client settled the rule on 2026-09-10.
void main() {
  group('the boundary', () {
    test('7,500 exactly is the HIGH band', () {
      // `<= 7500 => 5%` taxed the boundary itself — and the commonest round
      // number a host picks — at the low rate, while the server charged the
      // high one. Two screens then showed a total no invoice would match.
      expect(gstRateForNight(7499), kGstLow);
      expect(gstRateForNight(7500), kGstHigh);
      expect(gstRateForNight(7501), kGstHigh);
    });

    test('an ordinary night is the low band', () {
      expect(gstRateForNight(2000), kGstLow);
      expect(gstRateForNight(0), kGstLow);
    });
  });

  group('the figure the band is taken from', () {
    test('THE ONE THAT MATTERS: it is per NIGHT, not per stay', () {
      // The checkout banded on the whole stay, so two nights at 5,000 came to
      // 10,000 and were taxed at 18% — a rate neither night is anywhere near.
      expect(gstOnStay(10000, nights: 2), closeTo(500, 0.001));
      // ...and one night at 10,000 really is the high band.
      expect(gstOnStay(10000, nights: 1), closeTo(1800, 0.001));
    });

    test('a stay of dear nights stays in the high band', () {
      expect(gstOnStay(16000, nights: 2), closeTo(2880, 0.001));
    });

    test('an unknown night count does not divide by zero', () {
      expect(gstOnStay(5000, nights: 0), closeTo(250, 0.001));
    });
  });
}
