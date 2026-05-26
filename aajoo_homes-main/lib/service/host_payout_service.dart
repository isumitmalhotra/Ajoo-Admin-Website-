import 'package:dio/dio.dart';
import 'package:rent_home/data/source/remote/api_client/api_client.dart';
import 'package:rent_home/data/models/payout_list_model.dart';

class HostPayoutService {
  final ApiClient apiClient = ApiClient();
  HostPayoutService();

  Future<bool> createPayoutRequest(int amount) async {
    try {
      final response = await apiClient.post("/payout/request/create", data: {
        'amount': amount,
      });
      return response['success'];
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  Future<PayoutListResponse> getPayoutList() async {
    try {
      final response = await apiClient.get("/payout/request/list");
      return PayoutListResponse.fromJson(response);
    } catch (e) {
      throw Exception("Error in fetching payout list: $e");
    }
  }

  void _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        print('Error: ${error.response?.data}');
      } else {
        print('Error: ${error.message}');
      }
    }
  }
}
