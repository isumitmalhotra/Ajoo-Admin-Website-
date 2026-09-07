import 'package:dio/dio.dart';

import 'package:rent_home/data/ApiConstants.dart';
import 'package:rent_home/service/auth_service.dart';
import 'package:rent_home/utils/app_log.dart';
import 'package:rent_home/utils/service_log.dart';
import 'package:rent_home/utils/secure_store.dart';

/// One of the guest's support tickets, as the list shows it.
class GuestTicket {
  const GuestTicket({
    required this.id,
    required this.reference,
    required this.subject,
    required this.category,
    required this.status,
    this.lastReplyAt,
    this.unread = 0,
  });

  final int id;
  final String reference;
  final String subject;
  final String category;
  final String status;
  final DateTime? lastReplyAt;

  /// Replies from support the guest has not opened yet.
  final int unread;

  bool get isSafety => category.toUpperCase() == 'SAFETY';

  static DateTime? _at(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

  factory GuestTicket.fromJson(Map<String, dynamic> j) => GuestTicket(
        id: int.tryParse(j['ticketId']?.toString() ?? '') ?? 0,
        reference: (j['reference'] ?? '').toString(),
        subject: (j['subject'] ?? '').toString(),
        category: (j['category'] ?? '').toString(),
        status: (j['status'] ?? 'OPEN').toString(),
        lastReplyAt: _at(j['lastReplyAt'] ?? j['createdAt']),
        unread: int.tryParse(j['unread']?.toString() ?? '') ?? 0,
      );
}

/// One message in a ticket. `mine` is true for the guest's own.
class TicketMessage {
  const TicketMessage({required this.mine, required this.body, this.at});
  final bool mine;
  final String body;
  final DateTime? at;

  factory TicketMessage.fromJson(Map<String, dynamic> j) => TicketMessage(
        // The server says 'you' or 'support' — whether an admin or an agent
        // typed it is deliberately not the guest's business.
        mine: (j['from'] ?? '').toString() == 'you',
        body: (j['message'] ?? '').toString(),
        at: j['createdAt'] == null
            ? null
            : DateTime.tryParse(j['createdAt'].toString())?.toLocal(),
      );
}

/// The guest's own support tickets — including safety reports.
///
/// The app had no screen for these at all: tickets could be RAISED (the safety
/// flow, the chatbot) and the reply had nowhere to appear. The safety screen
/// told people "you can follow it in Help & Support" and Help & Support was an
/// FAQ. The website has had the list, the thread and the reply box for months;
/// this is the same three things.
class GuestTicketService {
  GuestTicketService._();
  static final GuestTicketService instance = GuestTicketService._();

  final _dio = Dio(BaseOptions(
    baseUrl: Apiconstants.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  Future<Options?> _auth() async {
    final token = await secureRead(AuthService().TOKEN_KEY);
    if (token == null || token.isEmpty) return null;
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  /// The guest's tickets, newest first.
  ///
  /// NULL means the request failed; an empty list means there are none. They
  /// are different things and this used to return `[]` for both — so a failed
  /// load drew "Nothing here yet" over a ticket the card on the previous
  /// screen had just counted. That is the trap utils/service_log.dart was
  /// written for, repeated: an empty state is indistinguishable from a broken
  /// one, and the person concludes their report vanished.
  Future<List<GuestTicket>?> list() async {
    try {
      final opts = await _auth();
      if (opts == null) return const [];
      final res = await _dio.post('/user/support/tickets/search',
          data: {'page': 1, 'limit': 50}, options: opts);
      final data = res.data is Map ? res.data['data'] : null;
      final raw = data is Map ? data['tickets'] : null;
      // A 200 with no list is a shape we do not understand — not "none".
      if (raw is! List) return null;
      return raw
          .whereType<Map>()
          .map((e) => GuestTicket.fromJson(Map<String, dynamic>.from(e)))
          .where((t) => t.id > 0)
          .toList();
    } catch (e) {
      logServiceError('guestTickets.list', e);
      return null;
    }
  }

  /// One thread. Opening it marks support's replies read, server-side.
  Future<List<TicketMessage>?> thread(int ticketId) async {
    try {
      final opts = await _auth();
      if (opts == null) return null;
      final res = await _dio.get('/user/support/tickets/$ticketId',
          options: opts);
      final data = res.data is Map ? res.data['data'] : null;
      final raw = data is Map ? data['messages'] : null;
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => TicketMessage.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      appLog('guest ticket thread failed: $e', tag: 'support');
      return null;
    }
  }

  /// Reply on a ticket. True when it was accepted.
  Future<bool> reply(int ticketId, String message) async {
    try {
      final opts = await _auth();
      if (opts == null) return false;
      final res = await _dio.post('/user/support/tickets/reply',
          data: {'ticketId': ticketId, 'message': message}, options: opts);
      return res.data is Map && res.data['success'] == true;
    } catch (e) {
      appLog('guest ticket reply failed: $e', tag: 'support');
      return false;
    }
  }
}
