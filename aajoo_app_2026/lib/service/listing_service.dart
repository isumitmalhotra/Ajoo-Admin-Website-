// The listing engine's API, from the app.
//
// One-for-one with the website's services/listingApi.ts, hitting the same
// endpoints in the same order: /listing/schema to draw the form, /listing/step1
// to create the draft and hand back a property_id, steps 2–5 to fill it in,
// /listing/readiness to score it, and /listing/submit to send it for review.
//
// Each step is saved as the host leaves it rather than everything at the end,
// which is what makes the wizard resumable: a draft exists from step 1 onward,
// so a dropped connection or a closed app costs one step, not the whole
// listing.
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rent_home/models/listing_schema.dart';
import 'package:rent_home/data/ApiConstants.dart';

/// What went wrong, in words the host can act on.
class ListingException implements Exception {
  ListingException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ListingService {
  ListingService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.contentType = 'application/json';
    // Never wait forever. Dio's default timeout is null, and this wizard
    // uploads photos — a stalled request would leave the host on a spinner
    // with no error and no way back, which is exactly the failure the
    // property service documents.
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(minutes: 3);
    _dio.options.receiveTimeout = const Duration(minutes: 3);
  }

  final Dio _dio = Dio();
  final String baseUrl = '${Apiconstants.baseUrl}/';
  final _storage = const FlutterSecureStorage();

  Future<Options> _auth() async {
    final token = await _storage.read(key: 'user_token');
    return Options(headers: {
      if (token != null) 'Authorization': 'Bearer $token',
    });
  }

  /// The server wraps everything as { success, message, data }.
  ///
  /// A `success: false` body still arrives as HTTP 200 on this API, so the
  /// envelope has to be read rather than the status code — otherwise a
  /// rejected step looks like a saved one.
  dynamic _unwrap(Response res) {
    final body = res.data;
    if (body is Map) {
      if (body['success'] == false) {
        final msg = body['message'];
        throw ListingException(
          msg is List ? msg.join(', ') : (msg ?? 'Request failed').toString(),
        );
      }
      return body['data'] ?? body;
    }
    return body;
  }

  /// Turn a transport failure into something worth showing a host.
  Never _rethrowFriendly(Object e) {
    if (e is ListingException) throw e;
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        final m = data['message'];
        throw ListingException(m is List ? m.join(', ') : m.toString());
      }
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          throw ListingException(
              'The server took too long to answer. Check your connection and try again.');
        case DioExceptionType.connectionError:
          throw ListingException(
              "Couldn't reach Aajoo. Check your connection and try again.");
        default:
          throw ListingException(e.message ?? 'Something went wrong.');
      }
    }
    throw ListingException(e.toString());
  }

  // ── Schema ────────────────────────────────────────────────────────────────

  /// Cached for the life of the app: the schema is a definition, not data, and
  /// re-fetching it on every step made the wizard feel slower than it is.
  static ListingSchema? _cached;

  Future<ListingSchema> getSchema({bool refresh = false}) async {
    if (_cached != null && !refresh) return _cached!;
    try {
      final res = await _dio.get('listing/schema', options: await _auth());
      final data = _unwrap(res);
      if (data is! Map) {
        throw ListingException('The listing form could not be loaded.');
      }
      return _cached = ListingSchema.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      _rethrowFriendly(e);
    }
  }

  // ── Steps ─────────────────────────────────────────────────────────────────

  /// Creates the draft (no property_id) or updates it (with one), and returns
  /// the property_id every later step is keyed on.
  Future<int> saveStep1(Map<String, dynamic> payload) async {
    final data = await _post('listing/step1', payload);
    final id = data is Map ? data['propertyId'] : null;
    final parsed = id is num ? id.toInt() : int.tryParse('${id ?? ''}');
    if (parsed == null) {
      throw ListingException('The server did not return a listing id.');
    }
    return parsed;
  }

  Future<void> saveStep2(Map<String, dynamic> payload) =>
      _post('listing/step2', payload);

  Future<Map<String, dynamic>> saveStep3(Map<String, dynamic> payload) async {
    final data = await _post('listing/step3', payload);
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  Future<void> saveStep4(Map<String, dynamic> payload) =>
      _post('listing/step4', payload);

  Future<void> saveStep5(Map<String, dynamic> payload) =>
      _post('listing/step5', payload);

  Future<dynamic> _post(String path, Map<String, dynamic> payload) async {
    try {
      final res = await _dio.post(path, data: payload, options: await _auth());
      return _unwrap(res);
    } catch (e) {
      _rethrowFriendly(e);
    }
  }

  // ── Draft, readiness, submit ──────────────────────────────────────────────

  /// Everything already saved for a listing, so the wizard can be reopened.
  Future<Map<String, dynamic>> getDraft(int propertyId) async {
    try {
      final res =
          await _dio.get('listing/draft/$propertyId', options: await _auth());
      final data = _unwrap(res);
      return data is Map ? Map<String, dynamic>.from(data) : {};
    } catch (e) {
      _rethrowFriendly(e);
    }
  }

  /// The completeness score, what is missing, and whether it can be submitted.
  Future<Map<String, dynamic>> getReadiness(int propertyId) async {
    try {
      final res = await _dio.get('listing/readiness/$propertyId',
          options: await _auth());
      final data = _unwrap(res);
      return data is Map ? Map<String, dynamic>.from(data) : {};
    } catch (e) {
      _rethrowFriendly(e);
    }
  }

  /// Send for review. All seven declarations must be true.
  Future<Map<String, dynamic>> submit(Map<String, dynamic> payload) async {
    final data = await _post('listing/submit', payload);
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  // ── Media ─────────────────────────────────────────────────────────────────

  /// Uploads APPEND to the listing — they never replace what is already there.
  ///
  /// Returns the media list and the photo readiness the server calculated, so
  /// the step can say "10 of 10" without counting locally and disagreeing.
  Future<Map<String, dynamic>> uploadMedia({
    required int propertyId,
    required List<File> files,
    required List<String> categories,
  }) async {
    try {
      final form = FormData();
      form.fields.add(MapEntry('property_id', '$propertyId'));
      for (var i = 0; i < files.length; i++) {
        form.files.add(MapEntry(
          'files',
          await MultipartFile.fromFile(files[i].path,
              filename: files[i].path.split(Platform.pathSeparator).last),
        ));
        form.fields.add(MapEntry(
            'categories', i < categories.length ? categories[i] : ''));
      }
      final res = await _dio.post('listing/media/upload',
          data: form, options: await _auth());
      final data = _unwrap(res);
      return data is Map ? Map<String, dynamic>.from(data) : {};
    } catch (e) {
      _rethrowFriendly(e);
    }
  }

  /// One verification document (identity or ownership proof) → its URL.
  Future<String?> uploadDocument({
    required int propertyId,
    required File file,
  }) async {
    try {
      final form = FormData.fromMap({
        'property_id': '$propertyId',
        'kind': 'document',
        'files': await MultipartFile.fromFile(file.path,
            filename: file.path.split(Platform.pathSeparator).last),
      });
      final res = await _dio.post('listing/media/upload',
          data: form, options: await _auth());
      final data = _unwrap(res);
      if (data is Map && data['uploaded'] is List) {
        final first = (data['uploaded'] as List).firstOrNull;
        if (first is Map) return first['url']?.toString();
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('uploadDocument failed: $e');
      _rethrowFriendly(e);
    }
  }

  Future<Map<String, dynamic>> deleteMedia(int mediaId) async {
    try {
      final res =
          await _dio.delete('listing/media/$mediaId', options: await _auth());
      final data = _unwrap(res);
      return data is Map ? Map<String, dynamic>.from(data) : {};
    } catch (e) {
      _rethrowFriendly(e);
    }
  }
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
