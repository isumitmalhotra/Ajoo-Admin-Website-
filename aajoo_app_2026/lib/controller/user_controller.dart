import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rent_home/models/booking_history_response_model.dart';
import 'package:rent_home/models/ongoing_reponse.dart';
import 'package:rent_home/models/single_property_response.dart';
import 'package:rent_home/models/user_review_model.dart';
import 'package:rent_home/service/property_service.dart';
import 'package:rent_home/service/user_service.dart';
import 'package:rent_home/service/booking_service.dart';

class UserController extends GetxController {
  final UserService _userService = UserService();
  final PropertyService _propertyService = PropertyService();
  final RxBool isLoading = false.obs;
  final RxBool isError = false.obs;
  final Rx<BookingHistoryResponse?> bookingHistory =
      Rx<BookingHistoryResponse?>(null);
  final Rx<SinglePropertyResponse?> property =
      Rx<SinglePropertyResponse?>(null);
  final Rx<LatLng> propertyLocation = const LatLng(0.0, 0.0).obs;
  final Rx<OnGoingBookingResponse?> ongoingBookings =
      Rx<OnGoingBookingResponse?>(null);
  final Rx<UserReviewResponse?> userReviews = Rx<UserReviewResponse?>(null);
  Future<void> fetchOngoingBookings() async {
    isLoading.value = true;
    try {
      final bookings = await _userService.getOngoingBookings();
      ongoingBookings.value = bookings;
      print("ongoing booking created ");
      isError.value = false;
    } catch (e) {
      print("ONGOING - $e");
      isError.value = true;
      // showSnackbar("Error", e.toString(), true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getUserReviews() async {
    isLoading.value = true;
    try {
      final response = await _userService.getUserReviews();
      userReviews.value = response;
      print("User Reviews: ${userReviews.value}");
      isError.value = false;
    } catch (e) {
      isError.value = true;
      // showSnackbar("Error", e.toString(), true);
    } finally {
      isLoading.value = false;
    }
  }

  /// Uploads a new profile picture. Returns the new image URL on success so
  /// the caller can update the avatar immediately, or null on failure.
  Future<String?> addProfileImage(File image) async {
    isLoading.value = true;
    try {
      final imageUrl = await _userService.uploadProfileImage(image);
      if (imageUrl != null && imageUrl.isNotEmpty) {
        showSnackbar("Success", "Profile image updated successfully", false);
        return imageUrl;
      } else {
        showSnackbar("Error", "Failed to update profile image", true);
        return null;
      }
    } catch (e) {
      isError.value = true;
      showSnackbar("Error", e.toString(), true);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Removes the current user's profile picture on the server.
  /// Returns true on success (caller is expected to refresh user data).
  Future<bool> removeProfileImage() async {
    isLoading.value = true;
    try {
      final ok = await _userService.deleteProfileImage();
      if (ok) {
        showSnackbar("Removed", "Profile photo removed", false);
      } else {
        showSnackbar("Error", "Could not remove photo. Please try again.", true);
      }
      return ok;
    } catch (e) {
      isError.value = true;
      showSnackbar("Error", e.toString(), true);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Soft-deletes one of the current user's reviews.
  /// Returns true on success (caller is expected to refresh the review list).
  Future<bool> deleteUserReview(int reviewId) async {
    try {
      final ok = await _userService.deleteUserReview(reviewId);
      if (ok) {
        showSnackbar("Deleted", "Your review was removed", false);
      } else {
        showSnackbar(
            "Error", "Could not delete review. Please try again.", true);
      }
      return ok;
    } catch (e) {
      isError.value = true;
      showSnackbar("Error", e.toString(), true);
      return false;
    }
  }

  /// Changes the current user's password via `POST /user/update-password`.
  /// Surfaces the server's message on both success and failure so the user
  /// sees the real reason (e.g. wrong current password). Returns true on
  /// success (caller is expected to pop the screen).
  Future<bool> changePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    isLoading.value = true;
    try {
      final result = await _userService.changePassword(
        userId: userId,
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      showSnackbar(
        result.success ? "Success" : "Error",
        result.message,
        !result.success,
      );
      return result.success;
    } catch (e) {
      isError.value = true;
      showSnackbar("Error", e.toString(), true);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getUserHistory() async {
    isLoading.value = true;
    try {
      final response = await _userService.getBookingHistory();
      print(response.data);
      bookingHistory.value = response;
      isError.value = false;
    } catch (e) {
      isError.value = true;
      showSnackbar("Error", e.toString(), true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getProperty(int id) async {
    print("Property ID: $id");
    isLoading.value = true;
    try {
      final response = await _propertyService.getSingleProperty(id);
      property.value = response;
      propertyLocation.value = LatLng(
        double.parse(response.data!.propertyLatitude!),
        double.parse(response.data!.propertyLongitude!),
      );
      print("Property Location: ${propertyLocation.value.latitude}");
      isError.value = false;
    } catch (e) {
      print(e);
      isError.value = true;
      showSnackbar("Error", e.toString(), true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addReview(Map<String, dynamic> reviewData) async {
    try {
      final response = await _userService.addReview(reviewData);
      if (response) {
        showSnackbar("Success", "Review added successfully", false);
      } else {
        showSnackbar("Error", "Failed to add review", true);
      }
    } catch (e) {
      isError.value = true;
      showSnackbar("Error", e.toString(), true);
    } finally {}
  }

  Future<Map<String, dynamic>?> createOngoingBookingPayment(
      String bookingId) async {
    try {
      isLoading.value = true;
      // Create BookingService instance locally to avoid circular dependency
      final bookingService = BookingService();
      final result =
          await bookingService.createOngoingBookingPayment(bookingId);
      showSnackbar("Success", "Payment initiated successfully", false);
      return result;
    } catch (e) {
      showSnackbar("Error", "Failed to create payment: ${e.toString()}", true);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  void showSnackbar(String title, String message, bool isError) {
    // Defer to after the current frame and guard against overlay/context
    // errors. Get.snackbar can throw "No Overlay widget found" when invoked
    // mid-transition (e.g. right after returning from the image picker); a
    // failed toast must never break the business flow that triggered it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        Get.snackbar(
          title,
          message,
          snackPosition: SnackPosition.TOP,
          backgroundColor: isError ? Colors.red[100] : Colors.green[100],
          colorText: isError ? Colors.red[900] : Colors.green[900],
          duration: const Duration(seconds: 3),
        );
      } catch (e) {
        print("showSnackbar failed: $e");
      }
    });
  }
}
