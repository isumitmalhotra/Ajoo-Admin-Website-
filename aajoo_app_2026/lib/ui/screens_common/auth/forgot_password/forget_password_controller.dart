import 'package:get/get.dart';
import 'package:rent_home/controller/alert_dialog.dart';
import 'package:rent_home/service/forgot_password_service.dart';
import 'dart:async';

class ForgetPasswordController extends GetxController {
  final email = ''.obs;
  final otp = ''.obs;
  final password = ''.obs;
  final cPassword = ''.obs;
  final isLoading = false.obs;
  final resendCountdown = 30.obs; // Countdown timer for resend OTP
  Timer? _resendTimer;
  final _forgetPasswordService = ForgotPasswordService();

  @override
  void onInit() {
    super.onInit();
    startResendTimer(); // Start timer when controller is initialized
  }

  @override
  void onClose() {
    _resendTimer?.cancel(); // Clean up timer
    super.onClose();
  }

  void startResendTimer() {
    resendCountdown.value = 30; // Reset countdown
    _resendTimer?.cancel(); // Cancel any existing timer
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendCountdown.value > 0) {
        resendCountdown.value--;
      } else {
        timer.cancel(); // Stop timer when countdown reaches 0
      }
    });
  }

  Future<bool> sendOtp() async {
    isLoading.value = true;
    try {
      // A-11: accept a mobile number as well as an email. The field takes
      // whichever the person actually signed up with, rather than making them
      // remember which one it was.
      final isMobile = ForgotPasswordService.looksLikeMobile(email.value);
      final bool response;
      String? failure;
      if (isMobile) {
        final r = await _forgetPasswordService.sendOtpToMobile(email.value);
        response = r.ok;
        failure = r.message;
      } else {
        // Email path surfaces the server's reason now too — failures used to
        // collapse into a bare false that all looked identical to the user.
        final r = await _forgetPasswordService.sendOtpToEmail(email.value);
        response = r.ok;
        failure = r.message;
      }
      if (response) {
        showAlert('Code sent',
            isMobile
                ? 'We sent a code by SMS to ${email.value}'
                : 'If that email is registered, a code is on its way to it',
            false);
        startResendTimer(); // Restart timer after sending OTP
        return true;
      } else {
        // Show the server's own reason — including "SMS isn't available yet" —
        // rather than a flat "Failed to send OTP" that says nothing about what
        // to do next.
        showAlert('Error', failure ?? 'Failed to send OTP', true);
        if (resendCountdown.value > 0) {
          // Get.snackbar(
          //     'Info', 'You can resend OTP in ${resendCountdown.value} seconds',
          //     backgroundColor: Colors.yellow);
          return false;
        } else {
          startResendTimer(); // Restart timer if sending failed and countdown expired
          return false;
        }
      }
    } catch (e) {
      showAlert('Error', 'Something went wrong while sending OTP', true);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> verifyOtp() async {
    isLoading.value = true;
    try {
      final response =
          await _forgetPasswordService.verifyOtp(email.value, otp.value);
      if (response.ok) {
        showAlert('Success', 'OTP verified', false);
        return true;
      } else {
        showAlert('Error', response.message ?? 'Failed to verify OTP', true);
        return false;
      }
    } catch (e) {
      showAlert(
          'Error', 'An unexpected error occurred while verifying OTP', true);
      return false;
    } finally {
      // Always reset loading so the next page isn't stuck disabled
      isLoading.value = false;
    }
  }

  Future<bool> updatePassword() async {
    isLoading.value = true;
    try {
      final response = await _forgetPasswordService.updatePassword(
          password.value, cPassword.value, email.value);
      if (response.ok) {
        showAlert('Success', 'Password updated, Please login with new password',
            false);
        return true;
      } else {
        // The server's own reason — a policy rejection names the rule broken.
        showAlert(
            'Error', response.message ?? 'Failed to update password', true);
        return false;
      }
    } catch (e) {
      showAlert('Error', 'An unexpected error occurred while updating password',
          true);
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
