// Opening a conversation from a booking.
//
// "Chat with Guest" on a host's booking, and "Chat with host" on a guest's,
// both used to push the PRICE NEGOTIATION screen — a price bar, quick-price
// chips and a Custom Offer box, shown to two people discussing a stay that is
// already paid for. Reported as "Chat with Guest incorrectly redirects to the
// Negotiation chat after booking completion".
//
// The regular chat has existed the whole time. `tbl_messages` carries person to
// person conversations with no property attached; `MessagesScreen` is its
// inbox, and the website has routed "Contact Host" into it for months —
// prefilling an opening line that names the stay, so the other side does not
// have to ask which booking this is about (redesign/lib/contactHost.ts).
//
// This is the app's copy of that wording, deliberately identical: a guest who
// messages from the website and then from the app should not appear to be two
// different people writing in two different registers.

/// "05 Sep" from "05-09-2026". Falls back to whatever it was given.
String _shortDate(String? dmy) {
  final v = (dmy ?? '').trim();
  if (v.isEmpty) return '';
  final m = RegExp(r'^(\d{1,2})-(\d{1,2})-(\d{4})$').firstMatch(v);
  if (m == null) return v;
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final mo = int.tryParse(m.group(2)!);
  if (mo == null || mo < 1 || mo > 12) return v;
  return '${m.group(1)!.padLeft(2, '0')} ${months[mo - 1]}';
}

/// "05 Sep – 07 Sep 2026", or "" when the dates are not known.
String stayRangeLabel(String? from, String? to) {
  final a = _shortDate(from);
  final b = _shortDate(to);
  if (a.isEmpty && b.isEmpty) return '';
  if (b.isEmpty) return a;
  final year = RegExp(r'^\d{1,2}-\d{1,2}-(\d{4})$')
      .firstMatch((to ?? '').trim())
      ?.group(1);
  return '$a – $b${year != null ? ' $year' : ''}';
}

/// What a GUEST opens with: the same sentence the website prefills.
String guestOpeningMessage({
  String? propertyName,
  String? bookingCode,
  String? from,
  String? to,
}) {
  final name = (propertyName ?? '').trim();
  final dates = stayRangeLabel(from, to);
  final ref = (bookingCode ?? '').trim();
  if (name.isEmpty && dates.isEmpty && ref.isEmpty) return '';

  final parts = <String>[name.isEmpty ? 'my booking' : 'my stay at $name'];
  if (dates.isNotEmpty) parts.add('($dates)');
  final ending = ref.isEmpty ? '' : ' Booking ref: $ref.';
  return "Hi! I'd like to ask about ${parts.join(' ')}.$ending";
}

/// What a HOST opens with.
///
/// The website has no host-side equivalent yet, so this is new wording rather
/// than a copy — but the shape is the same, because the reason is the same: a
/// guest with more than one stay should not have to ask which one this is.
String hostOpeningMessage({
  String? guestName,
  String? propertyName,
  String? bookingCode,
  String? from,
  String? to,
}) {
  final who = (guestName ?? '').trim().split(' ').first;
  final name = (propertyName ?? '').trim();
  final dates = stayRangeLabel(from, to);
  final ref = (bookingCode ?? '').trim();
  if (name.isEmpty && dates.isEmpty && ref.isEmpty) return '';

  final greeting = who.isEmpty ? 'Hello!' : 'Hello $who!';
  final about = name.isEmpty ? 'your booking' : 'your stay at $name';
  final when = dates.isEmpty ? '' : ' ($dates)';
  final ending = ref.isEmpty ? '' : ' Booking ref: $ref.';
  return "$greeting I'm getting in touch about $about$when.$ending";
}
