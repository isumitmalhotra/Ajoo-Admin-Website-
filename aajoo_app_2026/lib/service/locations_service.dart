import 'package:dio/dio.dart';

import 'package:rent_home/data/ApiConstants.dart';

/// States and cities from the platform's reference tables.
///
/// The listing wizard took State and City as free text on mobile while the
/// website picked them from these tables. Free text is exactly how the
/// catalogue accumulated "KURUKSHETRA", "VIDISHA" and thousands of other junk
/// labels that later had to be cleaned by hand — and a listing typed as
/// "hariyana" simply never appears when a guest searches Haryana.
///
/// 37 states and UTs; cities are fetched per state (Haryana returns 55).
/// Public — no auth — and cached for the session, because a picker that
/// re-fetches on every open is a picker people stop waiting for.
class LocationsService {
  LocationsService._();
  static final LocationsService instance = LocationsService._();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: Apiconstants.baseUrl,
    contentType: 'application/json',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
  ));

  List<String>? _states;
  final Map<String, List<String>> _cities = {};

  /// Never throws: a picker that cannot load its list falls back to free text
  /// rather than blocking the listing.
  Future<List<String>> states() async {
    if (_states != null) return _states!;
    try {
      final res = await _dio.get('/public/locations/states');
      final data = res.data is Map ? res.data['data'] : null;
      final list = data is Map ? data['states'] : null;
      _states = list is List ? list.map((e) => e.toString()).toList() : const [];
    } catch (_) {
      _states = const [];
    }
    return _states!;
  }

  Future<List<String>> cities(String state) async {
    final key = state.trim().toLowerCase();
    if (key.isEmpty) return const [];
    final cached = _cities[key];
    if (cached != null) return cached;
    try {
      final res = await _dio.get('/public/locations/cities',
          queryParameters: {'state': state.trim()});
      final data = res.data is Map ? res.data['data'] : null;
      final list = data is Map ? data['cities'] : null;
      _cities[key] =
          list is List ? list.map((e) => e.toString()).toList() : const [];
    } catch (_) {
      _cities[key] = const [];
    }
    return _cities[key]!;
  }
}
