
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
import '../utils/service_log.dart';


import 'package:rent_home/utils/app_log.dart';
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
  /// Resolved on use, never at construction -- see the note in AuthController.
  /// `FirebaseMessaging.instance` throws when Firebase did not initialise, and
  /// as a field initializer that took the whole app down rather than costing
  /// it push notifications.
  FirebaseMessaging? get _firebaseMessaging {
    try {
      return FirebaseMessaging.instance;
    } catch (e) {
      logServiceError('notification_service:48', e);
      return null;
    }
  }
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
      // Long enough for a COLD BACKEND, which is the normal case here.
      //
      // These were 5s connect / 8s receive, chosen so a dead endpoint would
      // bail fast rather than stall the UI. The backend sleeps when idle and
      // takes tens of seconds to wake, so the fast bail fired on a server that
      // was merely waking up: opening Settings > Notifications after a few
      // quiet minutes showed "We couldn't load your preferences", and the same
      // screen loaded perfectly on the next attempt. Observed on build 50.
      //
      // A user reads that as broken, not as slow. Waiting is the lesser harm —
      // every screen here shows a spinner while it waits and an honest failure
      // afterwards.
      connectTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
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

  Future<AppNotificationResponse> getNotification({bool history = true}) async {
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.baseUrl = baseUrl;
    _dio.options.headers["Authorization"] = 'Bearer $token';
    try {
      // scope=all asks for the HISTORY — read and unread, paged.
      //
      // Without it the server returns unread rows only, which is what it has
      // always done and what older builds depend on: reading a notification
      // removed it from the one screen that listed it, so nobody could go back
      // and find what they had been told. An older server ignores the query and
      // answers exactly as before, so this is safe against either.
      final response = await _dio.get(
        "/user/notification/Listing",
        queryParameters: history ? {"scope": "all", "limit": 50} : null,
      );
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

  /// What this person wants to be interrupted about.
  ///
  /// Absent keys mean the default, which is on — a category added to the
  /// server later must not arrive switched off on an older build.
  Future<Map<String, dynamic>?> getPreferences() async {
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.baseUrl = baseUrl;
    _dio.options.headers["Authorization"] = 'Bearer $token';
    try {
      final res = await _dio.get("/user/notification/preferences");
      final data = res.data?["data"];
      return data is Map ? Map<String, dynamic>.from(data) : null;
    } catch (e) {
      logger.w("getPreferences failed: $e");
      return null;
    }
  }

  /// Save ONE switch. The server merges, so the categories this build does not
  /// know about are left alone rather than wiped.
  Future<Map<String, dynamic>?> setPreference(
      String channel, String key, bool value) async {
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.baseUrl = baseUrl;
    _dio.options.headers["Authorization"] = 'Bearer $token';
    try {
      // A category switch governs BOTH interrupting channels.
      //
      // Since 2026-09-12 every notification also goes out as mail, gated by
      // the same category on the server's `email` map -- a map nothing on this
      // screen could reach, so a guest who turned "Offers and negotiations"
      // off went on receiving an email for every counter. WhatsApp is its own
      // question (marketing only) and is left alone.
      //
      // One key per channel, never the whole object: the server merges, and
      // this client may know about fewer categories than it does.
      final res = await _dio.put(
        "/user/notification/preferences",
        data: channel == 'push'
            ? {
                'push': {key: value},
                'email': {key: value},
              }
            : {
                channel: {key: value}
              },
      );
      final prefs = res.data?["data"]?["preferences"];
      return prefs is Map ? Map<String, dynamic>.from(prefs) : null;
    } catch (e) {
      logger.w("setPreference failed: $e");
      return null;
    }
  }

  /// Clear the badge in one action.
  ///
  /// Marking twenty rows one tap at a time is not a thing anyone does, so a
  /// count that could only come down that way never came down. Returns the
  /// server's count afterwards rather than assuming zero.
  Future<int?> markAllRead() async {
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.baseUrl = baseUrl;
    _dio.options.headers["Authorization"] = 'Bearer $token';
    try {
      final response = await _dio.post("/user/notification/read-all");
      if (response.statusCode == 200 && response.data?["success"] == true) {
        final n = response.data?["data"]?["unreadCount"];
        return n is num ? n.toInt() : 0;
      }
    } on DioException catch (e) {
      logger.w("markAllRead failed: ${e.response?.data}");
    } catch (_) {}
    return null;
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
        // A LIST. The endpoint's schema takes an array — a bare integer was
        // rejected at validation, so every mark-read from the app failed
        // silently and no notification was ever marked read. The server now
        // coerces a scalar too, so builds already on phones work, but sending
        // the right shape is the actual contract.
        data: {
          "notificationId": [notificationId]
        },
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
    final messaging = _firebaseMessaging;
    if (messaging == null) {
      logger.w("Firebase unavailable — no FCM token, push is off this run.");
      return null;
    }
    return await messaging.getToken();
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
      appLog(data);
      if (Get.isRegistered<NotificationRoutingService>()) {
        Get.find<NotificationRoutingService>().handleNotificationData(data);
      }
    });
  }

  /// **4️⃣ Setup Firebase Listeners**
  Future<void> _setupFirebaseListeners() async {
    // Same reason as the lazy getter above: these throw when Firebase did not
    // initialise, and an unguarded throw here costs the app rather than push.
    try {
      _attachListeners();
    } catch (e) {
      logger.w("Firebase listeners unavailable, push is off this run: $e");
    }
  }

  void _attachListeners() {
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

    // Cold-start handling lives in NotificationRoutingService, which is the
    // service that knows how to route. This was a second getInitialMessage()
    // subscriber whose body had been commented out to stop it double-routing,
    // leaving a 2-second timer that woke up and did nothing. One owner is
    // clearer than one owner plus a disabled copy.

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
