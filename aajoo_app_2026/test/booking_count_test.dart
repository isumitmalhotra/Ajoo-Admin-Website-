import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/service/host_service.dart';

/// The dashboard's booking count, across every shape the endpoint can answer
/// with.
///
/// The tile used to take `.length` of the whole booking history — 17,735 bytes
/// for a host with 30 bookings, fetched on every dashboard visit to render one
/// integer. It asks for a count now, and this is what proves the count survives
/// the round trip: a wrong parse here shows a confident "0" and looks exactly
/// like a host with no bookings.
void main() {
  test('reads totalcount from a paged response', () {
    final body = {
      'success': true,
      'data': {'rows': [{}], 'totalcount': 30, 'page': 1, 'limit': 1, 'totalPages': 30},
    };
    expect(HostService.parseBookingCount(body), 30);
  });

  test('a count sent as a string still parses', () {
    // MySQL drivers have handed us "5.00" for a DECIMAL before, and
    // int.tryParse returns null on that — a five-star review drew five empty
    // stars for exactly this reason.
    expect(HostService.parseBookingCount({'data': {'totalcount': '30'}}), 30);
    expect(HostService.parseBookingCount({'data': {'totalcount': '30.00'}}), 30);
  });

  test('falls back to the list length on a backend that ignores paging', () {
    final body = {'data': List.generate(12, (i) => {'book_id': 'B$i'})};
    expect(HostService.parseBookingCount(body), 12);
  });

  test('an empty history is zero, not a crash', () {
    expect(HostService.parseBookingCount({'data': []}), 0);
    expect(HostService.parseBookingCount({'data': {'rows': [], 'totalcount': 0}}), 0);
  });

  test('a shape we do not recognise is zero, not an exception', () {
    expect(HostService.parseBookingCount(null), 0);
    expect(HostService.parseBookingCount('nonsense'), 0);
    expect(HostService.parseBookingCount({'data': {'nope': 1}}), 0);
  });
}
