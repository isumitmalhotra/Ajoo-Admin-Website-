
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rent_home/data/source/remote/api_client/api_client.dart';

class ForgotPasswordService {
  final ApiClient apiClient = ApiClient();

  Future<bool> sendOtpToEmail(String email) async {
    try {
      final response = await apiClient.post(
        "/user/forget-password",
        data: {"userEmail": email.trim()},
      );
      return response['success'];
    } catch (err) {
      return false;
    }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    try {
      final response = await apiClient.post("/user/forget/verify-otp", data: {
        "userEmail": email.trim(),
        "otp": otp,
      });
      final forget_password_token = response['data']["token"];
      await const FlutterSecureStorage()
          .write(key: "forget_password_token", value: forget_password_token);
      return response['success'];
    } catch (err) {
      return false;
    }
  }

  Future<bool> updatePassword(String password, String cPassword, String email) async {
    final token = await const FlutterSecureStorage().read(key: "forget_password_token");
    print('FORGET Token: $token');
    try {
      final response = await apiClient.post(
        "/user/update/forget-password", 
        data: {
          "newPassword": password,
          "confirmPassword": cPassword,
          "token": token,
          "userEmail": email.trim()
        },
        authToken: token
      );
      return response['success'];
     } catch (err) {
      return false;
    }
  }
}
