import 'package:flutter/material.dart';

import 'package:rent_home/constants.dart';
import 'package:rent_home/ui/design/aajoo_skin.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/utils/money.dart';

/// What a stay costs, said the same way everywhere.
///
/// WHY THIS EXISTS
///
/// The app quoted one booking at two prices. The confirmation screen read
/// `book_total_amt` and said ₹4,200; the booking-detail screen read
/// `book_price` — the pre-tax room subtotal — labelled it "Amount" and said
/// ₹4,000. Both were "the price of this booking", neither said which, and a
/// guest comparing the two had no way to tell whether they had been charged
/// twice, quoted wrongly, or were about to be surprised at the door.
///
/// Two rules, and they hold on every surface:
///
///   1. **The headline number is always the total, tax included.** A figure
///      presented as the price of a stay is what the guest owes. There is no
///      screen on which the subtotal is the answer to "how much is this?".
///   2. **The breakdown is always visible with it.** Room charge, extras,
///      discount, taxes — then the total. A number nobody can decompose is a
///      number a guest has to take on trust, and this is money.
///
/// Both apply whether the stay is paid, unpaid, pay-at-property or cancelled;
/// only the label above the total changes.
class AmountBreakdown extends StatelessWidget {
  const AmountBreakdown({
    super.key,
    required this.roomCharge,
    required this.total,
    this.taxes,
    this.discount = 0,
    this.extras = 0,
    this.nights,
    this.totalLabel = 'Total',
    this.footnote,
    this.dense = false,
  });

  /// The room subtotal, before tax and after any discount is separately shown.
  final double roomCharge;

  /// What the guest owes. The headline.
  final double total;

  /// Taxes and fees. Null derives them — total − room − extras + discount is
  /// the tax by construction — so a caller that only has two of the three
  /// numbers still shows an honest breakdown rather than omitting the line.
  final double? taxes;

  final double discount;

  /// Extra-guest or party charges, when the caller separates them out.
  final double extras;

  /// Shown beside the room charge ("2 nights"), when known.
  final int? nights;

  /// "Total", "Total due", "Total paid" — the total is the same number; this
  /// only says what has happened to it.
  final String totalLabel;

  /// A line under the total, e.g. "Due at the property".
  final String? footnote;

  final bool dense;

  double get _taxes {
    if (taxes != null) return taxes! < 0 ? 0 : taxes!;
    final derived = total - roomCharge - extras + discount;
    return derived > 0 ? derived : 0;
  }

  @override
  Widget build(BuildContext context) {
    return LuxBuilder(
      builder: (context, skin) {
        final gap = SizedBox(height: dense ? 5 : 7);
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(dense ? 12 : 14),
          decoration: BoxDecoration(
            color: skin.isLux ? skin.surface : kCream,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: skin.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row(
                skin,
                nights == null
                    ? 'Room charge'
                    : 'Room charge · ${nights!} night${nights == 1 ? '' : 's'}',
                rupees(roomCharge),
              ),
              if (extras > 0) ...[
                gap,
                _row(skin, 'Extra guests', rupees(extras)),
              ],
              if (discount > 0) ...[
                gap,
                _row(skin, 'Discount', '− ${rupees(discount)}',
                    tone: kSuccess),
              ],
              gap,
              _row(skin, 'Taxes & fees', rupees(_taxes)),
              Padding(
                padding: EdgeInsets.symmetric(vertical: dense ? 8 : 10),
                child: Divider(height: 1, color: skin.line),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(totalLabel,
                      style: fraunces(
                          fontSize: dense ? 14.5 : 16,
                          fontWeight: FontWeight.w700,
                          color: skin.ink)),
                  Text(rupees(total),
                      style: fraunces(
                          fontSize: dense ? 15.5 : 17,
                          fontWeight: FontWeight.w700,
                          color: skin.primary)),
                ],
              ),
              if (footnote != null) ...[
                const SizedBox(height: 4),
                Text(footnote!,
                    style: inter(fontSize: 11.5, color: skin.muted)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _row(AajooSkin skin, String label, String value, {Color? tone}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label,
                style: inter(
                    fontSize: dense ? 12.5 : 13.5, color: tone ?? skin.muted)),
          ),
          const SizedBox(width: 10),
          Text(value,
              style: inter(
                  fontSize: dense ? 12.5 : 13.5,
                  fontWeight: FontWeight.w600,
                  color: tone ?? skin.muted)),
        ],
      );
}
