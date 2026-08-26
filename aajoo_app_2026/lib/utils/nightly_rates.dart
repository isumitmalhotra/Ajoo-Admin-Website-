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

/// A host's long-stay rate, resolved for a given number of nights.
class LongStayRate {
  const LongStayRate({required this.nightlyRate, required this.label});

  /// The stated period price divided by its own nights.
  final double nightlyRate;

  /// "Weekly rate" / "Monthly rate" — what to call it to the guest.
  final String label;
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
    this.weeklyPrice,
    this.monthlyPrice,
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

  /// Still stored and round-tripped, deliberately NOT applied to a price: a
  /// stay must not get both a percentage and a stated price.
  final double weeklyDiscountPercent;
  final double monthlyDiscountPercent;

  /// What the host says a week and a month COST, in total. Null when they do
  /// not offer one, in which case the stay is quoted night by night.
  final double? weeklyPrice;
  final double? monthlyPrice;

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
      weeklyPrice: _money(j['weeklyPrice']),
      monthlyPrice: _money(j['monthlyPrice']),
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

  /// The host's long-stay rate for a stay of [nights], or null.
  ///
  /// The stated price is divided by its own night count into an effective
  /// nightly rate, applied to every night. That is what makes it usable at any
  /// length — a 9-night stay gets the weekly rate for all 9 nights, and there
  /// is no cliff where one extra night costs a whole extra week.
  ///
  /// Monthly wins over weekly when both apply. Mirrors longStayRateFor in
  /// utils/nightlyRates.js, which the server re-runs and refuses a booking
  /// that disagrees with — so these must not drift.
  LongStayRate? longStayFor(int nights) {
    if (nights <= 0) return null;
    final monthly = monthlyPrice ?? 0;
    if (nights >= kMonthlyNights && monthly > 0) {
      return LongStayRate(
          nightlyRate: monthly / kMonthlyNights, label: 'Monthly rate');
    }
    final weekly = weeklyPrice ?? 0;
    if (nights >= kWeeklyNights && weekly > 0) {
      return LongStayRate(
          nightlyRate: weekly / kWeeklyNights, label: 'Weekly rate');
    }
    return null;
  }

  /// True when this stay is priced differently from a flat base x nights, so
  /// the UI can say why the number is not what the headline rate implies.
  bool differsFromFlat(DateTime? from, DateTime? to, int nights) {
    if (!weekendPricing || nights <= 0) return false;
    return quote(from, to) != base * nights;
  }
}
