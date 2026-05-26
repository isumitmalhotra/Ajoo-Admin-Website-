
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:rent_home/controller/user_controller.dart';
import 'package:rent_home/data/source/remote/api_client/api_client.dart';
import 'package:rent_home/data/models/create_booking_response.dart';
import 'package:rent_home/data/models/single_property_response.dart';

class BookingService {
  final ApiClient apiClient = ApiClient();
 

  UserController? get userController {
    try {
      return Get.find<UserController>();
    } catch (e) {
      return null;
    }
  }

  Future<BookingResponse> createBooking(Map<String, dynamic> data) async {
    try {
      final response = await apiClient.post('/booking/create', data: data);
      userController?.fetchOngoingBookings();
      return BookingResponse.fromJson(response);
    } catch (e) {
      throw _handleError(e);
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
    try {
      final response = await apiClient.get("/properties/$id");
      final propertyResponse = SinglePropertyResponse.fromJson(response);
      return propertyResponse;
    } on Exception catch (e) {
      _handleError(e);
      return SinglePropertyResponse(
          success: false,
          message: "Failed to get property",
          data: SinglePropertyData());
    }
  }

  Future<bool> verifyPayment(
      String orderId, String paymentId, String signature) async {
    try {
      final response = await apiClient.post('/create/payment-verify', data: {
        "orderId": orderId,
        "paymentId": paymentId,
        "signature": signature,
      });
      return response['success'];
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> cancelBooking(String bookingId, String reason) async {
    final data = {
      "bookingId": bookingId,
      "reason": reason,
    };
    try {
      final response = await apiClient.post('/user/cancel/booking', data: data);
      userController?.fetchOngoingBookings();
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createOngoingBookingPayment(String bookingId) async {
    final data = {
      "bookingId": bookingId,
    };
    try {
      final response = await apiClient.post('/user/ongoing/bookings/payment/create', data: data);
      return response;
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
