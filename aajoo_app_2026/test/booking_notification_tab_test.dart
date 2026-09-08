import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/ui/screens_renter/history/history_page.dart';
import 'package:rent_home/utils/notification_link.dart';

/// A notification outlives the stay it is about.
///
/// Build 51, renter 101: tapping "Booking Successfull, Your Booking id is
/// B719836" opened My Bookings on Upcoming, which said "No upcoming bookings".
/// The stay was real and one tab away, under Completed — its dates (7–8 Sep)
/// had passed. Nothing on screen said so.
///
/// These tests pin the two halves of that: the destination still asks for
/// Upcoming, because that is right at the moment the notification is sent, and
/// the booking's own dates still say Completed. The screen reconciles them by
/// following the booking, so a change to either half that silently made them
/// agree — or that dropped the highlight — would fail here.
void main() {
  String d(DateTime t) =>
      '${t.day.toString().padLeft(2, '0')}-${t.month.toString().padLeft(2, '0')}-${t.year}';

  final now = DateTime.now();
  final endedFrom = d(now.subtract(const Duration(days: 3)));
  final endedTo = d(now.subtract(const Duration(days: 2)));
  final futureFrom = d(now.add(const Duration(days: 10)));
  final futureTo = d(now.add(const Duration(days: 12)));

  group('a booking notification and the booking can disagree', () {
    test('the notification asks for Upcoming and carries the stay', () {
      final dest = notificationDestination(
        title: 'Booking Successfull',
        message: 'Booking Successfull, Your Booking id is B719836',
        isHost: false,
        bookingId: 'B719836',
      );
      expect(dest.route, '/history');
      expect(dest.arguments['tab'], 'Upcoming');
      expect(dest.arguments['highlight'], 'B719836');
    });

    test('a stay whose dates have passed is Completed, not Upcoming', () {
      expect(bookingTabIndex('Booked', from: endedFrom, to: endedTo), 2);
    });

    test('a stay still to come is Upcoming', () {
      expect(bookingTabIndex('Booked', from: futureFrom, to: futureTo), 0);
    });

    test('a cancelled stay is Cancelled whatever its dates say', () {
      expect(bookingTabIndex('Cancelled', from: futureFrom, to: futureTo), 3);
    });
  });

  test('a cancellation notification asks for the Cancelled tab', () {
    final dest = notificationDestination(
      title: 'Your booking is cancelled',
      isHost: false,
      bookingId: 'B780678',
    );
    expect(dest.arguments['tab'], 'Cancelled');
    expect(dest.arguments['highlight'], 'B780678');
  });
}
