import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Default 401 behavior — a soft-deleted or expired session (backend returns
/// 401 "Account no longer exists" / "token expired") clears the local session
/// and sends the user to login. Mirrors the web axios interceptor. Callers that
/// pass their own `onUnauthorized` override this.
Future<void> _defaultUnauthorized(String message) async {
  try {
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'user_token');
    await storage.delete(key: 'user_data');
  } catch (_) {}
  // Guard against redirect loops.
  if (Get.currentRoute != '/login') {
    Get.offAllNamed('/login');
  }
}

Future<String> handleApiError(
  dynamic error, {
  Future<void> Function(String message)? onError,
  Future<void> Function(String message)? onUnauthorized,
}) async {
  String message = 'Something went wrong.';
  int? statusCode;

  if (error is DioException) {
    statusCode = error.response?.statusCode;
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      message = data['message'].toString();
    } else if (error.message != null) {
      message = error.message!;
    }
  } else if (error is Exception) {
    message = error.toString().replaceFirst('Exception: ', '');
  }

  if (statusCode == 401) {
    if (onUnauthorized != null) {
      await onUnauthorized(message);
    } else {
      await _defaultUnauthorized(message);
    }
  } else if (onError != null) {
    await onError(message);
  }

  return message;
}
