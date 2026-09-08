import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/utils/notification_link.dart';

/// Every row in the host feed has somewhere to go.
///
/// The host list routed on ntf_link_path alone and returned early when it was
/// empty. But the feed is merged from two tables, and hostSearch only
/// synthesises a path for a guest-table row that names a property
/// (`un_propId ? '/property?id=…' : null`). Support replies, payout notices
/// and messages carry no property, so they arrived with a null path and went
/// nowhere — while still marking themselves read and dropping the badge, which
/// is the worst combination: the sign that something happened disappears and
/// you never find out what.
///
/// Seen on host 100, build 52, tapping "Support replied to your ticket".
///
/// The fallback is the same classifier the guest list and the push router use,
/// so one row cannot mean two different things on two screens.
void main() {
  group('a host row with no link path still knows where it belongs', () {
    test('a support reply is support, not unknown', () {
      expect(
        notificationKind(
          title: 'Support replied to your ticket',
          message: '"QA checklist ticket" — open Support to read the reply.',
        ),
        NotifKind.support,
      );
    });

    test('a payout notice is payment', () {
      expect(
        notificationKind(
          title: 'Payment received',
          message: 'Payment for Inv_703473 was received.',
        ),
        NotifKind.payment,
      );
    });

    test('a price offer is an offer, not a booking', () {
      expect(
        notificationKind(
          title: 'New price offer',
          message: 'A guest offered 1,600/night for Aajoo Homes.',
        ),
        NotifKind.offer,
      );
    });

    test('a booking request is a booking', () {
      expect(
        notificationKind(
          title: 'A booking is waiting for your approval',
          message: 'Booking B703473 needs your approval.',
        ),
        NotifKind.booking,
      );
    });

    test('a guest message is a conversation', () {
      expect(
        notificationKind(
          title: 'New message from Aajoo Renter',
          message: "Hi! I'd like to ask about my stay.",
        ),
        NotifKind.message,
      );
    });
  });

  /// The one row that DID route was the host-table copy, whose ntf_link_path
  /// is a real website path. That path must keep working — the fallback is an
  /// addition, not a replacement.
  test('the host bookings tab has one agreed number', () {
    expect(kHostBookingsTab, 3);
  });
}
