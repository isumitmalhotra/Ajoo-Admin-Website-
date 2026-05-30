import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:rent_home/controller/alert_dialog.dart';
import 'package:rent_home/data/models/host_booking_history_model.dart';
import 'package:rent_home/data/models/host_ongoing_response.dart';
import 'package:rent_home/data/models/host_properties_reponse.dart';
import 'package:rent_home/data/models/transaction_model.dart';
import 'package:rent_home/service/host_service.dart';
import 'package:rent_home/service/property_service.dart';

class HostBookingHistoryController extends GetxController {
  final HostService hostService = HostService();
  final storage = const FlutterSecureStorage();
  RxBool loading = false.obs;
  RxString error = ''.obs;

  final isLoading = false.obs;
  final isSubmittingReview = false.obs;
  final errorMessage = RxnString();

  String TOKEN_KEY = 'user_token';

  Rx<HostBookingHistoryResponse?> hostBookingHistoryResponse =
      Rx<HostBookingHistoryResponse?>(null);

  Future<void> _initialize() async {
    final token = await storage.read(key: TOKEN_KEY);
    hostService.setToken(token ?? '');
  }

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> getHostBookingHistory() async {
    try {
      loading.value = true;
      final response = await hostService.getBookingHistory();
      hostBookingHistoryResponse.value = response;
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<void> addUserReview(
      int rating, String id, String description, String title) async {
    loading.value = true;
    try {
      final response =
          await hostService.addUserReview(rating, id, description, title);
      if (response) {
        showSnackbar("Review Added Successfully", "", false);
      } else {
        showSnackbar("Something went Wrong", "error adding review", true);
      }
    } catch (e) {
      error.value = e.toString();
      showSnackbar(e.toString(), "Error adding review", true);
    } finally {
      loading.value = false;
    }
  }

  void showSnackbar(String title, String message, bool isError) {
    showAlert(title, message, isError);
  }

  Future<ReviewResult> submitReview(
    int rating,
    String id,
    String description,
    String title,
  ) async {
    try {
      isSubmittingReview.value = true;
      errorMessage.value = null;

      print("submitReview button tapped");

      final response =
          await hostService.addUserReview(rating, id, description, title);

      if (!response) {
        return ReviewResult(
          isSuccess: false,
          message: "Error adding review",
        );
      }

      return ReviewResult(
        isSuccess: true,
        message: "Review added successfully",
      );
    } catch (e) {
      return ReviewResult(
        isSuccess: false,
        message: "Something went wrong",
      );
    } finally {
      isSubmittingReview.value = false;
    }
  }
}

class ReviewResult {
  final bool isSuccess;
  final String? message;

  ReviewResult({required this.isSuccess, this.message});
}
