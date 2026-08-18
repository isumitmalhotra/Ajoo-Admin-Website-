import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/controller/user_controller.dart';
import 'package:rent_home/models/create_booking_response.dart';
import 'package:rent_home/service/booking_service.dart';

class BookingController extends GetxController {
  RxBool isLoading = false.obs;
  RxString error = "".obs;
  final Rx<BookingResponse?> bookingResponse = Rx<BookingResponse?>(null);
  final BookingService _bookingService = BookingService();
  final UserController userController = Get.find<UserController>();

  Future<BookingResponse> createBooking(Map<String, dynamic> data) async {
    // No client-side booking caps.
    //
    // This used to enforce "max 3 active bookings" and "max 1 pay-on-arrival"
    // in the app. Neither rule exists on the web or in the API — they were
    // invented here — so a guest with three live bookings simply could not
    // book from the phone at all, and the thrown exception was never caught,
    // so the sheet closed with no message. That is the "can't book from
    // mobile" report.
    //
    // The server owns this policy: it allows unlimited bookings and caps only
    // OUTSTANDING pay-on-arrival ones (unpaid and not yet checked out). It
    // returns a plain message when it refuses, which the UI surfaces. A second
    // copy of the rule here could only ever drift out of step with it.
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
        showSnackbar("Booking Failed", "Booking has been failed", true);
      }
      return bookingResponse.value!;
    } catch (e) {
      error.value = e.toString();
      rethrow;
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
        showSnackbar(
            "Payment Success", "Payment has been successfully done", false);
      } else {
        showSnackbar("Payment Failed", "Payment has been failed", true);
      }
      return response;
    } catch (e) {
      error.value = e.toString();
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> cancelBooking(String bookingId, String reason) async {
    isLoading.value = true;
    try {
      await _bookingService.cancelBooking(bookingId, reason);
      return true;
    } catch (e) {
      error.value = e.toString();
      showSnackbar("Error", "Failed to cancel booking: ${e.toString()}", true);
      return false;
    } finally {
      // No `return` here: a return inside finally overrides the catch's
      // `return false`, so every FAILED cancellation reported success and the
      // booking quietly stayed alive.
      isLoading.value = false;
      userController.fetchOngoingBookings();
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
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  void showSnackbar(String title, String message, bool isError) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: isError ? Colors.red[100] : Colors.green[100],
      colorText: isError ? Colors.red[900] : Colors.green[900],
      duration: const Duration(seconds: 3),
    );
  }
}
