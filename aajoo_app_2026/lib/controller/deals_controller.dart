import 'package:get/get.dart';
import 'package:rent_home/models/negotiated_deal.dart';
import 'package:rent_home/models/guest_negotiation.dart';
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

  // ── Negotiations (the conversation, not just the resulting coupon) ──────
  // A coupon is the OUTCOME of an accepted offer. Until 2026-08-23 that was
  // the only thing the guest could see, so an offer still being argued over —
  // or countered by the host — was invisible to them entirely.
  final RxList<GuestNegotiation> negotiations = <GuestNegotiation>[].obs;
  final RxBool negotiationsLoading = false.obs;

  /// Threads where the host has countered and the guest holds the next move.
  int get awaitingYouCount =>
      negotiations.where((n) => n.awaitingYou).length;

  Future<void> loadNegotiations() async {
    negotiationsLoading.value = true;
    try {
      negotiations.value = await _service.getMyNegotiations();
    } finally {
      negotiationsLoading.value = false;
    }
  }

  /// Accept or decline a host counter. Returns null on success, else a message.
  Future<String?> respond(int offerId, String action) async {
    final err = await _service.respondToNegotiation(offerId: offerId, action: action);
    if (err == null) {
      await loadNegotiations();
      // An accepted counter mints a coupon, so the deals list is stale now.
      await load();
    }
    return err;
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
