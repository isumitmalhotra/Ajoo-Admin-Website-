import 'package:dio/dio.dart';
import 'package:rent_home/data/ApiConstants.dart';
import 'package:rent_home/models/cancellation_policy.dart';
import 'package:rent_home/utils/service_log.dart';

/// The three public cancellation-policy endpoints. No token: the policy is
/// public before you book, which is the whole point of showing it.
class CancellationPolicyService {
  CancellationPolicyService._();
  static final CancellationPolicyService instance = CancellationPolicyService._();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: '${Apiconstants.baseUrl}/',
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
  ));

  List<CancellationPolicyOption>? _policiesCache;

  /// The five published policies with their rules — static, cached for the
  /// session.
  Future<List<CancellationPolicyOption>> policies() async {
    if (_policiesCache != null) return _policiesCache!;
    try {
      final res = await _dio.get('common/cancellation-policies');
      final data = res.data is Map ? res.data['data'] : null;
      final list = (data is Map ? data['policies'] : null) ?? [];
      if (list is! List) return [];
      _policiesCache = list
          .whereType<Map>()
          .map((e) => CancellationPolicyOption.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      ServiceErrors.clear('cancellationPolicies');
      return _policiesCache!;
    } catch (e) {
      logServiceError('cancellationPolicies', e);
      return [];
    }
  }

  /// One stay's refund ladder as dates. [checkIn] is DD-MM-YYYY, the format
  /// every booking date travels in.
  Future<CancellationSchedule?> schedule(int propertyId, String checkIn) async {
    try {
      final res = await _dio.get('common/cancellation-schedule',
          queryParameters: {'propertyId': propertyId, 'checkIn': checkIn});
      final data = res.data is Map ? res.data['data'] : null;
      if (data is! Map) return null;
      ServiceErrors.clear('cancellationSchedule');
      return CancellationSchedule.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      logServiceError('cancellationSchedule', e);
      return null;
    }
  }

  /// The full policy text, served from one place for the website and the app.
  Future<CancellationPolicyText?> text() async {
    try {
      final res = await _dio.get('common/cancellation-policy');
      final data = res.data is Map ? res.data['data'] : null;
      if (data is! Map) return null;
      ServiceErrors.clear('cancellationPolicyText');
      return CancellationPolicyText.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      logServiceError('cancellationPolicyText', e);
      return null;
    }
  }
}
