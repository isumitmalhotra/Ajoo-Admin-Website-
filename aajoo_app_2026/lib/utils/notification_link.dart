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
  support,
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

/// The host portal's Bookings tab, in HostTabProvider's numbering (2 Dashboard,
/// 3 Bookings, 5 Profile, 6 Messages). Passed as `hostTab` so a notification
/// can open the portal on the tab it is about instead of its dashboard.
const int kHostBookingsTab = 3;

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
  // Support had no kind at all, so "Support replied to your ticket" — whose own
  // body says "open Support to read the reply" — fell through to unknown and
  // landed on the home screen. Found on the website, on a real account; the
  // same rule and the same gap live here.
  //
  // AFTER offer, deliberately, and in the order the server's category rule
  // uses: "the guest replied to your offer" is an offer, and `reply` would
  // otherwise capture it.
  if (has(['support', 'ticket', 'reply', 'replied', 'complaint'])) {
    return NotifKind.support;
  }
  if (has(['refund', 'payment', 'payout', 'paid', 'invoice', 'transaction'])) {
    return NotifKind.payment;
  }
  if (has(['listing', 'property_approved', 'property_rejected', 'verification'])) {
    return NotifKind.listing;
  }
  if (has(['review', 'rating'])) return NotifKind.review;
  if (has(['password', 'kyc', 'security'])) return NotifKind.account;
  // "check_in" is the payload type the server sends and "checked in" is how
  // the title reads — neither matches "check-in", so the check-in notice
  // classified as unknown and landed on the home screen rather than the stay
  // it was about. Both spellings, both separators. Kept identical to the
  // website's classifier in notificationLink.ts.
  if (has([
    'book', 'stay',
    'check-in', 'check_in', 'checkin', 'checked in',
    'check-out', 'check_out', 'checked out',
  ])) {
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
  /// The stay this is about, e.g. "B931569". Carried into the destination so
  /// the list can point at the row instead of dropping the guest at the top of
  /// it — on an account with nine bookings that is most of the value of having
  /// been notified.
  String? bookingId,
}) {
  final home = isHost ? '/host/home' : '/home';
  final kind = notificationKind(
    title: title,
    message: message,
    payloadType: payloadType,
  );
  final hasProperty = (propertyId ?? '').trim().isNotEmpty;
  final hasBooking = (bookingId ?? '').trim().isNotEmpty;

  switch (kind) {
    case NotifKind.message:
    case NotifKind.offer:
      // The negotiation thread is the only conversation surface in this app.
      return hasProperty
          ? NotifDestination('/negotiation',
              arguments: {'propertyId': propertyId})
          : NotifDestination(home);

    case NotifKind.cancellation:
      // /history is the GUEST's My Bookings, and it was where a host's own
      // cancellation notice sent them: a screen that asks the guest booking
      // endpoint what stays THEY have booked, and answers "No cancelled
      // bookings" to a host whose calendar just lost a night. The host portal
      // has its own bookings tab; this opens it.
      return isHost
          ? const NotifDestination('/host/home',
              arguments: {'hostTab': kHostBookingsTab})
          : NotifDestination('/history',
              arguments: {
                'tab': 'Cancelled',
                if (hasBooking) 'highlight': bookingId
              });

    case NotifKind.booking:
      return isHost
          ? const NotifDestination('/host/home',
              arguments: {'hostTab': kHostBookingsTab})
          : NotifDestination('/history',
              arguments: {
                'tab': 'Upcoming',
                if (hasBooking) 'highlight': bookingId
              });

    case NotifKind.payment:
      // Guests find charges and refunds against the stay itself; a host's
      // earnings live behind their own home shell.
      return isHost
          ? NotifDestination(home)
          : NotifDestination('/history',
              arguments: {'tab': 'Completed', if (hasBooking) 'highlight': bookingId});

    case NotifKind.support:
      // One screen, both roles — the host support screen is reached from the
      // host shell, and a notification that says "open Support" has to open it.
      return const NotifDestination('/support');

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
