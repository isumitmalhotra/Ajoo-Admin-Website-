// Two questions, two answers.
//
// `tbl_book_statuses` mixes two unrelated axes in one column: where the booking
// is in its life ("Booking Confirmed", "Cancelled", "Check In") and whether it
// has been paid for ("Paid", "Payment Pending", "Payment Received"). Rendering
// that column as a single chip produced a list where one card said "Booking
// Confirmed" and the next said "Paid" — the host could not tell whether the
// first was unpaid or the second unconfirmed, because the two cards were
// answering different questions.
//
// This is the Dart twin of web `src/redesign/lib/bookingStatus.ts`; keep the
// wording in step so a host reading the app and the site sees one story.
import 'package:flutter/material.dart';

import '../constants.dart';

/// Payment-flavoured titles are not lifecycle states — they mean "confirmed".
const _paymentTitles = <String>[
  'paid',
  'payment pending',
  'payment received',
  'pending',
  'unpaid',
];

/// The life of the booking, with payment wording stripped out.
///
/// [ended] / [started] let the caller fold in what only the dates know: the
/// backend never writes a "completed" status, so a stay that checked out still
/// carries whatever status it was created with.
String lifecycleLabel(
  String? raw, {
  bool ended = false,
  bool started = false,
  /// Payment facts, when the caller has them. Without these the online
  /// never-paid case cannot be told apart from a real booking.
  bool? isPaid,
  bool? isCod,
}) {
  final s = (raw ?? '').trim().toLowerCase();
  if (s.contains('cancel')) return 'Cancelled';
  if (s.contains('reject') || s.contains('declin')) return 'Declined';
  if (s.contains('no show') || s.contains('no-show')) return 'No show';
  if (ended) return 'Completed';
  if (s.contains('check out') || s.contains('check-out')) return 'Completed';
  if (s.contains('check in') || s.contains('check-in')) return 'Staying now';
  if (started) return 'Staying now';
  if (s.contains('complet')) return 'Completed';
  if (s.contains('suspend')) return 'Suspended';
  if (s.contains('fail')) return 'Failed';
  // An ONLINE booking whose payment never completed is not confirmed of
  // anything — no money was taken and no host agreed to it. Pay-at-property
  // is the deliberate exception: unpaid is its normal state.
  if (isPaid != null &&
      isPaid == false &&
      isCod != true &&
      s.contains('payment pending')) {
    return 'Payment pending';
  }
  // "Paid" / "Payment Pending" only ever described the money. A booking that
  // exists and is not cancelled is confirmed, whatever its payment says.
  if (s.isEmpty || _paymentTitles.contains(s)) return 'Confirmed';
  // 'Booking Confirmed' is the HOST's approval, and must be checked before the
  // bare 'Booked' below — which is the state a request waits in FOR that
  // approval. These were fused in one `||`, so a booking the host still had to
  // approve reported itself as Confirmed on both sides of the app.
  if (s.contains('confirm')) return 'Confirmed';
  if (s.contains('book')) return 'Awaiting approval';
  return raw!.trim();
}

/// Background + foreground for a lifecycle chip.
(Color, Color) lifecycleColors(String label) {
  final s = label.toLowerCase();
  if (s.contains('cancel') ||
      s.contains('declin') ||
      s.contains('fail') ||
      s.contains('no show')) {
    return (const Color(0xFFFDECEC), kDanger);
  }
  if (s.contains('complet')) return (const Color(0xFFEFF3F8), kInk2);
  if (s.contains('staying')) return (const Color(0xFFEAF6EE), kSuccess);
  if (s.contains('suspend')) return (const Color(0xFFFFF6E5), kClay);
  // Anything still waiting on somebody — the host's approval, or a payment
  // that never landed — reads as amber, not as a settled green.
  if (s.contains('awaiting') || s.contains('payment pending')) {
    return (const Color(0xFFFFF6E5), kClay);
  }
  return (const Color(0xFFFFF1E6), kClay);
}

/// The money, on its own terms.
///
/// A pay-at-property booking that has not been settled is not "pending" in the
/// failed-checkout sense — it is due on arrival, which is a different thing to
/// tell a host, so it gets its own wording.
class PaymentBadge {
  const PaymentBadge(this.label, this.bg, this.fg);
  final String label;
  final Color bg;
  final Color fg;
}

PaymentBadge paymentBadge({required bool isPaid, required bool isCod}) {
  if (isPaid) return const PaymentBadge('Paid', Color(0xFFEAF6EE), kSuccess);
  if (isCod) {
    return const PaymentBadge('Pay at property', Color(0xFFFFF6E5), kClay);
  }
  return const PaymentBadge('Payment pending', Color(0xFFFFF6E5), kClay);
}
