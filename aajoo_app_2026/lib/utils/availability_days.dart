// Which nights a renter may not pick.
//
// /booking/property-availability returns bookings AND the dates the host has
// closed off in one `bookedRanges` array, so a host block is enforced by the
// same predicate as a booking — which is the whole point of blocking: dates the
// host has taken for an off-platform stay must be unavailable here, not merely
// annotated somewhere else.
//
// The rule matches the backend's double-booking guard: a range is inclusive of
// check-in and exclusive of check-out, because a checkout and the next
// check-in can share a day.
//
// This exists because the predicate had to be written three times — the
// redesigned property page has its own copy, and the two screens fixed here had
// none at all, which is how a renter could still take a blocked date.
import 'package:flutter/material.dart';

class BookedDays {
  const BookedDays(this.ranges);

  final List<DateTimeRange> ranges;

  static const BookedDays none = BookedDays(<DateTimeRange>[]);

  bool get isEmpty => ranges.isEmpty;

  bool contains(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    for (final r in ranges) {
      if (!day.isBefore(r.start) && day.isBefore(r.end)) return true;
    }
    return false;
  }

  /// The first pickable day at or after [candidate], within [first]…[last].
  ///
  /// showDatePicker asserts that its initialDate is selectable, so handing it a
  /// booked day throws. Null means the whole window is taken — the caller must
  /// then not open the picker at all rather than open it on a day the predicate
  /// will reject.
  DateTime? firstFree(DateTime candidate, DateTime first, DateTime last) {
    var d = candidate.isBefore(first) ? first : candidate;
    while (!d.isAfter(last)) {
      if (!contains(d)) return d;
      d = DateTime(d.year, d.month, d.day + 1);
    }
    return null;
  }
}
