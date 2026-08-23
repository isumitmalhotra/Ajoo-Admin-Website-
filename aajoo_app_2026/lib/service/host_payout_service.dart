import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rent_home/models/host_account_details_model.dart';
import 'package:rent_home/models/payout_list_model.dart';

class HostPayoutService {
  final Dio _dio = Dio();
  final String baseUrl = 'https://aajaodev.onrender.com/';
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

  Future<PayoutListResponse> getPayoutList() async {
    const endpoint = "payout/request/list";
    await _attachAuth();

    try {
      final response = await _dio.get(endpoint);
      return PayoutListResponse.fromJson(response.data);
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
