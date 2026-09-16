import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
// The controller registered in InitBinding — not lib/controller/auth_controller
// .dart, which shares the class name. Get.find keys on the name, so importing
// the wrong one type-casts the live instance to a class it is not.
import '../ui/screens_common/auth/auth_controller.dart';
import '../ui/screens_renter/messages/messages_screen.dart';
import '../ui/screens_renter/negotiations/guest_negotiations_screen.dart';
import '../ui/screens_host/negotiations/host_negotiations_screen.dart';
import '../utils/notification_link.dart';


import 'package:rent_home/utils/app_log.dart';
class NotificationRoutingService extends GetxService {
  final _storage = const FlutterSecureStorage();

  static NotificationRoutingService get instance => Get.find();

  final RxString _pendingRoute = ''.obs;
  final RxMap<String, dynamic> _pendingData = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _setupNotificationHandlers();
  }

  /// Key under which the last cold-start notification we acted on is stored.
  static const _handledColdStartKey = 'last_handled_initial_message';

  /// Push routing is a feature, not a prerequisite for opening the app.
  ///
  /// Every FirebaseMessaging call below throws `[core/no-app]` when Firebase
  /// did not initialise, and unguarded that took the app down on exactly the
  /// devices main() already works around with a timeout. Losing push there is
  /// the intended trade; losing the app is not.
  void _setupNotificationHandlers() {
    try {
      _attachFirebaseHandlers();
    } catch (e) {
      // ignore: avoid_print
      appLog('push routing unavailable, continuing without it: $e');
    }
  }

  void _attachFirebaseHandlers() {
    // Handle notification when app is opened from notification (terminated
    // state).
    //
    // getInitialMessage() returns the push that launched the app — but it is
    // not guaranteed to return it only once. On Android the launch intent
    // survives, so an ordinary cold start later can hand back the SAME message
    // and the app navigates off to a notification the user dealt with days
    // ago. Remembering which one we have already acted on makes this
    // idempotent whatever the platform does.
    FirebaseMessaging.instance.getInitialMessage().then((message) async {
      if (message == null) return;

      final id = message.messageId ??
          // Not every provider sets messageId; fall back to something stable
          // for this payload so we still de-duplicate.
          '${message.sentTime?.millisecondsSinceEpoch ?? ''}:${message.data}';

      try {
        final seen = await _storage.read(key: _handledColdStartKey);
        if (seen == id) return; // already routed for this one
        await _storage.write(key: _handledColdStartKey, value: id);
      } catch (_) {
        // Storage unavailable — route anyway rather than swallow a tap the
        // user just made.
      }

      handleNotificationData(message.data);
    });

    // Handle notification when app is in background and notification is tapped
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      handleNotificationData(message.data);
    });
  }

  void handleNotificationData(Map<String, dynamic> data) async {
    appLog('📱 Handling notification data: $data');

    // A push used to be ignored outright unless it carried both `route` and
    // `type`. Most carry neither, so tapping them did nothing at all. There is
    // always a title and body — that is enough to work out where to go.
    final String route = (data['route'] ?? '').toString();
    final String type = (data['type'] ?? '').toString();

    // Check authentication
    final authController = Get.find<AuthController>();
    final status = await authController.checkLoginStatus();
    if (!status) {
      appLog('🔒 User not logged in, redirecting to login');
      _setPendingNavigation(route, data);
      Get.toNamed('/login');
      return;
    }

    _routeToPage(route, type, data);
  }

  void _routeToPage(String route, String type, Map<String, dynamic> data) {
    final title = (data['title'] ?? '').toString();
    final body = (data['body'] ?? data['message'] ?? '').toString();
    final propertyId = (data['propertyId'] ?? '').toString();

    final kind = notificationKind(
      title: title,
      message: body,
      payloadType: type,
    );

    /**
     * An offer notification opens MY NEGOTIATIONS — the list of threads —
     * not the old socket chat.
     *
     * Client, 2026-09-16: "Which negotiation page it is taking me from
     * notifications??" The push was routed to PriceNegotiationPage, the
     * pre-rebuild screen with its own thirty-second countdown, quick-price
     * chips (−200/−100/−50/+50) and a running offer counter — a second
     * client for one engine, and the one the negotiation rebuild replaced on
     * 2026-09-12. The listing's own sheet stopped using it that day; the
     * notifications never did, so every offer notification led straight back
     * into it.
     *
     * The thread lives on the negotiations screen now: what was offered and
     * what came back, with Accept / Counter / Decline on the row that holds
     * the next move. The host has their own.
     */
    if (kind == NotifKind.offer) {
      final isHost = Get.find<AuthController>().authIsHost.value;
      Get.to(() => isHost
          ? const HostNegotiationsScreen()
          : const GuestNegotiationsScreen());
      return;
    }

    // A chat notification with no property: open the inbox, deep-linked to
    // whoever sent it.
    //
    // These used to fall through to the home screen, because the only
    // conversation surface was the property-scoped negotiation thread and
    // these messages carry no property. There is an inbox now, so the
    // notification can land on the actual conversation.
    if (kind == NotifKind.message) {
      final sender = (data['senderId'] ?? data['userId'] ?? '').toString();
      Get.to(() => MessagesScreen(
            openWith: sender.isEmpty ? null : sender,
            openWithName: (data['senderName'] ?? data['name'] ?? '').toString().isEmpty
                ? null
                : (data['senderName'] ?? data['name']).toString(),
          ));
      return;
    }

    // Everything else: resolve from the wording, exactly as the in-app list
    // does. Never follow the payload's own path blindly — those are the web's
    // routes ("/messages", "/bookings") and this app has none of them.
    final destination = notificationDestination(
      title: title,
      message: body,
      payloadType: type,
      payloadRoute: route,
      isHost: Get.find<AuthController>().authIsHost.value,
      propertyId: propertyId.isEmpty ? null : propertyId,
      bookingId: (data['bookingId'] ?? '').toString().isEmpty
          ? null
          : (data['bookingId']).toString(),
    );
    final target =
        destination.route == '/negotiation' ? _homeRoute() : destination.route;
    Get.toNamed(target, arguments: destination.arguments);
  }

  String _homeRoute() =>
      Get.find<AuthController>().authIsHost.value ? '/host/home' : '/home';


  // Booking and property notifications used to be sent to '/booking/details'
  // and '/property/details'. Neither is a route in this app, so both taps hit
  // the unknown-route page. notificationDestination maps them to screens that
  // exist instead.

  void _setPendingNavigation(String route, Map<String, dynamic> data) {
    _pendingRoute.value = route;
    _pendingData.value = data;
    appLog('📱 Pending navigation set: $route with data: $data');
  }

  void setPendingRoute(String route) {
    _pendingRoute.value = route;
  }

  void processPendingNavigation() {
    if (_pendingRoute.value.isNotEmpty) {
      final route = _pendingRoute.value;
      final data = Map<String, dynamic>.from(_pendingData);

      _clearPendingNavigation();

      // Small delay to ensure login process is complete
      Future.delayed(const Duration(milliseconds: 500), () {
        if (data.isNotEmpty) {
          final type = data['type'] ?? 'default';
          _routeToPage(route, type, data);
        } else {
          Get.toNamed(route);
        }
      });
    }
  }

  void _clearPendingNavigation() {
    _pendingRoute.value = '';
    _pendingData.clear();
  }

  // Helper method to manually trigger navigation for testing
  void testNotificationNavigation({
    required String type,
    required Map<String, dynamic> data,
  }) {
    data['type'] = type;
    handleNotificationData(data);
  }
}
