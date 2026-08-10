
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:rent_home/models/host_booking_history_model.dart';
import 'package:rent_home/models/host_ongoing_response.dart';
import 'package:rent_home/models/host_properties_reponse.dart' as hostResponse;
import 'package:rent_home/models/transaction_model.dart';

class HostService {
  final Dio _dio = Dio();
  final String baseUrl = 'https://aajaodev.onrender.com';
  String? _token;

  HostService() {
    _dio.options.baseUrl = baseUrl;
    _dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
      compact: true,
      maxWidth: 90,
      enabled: true,
    ));
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

  void setToken(String token) {
    _token = token;
  }

  Future<bool> updatePropertyStatus(int propId, int status) async {
    final url = '$baseUrl/host/property/update-status';
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.headers['Authorization'] = 'Bearer $token';

    try {
      final response =
          await _dio.post(url, data: {'propertyId': propId, 'status': status});
      return response.data['success'];
    } on DioException catch (err) {
      throw _handleError(err);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// One page of the host's listings.
  ///
  /// This used to post `{}` and take whatever came back, which was every
  /// listing the host owned. That is 29,230 rows and 38 MB for the test host —
  /// enough to stall or kill the app before it drew anything. The endpoint is
  /// paginated now and the response carries `totalcount` for any figure that
  /// needs to describe the whole account.
  Future<hostResponse.HostPropertiesResponse> getHostProperties({
    int page = 1,
    int limit = 20,
    String? q,
  }) async {
    final url = '$baseUrl/host/property-search';
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.headers['Authorization'] = 'Bearer $token';

    try {
      final response = await _dio.post(url, data: {
        'page': page,
        'limit': limit,
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      });
      final json = response.data;
      // Was: print the whole response, twice. That is a page of listings dumped
      // to the console on every load, and used to be the entire 38 MB.
      print("Host properties: page $page, ${json['data']?['totalcount'] ?? '?'} total");

      if (json['message'] == "no record found") {
        return hostResponse.HostPropertiesResponse(
          success: false,
          message: "No properties found",
          data: hostResponse.Data(
            properties: [],
          ),
        );
      }

      // Handle different response structures
      Map<String, dynamic> responseData = {
        'success': json['success'] ?? true,
        'message': json['message'] ?? 'Success',
        'data': json['data'] ?? json, // Handle case where data is at root level
      };

      return hostResponse.HostPropertiesResponse.fromJson(responseData);
    } on DioException catch (err) {
      print("DioException: $err");
      throw _handleError(err);
    } catch (e) {
      print("Error in fetching property: ${e.toString()}");
      throw _handleError(e);
    }
  }

  Future<TransactionResponse> getHostTransactions() async {
    final url = '$baseUrl/host/transaction-history';
    final token = await const FlutterSecureStorage().read(key: "user_token");
    print(token);
    _dio.options.headers['Authorization'] = 'Bearer $token';

    try {
      final response = await _dio.post(url, data: {});
      final json = response.data;
      print(json);
      final model = TransactionResponse.fromJson(json);
      // print("model contervet");
      return model;
    } on DioException catch (err) {
      print(err);
      throw _handleError(err);
    } catch (e) {
      print(e);
      throw _handleError(e);
    }
  }

  Future<HostBookingHistoryResponse> getBookingHistory() async {
    final token = await const FlutterSecureStorage().read(key: "user_token");
    print(token);
    _dio.options.headers['Authorization'] = 'Bearer $token';
    try {
      final response = await _dio.post("/host/booking-history");
      final json = response.data;
      print(json);
      final model = HostBookingHistoryResponse.fromJson(json);
      return model;
    } catch (err) {
      print(err);
      throw _handleError(err);
    }
  }

  Future<bool> addUserReview(
      int rating, String id, String description, String title) async {
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.headers['Authorization'] = "Bearer $token";
    final response = await _dio.post("/review/host/add-user-review", data: {
      "rating": rating,
      "bookingId": id,
      "description": description,
      "title": title,
    });
    print(response.data);
    if (response.statusCode == 200) {
      return response.data['success'];
    } else {
      return false;
    }
  }

  Future<HostOnGoingBookingResponse> getHostOngoing(int hostId) async {
    final url = '$baseUrl/booking/ongoing-host';
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.headers['Authorization'] = 'Bearer $token';
    print("Getting Ongoing Booking");
    try {
      final response = await _dio.post(url);
      print(response.data);
      final model = HostOnGoingBookingResponse.fromJson(response.data);
      return model;
    } catch (e) {
      print(e);
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      final response = error.response?.data;
      final message = response?['message'] ?? error.message;
      return Exception(message);
    }
    return Exception(error.toString());
  }
}
