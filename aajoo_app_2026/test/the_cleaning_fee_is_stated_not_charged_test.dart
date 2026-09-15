// The cleaning fee is stated, not charged — on every screen that prices a
// stay, in the same words as the website.
//
// Client decision, 2026-09-15 (master list §1.14): "it will only be stated
// in Things to know and all; if the renter requested it, it can be availed
// at that price and payments will be taken directly by the host." That
// reverses the five days (2026-09-10 to 09-15, builds 88–93) in which the
// server added it to every quote and this app charged, taxed and sent it.
//
// On 29310 (₹12,000 a night, ₹1,000 cleaning, 14–16 Sep): payable 24,000,
// GST 4,320, total 28,320 — and one line under the total saying the host
// charges ₹1,000 for cleaning if asked.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/utils/booking_pricing.dart';
import 'package:rent_home/utils/cleaning_fee.dart';
import 'package:rent_home/utils/nightly_rates.dart';

/// The file with comments removed, so the assertions read code, not prose.
String codeOnly(String src) => src
    .replaceAll('\r\n', '\n')
    .split('\n')
    .where((l) => !l.trimLeft().startsWith('//'))
    .join('\n');

void main() {
  group('the sum', () {
    test("THE CLIENT'S LISTING: two nights at 12,000 with 1,000 cleaning is 28,320, not 29,500", () {
      final p = priceStay(
        roomSubtotal: 24000,
        perNightTariff: 12000,
        cleaningFee: 1000,
        taxNights: const [12000, 12000],
      );
      expect(p.chargeable, 24000, reason: 'the cleaning fee is in the price sent');
      expect(p.taxes, 4320, reason: 'GST is being taken on the cleaning fee');
      expect(p.total, 28320);
      expect(p.cleaningFee, 1000, reason: 'the statement lost its figure');
    });

    test('no fee, no change', () {
      final p = priceStay(roomSubtotal: 24000, perNightTariff: 12000);
      expect(p.cleaningFee, 0);
      expect(p.chargeable, 24000);
    });
  });

  group('the words', () {
    test('per night or per stay, and nothing else', () {
      expect(cleaningFeeUnit('per_night'), 'per night');
      expect(cleaningFeeUnit('per_stay'), 'per stay');
      expect(cleaningFeeUnit('one_time'), 'per stay');
      expect(cleaningFeeUnit(null), 'per stay',
          reason: 'no frequency reads as per stay, the smaller of the two');
    });

    test('the sentence under the total, word for word the website\'s', () {
      expect(
        cleaningFeeStatement(500, 'per_stay', nights: 2),
        'The host charges ₹500 for cleaning if you ask for it — '
        'arranged and paid directly with them, not included in this total.',
      );
      expect(
        cleaningFeeStatement(500, 'per_night', nights: 3),
        'The host charges ₹500 per night (₹1,500 for 3 nights) for cleaning '
        'if you ask for it — arranged and paid directly with them, not '
        'included in this total.',
      );
      expect(cleaningFeeStatement(0, 'per_stay', nights: 2), '',
          reason: 'a listing with no fee says nothing');
    });

    test('the line under Things to know', () {
      expect(cleaningFeeRule(1000, 'per_stay'),
          'Cleaning available at ₹1,000 per stay, paid to the host');
      expect(cleaningFeeRule(500, 'per_night'),
          'Cleaning available at ₹500 per night, paid to the host');
    });

    test('the listing carries the figure, so Things to know can say it without dates', () {
      final rule = PricingRule.fromJson({
        'base': 12000,
        'cleaningFee': '1000',
        'cleaningFeeType': 'per_stay',
      });
      expect(rule?.cleaningFee, 1000);
      expect(rule?.cleaningFeeUnit, 'per stay');
      expect(PricingRule.fromJson({'base': 12000})?.cleaningFee, 0);
    });
  });

  group('the screens', () {
    final page = codeOnly(File(
            'lib/ui/screens_renter/property_details/property_page.dart')
        .readAsStringSync());
    final tabs = codeOnly(File(
            'lib/ui/screens_renter/property_details/components/property_tabs.dart')
        .readAsStringSync());
    final pricing = codeOnly(
        File('lib/utils/booking_pricing.dart').readAsStringSync());

    test('the booking sheet states the fee under the total and has no cleaning line', () {
      expect(page, isNot(contains("'Cleaning fee'")),
          reason: 'the sheet charges the cleaning fee as a line again');
      expect(page, isNot(contains("'Cleaning fee (per night)'")));
      expect(page, contains('cleaningFeeStatement('),
          reason: 'the sheet does not state the fee under the total');
    });

    test('Things to know states it — the client\'s words for where it lives', () {
      expect(tabs, contains('cleaningFeeRule('));
    });

    test('priceStay keeps it out of chargeable', () {
      expect(pricing, contains('final chargeable = subtotal + party + petCharge;'));
      expect(pricing, isNot(contains('petCharge + cleaning;')),
          reason: 'the cleaning fee is in the price sent again');
    });
  });
}
