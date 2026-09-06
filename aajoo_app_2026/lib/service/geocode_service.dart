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

/// A pin, and the address the platform resolved it to.
///
/// The host listing wizard fills its whole location section from one of these,
/// so it carries every field that section asks for rather than the two the
/// guest-side search needs. Field names are the backend's own — see
/// `toAddressFields` in the geocode controller.
class PickedAddress {
  const PickedAddress({
    required this.lat,
    required this.lng,
    this.label = '',
    this.state = '',
    this.district = '',
    this.city = '',
    this.village = '',
    this.pincode = '',
    this.street = '',
  });

  final double lat;
  final double lng;

  /// Google's own one-line address, shown under the map so the host can see
  /// what the pin actually resolved to before accepting it.
  final String label;
  final String state;
  final String district;
  final String city;
  final String village;
  final String pincode;
  final String street;

  /// True when the lookup found nothing useful. The pin still counts —
  /// coordinates are the one thing the form cannot do without — but there is
  /// nothing to fill the fields with.
  bool get isEmpty =>
      state.isEmpty && city.isEmpty && street.isEmpty && pincode.isEmpty;

  static String _s(dynamic v) => v?.toString().trim() ?? '';

  static PickedAddress fromJson(
      double lat, double lng, Map<String, dynamic> j) {
    final a = j['address'];
    final m = a is Map ? a : const {};
    return PickedAddress(
      lat: lat,
      lng: lng,
      label: _s(j['label']),
      state: _s(m['state']),
      district: _s(m['district']),
      city: _s(m['city']),
      village: _s(m['village']),
      pincode: _s(m['pincode']),
      street: _s(m['street']),
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

  /// What address a pin sits at.
  ///
  /// Always asked for the CHOSEN point, even when the host picked a search
  /// suggestion that appears to carry an address already. The suggestion's
  /// address is empty whenever the backend answers from Google's legacy Text
  /// Search, which cannot return address components at all — and which of the
  /// two Google generations answers is a console setting no client can see.
  /// The website trusted the suggestion and filled nothing; one lookup for the
  /// point actually chosen is cheap and always right.
  ///
  /// Never throws: a failed lookup returns null and the caller keeps the pin.
  /// Pass a [cancelToken] to drop a lookup whose pin has already moved on.
  /// Without one the request keeps a connection open and finishes into
  /// nothing, which is what made panning across a map feel like wading.
  Future<PickedAddress?> reverse(double lat, double lng,
      {CancelToken? cancelToken}) async {
    try {
      final res = await _dio.get('/public/geocode/reverse',
          queryParameters: {'lat': lat, 'lng': lng},
          cancelToken: cancelToken);
      final data = res.data is Map ? res.data['data'] : null;
      if (data is! Map) return null;
      return PickedAddress.fromJson(
          lat, lng, Map<String, dynamic>.from(data));
    } on DioException catch (e) {
      // A cancelled lookup is the caller doing its job, not a failure.
      if (CancelToken.isCancel(e)) return null;
      _logger.w('reverse geocode failed for $lat,$lng: $e');
      return null;
    } catch (e) {
      _logger.w('reverse geocode failed for $lat,$lng: $e');
      return null;
    }
  }
}
