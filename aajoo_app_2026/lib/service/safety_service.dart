import 'package:dio/dio.dart';

import 'package:rent_home/data/ApiConstants.dart';
import 'package:rent_home/service/auth_service.dart';
import 'package:rent_home/utils/app_log.dart';
import 'package:rent_home/utils/secure_store.dart';

/// One option in the report picker.
class SafetyReason {
  const SafetyReason(this.key, this.label);
  final String key;
  final String label;
}

/// What a report attempt did.
///
/// Success carries the reference so the person has something to quote; failure
/// carries a sentence to show them. Deliberately NOT a bool: "it didn't send"
/// is the one outcome this flow must never hide.
class SafetyResult {
  const SafetyResult({
    required this.ok,
    this.reference,
    this.message,
    this.uncertain = false,
  });
  final bool ok;
  final String? reference;
  final String? message;

  /// The request timed out: we do not know whether it arrived.
  ///
  /// Found on a device. The first SOS timed out at twelve seconds, the screen
  /// said "Couldn't send that" — and the ticket was sitting in the admin queue
  /// the whole time. Telling somebody their alert failed when it did not is
  /// worse than a plain failure: they do not follow up, or they raise it again
  /// and support gets two of the same emergency.
  ///
  /// A timeout is UNKNOWN, not FAILED, and this flow is the last place to
  /// blur the two.
  final bool uncertain;
}

/// Safety: the SOS alert and the report flow (audit finding A-2).
///
/// Aajoo cannot dispatch police or an ambulance. The screen dials the real
/// emergency number first; this service is the SECOND thing that happens — it
/// tells Aajoo, with the stay and, where the device allows, the coordinates, so
/// support can act on the listing and reach the host.
class SafetyService {
  SafetyService._();
  static final SafetyService instance = SafetyService._();

  /// Longer than the app's usual budget, deliberately.
  ///
  /// The first report sent from a device timed out at twelve seconds and told
  /// the person it had failed — correct behaviour, and the wrong outcome. The
  /// backend sleeps when idle and its first response after that can take
  /// twenty seconds or more; a safety report is the last request that should
  /// give up while the server is still waking. Thirty seconds, and the person
  /// sees "Sending…" for as long as it takes rather than a failure that was
  /// only impatience.
  final _dio = Dio(BaseOptions(
    baseUrl: Apiconstants.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  /// The reasons a person can pick from.
  ///
  /// Never throws — a form that will not open because a list failed to load is
  /// worse than one with a single "Something else".
  Future<List<SafetyReason>> reasons() async {
    try {
      final res = await _dio.get('/public/safety/reasons');
      final data = res.data is Map ? res.data['data'] : null;
      final raw = data is Map ? data['reasons'] : null;
      if (raw is! List) return const [SafetyReason('other', 'Something else')];
      final list = raw
          .whereType<Map>()
          .map((e) => SafetyReason(
              (e['key'] ?? '').toString(), (e['label'] ?? '').toString()))
          .where((r) => r.key.isNotEmpty && r.label.isNotEmpty)
          .toList();
      return list.isEmpty
          ? const [SafetyReason('other', 'Something else')]
          : list;
    } catch (e) {
      appLog('safety reasons failed: $e', tag: 'safety');
      return const [SafetyReason('other', 'Something else')];
    }
  }

  /// Raise an SOS, or file a report.
  ///
  /// [kind] is 'sos' or 'report'. An SOS may carry no message at all —
  /// somebody pressing it may not be in a position to type.
  Future<SafetyResult> report({
    required String kind,
    String? reason,
    String message = '',
    String? bookingId,
    int? propertyId,
    double? lat,
    double? lng,
  }) async {
    try {
      final token = await secureRead(AuthService().TOKEN_KEY);
      if (token == null || token.isEmpty) {
        return const SafetyResult(
          ok: false,
          message: 'Please sign in so we can reply to you about this.',
        );
      }
      final res = await _dio.post(
        '/user/safety/report',
        data: {
          'kind': kind,
          if (reason != null) 'reason': reason,
          'message': message,
          if (bookingId != null) 'bookingId': bookingId,
          if (propertyId != null) 'propertyId': propertyId,
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final body = res.data is Map ? res.data : const {};
      if (body['success'] == true) {
        final data = body['data'];
        return SafetyResult(
          ok: true,
          reference: data is Map ? data['reference']?.toString() : null,
          message: body['message']?.toString(),
        );
      }
      return SafetyResult(ok: false, message: body['message']?.toString());
    } on DioException catch (e) {
      // The server's own sentence when there is one — it is written for a
      // person, and "Request failed with status code 400" is not.
      final m = e.response?.data is Map ? e.response!.data['message'] : null;
      appLog('safety report failed: ${e.message}', tag: 'safety');

      const timedOut = {
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.sendTimeout,
      };
      if (m == null && timedOut.contains(e.type)) {
        return const SafetyResult(
          ok: false,
          uncertain: true,
          message:
              "We couldn't confirm that was sent — it may still have reached us. "
              'If you are in danger, call 112. Check Help & Support in a minute: '
              'if a ticket is there, we have it.',
        );
      }
      return SafetyResult(
        ok: false,
        message: m?.toString() ??
            "Couldn't send that. If you are in danger, call the emergency number.",
      );
    } catch (e) {
      appLog('safety report failed: $e', tag: 'safety');
      return const SafetyResult(
        ok: false,
        message:
            "Couldn't send that. If you are in danger, call the emergency number.",
      );
    }
  }
}
