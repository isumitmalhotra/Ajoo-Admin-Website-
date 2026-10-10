// The ongoing-bookings response sends book_price as text — "3.00", a MySQL
// DECIMAL through Sequelize — and Booking.fromJson cast it with `as num?`,
// which threw. One bad field failed the whole parse, so a guest with two
// bookings saw none ("ONGOING - type 'String' is not a subtype of type
// 'num?'", renter 179, iOS Simulator, 2026-10-09; Android parses the same
// Dart). Every other DECIMAL in the model was already parsed with _money;
// book_price was the one left on a cast.
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/models/ongoing_reponse.dart';

Map<String, dynamic> _payload(Object price) => {
      'success': true,
      'message': 'success',
      'data': {
        'count': 1,
        'bookings': [
          {
            'book_pri_id': 8,
            'book_id': 'B871634',
            'book_invoice': 'Inv_871634',
            'book_price': price,
            'book_tax': '0.15',
            'book_status': 1,
          },
        ],
      },
    };

void main() {
  test('a price sent as text parses, and so does the rest of the response', () {
    final r = OnGoingBookingResponse.fromJson(_payload('3.00'));
    expect(r.data!.bookings, hasLength(1));
    expect(r.data!.bookings.first.bookPrice, 3);
    expect(r.data!.bookings.first.bookTax, closeTo(0.15, 1e-9));
  });

  test('a price sent as a number still parses', () {
    final r = OnGoingBookingResponse.fromJson(_payload(8399.9));
    expect(r.data!.bookings.first.bookPrice, 8400,
        reason: 'rounded, not truncated');
  });
}
