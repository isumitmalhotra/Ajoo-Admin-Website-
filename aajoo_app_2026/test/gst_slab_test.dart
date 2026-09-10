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

    /// Reported 2026-09-10: "5% GST applied incorrectly to the weekly price
    /// even when the applicable weekly pricing is 7,500 and the weekend price
    /// is 8,500." The expectation was 18%, because every LIST rate on such a
    /// stay is at or above the slab.
    ///
    /// 5% is right. On the property in question a week of nights listed at
    /// 7,500 / 8,500 / 9,000 — 56,000 at list — sells for 45,000, and a 20%
    /// advance discount takes it to 36,000. That is ~5,142 a night, and the
    /// rule is on the final price the guest pays, not the sticker.
    ///
    /// The figures here are the SERVER's, taken from running the real pricing
    /// engine against property 29297. This app's helper is only a fallback for
    /// when the server sends no tax at all, so the number that matters is that
    /// the two agree.
    test('THE REPORTED CASE: a weekly stay is banded on its own per-night share', () {
      // 36,000 across 7 nights -> 5,142.86 a night -> low band -> 1,800.
      expect(gstOnStay(36000, nights: 7), closeTo(1800, 0.001));
      // Server: taxForNights(36000, [7500 x4, 8500 x2, 9000]) = 1800 at 5%.

      // And the same stay WITHOUT the week rate — seven nights at list — is
      // the higher band, which is what makes the discount the deciding fact
      // rather than the property being cheap.
      expect(gstOnStay(56000, nights: 7), closeTo(56000 * 0.18, 0.001));
    });

    test('an unknown night count does not divide by zero', () {
      expect(gstOnStay(5000, nights: 0), closeTo(250, 0.001));
    });
  });
}
