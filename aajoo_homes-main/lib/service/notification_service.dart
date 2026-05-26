import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:rent_home/data/source/remote/api_client/api_client.dart';
import '../data/models/notification_response_model.dart';
import 'notification_routing_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
  var logger = Logger();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final ApiClient apiClient = ApiClient();

  /// **Initialize Notification Service**
  Future<void> init() async {
    await _requestNotificationPermission();
    await _initLocalNotifications();
    await _setupFirebaseListeners();
  }

  Future<void> saveTokenToDatabase(String fcmToken) async {
    final token = await FlutterSecureStorage().read(key: "user_token") ?? " ";
    try {
      final response =
          await apiClient.post("/user/notification/allow-notification", data: {
        "deviceToken": fcmToken,
      });
      if (response['success']) {
      } else {}
    } catch (e) {
      logger.w("Error saving FCM Token: $e");
    }
  }

  Future<AppNotificationResponse> getNotification() async {
    try {
      final response = await apiClient.get("/user/notification/Listing");
      return AppNotificationResponse.fromJson(response);
    } catch (e) {
      logger.w(e);
      rethrow;
    }
  }

  /// **1️⃣ Request Notification Permission**
  Future<void> _requestNotificationPermission() async {
    PermissionStatus status = await Permission.notification.request();

    if (status.isGranted) {
      if (await _storage.read(key: "fcm_token") == null) {
        String? token = await _getFCMToken();
        print("fcmtoken from firebase $token");
        await _storage.write(key: "fcm_token", value: token!);
        await saveTokenToDatabase(token);
      } else {
        String? token = await _storage.read(key: "fcm_token");
        print("fcmtoken from storage $token");
        await saveTokenToDatabase(token!);
      }
    } else if (status.isDenied) {
      logger.w("🚫 Notification permission denied.");
    } else if (status.isPermanentlyDenied) {
      logger.w(
          "⚠️ Notification permission permanently denied. Redirecting to settings...");
      openAppSettings();
    }
  }

  /// **2️⃣ Get FCM Token**
  Future<String?> _getFCMToken() async {
    logger.w("Fetching FCM Token...");
    return await _firebaseMessaging.getToken();
  }

  /// **3️⃣ Initialize Local Notifications**
  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();

    const InitializationSettings settings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    await _localNotifications.initialize(settings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
      final data = jsonDecode(response.payload!);
      print(data);
      final route = data['route'];
      final hostId = data['hostId'];
      final type = data['type'];
      final propertyId = data['propertyId'];
      final lat = data['lat'];
      final long = data['long'];
      final userId = data['userId'];
      if (Get.isRegistered<NotificationRoutingService>()) {
        Get.find<NotificationRoutingService>().handleNotificationData(data);
      }
    });
  }

  /// **4️⃣ Setup Firebase Listeners**
  Future<void> _setupFirebaseListeners() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // logger.w(
      //     "📲 Foreground Notification Received: ${message.notification?.title}");
      // logger.w(
      //     "📲 Foreground Notification Received: ${message.notification?.body}");
      // logger.w("📲 Notification Data: ${message.data}");
      _showNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Let NotificationRoutingService handle the routing
      if (Get.isRegistered<NotificationRoutingService>()) {
        Get.find<NotificationRoutingService>()
            .handleNotificationData(message.data);
      }
    });

    // Handle notification when app is opened from terminated state
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        // Delay to ensure app is fully initialized
        Future.delayed(const Duration(seconds: 2), () {
          if (Get.isRegistered<NotificationRoutingService>()) {
            // Get.find<NotificationRoutingService>()
            //     .handleNotificationData(message.data);
            // Get.to(() => NotificationsScreen());
          }
        });
      }
    });

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  /// **5️⃣ Handle Background Notifications**
  Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    logger.w(
        "⏳ Background Notification Received: ${message.notification?.title}");
    _showNotification(message);
  }

  /// **6️⃣ Show Notification**
  Future<void> _showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails("channel_id", "channel_name",
            importance: Importance.high, priority: Priority.high);

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      0,
      message.notification?.title ?? "No Title",
      message.notification?.body ?? "No Body",
      details,
      payload: jsonEncode(message.data),
    );
  }

  // Future<>getNotification()async{

  // }
}

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  Logger()
      .w("⏳ Background Notification Received: ${message.notification?.title}");
}
