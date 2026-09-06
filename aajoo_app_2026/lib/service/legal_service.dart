import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rent_home/data/ApiConstants.dart';
import 'package:rent_home/models/legal_document.dart';
import 'package:rent_home/utils/service_log.dart';

/// Legal documents, and the record of who accepted them.
///
/// The Host Agreement's Developer Requirements ask for four things. Two of
/// them belong here: the host has to be able to READ the agreement (so the
/// text comes from the server, never from a copy compiled into this build),
/// and accepting it has to be recorded with a version, a timestamp, an IP and
/// the device — all of which the server takes from the request itself. This
/// client only says WHICH document was accepted.
class LegalService {
  LegalService._();
  static final LegalService instance = LegalService._();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: '${Apiconstants.baseUrl}/',
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
  ));

  final _storage = const FlutterSecureStorage();

  final Map<String, LegalDocument> _cache = {};

  /// The document text. Public — an agreement you must sign in to read is not
  /// published. Cached for the session; a version never changes under a key.
  Future<LegalDocument?> document(String key) async {
    final hit = _cache[key];
    if (hit != null) return hit;
    try {
      final res = await _dio.get('legal/document/$key');
      final body = res.data;
      if (body is! Map || body['success'] != true) return null;
      final doc = LegalDocument.fromJson(body['data']);
      if (doc != null) {
        _cache[key] = doc;
        ServiceErrors.clear('legalDocument');
      }
      return doc;
    } catch (e) {
      logServiceError('legalDocument', e);
      return null;
    }
  }

  /// What this host still owes. Empty on any failure, matching the server,
  /// which also fails open here: a question we could not ask must never lock a
  /// host out of their own portal. The hard gate is server-side on publish.
  Future<List<OutstandingLegal>> outstanding() async {
    final token = await _storage.read(key: 'user_token');
    if (token == null || token.isEmpty) return [];
    try {
      final res = await _dio.get(
        'host/legal/status',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final body = res.data;
      if (body is! Map || body['success'] != true) return [];
      final list = (body['data'] is Map) ? body['data']['outstanding'] : null;
      if (list is! List) return [];
      return list
          .map(OutstandingLegal.fromJson)
          .whereType<OutstandingLegal>()
          .toList();
    } catch (e) {
      logServiceError('legalStatus', e);
      return [];
    }
  }

  /// Record acceptance. Returns null on success, or a message to show.
  ///
  /// The version is NOT sent: the server writes its own current one. A client
  /// that supplied it could accept a version that no longer exists, which is
  /// the one thing this ledger has to be able to answer honestly.
  Future<String?> accept(String key, {String context = 'listing_publish'}) async {
    final token = await _storage.read(key: 'user_token');
    if (token == null || token.isEmpty) return 'Please sign in again.';
    try {
      final res = await _dio.post(
        'host/legal/accept',
        data: {
          'document': key,
          'accepted': true,
          'platform': 'app',
          'context': context,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final body = res.data;
      if (body is Map && body['success'] == true) return null;
      return (body is Map ? body['message']?.toString() : null) ??
          "We couldn't record your acceptance. Please try again.";
    } catch (e) {
      logServiceError('legalAccept', e);
      return "We couldn't record your acceptance. Please check your connection and try again.";
    }
  }
}
