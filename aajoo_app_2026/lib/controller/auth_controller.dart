import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'dart:io';
import '../models/update_user_model.dart';
import '../service/auth_service.dart';
import '../service/notification_routing_service.dart';
import '../models/user_models.dart';

class AuthController extends GetxController {
  final AuthService authService = AuthService();
  final storage = const FlutterSecureStorage();

  // State management
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxBool isLoggedIn = false.obs;
  final Rx<UserDetail?> userData = Rx<UserDetail?>(null);
  final RxString token = ''.obs;

  // Signup data management
  final RxMap<String, dynamic> signupData = <String, dynamic>{}.obs;
  final Rx<File?> profileImage = Rx<File?>(null);
  final Rx<File?> governmentIdImage = Rx<File?>(null);
  final Rx<File?> houseAgreement = Rx<File?>(null);

  String TOKEN_KEY = 'user_token';
  String USER_DATA_KEY = 'user_data';

  @override
  void onInit() {
    super.onInit();
    checkLoginStatus();
  }

  Future<bool> checkLoginStatus() async {
    try {
      final token = await storage.read(key: TOKEN_KEY);
      final savedUserDataStr = await storage.read(key: USER_DATA_KEY);

      if (token != null && savedUserDataStr != null) {
        authService.setToken(token);
        isLoggedIn.value = true;
        return true;
      }
      return false;
    } catch (e) {
      print('Error checking login status: $e');
      await logout();
      return false;
    }
  }

  void showSnackbar(String title, String message, bool isError) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: isError ? Colors.red[100] : Colors.green[100],
      colorText: isError ? Colors.red[900] : Colors.green[900],
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(10),
      borderRadius: 10,
      icon: Icon(
        isError ? Icons.error : Icons.check_circle,
        color: isError ? Colors.red[900] : Colors.green[900],
      ),
    );
  }

  // Login Flow
  Future<void> login(String email, String password, bool isHost) async {
    try {
      isLoading.value = true;
      error.value = '';
      print('Logging in with email: $email, isHost: $isHost');

      final LoginResponse response =
          await authService.login(email, password, isHost);
      if (response.success) {
        await _handleSuccessfulLogin(response.data);
      } else {
        _handleLoginError(response.message);
      }
    } catch (e) {
      print('Login error: $e');
      _handleLoginException("User not found or invalid credentials");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _handleSuccessfulLogin(LoginData data) async {
    await storage.write(key: TOKEN_KEY, value: data.token);
    await storage.write(
        key: USER_DATA_KEY, value: json.encode(data.user.toJson()));

    userData.value = data.user;
    isLoggedIn.value = true;
    token.value = data.token;
    authService.setToken(data.token);

    showSnackbar('Success', 'Login successful', false);

    // Check for pending notification navigation
    if (Get.isRegistered<NotificationRoutingService>()) {
      final notificationService = Get.find<NotificationRoutingService>();
      notificationService.processPendingNavigation();
    } else {
      // Navigate based on user type
      print("User is host: ${data.user.isHost}");
      if (data.user.isHost) {
        Get.offAllNamed('/host/home');
      } else {
        Get.offAllNamed('/home');
      }
    }
  }

  Future<void> getUserDetails({bool skipLogoutOnError = false}) async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await authService.getUserDetails();

      if (response.success) {
        userData.value = response.data.user;
        print('User data fetched successfully: ${userData.value?.toJson()}');
        final data = await storage.read(key: USER_DATA_KEY);
        print(data);
        print(userData.value?.toJson().map((key, value) {
          return MapEntry(key, value is String ? value.trim() : value);
        }));

        // userData.value = UserDetail.fromJson(json.decode(data!));
        // print(userData.value!.toJson());
      } else {
        error.value = response.message;
        if (!skipLogoutOnError) {
          await logout(); // Logout if unable to get user details
        }
      }
    } catch (e) {
      error.value = e.toString();
      if (!skipLogoutOnError) {
        await logout(); // Logout on error
      }
      // _handleLoginError("So")
    } finally {
      isLoading.value = false;
    }
  }

  void _handleLoginError(String message) {
    showSnackbar('Error', message, true);
    error.value = message;
  }

  void _handleLoginException(dynamic e) {
    final message = e is Exception
        ? e.toString().replaceAll('Exception: ', '')
        : e.toString();
    showSnackbar('Error', 'Login failed: $message', true);
    error.value = message;
  }

  void updateBasicInfo({
    required String fullName,
    required String dob,
    required String address,
    required String city,
    required String pincode,
    File? profileImage,
  }) {
    signupData.addAll({
      'user_fullName': fullName,
      'user_dob': dob,
      'user_address': address,
      'user_city': city,
      'user_zipcode': pincode,
    });
    if (profileImage != null) {
      this.profileImage.value = profileImage;
    }
  }

  Map<String, int> idTypeMapping = {
    'Aadhaar Card': 1,
    'PAN Card': 2,
    'Driving License': 3,
  };

  void updateGovernmentId({
    required String docType,
    required String docNumber,
    required File idImage,
  }) {
    // Convert string docType to number using the mapping
    final docTypeNumber = idTypeMapping[docType];

    signupData.addAll({
      'doc_type': docTypeNumber,
      'doc_number': docNumber,
    });
    governmentIdImage.value = idImage;
  }

  void updateEmergencyContact({
    required String countryCode,
    required String phoneNumber,
  }) {
    signupData['user_pnumber'] = phoneNumber;
  }

  void updateHouseAgreement(File agreement) {
    houseAgreement.value = agreement;
  }

  void updateReferralCode(String? code) {
    if (code != null && code.isNotEmpty) {
      signupData['user_ref'] = code;
    }
  }

  void updateSignupData(Map<String, dynamic> data) {
    signupData.addAll(data);
  }

  // Signup Flow methods remain mostly the same, just updated to use the new models
  Future<SignupResponse> submitSignup({
    required String email,
    required String password,
    required String confirmPassword,
    required bool isHost,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';
      print("ID DOC : ${governmentIdImage.value.toString()}");
      if (!_validateSignupData()) return Future.error('Invalid data');

      signupData.addAll({
        'user_email': email,
        'user_password': password,
        'user_confirmPassword': confirmPassword,
        'user_isHost': isHost,
      });
      print("This is the Sugn upr data--> ${signupData.toJson()}");

      print("ID DOC : ${governmentIdImage.value.toString()}");
      for (var key in signupData.keys) {
        print(
            '$key: ${signupData[key]}   type : ${signupData[key].runtimeType}');
      }
      final response = await authService.signup(
        fullName: signupData['user_fullName'],
        dob: signupData['user_dob'],
        email: signupData['user_email'],
        password: signupData['user_password'],
        confirmPassword: signupData['user_confirmPassword'],
        phone: signupData['user_pnumber'],
        address: signupData['user_address'],
        city: signupData['user_city'],
        zipcode: signupData['user_pincode'],
        // The ID image is optional, same as the web signup, which only appends
        // the file when one was picked. The type and number are not.
        idDoc: governmentIdImage.value,
        docType: int.tryParse(signupData['doc_type']?.toString() ?? '') ?? 0,
        docNumber: signupData['doc_number'] ?? '',
        isHost: signupData['user_isHost'],
        referralCode: (signupData['user_ref'] ?? '').toString(),
      );

      print(response);

      if (response.success) {
        showSnackbar('Success', 'Signup successful', false);
        clearSignupData();
        return response;
      } else {
        showSnackbar('Error', response.message, true);
        error.value = response.message;
        return response;
      }
    } catch (e) {
      final message = e is Exception
          ? e.toString().replaceAll('Exception: ', '')
          : e.toString();
      showSnackbar('Error', 'Signup failed: $message', true);
      error.value = message;
      return Future.error(message);
    } finally {
      isLoading.value = false;
    }
  }

  bool _validateSignupData() {
    if (!signupData.containsKey('user_pnumber')) {
      error.value = 'Contact number is required';
      showSnackbar('Error', 'contact number is required', true);
      return false;
    }
    return true;
  }

  Future<void> checkEmailAlreadyExists(String email) async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await authService.userAlreadyExist(email);
      print(response);

      if (response) {
        showSnackbar('Error', 'Email already exists', true);
        error.value = 'Email already exists';
      }
    } catch (e) {
      showSnackbar('Error', 'Error checking email: ${e.toString()}', true);
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateUserProfile(UserUpdateRequest request) async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await authService.updateProfile(request);

      if (response.success) {
        showSnackbar('Success', 'Profile updated successfully!', false);
        // Refresh user data without logout on error
        await getUserDetails(skipLogoutOnError: true);
      } else {
        error.value = response.message;
        showSnackbar('Error', response.message, true);
      }
    } catch (e) {
      final message = e is Exception
          ? e.toString().replaceAll('Exception: ', '')
          : e.toString();
      error.value = message;
      print('Error during profile update: $message');
      showSnackbar('Error', 'Failed to update profile: $message', true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateDocument({
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
      isLoading.value = true;
      error.value = '';

      final response = await authService.updateDocument(
        userFullName: userFullName,
        userPnumber: userPnumber,
        userAddress: userAddress,
        userCity: userCity,
        userZipcode: userZipcode,
        docType: docType,
        docNumber: docNumber,
        userIdDoc: userIdDoc,
      );

      if (response.success) {
        showSnackbar('Success', 'Document updated successfully!', false);
        // Refresh user data after successful update
        await getUserDetails(skipLogoutOnError: true);
      } else {
        error.value = response.message;
        showSnackbar('Error', response.message, true);
      }
    } catch (e) {
      final message = e is Exception
          ? e.toString().replaceAll('Exception: ', '')
          : e.toString();
      error.value = message;
      showSnackbar('Error', 'Failed to update document: $message', true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> switchMode(bool isHost) async {
    try {
      isLoading.value = true;
      error.value = '';

      // Throws with the server's reason when refused — see the note in
      // AuthService.switchUserMode.
      await authService.switchUserMode(isHost);
      if (userData.value != null) {
        await storage.write(
            key: USER_DATA_KEY, value: json.encode(userData.value!.toJson()));
      }
      showSnackbar('Success', 'Mode switched successfully', false);
      Get.offAllNamed("/");
    } catch (e) {
      showSnackbar('Error', 'Failed to switch mode: ${e.toString()}', true);
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void clearSignupData() {
    signupData.clear();
    profileImage.value = null;
    governmentIdImage.value = null;
    houseAgreement.value = null;
    error.value = '';
  }

  Future<void> logout() async {
    try {
      isLoggedIn.value = false;
      userData.value = null;

      await storage.delete(key: TOKEN_KEY);
      await storage.delete(key: USER_DATA_KEY);

      showSnackbar('Success', 'Logged out successfully', false);
      Get.offAllNamed('/login');
    } catch (e) {
      showSnackbar('Error', 'Logout failed: ${e.toString()}', true);
      print('Error during logout: $e');
    }
  }

  Future<bool> deleteAccount() async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await authService.deleteAccount();

      if (response['success'] == true) {
        // Clear all user data
        isLoggedIn.value = false;
        userData.value = null;
        await storage.delete(key: TOKEN_KEY);
        await storage.delete(key: USER_DATA_KEY);

        showSnackbar('Success', 'Account deleted successfully', false);
        Get.offAllNamed('/login');
        return true;
      } else {
        error.value = response['message'] ?? 'Failed to delete account';
        showSnackbar('Error', error.value, true);
        return false;
      }
    } catch (e) {
      error.value = 'Failed to delete account: ${e.toString()}';
      showSnackbar('Error', error.value, true);
      print('Error deleting account: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
