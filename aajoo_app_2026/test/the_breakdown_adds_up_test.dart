// A breakdown's lines must sum to its total.
//
// The server stores `book_price` NET of any deal or coupon (createBooking
// subtracts the discount before the row is written). Two screens passed it
// as the "Room charge" line and printed the discount on a line of its own,
// so B326241 (deal 11.58% on a ₹9,500 night) read
//   Room ₹8,400 − Discount ₹1,100 + Taxes ₹1,512 = ₹9,912
// which does not add up (300-case run, 2026-09-20). The listed room is
// price + discount; the tax is total − net price.
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/models/booking_history_response_model.dart';
import 'package:rent_home/models/ongoing_reponse.dart';

void main() {
  // B326241 as the server sent it.
  final row = <String, dynamic>{
    'book_pri_id': 141,
    'book_id': 'B326241',
    'book_invoice': 'Inv_326241',
    'book_price': 8399.90,
    'book_tax': 1511.98,
    'book_total_amt': 9911.88,
    'book_discount_amt': 1100.10,
    'book_is_paid': 0,
    'book_is_cod': 1,
    'book_status': 8,
    'book_added_at': '2026-09-20T15:15:00.000Z',
  };

  group('the ongoing booking', () {
    final b = Booking.fromJson(row);
    test('prints the LISTED room next to the discount, and the lines add up', () {
      expect(b.bookPrice, 8400, reason: 'book_price arrives net; rounded, not truncated');
      expect(b.roomListed, closeTo(9500, 0.15), reason: 'listed room = net + discount');
      expect(b.roomListed - b.bookDiscountAmt + b.taxesAndFees, closeTo(b.bookTotalAmt, 1.0));
    });
    test('the derived tax does not add the discount back twice', () {
      final noTax = Booking.fromJson({...row, 'book_tax': 0});
      expect(noTax.taxesAndFees, closeTo(9911.88 - 8400, 0.01), reason: 'tax is what is left after the NET room');
    });
  });

  group('the booking-history row', () {
    final h = BookingHistoryData.fromJson({
      ...row,
      'bookingProperty.property_name': 'Clamping suite for testing purpose',
      'bookingStatus.bs_title': 'Booking Confirmed',
    });
    test('its Room charge is the listed room, so the breakdown adds up', () {
      expect(h.roomCharge, closeTo(9500.0, 0.01));
      expect(h.roomCharge - (h.bookDiscountAmt ?? 0) + h.taxesAndFees, closeTo(9911.88, 0.01));
    });
  });
}
