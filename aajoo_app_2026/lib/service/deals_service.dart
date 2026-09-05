import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rent_home/data/ApiConstants.dart';
import 'package:rent_home/models/negotiated_deal.dart';
import 'package:rent_home/models/guest_negotiation.dart';
import '../utils/service_log.dart';

/// Renter's personal negotiated deals (coupons from accepted price offers).
/// GET /user/coupons/list → { data: { coupons: [...] } }. Mirrors the web
/// getMyCoupons() so mobile can show the same "Your negotiated deals" surface
/// and apply the coupon at checkout.
class DealsService {
  // Timeouts, because a stalled request here freezes a button for ever.
  // Accepting a counter shows a per-offer spinner and awaits this call; with no
  // deadline the spinner had no way to stop. Same omission MapService carried
  // behind the search.
  final Dio _dio = Dio(BaseOptions(
    contentType: 'application/json',
    connectTimeout: const Duration(seconds: 20),
    sendTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 30),
  ));

  /// Every negotiation this guest is in, both directions.
  ///
  /// GET /user/negotiations/list. Added 2026-08-23 alongside the web page —
  /// before it, an offer once sent vanished from the guest's view entirely,
  /// and a host's counter reached them only as a live socket event.
  Future<List<GuestNegotiation>> getMyNegotiations() async {
    final token = await const FlutterSecureStorage().read(key: "user_token");
    if (token == null || token.isEmpty) return [];
    _dio.options.headers['Authorization'] = 'Bearer $token';
    try {
      final res = await _dio.get('${Apiconstants.baseUrl}/user/negotiations/list');
      final data = res.data is Map ? res.data['data'] : null;
      final list = (data is Map ? data['negotiations'] : null) ?? [];
      if (list is! List) return [];
      // A successful answer clears the last failure, so a screen that
      // recovered stops showing the retry card.
      ServiceErrors.clear('guestNegotiations');
      return list
          .whereType<Map>()
          .map((e) => GuestNegotiation.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      // A stable key rather than file:line — the screen asks for this
      // exact call by name to tell 'empty' from 'broken'.
      logServiceError('guestNegotiations', e);
      return [];
    }
  }

  /// Send an opening offer on a property.
  ///
  /// POST /user/negotiations/offer — the same endpoint the website's "Send an
  /// Offer" modal posts to (customerApi.sendPropertyOffer). The app used to
  /// open a socket chat instead, which is why it grew a 30-second countdown
  /// and quick-price chips the web never had: two clients negotiating through
  /// two different transports against one engine.
  ///
  /// The server decides the outcome — at or above the host's floor it accepts
  /// and mints the 24-hour coupon itself; below it, the host is asked. The
  /// answer comes back here so the sheet can say which happened.
  Future<OfferOutcome> sendOffer({
    required int propertyId,
    required double offerPrice,
    String? message,
    String? bookFrom,
    String? bookTo,
    int? guests,
  }) async {
    final token = await const FlutterSecureStorage().read(key: "user_token");
    if (token == null || token.isEmpty) {
      return const OfferOutcome.failed('Please sign in to negotiate.');
    }
    _dio.options.headers['Authorization'] = 'Bearer $token';
    try {
      final res = await _dio.post(
        '${Apiconstants.baseUrl}/user/negotiations/offer',
        data: {
          'propertyId': propertyId,
          'offerPrice': offerPrice,
          if (message != null && message.trim().isNotEmpty)
            'message': message.trim(),
          if (bookFrom != null && bookFrom.isNotEmpty) 'bookFrom': bookFrom,
          if (bookTo != null && bookTo.isNotEmpty) 'bookTo': bookTo,
          // Declared server-side or stripUnknown drops it — the same way the
          // dates used to vanish before they were whitelisted.
          if (guests != null && guests > 0) 'guests': guests,
        },
      );
      final body = res.data;
      if (body is! Map || body['success'] != true) {
        return OfferOutcome.failed(
          (body is Map ? body['message']?.toString() : null) ??
              'Could not send that offer.',
        );
      }
      final data = Map<String, dynamic>.from(body['data'] ?? const {});
      return OfferOutcome(
        action: data['action']?.toString() ?? 'escalate_to_host',
        price: (data['price'] as num?)?.toDouble(),
        couponCode: data['couponCode']?.toString(),
        message: data['message']?.toString(),
      );
    } on DioException catch (e) {
      final body = e.response?.data;
      return OfferOutcome.failed(
        (body is Map ? body['message']?.toString() : null) ??
            'Could not send that offer. Check your connection and try again.',
      );
    } catch (_) {
      return const OfferOutcome.failed('Could not send that offer.');
    }
  }

  /// Accept or decline a host's counter. Accepting mints the same 24h personal
  /// coupon the host-accept path mints, so a deal struck either way checks out
  /// identically. Returns null on success, or a message to show the guest.
  Future<String?> respondToNegotiation({
    required int offerId,
    required String action,
    double? counterPrice,
    String? message,
  }) async {
    final token = await const FlutterSecureStorage().read(key: "user_token");
    if (token == null || token.isEmpty) return 'Please sign in again.';
    _dio.options.headers['Authorization'] = 'Bearer $token';
    try {
      final res = await _dio.post(
        '${Apiconstants.baseUrl}/user/negotiations/respond',
        data: {
          'offerId': offerId,
          'action': action,
          if (counterPrice != null) 'counterPrice': counterPrice,
          if (message != null && message.isNotEmpty) 'message': message,
        },
      );
      final ok = res.data is Map && res.data['success'] == true;
      return ok ? null : (res.data is Map ? res.data['message']?.toString() : null) ?? 'Could not send that.';
    } on DioException catch (e) {
      final d = e.response?.data;
      return (d is Map ? d['message']?.toString() : null) ?? 'Could not send that. Please try again.';
    } catch (_) {
      return 'Could not send that. Please try again.';
    }
  }

  Future<List<NegotiatedDeal>> getMyDeals() async {
    final token = await const FlutterSecureStorage().read(key: "user_token");
    if (token == null || token.isEmpty) return [];
    _dio.options.headers['Authorization'] = 'Bearer $token';
    try {
      final res = await _dio.get('${Apiconstants.baseUrl}/user/coupons/list');
      final data = res.data is Map ? res.data['data'] : null;
      final list = (data is Map ? data['coupons'] : null) ?? [];
      if (list is! List) return [];
      ServiceErrors.clear('guestDeals');
      return list
          .map((e) => NegotiatedDeal.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      logServiceError('guestDeals', e);
      return [];
    } catch (e) {
      logServiceError('guestDeals', e);
      return [];
    }
  }

  // Preview ANY coupon (personal or global) at checkout without booking. Returns
  // the discount so the app can show the discounted total before paying; the
  // authoritative apply happens at /booking/create.
  Future<CouponValidation> validateCoupon({
    required String code,
    required int propertyId,
    required double amount,
  }) async {
    final token = await const FlutterSecureStorage().read(key: "user_token");
    if (token == null || token.isEmpty) {
      return CouponValidation(valid: false, message: "Please log in to use a coupon.");
    }
    _dio.options.headers['Authorization'] = 'Bearer $token';
    try {
      final res = await _dio.post('${Apiconstants.baseUrl}/user/coupons/validate',
          data: {"couponCode": code, "propertyId": propertyId, "amount": amount});
      final d = res.data is Map ? res.data['data'] : null;
      if (d is! Map) return CouponValidation(valid: false, message: "Couldn't check that coupon.");
      return CouponValidation(
        valid: d['valid'] == true,
        message: (d['message'] ?? (d['valid'] == true ? "Coupon applied" : "Invalid coupon")).toString(),
        code: d['code']?.toString(),
        discount: double.tryParse((d['discount'] ?? 0).toString()) ?? 0,
        finalPrice: double.tryParse((d['finalPrice'] ?? 0).toString()) ?? 0,
        percent: double.tryParse((d['percent'] ?? 0).toString()) ?? 0,
        type: d['type']?.toString() ?? 'percent',
      );
    } catch (e) {
      return CouponValidation(valid: false, message: "Couldn't check that coupon. Please try again.");
    }
  }
}

class CouponValidation {
  final bool valid;
  final String message;
  final String? code;
  final double discount;
  final double finalPrice;
  /// Percentage off. Double for the same reason NegotiatedDeal.percent is.
  final double percent;
  final String type;
  CouponValidation({
    required this.valid,
    required this.message,
    this.code,
    this.discount = 0,
    this.finalPrice = 0,
    this.percent = 0,
    this.type = 'percent',
  });
}

/// What the server did with an offer.
///
/// `accept` means it cleared the host's floor and the 24-hour coupon already
/// exists; anything else means the host has been asked and will answer.
class OfferOutcome {
  const OfferOutcome({
    required this.action,
    this.price,
    this.couponCode,
    this.message,
    this.error,
  });

  const OfferOutcome.failed(String this.error)
      : action = 'error',
        price = null,
        couponCode = null,
        message = null;

  final String action;
  final double? price;
  final String? couponCode;
  final String? message;
  final String? error;

  bool get accepted => action == 'accept';
  bool get failed => error != null;
}
