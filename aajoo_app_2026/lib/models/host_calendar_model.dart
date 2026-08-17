// What /host/calendar returns: the bookings sitting on a listing's dates, and
// the ranges the host has taken off the market.
//
// Dates here are YYYY-MM-DD. The booking tables carry DD-MM-YYYY and the
// backend converts at the edge, so nothing below ever sees the other shape.
// They stay STRINGS on purpose: in ISO form a string compare is a date compare,
// so day lookup, ordering and "is this day inside the selection" all run on the
// key rather than on a DateTime.
import 'package:rent_home/utils/stay_clock.dart';

/// Normalises whatever the API sent to `YYYY-MM-DD`, accepting the booking
/// tables' DD-MM-YYYY as a fallback so one endpoint drifting cannot blank the
/// calendar. Null when the value is not a date at all.
String? _isoOf(dynamic value) {
  if (value == null) return null;
  final raw = value.toString();
  final iso = parseIsoDate(raw) ?? parseStayDate(raw);
  return iso == null ? null : toIsoDate(iso);
}

/// Money as a clean string ("5000.0" → "5000"); book_total_amt arrives as a
/// number from some rows and a string from others.
String _amountStr(dynamic v) {
  if (v == null) return '';
  if (v is num) return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  return v.toString();
}

String _str(dynamic v) => v == null ? '' : v.toString().trim();

/// Walks an inclusive YYYY-MM-DD range, day by day.
///
/// Guarded at 800 days because one malformed row — `to` before `from`, or a
/// range measured in years — would otherwise spin the UI thread. Same cap the
/// web calendar uses.
void eachIsoDay(String from, String to, void Function(String iso) fn) {
  final start = parseIsoDate(from);
  final end = parseIsoDate(to);
  if (start == null || end == null) return;
  var cur = start;
  for (var guard = 0; !cur.isAfter(end) && guard < 800; guard++) {
    fn(toIsoDate(cur));
    // Rebuilt from the fields rather than +Duration(days: 1): a DST boundary
    // would otherwise land the cursor at 23:00 the same day and repeat it.
    cur = DateTime(cur.year, cur.month, cur.day + 1);
  }
}

/// How many days an inclusive range covers.
int isoDayCount(String from, String to) {
  var n = 0;
  eachIsoDay(from, to, (_) => n += 1);
  return n;
}

/// Walks the NIGHTS a stay occupies — half-open `[from, to)`, so the checkout
/// day is not one of them.
///
/// A block and a stay are not the same shape and painting them with the same
/// walk is how the host ends up staring at a lie. `bookingCreate`'s guard,
/// `stayHitsBlock` and `/booking/property-availability` all agree that a stay
/// ending the 4th leaves the 4th on sale — check-out is 11:00 and the next
/// check-in 14:00. Colouring the 4th "Booked" would tell the host a day is
/// taken while the platform is still selling it, and — worse for R4 — would
/// stop them closing that day for their own turnover, which is the exact
/// inability the block endpoint's half-open comparison was written to remove.
void eachStayNight(String from, String to, void Function(String iso) fn) {
  final start = parseIsoDate(from);
  final end = parseIsoDate(to);
  if (start == null || end == null) return;
  if (!start.isBefore(end)) {
    // Same day, or `to` before `from`: malformed rather than zero-night. Show
    // it on its start day so the host can see the row exists at all.
    fn(toIsoDate(start));
    return;
  }
  var cur = start;
  for (var guard = 0; cur.isBefore(end) && guard < 800; guard++) {
    fn(toIsoDate(cur));
    cur = DateTime(cur.year, cur.month, cur.day + 1);
  }
}

/// Nights slept, which is one fewer than the days the two dates span.
int stayNights(String from, String to) {
  var n = 0;
  eachStayNight(from, to, (_) => n += 1);
  return n;
}

/// One booking occupying dates on the host's calendar.
class HostCalendarStay {
  const HostCalendarStay({
    required this.bookingId,
    required this.bookingPriId,
    required this.from,
    required this.to,
    required this.guestName,
    required this.guestPhone,
    required this.status,
    required this.amount,
    required this.paid,
  });

  final String bookingId;
  final int bookingPriId;
  final String from;
  final String to;
  final String guestName;
  final String guestPhone;
  final String status;
  final String amount;
  final bool paid;

  /// Null when the row carries no readable dates. A stay that cannot be placed
  /// must be left off — drawing it on an arbitrary day would be worse than
  /// omitting it, because the host would plan around a lie.
  static HostCalendarStay? fromJson(Map<String, dynamic> json) {
    final from = _isoOf(json['from']);
    final to = _isoOf(json['to']);
    if (from == null || to == null) return null;
    return HostCalendarStay(
      bookingId: _str(json['bookingId']),
      bookingPriId: int.tryParse(_str(json['bookingPriId'])) ?? 0,
      from: from,
      to: to,
      guestName: _str(json['guestName']),
      guestPhone: _str(json['guestPhone']),
      status: _str(json['status']),
      amount: _amountStr(json['amount']),
      paid: json['paid'] == true || json['paid'] == 1,
    );
  }
}

/// A range the host has closed off — an off-platform booking, maintenance,
/// their own stay.
class HostCalendarBlock {
  const HostCalendarBlock({
    required this.blockId,
    required this.from,
    required this.to,
    required this.reason,
  });

  final int blockId;
  final String from;
  final String to;
  final String reason;

  static HostCalendarBlock? fromJson(Map<String, dynamic> json) {
    final from = _isoOf(json['from']);
    final to = _isoOf(json['to']);
    final id = int.tryParse(_str(json['blockId']));
    if (from == null || to == null || id == null) return null;
    return HostCalendarBlock(
      blockId: id,
      from: from,
      to: to,
      reason: _str(json['reason']),
    );
  }
}

/// The whole payload for one listing.
class HostCalendar {
  const HostCalendar({
    required this.propertyId,
    required this.stays,
    required this.blocks,
  });

  final int propertyId;
  final List<HostCalendarStay> stays;
  final List<HostCalendarBlock> blocks;

  factory HostCalendar.fromJson(Map<String, dynamic> json) {
    List<T> parse<T>(dynamic list, T? Function(Map<String, dynamic>) build) {
      if (list is! List) return <T>[];
      return list
          .whereType<Map>()
          .map((e) => build(Map<String, dynamic>.from(e)))
          .whereType<T>()
          .toList();
    }

    return HostCalendar(
      propertyId: int.tryParse(_str(json['propertyId'])) ?? 0,
      stays: parse(json['stays'], HostCalendarStay.fromJson),
      blocks: parse(json['blocks'], HostCalendarBlock.fromJson),
    );
  }
}
