import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:rent_home/data/Apiconstants.dart';

/// The four surfaces the app was missing against the website: Refer & Earn,
/// host Performance, host Boost and the host notification list.
///
/// Every endpoint here already existed and shipped with the web host portal —
/// none of this is new server work. The app simply had no reader, so a host
/// could not see how their listings were doing, could not buy placement, and
/// had no notification list at all while guests did; and neither side could
/// find their referral code.
class GrowthService {
  GrowthService._();
  static final GrowthService instance = GrowthService._();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: Apiconstants.baseUrl,
    contentType: 'application/json',
    // Every other service in this app sets these. The one that did not —
    // MapService, behind the search — is why a stalled request could hang a
    // button forever.
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

  // ── Refer & Earn ─────────────────────────────────────────────────────────
  // GET /user/referrals/summary. One endpoint for both sides: the web reaches
  // it from /account/refer and /host/refer alike, and so does this.
  Future<ReferralSummary?> referrals() async {
    try {
      final res = await _dio.get('/user/referrals/summary',
          options: await _auth());
      final d = _data(res.data);
      return d == null ? null : ReferralSummary.fromJson(d);
    } catch (_) {
      return null;
    }
  }

  // ── Host performance ─────────────────────────────────────────────────────
  Future<HostPerformance?> performance() async {
    try {
      final res = await _dio.get('/host/performance/summary',
          options: await _auth());
      final d = _data(res.data);
      return d == null ? null : HostPerformance.fromJson(d);
    } catch (_) {
      return null;
    }
  }

  // ── Boost ────────────────────────────────────────────────────────────────
  Future<List<BoostRecord>> boosts() async {
    try {
      final res = await _dio.get('/host/boost/list', options: await _auth());
      final list = _data(res.data)?['boosts'];
      if (list is! List) return const [];
      return list
          .whereType<Map>()
          .map((e) => BoostRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Start a boost purchase. Returns the Razorpay order to open, or a message
  /// explaining why not.
  Future<BoostOrder> orderBoost({
    required int propertyId,
    required String plan,
  }) async {
    try {
      final res = await _dio.post(
        '/host/boost/order',
        data: {'propertyId': propertyId, 'plan': plan},
        options: await _auth(),
      );
      final d = _data(res.data);
      if (d == null) return const BoostOrder.failed('Could not start that boost.');
      return BoostOrder.fromJson(d);
    } on DioException catch (e) {
      final m = e.response?.data;
      return BoostOrder.failed(
        (m is Map ? m['message']?.toString() : null) ??
            'Could not start that boost. Please try again.',
      );
    } catch (_) {
      return const BoostOrder.failed(
          'Could not start that boost. Please try again.');
    }
  }

  /// Hand the signed Razorpay result back so the server can activate it.
  Future<String?> verifyBoost({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    try {
      final res = await _dio.post(
        '/host/boost/verify',
        data: {
          'razorpay_order_id': orderId,
          'razorpay_payment_id': paymentId,
          'razorpay_signature': signature,
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

  // ── Host notifications ───────────────────────────────────────────────────
  // GET (not POST) with page/limit as query parameters — the guest list is a
  // different endpoint with a different shape.
  Future<HostNotificationPage> hostNotifications({int page = 1, int limit = 30}) async {
    try {
      final res = await _dio.get(
        '/host/notifications/search',
        queryParameters: {'page': page, 'limit': limit},
        options: await _auth(),
      );
      final d = _data(res.data);
      final items = d?['items'];
      return HostNotificationPage(
        items: items is List
            ? items
                .whereType<Map>()
                .map((e) => HostNotification.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : const [],
        unread: int.tryParse('${d?['unreadCount'] ?? 0}') ?? 0,
        totalPages: int.tryParse('${d?['totalPages'] ?? 1}') ?? 1,
      );
    } catch (_) {
      return const HostNotificationPage(items: [], unread: 0, totalPages: 1);
    }
  }

  Future<void> markHostNotificationRead(int id) async {
    try {
      await _dio.put('/host/notifications/$id/read', options: await _auth());
    } catch (_) {
      // Best effort: failing to mark one read must not break the list.
    }
  }
}

// ── Models ─────────────────────────────────────────────────────────────────

num _n(dynamic v) {
  if (v is num) return v;
  return num.tryParse('${v ?? 0}') ?? 0;
}

class ReferralSummary {
  const ReferralSummary({
    required this.code,
    required this.link,
    required this.rewardPerReferral,
    required this.totalReferrals,
    required this.converted,
    required this.pending,
    required this.rewardsEarned,
    required this.walletBalance,
  });

  final String code;
  final String link;
  final num rewardPerReferral;
  final int totalReferrals;
  final int converted;
  final int pending;
  final num rewardsEarned;
  final num walletBalance;

  factory ReferralSummary.fromJson(Map<String, dynamic> j) => ReferralSummary(
        code: j['code']?.toString() ?? '',
        link: j['link']?.toString() ?? '',
        rewardPerReferral: _n(j['rewardPerReferral']),
        totalReferrals: _n(j['totalReferrals']).toInt(),
        converted: _n(j['converted']).toInt(),
        pending: _n(j['pending']).toInt(),
        rewardsEarned: _n(j['rewardsEarned']),
        walletBalance: _n(j['walletBalance']),
      );
}

/// One metric, this period against the last, with its history.
class PerfMetric {
  const PerfMetric({required this.current, required this.previous, required this.trend});

  final num current;
  final num previous;
  final List<num> trend;

  /// Change against the previous period. Null when there is no previous figure
  /// to compare against — never 0%, which would read as "no change" when the
  /// truth is "nothing to compare".
  double? get changePercent {
    if (previous <= 0) return null;
    return ((current - previous) / previous) * 100;
  }

  factory PerfMetric.fromJson(dynamic raw) {
    final j = raw is Map ? Map<String, dynamic>.from(raw) : const {};
    final t = j['trend'];
    return PerfMetric(
      current: _n(j['current']),
      previous: _n(j['previous']),
      trend: t is List ? t.map(_n).toList() : const [],
    );
  }
}

class HostPerformance {
  const HostPerformance({
    required this.occupancy,
    required this.revenue,
    required this.cancellations,
    required this.ratings,
    required this.channelSplit,
  });

  final PerfMetric occupancy;
  final PerfMetric revenue;
  final PerfMetric cancellations;
  final PerfMetric ratings;

  /// Direct / app / partner counts, as the web labels them.
  final List<num> channelSplit;

  factory HostPerformance.fromJson(Map<String, dynamic> j) => HostPerformance(
        occupancy: PerfMetric.fromJson(j['occupancy']),
        revenue: PerfMetric.fromJson(j['revenue']),
        cancellations: PerfMetric.fromJson(j['cancellations']),
        ratings: PerfMetric.fromJson(j['ratings']),
        channelSplit: j['channelSplit'] is List
            ? (j['channelSplit'] as List).map(_n).toList()
            : const [],
      );
}

class BoostRecord {
  const BoostRecord({
    required this.boostId,
    required this.propertyId,
    required this.propertyName,
    required this.plan,
    required this.amount,
    required this.status,
    this.start,
    this.end,
  });

  final int boostId;
  final int propertyId;
  final String propertyName;
  final String plan;
  final num amount;
  final String status;
  final DateTime? start;
  final DateTime? end;

  bool get isActive => status.toLowerCase() == 'active';

  factory BoostRecord.fromJson(Map<String, dynamic> j) => BoostRecord(
        boostId: _n(j['boostId']).toInt(),
        propertyId: _n(j['propertyId']).toInt(),
        propertyName: j['propertyName']?.toString() ?? 'Property',
        plan: j['plan']?.toString() ?? '',
        amount: _n(j['amount']),
        status: j['status']?.toString() ?? '',
        start: DateTime.tryParse(j['start']?.toString() ?? '')?.toLocal(),
        end: DateTime.tryParse(j['end']?.toString() ?? '')?.toLocal(),
      );
}

class BoostOrder {
  const BoostOrder({this.orderId, this.amountPaise, this.error});
  const BoostOrder.failed(String message)
      : orderId = null,
        amountPaise = null,
        error = message;

  final String? orderId;
  final int? amountPaise;
  final String? error;

  bool get ok => error == null && (orderId ?? '').isNotEmpty;

  factory BoostOrder.fromJson(Map<String, dynamic> j) {
    // The order may arrive nested (as the booking flow's does) or flat.
    final order = j['order'] is Map ? Map<String, dynamic>.from(j['order']) : j;
    final id = (order['id'] ?? order['orderId'] ?? j['orderId'])?.toString();
    if (id == null || id.isEmpty) {
      return const BoostOrder.failed('That boost could not be started.');
    }
    return BoostOrder(
      orderId: id,
      amountPaise: _n(order['amount'] ?? j['amount']).toInt(),
    );
  }
}

class HostNotification {
  const HostNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.isRead,
    this.linkPath,
    this.createdAt,
  });

  final int id;
  final String title;
  final String body;
  final String category;
  final bool isRead;

  /// Where the website would send you. Used to route the tap.
  final String? linkPath;
  final DateTime? createdAt;

  factory HostNotification.fromJson(Map<String, dynamic> j) => HostNotification(
        id: _n(j['ntf_id']).toInt(),
        title: j['ntf_title']?.toString() ?? '',
        body: j['ntf_body']?.toString() ?? '',
        category: j['ntf_category']?.toString() ?? '',
        isRead: _n(j['ntf_is_read']) == 1,
        linkPath: (j['ntf_link_path']?.toString().trim().isEmpty ?? true)
            ? null
            : j['ntf_link_path'].toString().trim(),
        createdAt:
            DateTime.tryParse(j['ntf_created_at']?.toString() ?? '')?.toLocal(),
      );
}

class HostNotificationPage {
  const HostNotificationPage({
    required this.items,
    required this.unread,
    required this.totalPages,
  });

  final List<HostNotification> items;
  final int unread;
  final int totalPages;
}
