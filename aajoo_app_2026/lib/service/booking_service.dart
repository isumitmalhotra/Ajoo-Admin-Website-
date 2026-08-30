import 'package:flutter/material.dart' show DateTimeRange;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rent_home/models/cancellation_quote.dart';
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

  /// Wallet balance (audit C-9) — spendable referral credit. Best-effort:
  /// any failure reads as ₹0 and the wallet row simply doesn't render, so a
  /// wallet hiccup can never block a booking.
  Future<double> getWalletBalance() async {
    final url = '$baseUrl/user/wallet';
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.headers['Authorization'] = 'Bearer $token';
    try {
      final response = await _dio.get(url);
      final data = response.data is Map ? response.data['data'] : null;
      return double.tryParse('${data is Map ? data['balance'] : 0}') ?? 0;
    } catch (_) {
      return 0;
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
        var to = parse(r['to']?.toString());
        if (from == null || to == null) continue;
        // Every range is read half-open [from, to) — a stay's `to` is the
        // checkout day, which the next guest may arrive on. A range whose end
        // is not after its start therefore covers no nights at all and would
        // silently block nothing, while the booking guard still refuses those
        // dates. The web client has carried this guard since the availability
        // calendar shipped; the app did not, so the two could disagree about
        // whether a day was free. Nothing in the data produces one today —
        // the backend already widens host blocks by a day before sending them
        // — which is exactly why the divergence was invisible.
        if (!to.isAfter(from)) {
          to = DateTime(from.year, from.month, from.day + 1);
        }
        out.add(DateTimeRange(start: from, end: to));
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

  /// What cancelling this booking would refund, and whether it is even
  /// allowed. Shown before the confirm dialog — see CancellationQuote.
  Future<CancellationQuote?> cancellationQuote(String bookingId) async {
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.headers['Authorization'] = "Bearer $token";
    try {
      final response = await _dio
          .post("$baseUrl/user/cancel/quote", data: {"bookingId": bookingId});
      final body = response.data;
      final data = body is Map ? body['data'] : null;
      if (data is! Map) return null;
      return CancellationQuote.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {
      // A quote we could not fetch must not block the cancel — the guest can
      // still proceed, they simply do not get the figure up front.
      return null;
    }
  }

  /// The invoice PDF for a booking, as bytes.
  ///
  /// GET /user/invoice/:bookId/download. The renter side never called this at
  /// all — the model has carried `book_invoice` since booking history shipped
  /// and nothing read it, so a guest could see that an invoice existed and had
  /// no way to obtain one. The website downloads it from Transactions.
  ///
  /// Keyed on book_id ("B212765") or book_pri_id, NOT the invoice number
  /// ("Inv_212765") — that answers "invoice not found", which is the trap the
  /// web client documents.
  ///
  /// Returns null rather than throwing: a missing invoice is a normal state
  /// (an unpaid booking has none), and the caller says so.
  Future<List<int>?> invoicePdf(String bookId) async {
    if (bookId.trim().isEmpty) return null;
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.headers['Authorization'] = "Bearer $token";
    try {
      final response = await _dio.get<List<int>>(
        "$baseUrl/user/invoice/${Uri.encodeComponent(bookId.trim())}/download",
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) return null;
      // A JSON error body comes back as bytes too. A real PDF starts %PDF-.
      if (bytes.length < 5 ||
          bytes[0] != 0x25 || bytes[1] != 0x50 ||
          bytes[2] != 0x44 || bytes[3] != 0x46) {
        return null;
      }
      return bytes;
    } catch (_) {
      return null;
    }
  }

  /// Cancel a booking.
  ///
  /// [otp] is the emailed one-time code. The server requires it (W4:
  /// cancellation triggers a refund, and a session alone is not enough to
  /// authorise that) and answers `otpRequired` without one — so a cancel
  /// sent from here without a code is refused outright, which is exactly
  /// what happened between the server change landing and this one.
  Future<Map<String, dynamic>> cancelBooking(
      String bookingId, String reason, {String? otp}) async {
    final url = "$baseUrl/user/cancel/booking";
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.headers['Authorization'] = "Bearer $token";
    final data = {
      "bookingId": bookingId,
      "reason": reason,
      // Omitted rather than sent empty: the schema treats an absent code and a
      // blank one differently, and a blank one reads as a wrong code.
      if (otp != null && otp.trim().isNotEmpty) "otp": otp.trim(),
    };
    try {
      final response = await _dio.post(url, data: data);
      print("Cancel booking response: ${response.data}");
      // A 200 with `success: false` is still a refusal.
      //
      // This returned response.data whatever it said, so the controller
      // reported success, the page flipped its badge to "Cancelled" and
      // toasted "Booking cancelled" — while the server had cancelled nothing.
      // The booking then failed to appear under Cancelled, because it never
      // was. Same swallow as the traveller delete.
      final body = response.data;
      if (body is Map && body['success'] == false) {
        throw Exception(body['message']?.toString() ??
            'This booking could not be cancelled.');
      }
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
