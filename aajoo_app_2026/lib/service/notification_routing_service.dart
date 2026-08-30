import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// The controller registered in InitBinding — not lib/controller/auth_controller
// .dart, which shares the class name. Get.find keys on the name, so importing
// the wrong one type-casts the live instance to a class it is not.
import '../ui/screens_common/auth/auth_controller.dart';
import '../ui/screens_renter/messages/messages_screen.dart';
import '../controller/user_controller.dart';
import '../models/properties_response_model.dart';
import '../utils/notification_link.dart';
import 'package:rent_home/data/ApiConstants.dart';

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

  void _setupNotificationHandlers() {
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
    print('📱 Handling notification data: $data');

    // A push used to be ignored outright unless it carried both `route` and
    // `type`. Most carry neither, so tapping them did nothing at all. There is
    // always a title and body — that is enough to work out where to go.
    final String route = (data['route'] ?? '').toString();
    final String type = (data['type'] ?? '').toString();

    // Check authentication
    final authController = Get.find<AuthController>();
    final status = await authController.checkLoginStatus();
    if (!status) {
      print('🔒 User not logged in, redirecting to login');
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

    // The negotiation thread needs a property, both party ids and a token, so
    // it can only be opened when the push carried them. That path fetches the
    // property and assembles the rest.
    final canOpenThread = (kind == NotifKind.message || kind == NotifKind.offer) &&
        propertyId.isNotEmpty &&
        data['userId'] != null &&
        data['receiverId'] != null &&
        data['hostId'] != null;
    if (canOpenThread) {
      _navigateToNegotiation(data);
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
    );
    final target =
        destination.route == '/negotiation' ? _homeRoute() : destination.route;
    Get.toNamed(target, arguments: destination.arguments);
  }

  String _homeRoute() =>
      Get.find<AuthController>().authIsHost.value ? '/host/home' : '/home';

  void _navigateToNegotiation(Map<String, dynamic> data) {
    final String? propertyId = data['propertyId'];
    final String? userId = data['userId'];
    final String? receiverId = data['receiverId'];
    final String? hostId = data['hostId'];
    final String? lat = data['lat'];
    final String? long = data['long'];

    if (propertyId == null ||
        userId == null ||
        receiverId == null ||
        hostId == null) {
      Get.snackbar(
        'Error',
        'Invalid negotiation data received',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    // Fetch property details first
    _fetchPropertyAndNavigateToNegotiation(
      propertyId: propertyId,
      userId: userId,
      receiverId: receiverId,
      hostId: hostId,
      lat: lat ?? '0.0',
      long: long ?? '0.0',
    );
  }

  Future<void> _fetchPropertyAndNavigateToNegotiation({
    required String propertyId,
    required String userId,
    required String receiverId,
    required String hostId,
    required String lat,
    required String long,
  }) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final userController = Get.find<UserController>();
      await userController.getProperty(int.parse(propertyId));

      if (Get.isDialogOpen ?? false) {
        Get.back(); // Close loading dialog
      }

      final propertyResponse = userController.property.value;
      if (propertyResponse == null || propertyResponse.data == null) {
        Get.snackbar(
          'Error',
          'Property not found',
          snackPosition: SnackPosition.TOP,
        );
        return;
      }

      // Convert SinglePropertyData to Property model for negotiation page
      final propertyData = propertyResponse.data!;
      final property = Property(
        propertyId: propertyData.propertyId ?? int.parse(propertyId),
        propertyName: propertyData.propertyName ?? 'Unknown Property',
        propertyAddress: propertyData.propertyAddress ?? '',
        propertyDesc: propertyData.propertyDesc ?? '',
        propertyPrice: propertyData.propertyPrice ?? '0',
        propertyCity: propertyData.propertyCity ?? '',
        propertyLongitude: propertyData.propertyLongitude ?? long,
        propertyLatitude: propertyData.propertyLatitude ?? lat,
        propertyHostId:
            propertyData.propertyHostId ?? int.tryParse(hostId) ?? 0,
        propertyZip: propertyData.propertyZip,
        propertyContact: propertyData.propertyContact,
        propDetailsPropDetailIsPetFriendly:
            propertyData.propDetails?.isPetFriendly,
        propDetailsPropDetailIsSmoke: propertyData.propDetails?.isSmoke,
        propDetailsPropDetailInTime: propertyData.propDetails?.inTime,
        propDetailsPropDetailOutTime: propertyData.propDetails?.outTime,
        propDetailsPropDetailExtra: propertyData.propDetails?.extra,
        coverImage:
            (propertyData.images != null && propertyData.images!.isNotEmpty)
                ? propertyData.images!.first.toString()
                : null,
        images:
            (propertyData.images ?? const []).map((e) => e.toString()).toList(),
        categoryTitles: const [],
        tags: propertyData.tags?.map((e) => e.toString()).toList(),
        categories: propertyData.categories?.map((e) => e.toString()).toList(),
        amenities: propertyData.amenities?.map((e) => e.toString()).toList(),
      );

      // Navigate to negotiation page with all required parameters
      Get.toNamed('/negotiation', arguments: {
        'userId': userId,
        'receiverId': userId,
        "senderId":
            Get.find<AuthController>().userData.value?.userId.toString() ?? '',
        'propertyId': propertyId,
        'serverUrl': Apiconstants.baseUrl, // Your server URL
        'token': Get.find<AuthController>().token.value,
        'property': property,
        'lat': lat,
        'long': long,
        'hostId': hostId,
      });
    } catch (e) {
      if (Get.isDialogOpen ?? false) {
        Get.back(); // Close loading dialog
      }

      Get.snackbar(
        'Error',
        'Failed to load property details: $e',
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  // Booking and property notifications used to be sent to '/booking/details'
  // and '/property/details'. Neither is a route in this app, so both taps hit
  // the unknown-route page. notificationDestination maps them to screens that
  // exist instead.

  void _setPendingNavigation(String route, Map<String, dynamic> data) {
    _pendingRoute.value = route;
    _pendingData.value = data;
    print('📱 Pending navigation set: $route with data: $data');
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
