import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rent_home/controller/alert_dialog.dart';
import 'package:rent_home/data/models/booking_history_response_model.dart';
import 'package:rent_home/data/models/ongoing_reponse.dart';
import 'package:rent_home/data/models/single_property_response.dart';
import 'package:rent_home/data/models/user_review_model.dart';
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
  //final Rxn<LatLng> propertyLocation = LatLng(0.0, 0.0).obs;
  final Rxn<LatLng> propertyLocation = Rxn<LatLng>();

  final Rx<OnGoingBookingResponse?> ongoingBookings =
      Rx<OnGoingBookingResponse?>(null);
  final Rx<UserReviewResponse?> userReviews = Rx<UserReviewResponse?>(null);
  Future<void> fetchOngoingBookings() async {
    isLoading.value = true;
    try {
      final bookings = await _userService.getOngoingBookings();
      ongoingBookings.value = bookings;
      isError.value = false;
    } catch (e) {
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

  Future<void> addProfileImage(File image) async {
    isLoading.value = true;
    try {
      final response = await _userService.uploadProfileImage(image);
      if (response) {
        showSnackbar("Success", "Profile image updated successfully", false);
      } else {
        showSnackbar("Error", "Failed to update profile image", true);
      }
    } catch (e) {
      isError.value = true;
      showSnackbar("Error", e.toString(), true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getUserHistory() async {
    isLoading.value = true;
    try {
      final response = await _userService.getBookingHistory();
      print(response.data);
      ;
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
    isLoading.value = true;
    try {
      final response = await _propertyService.getSingleProperty(id);
      property.value = response;
      propertyLocation.value = LatLng(
        double.parse(response.data!.propertyLatitude!),
        double.parse(response.data!.propertyLongitude!),
      );
      isError.value = false;
    } catch (e) {
      isError.value = true;
      showSnackbar("Error", e.toString(), true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addReview(Map<String, dynamic> reviewData) async {
    try {
      var desc = reviewData["description"];
      if (desc == null || desc.toString().trim().isEmpty) {
        showSnackbar("Error", "Please add description", true);
        return;
      }

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
    showAlert(title, message, isError);
  }
}
