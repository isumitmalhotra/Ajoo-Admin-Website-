// ignore_for_file: avoid_print

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:rent_home/data/source/remote/api_client/api_client.dart';
import 'package:rent_home/data/models/booking_history_response_model.dart';
import 'package:rent_home/data/models/ongoing_reponse.dart';
import 'package:rent_home/data/models/user_review_model.dart';

class UserService {
  final ApiClient apiClient = ApiClient();
  UserService();

  Future<BookingHistoryResponse> getBookingHistory() async {
    try {
      final response = await apiClient.get('/user/booking-history');
      return BookingHistoryResponse.fromJson(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserReviewResponse> getUserReviews() async {
    try {
      final response = await apiClient.get("/review/host/user-review-list");
      return UserReviewResponse.fromJson(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> addReview(Map<String, dynamic> reviewData) async {
    try {
      final response =
          await apiClient.post('/user/review-add', data: reviewData);
      return response['success'];
    } catch (e) {
      throw _handleError(e);
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
    try {
      final response = await apiClient.post('/user/ongoing/bookings');
      return OnGoingBookingResponse.fromJson(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> uploadProfileImage(File imageFile) async {
    try {
      // Create multipart form data
      final formData = FormData.fromMap({
        'user_image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });
      final response =
          await apiClient.post('/user/add/profile-pic', data: formData);
      // Assuming the API returns a success field in the response
      return response['success'] ?? true;
    } catch (e) {
      throw _handleError(e);
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

class AppException implements Exception {
  final String message;

  AppException(this.message);

  @override
  String toString() => message;
}
