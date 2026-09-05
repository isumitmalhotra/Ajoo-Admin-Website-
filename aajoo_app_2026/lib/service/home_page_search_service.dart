import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rent_home/models/search_property_model.dart';
import 'package:rent_home/data/ApiConstants.dart';

class HomePageSearchService {
  final _dio = Dio();
  final String baseUrl = '${Apiconstants.baseUrl}/';
  String? _token;
  HomePageSearchService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.contentType = 'application/json';
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        return handler.next(options);
      },
    ));
  }
  Future<SearchResponse> searchProperty(String query) async {
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.headers['Authorization'] = 'Bearer $token';
    // No coordinates, and therefore no radius either.
    //
    // These were posted as empty strings. Number("") is 0 on the server and
    // isFinite(0) is true, so a text search asked for stays within 10km of
    // 0N 0E — a point in the Atlantic — and every search from this screen
    // came back "no record found" whatever was typed. The server now treats a
    // blank coordinate as absent, so old builds are fixed too; this stops
    // sending the nonsense in the first place.
    final data = {
      "query": query,
      "sort_by": "property_id",
      "order": "desc",
      "limit": 10,
      "offset": 0,
    };

    try {
      final response = await _dio.post("properties/list", data: data);
      print(response.data);
      return SearchResponse.fromJson(response.data);
    } catch (Err) {
      print(Err);
      rethrow;
    }
  }

  /// [latitude]/[longitude]/[radiusKm] narrow the list to one place.
  ///
  /// This used to post empty strings for both coordinates, so the "Pre-booking
  /// near <place>" screen ignored the place entirely and returned the newest
  /// listings anywhere in the country — a guest who searched Karnal was shown
  /// stays in Vidisha under a heading that said Karnal.
  Future<SearchResponse> getPreBooking({
    bool isLuxury = false,
    double? latitude,
    double? longitude,
    int radiusKm = 10,
    int? guests,
    String? from,
    String? to,
    int? categoryId,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    // What the guest typed. Matched by the API against name, address, city and
    // state — the results screen used to filter its own fetched page by name,
    // so searching a stay by name looked inside sixty rows rather than the
    // catalogue.
    String? query,
    // 'default' | 'price_low_high' | 'price_high_low' | 'rating'. Ordered by
    // the API, because sorting the fetched page orders sixty rows and presents
    // them as the cheapest, or the best rated, on the platform.
    String? sortBy,
  }) async {
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.headers['Authorization'] = 'Bearer $token';
    // The API's own vocabulary for the sort, translated once here.
    const sortMap = {
      'price_low_high': ['property_price', 'asc'],
      'price_high_low': ['property_price', 'desc'],
      'rating': ['rating', 'desc'],
    };
    final chosenSort = sortMap[sortBy] ?? const ['property_id', 'desc'];
    final data = {
      "query": (query ?? "").trim(),
      // Omitted rather than sent empty when we have no fix: the endpoint only
      // applies its distance filter when BOTH are present, and an empty string
      // is not a coordinate.
      if (longitude != null) "longitude": longitude,
      if (latitude != null) "latitude": latitude,
      "sort_by": chosenSort[0],
      "order": chosenSort[1],
      // Was 10. Ten rows is a preview, not a catalogue: with sort and filter
      // controls on this screen, "Price: Low to High" reordered ten listings
      // and a price band could only ever narrow those same ten — so a guest
      // asking for stays under ₹1,000 was told there were none while the
      // platform held plenty. Sixty is one request, still small, and gives
      // the controls something real to work on.
      "limit": 60,
      "offset": 0,
      "radius": radiusKm,
      // The stay being searched for. Omitted when unset rather than sent
      // empty — an empty string is not a date and not a guest count.
      if (guests != null && guests > 0) "guests": guests,
      if (from != null && from.isNotEmpty) "from": from,
      if (to != null && to.isNotEmpty) "to": to,
      // Browse by property type, filtered in SQL by the API rather than over
      // the page this returns — see propertyListing in the backend. Filtering
      // the fetched page client-side is what made the category row look dead:
      // a small share of the catalogue is categorised, so narrowing 60 nearby
      // rows by "Villas" almost always produced nothing.
      if (categoryId != null && categoryId > 0) "category": categoryId,
      // Price band and rating floor, narrowed by the API rather than over the
      // sixty rows it returns. Filtering the fetched page meant "under
      // ₹1,000" searched sixty listings instead of the catalogue.
      if (minPrice != null && minPrice > 0) "minPrice": minPrice,
      if (maxPrice != null && maxPrice > 0) "maxPrice": maxPrice,
      if (minRating != null && minRating > 0) "minRating": minRating,
      "isLuxury": isLuxury
    };
    try {
      final response = await _dio.post("properties/list", data: data);
      print(response.data);
      return SearchResponse.fromJson(response.data);
    } catch (Err) {
      print(Err);
      rethrow;
    }
  }

  /// Properties in one named area, for the pre-booking area rails.
  ///
  /// Filters on `area`, not `city`. property_city is unreliable across the
  /// imported dataset — an exact city match returns 1 property for Mohali and
  /// 0 for Chandigarh, while the same names in property_address return 48 and
  /// 51. The backend's `filters.area` does the address match.
  Future<SearchResponse> getPropertiesByArea(
    String area, {
    bool isLuxury = false,
    int limit = 12,
  }) async {
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.headers['Authorization'] = 'Bearer $token';
    final data = {
      "query": "",
      "longitude": "",
      "latitude": "",
      "sort_by": "property_id",
      "order": "desc",
      "limit": limit,
      "offset": 0,
      "radius": 10,
      "isLuxury": isLuxury,
      "filters": {"area": area},
    };
    final response = await _dio.post("properties/list", data: data);
    return SearchResponse.fromJson(response.data);
  }
}
