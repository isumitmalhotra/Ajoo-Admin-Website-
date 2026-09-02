import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rent_home/data/ApiConstants.dart';
import 'package:rent_home/data/source/remote/dio_config.dart';
import 'package:rent_home/models/traveller_model.dart';
import 'package:rent_home/utils/upload_media_type.dart';

/// Saved travellers — the people an account books stays for.
///
/// Mirrors the web's /guest-profiles layer. A booking names one of these when
/// the person staying is not the person paying; naming nobody means the
/// account holder is the guest, which is the usual case.
///
/// The identity document never travels as a stored URL. It is uploaded as an
/// authenticated Cloudinary asset and read back through a signature that
/// expires in minutes, so [documentUrl] is fetched at the moment of viewing
/// rather than kept anywhere.
class TravellerService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _tokenKey = 'user_token';

  TravellerService() {
    DioConfig.apply(_dio, Apiconstants.baseUrl);
  }

  Future<Options> _auth() async {
    final token = await _storage.read(key: _tokenKey);
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  /// The signed-in account's saved travellers.
  ///
  /// Returns an empty list rather than throwing — an address-book outage
  /// should never be the thing that stops somebody booking.
  Future<List<Traveller>> list() async {
    try {
      final res = await _dio.get('/guest-profiles', options: await _auth());
      final body = res.data;
      if (body is! Map || body['success'] != true) return const [];
      final rows = body['data']?['travellers'];
      if (rows is! List) return const [];
      return rows
          .whereType<Map>()
          .map((e) => Traveller.fromJson(Map<String, dynamic>.from(e)))
          .where((t) => t.id > 0)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Create when [id] is absent, update when present.
  ///
  /// Throws with the server's own message, because the caller shows it: only
  /// the name is required, and the server says so better than a generic
  /// failure would.
  Future<Traveller> save({
    int? id,
    required String fullName,
    String? phone,
    String? email,
    int? age,
    String? gender,
    String? docType,
    String? docNumber,
  }) async {
    final res = await _dio.post(
      '/guest-profiles',
      data: {
        if (id != null) 'id': id,
        'fullName': fullName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (email != null && email.isNotEmpty) 'email': email,
        if (age != null) 'age': age,
        if (gender != null) 'gender': gender,
        if (docType != null && docType.isNotEmpty) 'docType': docType,
        if (docNumber != null && docNumber.isNotEmpty) 'docNumber': docNumber,
      },
      options: await _auth(),
    );
    final body = res.data;
    if (body is! Map || body['success'] != true) {
      throw Exception(body is Map ? (body['message'] ?? 'Could not save') : 'Could not save');
    }
    return Traveller.fromJson(Map<String, dynamic>.from(body['data']['traveller']));
  }

  /// Remove a saved traveller. Throws with the server's own reason.
  ///
  /// This used to fire the request and never look at the answer, so a refusal
  /// — "Traveller not found", an expired token, a dropped connection — was
  /// indistinguishable from success. The caller removed the row on screen
  /// regardless and the traveller came back on the next load, with nothing
  /// said. That is the "I removed them and they are still there" report.
  Future<void> remove(int id) async {
    final res = await _dio.post(
      '/guest-profiles/delete',
      data: {'id': id},
      options: await _auth(),
    );
    final body = res.data;
    if (body is! Map || body['success'] != true) {
      throw Exception(body is Map
          ? (body['message'] ?? 'Could not remove that guest')
          : 'Could not remove that guest');
    }
  }

  /// Attach a government ID. [filePath] is a local path from the file picker.
  Future<Traveller> uploadDocument(int id, String filePath, {String? docType}) async {
    final form = FormData.fromMap({
      'id': id,
      if (docType != null && docType.isNotEmpty) 'docType': docType,
      'document': await MultipartFile.fromFile(
        filePath,
        contentType: mediaTypeForPath(filePath),
      ),
    });
    final res = await _dio.post('/guest-profiles/document', data: form, options: await _auth());
    final body = res.data;
    if (body is! Map || body['success'] != true) {
      throw Exception(body is Map ? (body['message'] ?? 'Upload failed') : 'Upload failed');
    }
    return Traveller.fromJson(Map<String, dynamic>.from(body['data']['traveller']));
  }

  /// A short-lived signed link to a traveller's ID, or null if not permitted.
  ///
  /// Never cached: the signature expires, and a stale link is worse than
  /// asking again.
  Future<String?> documentUrl(int id) async {
    try {
      final res = await _dio.get('/guest-profiles/$id/document', options: await _auth());
      final body = res.data;
      if (body is! Map || body['success'] != true) return null;
      final url = body['data']?['url']?.toString();
      return (url == null || url.isEmpty) ? null : url;
    } catch (_) {
      return null;
    }
  }

  /// The traveller a booking is for — how a host reaches one. Null when the
  /// account holder was the guest, which is not an error.
  Future<Traveller?> forBooking(dynamic bookingId) async {
    try {
      final res = await _dio.get('/guest-profiles/for-booking/$bookingId', options: await _auth());
      final body = res.data;
      if (body is! Map || body['success'] != true) return null;
      final t = body['data']?['traveller'];
      if (t is! Map) return null;
      return Traveller.fromJson(Map<String, dynamic>.from(t));
    } catch (_) {
      return null;
    }
  }
}
