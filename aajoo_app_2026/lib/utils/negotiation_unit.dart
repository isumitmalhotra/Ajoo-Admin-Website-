/// What unit a negotiation is spoken in.
///
/// Client, 2026-09-15, on the offer dialog for a seven-night stay: "while
/// negotiating for weekly or monthly booking, renter should be asked total
/// price instead of per night?? … for less than 7 days, per night
/// negotiations is fine. But for weekly and monthly it should be on the
/// total."
///
/// The rule, the same on the server (utils/negotiationUnit.js) and the web
/// (redesign/lib/negotiationUnit.ts):
///
///   under 7 nights    per night        "₹3,000/night"
///   7 nights or more  the stay total   "₹42,000 for 7 nights"
///
/// The unit of RECORD stays per night — every offer, counter, event and
/// coupon carries a per-night figure — so a sheet that asks for a total
/// converts it with [perNightOf] before sending, and a screen that shows a
/// recorded figure multiplies back with [stayTotal]. Rounding recovers the
/// typed total for any stay under a hundred nights.
library;

import 'package:rent_home/utils/money.dart';

/// A week — the same line the host's weekly rate is drawn at.
const int kLongStayNights = 7;

bool isLongStay(int? nights) => (nights ?? 0) >= kLongStayNights;

/// The stay total a per-night figure comes to, to the rupee.
int stayTotal(num perNight, int nights) => (perNight * nights).round();

/// The per-night figure to SEND for a total the guest typed. Two decimals —
/// the column's.
double perNightOf(num total, int nights) {
  if (nights <= 0) return total.toDouble();
  return (total / nights * 100).roundToDouble() / 100;
}

/// What a typed amount MEANS, given the stay: the per-night figure to send
/// and the total it comes to. On a short stay the typed number is per night;
/// on a long one it is the total.
({double perNight, int total}) offerFromInput(num typed, int? nights) {
  final n = nights ?? 0;
  if (isLongStay(n)) return (perNight: perNightOf(typed, n), total: typed.round());
  return (perNight: typed.toDouble(), total: (typed * (n > 0 ? n : 1)).round());
}

/// How a short stay's price is phrased.
enum NightForm { slash, a, per }

/// A recorded per-night price, in the unit this stay is negotiated in.
/// "₹3,000/night" under a week; "₹42,000 for 7 nights" from a week.
String priceLine(num perNight, int? nights, {NightForm form = NightForm.slash}) {
  final n = nights ?? 0;
  if (isLongStay(n)) return '${rupees(stayTotal(perNight, n))} for $n nights';
  final p = rupees(perNight);
  switch (form) {
    case NightForm.a:
      return '$p a night';
    case NightForm.per:
      return '$p per night';
    case NightForm.slash:
      return '$p/night';
  }
}

/// The headline figure and its unit, for a number set beside a small label.
({String amount, String unit}) priceParts(num perNight, int? nights) {
  final n = nights ?? 0;
  if (isLongStay(n)) return (amount: rupees(stayTotal(perNight, n)), unit: ' for $n nights');
  return (amount: rupees(perNight), unit: ' /night');
}

/// What the input asks for.
String offerInputLabel(int? nights, {bool counter = false}) {
  if (isLongStay(nights)) {
    return counter
        ? 'Your counter for the $nights nights (₹) *'
        : 'Your offer for the $nights nights (₹)';
  }
  return counter ? 'Your counter price per night (₹) *' : 'Your offer per night (₹)';
}

/// Nights between two DD-MM-YYYY (or YYYY-MM-DD) dates; null when unknown.
int? nightsBetweenDmy(String? from, String? to) {
  DateTime? parse(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    final t = s.trim();
    final dmy = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$').firstMatch(t);
    if (dmy != null) {
      return DateTime.utc(int.parse(dmy.group(3)!), int.parse(dmy.group(2)!), int.parse(dmy.group(1)!));
    }
    final ymd = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(t);
    if (ymd != null) {
      return DateTime.utc(int.parse(ymd.group(1)!), int.parse(ymd.group(2)!), int.parse(ymd.group(3)!));
    }
    return null;
  }

  final a = parse(from);
  final b = parse(to);
  if (a == null || b == null) return null;
  final d = b.difference(a).inDays;
  return d > 0 ? d : null;
}
