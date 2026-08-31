/// A review the signed-in guest wrote about a stay.
///
/// Deliberately its own class rather than reusing `Review` from
/// user_review_model.dart — that one is the mirror image, a review a HOST
/// wrote about the guest, and the two have been confused before. This is the
/// shape `GET /user/reviews/list` returns, column names and all.
class MyReview {
  const MyReview({
    required this.id,
    required this.bookingId,
    required this.propertyId,
    required this.property,
    required this.place,
    required this.rating,
    required this.title,
    required this.body,
    required this.addedAt,
    this.image,
  });

  final int id;
  final String bookingId;
  final int propertyId;

  /// The listing's name, or a neutral stand-in — never a fabricated one.
  final String property;

  /// Address if we have one, else the city.
  final String place;

  final int rating;
  final String title;
  final String body;
  final DateTime? addedAt;

  /// The listing's cover photo, or null when it has none. Null means show a
  /// placeholder — never a stock photograph of a different property, which is
  /// what the website's version of this page used to do.
  final String? image;

  /// Ints from a payload that sends some of them as decimal strings.
  ///
  /// `br_rating` arrives as `"5.00"` — a DECIMAL column serialised by mysql2 —
  /// and `int.tryParse("5.00")` is null, so a five-star review rendered as five
  /// empty stars. The website is unaffected because JavaScript's Number()
  /// parses decimals; Dart's int.parse does not. Parse as a number, then round.
  static int _int(Object? v) {
    if (v is int) return v;
    if (v is num) return v.round();
    return (num.tryParse('${v ?? ''}') ?? 0).round();
  }

  factory MyReview.fromJson(Map<String, dynamic> j) {
    final p = j['propReview'] is Map
        ? Map<String, dynamic>.from(j['propReview'] as Map)
        : const <String, dynamic>{};
    final address = '${p['property_address'] ?? ''}'.trim();
    final city = '${p['property_city'] ?? ''}'.trim();
    return MyReview(
      id: _int(j['br_id']),
      bookingId: '${j['br_book_id'] ?? ''}',
      propertyId: _int(j['br_propId'] ?? p['property_id']),
      property: '${p['property_name'] ?? ''}'.trim().isEmpty
          ? 'Your stay'
          : '${p['property_name']}'.trim(),
      place: address.isNotEmpty ? address : (city.isNotEmpty ? city : ''),
      rating: _int(j['br_rating']),
      title: '${j['br_title'] ?? ''}'.trim(),
      body: '${j['br_desc'] ?? ''}'.trim(),
      addedAt: DateTime.tryParse('${j['br_addedAt'] ?? ''}'),
      image: (j['property_image'] ?? '').toString().isEmpty
          ? null
          : '${j['property_image']}',
    );
  }
}
