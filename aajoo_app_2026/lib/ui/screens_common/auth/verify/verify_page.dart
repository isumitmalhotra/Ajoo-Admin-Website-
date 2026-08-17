import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:iconsax/iconsax.dart';

import 'verify_controller.dart';

class VerifyPage extends StatelessWidget {
  final controller = Get.put(VerifyController());

  VerifyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: theme.primaryColor,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left_2, color: theme.primaryColor),
          onPressed: () => Get.offAndToNamed("/onboarding"),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Simple Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Iconsax.sms,
                    size: 40,
                    color: theme.primaryColor,
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                Text(
                  'Verify Your Email',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  'Enter the 6-digit code sent to',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 8),

                // Email — prefer the address passed for THIS verification
                // (signup / login-needs-verify) over any previously logged-in
                // user's email, which can be stale.
                Text(
                  (Get.arguments?['email'] as String?)?.isNotEmpty == true
                      ? Get.arguments!['email']
                      : (controller.authController.userData.value?.email ??
                          ''),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 48),

                // OTP Input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: PinCodeTextField(
                    appContext: context,
            // SIX digits. The server's generateOtp was deliberately raised from
            // four (9,000 possibilities is small enough to grind through when the
            // emailed code is the only thing guarding an account) and the app was
            // never updated — so the field took four digits, the validation
            // demanded exactly four, and the code in the email could not be
            // entered at all. Signup verification and password reset were both
            // impossible to complete.
                    length: 6,
                    obscureText: false,
                    animationType: AnimationType.fade,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(12),
                      fieldHeight: 56,
                      fieldWidth: 56,
                      activeFillColor: Colors.white,
                      inactiveFillColor: Colors.grey[50],
                      selectedFillColor: Colors.white,
                      activeColor: theme.primaryColor,
                      inactiveColor: Colors.grey[300]!,
                      selectedColor: theme.primaryColor,
                      borderWidth: 1.5,
                    ),
                    cursorColor: theme.primaryColor,
                    animationDuration: const Duration(milliseconds: 200),
                    enableActiveFill: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    // An OTP paste is only ever six digits.
                    beforeTextPaste: (text) =>
                        RegExp(r'^\d{6}$').hasMatch((text ?? '').trim()),
                    textStyle: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryColor,
                    ),
                    onChanged: (value) {
                      controller.otp.value = value;
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Error Message
                Obx(() => controller.error.value.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          controller.error.value,
                          style: TextStyle(
                            color: Colors.red[600],
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : const SizedBox.shrink()),

                const SizedBox(height: 32),

                // Verify Button
                Obx(() => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : controller.verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor:
                              theme.primaryColor.withOpacity(0.6),
                        ),
                        child: controller.isLoading.value
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                'Verify',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    )),

                const SizedBox(height: 24),

                // Resend Code
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive code? ",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    Obx(() => TextButton(
                          onPressed: controller.isResending.value
                              ? null
                              : controller.resendOtp,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: controller.isResending.value
                              ? SizedBox(
                                  height: 14,
                                  width: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      theme.primaryColor,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Resend',
                                  style: TextStyle(
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                        )),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
