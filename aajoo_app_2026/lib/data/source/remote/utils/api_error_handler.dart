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

/// Turn a transport-level failure into something a person can act on.
///
/// This used to fall through to `error.message`, which for a Dio connection
/// failure is the library's own diagnostic string — verbatim, on the login
/// screen:
///
///   "The connection errored: No route to host This indicates an error which
///    most likely cannot be solved by the library."
///
/// That tells the user nothing they can do anything about, and reads like the
/// app is broken rather than the network being unreachable. Every transport
/// failure now maps to a plain sentence, and only a genuine message from our
/// own API is ever shown as-is.
String _friendlyTransportMessage(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return "Aajoo is taking too long to respond. Please try again in a moment.";
    case DioExceptionType.connectionError:
      return "Can't reach Aajoo right now. Check your internet connection and try again.";
    case DioExceptionType.badCertificate:
      return "Couldn't establish a secure connection. Please try again.";
    case DioExceptionType.cancel:
      return "That request was cancelled.";
    case DioExceptionType.badResponse:
      return "Something went wrong at our end. Please try again.";
    case DioExceptionType.unknown:
      // A SocketException surfaces here too on some platforms.
      final raw = error.error?.toString() ?? '';
      if (raw.contains('SocketException') ||
          raw.contains('Failed host lookup') ||
          raw.contains('No route to host') ||
          raw.contains('Network is unreachable')) {
        return "Can't reach Aajoo right now. Check your internet connection and try again.";
      }
      return "Something went wrong. Please try again.";
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
    // Our own API's message is the only one worth showing verbatim. The
    // validation middleware returns `message` as a LIST of field errors, so
    // join it rather than printing "[Instance of ...]".
    final apiMessage = data is Map ? data['message'] : null;
    if (apiMessage is List && apiMessage.isNotEmpty) {
      message = apiMessage.map((e) => e.toString()).join(', ');
    } else if (apiMessage != null && apiMessage.toString().trim().isNotEmpty) {
      message = apiMessage.toString();
    } else {
      message = _friendlyTransportMessage(error);
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
