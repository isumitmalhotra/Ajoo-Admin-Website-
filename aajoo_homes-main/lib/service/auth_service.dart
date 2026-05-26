import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get_connect/http/src/exceptions/exceptions.dart';
import 'dart:io';
import 'package:rent_home/data/ApiConstants.dart';
import 'package:rent_home/data/source/remote/api_client/api_client.dart';
import 'package:rent_home/data/source/remote/utils/api_error_handler.dart';
import 'package:rent_home/data/source/remote/utils/unauthorized_user_exception.dart';
import '../data/models/update_user_model.dart';
import '../data/models/user_models.dart';

class AuthService {
  final String baseUrl = Apiconstants.baseUrl;
  final ApiClient apiClient = ApiClient();
  final storage = const FlutterSecureStorage();

  String TOKEN_KEY = 'user_token';
  String USER_DATA_KEY = 'user_data';

  AuthService() {}
  void setToken(String token) {
    apiClient.setToken(token);
  }

  Future<bool> checkLoginStatus() async {
    try {
      final token = await storage.read(key: TOKEN_KEY);
      final savedUserDataStr = await storage.read(key: USER_DATA_KEY);
      if (token != null && savedUserDataStr != null) {
        setToken(token);
        return true;
      }
      return false;
    } catch (e) {
      throw e;
    }
  }

  Future<void> saveUserData(dynamic data) async {
    await storage.write(key: USER_DATA_KEY, value: json.encode(data));
  }

  Future<UserDetail> getSavedUserDetails() async {
    try {
      final savedUserDataStr = await storage.read(key: USER_DATA_KEY);
      if (savedUserDataStr != null) {
        return UserDetail.fromJson(json.decode(savedUserDataStr));
      }
      throw Exception('No saved user data found');
    } catch (e) {
      throw e;
    }
  }

  Future<bool> logout() async {
    await storage.delete(key: TOKEN_KEY);
    await storage.delete(key: USER_DATA_KEY);
    await storage.delete(key: "fcm_token");
    return true;
  }

  Future<LoginResponse> login(
      String email, String password, bool isHost) async {
    try {
      final response = await apiClient.post('/user/login', data: {
        'user_email': email,
        'user_password': password,
        'isHost': isHost ? 1 : 0,
      });

      if (response['success'] == false) {
        final String msg = response['message'] ?? "";
        throw Exception(msg);
      }

      final loginResponse = LoginResponse.fromJson(response);
      if (loginResponse.success) {
        LoginData data = loginResponse.data;
        await storage.write(key: TOKEN_KEY, value: data.token);
        await storage.write(
            key: USER_DATA_KEY, value: json.encode(data.user.toJson()));
        setToken(loginResponse.data.token);
        await const FlutterSecureStorage().write(key: "pass", value: password);
        await const FlutterSecureStorage().write(key: "email", value: email);
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
    required File idDoc,
    required int docType,
    required String docNumber,
    required bool isHost,
    String? referralCode,
  }) async {
    try {
      final formData = FormData.fromMap({
        'user_fullName': fullName,
        'user_dob': dob,
        'user_email': email,
        'user_username': fullName.split(' ').first,
        'user_password': password,
        'user_confirmPassword': confirmPassword,
        'user_pnumber': phone,
        'user_address': address,
        'user_city': city,
        'user_zipcode': zipcode,
        'user_isHost': isHost,
        'doc_type': int.parse(docType.toString()),
        'doc_number': docNumber,
        'user_ref': referralCode ?? '',
        'user_id_doc': await MultipartFile.fromFile(
          idDoc.path,
          filename: idDoc.path.split('/').last,
        ),
      });
      // Debugging
      final response = await apiClient.post('/user/signup', data: formData);
      await const FlutterSecureStorage().write(key: "pass", value: password);
      await const FlutterSecureStorage().write(key: "email", value: email);
      return SignupResponse.fromJson(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<LoginResponse> verifyOtp({
    required int userId,
    required String otp,
  }) async {
    try {
      final response = await apiClient.post('/user/verify-otp', data: {
        'userId': userId,
        'otp': otp,
      });

      if (response['success']) {
        final token = response['data']['token'];
        setToken(token);
      }

      return LoginResponse.fromJson(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<LoginResponse> switchUserMode(bool isHost) async {
    try {
      final email = await const FlutterSecureStorage().read(key: "email");
      final password = await const FlutterSecureStorage().read(key: "pass");
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
      final response = await apiClient.get('/user/detail');
      return LoginResponse.fromJson(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ResendOtpResponse> resendOtp({required int userId}) async {
    try {
      final response = await apiClient.post('/user/otp-again', data: {
        'userId': userId,
      });
      return ResendOtpResponse.fromJson(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<BaseResponse> updateProfile(UserUpdateRequest request) async {
    try {
      final token = await const FlutterSecureStorage().read(key: "user_token");
      final formData = FormData();
      formData.fields
        ..add(MapEntry(
            'user_fullName', "${request.userFname} ${request.userLname}"))
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
      apiClient.setToken(token ?? "");
      final response = await apiClient.post('/user/update', data: formData);
      return BaseResponse.fromJson(response);
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

      final response = await apiClient.post('/user/update', data: formData);
      return BaseResponse.fromJson(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> isUserAlreadyExist(String email) async {
    try {
      final response =
          await apiClient.post("/user/is-exist", data: {"userEmail": email});
      if (response["message"] == "User Already Exist") {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      //throw Exception('Failed to delete account: $e');
      throw e;
    }
  }

  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final response = await apiClient.post('/user/delete');
      return response;
    } catch (e) {
      throw e;
    }
  }

  Exception _handleError(dynamic error) {
    return handleApiException(error);
  }
}
