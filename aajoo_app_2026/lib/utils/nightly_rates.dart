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

  /// Positive, finite money only — rejects null, "", 0 and rubbish, so a blank
  /// override falls back to base rather than producing a free night.
  static double? _money(dynamic v) {
    if (v == null) return null;
    final n = v is num ? v.toDouble() : double.tryParse(v.toString());
    if (n == null || !n.isFinite || n <= 0) return null;
    return n;
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

  /// True when this stay is priced differently from a flat base x nights, so
  /// the UI can say why the number is not what the headline rate implies.
  bool differsFromFlat(DateTime? from, DateTime? to, int nights) {
    if (!weekendPricing || nights <= 0) return false;
    return quote(from, to) != base * nights;
  }
}
