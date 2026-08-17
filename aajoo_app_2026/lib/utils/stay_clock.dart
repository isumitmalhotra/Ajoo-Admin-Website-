// When a stay starts and ends — the Dart counterpart of the web's
// redesign/lib/stayClock.ts. One definition per platform, same rule.
//
// Why this exists on mobile too: /booking/ongoing deliberately returns stays
// at DATE granularity ("check-out date is today or later"), which covers both
// a stay in progress and one still to come. The backend comment says it
// outright — "the client already derives currentlyStaying from the two dates".
// The web does. Mobile did not, so a booking whose 11 AM checkout had already
// passed still showed as an active stay for the rest of the day. That is the
// same bug that was reported and fixed on the web; this closes it here.
//
// Times are IST. The offset is fixed at +5:30 with no DST, so a plain offset
// is correct rather than a simplification.

const int _istOffsetMinutes = 330;

/// Check-in opens at 2 PM IST.
const int kCheckInHour = 14;

/// Check-out is 11 AM IST — not midnight, which is what made a finished stay
/// look active for another 13 hours.
const int kCheckOutHour = 11;

/// Parses the `DD-MM-YYYY` the booking API returns. Returns null on anything
/// unexpected so callers can fall back rather than show a wrong state.
DateTime? parseStayDate(String? raw) {
  if (raw == null) return null;
  final s = raw.trim();
  if (s.isEmpty) return null;

  final dmy = RegExp(r'^(\d{1,2})-(\d{1,2})-(\d{4})$').firstMatch(s);
  if (dmy != null) {
    final d = int.parse(dmy.group(1)!);
    final m = int.parse(dmy.group(2)!);
    final y = int.parse(dmy.group(3)!);
    return DateTime.utc(y, m, d);
  }

  // ISO or anything else Dart understands, as a fallback.
  final parsed = DateTime.tryParse(s);
  if (parsed == null) return null;
  return DateTime.utc(parsed.year, parsed.month, parsed.day);
}

/// Parses the `YYYY-MM-DD` the host-calendar API speaks — Sequelize DATEONLY
/// columns and /host/calendar — as distinct from the DD-MM-YYYY the booking
/// tables carry. The two must never be crossed: "03-04-2026" is the 3rd of
/// April in one and unreadable in the other.
///
/// Local midnight, not UTC: this feeds a month grid the host reads in their own
/// timezone, and a UTC day would highlight the day before for anyone west of
/// UTC. [parseStayDate] stays UTC because it feeds check-in/check-out instants.
DateTime? parseIsoDate(String? raw) {
  if (raw == null) return null;
  // Tolerates a trailing time, which is what a DATEONLY column serialises to
  // if the column is ever redeclared as DATE.
  final m = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})').firstMatch(raw.trim());
  if (m == null) return null;
  return DateTime(
      int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!));
}

/// `DateTime` → `YYYY-MM-DD`. In this form a string compare is also a date
/// compare, which is what lets the calendar key day lookups and range tests on
/// the string and never on a DateTime.
String toIsoDate(DateTime d) =>
    "${d.year.toString().padLeft(4, '0')}-"
    "${d.month.toString().padLeft(2, '0')}-"
    "${d.day.toString().padLeft(2, '0')}";

/// The exact instant a stay day begins or ends, in UTC.
DateTime? _stayMoment(DateTime? day, int hour) {
  if (day == null) return null;
  return DateTime.utc(day.year, day.month, day.day, hour)
      .subtract(const Duration(minutes: _istOffsetMinutes));
}

DateTime? checkInAt(String? from) => _stayMoment(parseStayDate(from), kCheckInHour);

DateTime? checkOutAt(String? to) => _stayMoment(parseStayDate(to), kCheckOutHour);

/// True once 2 PM IST on the check-in day has passed.
bool hasStarted(String? from, {DateTime? now}) {
  final t = checkInAt(from);
  if (t == null) return false;
  return !(now ?? DateTime.now().toUtc()).isBefore(t);
}

/// True once 11 AM IST on the check-out day has passed.
bool hasEnded(String? to, {DateTime? now}) {
  final t = checkOutAt(to);
  if (t == null) return false;
  return !(now ?? DateTime.now().toUtc()).isBefore(t);
}

/// The guest is in the property right now.
bool isStaying(String? from, String? to, {DateTime? now}) =>
    hasStarted(from, now: now) && !hasEnded(to, now: now);

/// The stay has not begun yet.
bool isUpcoming(String? from, {DateTime? now}) => !hasStarted(from, now: now);
