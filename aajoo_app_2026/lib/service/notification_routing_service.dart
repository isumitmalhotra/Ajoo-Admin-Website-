import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/auth_controller.dart';
import '../controller/user_controller.dart';
import '../models/properties_response_model.dart';

class NotificationRoutingService extends GetxService {
  static NotificationRoutingService get instance => Get.find();

  final RxString _pendingRoute = ''.obs;
  final RxMap<String, dynamic> _pendingData = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _setupNotificationHandlers();
  }

  void _setupNotificationHandlers() {
    // Handle notification when app is opened from notification (terminated state)
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        handleNotificationData(message.data);
      }
    });

    // Handle notification when app is in background and notification is tapped
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      handleNotificationData(message.data);
    });
  }

  void handleNotificationData(Map<String, dynamic> data) async {
    print('📱 Handling notification data: $data');

    final String? route = data['route'];
    final String? type = data['type'];

    if (route == null || type == null) {
      print('❌ Invalid notification data: missing route or type');
      return;
    }

    // Check authentication
    final authController = Get.find<AuthController>();
    final status = await authController.checkLoginStatus();
    if (!status) {
      print('🔒 User not logged in, redirecting to login');
      _setPendingNavigation(route, data);
      Get.toNamed('/login');
      return;
    }

    // Route based on notification type
    _routeToPage(route, type, data);
  }

  void _routeToPage(String route, String type, Map<String, dynamic> data) {
    switch (type) {
      case 'negotiation_request':
        _navigateToNegotiation(data);
        break;
      case 'booking_confirmation':
        _navigateToBookingDetails(data);
        break;
      case 'payment_update':
        _navigateToPaymentHistory(data);
        break;
      case 'property_update':
        _navigateToPropertyDetails(data);
        break;
      default:
        _navigateToDefaultRoute(route, data);
        break;
    }
  }

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
        'serverUrl': 'https://aajaodev.onrender.com', // Your server URL
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

  void _navigateToBookingDetails(Map<String, dynamic> data) {
    final String? bookingId = data['bookingId'];
    if (bookingId != null) {
      Get.toNamed('/booking/details', arguments: {'bookingId': bookingId});
    }
  }

  void _navigateToPaymentHistory(Map<String, dynamic> data) {
    Get.toNamed('/history', arguments: {'tab': 'payments'});
  }

  void _navigateToPropertyDetails(Map<String, dynamic> data) {
    final String? propertyId = data['propertyId'];
    if (propertyId != null) {
      Get.toNamed('/property/details', arguments: {'propertyId': propertyId});
    }
  }

  void _navigateToDefaultRoute(String route, Map<String, dynamic> data) {
    Get.toNamed(route, arguments: data);
  }

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
