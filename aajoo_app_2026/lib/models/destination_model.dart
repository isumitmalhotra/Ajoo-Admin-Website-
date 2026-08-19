/// A place the platform can actually put someone.
///
/// Mirrors the website's `Destination` (services/customerApi.ts): name, a live
/// count of stays, and the coordinates to centre a search on. The count comes
/// from the listings themselves, which is the point — the web rail used to
/// carry five hardcoded tiles with invented numbers, four of which led to an
/// empty search. Nothing here is allowed to advertise stays that are not there.
class Destination {
  const Destination({
    required this.name,
    required this.count,
    this.lat,
    this.lng,
  });

  final String name;
  final int count;
  final double? lat;
  final double? lng;

  /// True when we can actually centre a search on this place.
  bool get hasPosition => lat != null && lng != null;

  factory Destination.fromJson(Map<String, dynamic> json) {
    double? asDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    int asInt(dynamic v) {
      if (v is num) return v.toInt();
      return int.tryParse('${v ?? ''}') ?? 0;
    }

    return Destination(
      name: (json['name'] ?? '').toString().trim(),
      count: asInt(json['count']),
      lat: asDouble(json['lat'] ?? json['latitude']),
      lng: asDouble(json['lng'] ?? json['longitude']),
    );
  }

  /// "12 stays" / "1 stay" — never a bare number with no unit.
  String get staysLabel => '$count stay${count == 1 ? '' : 's'}';
}
