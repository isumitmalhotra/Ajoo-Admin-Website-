import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import "package:http/http.dart" as http;
import '../data/source/remote/dio_config.dart';
import '../models/update_user_model.dart';
import '../models/user_models.dart';
import 'package:rent_home/utils/secure_store.dart';
import 'package:rent_home/data/ApiConstants.dart';
import 'package:rent_home/utils/upload_media_type.dart';
import '../utils/service_log.dart';
import 'package:rent_home/data/source/remote/utils/api_error_handler.dart';


import 'package:rent_home/utils/app_log.dart';
/// Does this /user/is-exist body say the address is taken?
///
/// Separate from the request so it can be tested against real payloads: the
/// whole defect was that the ANSWER was never read. The server used to reply
/// 400 for "yes, taken", the caller threw on any non-2xx before parsing, and
/// the signup screen showed a generic failure for the one case the check exists
/// to detect.
///
/// Returns null when the body says nothing either way, which the caller reports
/// as unavailable rather than guessing.
bool? emailIsTakenFrom(dynamic data) {
  if (data is! Map) return null;
  // What the server says now.
  final payload = data["data"];
  if (payload is Map && payload["exists"] is bool) {
    return payload["exists"] as bool;
  }
  // The older contract, still true, so either server satisfies this.
  final message = data["message"];
  if (message != null) return message.toString() == "User Already Exist";
  return null;
}

/// The address check could not be reached or could not be understood.
///
/// Distinct from a plain Exception so a caller can tell "we do not know" apart
/// from "that address is taken" -- refusing a signup because a pre-flight check
/// was unreachable is the wrong answer, and showing "Something went wrong" when
/// the address really is registered is the bug this separation fixes.
class EmailCheckUnavailable implements Exception {
  @override
  String toString() =>
      "We could not check that email just now. Please try again.";
}

class AuthService {
  final Dio _dio = Dio();
  final String baseUrl = Apiconstants.baseUrl;
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
      appLog('Error decoding saved user data: $e');
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
    } catch (e) {
      logServiceError('auth_service:100', e);
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
      appLog("isHost: $isHost");
      appLog(redact(response.data), tag: 'auth');

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
      appLog('${isHost}isHost');
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
          contentType: mediaTypeForPath(idDoc.path),
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
      appLog(redact(response.data), tag: 'auth');
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
            contentType: mediaTypeForPath(request.idDoc!.path),
          ),
        ));
      }
      _dio.options.headers["Authorization"] = "Bearer $token";
      final response = await _dio.post('/user/update', data: formData);
      appLog(redact(response.data), tag: 'auth');
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
          contentType: mediaTypeForPath(userIdDoc.path),
        ),
      });

      final response = await _dio.post('/user/update', data: formData);
      appLog(redact(response.data), tag: 'auth.document');
      return BaseResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Is this address already registered for the account being created?
  ///
  /// The server used to answer 400 for "yes, it is taken", and the guard below
  /// threw on any non-2xx BEFORE the body was read -- so the one answer this
  /// call exists to obtain arrived as `Exception('Email check unavailable')`,
  /// and the signup screen showed a generic failure instead of telling the
  /// person their email was already registered. The server now answers 200 for
  /// both outcomes; reading the body rather than the status code is what makes
  /// that hold, and keeps working against either server.
  ///
  /// [isHost] is the role being signed up for. The same address may hold one
  /// guest account and one host account -- login resolves an account by email
  /// AND role -- so asking without the role refused host signups the server
  /// would have accepted.
  Future<bool> userAlreadyExist(String email, {bool? isHost}) async {
    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse("$baseUrl/user/is-exist"),
            body: {
              "userEmail": email,
              if (isHost != null) "isHost": isHost.toString(),
            },
          )
          // 30s tolerates a Render free-tier cold start (the first request
          // after the service idles can take 20-40s); warm requests are ~1s.
          .timeout(const Duration(seconds: 30));
    } catch (err) {
      // Only a genuine transport failure reaches here now. The caller must be
      // able to tell this apart from "the address is taken", because blocking
      // a signup over an unreachable check is the wrong answer.
      appLog(err);
      throw EmailCheckUnavailable();
    }

    try {
      // The BODY is the answer, whatever the status code was.
      final taken = emailIsTakenFrom(jsonDecode(response.body));
      if (taken != null) return taken;
    } catch (err) {
      appLog(err);
    }
    throw EmailCheckUnavailable();
  }

  Future<bool> isUserAlreadyExist(String email, {bool? isHost}) async {
    return userAlreadyExist(email, isHost: isHost);
  }

  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final response = await _dio.post('/user/delete');
      appLog(redact(response.data), tag: 'auth.delete');
      return response.data;
    } catch (e) {
      appLog('Error deleting account: $e');
      throw Exception('Failed to delete account: $e');
    }
  }

  Exception _handleError(dynamic error) {
    // Don't automatically redirect on every error - let the calling code handle it
    // get_package.Get.offAll(() => const AuthPage());
    if (error is DioException) {
      final response = error.response?.data;
      appLog('API error: ${redact(response)}', tag: 'auth');
      // NOT error.message: for a transport failure that is Dio's own
      // diagnostic string, and wrapping it in an Exception here defeats the
      // friendly mapping in handleApiError — the caller receives a plain
      // Exception, not a DioException, so the mapper never runs. This is how
      // "The connection errored: No route to host This indicates an error
      // which most likely cannot be solved by the library." reached a login
      // screen. Our API's own message still wins when there is one.
      final message = response?['message'] ?? friendlyTransportMessage(error);
      appLog('Error during API call: $message');
      // Get.snackbar('Error', message, snackPosition: SnackPosition.TOP
      return Exception(message);
    }
    return Exception(error.toString());
  }
}
