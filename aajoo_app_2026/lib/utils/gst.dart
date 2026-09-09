/// Accommodation GST, one rule for the whole app.
///
/// The slab (client rule, 2026-09-10):
///
///   a night under Rs 7,500       -> 5%
///   a night at Rs 7,500 or above -> 18%
///
/// Two things about it are easy to get wrong, and the app got both.
///
/// THE BOUNDARY. Three screens wrote `price <= 7500 ? 0.05 : 0.18`, so a night
/// priced at exactly Rs 7,500 — the commonest round number a host picks, and
/// the boundary itself — was taxed at 5%. It is 18%.
///
/// THE FIGURE IT IS TAKEN FROM. It is a PER-NIGHT rule. The checkout banded on
/// the whole stay, so two nights at Rs 5,000 came to Rs 10,000 and were taxed
/// at 18% — a rate neither night is anywhere near. Band on one night, then
/// apply it to what is being charged.
///
/// And the base is the price the guest actually pays, after every discount.
///
/// NONE OF THIS SHOULD DECIDE WHAT A GUEST IS CHARGED. The server works the
/// tax out night by night, so a stay mixing a cheap midweek night with a dear
/// weekend one is taxed 5% on one and 18% on the other, which nothing here can
/// reproduce without the rate card. Every caller must prefer the server's own
/// figure and reach for this only when that has not arrived — see
/// [[money_display_rule]]: never recompute GST client-side when the server has
/// already said.
library;

/// The rupee figure at and above which a night is taxed at the higher rate.
const double kGstSlabAt = 7500;

const double kGstHigh = 0.18;
const double kGstLow = 0.05;

/// The rate for ONE night at [nightlyCharge] — the amount actually charged for
/// that night, after discounts. At the boundary, the higher rate.
double gstRateForNight(num nightlyCharge) =>
    nightlyCharge >= kGstSlabAt ? kGstHigh : kGstLow;

/// GST on a stay, banded on what one night of it costs.
///
/// [total] is the payable amount after discounts; [nights] is how many nights
/// it covers (1 when unknown, which is the same answer as before for a
/// single-night stay). An approximation for a stay whose nights differ in
/// price — the server is the authority there.
double gstOnStay(num total, {int nights = 1}) {
  final n = nights > 0 ? nights : 1;
  return total * gstRateForNight(total / n);
}
