// The server can refuse a verified FIRST payment on purpose: another guest
// took the nights while the Razorpay session was open, the booking is
// cancelled and the money is on its way back (backend nightsTakenByAnother,
// BK-051, 2026-09-21). The app's success handler used to await verify with
// no catch at all — a 400 threw out of an async void and the guest saw
// nothing; the fallback would have said "we couldn't confirm your payment",
// which is also wrong. Now the service raises DatesTakenDuringPayment and the
// page says what happened.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/service/booking_service.dart';

String codeOnly(String src) => src
    .replaceAll('\r\n', '\n')
    .split('\n')
    .where((l) => !l.trimLeft().startsWith('//') && !l.trimLeft().startsWith('///'))
    .join('\n');

void main() {
  group('a refunded payment is not a stay', () {
    test('the exception carries the server\'s sentence and the amount', () {
      const e = DatesTakenDuringPayment(message: 'Those dates were taken.', refundAmount: 6615);
      expect(e.toString(), 'Those dates were taken.');
      expect(e.refundAmount, 6615);
    });

    test('the service raises it from the server\'s datesTaken flag, and only then', () {
      final svc = codeOnly(File('lib/service/booking_service.dart').readAsStringSync());
      final verify = svc.substring(svc.indexOf('Future<bool> verifyPayment('), svc.indexOf('Future<CancellationQuote?> cancellationQuote('));
      expect(verify, contains("if (data is Map && data['datesTaken'] == true) {"));
      expect(verify, contains('throw DatesTakenDuringPayment('));
      expect(verify, contains('if (e is DatesTakenDuringPayment) rethrow;'));
    });

    test('the property page catches it and says what happened, not "we couldn\'t confirm"', () {
      final page = codeOnly(File('lib/ui/screens_renter/property_details/property_page.dart').readAsStringSync());
      final handler = page.substring(page.indexOf('void _handlePaymentSuccess('), page.indexOf('void _handlePaymentError('));
      expect(handler, contains('} on DatesTakenDuringPayment catch (e) {'));
      expect(handler, contains("title: 'Those dates were taken while you paid',"));
      expect(handler, contains('reason: e.message,'));
      // ...and a plain failure still has its own, honest sentence.
      expect(handler, contains('title: "We couldn\'t confirm your payment",'));
      expect(handler.indexOf('on DatesTakenDuringPayment'), lessThan(handler.indexOf('} catch (_) {')));
    });
  });
}
