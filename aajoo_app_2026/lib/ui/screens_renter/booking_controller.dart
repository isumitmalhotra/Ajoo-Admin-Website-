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

  /*
   * Booking limits, checked before the request so the guest gets an instant
   * answer rather than a round trip.
   *
   * These used to decide what counts as "active" by comparing the status
   * TITLE against "Cancelled" and "Completed". There is no Completed status:
   * tbl_book_statuses has Payment Pending, Cancelled, Paid, Booked,
   * "Check In ", "Check Out " (with the trailing spaces), Booking Confirmed,
   * Payment Received and Running. So that comparison excluded exactly one
   * status and everything else counted, forever.
   *
   * What it cost: the app creates the booking BEFORE opening Razorpay, so an
   * abandoned card payment leaves a Payment Pending row behind. Three of those
   * and the guest was locked out with "You cannot have more than 3 active
   * bookings" — for three payments they never made.
   *
   * Statuses, not titles, now — and the same set the backend's own guard uses,
   * which deliberately does not treat an unpaid pending booking as holding a
   * slot beyond a short window.
   */
  // 2 Cancelled, 7 Check Out: finished either way, never blocking.
  static const _finishedStatuses = {2, 7};
  // 1 Payment Pending: created before Razorpay, so it may be an abandoned
  // checkout rather than a real reservation. The backend holds these for 30
  // minutes; past that they hold nothing.
  static const _pendingStatus = 1;
  static const _pendingHold = Duration(minutes: 30);

  bool _countsAsActive(dynamic b) {
    final status = b.bookStatus as int;
    if (_finishedStatuses.contains(status)) return false;
    if (status == _pendingStatus) {
      final added = b.bookAddedAt as DateTime?;
      // No timestamp — treat it as live rather than silently letting a real
      // reservation through.
      if (added == null) return true;
      return DateTime.now().difference(added) < _pendingHold;
    }
    return true;
  }

  Future<BookingResponse> createBooking(Map<String, dynamic> data) async {
    // 1. Check Booking Limits
    final ongoing = userController.ongoingBookings.value;
    if (ongoing != null && ongoing.data.bookings.isNotEmpty) {
      final activeBookings =
          ongoing.data.bookings.where(_countsAsActive).toList();

      // Rule 1: Max 3 active bookings total
      if (activeBookings.length >= 3) {
        showAlert(
            "Booking Limit Reached",
            "You cannot have more than 3 active bookings. Please complete or cancel an existing booking.",
            true);
        throw Exception("Booking limit reached (Max 3 active bookings)");
      }

      // Rule 2: Max 1 active Pay on Arrival (COD) booking.
      // Only reached when the guest already HAS one and is starting another —
      // it is not a policy notice shown on a first booking.
      final isNewBookingCod = data['isCod'] == true;
      if (isNewBookingCod) {
        final activeCodBookings =
            activeBookings.where((b) => b.bookIsCod).length;
        if (activeCodBookings >= 1) {
          showAlert(
              "Pay on Arrival Limit",
              "You can only have 1 active 'Pay on Arrival' booking. Please complete or cancel that one, or pay online for this stay.",
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
        showAlert(
            "Payment Success", "Payment has been successfully done", false);
      } else {
        showAlert("Payment Failed", "Payment has been failed", true);
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
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  void showSnackbar(String title, String message, bool isError) {
    showAlert(title, message, isError);
  }
}
