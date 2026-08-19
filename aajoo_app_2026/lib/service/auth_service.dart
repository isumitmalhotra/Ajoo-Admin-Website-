import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import "package:http/http.dart" as http;
import '../data/source/remote/dio_config.dart';
import '../models/update_user_model.dart';
import '../models/user_models.dart';
import 'package:rent_home/utils/secure_store.dart';

class AuthService {
  final Dio _dio = Dio();
  final String baseUrl = 'https://aajaodev.onrender.com';
  final String TOKEN_KEY = 'user_token';
  final String USER_DATA_KEY = 'user_data';
  // The shared, hardened instance: reads on a device with a broken Keystore
  // return null instead of throwing. See utils/secure_store.dart.
  final FlutterSecureStorage storage = secureStore;
  String? _token;

  AuthService() {
    // Was: no timeouts at all, and a logger that printed request bodies —
    // passwords on the way out, JWTs on the way back — into logcat on every
    // device, release builds included.
    //
    // The timeouts matter here more than anywhere: the backend is on Render's
    // free tier and sleeps after ~15 minutes, so the first login of the day has
    // to wake it. Without a timeout that is an indefinite spinner, and the
    // connection attempt against a waking container is what produced
    // "No route to host" on a server that was healthy a minute later.
    DioConfig.apply(_dio, baseUrl);

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
    final token = await secureRead(TOKEN_KEY);
    if (token == null || token.isEmpty) {
      return false;
    }
    setToken(token);
    return true;
  }

  Future<UserDetail?> getSavedUserDetails() async {
    final savedUserDataStr = await secureRead(USER_DATA_KEY);
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
    // Older installs persisted the password; clear it on the way out so an
    // upgrade does not leave it sitting there indefinitely.
    await purgeStoredPassword();
  }

  /// Best-effort server-side session invalidation. Backend deletes the row
  /// in `tbl_user_login_auth` so the JWT can't be reused. Failure is
  /// tolerated — caller still proceeds with local logout. The token must
  /// still be available on the Dio instance when this is called.
  Future<bool> serverLogout() async {
    final token = _token ?? await storage.read(key: TOKEN_KEY);
    if (token == null || token.isEmpty) return false;
    try {
      final response = await _dio.post(
        '/user/logout',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200 &&
          response.data is Map &&
          response.data['success'] == true;
    } catch (_) {
      return false;
    }
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
        // The password is deliberately NOT stored. It used to be, so that
        // switchUserMode() could silently log in again with the other isHost
        // flag — /user/switch-mode does that with the session token now, so
        // keeping a password on the device bought nothing and risked plenty.
        await storage.write(key: "email", value: email);
      }
      return loginResponse;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Exchange a Firebase ID token (obtained after a Google sign-in) for an
  /// Aajoo session. The server verifies the token and returns exactly what
  /// /user/login returns, so the caller can reuse the normal success path.
  Future<LoginResponse> loginWithGoogle(String idToken, bool isHost) async {
    try {
      final response = await _dio.post('/user/auth/google', data: {
        'idToken': idToken,
        'isHost': isHost ? 1 : 0,
      });

      final loginResponse = LoginResponse.fromJson(response.data);

      if (loginResponse.success) {
        setToken(loginResponse.data.token);
        await storage.write(key: TOKEN_KEY, value: loginResponse.data.token);
        await saveUserData(loginResponse.data.user.toJson());
        // No password is stored: there is not one for a Google account, and
        // writing a placeholder would let the silent re-login path try it.
        await storage.delete(key: 'pass');
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
      };
      // Only send a referral when there actually is one. The backend attributes
      // the reward off this field, and an unknown code is silently discarded —
      // so a placeholder here reads as "referred by nobody" while still looking
      // like a referral in the request.
      final ref = (referralCode ?? '').trim();
      if (ref.isNotEmpty) {
        fields['user_ref'] = ref;
      }
      if (idDoc != null) {
        fields['user_id_doc'] = await MultipartFile.fromFile(
          idDoc.path,
          filename: idDoc.path.split('/').last,
        );
      }
      final formData = FormData.fromMap(fields);
      final response = await _dio.post('/user/signup', data: formData);
      // Email only — see the note in login() on why the password is not kept.
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
      // == true, not a bare truthiness read: `success` is dynamic, and a 0/1
      // from the server would make the bare read throw int-is-not-bool.
      if (response.data['success'] == true) {
        final token = response.data['data']['token'];
        setToken(token);
        await storage.write(key: TOKEN_KEY, value: token);
      }

      return LoginResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Swap the session between guest and host.
  ///
  /// Trades the current token for one carrying the other role. This used to
  /// re-run login() with a password read back off the device; the server can
  /// do it from the token now, so nothing has to remember a password.
  Future<bool> switchUserMode(bool isHost) async {
    try {
      final response = await _dio.post('/user/switch-mode', data: {
        'isHost': isHost ? 1 : 0,
      });
      final body = response.data;
      final ok = body is Map && body['success'] == true;
      if (!ok) {
        // Refused for a reason worth showing — e.g. this account is not a host.
        throw Exception(
            (body is Map ? body['message'] : null) ?? 'Could not switch mode');
      }
      final token = body['data']?['token'] as String?;
      if (token == null || token.isEmpty) {
        throw Exception('Could not switch mode');
      }
      setToken(token);
      await storage.write(key: TOKEN_KEY, value: token);
      return true;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Clear the password this app used to persist.
  ///
  /// Existing installs still have it in secure storage from before the change
  /// above; upgrading must not silently leave it there forever.
  Future<void> purgeStoredPassword() async {
    try {
      await storage.delete(key: "pass");
    } catch (_) {
      /* nothing to remove */
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
      // The backend stores one user_fullName column; the app edits first/last
      // separately. This used to send ONLY userFname — so saving your profile
      // truncated "Sumit Malhotra" to "Sumit" — and never sent user_state at
      // all, which is why State reverted to empty after every save.
      final fullName = [request.userFname.trim(), request.userLname.trim()]
          .where((part) => part.isNotEmpty)
          .join(' ');
      final formData = FormData();
      formData.fields
        ..add(MapEntry('user_fullName', fullName))
        ..add(MapEntry('user_pnumber', request.userPnumber))
        ..add(MapEntry('user_address', request.userAddress))
        ..add(MapEntry('user_city', request.userCity))
        ..add(MapEntry('user_state', request.userState))
        ..add(MapEntry('user_zipcode', request.userZipcode));
      // One-time email code authorising a phone change. Only attached when
      // the screen collected one — an unchanged phone saves without it.
      if (request.otp != null && request.otp!.isNotEmpty) {
        formData.fields.add(MapEntry('otp', request.otp!));
      }
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

  /// Ask the server to email the account's registered address a one-time
  /// code authorising a sensitive change. `intent` is 'phone' or 'password'
  /// (POST /user/security/otp). The change endpoints then require the code:
  /// /user/update rejects a CHANGED phone without it, and
  /// /user/update-password takes it alongside the current password.
  Future<({bool success, String message})> requestSecurityOtp(
      String intent) async {
    try {
      final token = _token ?? await storage.read(key: TOKEN_KEY);
      final response = await _dio.post(
        '/user/security/otp',
        data: {'intent': intent},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = response.data;
      final success = data is Map && data['success'] == true;
      final message = (data is Map ? data['message'] : null)?.toString() ??
          (success
              ? 'We emailed you a verification code.'
              : 'Could not send the verification code.');
      return (success: success, message: message);
    } on DioException catch (err) {
      final data = err.response?.data;
      final message = (data is Map ? data['message'] : null)?.toString() ??
          err.message ??
          'Could not send the verification code.';
      return (success: false, message: message);
    } catch (e) {
      return (success: false, message: e.toString());
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
          // 30s tolerates a Render free-tier cold start (the first request
          // after the service idles can take 20-40s); warm requests are ~1s.
          .timeout(const Duration(seconds: 30));
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
