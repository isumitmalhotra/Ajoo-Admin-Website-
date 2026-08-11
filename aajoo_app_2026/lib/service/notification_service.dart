
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:logger/logger.dart';
import 'package:rent_home/data/ApiConstants.dart';
import '../models/notification_response_model.dart';
import 'notification_routing_service.dart';

/// Background FCM handler.
///
/// This MUST be a top-level (or static) function annotated with
/// `@pragma('vm:entry-point')`. Firebase runs background messages in a
/// separate isolate and reaches this code through a CallbackHandle, and
/// `PluginUtilities.getCallbackHandle()` returns null for an instance method.
/// The plugin then force-unwraps that null, which is exactly what threw
/// "Null check operator used on a null value" during startup and left the
/// app sitting on a blank, unresponsive screen.
///
/// Deliberately minimal: this isolate has none of the app's state, and
/// Android already renders a message that carries a `notification` payload,
/// so building another one here would show the user two.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Intentionally empty. Registering a handler is what allows data-only
  // messages to wake the app; the system draws the notification itself.
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
  var logger = Logger();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// **Initialize Notification Service**
  ///
  /// Never allowed to take the app down with it. This runs during startup, so
  /// anything that escapes here reaches the framework as an unhandled
  /// exception and the user gets a blank, unresponsive screen — which is
  /// exactly what happened when the background-handler registration threw.
  /// Push is a convenience; being unable to open the app is not a reasonable
  /// price for it.
  Future<void> init() async {
    try {
      await _requestNotificationPermission();
      await _initLocalNotifications();
      await _setupFirebaseListeners();
      logger.w("📲Notification Service Init");
    } catch (e, st) {
      logger.e("Notification init failed — continuing without push", error: e, stackTrace: st);
    }
  }

  final Dio _dio = Dio(
    BaseOptions(
      contentType: 'application/json',
      headers: {
        'Accept': 'application/json',
      },
      // Short timeouts — failed/missing endpoints bail quickly so the UI
      // doesn't stall while waiting on a dead backend. Defaults are ~30s.
      connectTimeout: const Duration(seconds: 5),
      sendTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  )..interceptors.add(PrettyDioLogger(
      requestHeader: kDebugMode,
      requestBody: kDebugMode,
      responseBody: kDebugMode,
      responseHeader: false,
      error: true,
      compact: true,
      maxWidth: 90,
      enabled: kDebugMode,
    ));

  // Single source of truth: route through Apiconstants so the notification
  // service follows the same base URL as the rest of the app. Was previously
  // pinned to a different deploy (onrender) which 404s.
  String get baseUrl => Apiconstants.baseUrl;
  Future<void> saveTokenToDatabase(String fcmToken) async {
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.baseUrl = baseUrl;
    _dio.options.headers["Authorization"] = 'Bearer $token';
    try {
      final response =
          await _dio.post("/user/notification/allow-notification", data: {
        "deviceToken": fcmToken,
      });
      if (response.statusCode == 200) {
        logger.w(response.data.toString());
        logger.w("FCM Token saved to database successfully.");
      } else {
        logger.w("Failed to save FCM Token to database.");
      }
    } on DioException catch (e) {
      logger.w(e.response);

      logger.w("Error saving FCM Token: $e");
    }
  }

  Future<AppNotificationResponse> getNotification() async {
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.baseUrl = baseUrl;
    _dio.options.headers["Authorization"] = 'Bearer $token';
    try {
      final response = await _dio.get("/user/notification/Listing");
      if (response.statusCode == 200) {
        return AppNotificationResponse.fromJson(response.data);
      } else {
        throw Exception("Failed to load notifications");
      }
    } on DioException catch (e) {
      logger.w(e.response);
      throw Exception("Error fetching notifications: $e");
    }
  }

  /// Marks a single notification as read on the backend. Returns true on
  /// success, false on any failure — caller decides whether to update local
  /// state optimistically. Backend expects: `{ notificationId: <int> }`.
  Future<bool> markNotificationAsRead(int notificationId) async {
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.baseUrl = baseUrl;
    _dio.options.headers["Authorization"] = 'Bearer $token';
    try {
      final response = await _dio.post(
        "/user/notification/mark-read",
        data: {"notificationId": notificationId},
      );
      final ok = response.statusCode == 200 && response.data?["success"] == true;
      if (!ok) {
        logger.w("markNotificationAsRead non-ok response: ${response.data}");
      }
      return ok;
    } on DioException catch (e) {
      logger.w("markNotificationAsRead error: ${e.message}");
      return false;
    } catch (e) {
      logger.w("markNotificationAsRead unexpected: $e");
      return false;
    }
  }

  /// **1️⃣ Request Notification Permission**
  Future<void> _requestNotificationPermission() async {
    PermissionStatus status = await Permission.notification.request();

    if (status.isGranted) {
      logger.w("✅ Notification permission granted.");
      if (await _storage.read(key: "fcm_token") == null) {
        String? token = await _getFCMToken();
        await _storage.write(key: "fcm_token", value: token!);
        await saveTokenToDatabase(token);
        logger.w("FCM Token: $token");
      } else {
        String? token = await _storage.read(key: "fcm_token");
        await saveTokenToDatabase(token!);
        logger.w("FCM Token: $token");
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
      logger.d("📩 Notitication clicked");
      logger.d("payload: ${response.payload}");
      final data = jsonDecode(response.payload!);
      print(data);
      if (Get.isRegistered<NotificationRoutingService>()) {
        Get.find<NotificationRoutingService>().handleNotificationData(data);
      }
    });
  }

  /// **4️⃣ Setup Firebase Listeners**
  Future<void> _setupFirebaseListeners() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      logger.w(
          "📲 Foreground Notification Received: ${message.notification?.title}");
      logger.w(
          "📲 Foreground Notification Received: ${message.notification?.body}");
      logger.w("📲 Notification Data: ${message.data}");
      _showNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      logger.w("📩 Notification Clicked (Background)");
      logger.w("📩 Notification Data: ${message.data}");
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
        logger.w("📩 Notification opened app from terminated state");
        logger.w("📩 Notification Data: ${message.data}");
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
