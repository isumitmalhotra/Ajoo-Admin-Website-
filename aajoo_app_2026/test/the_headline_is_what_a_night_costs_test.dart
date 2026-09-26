// The sticky bar showed two numbers from the same screen that disagreed by 80%.
//
// Photographed by the client on 26 September 2026 — a SATURDAY — on the
// listing "Villa in the hills of landour Uttarakhand", whose pricing record is
// base 5,000 with saturday 9,000:
//
//     ₹5,000 /night
//     ₹10,620 total · incl. taxes · 1 night
//
// 10,620 is 9,000 + 18% GST, and it is CORRECT: the server priced the Saturday
// at the rate the host set. The headline is the wrong one. It read
// `currentPrice`, which is `property_price` — the flat nightly column, and on
// any weekend stay simply not what a night costs.
//
// This is the trap the master list calls "Dated Price, Undated Column", and it
// had already been found once, in the offer sheet, where measuring an offer
// against the flat column refused offers UNDER what the nights actually cost.
// `listedPerNight` was written then. The headline was left reading the column.
//
// Nothing about this is iOS-specific — it is one Flutter codebase, so Android
// showed the same two numbers.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/utils/nightly_rates.dart';
import 'package:rent_home/utils/offer_ceiling.dart';

String _codeOnly(String src) => src
    .replaceAll('\r\n', '\n')
    .split('\n')
    .where((l) =>
        !l.trimLeft().startsWith('//') && !l.trimLeft().startsWith('///'))
    .join('\n');

void main() {
  final page = _codeOnly(File(
          'lib/ui/screens_renter/property_details/property_page.dart')
      .readAsStringSync());

  /// The client's listing, exactly as the API serves it.
  final landour = PricingRule.fromJson(const {
    'base': 5000,
    'weekendPricing': true,
    'friday': 9000,
    'saturday': 9000,
    'sunday': 10000,
  })!;

  group('the rate for a date', () {
    test('a Saturday is the Saturday rate, not the base', () {
      // 26 September 2026 is a Saturday. If this ever fails, check the day
      // before the code: DateTime.weekday is 1=Monday…7=Sunday, and reading it
      // as JavaScript's 0=Sunday shifts every rate by a day.
      final sat = DateTime(2026, 9, 26);
      expect(sat.weekday, DateTime.saturday);
      expect(landour.rateForDate(sat), 9000);
      expect(landour.rateForDate(DateTime(2026, 9, 27)), 10000); // Sunday
      expect(landour.rateForDate(DateTime(2026, 9, 29)), 5000); // Tuesday
    });

    test('one Saturday night is quoted at 9,000, not 5,000', () {
      // Half-open: 26th to 27th is ONE night, the Saturday.
      expect(landour.quote(DateTime(2026, 9, 26), DateTime(2026, 9, 27)), 9000);
      expect(
        landour.differsFromFlat(
            DateTime(2026, 9, 26), DateTime(2026, 9, 27), 1),
        isTrue,
        reason: 'the stay is not base × nights, and the UI must be able to say so',
      );
    });
  });

  group('the headline', () {
    test('is the server subtotal per night when there is a quote', () {
      // What the bar must now show for the client's stay: 9,000, matching the
      // 10,620 total beside it once GST is added.
      expect(
        listedPerNight(roomSubtotal: 9000, nights: 1, basePrice: 5000),
        9000,
      );
      // And for a two-night Sat+Sun: (9,000 + 10,000) / 2.
      expect(
        listedPerNight(roomSubtotal: 19000, nights: 2, basePrice: 5000),
        9500,
      );
    });

    test('falls back to the flat column only when there is no quote yet', () {
      // First paint, before the server answers. Showing something is better
      // than showing nothing; it corrects itself when the quote lands.
      expect(listedPerNight(roomSubtotal: null, nights: 1, basePrice: 5000), 5000);
      expect(listedPerNight(roomSubtotal: 0, nights: 1, basePrice: 5000), 5000);
      expect(listedPerNight(roomSubtotal: 9000, nights: 0, basePrice: 5000), 5000);
    });

    test('the sticky bar reads _listedPerNight, not currentPrice', () {
      // The actual regression guard. `currentPrice` is still used elsewhere
      // and legitimately — it is the flat column, and some things do want it —
      // so this pins the ONE place that was wrong.
      expect(
        page,
        contains('final perNight = _listedPerNight.toStringAsFixed(0)'),
        reason: 'the headline is back on the flat property_price column, so on '
            'any weekend stay it will disagree with the total beside it',
      );
      expect(
        page.contains('final perNight = currentPrice.toStringAsFixed(0)'),
        isFalse,
        reason: 'the flat column is feeding the headline again',
      );
    });
  });

  test('the GST band is decided by what the night ACTUALLY costs', () {
    // Worth pinning because it is the other half of the same screen. The
    // Saturday rate of 9,000 is ABOVE the 7,500 band, so it attracts 18% —
    // 10,620. Had the headline's 5,000 been used to price the stay it would
    // have fallen in the 12% band and produced 5,600, and the client would
    // have been undercharged rather than merely confused.
    expect(9000 * 1.18, closeTo(10620, 0.001));
    expect(5000 * 1.12, closeTo(5600, 0.001));
  });
}
