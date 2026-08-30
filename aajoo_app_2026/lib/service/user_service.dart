// ignore_for_file: avoid_print

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:rent_home/models/booking_history_response_model.dart';
import 'package:rent_home/models/ongoing_reponse.dart';
import 'package:rent_home/models/user_review_model.dart';
import 'package:rent_home/data/ApiConstants.dart';

class UserService {
  final _dio = Dio();
  UserService() {
    _dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
      compact: true,
      maxWidth: 100,
    ));
  }
  final String baseUrl = Apiconstants.baseUrl;
  Future<BookingHistoryResponse> getBookingHistory() async {
    final url = '$baseUrl/user/booking-history';
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.headers['Authorization'] = 'Bearer $token';
    try {
      final response = await _dio.get(url);
      final json = response.data;

      return BookingHistoryResponse.fromJson(json);
    } on DioException catch (err) {
      throw _handleError(err);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserReviewResponse> getUserReviews() async {
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.headers['Authorization'] = 'Bearer $token';
    try {
      final response = await _dio.get("$baseUrl/review/host/user-review-list");
      final json = response.data;
      print(json);

      return UserReviewResponse.fromJson(json);
    } catch (e) {
      print(e);
      throw _handleError(e);
    }
  }

  Future<bool> addReview(Map<String, dynamic> reviewData) async {
    final url = '$baseUrl/user/review-add';
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.headers['Authorization'] = 'Bearer $token';
    try {
      final response = await _dio.post(url, data: reviewData);
      print(response.data);
      return response.data['success'];
    } on DioException catch (err) {
      throw _handleError(err);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Changes the logged-in user's password. Backend route
  /// `POST /user/update-password` (JWT-auth) requires the current password,
  /// the new password, and a matching confirmation. Returns the success flag
  /// plus the server message so the caller can surface the exact reason
  /// (e.g. "current password is incorrect").
  Future<({bool success, String message})> changePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
    String? otp,
  }) async {
    final url = '$baseUrl/user/update-password';
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.headers['Authorization'] = 'Bearer $token';

    try {
      final response = await _dio.post(url, data: {
        'userId': userId,
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
        // One-time email code (POST /user/security/otp, intent 'password').
        // The current password proves the actor knows the secret; the code
        // proves they hold the mailbox. The server wants both.
        if (otp != null && otp.isNotEmpty) 'otp': otp,
      });
      final data = response.data;
      final success = data is Map && data['success'] == true;
      final message = (data is Map ? data['message'] : null)?.toString() ??
          (success
              ? 'Password updated successfully'
              : 'Could not update password');
      return (success: success, message: message);
    } on DioException catch (err) {
      final data = err.response?.data;
      final message = (data is Map ? data['message'] : null)?.toString() ??
          err.message ??
          'Could not update password';
      return (success: false, message: message);
    } catch (e) {
      return (success: false, message: e.toString());
    }
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      final response = error.response?.data;
      final message = response?['message'] ?? error.message;
      return Exception(message);
    }
    return Exception(error.toString());
  }

  Future<OnGoingBookingResponse> getOngoingBookings() async {
    final url = '$baseUrl/user/ongoing/bookings';
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.headers['Authorization'] = 'Bearer $token';

    try {
      final response = await _dio.post(url);
      final json = response.data;
      print(json);

      return OnGoingBookingResponse.fromJson(json);
    } on DioException catch (err) {
      throw _handleError(err);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Uploads a new profile picture and returns the resulting image URL on
  /// success (or null if the server reports failure). The returned URL lets
  /// the UI update the avatar immediately without depending on a follow-up
  /// `/user/detail` refresh.
  Future<String?> uploadProfileImage(File imageFile) async {
    final url = '$baseUrl/user/add/profile-pic';
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.headers['Authorization'] = 'Bearer $token';

    try {
      // Create multipart form data
      final formData = FormData.fromMap({
        'user_image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      // Send POST request
      final response = await _dio.post(url, data: formData);
      print(response.data);

      final data = response.data;
      if (data is Map && data['success'] == true) {
        return data['data']?['image'] as String?;
      }
      return null;
    } on DioException catch (err) {
      throw _handleError(err);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Removes the user's profile picture on the server. Backend clears the
  /// stored attachment. Returns true on success.
  Future<bool> deleteProfileImage() async {
    final url = '$baseUrl/user/delete/profile-pic';
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.headers['Authorization'] = 'Bearer $token';

    try {
      final response = await _dio.post(url);
      print(response.data);
      return response.statusCode == 200 &&
          response.data is Map &&
          response.data['success'] == true;
    } on DioException catch (err) {
      print('deleteProfileImage DioException: ${err.message}');
      return false;
    } catch (e) {
      print('deleteProfileImage error: $e');
      return false;
    }
  }

  /// Soft-deletes a review created by the current user. Backend filters by
  /// `br_userId = req.user.userId`, so a user can never delete someone
  /// else's review even if they guess a reviewId. Returns true on success.
  Future<bool> deleteUserReview(int reviewId) async {
    final url = '$baseUrl/review/user/delete-review';
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.headers['Authorization'] = 'Bearer $token';

    try {
      final response = await _dio.post(url, data: {'reviewId': reviewId});
      print(response.data);
      return response.statusCode == 200 &&
          response.data is Map &&
          response.data['success'] == true;
    } on DioException catch (err) {
      print('deleteUserReview DioException: ${err.message}');
      return false;
    } catch (e) {
      print('deleteUserReview error: $e');
      return false;
    }
  }

// Helper method to parse dates in format dd-MM-yyyy
  DateTime _parseDate(String dateString) {
    final parts = dateString.split('-');
    if (parts.length != 3) {
      throw FormatException('Invalid date format: $dateString');
    }

    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);

    return DateTime(year, month, day);
  }
}
