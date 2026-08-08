import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
      final response = await _forgetPasswordService.sendOtpToEmail(email.value);
      if (response) {
        Get.snackbar('Success', 'OTP sent to ${email.value}',
            backgroundColor: Colors.green);
        startResendTimer(); // Restart timer after sending OTP
        return true;
      } else {
        Get.snackbar('Error', 'Failed to send OTP',
            backgroundColor: Colors.red);
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
      Get.snackbar('Error', 'Something went wrong while sending OTP',
          backgroundColor: Colors.red, colorText: Colors.white);
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
      if (response) {
        Get.snackbar('Success', 'OTP verified', backgroundColor: Colors.green);
        return true;
      } else {
        Get.snackbar('Error', 'Failed to verify OTP',
            backgroundColor: Colors.red, colorText: Colors.white);
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred while verifying OTP',
          backgroundColor: Colors.red, colorText: Colors.white);
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
      if (response) {
        Get.snackbar(
            'Success', 'Password updated, Please login with new password',
            backgroundColor: Colors.green);
        return true;
      } else {
        Get.snackbar('Error', 'Failed to update password',
            backgroundColor: Colors.red, colorText: Colors.white);
        return false;
      }
    } catch (e) {
      Get.snackbar(
          'Error', 'An unexpected error occurred while updating password',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
