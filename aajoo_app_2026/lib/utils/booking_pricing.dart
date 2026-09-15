// What a stay costs — the Dart counterpart of the web's summarize() in
// redesign/lib/bookingDraft.ts, and a mirror of the backend's
// calculateBookingtax() in utils/methods.js. One rule, three platforms.
//
// Why this exists: the app used to do the arithmetic inline, three times in
// property_page.dart (the header price, the breakdown panel, and the submit
// handler), and got it wrong in the same three ways:
//
//   1. It sent the ALREADY-TAXED total to /booking/create as `price`. The
//      backend treats `price` as the pre-tax room subtotal and adds GST to it,
//      so the tax was applied twice. On booking B618787 the guest was quoted
//      and charged ₹23,020 while the row stored book_total_amt ₹24,171 — and
//      pay-on-arrival collects book_total_amt, so that guest would have been
//      billed ₹1,151 more than the app ever showed them.
//
//   2. It picked the GST band from the STAY total rather than the per-night
//      tariff. Indian accommodation GST bands on the nightly rate: a ₹4,000
//      room booked two nights is ₹8,000 for the stay but still 5%, not 18%.
//      The backend bands on property_price (per night) and the web on
//      perNight; only mobile banded on the total, so it showed 18% where
//      the guest was actually charged 5%.
//
//   3. It added a ₹10 "Platform Fee" that nothing collects. The backend never
//      adds one, and the web dropped fees deliberately ("Cleaning/service fees
//      from the old mockup are NOT charged by the backend"). It was a line
//      item in the UI and nowhere else.
//
// The authoritative amount is still whatever the backend puts in the Razorpay
// order. This exists so the figure shown before that call matches it.

/// A stay's price, broken down the way the guest sees it.
class StayPrice {
  /// The room total for the whole stay, before discount and tax. This is the
  /// value to send to /booking/create as `price` — send it UNDISCOUNTED and
  /// pass `couponCode` alongside, because the backend recomputes the discount
  /// itself and applies it to whatever it is given. Sending an already
  /// discounted figure would take the discount twice.
  final double roomSubtotal;

  /// What guests beyond the host's included headcount add for the whole stay.
  ///
  /// Shown as its own line, but it is part of what is charged: the backend
  /// discounts and taxes room + party charge, and validates the `price` the app
  /// sends against that sum. Send [chargeable], not [roomSubtotal].
  final double extraGuestFee;

  /// What the declared pets add for the whole stay — per pet, per night.
  ///
  /// Like [extraGuestFee] it is shown as its own line and is part of what is
  /// charged: the backend discounts and taxes room + party + pets, and
  /// validates the `price` the app sends against that sum.
  final double petFee;

  /// How many pets were declared, so the line can name them.
  final int pets;

  /// The host's cleaning fee for the stay, quoted by the server — STATED,
  /// not charged (client decision, 2026-09-15, §1.14). Carried so the sheet
  /// can say it under the total, in the same words as the website; outside
  /// [chargeable], the discount and the tax. (Builds 88–93 charged it; the
  /// server recognises a price they send and charges without it.)
  final double cleaningFee;

  /// Room + party charge + pets — the figure to send as `price`. Not cleaning.
  final double chargeable;

  /// The coupon or negotiated-deal reduction — a percentage of [roomSubtotal]
  /// and of nothing else. The fees ride through it untouched.
  final double discount;

  /// What the same nights would have cost at the ordinary nightly rate.
  ///
  /// [roomSubtotal] is what the guest is actually charged — the host's weekly
  /// or monthly rate when the stay is long enough to earn one. The difference
  /// between the two is the saving, and it is shown to the guest as a
  /// percentage and an amount ("you saved 25% — ₹43,750").
  final double nightlyTotal;

  /// [nightlyTotal] − [roomSubtotal]. Never negative.
  final double longStaySaving;

  /// That saving as a percentage of [nightlyTotal], to one decimal. Derived,
  /// never stored: it describes the price rather than setting it.
  final double longStaySavingPercent;

  /// "Weekly rate" / "Monthly rate", or null when neither applied.
  final String? longStayLabel;

  /// [chargeable] less [discount] — the base GST is actually charged on.
  final double discountedRoom;

  /// 5 or 18 when every night is in one band; the blended figure (to two
  /// decimals) when the nights straddle ₹7,500. A blend is a division, not
  /// a rate — print [taxBands] where a rate belongs.
  final double taxPct;

  /// The band each night landed in, in stay order. Empty when the stay was
  /// banded on the average night (no server weights).
  final List<int> taxBands;

  /// GST on [discountedRoom].
  final double taxes;

  /// What the guest pays.
  final double total;

  const StayPrice({
    required this.roomSubtotal,
    required this.extraGuestFee,
    this.petFee = 0,
    this.cleaningFee = 0,
    this.pets = 0,
    required this.chargeable,
    required this.discount,
    this.nightlyTotal = 0,
    this.longStaySaving = 0,
    this.longStaySavingPercent = 0,
    this.longStayLabel,
    required this.discountedRoom,
    required this.taxPct,
    this.taxBands = const [],
    required this.taxes,
    required this.total,
  });

  /// "GST (5%)" when one band; "GST · 6 nights at 5% · 1 night at 18%" when
  /// the nights straddle the line. Never the blended average as a rate —
  /// the client asked why a stay was "taxed at 7.21%", and it was not: it
  /// was six nights at 5% and one at 18%.
  String get taxLabel {
    final bands = taxBands.where((b) => b > 0).toList();
    if (bands.isEmpty) return 'GST (${_pctText(taxPct)}%)';
    final counts = <int, int>{};
    for (final b in bands) {
      counts[b] = (counts[b] ?? 0) + 1;
    }
    if (counts.length == 1) return 'GST (${counts.keys.first}%)';
    final keys = counts.keys.toList()..sort();
    return 'GST · ${keys.map((k) => '${counts[k]} night${counts[k] == 1 ? '' : 's'} at $k%').join(' · ')}';
  }

  static String _pctText(double v) {
    final r = (v * 100).round() / 100;
    return r == r.roundToDouble() ? r.toStringAsFixed(0) : r.toString();
  }
}

/// Prices a stay.
///
/// [roomSubtotal] is the room charge for the whole stay (per-night × nights,
/// or the negotiated figure). [perNightTariff] is the listed nightly rate and
/// decides the GST band only — it is never itself charged. [discount] is any
/// validated coupon or negotiated-deal reduction, worked out on the ROOM; the
/// backend applies it BEFORE GST and never to the fees, so this does too.
///
/// Indian accommodation GST:
///   per-night ≤ ₹7,500 → 5%
///   per-night >  ₹7,500 → 18%
StayPrice priceStay({
  required double roomSubtotal,
  required double perNightTariff,
  double discount = 0,
  double extraGuestFee = 0,
  double petFee = 0,
  double cleaningFee = 0,
  int pets = 0,
  double nightlyTotal = 0,
  String? longStayLabel,
  List<double> taxNights = const [],
}) {
  // [roomSubtotal] is ALREADY the host's long-stay rate when one applies —
  // the caller resolves it, the same way the server does in quoteRange. What
  // arrives here as [nightlyTotal] is only the comparison: what the same
  // nights would have cost night by night, so the saving can be stated.
  final subtotal = roomSubtotal.isFinite && roomSubtotal > 0 ? roomSubtotal : 0.0;
  final nightly =
      nightlyTotal.isFinite && nightlyTotal > subtotal ? nightlyTotal : subtotal;
  final saving = nightly - subtotal;
  final savingPercent =
      nightly > 0 ? (saving / nightly * 1000).roundToDouble() / 10 : 0.0;
  final party =
      extraGuestFee.isFinite && extraGuestFee > 0 ? extraGuestFee : 0.0;
  final petCharge = petFee.isFinite && petFee > 0 ? petFee : 0.0;
  final cleaning = cleaningFee.isFinite && cleaningFee > 0 ? cleaningFee : 0.0;
  // The party charge and the pets ride with the room into the tax, because
  // GST is levied on the final price the guest pays. They do NOT ride into
  // the discount: a coupon — and a negotiated deal, which reaches checkout
  // as one — is a percentage of the ROOM. The server mints the deal against
  // the room subtotal so that percentage reproduces the agreed per-night
  // price; taken off a bigger number it under-pays the host (client,
  // 2026-09-14, listing 29310). The cleaning fee rides into NOTHING: stated,
  // not charged, since 2026-09-15 (client, §1.14) — it is returned for the
  // sentence under the total and is paid to the host directly.
  final chargeable = subtotal + party + petCharge;
  final off = (discount.isFinite && discount > 0 ? discount : 0.0)
      .clamp(0.0, subtotal)
      .toDouble();
  final discountedRoom = (chargeable - off).clamp(0.0, chargeable).toDouble();
  // Per night when the server told us how the nights are weighted, and on
  // the average night only when it did not.
  //
  // Seen on the emulator, 2026-09-15, listing 29309 for 15–22 Sep: the
  // server bands each night on its own share (six under ₹7,500 at 5%, the
  // Sunday over it at 18% — ₹3,279.43) while this pricer took one band from
  // the base tariff and charged 5% on everything (₹2,275). The app showed
  // ₹47,775 and the Razorpay order — the server's figure — was ₹48,779.43.
  // The website had the same fault and was fixed the same way on 13 Sep.
  final weights = taxNights.where((w) => w.isFinite && w > 0).toList();
  final weightSum = weights.fold<double>(0, (a, b) => a + b);
  double taxPct;
  double taxes;
  var taxBands = const <int>[];
  if (weights.isNotEmpty && weightSum > 0 && discountedRoom > 0) {
    final bands = <int>[];
    var exact = 0.0;
    for (final w in weights) {
      final share = discountedRoom * (w / weightSum);
      final pct = share >= 7500 ? 18 : 5;
      bands.add(pct);
      exact += share * pct / 100;
    }
    // Rounded ONCE on the sum, like the server: rounding each night and
    // adding drifts a paise a night.
    taxes = (exact * 100).roundToDouble() / 100;
    taxPct = (taxes / discountedRoom * 10000).roundToDouble() / 100;
    taxBands = bands;
  } else {
    // 7,500 exactly is the HIGH band — client rule, 2026-09-10.
    taxPct = perNightTariff >= 7500 ? 18 : 5;
    // Rounded to paise, the same way the backend rounds, so the total shown
    // here equals the Razorpay order amount exactly rather than a rupee out.
    taxes = (discountedRoom * taxPct).roundToDouble() / 100;
  }
  return StayPrice(
    // The room at the host's long-stay rate when one applies: this is `price`
    // on the booking, and the server computes the identical figure.
    roomSubtotal: subtotal,
    nightlyTotal: nightly,
    longStaySaving: saving,
    longStaySavingPercent: savingPercent,
    longStayLabel: saving > 0 ? longStayLabel : null,
    extraGuestFee: party,
    petFee: petCharge,
    cleaningFee: cleaning,
    pets: pets,
    chargeable: chargeable,
    discount: chargeable - discountedRoom,
    discountedRoom: discountedRoom,
    taxPct: taxPct,
    taxBands: taxBands,
    taxes: taxes,
    total: discountedRoom + taxes,
  );
}
