
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:rent_home/models/host_booking_history_model.dart';
import 'package:rent_home/models/host_negotiation.dart';
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
      requestHeader: kDebugMode,
      requestBody: kDebugMode,
      responseBody: kDebugMode,
      responseHeader: false,
      error: true,
      compact: true,
      maxWidth: 90,
      enabled: kDebugMode,
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
    String? sort,
    /// active | inactive | review | draft. Omit for everything.
    String? status,
  }) async {
    final url = '$baseUrl/host/property-search';
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.headers['Authorization'] = 'Bearer $token';

    try {
      final response = await _dio.post(url, data: {
        'page': page,
        'limit': limit,
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        if (sort != null && sort.isNotEmpty && sort != 'newest') 'sort': sort,
        if (status != null && status.isNotEmpty) 'status': status,
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

  /// Every negotiation addressed to this host, newest first (A-70).
  ///
  /// The endpoint has existed since negotiation shipped and nothing called it,
  /// so a host could only find an offer by catching its push notification.
  /// Returns an empty list rather than throwing — an empty negotiations
  /// section is a correct dashboard, an exception is a broken one.
  /// POST /host/support/tickets/search — this host's own tickets.
  ///
  /// The app's Support screen was a WhatsApp/chat launcher only; the ticket
  /// endpoints shipped with the web host portal and the app never called them,
  /// so an issue raised in the app left no record anyone could track.
  Future<List<Map<String, dynamic>>> getSupportTickets() async {
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.headers['Authorization'] = 'Bearer $token';
    try {
      final response = await _dio.post("/host/support/tickets/search", data: {});
      final data = response.data is Map ? response.data['data'] : null;
      final list = data is Map ? data['items'] : null;
      if (list is! List) return const [];
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (err) {
      return const [];
    }
  }

  /// POST /host/support/tickets/create.
  ///
  /// `category` is REQUIRED by the server and must be one of its enum values —
  /// the web form omitted it for months, so every ticket was refused with a
  /// bare "category is required". Returns null on success, else a message.
  Future<String?> createSupportTicket({
    required String subject,
    required String category,
    required String message,
  }) async {
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.headers['Authorization'] = 'Bearer $token';
    try {
      final res = await _dio.post("/host/support/tickets/create",
          data: {"subject": subject, "category": category, "message": message});
      final ok = res.data is Map && res.data['success'] == true;
      return ok ? null : 'Could not raise that ticket.';
    } on DioException catch (e) {
      final d = e.response?.data;
      return (d is Map ? d['message']?.toString() : null) ??
          'Could not raise that ticket.';
    } catch (_) {
      return 'Could not raise that ticket.';
    }
  }

  /// POST /host/support/tickets/reply — add a message to an existing ticket.
  Future<String?> replySupportTicket({
    required int ticketId,
    required String message,
  }) async {
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.headers['Authorization'] = 'Bearer $token';
    try {
      final res = await _dio.post("/host/support/tickets/reply",
          data: {"ticketId": ticketId, "message": message});
      final ok = res.data is Map && res.data['success'] == true;
      return ok ? null : 'Could not send that reply.';
    } on DioException catch (e) {
      final d = e.response?.data;
      return (d is Map ? d['message']?.toString() : null) ??
          'Could not send that reply.';
    } catch (_) {
      return 'Could not send that reply.';
    }
  }

  /// POST /host/statements/search — one entry per month a host earned in.
  ///
  /// The endpoint shipped with the finance sprint and neither client called
  /// it: on the web /host/statements redirected to Payouts, and the app had
  /// no reader at all. A statement_id is a YYYY-MM period.
  Future<List<Map<String, dynamic>>> getStatements() async {
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.headers['Authorization'] = 'Bearer $token';
    try {
      final response =
          await _dio.post("/host/statements/search", data: {"page": 1, "limit": 50});
      final data = response.data is Map ? response.data['data'] : null;
      final list = data is Map ? (data['items'] ?? data['rows']) : null;
      if (list is! List) return const [];
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (err) {
      return const [];
    }
  }

  /// GET /host/statements/download/:id — the month's PDF, as bytes.
  Future<List<int>?> downloadStatement(String statementId) async {
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.headers['Authorization'] = 'Bearer $token';
    try {
      final response = await _dio.get<List<int>>(
        "/host/statements/download/$statementId",
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data;
    } catch (err) {
      return null;
    }
  }

  /// GET /host/earnings/summary — the figures the web Earnings page shows.
  ///
  /// The app had no earnings reader at all: the home card summed
  /// /host/transaction-history client-side, which is a different question
  /// (payments received) answered with a different number. This is the same
  /// endpoint and the same arithmetic the web uses, so the two platforms can
  /// no longer disagree about what a host has earned.
  ///
  /// Returns an empty map rather than throwing — an empty earnings screen is
  /// a correct one for a new host; an exception is a broken app.
  Future<Map<String, dynamic>> getEarningsSummary() async {
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.headers['Authorization'] = 'Bearer $token';
    try {
      final response = await _dio.get("/host/earnings/summary");
      final data = response.data is Map ? response.data['data'] : null;
      return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
    } catch (err) {
      return <String, dynamic>{};
    }
  }

  Future<List<HostNegotiation>> getNegotiations() async {
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.headers['Authorization'] = 'Bearer $token';
    try {
      final response = await _dio.get("/host/negotiations/list");
      final data = response.data is Map ? response.data['data'] : null;
      final list = data is Map ? data['negotiations'] : null;
      if (list is! List) return const [];
      return list
          .whereType<Map>()
          .map((e) => HostNegotiation.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (err) {
      return const [];
    }
  }

  /// Answer an offer: 'accept' | 'decline' | 'counter'.
  ///
  /// POST /host/negotiations/respond has existed as long as the list endpoint,
  /// and the app never called it — the host could SEE offers and had no way to
  /// answer one anywhere in the app. Accepting mints the guest's one-time 24h
  /// coupon at the agreed price; the server returns its code, which is worth
  /// showing so the host knows the deal actually issued.
  ///
  /// Throws with the server's own words so a refusal is readable.
  Future<({bool ok, String? couponCode, String? message})> respondNegotiation({
    required int offerId,
    required String action,
    double? counterPrice,
    String? message,
  }) async {
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.headers['Authorization'] = 'Bearer $token';
    try {
      final response = await _dio.post("/host/negotiations/respond", data: {
        "offerId": offerId,
        "action": action,
        if (counterPrice != null) "counterPrice": counterPrice,
        if (message != null && message.trim().isNotEmpty)
          "message": message.trim(),
      });
      final body = response.data;
      final ok = body is Map && body['success'] == true;
      final data = body is Map ? body['data'] : null;
      return (
        ok: ok,
        couponCode: data is Map ? data['couponCode']?.toString() : null,
        message: body is Map ? body['message']?.toString() : null,
      );
    } on DioException catch (err) {
      final data = err.response?.data;
      final msg = data is Map ? data['message'] : null;
      throw Exception(msg is List
          ? msg.join(', ')
          : (msg?.toString() ?? 'Could not send your response.'));
    }
  }

  /// The mirror of no-show: the guest DID arrive, and the host says so.
  /// Returns the server's message on failure via exception.
  Future<void> markBookingCheckIn(String bookingId) async {
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.headers['Authorization'] = 'Bearer $token';
    try {
      final response = await _dio
          .post("/host/booking/check-in", data: {"bookingId": bookingId});
      final body = response.data;
      if (body is! Map || body['success'] != true) {
        throw Exception(
            (body is Map ? body['message'] : null)?.toString() ??
                'Could not check the guest in.');
      }
    } on DioException catch (err) {
      final data = err.response?.data;
      final msg = data is Map ? data['message'] : null;
      throw Exception(msg is List
          ? msg.join(', ')
          : (msg?.toString() ?? 'Could not check the guest in.'));
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
