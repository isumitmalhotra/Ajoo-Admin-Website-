import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/ui/design/aajoo_skin.dart';
import 'package:rent_home/controller/deals_controller.dart';
import 'package:rent_home/models/negotiated_deal.dart';
import 'package:rent_home/ui/screens_renter/property_details/open_property.dart';

/// Compact "you have a negotiated deal" banner for the renter home — the mobile
/// mirror of the web dashboard "Your negotiated deals" card. Shows the most
/// urgent active deal (24h coupon from an accepted offer). Tapping fetches the
/// sanctioned property and opens it with the agreed dates + coupon pre-filled,
/// so the renter never has to hunt for the listing again.
class NegotiatedDealBanner extends StatelessWidget {
  const NegotiatedDealBanner({super.key});

  /// A percentage as a person would write it — "10", not "10.0".
  static String _pctLabel(double v) {
    final r = (v * 100).round() / 100;
    return r == r.roundToDouble() ? r.toStringAsFixed(0) : r.toString();
  }

  static String _pretty(String? dmy) {
    if (dmy == null || dmy.isEmpty) return '';
    try {
      final p = dmy.split('-');
      final d = DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
      return DateFormat('d MMM').format(d);
    } catch (_) {
      return dmy;
    }
  }

  Future<void> _openDeal(NegotiatedDeal deal) async {
    if (deal.propertyId == null) return;
    // Fetch + shape + navigate lives in openPropertyById — the same sequence
    // the blog's "stay in this story" card uses, so the two cannot drift.
    await openPropertyById(
      deal.propertyId!,
      dealCode: deal.code,
      dealFrom: deal.bookFrom,
      dealTo: deal.bookTo,
      dealPercent: deal.percent,
      errorTitle: 'Deal',
    );
  }

  @override
  Widget build(BuildContext context) {
    final DealsController c = Get.find<DealsController>();
    return Obx(() {
      final active = c.activeDeals;
      if (active.isEmpty) return const SizedBox.shrink();
      final deal = active.first;
      final left = deal.countdown;
      final dates = deal.hasDates
          ? '${_pretty(deal.bookFrom)} → ${_pretty(deal.bookTo)}'
          : null;
      // Floats over the map, so in LUX a Warm Ivory bar was a white slab
      // hanging in the middle of a black screen. The green rule stays — it is
      // status, not brand, and a live deal reads the same in both modes.
      return LuxBuilder(builder: (context, skin) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openDeal(deal),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: skin.isLux ? skin.surface : kCream,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kSuccess),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kSuccess,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    deal.isPercent ? '${_pctLabel(deal.percent)}% OFF' : '₹${deal.amount.toStringAsFixed(0)} OFF',
                    style: const TextStyle(
                        color: kCream,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deal.propertyName ?? 'Your negotiated deal',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: inter(
                            color: skin.ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        [
                          if (dates != null) dates,
                          if (left != null) '⏳ $left left' else 'Expiring',
                        ].join('  ·  '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: left != null ? kClay600 : kDanger,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: kClay,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text('Book now',
                      style: TextStyle(
                          color: kCream,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ));
    });
  }
}
