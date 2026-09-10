import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:rent_home/data/ApiConstants.dart';
import '../utils/service_log.dart';

/// Change requests waiting on this host.
///
/// Reported 2026-09-10 (bug 28): a guest's request to move their dates was
/// "visible in the booking on the web, but not shown or notified anywhere in
/// the Host app". It was not a display fault — the app had no idea this
/// feature existed. No model, no service, no screen, and nothing calling
/// /host/booking/modifications, which had been serving the website all along.
///
/// This is time-critical in a way an ordinary booking row is not: the nights
/// the guest is asking for are still on sale to everybody else while the host
/// thinks about it, and the request expires. A host who works from their phone
/// had no way to answer one at all.
class BookingModificationService {
  BookingModificationService._();
  static final BookingModificationService instance = BookingModificationService._();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: Apiconstants.baseUrl,
    contentType: 'application/json',
    connectTimeout: const Duration(seconds: 20),
    sendTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 30),
  ));

  Future<Options> _auth() async {
    final token = await const FlutterSecureStorage().read(key: 'user_token');
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  static Map<String, dynamic>? _data(dynamic body) {
    if (body is! Map) return null;
    final d = body['data'];
    return d is Map ? Map<String, dynamic>.from(d) : null;
  }

  /// GET /host/booking/modifications.
  ///
  /// Returns null on failure, never an empty list: "no requests" and "we could
  /// not ask" look identical on screen and only one of them means the host has
  /// nothing to do.
  Future<List<BookingChangeRequest>?> pending() async {
    try {
      final res = await _dio.get('/host/booking/modifications', options: await _auth());
      final d = _data(res.data);
      final raw = d?['modifications'];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => BookingChangeRequest.fromJson(Map<String, dynamic>.from(e)))
          .where((r) => r.status == 'pending')
          .toList();
    } catch (e) {
      logServiceError('booking_modification_service:pending', e);
      return null;
    }
  }

  /// POST /host/booking/modify/respond.
  ///
  /// Returns the server's own sentence. It knows things this screen does not —
  /// that the price moved since the request was made, that the nights went
  /// while the host was deciding — and its wording is the honest answer.
  Future<({bool ok, String message})> respond({
    required int id,
    required bool approve,
    String? note,
  }) async {
    try {
      final res = await _dio.post(
        '/host/booking/modify/respond',
        data: {
          'id': id,
          'approve': approve,
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        },
        options: await _auth(),
      );
      final body = res.data;
      final ok = body is Map && body['success'] == true;
      final msg = body is Map ? (body['message']?.toString() ?? '') : '';
      return (ok: ok, message: msg.isEmpty ? (ok ? 'Done.' : 'That did not go through.') : msg);
    } on DioException catch (e) {
      // A refusal arrives as a 4xx with the reason in the body. Showing "That
      // did not go through" over the top of "the price for those dates has
      // changed" would hide the only useful sentence in the exchange.
      final body = e.response?.data;
      final msg = body is Map ? (body['message']?.toString() ?? '') : '';
      logServiceError('booking_modification_service:respond', e);
      return (ok: false, message: msg.isEmpty ? 'That did not go through.' : msg);
    } catch (e) {
      logServiceError('booking_modification_service:respond', e);
      return (ok: false, message: 'That did not go through.');
    }
  }
}

/// One guest request to change a stay.
class BookingChangeRequest {
  const BookingChangeRequest({
    required this.id,
    required this.bookingId,
    required this.status,
    required this.oldFrom,
    required this.oldTo,
    required this.oldGuests,
    required this.newFrom,
    required this.newTo,
    required this.newGuests,
    required this.difference,
    this.guestNote,
  });

  final int id;
  final int bookingId;
  final String status;
  final String oldFrom;
  final String oldTo;
  final int oldGuests;
  final String newFrom;
  final String newTo;
  final int newGuests;

  /// Positive: the guest owes. Negative: a refund is due.
  final double difference;
  final String? guestNote;

  static int _i(dynamic v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0;
  static double _d(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;

  factory BookingChangeRequest.fromJson(Map<String, dynamic> j) {
    final cur = j['current'] is Map ? Map<String, dynamic>.from(j['current']) : const {};
    final pro = j['proposed'] is Map ? Map<String, dynamic>.from(j['proposed']) : const {};
    return BookingChangeRequest(
      id: _i(j['id']),
      bookingId: _i(j['bookingId']),
      status: (j['status'] ?? '').toString(),
      oldFrom: (cur['from'] ?? '').toString(),
      oldTo: (cur['to'] ?? '').toString(),
      oldGuests: _i(cur['guests']),
      newFrom: (pro['from'] ?? '').toString(),
      newTo: (pro['to'] ?? '').toString(),
      newGuests: _i(pro['guests']),
      difference: _d(j['difference']),
      guestNote: (j['guestNote']?.toString().trim().isEmpty ?? true)
          ? null
          : j['guestNote'].toString().trim(),
    );
  }

  /// What the change does to the money, in the host's favour or not.
  ///
  /// Said in words rather than as a signed number: "-2,400" beside a request
  /// is read as either direction depending on who is looking.
  String get moneyLine {
    if (difference.abs() < 0.5) return 'No change to the total.';
    return difference > 0
        ? 'The guest pays ₹${difference.abs().round()} more.'
        : 'You refund ₹${difference.abs().round()}.';
  }

  bool get datesChanged => oldFrom != newFrom || oldTo != newTo;
  bool get guestsChanged => oldGuests != newGuests;
}
