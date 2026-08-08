import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:rent_home/models/host_booking_history_model.dart';
import 'package:rent_home/models/host_ongoing_response.dart';
import 'package:rent_home/models/host_properties_reponse.dart';
import 'package:rent_home/models/transaction_model.dart';
import 'package:rent_home/service/host_service.dart';
import 'package:rent_home/service/property_service.dart';

class HostController extends GetxController {
  final HostService hostService = HostService();
  final PropertyService propertyService = PropertyService();
  final storage = const FlutterSecureStorage();
  RxBool loading = false.obs;
  RxString error = ''.obs;
  Rx<HostOnGoingBookingResponse?> HostOngoingResponse =
      Rx<HostOnGoingBookingResponse?>(null);
  Rx<HostPropertiesResponse?> hostPropertiesResponse =
      Rx<HostPropertiesResponse?>(null);

  Rx<TransactionResponse?> transactionHistoryResponse =
      Rx<TransactionResponse?>(null);
  String TOKEN_KEY = 'user_token';
  Rx<File?> coverImage = Rx<File?>(null);

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

  Future<void> getTransactionHistory() async {
    try {
      loading.value = true;
      final response = await hostService.getHostTransactions();
      transactionHistoryResponse.value = response;
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<void> updateCoverImage(int id) async {
    loading.value = true;
    try {
      final response =
          await propertyService.updatePropertyCoverImage(id, coverImage.value!);
      if (response) {
        showSnackbar("Image Updated Successfully", "", false);
      } else {
        showSnackbar("Something went Wrong", "error updating image", true);
      }
    } catch (e) {
      error.value = e.toString();
      showSnackbar(e.toString(), "Error updating image", true);
    }
  }

  Future<void> updatePropertyStatus(int propId, int status) async {
    loading.value = true;
    try {
      final response = await hostService.updatePropertyStatus(propId, status);
      if (response) {
        showSnackbar("Property Status Updated Successfully", "", false);
      } else {
        showSnackbar(
            "Something went Wrong", "error updating property status", true);
      }
    } catch (e) {
      error.value = e.toString();
      showSnackbar(e.toString(), "Error updating property status", true);
    } finally {
      loading.value = false;
    }
  }

  Future<void> getHostProperties() async {
    try {
      loading.value = true;
      final response = await hostService.getHostProperties();
      hostPropertiesResponse.value = response;
    } catch (e) {
      error.value = e.toString();
      print(e);
    } finally {
      loading.value = false;
    }
  }

  Future<void> deleteProperty(int id) async {
    loading.value = false;
    final response = await propertyService.deleteProperty(id);
    if (response) {
      showSnackbar("Property Deleted Successfully", "", false);
    } else {
      showSnackbar("Something went Wrong", "error deleting property", true);
    }
    loading.value = false;
  }

  Future<void> getHostOngoing(int hostId) async {
    await _initialize();

    try {
      loading.value = true;
      final response = await hostService.getHostOngoing(hostId);
      HostOngoingResponse.value = response;
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
      print(e);
      showSnackbar(e.toString(), "Error adding review", true);
    } finally {
      loading.value = false;
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
