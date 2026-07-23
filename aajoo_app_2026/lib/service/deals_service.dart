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
}
