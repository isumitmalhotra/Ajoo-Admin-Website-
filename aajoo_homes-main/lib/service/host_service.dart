
import 'package:dio/dio.dart';
import 'package:rent_home/data/source/remote/api_client/api_client.dart';
import 'package:rent_home/data/models/host_booking_history_model.dart';
import 'package:rent_home/data/models/host_ongoing_response.dart';
import 'package:rent_home/data/models/host_properties_reponse.dart' as hostResponse;
import 'package:rent_home/data/models/transaction_model.dart';

class HostService {
  final ApiClient apiClient = ApiClient();
  HostService();

  void setToken(String token) {
    apiClient.setToken(token);
  }

  Future<bool> updatePropertyStatus(int propId, int status) async {
    try {
      final response =
          await apiClient.post('/host/property/update-status', data: {'propertyId': propId, 'status': status});
      return response.data['success'];
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<hostResponse.HostPropertiesResponse> getHostProperties() async {
    try {
      final response = await apiClient.post('/host/property-search', data: {});
      final json = response;
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
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<TransactionResponse> getHostTransactions() async {
    try {
      final response = await apiClient.post("/host/transaction-history", data: {});
      final model = TransactionResponse.fromJson(response);
      return model;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<HostBookingHistoryResponse> getBookingHistory() async {
    try {
      final response = await apiClient.post("/host/booking-history");
      final model = HostBookingHistoryResponse.fromJson(response);
      return model;
    } catch (err) {
      throw _handleError(err);
    }
  }

  Future<bool> addUserReview(int rating, String id, String description, String title) async {
    try {
      final response = await apiClient.post("/review/host/add-user-review", data: {
        "rating": rating,
        "bookingId": id,
        "description": description,
        "title": title,
      });
        return response['success'];
    } catch (err) {
        return false;
    }
  }

  Future<HostOnGoingBookingResponse> getHostOngoing(int hostId) async {
    try {
      final response = await apiClient.post("/booking/ongoing-host");
      final model = HostOnGoingBookingResponse.fromJson(response);
      return model;
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
