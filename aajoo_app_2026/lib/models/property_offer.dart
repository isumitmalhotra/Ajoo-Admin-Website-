/// A discount running on a listing right now.
///
/// Not a coupon — nobody types a code. The listing simply shows the old price
/// struck through and the new one beside it. The server works both figures out
/// and sends them; nothing here recomputes a discount, because a client that
/// can name the price is a client that can invent one.
///
/// Mirrors `utils/propertyOffers.js` publicShape on the backend and the web
/// card's `offer` prop, so all three surfaces show the same thing.
class PropertyOffer {
  const PropertyOffer({
    required this.id,
    required this.title,
    required this.was,
    required this.now,
    required this.percent,
    this.endsAt,
    this.slotsLeft,
    this.payModes = const ['full'],
  });

  final int id;

  /// What the guest sees above the price — "Limited time offer" by default.
  final String title;

  /// The listed price, struck through.
  final num was;

  /// What they actually pay.
  final num now;
  final int percent;

  final DateTime? endsAt;

  /// Null when the offer is uncapped. Zero means the advertised cap is spent
  /// and only the buffer is holding it open — never advertise a count then.
  final int? slotsLeft;

  /// Which payment methods this offer may be booked with. 'full' is always in;
  /// 'deposit' and 'cod' only if whoever created it ticked those boxes.
  final List<String> payModes;

  bool get allowsDeposit => payModes.contains('deposit');
  bool get allowsCod => payModes.contains('cod');

  static num _n(Object? v) => v is num ? v : num.tryParse('${v ?? ''}') ?? 0;

  /// Returns null for anything that is not a real discount, so callers can
  /// treat "no offer" and "a zero-percent offer" the same way — a struck-through
  /// price identical to the new one reads as a trick.
  static PropertyOffer? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final j = Map<String, dynamic>.from(raw);
    final was = _n(j['was']);
    final now = _n(j['now']);
    final pct = _n(j['percent']).toInt();
    if (pct <= 0 || was <= 0 || now <= 0 || now >= was) return null;

    return PropertyOffer(
      id: _n(j['id']).toInt(),
      title: '${j['title'] ?? 'Limited time offer'}',
      was: was,
      now: now,
      percent: pct,
      endsAt: j['endsAt'] == null ? null : DateTime.tryParse('${j['endsAt']}'),
      slotsLeft: j['slotsLeft'] == null ? null : _n(j['slotsLeft']).toInt(),
      payModes: (j['payModes'] is List)
          ? List<String>.from((j['payModes'] as List).map((e) => '$e'))
          : const ['full'],
    );
  }

  /// The proportion to apply to a multi-night subtotal. The server discounts
  /// the room subtotal and leaves extra-guest fees at full rate; this is the
  /// same ratio, so a quote shown here matches the one charged.
  double get ratio => was <= 0 ? 1 : now / was;
}
