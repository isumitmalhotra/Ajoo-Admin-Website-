import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/models/transaction_model.dart';

/// The Invoices screen says what the guest paid.
///
/// Found 2026-09-11 with Booking #B205678 open beside it: the booking card
/// said ₹5,250, the invoice card said ₹5,000. `pay_amount` is the pre-tax
/// subtotal (host earnings are credited from it); the guest paid the tax,
/// and an invoice is the one thing a host forwards to a guest. The server
/// now sends the booking's total beside it; this is the model reading it,
/// with the fallbacks an older server or a payment whose booking is gone
/// would need.
void main() {
  Map<String, dynamic> row([Map<String, dynamic> over = const {}]) => {
        'pay_id': 9,
        'pay_invoice': 'Inv_205678',
        'pay_raz_id': 'pay_x',
        'pay_bookId': 'B205678',
        'pay_amount': '5000.00',
        'pay_gateway_amount': '5250.00',
        'pay_total_amount': 5250,
        'pay_tax_amount': 250,
        'pay_base_amount': 5000,
        'pay_status_text': 'Paid & Verified',
        'pay_addedAt': '2026-09-10T18:33:27.000Z',
        'userPayment.user_fullName': 'Aajoo Renter',
        'paymentProperty.property_name': 'Aajoo Homes',
        'paymentStatus.bs_title': 'Paid',
        'paymentStatus.bs_code': 3,
        ...over,
      };

  test('the card shows the tax-inclusive total, not the subtotal', () {
    final t = Transaction.fromJson(row());
    expect(t.chargedAmount, 5250,
        reason: 'the invoice reads the pre-tax subtotal beside a booking '
            'card that reads the total');
    expect(t.taxAmount, 250);
    expect(t.payBookId, 'B205678');
  });

  test('an older server: the gateway amount is what was charged', () {
    final t = Transaction.fromJson(row({
      'pay_total_amount': null,
      'pay_tax_amount': null,
      'pay_base_amount': null,
    }));
    expect(t.chargedAmount, 5250);
    expect(t.taxAmount, 0);
  });

  test('a row from before either column existed: the subtotal is all there is',
      () {
    final t = Transaction.fromJson(row({
      'pay_gateway_amount': null,
      'pay_total_amount': null,
      'pay_tax_amount': null,
      'pay_base_amount': null,
      'pay_amount': '2362.50',
    }));
    expect(t.chargedAmount, 2362.5);
  });

  test('a null name or property does not crash the whole list', () {
    // Every field was a bare cast; one null guest took every invoice down.
    final t = Transaction.fromJson(row({
      'userPayment.user_fullName': null,
      'paymentProperty.property_name': null,
    }));
    expect(t.userPaymentUserFullName, 'Guest');
    expect(t.paymentPropertyPropertyName, '');
  });

  test('what a payment brought in is its own figure, not the stay total', () {
    // A deposit stay has two rows that both carry the stay's total as
    // pay_total_amount. Summing chargedAmount counted ₹2,100 twice on the
    // dashboard; receivedAmount is the gateway's figure for THIS row.
    final deposit = Transaction.fromJson(row({
      'pay_amount': '200.00',
      'pay_gateway_amount': '210.00',
      'pay_total_amount': 2100,
    }));
    final balance = Transaction.fromJson(row({
      'pay_amount': '1800.00',
      'pay_gateway_amount': '1890.00',
      'pay_total_amount': 2100,
    }));
    expect(deposit.receivedAmount + balance.receivedAmount, 2100);
    expect(deposit.chargedAmount, 2100, reason: 'the invoice still reads the stay total');
    expect(deposit.isRefunded, isFalse);
    final back = Transaction.fromJson(row({'pay_status_text': 'Refunded'}));
    expect(back.isRefunded, isTrue);
    final part = Transaction.fromJson(row({'pay_status_text': 'Partly refunded ₹1050.00'}));
    expect(part.isRefunded, isTrue);
  });
}
