import 'package:dio/dio.dart';
import 'package:rent_home/data/source/remote/utils/unauthorized_user_exception.dart';

Exception handleApiException(dynamic error) {
  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    final response = error.response?.data;

    final String message = (response?['message'] as String?) ??
        error.message ??
        'Something went wrong';
    // 🔐 Detect Unauthorized
    if (statusCode == 401) {
      return UnauthorizedUserException(
        message.trim().isNotEmpty
            ? message
            : "Session expired. Please login again.",
      );
    }
    return Exception(message);
  }
  return Exception(error.toString());
}

Future<String> handleApiError(
  dynamic error, {
  Future<void> Function(String message)? onError,
  Future<void> Function(String message)? onUnauthorized,
}) async {
  if (error is UnauthorizedUserException) {
    final msg = error.message;
    if (onUnauthorized != null) {
      await onUnauthorized(msg);
    }
    return msg; // important: stop further handling
  }

  final msg = error is Exception
      ? error.toString().replaceAll('Exception: ', '')
      : 'Something went wrong';

  if (onError != null) {
    await onError(msg);
  }

  return msg;
}
