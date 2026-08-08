import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/data/source/remote/api_client/model/ApiException.dart';
import 'package:rent_home/data/models/properties_response_model.dart';
import 'package:rent_home/service/notification_service.dart';
import 'package:rent_home/service/property_service.dart';

import '../../../data/models/notification_response_model.dart';

class NotificationController extends GetxController {
  RxBool isLoading = false.obs;
  RxBool error = false.obs;
  RxString errorMsg = ''.obs;
  RxInt notificationCount = 0.obs;
  Rx<AppNotificationResponse?> notificationData =
      Rx<AppNotificationResponse?>(null);
  final NotificationService notificationService = NotificationService();

  final PropertyService propertyService = PropertyService();
  Future<Property> getSingleProperty(int id) async {
    final response = await propertyService.getSingleProperty(id);
    return Property.fromJson(response.data!.toJson());
  }

  Future<void> getNotificationData() async {
    errorMsg.value = "";
    try {
      isLoading.value = true;
      final response = await notificationService.getNotification();
      notificationData.value = response;
      if (response.success) {
        notificationCount.value = response.data.notifications.length;
      } else {
        notificationCount.value = 0;
      }
    } catch (e) {
      if (e is ApiException) {
        error.value = true;
        errorMsg.value = e.message;
      } else {
        error.value = true;
        errorMsg.value = 'Unexpected error';
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Optimistically marks a notification read in local state, then fires the
  /// backend call. Reverts on failure so the unread badge stays accurate.
  /// Idempotent — no-op if already read.
  Future<void> markAsRead(int notificationId) async {
    final response = notificationData.value;
    if (response == null) return;

    final idx = response.data.notifications
        .indexWhere((n) => n.unId == notificationId);
    if (idx == -1) return;

    final notif = response.data.notifications[idx];
    if (notif.unIsRead == 1) return; // already read

    // Optimistic flip
    notif.unIsRead = 1;
    notificationData.refresh();

    final ok =
        await notificationService.markNotificationAsRead(notificationId);
    if (!ok) {
      // Revert if the server rejected us
      notif.unIsRead = 0;
      notificationData.refresh();
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
