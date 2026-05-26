// verify_controller.dart
import 'package:get/get.dart';
import 'package:rent_home/controller/alert_dialog.dart';

import '../../../../service/auth_service.dart';
import '../auth_controller.dart';

class VerifyController extends GetxController {
  final AuthService authService = AuthService();
  final AuthController authController = Get.find<AuthController>();

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxString otp = ''.obs;
  final RxBool isResending = false.obs;

  int? userId;

  @override
  void onInit() {
    super.onInit();
    userId = Get.arguments['userId'];
  }

  Future<void> verifyOtp() async {
    if (otp.value.length != 4) {
      showAlert(
        'Error',
        'Please enter a valid 4-digit OTP',
        true,
      );
      return;
    }

    try {
      isLoading.value = true;
      error.value = '';

      final response = await authService.verifyOtp(
        userId: userId!,
        otp: otp.value,
      );

      if (response.success) {
        // Store token and user data
        await authService.storage.write(
          key: authService.TOKEN_KEY,
          value: response.data.token,
        );

        await authService.storage.write(
          key: authService.USER_DATA_KEY,
          value: response.data.user.toJson().toString(),
        );

        authController.isLoggedIn.value = true;
        authController.userData.value = response.data.user;

        showAlert('Success', 'Verification successful', false);

        // Navigate based on user type
        if (response.data.user.isHost) {
          Get.offAllNamed('/host/home');
        } else {
          Get.offAllNamed('/home');
        }
      } else {
        error.value = response.message;
        showAlert('Error', response.message, true);
      }
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      error.value = message;
      showAlert('Error', message, true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendOtp() async {
    if (userId == null) {
      showAlert(
        'Error',
        'User ID not found',
        true,
      );
      return;
    }

    try {
      isResending.value = true;
      final response = await authService.resendOtp(userId: userId!);

      if (response.success) {
        showAlert(
          'Success',
          'OTP has been resent to your email',
          false,
        );
      } else {
        showAlert(
          'Error',
          response.message,
          true,
        );
      }
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      showAlert(
        'Error',
        'Failed to resend OTP: $message',
        true,
      );
    } finally {
      isResending.value = false;
    }
  }
}
