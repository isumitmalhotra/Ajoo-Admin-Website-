import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rent_home/models/search_property_model.dart';

class HomePageSearchService {
  final _dio = Dio();
  final String baseUrl = 'https://aajaodev.onrender.com/';
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
    final data = {
      "query": query,
      "longitude": "",
      "latitude": "",
      "sort_by": "property_id",
      "order": "desc",
      "limit": 10,
      "offset": 0,
      "radius": 10
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

  Future<SearchResponse> getPreBooking({bool isLuxury = false}) async {
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.headers['Authorization'] = 'Bearer $token';
    final data = {
      "query": "",
      "longitude": "",
      "latitude": "",
      "sort_by": "property_id",
      "order": "desc",
      // Was 10. Ten rows is a preview, not a catalogue: with sort and filter
      // controls on this screen, "Price: Low to High" reordered ten listings
      // and a price band could only ever narrow those same ten — so a guest
      // asking for stays under ₹1,000 was told there were none while the
      // platform held plenty. Sixty is one request, still small, and gives
      // the controls something real to work on.
      "limit": 60,
      "offset": 0,
      "radius": 10,
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
