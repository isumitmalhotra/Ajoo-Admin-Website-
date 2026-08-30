import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rent_home/data/ApiConstants.dart';

/// KYC verification (DIDIT) API client — mirrors the web `/verify/*` flow.
///
/// Contexts: `renter_kyc` (verify once at signup), `host_kyc` (host listing),
/// `guest_kyc` (at booking — requires a bookingId). The backend stores the
/// session id on the user/booking and resolves the decision via webhook +
/// the check-session pull.
class VerifyService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String baseUrl = Apiconstants.baseUrl;
  final String _tokenKey = 'user_token';

  VerifyService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  Future<String?> _token() => _storage.read(key: _tokenKey);

  /// Starts a DIDIT session. Returns
  /// `{sessionId, sessionUrl, stub, alreadyVerified}`.
  ///
  /// `sessionUrl` is null in two very different situations, and the caller has
  /// to tell them apart: DIDIT is not configured server-side (`stub`), or the
  /// user is already verified inside the 90-day window and the server skipped
  /// the session (`alreadyVerified`). Both used to arrive as a bare null URL,
  /// so someone who was verified and asked to redo their KYC was told identity
  /// verification was temporarily unavailable (A-66).
  ///
  /// [force] re-verifies on purpose, ignoring that skip. Use it only when the
  /// user has explicitly asked to redo KYC.
  Future<Map<String, dynamic>> createSession({
    required String context,
    int? bookingId,
    bool force = false,
  }) async {
    final token = await _token();
    final res = await _dio.post(
      '/verify/create-session',
      data: {
        'context': context,
        if (bookingId != null) 'bookingId': bookingId,
        if (force) 'force': true,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final data = (res.data is Map ? res.data['data'] : null) ?? {};
    return {
      'sessionId': data['sessionId'],
      'sessionUrl': data['sessionUrl'],
      'stub': data['stub'] == true,
      'alreadyVerified': data['status']?.toString() == 'verified',
    };
  }

  /// Active pull — hits DIDIT directly, applies the decision, returns status.
  /// Use this first so we don't depend on the webhook having landed yet.
  Future<String> checkSession(String sessionId) async {
    final token = await _token();
    final res = await _dio.get(
      '/verify/check-session/$sessionId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return _statusOf(res.data);
  }

  /// DB-backed status (webhook-driven).
  Future<String> getStatus(String sessionId) async {
    final token = await _token();
    final res = await _dio.get(
      '/verify/status',
      queryParameters: {'sessionId': sessionId},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return _statusOf(res.data);
  }

  String _statusOf(dynamic body) {
    if (body is Map) {
      final data = body['data'];
      if (data is Map && data['status'] != null) return data['status'].toString();
      if (body['status'] != null) return body['status'].toString();
    }
    return 'pending';
  }
}
