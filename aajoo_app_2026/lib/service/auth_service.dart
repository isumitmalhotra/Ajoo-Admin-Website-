import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import "package:http/http.dart" as http;
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../models/update_user_model.dart';
import '../models/user_models.dart';

class AuthService {
  final Dio _dio = Dio();
  final String baseUrl = 'https://api.aajoohomes.com';
  final String TOKEN_KEY = 'user_token';
  final String USER_DATA_KEY = 'user_data';
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  String? _token;

  AuthService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.contentType = 'application/json';
    _dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
      compact: true,
      maxWidth: 90,
      enabled: true,
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        return handler.next(options);
      },
    ));
  }

  void setToken(String token) {
    _token = token;
  }

  Future<bool> checkLoginStatus() async {
    final token = await storage.read(key: TOKEN_KEY);
    if (token == null || token.isEmpty) {
      return false;
    }
    setToken(token);
    return true;
  }

  Future<UserDetail?> getSavedUserDetails() async {
    final savedUserDataStr = await storage.read(key: USER_DATA_KEY);
    if (savedUserDataStr == null || savedUserDataStr.isEmpty) {
      return null;
    }
    try {
      final data = jsonDecode(savedUserDataStr) as Map<String, dynamic>;
      return UserDetail.fromJson(data);
    } catch (e) {
      print('Error decoding saved user data: $e');
      return null;
    }
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await storage.write(key: USER_DATA_KEY, value: jsonEncode(userData));
  }

  Future<void> logout() async {
    _token = null;
    await storage.delete(key: TOKEN_KEY);
    await storage.delete(key: USER_DATA_KEY);
  }

  Future<LoginResponse> login(
      String email, String password, bool isHost) async {
    try {
      final response = await _dio.post('/user/login', data: {
        'user_email': email,
        'user_password': password,
        'isHost': isHost ? 1 : 0,
      });
      print("isHost: $isHost");
      print(response.data);

      final loginResponse = LoginResponse.fromJson(response.data);

      if (loginResponse.success) {
        setToken(loginResponse.data.token);
        await storage.write(key: TOKEN_KEY, value: loginResponse.data.token);
        await saveUserData(loginResponse.data.user.toJson());
        await storage.write(key: "pass", value: password);
        await storage.write(key: "email", value: email);
      }
      return loginResponse;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<SignupResponse> signup({
    required String fullName,
    required String dob,
    required String email,
    required String password,
    required String confirmPassword,
    required String phone,
    required String address,
    required String city,
    required String zipcode,
    File? idDoc,
    required int docType,
    required String docNumber,
    required bool isHost,
    String? referralCode,
  }) async {
    try {
      print('${isHost}isHost');
      final usernameBase = fullName.trim().split(' ').first;
      final Map<String, dynamic> fields = {
        'user_fullName': fullName,
        'user_dob': dob,
        'user_email': email,
        'user_username': usernameBase.isEmpty ? email.split('@').first : usernameBase,
        'user_password': password,
        'user_confirmPassword': confirmPassword,
        'user_pnumber': phone,
        'user_address': address,
        'user_city': city,
        'user_zipcode': zipcode,
        'user_isHost': isHost,
        'doc_type': docType,
        'doc_number': docNumber,
        'user_ref': referralCode ?? '',
      };
      if (idDoc != null) {
        fields['user_id_doc'] = await MultipartFile.fromFile(
          idDoc.path,
          filename: idDoc.path.split('/').last,
        );
      }
      final formData = FormData.fromMap(fields);
      final response = await _dio.post('/user/signup', data: formData);
      await const FlutterSecureStorage().write(key: "pass", value: password);
      await const FlutterSecureStorage().write(key: "email", value: email);
      return SignupResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<LoginResponse> verifyOtp({
    required int userId,
    required String otp,
  }) async {
    try {
      final response = await _dio.post('/user/verify-otp', data: {
        'userId': userId,
        'otp': otp,
      });
      print(response.data);

      if (response.data['success']) {
        final token = response.data['data']['token'];
        setToken(token);
        await storage.write(key: TOKEN_KEY, value: token);
      }

      return LoginResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<LoginResponse> switchUserMode(bool isHost) async {
    try {
      final email = await storage.read(key: "email");
      final password = await storage.read(key: "pass");
      if (email == null || password == null) {
        throw Exception("User not logged in");
      }
      final response = await login(email, password, isHost);
      if (response.success) {
        setToken(response.data.token);
      }
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<LoginResponse> getUserDetails() async {
    try {
      final response = await _dio.get('/user/detail');
      print(response.data);
      return LoginResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ResendOtpResponse> resendOtp({required int userId}) async {
    try {
      final response = await _dio.post('/user/otp-again', data: {
        'userId': userId,
      });

      return ResendOtpResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<BaseResponse> updateProfile(UserUpdateRequest request) async {
    try {
      final token = await storage.read(key: TOKEN_KEY);
      print("json: ${request.toJson()}");
      final formData = FormData();
      formData.fields
        ..add(MapEntry('user_fullName', request.userFname))
        ..add(MapEntry('user_pnumber', request.userPnumber))
        ..add(MapEntry('user_address', request.userAddress))
        ..add(MapEntry('user_city', request.userCity))
        ..add(MapEntry('user_zipcode', request.userZipcode));
      if (request.docType != null) {
        formData.fields.add(MapEntry('doc_type', request.docType!));
      }
      if (request.docNumber != null) {
        formData.fields.add(MapEntry('doc_number', request.docNumber!));
      }
      if (request.idDoc != null) {
        formData.files.add(MapEntry(
          'user_id_doc',
          await MultipartFile.fromFile(
            request.idDoc!.path,
            filename: request.idDoc!.path.split('/').last,
          ),
        ));
      }
      _dio.options.headers["Authorization"] = "Bearer $token";
      final response = await _dio.post('/user/update', data: formData);
      print(response.data);
      return BaseResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<BaseResponse> updateDocument({
    required String userFullName,
    required String userPnumber,
    required String userAddress,
    required String userCity,
    required String userZipcode,
    required int docType,
    required String docNumber,
    required File userIdDoc,
  }) async {
    try {
      final formData = FormData.fromMap({
        'user_fullName': userFullName,
        'user_pnumber': userPnumber,
        'user_address': userAddress,
        'user_city': userCity,
        'user_zipcode': userZipcode,
        'doc_type': docType,
        'doc_number': docNumber,
        'user_id_doc': await MultipartFile.fromFile(
          userIdDoc.path,
          filename: userIdDoc.path.split('/').last,
        ),
      });

      final response = await _dio.post('/user/update', data: formData);
      print('Document update response: ${response.data}');
      return BaseResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> userAlreadyExist(String email) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/user/is-exist"),
            body: {"userEmail": email},
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Email check failed (${response.statusCode})');
      }

      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        final message = data["message"]?.toString();
        if (message == null) {
          throw Exception('Email check returned unexpected response');
        }
        return message == "User Already Exist";
      }

      throw Exception('Email check returned unexpected response');
    } catch (err) {
      print(err);
      throw Exception('Email check unavailable');
    }
  }

  Future<bool> isUserAlreadyExist(String email) async {
    return userAlreadyExist(email);
  }

  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final response = await _dio.post('/user/delete');
      print('Delete account response: ${response.data}');
      return response.data;
    } catch (e) {
      print('Error deleting account: $e');
      throw Exception('Failed to delete account: $e');
    }
  }

  Exception _handleError(dynamic error) {
    // Don't automatically redirect on every error - let the calling code handle it
    // get_package.Get.offAll(() => const AuthPage());
    if (error is DioException) {
      final response = error.response?.data;
      print('Error during API call: $response');
      final message = response?['message'] ?? error.message;
      print('Error during API call: $message');
      // Get.snackbar('Error', message, snackPosition: SnackPosition.TOP
      return Exception(message);
    }
    return Exception(error.toString());
  }
}
