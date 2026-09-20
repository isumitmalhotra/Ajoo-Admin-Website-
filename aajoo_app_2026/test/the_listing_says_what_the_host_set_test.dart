// Two things the 300-case run caught on the app's listing page (2026-09-20,
// listing 29306): the booking sheet printed "12:00PM / 12:00PM · set by the
// host" for a host who set 14:00 / 11:00 — the wizard's stayWindow was never
// read — and "Where you'll sleep" listed only the bathrooms of a
// three-bedroom stay, because a bedroom with no bed line was skipped while
// the website lists it.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/models/single_property_response.dart';

String codeOnly(String src) => src
    .replaceAll('\r\n', '\n')
    .split('\n')
    .where((l) => !l.trimLeft().startsWith('//') && !l.trimLeft().startsWith('///'))
    .join('\n');

void main() {
  group('the stay clock', () {
    test('is parsed from the payload the server sends', () {
      final w = StayWindow.fromJson({'checkIn': '14:00', 'checkOut': '11:00'});
      expect(w.checkIn, '14:00');
      expect(w.checkOut, '11:00');
      final blank = StayWindow.fromJson({'checkIn': 'null', 'checkOut': ''});
      expect(blank.checkIn, isNull);
      expect(blank.checkOut, isNull);
    });

    test('the sheet reads the wizard hours before the legacy row', () {
      final page = codeOnly(File('lib/ui/screens_renter/property_details/property_page.dart').readAsStringSync());
      expect(page, contains("_clock(_single?.stayWindow?.checkIn) ?? _stayTime(_single?.propDetails?.inTime, widget.inTime)"));
      expect(page, contains("_clock(_single?.stayWindow?.checkOut) ?? _stayTime(_single?.propDetails?.outTime, widget.outTime)"));
    });
  });

  group('where you will sleep', () {
    test('an undescribed bedroom still counts as detail, as it does on the website', () {
      final rooms = PropertyRooms.fromJson({
        'bedrooms': [{'index': 1, 'heading': 'Bedroom 1'}, {'index': 2, 'heading': 'Bedroom 2'}, {'index': 3, 'heading': 'Bedroom 3'}],
        'bathrooms': [{'index': 1, 'heading': 'Bathroom 1'}, {'index': 2, 'heading': 'Bathroom 2'}],
      });
      expect(rooms.bedrooms.length, 3);
      expect(rooms.hasDetail, isTrue);
      expect(PropertyRooms.fromJson({'bedrooms': [], 'bathrooms': []}).hasDetail, isFalse);
    });

    test('every bedroom is rendered, described or not', () {
      final tabs = codeOnly(File('lib/ui/screens_renter/property_details/components/property_tabs.dart').readAsStringSync());
      expect(tabs, contains('for (final r in rooms.bedrooms) card(r, Icons.bed_outlined),'));
      expect(tabs, isNot(contains("if (r.beds.isNotEmpty || (r.bathroom ?? '').isNotEmpty)\n            card(r, Icons.bed_outlined)")));
    });
  });
}
