import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:rent_home/models/host_calendar_model.dart';
import 'package:rent_home/data/ApiConstants.dart';

/// The host calendar's three endpoints, all owner-scoped server-side by
/// property_host_id — a host can only ever read or change their own listing.
///
/// There is no separate host token: /host/* is authorised with the same
/// `user_token` every other call uses, and the host role is a claim inside it.
class HostCalendarService {
  final Dio _dio = Dio();
  final String baseUrl = Apiconstants.baseUrl;

  HostCalendarService() {
    _dio.options.baseUrl = baseUrl;
    _dio.interceptors.add(PrettyDioLogger(
      requestHeader: kDebugMode,
      requestBody: kDebugMode,
      responseBody: kDebugMode,
      responseHeader: false,
      error: true,
      compact: true,
      maxWidth: 90,
      enabled: kDebugMode,
    ));
    _dio.options.contentType = 'application/json';
  }

  Future<void> _authorize() async {
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Stays + manual blocks for one listing, in a single call.
  ///
  /// Throws rather than returning an empty calendar. An empty calendar is a
  /// claim that the whole month is free, and that is the one thing this screen
  /// must never say by accident.
  Future<HostCalendar> getCalendar(int propertyId) async {
    await _authorize();
    final Response<dynamic> response;
    try {
      response = await _dio
          .get('/host/calendar', queryParameters: {'propertyId': propertyId});
    } on DioException catch (err) {
      throw _handleError(err);
    } catch (e) {
      throw _handleError(e);
    }

    final body = response.data;
    final data = body is Map ? body['data'] : null;
    if (data is! Map) {
      throw Exception(
          _messageOf(body) ?? "Couldn't load this listing's calendar.");
    }
    return HostCalendar.fromJson(Map<String, dynamic>.from(data));
  }

  /// Close a range of dates. Dates go out as YYYY-MM-DD.
  ///
  /// Must throw on failure: the server refuses to block dates that already hold
  /// a booking and names the booking in the way ("Those dates include booking
  /// AJ123…"), which is the only fact the host can act on. Swallowing it would
  /// leave them staring at a calendar that silently declined.
  ///
  /// Returns the created block, or null when the server saved it but told us no
  /// id — the caller then refetches, because Unblock needs that id.
  Future<HostCalendarBlock?> blockDates({
    required int propertyId,
    required String from,
    required String to,
    String? reason,
  }) async {
    await _authorize();
    final trimmed = (reason ?? '').trim();
    final Response<dynamic> response;
    try {
      response = await _dio.post('/host/calendar/block', data: {
        'propertyId': propertyId,
        'from': from,
        'to': to,
        if (trimmed.isNotEmpty) 'reason': trimmed,
      });
    } on DioException catch (err) {
      throw _handleError(err);
    } catch (e) {
      throw _handleError(e);
    }

    final body = response.data;
    // A 200 carrying success:false still means the dates were not blocked.
    if (body is Map && body['success'] == false) {
      throw Exception(_messageOf(body) ?? "Couldn't block those dates.");
    }
    final data = body is Map ? body['data'] : null;
    if (data is! Map) return null;
    return HostCalendarBlock.fromJson(Map<String, dynamic>.from(data));
  }

  /// Reopen a blocked range.
  Future<void> unblockDates(int blockId) async {
    await _authorize();
    final Response<dynamic> response;
    try {
      response = await _dio.post('/host/calendar/unblock', data: {'blockId': blockId});
    } on DioException catch (err) {
      throw _handleError(err);
    } catch (e) {
      throw _handleError(e);
    }

    final body = response.data;
    if (body is Map && body['success'] == false) {
      throw Exception(_messageOf(body) ?? "Couldn't unblock those dates.");
    }
  }

  /// The server's own wording. express-validator sends an array of messages,
  /// so a plain toString would show the host `[Instance of ...]`.
  String? _messageOf(dynamic body) {
    final m = body is Map ? body['message'] : null;
    if (m is List) return m.join(', ');
    final s = m?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      final message = _messageOf(error.response?.data) ?? error.message;
      return Exception(message);
    }
    return Exception(error.toString());
  }
}
