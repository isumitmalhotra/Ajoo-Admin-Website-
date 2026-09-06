/// The server's price for one stay — `POST /pricing/quote`.
///
/// Pricing Architecture §15: "the UI never computes the final price". The app
/// kept its own copy of the rate card and worked the room charge out locally,
/// which was fine while the two implementations agreed and silently wrong the
/// moment they did not. The Advance Booking Discount (§10–§12) is exactly that
/// case: the server takes it off, the app knew nothing about it, and
/// booking.controller refuses a price more than a rupee from its own — so an
/// advance booking on a discounted listing could not be made from the app at
/// all.
///
/// This is the answer, not a hint. The local arithmetic stays as the fallback
/// for the moment the quote has not arrived (or cannot), so a guest is never
/// left staring at a blank price.
class StayQuote {
  /// The room charge the server will insist on — long-stay rate applied,
  /// advance-booking discount already deducted, before any running offer.
  final double subtotal;

  /// The same figure BEFORE the advance discount, so the breakdown can show
  /// "Original price / Advance Booking Discount / Final price" (§12).
  final double originalSubtotal;
  final double advanceDiscountPercent;
  final double advanceDiscount;

  final double extraGuestFee;
  final double petFee;
  final double total;
  final double taxes;
  final double taxPct;
  final double grandTotal;
  final int nightCount;

  /// "Weekly rate" / "Monthly rate", or null when this stay earns neither.
  final String? longStayLabel;
  final double longStaySaving;

  /// Decided by the server so no client keeps its own calendar arithmetic.
  final bool isPreBooking;

  const StayQuote({
    required this.subtotal,
    required this.originalSubtotal,
    required this.advanceDiscountPercent,
    required this.advanceDiscount,
    required this.extraGuestFee,
    required this.petFee,
    required this.total,
    required this.taxes,
    required this.taxPct,
    required this.grandTotal,
    required this.nightCount,
    required this.longStayLabel,
    required this.longStaySaving,
    required this.isPreBooking,
  });

  /// Money arrives as a number OR as a string — mysql2 hands DECIMAL columns
  /// back as strings, and they travel through the API unchanged.
  static double _num(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static StayQuote? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final j = Map<String, dynamic>.from(raw);
    // No grand total means this is not a quote, whatever else came back.
    if (j['grandTotal'] == null) return null;
    final subtotal = _num(j['subtotal']);
    if (subtotal <= 0) return null;
    return StayQuote(
      subtotal: subtotal,
      // Equal to the subtotal on every stay that earns no discount, so a
      // caller can use it unconditionally.
      originalSubtotal:
          j['originalSubtotal'] == null ? subtotal : _num(j['originalSubtotal']),
      advanceDiscountPercent: _num(j['advanceDiscountPercent']),
      advanceDiscount: _num(j['advanceDiscount']),
      extraGuestFee: _num(j['extraGuestFee']),
      petFee: _num(j['petFee']),
      total: _num(j['total']),
      taxes: _num(j['taxes']),
      taxPct: _num(j['taxPct']),
      grandTotal: _num(j['grandTotal']),
      nightCount: (_num(j['nightCount'])).round(),
      longStayLabel: (j['longStayLabel'] as String?)?.trim().isEmpty ?? true
          ? null
          : j['longStayLabel'] as String,
      longStaySaving: _num(j['longStaySaving']),
      isPreBooking: j['isPreBooking'] == true,
    );
  }
}
