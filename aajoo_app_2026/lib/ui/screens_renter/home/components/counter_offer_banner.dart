import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/ui/design/aajoo_skin.dart';
import 'package:rent_home/utils/lux_mode.dart';
import 'package:rent_home/controller/deals_controller.dart';
import 'package:rent_home/ui/screens_renter/negotiations/guest_negotiations_screen.dart';
import 'package:rent_home/utils/fonts.dart';

/// "The host countered — your move", on the renter home.
///
/// [NegotiatedDealBanner] shows a deal that is already DONE: an accepted offer
/// with a 24-hour coupon waiting to be spent. The state before that had nothing
/// at all. A guest sent an offer, the host answered with a counter, and the only
/// place that said so was a row buried in Profile — so the answer sat there
/// unread while the guest concluded their offer had gone nowhere.
///
/// Deliberately narrow: it appears only when a thread is genuinely waiting on
/// the guest. Threads sitting with the host say nothing here, because there is
/// nothing for the guest to do about those and a banner that is always on stops
/// being read.
class CounterOfferBanner extends StatelessWidget {
  const CounterOfferBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final skin = AajooSkin.of(LuxMode.instance.isOn);
    final DealsController c = Get.isRegistered<DealsController>()
        ? Get.find<DealsController>()
        : Get.put(DealsController());
    return Obx(() {
      final waiting = c.awaitingYouCount;
      if (waiting <= 0) return const SizedBox.shrink();

      // Name the stay when there is exactly one — "The host countered on
      // Malhotra Villa" is worth crossing the screen for; "1 negotiation needs
      // your reply" is not.
      final one = waiting == 1
          ? c.negotiations.firstWhereOrNull((n) => n.awaitingYou)
          : null;
      final title = one != null
          ? 'The host countered on ${one.propertyName}'
          : '$waiting offers need your reply';

      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Get.to(() => const GuestNegotiationsScreen()),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: skin.isLux ? skin.surface : kCream,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kIndigo.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: kIndigo50, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.handshake_outlined,
                      size: 18, color: kIndigo),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: skin.ink)),
                      const SizedBox(height: 2),
                      Text('Answer it before it expires',
                          style: inter(fontSize: 11.5, color: skin.muted)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: skin.muted),
              ],
            ),
          ),
        ),
      );
    });
  }
}
