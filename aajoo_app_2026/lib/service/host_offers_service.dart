import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:rent_home/data/ApiConstants.dart';

/// Running a discount on your own listing, from the phone.
///
/// The guest side of this shipped on both platforms — a card shows the old
/// price struck through and the new one beside it — but only the website could
/// ever START one. A host who works from their phone could see their listing
/// discounted and had no way to run, change or stop a discount themselves.
///
/// Same three endpoints the website calls, so the rules live in one place:
/// the server owns the floor (`property_mini_price`), the percentage ceiling,
/// the window and the slot arithmetic, and its refusal sentence is the one
/// worth showing. Nothing here re-implements any of that.
class HostOffersService {
  HostOffersService._();
  static final HostOffersService instance = HostOffersService._();

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

  /// The server's own sentence, when it sent one. Its refusals name the rule
  /// that was broken ("below the minimum you set for this listing"), which is
  /// more use than anything this file could invent.
  static String _message(Object e, String fallback) {
    if (e is DioException) {
      final m = e.response?.data;
      if (m is Map) {
        final v = m['message'];
        if (v is List && v.isNotEmpty) return v.join(', ');
        if (v != null && '$v'.isNotEmpty) return '$v';
      }
    }
    return fallback;
  }

  /// GET /host/offers.
  ///
  /// Throws rather than returning an empty list, because "you have no offers"
  /// and "we could not ask" look identical on screen and only one of them is
  /// a fact — the same rule the settlements screen follows.
  Future<List<HostOffer>> list() async {
    final res = await _dio.get('/host/offers', options: await _auth());
    final d = res.data;
    final data = d is Map && d['data'] is Map ? d['data'] as Map : const {};
    final rows = data['offers'];
    if (rows is! List) return const [];
    return rows
        .whereType<Map>()
        .map((e) => HostOffer.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// POST /host/offers. Returns null on success, a sentence on refusal.
  Future<String?> create(NewHostOffer offer) async {
    try {
      await _dio.post('/host/offers',
          data: offer.toJson(), options: await _auth());
      return null;
    } catch (e) {
      return _message(e, "Couldn't start that offer.");
    }
  }

  /// POST /host/offers/:id/end. Returns null on success, a sentence on failure.
  Future<String?> end(int offerId) async {
    try {
      await _dio.post('/host/offers/$offerId/end',
          data: const <String, dynamic>{}, options: await _auth());
      return null;
    } catch (e) {
      return _message(e, "Couldn't end that offer.");
    }
  }
}

num _n(Object? v) => v is num ? v : num.tryParse('${v ?? ''}') ?? 0;

/// What the host is about to run. Mirrors the website's `NewOffer`.
class NewHostOffer {
  const NewHostOffer({
    required this.propertyId,
    required this.kind,
    required this.endsAt,
    this.percent,
    this.price,
    this.title = 'Limited time offer',
    this.slotLimit,
    this.buffer = 3,
    this.allowDeposit = false,
    this.allowCod = false,
  });

  final int propertyId;

  /// `percent` — take a share off the nightly price.
  /// `price`   — name the discounted nightly price outright.
  final String kind;
  final num? percent;
  final num? price;
  final String title;
  final DateTime endsAt;

  /// Null means unlimited.
  final int? slotLimit;

  /// Headroom past the cap, so a guest already on the payment sheet is not
  /// repriced mid-checkout.
  final int buffer;

  final bool allowDeposit;
  final bool allowCod;

  Map<String, dynamic> toJson() => {
        'propertyId': propertyId,
        'kind': kind,
        if (kind == 'percent') 'percent': percent,
        if (kind == 'price') 'price': price,
        'title': title,
        'endsAt': endsAt.toUtc().toIso8601String(),
        'slotLimit': slotLimit,
        'buffer': buffer,
        'allowDeposit': allowDeposit,
        'allowCod': allowCod,
      };
}

/// One offer as the server describes it.
class HostOffer {
  const HostOffer({
    required this.id,
    required this.propertyId,
    required this.property,
    required this.title,
    required this.kind,
    required this.was,
    required this.now,
    required this.percent,
    required this.endsAt,
    required this.slotLimit,
    required this.slotsUsed,
    required this.slotsLeft,
    required this.payModes,
    required this.createdBy,
    required this.status,
    required this.endedReason,
  });

  final int id;
  final int propertyId;
  final String property;
  final String title;
  final String kind;

  /// The listed price and the discounted one, both priced by the server.
  final num was;
  final num now;
  final num percent;

  final String endsAt;
  final int? slotLimit;
  final int slotsUsed;
  final int? slotsLeft;
  final List<String> payModes;

  /// `host` or `admin`. An admin campaign on your listing is not yours to end.
  final String createdBy;

  /// `Running` · `Finished` · `Ended`.
  final String status;
  final String? endedReason;

  bool get isRunning => status == 'Running';
  bool get startedByAdmin => createdBy == 'admin';

  factory HostOffer.fromJson(Map<String, dynamic> j) => HostOffer(
        id: _n(j['id']).toInt(),
        propertyId: _n(j['propertyId']).toInt(),
        property: '${j['property'] ?? 'Your listing'}',
        title: '${j['title'] ?? 'Limited time offer'}',
        kind: '${j['kind'] ?? 'percent'}',
        was: _n(j['was']),
        now: _n(j['now']),
        percent: _n(j['percent']),
        endsAt: '${j['endsAt'] ?? ''}',
        slotLimit: j['slotLimit'] == null ? null : _n(j['slotLimit']).toInt(),
        slotsUsed: _n(j['slotsUsed']).toInt(),
        slotsLeft: j['slotsLeft'] == null ? null : _n(j['slotsLeft']).toInt(),
        payModes: (j['payModes'] is List ? j['payModes'] as List : const [])
            .map((e) => '$e')
            .toList(),
        createdBy: '${j['createdBy'] ?? 'host'}',
        status: '${j['status'] ?? 'Finished'}',
        endedReason: j['endedReason'] == null ? null : '${j['endedReason']}',
      );
}
