import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import 'package:rent_home/data/ApiConstants.dart';

/// A place the guest can search from — a real geocoded location, not a city we
/// happen to have a listing in.
class GeoPlace {
  const GeoPlace({
    required this.label,
    required this.lat,
    required this.lng,
    this.city,
    this.state,
  });

  /// Full readable name, e.g. "Karnal, Haryana, India".
  final String label;
  final double lat;
  final double lng;
  final String? city;
  final String? state;

  /// The first line of the label — "Karnal" out of "Karnal, Haryana, India".
  String get shortName {
    final head = label.split(',').first.trim();
    return head.isEmpty ? label : head;
  }

  /// The rest, for the second line of a suggestion row.
  String get context {
    final parts = label.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    return parts.length > 1 ? parts.sublist(1).join(', ') : '';
  }

  static double? _d(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '');
  }

  static GeoPlace? fromJson(Map<String, dynamic> j) {
    final lat = _d(j['lat']);
    final lng = _d(j['lng'] ?? j['lon']);
    final label = (j['label'] ?? j['display_name'] ?? '').toString().trim();
    if (lat == null || lng == null || label.isEmpty) return null;
    final addr = j['address'];
    return GeoPlace(
      label: label,
      lat: lat,
      lng: lng,
      city: addr is Map ? addr['city']?.toString() : null,
      state: addr is Map ? addr['state']?.toString() : null,
    );
  }
}

/// Turning a typed place name into coordinates.
///
/// The app used to offer "destinations" derived from the cities of listings it
/// had already loaded, so typing anywhere we do not yet have a stay answered
/// "No matches" — Karnal included, despite the platform having listings there.
/// The website has always searched a real geocoder through the backend's
/// proxy; this is the same endpoint.
///
/// Proxied rather than called directly because Nominatim sends no CORS headers
/// and wants a contactable user agent; the backend also caches the results.
class GeocodeService {
  GeocodeService._();
  static final GeocodeService instance = GeocodeService._();

  final _logger = Logger();
  final _dio = Dio(BaseOptions(
    baseUrl: Apiconstants.baseUrl,
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  /// Places matching [query]. Never throws — an unknown place is an empty
  /// list, which the caller shows as "no matches" rather than an error.
  Future<List<GeoPlace>> search(String query) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    try {
      final res = await _dio.get('/public/geocode/search',
          queryParameters: {'q': q});
      final data = res.data is Map ? res.data['data'] : null;
      final raw = (data is Map ? data['places'] : null) ?? data;
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => GeoPlace.fromJson(Map<String, dynamic>.from(e)))
          .whereType<GeoPlace>()
          .toList();
    } catch (e) {
      _logger.w('geocode search failed for "$q": $e');
      return const [];
    }
  }

  /// A single best match, for when the guest typed a place and pressed Search
  /// without picking a suggestion.
  Future<GeoPlace?> resolve(String query) async {
    final places = await search(query);
    return places.isEmpty ? null : places.first;
  }
}
