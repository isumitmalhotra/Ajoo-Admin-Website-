import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rent_home/models/host_account_details_model.dart';
import 'package:rent_home/models/payout_list_model.dart';
import 'package:rent_home/data/ApiConstants.dart';

class HostPayoutService {
  final Dio _dio = Dio();
  final String baseUrl = '${Apiconstants.baseUrl}/';
  HostPayoutService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.contentType = 'application/json';
  }

  Future<void> _attachAuth() async {
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<bool> createPayoutRequest(int amount) async {
    const endpoint = "payout/request/create";
    await _attachAuth();

    try {
      final response = await _dio.post(endpoint, data: {
        'amount': amount,
      });
      return response.data['success'] == true;
    } on DioException catch (err) {
      _handleError(err);
      return false;
    } catch (e) {
      print("Error in creating payout request: $e");
      return false;
    }
  }

  /// What the host has earned and what has been paid.
  ///
  /// This used to call `/payout/request/list`, the old "ask us for your money"
  /// flow: it sums `tbl_host_earnings` and lists `tbl_payout_req`. The platform
  /// stopped working that way when the payout engine shipped — earnings land in
  /// `tbl_financial_ledger` and payouts are raised automatically into
  /// `tbl_payouts`, which is what the website reads.
  ///
  /// Checked against production on 2026-08-31 with the same host signed in on
  /// both: the website showed ₹30,333.16 pending across ten payouts while this
  /// screen showed ₹0 and "No Payout History". Nothing was broken in the sense
  /// of erroring — it asked the wrong table and got a truthful zero.
  ///
  /// It now reads the two endpoints the website reads, so one ledger answers
  /// both. The old shape is kept because the screens are built on it.
  Future<PayoutListResponse> getPayoutList() async {
    await _attachAuth();

    try {
      // Fetched together: a total with no rows under it, or rows with no
      // total over them, is a half-drawn screen either way.
      final results = await Future.wait([
        _dio.get('/host/earnings/summary'),
        _dio.get('/host/payout/history?limit=50'),
      ]);

      Map<String, dynamic> dataOf(Response r) {
        final b = r.data;
        return b is Map && b['data'] is Map
            ? Map<String, dynamic>.from(b['data'] as Map)
            : <String, dynamic>{};
      }

      num n(Object? v) => v is num ? v : num.tryParse('${v ?? ''}') ?? 0;

      final earnings = dataOf(results[0]);
      final history = dataOf(results[1]);

      final rows = (history['items'] is List ? history['items'] as List : const [])
          .whereType<Map>()
          .map((e) => PayoutRequest.fromPayoutRow(Map<String, dynamic>.from(e)))
          .toList();

      return PayoutListResponse(
        success: true,
        message: 'success',
        data: Data(
          hostTotalEarning: n(earnings['totalEarnings']),
          // "Pending", not "earned minus paid": a payout an admin has put on
          // hold is not on its way, and the server already excludes those.
          earningLeft: n(earnings['pendingPayouts']),
          settled: n(earnings['settledPayouts']),
          payoutRequests: rows,
        ),
      );
    } on DioException catch (err) {
      _handleError(err);
      throw Exception("Error in fetching payout list: $err");
    } catch (e) {
      print("Error in fetching payout list: $e");
      throw Exception("Error in fetching payout list: $e");
    }
  }

  /// Returns the host's saved bank account details, or `null` if none exist.
  Future<HostAccountDetails?> getHostAccountDetails() async {
    const endpoint = "payout/account/details";
    await _attachAuth();

    try {
      final response = await _dio.get(endpoint);
      final data = response.data;
      if (data is! Map || data['success'] != true) return null;
      final raw = data['data'];
      if (raw == null || raw is! Map) return null;
      return HostAccountDetails.fromJson(Map<String, dynamic>.from(raw));
    } on DioException catch (err) {
      _handleError(err);
      return null;
    } catch (e) {
      print("Error in fetching host account details: $e");
      return null;
    }
  }

  /// Adds or updates the host's bank account.
  /// Pass [accountId] to update an existing record; omit to create or upsert.
  Future<bool> saveHostAccountDetails({
    required String accountNumber,
    required String accountIfsc,
    /// REQUIRED for a transfer. RazorpayX cannot initiate one without the
    /// name on the account, and the server now refuses a bank account that
    /// arrives without it — the form collected this and never sent it.
    required String accountHolderName,
    String? bankName,
    int? accountId,
  }) async {
    const endpoint = "payout/account/details-add";
    await _attachAuth();

    try {
      final payload = <String, dynamic>{
        'accountNumber': accountNumber,
        'accountIfsc': accountIfsc,
        'accountHolderName': accountHolderName,
        if (bankName != null && bankName.isNotEmpty) 'bankName': bankName,
      };
      if (accountId != null) payload['accountId'] = accountId;

      final response = await _dio.post(endpoint, data: payload);
      return response.data['success'] == true;
    } on DioException catch (err) {
      _handleError(err);
      return false;
    } catch (e) {
      print("Error in saving host account details: $e");
      return false;
    }
  }

  void _handleError(DioException err) {
    if (err.response != null) {
      print('Error: ${err.response?.data}');
    } else {
      print('Error: ${err.message}');
    }
  }
}
