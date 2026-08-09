// Where a notification should take you when you tap it — the Dart counterpart
// of the web's redesign/lib/notificationLink.ts, so both platforms read the
// same notification the same way.
//
// What was wrong here: the notifications screen navigated only for negotiation
// rows that carried a propertyId. Every other row just marked itself read and
// went nowhere — the same dead end the web fixed. Push taps were worse: the
// router returned early unless the payload carried BOTH `route` and `type`
// (most payloads carry neither), decided purely on `type`, and otherwise handed
// the stored path straight to Get.toNamed. Those stored paths come from the
// web's layout — "/messages", "/bookings", "/negotitation" — and none of them
// are routes in this app, so following one lands on the unknown-route page.
//
// Two rules carried over from the web:
//   1. Wording decides, `payload.type` is only a fallback. The stored types are
//      copy-pasted between flows and demonstrably wrong: a live row titled
//      "Your Property has been Booked" carries type "negotiation_request".
//   2. A route from the payload is honoured only if this app really has it.
//
// Destinations differ by role, because one row is read from two sides: a
// cancellation means "your stay is off" to a guest and "that date is free
// again" to the host.

/// What a notification is about.
enum NotifKind {
  message,
  offer,
  cancellation,
  booking,
  payment,
  listing,
  review,
  account,
  unknown,
}

/// Routes actually registered in main.dart. A payload route outside this set is
/// from an older layout and is ignored rather than followed into a blank page.
const Set<String> kKnownRoutes = {
  '/', '/onboarding', '/forgot-password', '/profile', '/login', '/home',
  '/host/home', '/verify', '/kyc', '/support', '/settings', '/history', '/faq',
  '/bookmarkProperties', '/negotiation', '/location-picker', '/notifications',
  '/webview',
};

/// Where a tap should land, and what the destination needs to know.
class NotifDestination {
  const NotifDestination(this.route, {this.arguments = const {}});

  final String route;
  final Map<String, dynamic> arguments;

  @override
  String toString() => arguments.isEmpty ? route : '$route $arguments';
}

NotifKind _classify(String text) {
  bool has(List<String> needles) => needles.any(text.contains);

  // Order matters: "Booking cancelled" is a cancellation, not a booking, and
  // "Offer accepted — book within 24 hours" is an offer, not a booking.
  if (has(['cancel', 'no_show', 'no-show'])) return NotifKind.cancellation;
  if (has(['chat', 'message'])) return NotifKind.message;
  if (has(['offer', 'negotiat', 'counter', 'coupon', 'deal'])) {
    return NotifKind.offer;
  }
  if (has(['refund', 'payment', 'payout', 'paid', 'invoice', 'transaction'])) {
    return NotifKind.payment;
  }
  if (has(['listing', 'property_approved', 'property_rejected', 'verification'])) {
    return NotifKind.listing;
  }
  if (has(['review', 'rating'])) return NotifKind.review;
  if (has(['password', 'kyc', 'security'])) return NotifKind.account;
  if (has(['book', 'stay', 'check-in', 'checkin', 'check-out'])) {
    return NotifKind.booking;
  }
  return NotifKind.unknown;
}

/// The kind of a notification, from its wording first and its stored type only
/// as a fallback.
NotifKind notificationKind({
  String? title,
  String? message,
  String? payloadType,
}) {
  final fromText =
      _classify('${title ?? ''} ${message ?? ''}'.toLowerCase());
  if (fromText != NotifKind.unknown) return fromText;
  return _classify((payloadType ?? '').toLowerCase());
}

/// An explicit payload route, but only when this app actually has it.
String? _explicitRoute(String? raw) {
  final value = (raw ?? '').trim();
  if (value.isEmpty) return null;
  final path = value.split('?').first;
  final normalised = path.startsWith('/') ? path : '/$path';
  return kKnownRoutes.contains(normalised) ? normalised : null;
}

/// Where tapping this notification should go, for the person reading it.
///
/// [propertyId] is what makes a conversation openable: this app has no message
/// inbox, only the per-property negotiation chat, so a chat notification can
/// only be opened when we know which property it belongs to. Without one the
/// reader is sent to their own home rather than to a route that does not exist.
NotifDestination notificationDestination({
  String? title,
  String? message,
  String? payloadType,
  String? payloadRoute,
  required bool isHost,
  String? propertyId,
}) {
  final home = isHost ? '/host/home' : '/home';
  final kind = notificationKind(
    title: title,
    message: message,
    payloadType: payloadType,
  );
  final hasProperty = (propertyId ?? '').trim().isNotEmpty;

  switch (kind) {
    case NotifKind.message:
    case NotifKind.offer:
      // The negotiation thread is the only conversation surface in this app.
      return hasProperty
          ? NotifDestination('/negotiation',
              arguments: {'propertyId': propertyId})
          : NotifDestination(home);

    case NotifKind.cancellation:
      return const NotifDestination('/history', arguments: {'tab': 'Cancelled'});

    case NotifKind.booking:
      return const NotifDestination('/history', arguments: {'tab': 'Upcoming'});

    case NotifKind.payment:
      // Guests find charges and refunds against the stay itself; a host's
      // earnings live behind their own home shell.
      return isHost
          ? NotifDestination(home)
          : const NotifDestination('/history', arguments: {'tab': 'Completed'});

    case NotifKind.listing:
    case NotifKind.review:
      return NotifDestination(home);

    case NotifKind.account:
      return const NotifDestination('/settings');

    case NotifKind.unknown:
      // Nothing recognisable — a real payload route if there is one, otherwise
      // home, which is at least somewhere the notification can be found again.
      return NotifDestination(_explicitRoute(payloadRoute) ?? home);
  }
}
