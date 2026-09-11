import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/models/host_booking_history_model.dart';
import 'package:rent_home/utils/booking_status.dart';

/// A deposit stay is paid and still owing — the host's badge says so.
///
/// B736755 (2026-09-11): the host's card read "₹7,518 · Paid" on a stay
/// that had received ₹752, with ₹6,766 owed before the guest could be
/// checked in; after the guest cancelled and was refunded, the card went
/// on saying "Paid".
void main() {
  test('a deposit stay is not "Paid"', () {
    final b = paymentBadge(
      isPaid: true,
      isCod: false,
      payMode: 'deposit',
      total: 7518,
      amountPaid: 751.8,
    );
    expect(b.label, 'Deposit paid · ₹6,766 due',
        reason: 'the host is told the money is in when a tenth of it is');
  });

  test('a settled deposit is Paid; a refund says so', () {
    expect(
        paymentBadge(
                isPaid: true,
                isCod: false,
                payMode: 'deposit',
                total: 7518,
                amountPaid: 7518)
            .label,
        'Paid');
    expect(
        paymentBadge(
                isPaid: true,
                isCod: false,
                refundAmount: 751.8,
                refundStatus: 'COMPLETED')
            .label,
        'Refunded ₹752');
    expect(
        paymentBadge(
                isPaid: true,
                isCod: false,
                refundAmount: 6825,
                refundStatus: 'PENDING')
            .label,
        'Refund of ₹6,825 pending');
  });

  test('a caller with only the two booleans keeps the old answers', () {
    expect(paymentBadge(isPaid: true, isCod: false).label, 'Paid');
    expect(paymentBadge(isPaid: false, isCod: true).label, 'Pay at property');
    expect(paymentBadge(isPaid: false, isCod: false).label, 'Payment pending');
  });

  test('the host booking row carries what was paid and refunded', () {
    final b = HostBookingHistory.fromJson({
      'book_id': 'B736755',
      'book_price': '7160.00',
      'book_total_amt': '7518.00',
      'book_is_paid': 1,
      'book_is_cod': 0,
      'book_pay_mode': 'deposit',
      'book_amount_paid': '751.80',
      'book_refund_amount': '751.80',
      'book_refund_status': 'COMPLETED',
      'book_no_of_pets': 1,
      'bookingStatus.bs_title': 'Cancelled',
    });
    expect(b.bookPayMode, 'deposit');
    expect(b.bookAmountPaid, 751.8);
    expect(b.bookRefundAmount, 751.8);
    expect(b.bookRefundStatus, 'COMPLETED');
    expect(b.bookNoOfPets, 1);
  });
}
