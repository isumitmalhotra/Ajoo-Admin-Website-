/// The host's cleaning fee, said the same way everywhere.
///
/// STATED, not charged. Client decision, 2026-09-15 (master list §1.14),
/// answering "is the cleaning fee charged, or only stated?": "it will only be
/// stated in Things to know and all; if the renter requested it, it can be
/// availed at that price and payments will be taken directly by the host."
///
/// So the figure never enters a total: not on the booking sheet, not in the
/// price the app sends. It is a fact about the listing, in the same position
/// as the security deposit — below the total and outside it — and a line
/// under Things to know so a guest reads it before they pick dates. One
/// sentence, built here, word for word the website's
/// (`src/redesign/lib/cleaningFee.ts`), so the two platforms cannot drift
/// into two phrasings of one fee. (Builds 88–93 charged it; the server
/// recognises the price they send and charges without it.)
library;

import 'money.dart';

/// "per night" or "per stay" — the two ways a host can mean it.
String cleaningFeeUnit(String? type) =>
    (type ?? '').toLowerCase() == 'per_night' ? 'per night' : 'per stay';

/// The statement for a stay, given the PER-UNIT figure the host set.
///
/// With [nights] on a per-night fee the sentence also gives the stay's
/// figure, because "₹500 per night" against a fortnight is a number worth
/// seeing. Empty when there is no fee, so a caller can test `isNotEmpty`.
String cleaningFeeStatement(num fee, String? type, {int nights = 0}) {
  final amount = fee.isFinite && fee > 0 ? fee : 0;
  if (amount <= 0) return '';
  final unit = cleaningFeeUnit(type);
  final String figure;
  if (unit == 'per night' && nights > 1) {
    figure = '${rupees(amount)} per night '
        '(${rupees(amount * nights)} for $nights nights)';
  } else if (unit == 'per night') {
    figure = '${rupees(amount)} per night';
  } else {
    figure = rupees(amount);
  }
  return 'The host charges $figure for cleaning if you ask for it — '
      'arranged and paid directly with them, not included in this total.';
}

/// The short form for Things to know, where there are no dates yet.
String cleaningFeeRule(num fee, String? type) {
  final amount = fee.isFinite && fee > 0 ? fee : 0;
  if (amount <= 0) return '';
  return 'Cleaning available at ${rupees(amount)} ${cleaningFeeUnit(type)}, '
      'paid to the host';
}
