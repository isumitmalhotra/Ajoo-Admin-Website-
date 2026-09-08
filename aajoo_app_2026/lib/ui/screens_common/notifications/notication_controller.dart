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
      // The server's COUNT, not the length of what came back. The list is the
      // history now — read rows included — so counting it would have shown a
      // badge for notifications the guest had already opened.
      notificationCount.value = response.success ? response.data.unreadCount : 0;
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

    // The badge comes down with it. It sits on the bell the guest is looking
    // at, and leaving it until the next fetch reads as the app not noticing.
    if (notificationCount.value > 0) notificationCount.value -= 1;

    final ok =
        await notificationService.markNotificationAsRead(notificationId);
    if (!ok) {
      // Revert if the server rejected us
      notif.unIsRead = 0;
      notificationCount.value += 1;
      notificationData.refresh();
    }
  }

  /// Clear everything unread, in one call rather than one per row.
  Future<void> markAllAsRead() async {
    final response = notificationData.value;
    if (response == null) return;
    final unread = response.data.notifications.where((n) => n.unIsRead != 1).toList();
    if (unread.isEmpty && notificationCount.value == 0) return;

    for (final n in unread) {
      n.unIsRead = 1;
    }
    final previous = notificationCount.value;
    notificationCount.value = 0;
    notificationData.refresh();

    final after = await notificationService.markAllRead();
    if (after == null) {
      // The server refused. Put it back rather than showing "all caught up"
      // over notifications that are still unread.
      for (final n in unread) {
        n.unIsRead = 0;
      }
      notificationCount.value = previous;
      notificationData.refresh();
    } else {
      notificationCount.value = after;
    }
  }

  /// Refresh just the count, for surfaces that show a badge but no list.
  Future<void> refreshCount() async {
    try {
      final response = await notificationService.getNotification(history: false);
      if (response.success) notificationCount.value = response.data.unreadCount;
    } catch (_) {
      // Signed out or offline — keep the last figure rather than flashing a
      // zero that claims everything has been read.
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
