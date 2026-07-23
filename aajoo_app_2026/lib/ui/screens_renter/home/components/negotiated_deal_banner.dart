import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/controller/deals_controller.dart';
import 'package:rent_home/controller/user_controller.dart';
import 'package:rent_home/models/negotiated_deal.dart';
import 'package:rent_home/models/properties_response_model.dart';
import 'package:rent_home/ui/screens_renter/property_details/property_page.dart';

/// Compact "you have a negotiated deal" banner for the renter home — the mobile
/// mirror of the web dashboard "Your negotiated deals" card. Shows the most
/// urgent active deal (24h coupon from an accepted offer). Tapping fetches the
/// sanctioned property and opens it with the agreed dates + coupon pre-filled,
/// so the renter never has to hunt for the listing again.
class NegotiatedDealBanner extends StatelessWidget {
  const NegotiatedDealBanner({super.key});

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
    Get.dialog(const Center(child: CircularProgressIndicator()),
        barrierDismissible: false);
    try {
      final userController = Get.find<UserController>();
      await userController.getProperty(deal.propertyId!);
      final resp = userController.property.value;
      if (Get.isDialogOpen ?? false) Get.back();
      final pd = resp?.data;
      if (pd == null) {
        Get.snackbar('Deal', 'Could not open this property. Please try again.',
            snackPosition: SnackPosition.TOP);
        return;
      }
      final property = Property(
        propertyId: pd.propertyId ?? deal.propertyId!,
        propertyName: pd.propertyName ?? deal.propertyName ?? 'Property',
        propertyAddress: pd.propertyAddress ?? '',
        propertyDesc: pd.propertyDesc ?? '',
        propertyPrice: pd.propertyPrice ?? '0',
        propertyCity: pd.propertyCity ?? '',
        propertyLongitude: pd.propertyLongitude ?? '0.0',
        propertyLatitude: pd.propertyLatitude ?? '0.0',
        propertyHostId: pd.propertyHostId ?? 0,
        propertyZip: pd.propertyZip,
        propertyContact: pd.propertyContact,
        propDetailsPropDetailIsPetFriendly: pd.propDetails?.isPetFriendly,
        propDetailsPropDetailIsSmoke: pd.propDetails?.isSmoke,
        propDetailsPropDetailInTime: pd.propDetails?.inTime,
        propDetailsPropDetailOutTime: pd.propDetails?.outTime,
        propDetailsPropDetailExtra: pd.propDetails?.extra,
        coverImage: (pd.images != null && pd.images!.isNotEmpty)
            ? pd.images!.first.toString()
            : null,
        images: (pd.images ?? const []).map((e) => e.toString()).toList(),
        categoryTitles: const [],
        tags: pd.tags?.map((e) => e.toString()).toList(),
        categories: pd.categories?.map((e) => e.toString()).toList(),
        amenities: pd.amenities?.map((e) => e.toString()).toList(),
      );
      Get.to(() => PropertyPage(
            property: property,
            price: property.propertyPrice,
            name: property.propertyName,
            location: property.propertyAddress,
            image: property.coverImage ?? '',
            id: property.propertyId,
            rating: '4.5',
            description: property.propertyDesc,
            lat: property.propertyLatitude,
            long: property.propertyLongitude,
            galleryImages: property.images.map((e) => e.toString()).toList(),
            inTime: property.propDetailsPropDetailInTime,
            outTime: property.propDetailsPropDetailOutTime,
            dealCode: deal.code,
            dealFrom: deal.bookFrom,
            dealTo: deal.bookTo,
            dealPercent: deal.percent,
          ));
    } catch (_) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar('Deal', 'Could not open this property. Please try again.',
          snackPosition: SnackPosition.TOP);
    }
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
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openDeal(deal),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: kCream,
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
                    deal.isPercent ? '${deal.percent}% OFF' : '₹${deal.amount.toStringAsFixed(0)} OFF',
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
                        style: const TextStyle(
                            color: kInk,
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
      );
    });
  }
}
