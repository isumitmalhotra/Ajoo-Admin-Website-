/// A live negotiated deal (personal coupon) for the logged-in renter — the
/// mobile mirror of the web dashboard "Your negotiated deals" card.
///
/// Comes from GET /user/coupons/list. When it originated from an accepted price
/// offer it carries the sanctioned stay dates (DD-MM-YYYY) and a 24-hour expiry,
/// so the app can offer a one-click "Book now" at the agreed stay.
class NegotiatedDeal {
  final String code;
  final String title;
  /// The agreed reduction, as a percentage of the room total.
  ///
  /// A DOUBLE, and it has to be. This was an int parsed with int.tryParse, and
  /// int.tryParse("9.38") is null — so every negotiated percentage that was not
  /// a whole number became 0, the banner read "0% OFF", and "Book at the agreed
  /// price" opened checkout at the FULL price with the coupon showing no
  /// discount at all. A negotiated price almost never lands on a whole
  /// percentage: ₹3,200 down to ₹2,900 is 9.375%.
  final double percent;
  final double amount;
  final String type; // "percent" | "amount"
  final int? propertyId;
  final String? propertyName;
  final DateTime? validTo;
  final String? bookFrom; // DD-MM-YYYY
  final String? bookTo; // DD-MM-YYYY

  NegotiatedDeal({
    required this.code,
    required this.title,
    required this.percent,
    required this.amount,
    required this.type,
    this.propertyId,
    this.propertyName,
    this.validTo,
    this.bookFrom,
    this.bookTo,
  });

  factory NegotiatedDeal.fromJson(Map<String, dynamic> json) {
    int? asInt(dynamic v) => v == null ? null : int.tryParse(v.toString());
    return NegotiatedDeal(
      code: (json['code'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      percent: double.tryParse((json['percent'] ?? 0).toString()) ?? 0,
      amount: double.tryParse((json['amount'] ?? 0).toString()) ?? 0,
      type: (json['type'] ?? 'percent').toString(),
      propertyId: asInt(json['propertyId']),
      propertyName: json['propertyName']?.toString(),
      validTo: json['validTo'] != null
          ? DateTime.tryParse(json['validTo'].toString())
          : null,
      bookFrom: (json['bookFrom'] == null || json['bookFrom'].toString().isEmpty)
          ? null
          : json['bookFrom'].toString(),
      bookTo: (json['bookTo'] == null || json['bookTo'].toString().isEmpty)
          ? null
          : json['bookTo'].toString(),
    );
  }

  bool get isPercent => type == 'percent';
  bool get hasDates => (bookFrom?.isNotEmpty ?? false) && (bookTo?.isNotEmpty ?? false);

  /// Whether the deal is still redeemable (24-hour window not elapsed).
  bool get isActive => validTo == null ? true : validTo!.isAfter(DateTime.now());

  /// Short "23h 41m" / "42m" countdown, or null if expired / no expiry.
  String? get countdown {
    if (validTo == null) return null;
    final ms = validTo!.difference(DateTime.now()).inMilliseconds;
    if (ms <= 0) return null;
    final h = ms ~/ 3600000;
    final m = (ms % 3600000) ~/ 60000;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }
}
