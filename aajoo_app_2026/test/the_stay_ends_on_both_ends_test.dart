// The stay ends on both ends (app). Client, 2026-09-19: "check out process
// is still missing — both the ends." The host had no check-out anywhere;
// the guest's "Checkout" button only opened the review page, so a guest who
// skipped the review never checked out.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String codeOnly(String src) => src
    .replaceAll('\r\n', '\n')
    .split('\n')
    .where((l) => !l.trimLeft().startsWith('//') && !l.trimLeft().startsWith('///'))
    .join('\n');

void main() {
  final hostService = codeOnly(File('lib/service/host_service.dart').readAsStringSync());
  final hostDetail = codeOnly(File('lib/ui/screens_host/booking_history/host_booking_detail_page.dart').readAsStringSync());
  final bookingService = codeOnly(File('lib/service/booking_service.dart').readAsStringSync());
  final ongoing = codeOnly(File('lib/ui/screens_renter/home/view_ongoing_booking.dart').readAsStringSync());

  group('the host end', () {
    test('talks to the check-out endpoint the server now has', () {
      expect(hostService, contains('.post("/host/booking/check-out", data: {"bookingId": bookingId})'));
      expect(hostService, contains('Future<void> markBookingCheckOut(String bookingId) async {'));
    });

    test('offers Check-out once the guest is in, and only then', () {
      expect(hostDetail, contains('bool get _canCheckOut => _isCheckedIn && !_isCheckedOut && !_isCancelled;'));
      expect(hostDetail, contains("'Mark guest as checked-out'"));
      final button = hostDetail.indexOf('if (_canCheckOut) ...[');
      expect(button, greaterThan(-1));
      expect(hostDetail.substring(button, button + 900), contains('onPressed: _checkingOut ? null : _markCheckedOut'));
    });

    test('the page tells the truth without a refetch, and says what the guest was told', () {
      expect(hostDetail, contains("setState(() => b.bookingStatusBsTitle = 'Check Out');"));
      expect(hostDetail, contains("asked to leave a review"));
    });
  });

  group('the guest end', () {
    test('has its own check-out call that returns the server data', () {
      expect(bookingService, contains('final url = "\$baseUrl/user/booking/check-out";'));
      expect(bookingService, contains('Future<Map<String, dynamic>> checkOutBooking(String bookingId) async {'));
    });

    test('ends the stay BEFORE opening the review, and stops if the server refuses', () {
      final call = ongoing.indexOf('await BookingService()');
      final review = ongoing.indexOf('Get.to(() => HotelCheckoutPage(');
      expect(call, greaterThan(-1));
      expect(review, greaterThan(call), reason: 'the check-out call must come before the review page');
      final between = ongoing.substring(call, review);
      expect(between, contains('return;'), reason: 'a refused check-out must not open the review');
      expect(ongoing, contains("onPressed: () async {"));
    });
  });
}
