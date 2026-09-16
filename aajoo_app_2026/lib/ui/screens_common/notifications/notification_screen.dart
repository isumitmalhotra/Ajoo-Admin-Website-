
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/ui/screens_renter/negotiations/guest_negotiations_screen.dart';
import 'package:rent_home/ui/screens_host/negotiations/host_negotiations_screen.dart';
import 'package:rent_home/ui/screens_renter/messages/messages_screen.dart';
import 'package:iconsax/iconsax.dart';
import 'package:logger/logger.dart';
import 'package:rent_home/ui/screens_common/auth/auth_controller.dart';
import 'package:rent_home/data/models/notification_response_model.dart';
import 'package:rent_home/ui/screens_common/notifications/components/notification_list_item.dart';
import 'package:rent_home/ui/screens_common/notifications/notication_controller.dart';
import 'package:rent_home/widgets/common_back_button.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/utils/notification_link.dart';
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
        actions: [
          // One action for the whole account, not one tap per row. A badge
          // that could only be cleared row by row never got cleared.
          Obx(() {
            final unread = notificationController.notificationCount.value;
            if (unread == 0) return const SizedBox.shrink();
            return TextButton(
              onPressed: notificationController.markAllAsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            );
          }),
        ],
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
      final payload = notification.payload;
      final kind = notificationKind(
        title: notification.unTitle,
        message: notification.unMessage,
        payloadType: payload?.type,
      );
      /**
       * An OFFER opens My Negotiations; a MESSAGE opens the inbox.
       *
       * Client, 2026-09-16: "Which negotiation page it is taking me from
       * notifications??" Tapping an offer notification pushed
       * PriceNegotiationPage — the pre-rebuild socket chat with its own
       * thirty-second countdown, quick-price chips and offer counter, which
       * the negotiation rebuild replaced on 2026-09-12. The listing stopped
       * opening it that day; this list never did, so a notification was the
       * way back into a screen nothing else used.
       *
       * Both destinations show the state the server actually has, and
       * neither needs a property fetch, a token or four ids assembled by
       * hand — which is what the branch this replaces spent thirty lines
       * doing, and frequently got wrong ("current user could be either
       * party").
       */
      if (kind == NotifKind.offer) {
        Get.to(() => authController.authIsHost.value
            ? const HostNegotiationsScreen()
            : const GuestNegotiationsScreen());
        return;
      }
      if (kind == NotifKind.message) {
        Get.to(() => MessagesScreen(openWith: payload?.userId));
        return;
      }

      // Everything else used to stop here, marked read and going nowhere — you
      // never found out what it was about. Resolve a destination from the
      // wording, the same way the web does.
      final destination = notificationDestination(
        title: notification.unTitle,
        message: notification.unMessage,
        payloadType: payload?.type,
        payloadRoute: payload?.route,
        isHost: authController.authIsHost.value,
        propertyId: payload?.propertyId,
        // The stored row knows which booking it was about; the list can then
        // point at that row rather than opening a tab and stopping.
        bookingId: notification.unBookingId,
      );
      Get.toNamed(destination.route, arguments: destination.arguments);
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
