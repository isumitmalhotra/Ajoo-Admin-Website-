/// One negotiation thread on the host's side (A-70).
///
/// `/host/negotiations/list` has existed since the negotiation feature
/// shipped, and nothing in the app ever called it: a host could only find an
/// offer by catching its push notification. This is the model for that
/// endpoint — one row per property/guest pair, most recent offer first, which
/// is how the server already collapses the threads.
class HostNegotiation {
  final int offerId;
  final int propertyId;
  final String propertyName;
  final double originalPrice;
  final int renterId;
  final String renterName;
  final double offerPrice;
  final String message;

  /// pending | accepted | declined | countered — whatever the server stored.
  final String status;
  final DateTime? createdAt;

  /// The stay the guest is asking for, DD-MM-YYYY, so the host can see what
  /// they would be sanctioning. Null on older offers made before dates were
  /// carried on the offer.
  final String? bookFrom;
  final String? bookTo;

  const HostNegotiation({
    required this.offerId,
    required this.propertyId,
    required this.propertyName,
    required this.originalPrice,
    required this.renterId,
    required this.renterName,
    required this.offerPrice,
    required this.message,
    required this.status,
    this.createdAt,
    this.bookFrom,
    this.bookTo,
  });

  bool get isPending => status.toLowerCase() == 'pending';

  /// How far below the asking price the guest is, as a percentage. Null when
  /// there is no asking price to compare against — never 0, which would read
  /// as "they offered full price".
  double? get discountPercent {
    if (originalPrice <= 0 || offerPrice <= 0) return null;
    return ((originalPrice - offerPrice) / originalPrice) * 100;
  }

  static double _d(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  static int _i(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  factory HostNegotiation.fromJson(Map<String, dynamic> json) {
    DateTime? created;
    final raw = json['createdAt'];
    if (raw is String && raw.isNotEmpty) {
      try {
        created = DateTime.parse(raw).toLocal();
      } catch (_) {}
    }
    String? nonEmpty(dynamic v) {
      final s = v?.toString().trim() ?? '';
      return s.isEmpty ? null : s;
    }

    return HostNegotiation(
      offerId: _i(json['offerId']),
      propertyId: _i(json['propertyId']),
      propertyName: json['propertyName']?.toString() ?? 'Property',
      originalPrice: _d(json['originalPrice']),
      renterId: _i(json['renterId']),
      renterName: json['renterName']?.toString() ?? 'Guest',
      offerPrice: _d(json['offerPrice']),
      message: json['message']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      createdAt: created,
      bookFrom: nonEmpty(json['bookFrom']),
      bookTo: nonEmpty(json['bookTo']),
    );
  }
}
