import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:rent_home/data/ApiConstants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rent_home/data/source/remote/api_client/model/ApiException';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  final Dio _dio = Dio();

  factory ApiClient() => _instance;

  ApiClient._internal() {
    _dio
      ..options.baseUrl = baseUrl
      ..options.contentType = Headers.jsonContentType
      ..options.headers = {
        'Accept': 'application/json',
      };
    // _dio.interceptors.add(PrettyDioLogger(
    //   requestHeader: true,
    //   requestBody: true,
    //   responseBody: true,
    //   responseHeader: false,
    //   error: true,
    //   compact: true,
    //   maxWidth: 90,
    //   enabled: true,
    // ));

//Interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          print('''
            🚀 REQUEST
            ➡️ ${options.method} ${options.uri}
            Headers: ${options.headers}
            Body: ${options.data}
            ''');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('''
              ✅ RESPONSE
              ⬅️ ${response.statusCode} ${response.requestOptions.uri}
              Data: ${response.data}
              ''');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          print('''
              ❌ ERROR
              ⛔ ${e.requestOptions.method} ${e.requestOptions.uri}
              Status: ${e.response?.statusCode}
              Message: ${e.message}
              Response: ${e.response?.data}
              ''');
          return handler.next(e);
        },
      ),
    );
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        return handler.next(options);
      },
    ));
  }

  String? _token;
  final String baseUrl = Apiconstants.baseUrl;

  /// Initialize Hive and open the settings box
  void _init() {}

  void setToken(String token) {
    _token = token;
  }

  Future<void> _setToken() async {
    final String? token =
        await const FlutterSecureStorage().read(key: "user_token");
    if (token != null) {
      setToken(token);
      print("bearertoken $token");
    }
  }

  // =======================
  // GET
  // =======================
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    Options? options,
  }) async {
    await _setToken();
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParams,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception("Unexpected error: $e");
    }
  }

  // =======================
  // POST
  // =======================
  Future<dynamic> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Options? options,
    String? authToken,
  }) async {
// If token is explicitly passed, use it
    if (authToken != null && authToken.isNotEmpty) {
      setToken(authToken);
    } else {
      // Otherwise, load token from storage
      await _setToken();
    }
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParams,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception("Unexpected error: $e");
    }
  }

  // =======================
  // PUT
  // =======================
  Future<dynamic> put(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Options? options,
  }) async {
    await _setToken();
    try {
      final response = await _dio.put(
        endpoint,
        data: data,
        queryParameters: queryParams,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception("Unexpected error: $e");
    }
  }

  // =======================
  // DELETE
  // =======================
  Future<dynamic> delete(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Options? options,
  }) async {
    await _setToken();
    try {
      final response = await _dio.delete(
        endpoint,
        data: data,
        queryParameters: queryParams,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception("Unexpected error: $e");
    }
  }

  // =======================
  // ERROR HANDLER
  // =======================
  // Exception _handleError(DioException e) {
  //   final message =
  //       e.response?.data?['message'] ??
  //       e.message ??
  //       'Something went wrong';
  //   return Exception(message);
  // }

  ApiException _handleError(DioException e) {
    final statusCode = e.response?.statusCode;

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown) {
      return ApiException(
        message: "No internet connection. Please check your network.",
        statusCode: 0,
        data: null,
      );
    }

    final message =
        e.response?.data?['message'] ?? e.message ?? 'Something went wrong';

    if (statusCode == 401) {
      return ApiException(
        message: "Session expired. Please login again.",
        statusCode: 401,
        data: e.response?.data,
      );
    }
    return ApiException(
      message: message,
      statusCode: e.response?.statusCode,
      data: e.response?.data,
    );
  }
}
