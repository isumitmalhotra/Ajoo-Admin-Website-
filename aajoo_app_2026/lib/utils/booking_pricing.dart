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

  /// Room + party charge — the figure to send as `price`.
  final double chargeable;

  /// The coupon or negotiated-deal reduction applied to [chargeable].
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

  /// [roomSubtotal] less [discount] — the base GST is actually charged on.
  final double discountedRoom;

  /// 5 or 18, chosen by the per-night tariff.
  final int taxPct;

  /// GST on [discountedRoom].
  final double taxes;

  /// What the guest pays.
  final double total;

  const StayPrice({
    required this.roomSubtotal,
    required this.extraGuestFee,
    this.petFee = 0,
    this.pets = 0,
    required this.chargeable,
    required this.discount,
    this.nightlyTotal = 0,
    this.longStaySaving = 0,
    this.longStaySavingPercent = 0,
    this.longStayLabel,
    required this.discountedRoom,
    required this.taxPct,
    required this.taxes,
    required this.total,
  });
}

/// Prices a stay.
///
/// [roomSubtotal] is the room charge for the whole stay (per-night × nights,
/// or the negotiated figure). [perNightTariff] is the listed nightly rate and
/// decides the GST band only — it is never itself charged. [discount] is any
/// validated coupon or negotiated-deal reduction; the backend applies it to
/// the room total BEFORE GST, so this does too.
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
  int pets = 0,
  double nightlyTotal = 0,
  String? longStayLabel,
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
  // The party charge and the pets ride with the room through discount and tax,
  // because that is what the backend does with them.
  final chargeable = subtotal + party + petCharge;
  final off = discount.isFinite && discount > 0 ? discount : 0.0;
  final discountedRoom = (chargeable - off).clamp(0.0, chargeable).toDouble();
  final taxPct = perNightTariff > 7500 ? 18 : 5;
  // Rounded to paise, the same way the backend rounds, so the total shown here
  // equals the Razorpay order amount exactly rather than being a rupee out.
  final taxes = (discountedRoom * taxPct).roundToDouble() / 100;
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
    pets: pets,
    chargeable: chargeable,
    discount: chargeable - discountedRoom,
    discountedRoom: discountedRoom,
    taxPct: taxPct,
    taxes: taxes,
    total: discountedRoom + taxes,
  );
}
