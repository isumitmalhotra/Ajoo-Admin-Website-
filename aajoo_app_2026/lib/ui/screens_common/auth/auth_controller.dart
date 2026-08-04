import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:rent_home/controller/alert_dialog.dart';
import 'package:rent_home/data/models/action_result.dart';
import 'package:rent_home/data/source/remote/utils/api_error_handler.dart';
import 'dart:io';
import '../../../data/models/update_user_model.dart';
import '../../../service/auth_service.dart';
import '../../../service/bookmark_service.dart';
import '../../../service/notification_routing_service.dart';
import '../../../data/models/user_models.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

class AuthController extends GetxController {
  final AuthService authService = AuthService();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  // State management
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxBool isLoggedIn = false.obs;
  final Rx<UserDetail?> userData = Rx<UserDetail?>(null);
  final RxString token = ''.obs;

  // Signup data management
  final RxMap<String, dynamic> signupData = <String, dynamic>{}.obs;
  // Authoritative auth fields captured at the email/password step. Kept as
  // dedicated fields (NOT only in signupData) so they can't be lost when the
  // map is rebuilt across the multi-step profile flow. submitSignup prefers
  // these over signupData/params.
  final RxString authEmail = ''.obs;
  final RxString authPassword = ''.obs;
  final RxString authConfirmPassword = ''.obs;
  final RxBool authIsHost = false.obs;
  final Rx<File?> profileImage = Rx<File?>(null);
  final Rx<File?> governmentIdImage = Rx<File?>(null);
  final Rx<File?> houseAgreement = Rx<File?>(null);

  @override
  void onInit() {
    super.onInit();
    checkLoginStatus();
  }

  // Check if user is logged in
  Future<bool> checkLoginStatus() async {
    try {
      final loggedInStatus = await authService.checkLoginStatus();
      if (loggedInStatus) {
        userData.value = await authService.getSavedUserDetails();
      }
      isLoggedIn.value = loggedInStatus;
      return loggedInStatus;
    } catch (e) {
      rethrow;
    }
  }

  // Login method
  Future<void> login(String email, String password, bool isHost) async {
    try {
      isLoading.value = true;
      error.value = '';
      final LoginResponse response =
          await authService.login(email, password, isHost);
      if (response.success) {
        await _handleSuccessfulLogin(response.data);
      } else if (response.needsVerification && response.userId != null) {
        // Account exists but isn't verified — route to the OTP screen so the
        // user can verify and continue, instead of dead-ending on an error.
        error.value = '';
        showAlert('Verify your account',
            'We sent a verification code. Please verify to continue.', false);
        Get.toNamed('/verify',
            arguments: {'userId': response.userId, 'email': email});
      } else {
        String message = response.message;
        showAlert('Error', message, true);
        error.value = message;
      }
    } catch (e) {
      await handleApiError(e, onError: (message) async {
        _showLoginError(message);
      }, onUnauthorized: (message) async {
        _showLoginError(message);
      });
    } finally {
      isLoading.value = false;
    }
  }

  /// Sign in with Google.
  ///
  /// google_sign_in proves who the user is to Google; firebase_auth turns that
  /// into a Firebase ID token, which is what the backend verifies. Posting the
  /// raw Google token instead would fail — it is issued by Google, not Firebase.
  ///
  /// serverClientId is the web client from google-services.json. Without it the
  /// token audience does not match the project and verification is rejected.
  Future<void> loginWithGoogle(bool isHost) async {
    try {
      isLoading.value = true;
      error.value = '';

      final googleSignIn = GoogleSignIn(
        serverClientId:
            '1006999733744-9mhft1ke8c7cm6ut72bjkq30etnb5ora.apps.googleusercontent.com',
      );
      // Sign out first so a shared handset can choose an account rather than
      // silently reusing whoever signed in last.
      await googleSignIn.signOut();

      final account = await googleSignIn.signIn();
      if (account == null) {
        // The user backed out of the chooser — not an error.
        isLoading.value = false;
        return;
      }

      final googleAuth = await account.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
      final userCredential =
          await fb.FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseIdToken = await userCredential.user?.getIdToken();

      if (firebaseIdToken == null) {
        _showLoginError('Could not complete Google sign-in. Please try again.');
        return;
      }

      final response =
          await authService.loginWithGoogle(firebaseIdToken, isHost);

      // The Firebase session was only ever proof of identity; ours is the
      // session from here, so do not leave a second one to go stale.
      await fb.FirebaseAuth.instance.signOut();
      await googleSignIn.signOut();

      if (response.success) {
        await _handleSuccessfulLogin(response.data);
      } else {
        _showLoginError(response.message);
      }
    } catch (e) {
      await handleApiError(e, onError: (message) async {
        _showLoginError(message);
      }, onUnauthorized: (message) async {
        _showLoginError(message);
      });
    } finally {
      isLoading.value = false;
    }
  }

  void _showLoginError(String message) {
    String msg = message.replaceAll('Exception: ', '');
    showAlert('Error', msg, true);
    error.value = msg;
  }

  Future<void> _handleSuccessfulLogin(LoginData data) async {
    userData.value = data.user;
    isLoggedIn.value = true;
    token.value = data.token;
    authService.setToken(data.token);

    showAlert('Success', 'Login successful', false);
    if (Get.isRegistered<NotificationRoutingService>()) {
      final notificationService = Get.find<NotificationRoutingService>();
      notificationService.processPendingNavigation();
    } else {
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
      } else {
        error.value = response.message;
      }
    } catch (e) {
      await handleApiError(e, onError: (message) async {
        error.value = message;
      }, onUnauthorized: (message) async {
        await logout(); // Logout on error
      });
    } finally {
      isLoading.value = false;
    }
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

  Future<SignupResponse> submitSignup({
    required String email,
    required String password,
    required String confirmPassword,
    required bool isHost,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';
      if (!_validateSignupData()) return Future.error('Invalid data');

      // Resolve auth fields from the most reliable source: dedicated fields →
      // passed params → signupData. This prevents the email/password being lost
      // when signupData is rebuilt across the multi-step profile flow.
      final resolvedEmail = [
        authEmail.value.trim(),
        email.trim(),
        (signupData['user_email'] ?? '').toString().trim(),
      ].firstWhere((v) => v.isNotEmpty, orElse: () => '');
      final resolvedPassword = [
        authPassword.value,
        password,
        (signupData['user_password'] ?? '').toString(),
      ].firstWhere((v) => v.isNotEmpty, orElse: () => '');
      final resolvedConfirm = [
        authConfirmPassword.value,
        confirmPassword,
        (signupData['user_confirmPassword'] ?? '').toString(),
      ].firstWhere((v) => v.isNotEmpty, orElse: () => '');
      // Host role: trust the dedicated field set at the role-selection step,
      // OR the passed param — if either says host, register as host. Both
      // derive from the same selection, so this only adds resilience.
      final resolvedIsHost = authIsHost.value || isHost;

      // Guard: never hit the backend with a missing email (it returns the
      // confusing "Missing required fields"). Surface a clear client error.
      if (resolvedEmail.isEmpty) {
        error.value =
            'Your email is missing. Please go back and re-enter your details.';
        showAlert('Error', error.value, true);
        return Future.error(error.value);
      }

      // Keep signupData consistent with the resolved values.
      signupData.addAll({
        'user_email': resolvedEmail,
        'user_password': resolvedPassword,
        'user_confirmPassword': resolvedConfirm,
        'user_isHost': resolvedIsHost,
      });
      final response = await authService.signup(
        fullName: (signupData['user_fullName'] ?? '').toString(),
        dob: (signupData['user_dob'] ?? '').toString(),
        email: resolvedEmail,
        password: resolvedPassword,
        confirmPassword: resolvedConfirm,
        phone: (signupData['user_pnumber'] ?? '').toString(),
        address: (signupData['user_address'] ?? '').toString(),
        city: (signupData['user_city'] ?? '').toString(),
        zipcode: (signupData['user_pincode'] ?? '').toString(),
        idDoc: governmentIdImage.value,
        docType: int.tryParse(signupData['doc_type']?.toString() ?? '') ?? 0,
        docNumber: (signupData['doc_number'] ?? '').toString(),
        isHost: resolvedIsHost,
        referralCode: "0000",
      );
      if (response.success) {
        showAlert('Success', 'Signup successful', false);
        clearSignupData();
        return response;
      } else {
        showAlert('Error', response.message, true);
        error.value = response.message;
        return response;
      }
    } catch (e) {
      final message = await handleApiError(e, onError: (message) async {
        showAlert('Error', 'Signup failed: $message', true);
        error.value = message;
      }, onUnauthorized: (message) async {
        showAlert('Error', 'Signup failed: $message', true);
        error.value = message;
      });
      return Future.error(message);
    } finally {
      isLoading.value = false;
    }
  }

  bool _validateSignupData() {
    if (!signupData.containsKey('user_pnumber')) {
      error.value = 'Contact number is required';
      showAlert('Error', 'contact number is required', true);
      return false;
    }
    return true;
  }

  Future<void> checkEmailAlreadyExists(String email) async {
    try {
      isLoading.value = true;
      error.value = '';
      final response = await authService.isUserAlreadyExist(email);
      if (response) {
        showAlert('Error', 'Email already exists', true);
        error.value = 'Email already exists';
      }
    } catch (e) {
      const message = 'Something went wrong.'; //await handleApiError(e);
      showAlert('Error', 'Something went wrong.', true);
      error.value = message;
    } finally {
      isLoading.value = false;
    }
  }

  Future<ActionResult> updateUserProfile(
    UserUpdateRequest request,
  ) async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await authService.updateProfile(request);

      if (!response.success) {
        return ActionResult(
          isSuccess: false,
          message: response.message,
        );
      }
      await getUserDetails(skipLogoutOnError: true);

      return ActionResult(
        isSuccess: true,
        message: 'Profile updated successfully!',
      );
    } catch (e) {
      await handleApiError(e);
      error.value = 'Something went wrong.';
      return ActionResult(
        isSuccess: false,
        message: 'Something went wrong.',
      );
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
        showAlert('Success', 'Document updated successfully!', false);
        await getUserDetails(skipLogoutOnError: true);
      } else {
        error.value = response.message;
        showAlert('Error', response.message, true);
      }
    } catch (e) {
      await handleApiError(e,
          onError: (message) async => error.value = message,
          onUnauthorized: (message) async => await logout());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> switchMode(bool isHost) async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await authService.switchUserMode(isHost);
      if (response.success) {
        await authService.saveUserData(userData.value!.toJson());
        showAlert('Success', 'Mode switched successfully', false);
        Get.offAllNamed("/");
      } else {
        showAlert('Error', response.message, true);
        error.value = response.message;
      }
    } catch (e) {
      showAlert('Error', 'Failed to switch mode: ${e.toString()}', true);
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void clearSignupData() {
    signupData.clear();
    authEmail.value = '';
    authPassword.value = '';
    authConfirmPassword.value = '';
    authIsHost.value = false;
    profileImage.value = null;
    governmentIdImage.value = null;
    houseAgreement.value = null;
    error.value = '';
  }

  Future<void> logout() async {
    try {
      // Server-side session teardown BEFORE clearing the local token —
      // otherwise the Authorization header is gone and the backend can't
      // identify which session row to delete. Failure tolerated: we always
      // proceed to local logout so the user is never stuck signed-in on
      // their device because of a network hiccup.
      await authService.serverLogout();

      isLoggedIn.value = false;
      userData.value = null;
      await authService.logout();
      await _firebaseMessaging.deleteToken();
      // Clear per-user caches so the next account doesn't inherit previous
      // user's bookmarks (was a real risk when bookmarks lived in
      // FlutterSecureStorage under a shared key).
      await BookmarkService().clearCache();
      showAlert('Success', 'Logged out successfully', false);
      Get.offAllNamed('/login');
    } catch (e) {
      showAlert('Error', 'Something went wrong.', true);
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
        await authService.logout(); // Clear tokens and user data from storage
        await _firebaseMessaging.deleteToken();
        showAlert('Success', 'Account deleted successfully', false);
        Get.offAllNamed('/login');
        return true;
      } else {
        error.value = response['message'] ?? 'Failed to delete account';
        showAlert('Error', error.value, true);
        return false;
      }
    } catch (e) {
      error.value = 'Something went wrong.';
      showAlert('Error', error.value, true);
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
