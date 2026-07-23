import 'package:get/get.dart';
import 'package:rent_home/models/negotiated_deal.dart';
import 'package:rent_home/service/deals_service.dart';

/// Holds the renter's live negotiated deals (accepted price offers → 24h dated
/// coupons). Mirrors the web dashboard "Your negotiated deals" data source.
class DealsController extends GetxController {
  final DealsService _service = DealsService();
  final RxList<NegotiatedDeal> deals = <NegotiatedDeal>[].obs;
  final RxBool isLoading = false.obs;

  /// Only still-redeemable deals, soonest-expiring first.
  List<NegotiatedDeal> get activeDeals {
    final list = deals.where((d) => d.isActive).toList();
    list.sort((a, b) {
      final av = a.validTo?.millisecondsSinceEpoch ?? 1 << 62;
      final bv = b.validTo?.millisecondsSinceEpoch ?? 1 << 62;
      return av.compareTo(bv);
    });
    return list;
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      deals.value = await _service.getMyDeals();
    } finally {
      isLoading.value = false;
    }
  }

  /// The live deal for a given property (soonest-expiring), or null.
  NegotiatedDeal? forProperty(int? propertyId) {
    if (propertyId == null) return null;
    for (final d in activeDeals) {
      if (d.propertyId == propertyId) return d;
    }
    return null;
  }
}
