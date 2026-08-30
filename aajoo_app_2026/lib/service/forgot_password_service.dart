import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:rent_home/data/ApiConstants.dart';

class ForgotPasswordService {
  final _dio = Dio();
  final String baseUrl = '${Apiconstants.baseUrl}/';
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

  /// True when the text the user typed is a mobile number rather than an email.
  /// A reset should not make someone remember which one they signed up with.
  static bool looksLikeMobile(String v) {
    final digits = v.replaceAll(RegExp(r'\D'), '');
    return !v.contains('@') && digits.length >= 10;
  }

  /// Start a reset by SMS (A-11). The platform had no SMS capability at all
  /// until now, so this is new rather than repaired. Returns the server's own
  /// message when it refuses — including the honest "SMS isn't available yet"
  /// while no provider is configured — because a silent false here is what
  /// leaves someone waiting for a text nobody tried to send.
  Future<({bool ok, String? message})> sendOtpToMobile(String mobile) async {
    try {
      final response = await _dio.post(
        "user/forget-password/sms",
        data: {"mobile": mobile.replaceAll(RegExp(r'\D'), '')},
      );
      return (ok: response.data['success'] == true, message: response.data['message']?.toString());
    } on DioException catch (err) {
      return (ok: false, message: _serverMessage(err));
    } catch (_) {
      return (ok: false, message: null);
    }
  }

  /// The server's explanation, if it gave one. Errors here used to be swallowed
  /// into a bare `false`, so every failure looked identical to the user.
  String? _serverMessage(DioException err) {
    final data = err.response?.data;
    if (data is Map && data['message'] != null) {
      final m = data['message'];
      if (m is List) return m.join(', ');
      return m.toString();
    }
    return null;
  }

  /// Email channel. No Authorization header: this is a LOGGED-OUT flow, and
  /// the stale user_token this used to attach belonged to whoever last used
  /// the device — wrong on principle even when the server ignored it.
  Future<({bool ok, String? message})> sendOtpToEmail(String email) async {
    _dio.options.headers.remove('Authorization');
    try {
      final response = await _dio.post(
        "user/forget-password",
        data: {"userEmail": email.trim()},
      );
      return (
        ok: response.data['success'] == true,
        message: response.data['message']?.toString()
      );
    } on DioException catch (err) {
      return (ok: false, message: _serverMessage(err));
    } catch (_) {
      return (ok: false, message: null);
    }
  }

  Future<({bool ok, String? message})> verifyOtp(
      String email, String otp) async {
    _dio.options.headers.remove('Authorization');
    try {
      // Either channel — the server keys the same OTP row on whichever was
      // used, so send the one the person actually typed.
      final isMobile = looksLikeMobile(email);
      final response = await _dio.post("/user/forget/verify-otp", data: {
        if (isMobile) "mobile": email.replaceAll(RegExp(r'\D'), '')
        else "userEmail": email.trim(),
        "otp": otp,
      });
      final ok = response.data['success'] == true;
      if (ok) {
        final forgetPasswordToken = response.data['data']?["token"];
        if (forgetPasswordToken != null) {
          await const FlutterSecureStorage().write(
              key: "forget_password_token",
              value: forgetPasswordToken.toString());
        }
      }
      return (ok: ok, message: response.data['message']?.toString());
    } on DioException catch (err) {
      return (ok: false, message: _serverMessage(err));
    } catch (_) {
      return (ok: false, message: null);
    }
  }

  Future<({bool ok, String? message})> updatePassword(
      String password, String cPassword, String email) async {
    // The short-lived reset token verifyOtp stored — NOT a user session.
    final token =
        await const FlutterSecureStorage().read(key: "forget_password_token");
    _dio.options.headers['Authorization'] = 'Bearer $token';
    try {
      final response = await _dio.post("user/update/forget-password", data: {
        "newPassword": password,
        "confirmPassword": cPassword,
        "token": token,
        "userEmail": email.trim()
      });
      return (
        ok: response.data['success'] == true,
        message: response.data['message']?.toString()
      );
    } on DioException catch (err) {
      // Surface the server's reason — a 422 here carries the password rules.
      return (ok: false, message: _serverMessage(err));
    } catch (_) {
      return (ok: false, message: null);
    }
  }
}
