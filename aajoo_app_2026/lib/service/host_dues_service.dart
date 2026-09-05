import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:rent_home/data/ApiConstants.dart';
import '../utils/service_log.dart';

/// Pay-at-property settlement — what a host owes the platform, and paying it.
///
/// On a cash booking the guest hands the whole amount to the host at the door,
/// so Aajoo's commission, the GST on it, and the accommodation GST we remit
/// all have to come back the other way. The web portal got this screen first;
/// without it here, a host who works from their phone would have met the
/// charge for the first time as a smaller payout.
///
/// Nothing in this file sends an amount. The server sums what is owed from its
/// own rows — a client that could name the figure would be a client that
/// decides what it owes.
class HostDuesService {
  HostDuesService._();
  static final HostDuesService instance = HostDuesService._();

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

  /// GET /host/dues. Returns null on failure — the caller must be able to tell
  /// "nothing owed" from "we could not ask", because those look identical on
  /// screen and only one of them is good news.
  Future<HostDues?> load() async {
    try {
      final res = await _dio.get('/host/dues', options: await _auth());
      final d = _data(res.data);
      return d == null ? null : HostDues.fromJson(d);
    } catch (e) {
      logServiceError('host_dues_service:48', e);
      return null;
    }
  }

  /// POST /host/dues/pay — settles everything currently payable. No due ids
  /// are sent: the server picks the rows and totals them.
  Future<DuesOrder> startPayment() async {
    try {
      final res = await _dio.post('/host/dues/pay',
          data: const <String, dynamic>{}, options: await _auth());
      final d = _data(res.data);
      if (d == null) return const DuesOrder.failed('Could not start the payment.');
      return DuesOrder.fromJson(d);
    } on DioException catch (e) {
      final m = e.response?.data;
      return DuesOrder.failed((m is Map ? m['message']?.toString() : null) ??
          'Could not start the payment. Please try again.');
    } catch (_) {
      return const DuesOrder.failed(
          'Could not start the payment. Please try again.');
    }
  }

  /// POST /host/dues/verify. Returns null on success, a sentence on failure.
  ///
  /// The due ids come from the order rather than from whatever is outstanding
  /// now, so what gets settled is exactly what was charged.
  Future<String?> verify({
    required String orderId,
    required String paymentId,
    required String signature,
    required List<int> dueIds,
  }) async {
    try {
      final res = await _dio.post(
        '/host/dues/verify',
        data: {
          'orderId': orderId,
          'paymentId': paymentId,
          'signature': signature,
          'dueIds': dueIds,
        },
        options: await _auth(),
      );
      final ok = res.data is Map && res.data['success'] == true;
      return ok ? null : 'We could not confirm that payment.';
    } on DioException catch (e) {
      final m = e.response?.data;
      return (m is Map ? m['message']?.toString() : null) ??
          'We could not confirm that payment.';
    } catch (_) {
      return 'We could not confirm that payment.';
    }
  }
}

num _n(Object? v) => v is num ? v : num.tryParse('${v ?? ''}') ?? 0;

/// One stay's charge, kept in its three parts.
///
/// Stored separately rather than as a total because they are genuinely
/// different things — our fee, tax on our fee, and tax we remit on the host's
/// behalf — and a host asked for money on cash they already hold needs to be
/// able to check the arithmetic.
class HostDue {
  const HostDue({
    required this.dueId,
    required this.bookingCode,
    required this.property,
    required this.stayFrom,
    required this.stayTo,
    required this.collectedFromGuest,
    required this.commission,
    required this.gstOnCommission,
    required this.accommodationGst,
    required this.amount,
    required this.payableNow,
  });

  final int dueId;
  final String bookingCode;
  final String property;
  final String stayFrom;
  final String stayTo;
  final num collectedFromGuest;
  final num commission;
  final num gstOnCommission;
  final num accommodationGst;
  final num amount;

  /// False until the stay has started. An unstarted stay is not billed yet.
  final bool payableNow;

  /// What the host is left with. Equal, to the rupee, to an online booking of
  /// the same value — which is the reassurance the screen exists to give.
  num get hostKeeps {
    final left = collectedFromGuest - amount;
    return left < 0 ? 0 : left;
  }

  factory HostDue.fromJson(Map<String, dynamic> j) {
    final stay = j['stay'] is Map ? Map<String, dynamic>.from(j['stay']) : const {};
    final b = j['breakdown'] is Map
        ? Map<String, dynamic>.from(j['breakdown'])
        : const {};
    return HostDue(
      dueId: _n(j['dueId']).toInt(),
      bookingCode: '${j['bookingCode'] ?? ''}',
      property: '${j['property'] ?? 'Your property'}',
      stayFrom: '${stay['from'] ?? ''}',
      stayTo: '${stay['to'] ?? ''}',
      collectedFromGuest: _n(j['collectedFromGuest']),
      commission: _n(b['commission']),
      gstOnCommission: _n(b['gstOnCommission']),
      accommodationGst: _n(b['accommodationGst']),
      amount: _n(j['amount']),
      payableNow: j['payableNow'] == true,
    );
  }
}

/// A settlement that is already done. "Paid" and "withheld from a payout" are
/// the same rupees and very different facts, so [how] is kept.
class SettledDue {
  const SettledDue({
    required this.bookingCode,
    required this.amount,
    required this.how,
    required this.settledAt,
    required this.reference,
  });

  final String bookingCode;
  final num amount;
  final String how;
  final String settledAt;
  final String reference;

  factory SettledDue.fromJson(Map<String, dynamic> j) => SettledDue(
        bookingCode: '${j['bookingCode'] ?? ''}',
        amount: _n(j['amount']),
        how: '${j['how'] ?? 'Settled'}',
        settledAt: '${j['settledAt'] ?? ''}',
        reference: '${j['reference'] ?? ''}',
      );
}

class HostDues {
  const HostDues({
    required this.items,
    required this.settled,
    required this.payableNow,
    required this.upcoming,
    required this.note,
  });

  final List<HostDue> items;
  final List<SettledDue> settled;
  final num payableNow;
  final num upcoming;
  final String note;

  bool get hasAnything => items.isNotEmpty || settled.isNotEmpty;

  factory HostDues.fromJson(Map<String, dynamic> j) {
    final totals =
        j['totals'] is Map ? Map<String, dynamic>.from(j['totals']) : const {};
    return HostDues(
      items: (j['items'] is List ? j['items'] as List : const [])
          .whereType<Map>()
          .map((e) => HostDue.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      settled: (j['settled'] is List ? j['settled'] as List : const [])
          .whereType<Map>()
          .map((e) => SettledDue.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      payableNow: _n(totals['payableNow']),
      upcoming: _n(totals['upcoming']),
      note: '${j['note'] ?? 'Anything left unpaid is deducted from your next payout.'}',
    );
  }
}

class DuesOrder {
  const DuesOrder({this.orderId, this.amountPaise, this.dueIds = const [], this.error});
  const DuesOrder.failed(String message)
      : orderId = null,
        amountPaise = null,
        dueIds = const [],
        error = message;

  final String? orderId;
  final int? amountPaise;
  final List<int> dueIds;
  final String? error;

  bool get ok => error == null && (orderId ?? '').isNotEmpty;

  factory DuesOrder.fromJson(Map<String, dynamic> j) {
    final order = j['order'] is Map ? Map<String, dynamic>.from(j['order']) : const {};
    return DuesOrder(
      orderId: '${order['id'] ?? ''}',
      amountPaise: _n(order['amount']).toInt(),
      dueIds: (j['dueIds'] is List ? j['dueIds'] as List : const [])
          .map((e) => _n(e).toInt())
          .toList(),
    );
  }
}
