// The app's share of the client's 18 September batch — the same five the
// website got, where the app had the same fault:
//
//   "same-day check-in and check-out should be blocked while selecting dates"
//   "guest count 0 goes through and becomes 2"          (the app never allowed 0)
//   "exact location should show according to the host's setting"
//   "Indian map is still incorrect"                     (the app is Google-only)
//   "check the Book Now in mobile view"                 (the app has one button)
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/models/ongoing_reponse.dart';
import 'package:rent_home/models/single_property_response.dart';

String codeOnly(String src) => src
    .replaceAll('\r\n', '\n')
    .split('\n')
    .where((l) => !l.trimLeft().startsWith('//') && !l.trimLeft().startsWith('///'))
    .join('\n');

void main() {
  final page = codeOnly(File('lib/ui/screens_renter/property_details/property_page.dart').readAsStringSync());
  final tabs = codeOnly(File('lib/ui/screens_renter/property_details/components/property_tabs.dart').readAsStringSync());
  final confirmed = codeOnly(File('lib/ui/screens_renter/property_details/components/booking_confirmed_screen.dart').readAsStringSync());
  final ongoing = codeOnly(File('lib/ui/screens_renter/home/view_ongoing_booking.dart').readAsStringSync());

  group('same-day stay', () {
    test('the check-in day is never offered as a check-out', () {
      expect(page, contains('firstDate: selectedDate.add(const Duration(days: 1)),'),
          reason: 'the check-out picker still opens on the check-in day');
      final i = page.indexOf('bool _checkoutAllowed(DateTime from, DateTime d) {');
      expect(i, greaterThan(-1));
      expect(page.substring(i, i + 400), contains('.isAfter(DateTime(from.year, from.month, from.day))) return false;'),
          reason: 'the predicate must grey the check-in day itself, not rely on the silent bump after the tap');
    });
  });

  group('guest count', () {
    test('the stepper cannot reach zero', () {
      expect(page, contains('int _guests = 1;'));
      expect(page, contains('onPressed: _guests > 1'), reason: 'the minus button must stop at one');
    });
  });

  group("the host's exact-location setting", () {
    test('the listing model reads it, and absent means hidden', () {
      final shown = SinglePropertyData.fromJson(<String, dynamic>{
        'property_id': 1, 'location_is_approximate': false,
      });
      final hidden = SinglePropertyData.fromJson(<String, dynamic>{
        'property_id': 1, 'location_is_approximate': true,
      });
      final absent = SinglePropertyData.fromJson(<String, dynamic>{'property_id': 1});
      expect(shown.showsExactLocation, isTrue);
      expect(hidden.showsExactLocation, isFalse);
      expect(absent.showsExactLocation, isFalse);
    });

    test('the listing page draws a pin when the host shows it, a circle and the caption when not', () {
      expect(tabs, contains('PropertyAreaMap(lat: lat, lng: lng, exact: _s?.showsExactLocation ?? false),'));
      expect(tabs, contains("? {Marker(markerId: const MarkerId('stay'), position: at)}"));
      expect(tabs, contains('if (!exact)\n            Positioned('),
          reason: '"Exact location shared after booking" must not caption a pin the host chose to show');
    });

    test('the confirmed screen has two keys: the host answered, or the host shows it anyway', () {
      expect(confirmed, contains('final bool hostShowsExactLocation;'));
      expect(confirmed, contains('bool get _locationLocked => _awaiting && !widget.hostShowsExactLocation;'));
      expect(confirmed, contains('] else if (_locationLocked) ...['),
          reason: 'the map is still gated on the decision alone');
      expect(page, contains('hostShowsExactLocation: _single?.showsExactLocation ?? false,'),
          reason: 'the property page does not pass the setting through');
    });

    test('the ongoing-booking row carries the server flag, closed by default', () {
      final b = Booking.fromJson(<String, dynamic>{
        'book_pri_id': 1, 'book_id': 'B1', 'book_invoice': 'I1', 'book_price': 100,
        'book_is_paid': 1, 'book_is_cod': 0, 'book_status': 4,
        'hostShowsExactLocation': true,
      });
      expect(b.hostShowsExactLocation, isTrue);
      final older = Booking.fromJson(<String, dynamic>{
        'book_pri_id': 1, 'book_id': 'B1', 'book_invoice': 'I1', 'book_price': 100,
        'book_is_paid': 1, 'book_is_cod': 0, 'book_status': 4,
      });
      expect(older.hostShowsExactLocation, isFalse, reason: 'an older server must not open the pin');
    });

    test('the ongoing-booking screen holds the pin on an unanswered request the host keeps back', () {
      expect(ongoing, contains("lifecycleLabel(widget.booking.bookingStatusBsTitle) ==\n                                  'Awaiting approval' &&\n                              !widget.booking.hostShowsExactLocation)"));
      expect(ongoing, contains('The exact address and directions appear once the host accepts your request.'));
    });
  });

  group('maps', () {
    test('the app draws maps through Google only — no OpenStreetMap tiles anywhere', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('google_maps_flutter'));
      expect(pubspec, isNot(contains('flutter_map')));
      final hits = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => f.readAsStringSync().contains('openstreetmap'))
          .map((f) => f.path)
          .toList();
      expect(hits, isEmpty, reason: 'OSM tiles draw India the way Indian law does not allow');
    });
  });
}
