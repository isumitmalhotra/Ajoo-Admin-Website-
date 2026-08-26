/// Per-night pricing, mirroring `utils/nightlyRates.js` on the server and
/// `src/redesign/lib/nightlyRates.ts` on the web.
///
/// Step 4 of the listing wizard asks a host, behind a "Weekend pricing"
/// toggle, what they charge on Friday, Saturday and Sunday. Nothing read the
/// answers: the app quoted `rate * nights`, so a guest booking a Saturday was
/// charged the weekday price and the host was never paid the rate they set.
///
/// The server stays authoritative for money; this exists so the app can quote
/// and itemise a stay without a round trip per night.
/// The ceiling from the backend's PRICING_RULES.maxDiscountPercent.
const double _maxDiscountPercent = 90;

/// A stay of this many nights counts as weekly...
const int kWeeklyNights = 7;

/// ...and this many as monthly. Mirrors WEEKLY_NIGHTS / MONTHLY_NIGHTS in
/// utils/nightlyRates.js — the server recomputes the price and refuses a
/// booking that disagrees, so these must not drift.
const int kMonthlyNights = 28;

/// A host's long-stay discount, resolved for a given number of nights.
class LongStayDiscount {
  const LongStayDiscount({this.percent = 0, this.label});
  final double percent;
  final String? label;
  bool get applies => percent > 0 && label != null;
}

class PricingRule {
  const PricingRule({
    required this.base,
    required this.weekendPricing,
    this.friday,
    this.saturday,
    this.sunday,
    this.chargeExtraGuests = false,
    this.guestsIncluded = 0,
    this.extraGuestPrice = 0,
    this.maxExtraGuests = 0,
    this.weeklyDiscountPercent = 0,
    this.monthlyDiscountPercent = 0,
  });

  final double base;
  final bool weekendPricing;
  final double? friday;
  final double? saturday;
  final double? sunday;

  /// Step 4 also asks how many guests the base rate covers and what each one
  /// beyond that costs. Nothing read the answers on any platform, so a host
  /// who set "8 included, ₹1,000 each after" was never paid for the ninth.
  final bool chargeExtraGuests;
  final int guestsIncluded;
  final double extraGuestPrice;
  final int maxExtraGuests;

  /// What the host takes off a long stay. Step 4 collects both and, until now,
  /// nothing on any platform read them — a host offering 20% off a month was
  /// still quoting the full nightly rate times thirty-five nights.
  final double weeklyDiscountPercent;
  final double monthlyDiscountPercent;

  /// Positive, finite money only — rejects null, "", 0 and rubbish, so a blank
  /// override falls back to base rather than producing a free night.
  static double? _money(dynamic v) {
    if (v == null) return null;
    final n = v is num ? v.toDouble() : double.tryParse(v.toString());
    if (n == null || !n.isFinite || n <= 0) return null;
    return n;
  }

  /// A discount percentage, clamped to the schema's 90% maximum. Anything
  /// outside 0–90 is a data error and is ignored rather than trusted: an
  /// uncapped 150% would make a stay cost less than nothing.
  static double _percent(dynamic v) {
    final n = v is num ? v.toDouble() : double.tryParse('${v ?? ''}');
    if (n == null || !n.isFinite || n <= 0) return 0;
    return n > _maxDiscountPercent ? _maxDiscountPercent : n;
  }

  /// A non-negative whole count, or 0.
  static int _count(dynamic v) {
    if (v == null) return 0;
    final n = v is num ? v.toInt() : int.tryParse(v.toString());
    return (n == null || n < 0) ? 0 : n;
  }

  static PricingRule? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final j = Map<String, dynamic>.from(raw);
    return PricingRule(
      base: _money(j['base']) ?? 0,
      weekendPricing: j['weekendPricing'] == true,
      friday: _money(j['friday']),
      saturday: _money(j['saturday']),
      sunday: _money(j['sunday']),
      chargeExtraGuests: j['chargeExtraGuests'] == true,
      guestsIncluded: _count(j['guestsIncluded']),
      extraGuestPrice: _money(j['extraGuestPrice']) ?? 0,
      maxExtraGuests: _count(j['maxExtraGuests']),
      weeklyDiscountPercent: _percent(j['weeklyDiscountPercent']),
      monthlyDiscountPercent: _percent(j['monthlyDiscountPercent']),
    );
  }

  /// What one night costs, given the date that night STARTS.
  ///
  /// Dart's [DateTime.weekday] is 1 = Monday … 7 = Sunday, NOT the 0 = Sunday
  /// that JavaScript uses — getting this wrong would silently shift every rate
  /// by a day, so the constants are named rather than written inline.
  double rateForDate(DateTime date) {
    if (!weekendPricing) return base;
    switch (date.weekday) {
      case DateTime.friday:
        return friday ?? base;
      case DateTime.saturday:
        return saturday ?? base;
      case DateTime.sunday:
        return sunday ?? base;
      default:
        return base;
    }
  }

  /// Price a stay. Half-open [from, to): the checkout day is not a night.
  double quote(DateTime? from, DateTime? to) {
    if (from == null || to == null) return 0;
    var cursor = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    var total = 0.0;
    var guard = 0;
    while (cursor.isBefore(end) && guard < 400) {
      total += rateForDate(cursor);
      cursor = cursor.add(const Duration(days: 1));
      guard += 1;
    }
    return total;
  }

  /// What guests beyond the included headcount add, for the whole stay.
  ///
  /// Charged per extra guest per night, mirroring `extraGuestFeeFor` in
  /// utils/nightlyRates.js and `extraGuestFee` in the web's nightlyRates.ts.
  /// The server recomputes this and refuses a booking whose price disagrees,
  /// so drift here shows up as a rejected booking, not a wrong charge.
  double extraGuestFee(int guests, int nightCount) {
    if (!chargeExtraGuests) return 0;
    if (extraGuestPrice <= 0 || guestsIncluded <= 0) return 0;
    if (guests <= guestsIncluded || nightCount <= 0) return 0;
    var extra = guests - guestsIncluded;
    // A host who caps the extras means it: beyond the cap the booking is
    // refused on capacity rather than quietly billed.
    if (maxExtraGuests > 0 && extra > maxExtraGuests) extra = maxExtraGuests;
    return extra * extraGuestPrice * nightCount;
  }

  /// The host's discount for a stay of [nights].
  ///
  /// Monthly wins over weekly when both apply: it is the larger commitment,
  /// and a host who set both meant the monthly rate for a month-long guest.
  LongStayDiscount longStayFor(int nights) {
    if (nights <= 0) return const LongStayDiscount();
    if (nights >= kMonthlyNights && monthlyDiscountPercent > 0) {
      return LongStayDiscount(
          percent: monthlyDiscountPercent, label: 'Monthly discount');
    }
    if (nights >= kWeeklyNights && weeklyDiscountPercent > 0) {
      return LongStayDiscount(
          percent: weeklyDiscountPercent, label: 'Weekly discount');
    }
    return const LongStayDiscount();
  }

  /// True when this stay is priced differently from a flat base x nights, so
  /// the UI can say why the number is not what the headline rate implies.
  bool differsFromFlat(DateTime? from, DateTime? to, int nights) {
    if (!weekendPricing || nights <= 0) return false;
    return quote(from, to) != base * nights;
  }
}
