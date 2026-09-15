// A week is negotiated as a total; a night is negotiated as a night.
//
// Client, 2026-09-15, with a screenshot of the Send an Offer dialog on a
// seven-night stay asking "Your offer per night": "while negotiating for
// weekly or monthly booking, renter should be asked total price instead of
// per night?? … for less than 7 days, per night negotiations is fine. But
// for weekly and monthly it should be on the total."
//
// The unit of RECORD stays per night — every offer, counter and coupon —
// and the unit of CONVERSATION follows the stay (utils/negotiation_unit.dart),
// the same rule the web and the server carry.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/utils/negotiation_unit.dart';

String codeOnly(String src) => src
    .replaceAll('\r\n', '\n')
    .split('\n')
    .where((l) => !l.trimLeft().startsWith('//'))
    .join('\n');

void main() {
  group('the line is a week', () {
    test('seven nights is a total, six is per night', () {
      expect(kLongStayNights, 7);
      expect(isLongStay(6), isFalse);
      expect(isLongStay(7), isTrue);
      expect(isLongStay(30), isTrue);
      expect(isLongStay(0), isFalse, reason: 'no dates yet is per night');
      expect(isLongStay(null), isFalse);
    });
  });

  group('the reported dialog', () {
    test('15–22 Sept at 12,000 asks for a total against 84,000', () {
      final nights = nightsBetweenDmy('15-09-2026', '22-09-2026');
      expect(nights, 7);
      expect(offerInputLabel(nights), 'Your offer for the 7 nights (₹)');
      expect(priceLine(12000, nights), '₹84,000 for 7 nights');
      // The guest types 70,000; the server is sent 10,000 a night.
      final o = offerFromInput(70000, nights);
      expect(o.perNight, 10000);
      expect(o.total, 70000);
    });

    test('a two-night stay is untouched', () {
      expect(offerInputLabel(2), 'Your offer per night (₹)');
      expect(offerInputLabel(2, counter: true), 'Your counter price per night (₹) *');
      final o = offerFromInput(11100, 2);
      expect(o.perNight, 11100);
      expect(o.total, 22200);
      expect(priceLine(11100, 2), '₹11,100/night');
      expect(priceLine(11100, 2, form: NightForm.a), '₹11,100 a night');
      expect(priceParts(11100, 2).unit, ' /night');
    });
  });

  group('the record round-trips', () {
    test('a typed total comes back to the rupee', () {
      for (final c in [(100000, 7), (42000, 7), (99999, 7), (150000, 31), (123457, 28)]) {
        final perNight = perNightOf(c.$1, c.$2);
        expect((perNight * 100).roundToDouble() / 100, perNight,
            reason: 'the record is DECIMAL(10,2)');
        expect(stayTotal(perNight, c.$2), c.$1,
            reason: '${c.$1} for ${c.$2} nights came back as ${stayTotal(perNight, c.$2)}');
      }
    });

    test('nights are counted from either date format', () {
      expect(nightsBetweenDmy('15-09-2026', '22-09-2026'), 7);
      expect(nightsBetweenDmy('2026-09-15', '2026-09-22'), 7);
      expect(nightsBetweenDmy(null, '22-09-2026'), isNull);
      expect(nightsBetweenDmy('garbage', '22-09-2026'), isNull);
    });
  });

  group('every screen speaks the same unit', () {
    test('the send-offer sheet reads the typed figure in the stay\'s unit', () {
      final src = codeOnly(File(
              'lib/ui/screens_renter/property_details/widgets/send_offer_sheet.dart')
          .readAsStringSync());
      expect(src, contains('_label(skin, offerInputLabel(_nights))'));
      expect(src, contains('final offer = offerFromInput(typed, _nights);'));
      expect(src, contains('offerIsPointless(offer.total.toDouble(), _listedTotal)'),
          reason: 'a long stay is not compared total against total');
      expect(src, contains("'We can do \${priceLine(quoted, _nights)}'"));
      expect(src, contains("'Accept \${priceLine(quoted, _nights)}'"));
      expect(src, isNot(contains("/night'")),
          reason: 'a hardcoded /night survives in the sheet');
    });

    test('the property page hands the sheet the stay\'s list total', () {
      final src = codeOnly(File(
              'lib/ui/screens_renter/property_details/property_page.dart')
          .readAsStringSync());
      expect(src, contains('listedTotal: _serverQuote?.originalSubtotal'));
    });

    test('the guest and host screens, and the host card', () {
      final guest = codeOnly(File(
              'lib/ui/screens_renter/negotiations/guest_negotiations_screen.dart')
          .readAsStringSync());
      expect(guest, contains('offerInputLabel(nights, counter: true)'));
      expect(guest, contains('final v = offerFromInput(typed, nights).perNight;'));
      expect(guest, isNot(contains("/night'")));
      expect(guest, isNot(contains(' /night')));

      final host = codeOnly(File(
              'lib/ui/screens_host/negotiations/host_negotiations_screen.dart')
          .readAsStringSync());
      expect(host, contains('final value = offerFromInput(typed, stayNights).perNight;'));
      expect(host, isNot(contains('/night')));

      final card = codeOnly(File(
              'lib/ui/screens_host/home/components/negotiation_card.dart')
          .readAsStringSync());
      expect(card, contains('Text(_priced(n.offerPrice),'));
      expect(card, contains("Text('for \$_nights nights',"));
    });
  });
}
