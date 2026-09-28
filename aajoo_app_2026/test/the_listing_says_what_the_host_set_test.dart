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
    test('rows a host never described are NOT detail, on either platform', () {
      // CHANGED 2026-09-28. This used to expect isTrue, "as it does on the
      // website" — a parity fix from the 300-case run (2026-09-20) when the
      // two pages disagreed about this section.
      //
      // The parity finding was right and is untouched: WHICH rooms render
      // inside the section is still "all of them", on both platforms, and the
      // test below still pins it. What that fix did not question was whether
      // the section should appear AT ALL when nothing has been described —
      // and both sides said yes, because both were counting rows.
      //
      // saveFor writes one row per room from the COUNTS, so listing #1 (five
      // bedrooms, three bathrooms, none described) rendered eight boxes saying
      // "Bedroom 1 … Bathroom 3" and nothing else — strictly less than the
      // "5 bedrooms · 3 baths" chip already above it. The client reported it
      // on 2026-09-28. utils/propertyRooms.js answers it once now and sends
      // hasDetail, so the two cannot drift apart again.
      final bare = PropertyRooms.fromJson({
        'bedrooms': [{'index': 1, 'heading': 'Bedroom 1'}, {'index': 2, 'heading': 'Bedroom 2'}, {'index': 3, 'heading': 'Bedroom 3'}],
        'bathrooms': [{'index': 1, 'heading': 'Bathroom 1'}, {'index': 2, 'heading': 'Bathroom 2'}],
        'hasDetail': false,
      });
      expect(bare.bedrooms.length, 3, reason: 'the rooms must still arrive');
      expect(bare.hasDetail, isFalse);

      // One described bed is enough to bring the section back, and every
      // bedroom still comes with it.
      final described = PropertyRooms.fromJson({
        'bedrooms': [
          {'index': 1, 'heading': 'Master Bedroom', 'beds': '1 King bed'},
          {'index': 2, 'heading': 'Bedroom 2'},
        ],
        'bathrooms': [{'index': 1, 'heading': 'Bathroom 1'}],
        'hasDetail': true,
      });
      expect(described.hasDetail, isTrue);
      expect(described.bedrooms.length, 2);

      expect(PropertyRooms.fromJson({'bedrooms': [], 'bathrooms': []}).hasDetail, isFalse);
    });

    test('every bedroom is rendered, described or not', () {
      final tabs = codeOnly(File('lib/ui/screens_renter/property_details/components/property_tabs.dart').readAsStringSync());
      expect(tabs, contains('for (final r in rooms.bedrooms) card(r, Icons.bed_outlined),'));
      expect(tabs, isNot(contains("if (r.beds.isNotEmpty || (r.bathroom ?? '').isNotEmpty)\n            card(r, Icons.bed_outlined)")));
    });
  });
}
