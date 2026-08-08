import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:logger/logger.dart';
import 'package:rent_home/ui/screens_common/auth/auth_controller.dart';
import 'package:rent_home/controller/notication_controller.dart';
import 'package:rent_home/models/properties_response_model.dart';
import 'package:rent_home/service/property_service.dart';
import 'package:rent_home/widgets/negotitaion_page.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:animate_do/animate_do.dart';
import 'package:rent_home/constants.dart';
// import 'package:rent_home/controller/notification_controller.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
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
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
          ),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Obx(() {
        final data = notificationController.notificationData.value;
        final list = data?.data.notifications ?? [];
        return notificationController.isLoading.value
            ? const Center(
                child: CircularProgressIndicator(
                  color: kprimaryColor,
                ),
              )
            : notificationController.error.value
                ? const Center(
                    child: Text(
                      'Error fetching notifications',
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  )
                : (list.isEmpty)
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
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final notification = list[index];
                          return FadeInUp(
                            duration: const Duration(milliseconds: 300),
                            delay: Duration(milliseconds: 100 * index),
                            child: Card(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 16),
                                leading: CircleAvatar(
                                  child: Icon(
                                    notification.unIsRead == 1
                                        ? Icons.notifications_active
                                        : Icons.notifications_none,
                                    color: notification.unIsRead == 1
                                        ? kprimaryColor
                                        : Colors.grey,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notification.unTitle,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: notification.unIsRead == 1
                                              ? Colors.black
                                              : Colors.grey[800],
                                        ),
                                      ),
                                    ),
                                    if (notification.unIsRead == 1)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.red,
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      notification.unMessage,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      timeago.format(
                                          notification.createdAt?.toLocal() ??
                                              DateTime.now(),
                                          locale: 'en_short'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () async {
                                  final AuthController authController =
                                      Get.find<AuthController>();
                                  final currentUserId =
                                      authController.userData.value?.userId;

                                  if (notification.payload != null) {
                                    final payloadData = notification.payload!;

                                    // Handle negotiation requests and offer acceptances
                                    if ((notification.unTitle
                                            .contains("negotiation")) &&
                                        payloadData.propertyId != null) {
                                      try {
                                        final response = await PropertyService()
                                            .getSingleProperty(int.parse(
                                                payloadData.propertyId!));

                                        final property = Property.fromJson(
                                            response.data!.toJson());
                                        final token =
                                            await const FlutterSecureStorage()
                                                .read(key: "user_token");

                                        // Determine correct user roles based on notification type and current user
                                        String userId, senderId, receiverId;

                                        if (notification.unTitle
                                            .contains("negotiation")) {
                                          // For negotiation requests: current user is the host (receiver)
                                          userId = currentUserId.toString();
                                          senderId = currentUserId.toString();
                                          receiverId = payloadData.userId ??
                                              payloadData.receiverId ??
                                              "";
                                        } else {
                                          // For offer accepted: current user could be either party
                                          userId = currentUserId.toString();
                                          senderId = currentUserId.toString();
                                          receiverId =
                                              (currentUserId.toString() ==
                                                      payloadData.userId)
                                                  ? (payloadData.receiverId ??
                                                      payloadData.hostId ??
                                                      "")
                                                  : (payloadData.userId ?? "");
                                        }

                                        Logger()
                                            .f("Current User: $currentUserId");
                                        Logger().f(
                                            "Payload: ${payloadData.toJson()}");
                                        Logger().f(
                                            "Navigation - userId: $userId, senderId: $senderId, receiverId: $receiverId");

                                        Navigator.push(
                                            context,
                                            CupertinoPageRoute(
                                                builder: (context) =>
                                                    PriceNegotiationPage(
                                                        userId: userId,
                                                        receiverId: receiverId,
                                                        propertyId: payloadData
                                                            .propertyId!,
                                                        serverUrl:
                                                            "https://aajaodev.onrender.com/",
                                                        token: token.toString(),
                                                        property: property,
                                                        lat: payloadData.lat ??
                                                            "0.0",
                                                        long:
                                                            payloadData.long ??
                                                                "0.0",
                                                        hostId: payloadData
                                                                .hostId ??
                                                            currentUserId
                                                                .toString(),
                                                        senderId: senderId)));
                                      } catch (e) {
                                        Logger().e(
                                            "Error navigating to negotiation: $e");
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  "Error opening notification: ${e.toString()}")),
                                        );
                                      }
                                    }
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      );
      }),
    );
  }
}
