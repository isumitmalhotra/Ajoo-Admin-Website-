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
import 'package:rent_home/utils/upload_media_type.dart';

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

  /// Statuses that mean the server accepted a submission.
  ///
  /// "verified" is what the approve handler writes, and an admin can approve
  /// between the submit and the check below, so it counts as landed too.
  static const _submittedStates = {
    'submitted', 'approved', 'verified', 'held_for_verification',
  };

  /// Does this status mean the server accepted the submission?
  ///
  /// Public and pure so the rule can be tested without a network. Unknown or
  /// empty reads false: "cannot tell" must not be reported to the host as
  /// success.
  static bool looksSubmitted(String? status) =>
      _submittedStates.contains((status ?? '').trim().toLowerCase());

  /// Is this a failure to REACH the server, as opposed to an answer from it?
  ///
  /// The distinction is the whole point. A 400 saying "accept the
  /// declarations" is an answer and must be shown; a timeout is not, and the
  /// listing has to be read back before anything is concluded from it.
  static bool isTransportFailure(DioException e) =>
      e.response == null &&
      (e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError);

  /// Send for review. All seven declarations must be true.
  ///
  /// A submit that TIMES OUT is not the same as a submit that failed, and this
  /// endpoint is the one place in the wizard where the difference is visible
  /// to the host. Reported as "Submit for Review keeps loading even after the
  /// property is submitted": the server had done the work and the answer never
  /// arrived, so the app sat on a spinner — for up to the three-minute receive
  /// timeout this service sets for photo uploads.
  ///
  /// Two changes. The submit gets its own, much shorter timeout, because it is
  /// a small JSON POST and has no business inheriting an upload's patience.
  /// And when the transport fails, the listing is READ BACK before deciding:
  /// if it now says submitted, the submit worked and the host is told so.
  ///
  /// Only transport failures are recovered this way. An HTTP error response is
  /// the server answering — "you have not accepted the declarations" is a real
  /// answer and must reach the host unchanged.
  Future<Map<String, dynamic>> submit(Map<String, dynamic> payload) async {
    final auth = await _auth();
    try {
      final res = await _dio.post(
        'listing/submit',
        data: payload,
        options: auth.copyWith(
          receiveTimeout: const Duration(seconds: 45),
          sendTimeout: const Duration(seconds: 45),
        ),
      );
      final data = _unwrap(res);
      return data is Map ? Map<String, dynamic>.from(data) : {};
    } on DioException catch (e) {
      final id = payload['property_id'];
      final propertyId = id is int ? id : int.tryParse('${id ?? ''}');
      if (isTransportFailure(e) && propertyId != null) {
        if (await _wasSubmitted(propertyId)) return {};
      }
      _rethrowFriendly(e);
    } catch (e) {
      _rethrowFriendly(e);
    }
  }

  /// Did the submit land after all? Never throws — this runs while another
  /// error is already in flight, and a failure here just means "cannot tell",
  /// which leaves the original error to be reported.
  Future<bool> _wasSubmitted(int propertyId) async {
    try {
      final res = await _dio.get(
        'listing/draft/$propertyId',
        options: (await _auth()).copyWith(
          receiveTimeout: const Duration(seconds: 20),
        ),
      );
      final data = _unwrap(res);
      if (data is! Map) return false;
      final property = data['property'];
      if (property is! Map) return false;
      return looksSubmitted('${property['verification_status'] ?? ''}');
    } catch (_) {
      return false;
    }
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
    /// One description per file, parallel to files exactly as categories is.
    ///
    /// Sending this field at all opts the app into the server's ALT rules: an
    /// empty or useless value is refused rather than quietly stored. That is
    /// the point — a gate only on the client is not a gate.
    List<String> alts = const [],
  }) async {
    try {
      final form = FormData();
      form.fields.add(MapEntry('property_id', '$propertyId'));
      for (var i = 0; i < files.length; i++) {
        form.files.add(MapEntry(
          'files',
          await MultipartFile.fromFile(files[i].path,
              filename: files[i].path.split(Platform.pathSeparator).last,
              contentType: mediaTypeForPath(files[i].path)),
        ));
        form.fields.add(MapEntry(
            'categories', i < categories.length ? categories[i] : ''));
        if (alts.isNotEmpty) {
          form.fields.add(MapEntry('alt', i < alts.length ? alts[i] : ''));
        }
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
            filename: file.path.split(Platform.pathSeparator).last,
            contentType: mediaTypeForPath(file.path)),
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
