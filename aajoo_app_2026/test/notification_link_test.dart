import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/utils/notification_link.dart';

void main() {
  group('notificationKind', () {
    test('wording wins over a wrong stored type — the live example', () {
      // A real row: title "Your Property has been Booked", body "Booking
      // Successfull", payload type "negotiation_request". Trusting the type
      // sent the host to Negotiations for a booking.
      expect(
        notificationKind(
          title: 'Your Property has been Booked',
          message: 'Booking Successfull',
          payloadType: 'negotiation_request',
        ),
        NotifKind.booking,
      );
    });

    test('falls back to the stored type when the wording says nothing', () {
      expect(
        notificationKind(title: 'Update', message: '', payloadType: 'payment_update'),
        NotifKind.payment,
      );
    });

    test('a cancelled booking is a cancellation, not a booking', () {
      expect(
        notificationKind(title: 'Booking cancelled', message: 'Your stay was cancelled'),
        NotifKind.cancellation,
      );
    });

    test('an accepted offer is an offer, not a booking', () {
      expect(
        notificationKind(
          title: 'Offer accepted',
          message: 'Book within 24 hours to keep this price',
        ),
        NotifKind.offer,
      );
    });

    test('unrecognisable wording and no type is unknown', () {
      expect(notificationKind(title: 'Hello there'), NotifKind.unknown);
    });
  });

  group('notificationDestination', () {
    test('a cancellation opens the cancelled tab for either side', () {
      for (final isHost in [true, false]) {
        final d = notificationDestination(
          title: 'Booking cancelled',
          isHost: isHost,
        );
        expect(d.route, '/history');
        expect(d.arguments['tab'], 'Cancelled');
      }
    });

    test('a chat notification opens that conversation when we know the property', () {
      final d = notificationDestination(
        title: 'New message from Aarav',
        isHost: true,
        propertyId: '12',
      );
      expect(d.route, '/negotiation');
      expect(d.arguments['propertyId'], '12');
    });

    test('a chat notification without a property goes home, not to a dead route', () {
      final d = notificationDestination(title: 'New message', isHost: false);
      expect(d.route, '/home');
    });

    test('a stored route from the web layout is ignored', () {
      // "/messages" is a real page on the web and no route at all here.
      final d = notificationDestination(
        title: 'Something happened',
        payloadRoute: '/messages',
        isHost: false,
      );
      expect(d.route, '/home');
    });

    test('a stored route this app really has is honoured', () {
      final d = notificationDestination(
        title: 'Something happened',
        payloadRoute: '/support',
        isHost: false,
      );
      expect(d.route, '/support');
    });

    test('a security notice opens settings', () {
      expect(
        notificationDestination(title: 'Your password was changed', isHost: false).route,
        '/settings',
      );
    });

    test('a payout notice sends the host home, a refund sends the guest to history', () {
      expect(
        notificationDestination(title: 'Payout processed', isHost: true).route,
        '/host/home',
      );
      final guest = notificationDestination(title: 'Refund issued', isHost: false);
      expect(guest.route, '/history');
      expect(guest.arguments['tab'], 'Completed');
    });
  });
}
