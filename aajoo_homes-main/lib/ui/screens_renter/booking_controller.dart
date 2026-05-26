import 'package:get/get.dart';
import 'package:rent_home/controller/alert_dialog.dart';
import 'package:rent_home/controller/user_controller.dart';
import 'package:rent_home/data/models/create_booking_response.dart';
import 'package:rent_home/service/booking_service.dart';

class BookingController extends GetxController {
  RxBool isLoading = false.obs;
  RxString error = "".obs;
  final Rx<BookingResponse?> bookingResponse = Rx<BookingResponse?>(null);
  final BookingService _bookingService = BookingService();
  final UserController userController = Get.find<UserController>();

  Future<BookingResponse> createBooking(Map<String, dynamic> data) async {
    // 1. Check Booking Limits
    final ongoing = userController.ongoingBookings.value;
    if (ongoing != null && ongoing.data.bookings.isNotEmpty) {
      // Filter for ACTIVE bookings (exclude Cancelled and Completed)
      final activeBookings = ongoing.data.bookings.where((b) {
        final status = b.bookingStatusBsTitle;
        return status != "Cancelled" && status != "Completed";
      }).toList();

      // Rule 1: Max 3 active bookings total
      if (activeBookings.length >= 3) {
        showAlert(
            "Booking Limit Reached",
            "You cannot have more than 3 active bookings. Please complete or cancel an existing booking.",
            true);
        // Return a dummy failed response or throw error to stop execution
        // Since we need to return BookingResponse, we can throw an exception or return a failure object if possible.
        // Throwing exception is safer to stop the flow immediately.
        throw Exception("Booking limit reached (Max 3 active bookings)");
      }

      // Rule 2: Max 1 active Pay on Arrival (COD) booking
      // Check if the NEW booking is COD
      final isNewBookingCod = data['isCod'] == true;

      if (isNewBookingCod) {
        final activeCodBookings =
            activeBookings.where((b) => b.bookIsCod).length;
        if (activeCodBookings >= 1) {
          showAlert(
              "Pay on Arrival Limit",
              "You can only have 1 active 'Pay on Arrival' booking. Please choose online payment or complete your existing booking.",
              true);
          throw Exception(
              "COD limit reached (Max 1 active Pay on Arrival booking)");
        }
      }
    }

    isLoading.value = true;
    try {
      bookingResponse.value = await _bookingService.createBooking(data);
      // Debug: booking response
      // final br = bookingResponse.value;
      // if (br?.data != null) {
      //   print(br!.data!.toJson());
      // }
      if (bookingResponse.value?.success == true) {
      } else {
        showAlert("Booking Failed", "Booking has been failed", true);
      }
      return bookingResponse.value!;
    } catch (e) {
      error.value = e.toString();
      throw e;
    } finally {
      userController.fetchOngoingBookings();
      isLoading.value = false;
    }
  }

  Future<bool> verifyPayment(
      String orderId, String paymentId, String signature) async {
    isLoading.value = true;
    try {
      final response =
          await _bookingService.verifyPayment(orderId, paymentId, signature);
      if (response) {
        showAlert(
            "Payment Success", "Payment has been successfully done", false);
      } else {
        showAlert("Payment Failed", "Payment has been failed", true);
      }
      return response;
    } catch (e) {
      error.value = e.toString();
      throw e;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> cancelBooking(String bookingId, String reason) async {
    isLoading.value = true;
    try {
      await _bookingService.cancelBooking(bookingId, reason);
    } catch (e) {
      error.value = e.toString();
      showAlert("Error", "Failed to cancel booking: ${e.toString()}", true);
      return false;
    } finally {
      isLoading.value = false;
      userController.fetchOngoingBookings();

      return true;
    }
  }

  Future<Map<String, dynamic>> createOngoingBookingPayment(
      String bookingId) async {
    isLoading.value = true;
    try {
      final response =
          await _bookingService.createOngoingBookingPayment(bookingId);
      return response;
    } catch (e) {
      error.value = e.toString();
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> getPropertyLatLong(int propertyId) async {
    isLoading.value = true;
    try {
      final response = await _bookingService.getPropertyLatLong(propertyId);
      return response;
    } catch (e) {
      error.value = e.toString();
      throw e;
    } finally {
      isLoading.value = false;
    }
  }

  void showSnackbar(String title, String message, bool isError) {
    showAlert(title, message, isError);
  }
}
