import 'package:flutter/material.dart' show DateTimeRange;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:rent_home/controller/user_controller.dart';
import 'package:rent_home/models/create_booking_response.dart';
import 'package:rent_home/models/single_property_response.dart';

class BookingService {
  final Dio _dio = Dio(
    BaseOptions(
      contentType: 'application/json',
    ),
  )..interceptors.add(PrettyDioLogger(
      requestHeader: kDebugMode,
      requestBody: kDebugMode,
      responseBody: kDebugMode,
      responseHeader: false,
      error: true,
      compact: true,
      maxWidth: 90,
      enabled: kDebugMode,
    ));
  final String baseUrl = 'https://aajaodev.onrender.com';

  UserController? get userController {
    try {
      return Get.find<UserController>();
    } catch (e) {
      // UserController not found, return null
      return null;
    }
  }

  Future<BookingResponse> createBooking(Map<String, dynamic> data) async {
    final url = '$baseUrl/booking/create';
    // print(data);
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.headers['Authorization'] = 'Bearer $token';
    try {
      print(data);
      final response = await _dio.post(url, data: data);

      print(response.data);
      userController?.fetchOngoingBookings();
      return BookingResponse.fromJson(response.data);
    } on DioException catch (err) {
      print(err.response?.data);
      throw _handleError(err);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Booked (unavailable) date ranges for a property → [{from, to}] as DateTime
  // (parsed from the backend's DD-MM-YYYY). Public — no auth needed. Used to grey
  // out taken nights in the date picker (parity with web's availability calendar).
  Future<List<DateTimeRange>> getBookedRanges(int propertyId) async {
    final url = '$baseUrl/booking/property-availability';
    try {
      final response = await _dio.post(url, data: {"propertyId": propertyId});
      final data = response.data is Map ? response.data['data'] : null;
      final ranges = (data is Map ? data['bookedRanges'] : null) ?? [];
      if (ranges is! List) return [];
      DateTime? parse(String? s) {
        if (s == null || s.isEmpty) return null;
        final p = s.split('-');
        if (p.length != 3) return null;
        final d = int.tryParse(p[0]), m = int.tryParse(p[1]), y = int.tryParse(p[2]);
        if (d == null || m == null || y == null) return null;
        return DateTime(y, m, d);
      }

      final out = <DateTimeRange>[];
      for (final r in ranges) {
        final from = parse(r['from']?.toString());
        final to = parse(r['to']?.toString());
        if (from != null && to != null) out.add(DateTimeRange(start: from, end: to));
      }
      return out;
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getPropertyLatLong(int propertyId) async {
    final property = await getSingleProperty(propertyId);

    if (property.success == true && property.data != null) {
      return {
        "latitude": property.data?.propertyLatitude ?? "0.0",
        "longitude": property.data?.propertyLongitude ?? "0.0",
      };
    } else {
      print(property.toJson());

      throw Exception("Failed to get property latitude and longitude");
    }
  }

  Future<SinglePropertyResponse> getSingleProperty(int id) async {
    final token = await const FlutterSecureStorage().read(key: "user_token");
    print(token);
    _dio.options.headers["Authorization"] = "Bearer $token";

    try {
      final response = await _dio.get("$baseUrl/properties/$id");

      // Remove this line that's causing the error
      // print("history ->>>" + response.data); // response.data is a Map, not a String

      // Instead, print like this if needed:
      print("history ->>> ${response.data}");

      if (response.statusCode == 200) {
        final propertyResponse = SinglePropertyResponse.fromJson(response.data);
        return propertyResponse;
      }
      return SinglePropertyResponse(
          success: false,
          message: "Failed to get property",
          data: SinglePropertyData());
    } on DioException catch (e) {
      print(e);
      _handleError(e);
      return SinglePropertyResponse(
          success: false,
          message: "Failed to get property",
          data: SinglePropertyData());
    } on Exception catch (e) {
      print(e);
      return SinglePropertyResponse(
          success: false,
          message: "Failed to get property",
          data: SinglePropertyData());
    }
  }

  Future<bool> verifyPayment(
      String orderId, String paymentId, String signature) async {
    final url = "$baseUrl/create/payment-verify";
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.headers['Authorization'] = "Bearer $token";
    try {
      final response = await _dio.post(url, data: {
        "orderId": orderId,
        "paymentId": paymentId,
        "signature": signature,
      });
      print(response.data);
      return response.data['success'];
    } on DioException catch (err) {
      throw _handleError(err);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> cancelBooking(
      String bookingId, String reason) async {
    final url = "$baseUrl/user/cancel/booking";
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.headers['Authorization'] = "Bearer $token";
    final data = {
      "bookingId": bookingId,
      "reason": reason,
      
    };
    try {
      final response = await _dio.post(url, data: data);
      print("Cancel booking response: ${response.data}");
      userController?.fetchOngoingBookings();
      return response.data;
    } on DioException catch (err) {
      print("Cancel booking error: ${err.response?.data}");
      throw _handleError(err);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createOngoingBookingPayment(
      String bookingId) async {
    final url = "$baseUrl/user/ongoing/bookings/payment/create";
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.headers['Authorization'] = "Bearer $token";
    final data = {
      "bookingId": bookingId,
    };
    try {
      final response = await _dio.post(url, data: data);
      print("Create ongoing booking payment response: ${response.data}");
      return response.data;
    } on DioException catch (err) {
      print("Create ongoing booking payment error: ${err.response?.data}");
      throw _handleError(err);
    } catch (e) {
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
