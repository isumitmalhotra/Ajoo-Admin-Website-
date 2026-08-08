import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class ForgotPasswordService {
  final _dio = Dio();
  final String baseUrl = 'https://aajaodev.onrender.com/';
  ForgotPasswordService() {
    _dio.options.baseUrl = baseUrl;
    _dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
      compact: true,
      maxWidth: 90,
    ));
    _dio.options.contentType = 'application/json';
  }

  Future<bool> sendOtpToEmail(String email) async {
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.headers['Authorization'] = 'Bearer $token';
    try {
      final response = await _dio.post(
        "user/forget-password",
        data: {"userEmail": email.trim()},
      );
      print(response.data);
      return response.data['success'];
    } catch (err) {
      print(err);
      return false;
    }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.headers['Authorization'] = 'Bearer $token';
    try {
      final response = await _dio.post("/user/forget/verify-otp", data: {
        "userEmail": email.trim(),
        "otp": otp,
      });
      print(response.data);
      final forgetPasswordToken = response.data['data']["token"];
      await const FlutterSecureStorage()
          .write(key: "forget_password_token", value: forgetPasswordToken);
      return response.data['success'];
    } catch (err) {
      print(err);
      return false;
    }
  }

  Future<bool> updatePassword(
      String password, String cPassword, String email) async {
    final token =
        await const FlutterSecureStorage().read(key: "forget_password_token");
    print('FORGET Token: $token');
    _dio.options.headers['Authorization'] = 'Bearer $token';
    try {
      final response = await _dio.post("user/update/forget-password", data: {
        "newPassword": password,
        "confirmPassword": cPassword,
        "token": token,
        "userEmail": email.trim()
      });
      print(response.data);
      return response.data['success'];
    } on DioException catch (err) {
      print(err);
      print(err.response?.data);
      return false;
    }
  }
}
