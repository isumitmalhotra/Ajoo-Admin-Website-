import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/utils/booking_status.dart';

/// What a booking's badge is allowed to claim.
///
/// `tbl_book_statuses` mixes two unrelated axes in one column — where the
/// booking is in its life, and where the money is — and the dates add a third
/// thing neither column knows. Getting the precedence wrong makes the badge
/// assert something that is not true, which is worse than saying nothing.
///
/// The case that prompted these: B794077 on production, status 5 "Booked",
/// never approved by the host, its stay window open. It was badged
/// "Staying now" on the very row that offered a Confirm button.
void main() {
  group('approval outranks the date window', () {
    test('an unapproved booking whose dates started is awaiting approval', () {
      expect(
        lifecycleLabel('Booked', started: true),
        'Awaiting approval',
        reason: 'the host has not approved it — the dates cannot say a guest is in',
      );
    });

    test('an approved booking whose dates started IS staying now', () {
      expect(lifecycleLabel('Booking Confirmed', started: true), 'Staying now');
    });

    test('a recorded check-in beats everything below it', () {
      // The host said the guest arrived. That is a fact, not an inference.
      expect(lifecycleLabel('Check In', started: true), 'Staying now');
    });

    test('an unapproved booking with no dates yet still reads awaiting', () {
      expect(lifecycleLabel('Booked'), 'Awaiting approval');
    });

    test('"Booking Confirmed" is not mistaken for "Booked"', () {
      // Both contain "book"; only one means the host agreed.
      expect(lifecycleLabel('Booking Confirmed'), 'Confirmed');
    });
  });

  group('the states that must always win', () {
    test('cancelled beats a started window', () {
      expect(lifecycleLabel('Cancelled', started: true), 'Cancelled');
    });

    test('a finished stay is completed, not staying now', () {
      expect(lifecycleLabel('Booked', started: true, ended: true), 'Completed');
    });

    test('a no-show is a no-show', () {
      expect(lifecycleLabel('No Show', started: true), 'No show');
    });

    test('declined is declined', () {
      expect(lifecycleLabel('Rejected', started: true), 'Declined');
    });
  });

  group('payment words are not lifecycle words', () {
    test('an unpaid ONLINE booking is not confirmed of anything', () {
      expect(
        lifecycleLabel('Payment Pending', isPaid: false, isCod: false),
        'Payment pending',
      );
    });

    test('an unpaid pay-at-property booking keeps its lifecycle status', () {
      // Unpaid is its normal state, so it must not be demoted for it.
      expect(
        lifecycleLabel('Booking Confirmed', isPaid: false, isCod: true),
        'Confirmed',
      );
    });

    test('"Paid" describes money, so the booking reads as confirmed', () {
      expect(lifecycleLabel('Paid'), 'Confirmed');
    });
  });

  /// A PAID booking still sitting at Payment Pending is waiting on its HOST.
  ///
  /// The web helper gained this branch on 2026-10-06; this one had only the
  /// UNPAID case, so a guest who had paid fell through to the payment-title
  /// fold and was told "Confirmed" for a stay no host had accepted. Found in
  /// the emulator pass of 2026-10-07 by auditing the callers of this function
  /// the same way the web ones were audited.
  group('a paid booking awaiting its host', () {
    test('reads "Awaiting approval", not "Confirmed"', () {
      expect(lifecycleLabel('Payment Pending', isPaid: true), 'Awaiting approval');
      expect(lifecycleLabel('payment pending', isPaid: true, isCod: false),
          'Awaiting approval');
    });

    test('an UNPAID one is still "Payment pending"', () {
      expect(lifecycleLabel('Payment Pending', isPaid: false, isCod: false),
          'Payment pending');
    });

    test('pay-at-property keeps its own meaning', () {
      // Unpaid is the normal state of a cash booking, so it must not be
      // demoted to "Payment pending".
      expect(lifecycleLabel('Payment Pending', isPaid: false, isCod: true),
          'Confirmed');
    });

    test('without the flag nothing changes for anyone else', () {
      // Callers that genuinely have no payment facts keep the old answer
      // rather than being told something the data does not support.
      expect(lifecycleLabel('Payment Pending'), 'Confirmed');
      expect(lifecycleLabel('Booking Confirmed', isPaid: true), 'Confirmed');
      expect(lifecycleLabel('Cancelled', isPaid: true), 'Cancelled');
    });
  });
}
