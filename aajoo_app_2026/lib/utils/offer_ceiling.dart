/// What a night of THIS stay actually lists at.
///
/// A listing's `property_price` is what it costs on an ordinary night. Weekend
/// and seasonal rates make a particular night cost something else — on 29291
/// the nightly column is ₹2,000 and 12–13 September is ₹2,500 — and a
/// negotiation is argued over the nights in the offer, not over the column.
///
/// The app quoted the flat column in two places that matter: the line under
/// the offer box ("Listed at ₹2,000 / night") and the refusal that fires
/// before the offer is ever sent. So on a weekend stay a guest was told their
/// ₹2,400 was "at or above the listed ₹2,000" and stopped — an offer ₹100
/// under what the stay cost, and above the host's accept line, refused by the
/// client before the server ever saw it.
///
/// The website fixed the same fault on 12 September in
/// `src/redesign/lib/offerCeiling.ts`; this is its twin, and the two are meant
/// to be read together.
library;

/// The per-night list price for the nights chosen.
///
/// [roomSubtotal] is the server's quote for the whole stay BEFORE any discount
/// — `originalSubtotal`, never `subtotal`, or a listing with a running offer
/// would lower its own negotiation ceiling. [basePrice] is the flat nightly
/// column, used when there is no quote yet: a figure that is merely stale is
/// better than a blank, and the server refuses an over-list offer anyway.
double listedPerNight({
  required double? roomSubtotal,
  required int nights,
  required double basePrice,
}) {
  if (roomSubtotal != null && roomSubtotal > 0 && nights > 0) {
    return (roomSubtotal / nights * 100).roundToDouble() / 100;
  }
  return basePrice;
}

/// Is there anything left to negotiate?
///
/// At or above what the stay costs, there is not: the guest can simply book.
/// Compared on whole rupees, because the ceiling can carry paise out of a
/// composite quote and "₹2,500.00 is not less than ₹2,499.997" is not a
/// sentence anyone should be shown.
bool offerIsPointless(double amount, double ceiling) {
  if (ceiling <= 0) return false;
  return amount.round() >= ceiling.round();
}
