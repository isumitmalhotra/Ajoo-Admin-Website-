/// An agreed price that has not become a booking yet — GET /host/deals/running.
///
/// A coupon, not a reservation: it holds no nights, and two guests may hold
/// one for the same dates; whoever pays first gets them. Shown in the host's
/// Upcoming tab while it runs (client decision, 2026-09-18) and dropped the
/// moment it expires.
class HostRunningDeal {
  final int dealId;
  final int propertyId;
  final String propertyName;
  final int guestId;
  final String guestName;
  final String? bookFrom; // DD-MM-YYYY
  final String? bookTo;
  final int? nights;
  final int discountPercent;

  /// The rupee figure the host said yes to, per night; null on an older deal
  /// whose accepted offer could not be found.
  final double? agreedPerNight;
  final double? agreedTotal;
  final DateTime? agreedAt;
  final DateTime expiresAt;
  final String note;

  const HostRunningDeal({
    required this.dealId,
    required this.propertyId,
    required this.propertyName,
    required this.guestId,
    required this.guestName,
    this.bookFrom,
    this.bookTo,
    this.nights,
    required this.discountPercent,
    this.agreedPerNight,
    this.agreedTotal,
    this.agreedAt,
    required this.expiresAt,
    required this.note,
  });

  bool get isRunning => expiresAt.isAfter(DateTime.now());

  /// "expires in 2h 10m", from the phone's clock.
  String timeLeft([DateTime? now]) {
    final left = expiresAt.difference(now ?? DateTime.now());
    if (left.isNegative || left.inMinutes <= 0) return 'expired';
    final m = left.inMinutes + (left.inSeconds % 60 > 0 ? 1 : 0);
    if (m < 60) return 'expires in ${m}m';
    final h = m ~/ 60;
    return 'expires in ${h}h ${(m % 60).toString().padLeft(2, '0')}m';
  }

  static double? _money(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  factory HostRunningDeal.fromJson(Map<String, dynamic> j) {
    final expires = DateTime.tryParse(j['expiresAt']?.toString() ?? '');
    return HostRunningDeal(
      dealId: (j['dealId'] as num?)?.toInt() ?? 0,
      propertyId: (j['propertyId'] as num?)?.toInt() ?? 0,
      propertyName: j['propertyName']?.toString() ?? 'Property',
      guestId: (j['guestId'] as num?)?.toInt() ?? 0,
      guestName: j['guestName']?.toString() ?? 'Guest',
      bookFrom: j['bookFrom']?.toString(),
      bookTo: j['bookTo']?.toString(),
      nights: (j['nights'] as num?)?.toInt(),
      discountPercent: (j['discountPercent'] as num?)?.toInt() ?? 0,
      agreedPerNight: _money(j['agreedPerNight']),
      agreedTotal: _money(j['agreedTotal']),
      agreedAt: DateTime.tryParse(j['agreedAt']?.toString() ?? ''),
      // An unparseable deadline is treated as already over: a deal must
      // never sit in Upcoming forever because a date failed to parse.
      expiresAt: expires ?? DateTime.fromMillisecondsSinceEpoch(0),
      note: j['note']?.toString() ??
          'Price agreed, not booked yet. The nights stay open to everyone until the guest pays.',
    );
  }
}
