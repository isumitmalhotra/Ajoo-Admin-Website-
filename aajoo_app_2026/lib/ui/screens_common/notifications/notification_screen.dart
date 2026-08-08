
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:logger/logger.dart';
import 'package:rent_home/ui/screens_common/auth/auth_controller.dart';
import 'package:rent_home/data/ApiConstants.dart';
import 'package:rent_home/data/models/notification_response_model.dart';
import 'package:rent_home/ui/screens_common/notifications/components/notification_list_item.dart';
import 'package:rent_home/ui/screens_common/notifications/notication_controller.dart';
import 'package:rent_home/widgets/common_back_button.dart';
import 'package:rent_home/ui/screens_common/price_negotiation/negotitaion_page.dart';
import 'package:rent_home/constants.dart';
// import 'package:rent_home/controller/notification_controller.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final AuthController authController = Get.find<AuthController>();
  bool _isProcessingTap = false;

  final NotificationController notificationController = Get.put(
    NotificationController(),
  );

  @override
  void initState() {
    super.initState();
    notificationController.getNotificationData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const CommonBackButton(),
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Stack(
        children: [
          _mainContent(),
          if (_isProcessingTap)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: CircularProgressIndicator(
                  color: kprimaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Obx _mainContent() {
    return Obx(() {
      final data = notificationController.notificationData.value;
      final list = data?.data.notifications ?? [];
      // Treat fetch error the same as empty — both feel like "nothing here"
      // to the user. Avoids the scary red "Unexpected error" string on a
      // network drop / dev-skip (no auth) / 401.
      final isEmptyOrError =
          notificationController.error.value || list.isEmpty;
      return notificationController.isLoading.value
          ? const Center(
              child: CircularProgressIndicator(
                color: kprimaryColor,
              ),
            )
          : isEmptyOrError
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.notification4,
                          size: 100,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 10),
                        const Center(
                          child: Text(
                            'No Notifications',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final notification = list[index];
                        return NotificationListItem(
                            notification: notification,
                            onTap: () => _onNotificationTap(notification),
                            index: index);
                      },
                    );
    });
  }

  Future<void> _onNotificationTap(AppNotification notification) async {
    if (_isProcessingTap) return;
    setState(() => _isProcessingTap = true);

    // Fire mark-read (don't await — UI shouldn't block on this; the
    // controller mutates local state optimistically + reverts on failure).
    // Skipped if already read so we don't pile retries on flaky network.
    if (notification.unIsRead != 1) {
      // ignore: discarded_futures — fire-and-forget
      notificationController.markAsRead(notification.unId);
    }

    try {
      if (notification.payload != null) {
        final currentUserId = authController.userData.value?.userId;
        final payloadData = notification.payload!;
        // Handle negotiation requests and offer acceptances
        if ((notification.unTitle.contains("negotiation")) &&
            payloadData.propertyId != null) {
          final property = await notificationController
              .getSingleProperty(int.parse(payloadData.propertyId!));
          final token =
              await const FlutterSecureStorage().read(key: "user_token");

          // Determine correct user roles based on notification type and current user
          String userId, senderId, receiverId;

          if (notification.unTitle.contains("negotiation")) {
            // For negotiation requests: current user is the host (receiver)
            userId = currentUserId.toString();
            senderId = currentUserId.toString();
            receiverId = payloadData.userId ?? payloadData.receiverId ?? "";
          } else {
            // For offer accepted: current user could be either party
            userId = currentUserId.toString();
            senderId = currentUserId.toString();
            receiverId = (currentUserId.toString() == payloadData.userId)
                ? (payloadData.receiverId ?? payloadData.hostId ?? "")
                : (payloadData.userId ?? "");
          }

          Logger().f("Current User: $currentUserId");
          Logger().f("Payload: ${payloadData.toJson()}");
          Logger().f(
              "Navigation - userId: $userId, senderId: $senderId, receiverId: $receiverId");

          Navigator.push(
              context,
              CupertinoPageRoute(
                  builder: (context) => PriceNegotiationPage(
                      userId: userId,
                      receiverId: receiverId,
                      propertyId: payloadData.propertyId!,
                      serverUrl: Apiconstants.serverUrl,
                      token: token.toString(),
                      property: property,
                      lat: payloadData.lat ?? "0.0",
                      long: payloadData.long ?? "0.0",
                      hostId: payloadData.hostId ?? currentUserId.toString(),
                      senderId: senderId)));
        }
      }
    } catch (e) {
      Logger().e("Error navigating to negotiation: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error opening notification: ${e.toString()}")),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessingTap = false);
      }
    }
  }
}
