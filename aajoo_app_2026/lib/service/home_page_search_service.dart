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
      "limit": 10,
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
}
