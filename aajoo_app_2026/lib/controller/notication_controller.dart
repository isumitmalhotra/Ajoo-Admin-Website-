import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/service/notification_service.dart';

import '../models/notification_response_model.dart';

class NotificationController extends GetxController{
  RxBool isLoading = false.obs;
  RxBool error = false.obs;
  RxInt notificationCount = 0.obs;
  Rx<AppNotificationResponse?> notificationData = Rx<AppNotificationResponse?>(null);
final NotificationService notificationService = NotificationService();

  Future<void> getNotificationData() async {
    try {
      isLoading.value = true;
      final response = await notificationService.getNotification();
      notificationData.value = response;
      if (response.success) {
        notificationCount.value = response.data.notifications.length;
      } else {
        notificationCount.value = 0;
      }
    } catch (err) {
      print(err);
      // showSnackbar("Error Fetching Notification  ", "Something went Wrong", true);
      error.value = true;
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