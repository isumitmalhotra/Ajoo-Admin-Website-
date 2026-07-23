import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rent_home/data/ApiConstants.dart';
import 'package:rent_home/models/negotiated_deal.dart';

/// Renter's personal negotiated deals (coupons from accepted price offers).
/// GET /user/coupons/list → { data: { coupons: [...] } }. Mirrors the web
/// getMyCoupons() so mobile can show the same "Your negotiated deals" surface
/// and apply the coupon at checkout.
class DealsService {
  final Dio _dio = Dio(BaseOptions(contentType: 'application/json'));

  Future<List<NegotiatedDeal>> getMyDeals() async {
    final token = await const FlutterSecureStorage().read(key: "user_token");
    if (token == null || token.isEmpty) return [];
    _dio.options.headers['Authorization'] = 'Bearer $token';
    try {
      final res = await _dio.get('${Apiconstants.baseUrl}/user/coupons/list');
      final data = res.data is Map ? res.data['data'] : null;
      final list = (data is Map ? data['coupons'] : null) ?? [];
      if (list is! List) return [];
      return list
          .map((e) => NegotiatedDeal.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (_) {
      return [];
    } catch (_) {
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
        percent: int.tryParse((d['percent'] ?? 0).toString()) ?? 0,
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
  final int percent;
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
