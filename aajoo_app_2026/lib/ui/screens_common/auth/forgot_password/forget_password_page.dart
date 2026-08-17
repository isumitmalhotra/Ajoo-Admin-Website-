import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rent_home/utils/input_sanitizers.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/ui/screens_common/auth/forgot_password/forget_password_controller.dart';

/// ForgetPasswordPage is a multi-step process using PageView:
/// 1️⃣ Send OTP to Email
/// 2️⃣ Verify OTP
/// 3️⃣ Change Password
class ForgetPasswordPage extends StatefulWidget {
  const ForgetPasswordPage({super.key});

  @override
  State<ForgetPasswordPage> createState() => _ForgetPasswordPageState();
}

class _ForgetPasswordPageState extends State<ForgetPasswordPage> {
  final ForgetPasswordController controller =
      Get.put(ForgetPasswordController());
  late final PageController _pageController;
  final FocusNode _otpFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _otpFocusNode.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kprimaryColor,
        foregroundColor: kcontentColor,
        centerTitle: true,
        title: const Text('Forget Password'),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Prevent manual swiping
        onPageChanged: (index) {
          if (index == 1) {
            // Move focus to OTP field when entering Verify OTP page
            _otpFocusNode.requestFocus();
          } else {
            // Unfocus on other pages to avoid typing into hidden fields
            FocusScope.of(context).unfocus();
          }
        },
        children: [
          _sendEmailSection(),
          _verifyOtpSection(),
          _changePasswordSection(),
        ],
      ),
    );
  }

  /// Step 1: Send Email
  Widget _sendEmailSection() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            const Text(
              'Forgot Password?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Enter your email below. We will send an OTP to reset your password.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextFormField(
              onChanged: (value) => controller.email.value = value,
              keyboardType: TextInputType.emailAddress,
              inputFormatters: AppInputFormatters.email,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return 'Please enter your email';
                if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(t)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
              decoration: InputDecoration(
                labelText: 'Email Address',
                prefixIcon: const Icon(Icons.email),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null // Disable button during loading
                        : () async {
                            if (controller.email.value.isEmpty) {
                              Get.snackbar(
                                  'Error', 'Please enter an email address');
                              return;
                            }
                            final success = await controller.sendOtp();
                            if (success) {
                              // Ensure previous inputs are unfocused before navigating
                              FocusScope.of(context).unfocus();
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeIn,
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kprimaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: controller.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Send OTP',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  /// Step 2: Verify OTP
  Widget _verifyOtpSection() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            const Text(
              'Verify OTP',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Enter the OTP sent to your email.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Image.asset(
              'assets/otp.jpg',
              height: 200,
              width: double.infinity,
              fit: BoxFit.fitHeight,
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: PinCodeTextField(
                focusNode: _otpFocusNode,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.circle,
                  borderRadius: BorderRadius.circular(40),
                  fieldHeight: 50,
                  fieldWidth: 50,
                ),
                // Six digits — see the note in auth/verify/verify_page.dart.
                length: 6,
                appContext: context,
                autoFocus: true,
                onChanged: (value) => controller.otp.value = value,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(height: 20),
            Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null // Disable button during loading
                        : () async {
                            if (controller.otp.value.length != 6) {
                              Get.snackbar(
                                  'Error', 'Please enter the 6-digit code we emailed you.');
                              return;
                            }
                            final isVerified = await controller.verifyOtp();
                            if (isVerified) {
                              FocusScope.of(context).unfocus();
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeIn,
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kprimaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: controller.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Verify OTP',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                  ),
                )),
            const SizedBox(height: 10),
            Obx(() => SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: controller.isLoading.value ||
                            controller.resendCountdown.value > 0
                        ? null // Disable button during loading or countdown
                        : () async {
                            final success = await controller.sendOtp();
                            if (success) {
                              controller.startResendTimer();
                              _otpFocusNode.requestFocus();
                            }
                          },
                    child: Text(
                      controller.resendCountdown.value > 0
                          ? 'Resend OTP in ${controller.resendCountdown.value}s'
                          : 'Resend OTP',
                      style: TextStyle(
                        fontSize: 16,
                        color: controller.resendCountdown.value > 0
                            ? Colors.grey
                            : kprimaryColor,
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  /// Step 3: Change Password
  Widget _changePasswordSection() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/password.png',
              height: 200,
              width: double.infinity,
              fit: BoxFit.fitHeight,
            ),
            const Text(
              'Reset Password',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Enter your new password below.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextFormField(
              onChanged: (value) => controller.password.value = value,
              obscureText: true,
              inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
              autovalidateMode: AutovalidateMode.onUserInteraction,
              // Same rule as change_password_page — a reset must not be able
              // to set a password the rest of the app would refuse.
              validator: (v) {
                final t = v ?? '';
                if (t.isEmpty) return 'Please enter a new password';
                if (t.length < 8) return 'At least 8 characters';
                if (!t.contains(RegExp(r'[A-Z]'))) return 'Add an uppercase letter';
                if (!t.contains(RegExp(r'[a-z]'))) return 'Add a lowercase letter';
                if (!t.contains(RegExp(r'\d'))) return 'Add a number';
                return null;
              },
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(Icons.lock),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              onChanged: (value) => controller.cPassword.value = value,
              obscureText: true,
              inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (v) =>
                  (v ?? '') == controller.password.value ? null : 'Passwords do not match',
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null // Disable button during loading
                        : () async {
                            final password = controller.password.value;
                            final cpassword = controller.cPassword.value;
                            if (password.isEmpty || cpassword.isEmpty) {
                              Get.snackbar('Error',
                                  'Please fill in both password fields');
                              return;
                            }
                            if (password != cpassword) {
                              Get.snackbar('Error', 'Passwords do not match');
                              return;
                            }
                            final isUpdated = await controller.updatePassword();
                            if (isUpdated) {
                              Get.offAllNamed(
                                  '/login'); // Navigate to login page
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kprimaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: controller.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Update Password',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
