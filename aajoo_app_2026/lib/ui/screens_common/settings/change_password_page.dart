import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/controller/user_controller.dart';
import 'package:rent_home/ui/screens_common/auth/auth_controller.dart';
import 'package:rent_home/ui/widgets/email_otp_sheet.dart';
import 'package:rent_home/ui/widgets/password_rules_checklist.dart';
import 'package:rent_home/utils/fonts.dart';

/// Change-password screen for a logged-in user (renter or host).
///
/// Backed by `POST /user/update-password` (JWT-auth) which requires the
/// current password + new password + confirmation + a one-time email code
/// (the current password proves the actor knows the secret, the code proves
/// they hold the mailbox — both, not either). This is distinct from the
/// forgot-password flow (that one is for logged-out users).
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  // True while the send-code request is in flight, before the OTP sheet
  // opens — keeps the button from firing a second email.
  bool _sendingOtp = false;

  final UserController _userController = Get.isRegistered<UserController>()
      ? Get.find<UserController>()
      : Get.put(UserController());
  final AuthController _authController = Get.find<AuthController>();

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = _authController.userData.value;
    final userId = user?.userId;
    if (userId == null) {
      Get.snackbar('Error', 'You must be logged in to change your password',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[900]);
      return;
    }

    // Sensitive change: email a one-time code first and only submit with it.
    // Someone holding an unlocked phone knows neither the password nor the
    // mailbox — this demands both.
    setState(() => _sendingOtp = true);
    final sent =
        await _authController.authService.requestSecurityOtp('password');
    if (!mounted) return;
    setState(() => _sendingOtp = false);
    if (!sent.success) {
      Get.snackbar('Error', sent.message,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[900]);
      return;
    }

    final otp = await showEmailOtpSheet(
      email: user?.email ?? 'your registered email',
      title: 'Confirm password change',
      resend: () => _authController.authService.requestSecurityOtp('password'),
    );
    // Backing out of the code sheet abandons the change entirely.
    if (otp == null || !mounted) return;

    final ok = await _userController.changePassword(
      userId: userId,
      currentPassword: _currentController.text,
      newPassword: _newController.text,
      confirmPassword: _confirmController.text,
      otp: otp,
    );

    if (ok && mounted) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kscaffoldColor,
      appBar: AppBar(
        title: Text('Change Password',
            style: fraunces(
                fontSize: 20, fontWeight: FontWeight.w700, color: kInk)),
        backgroundColor: kSand,
        foregroundColor: kInk,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update your password',
                style: fraunces(
                    fontSize: 22, fontWeight: FontWeight.w500, color: kInk),
              ),
              const SizedBox(height: 6),
              Text(
                'Enter your current password and choose a new one. '
                "We'll email you a code to confirm it's really you.",
                style: inter(fontSize: 13, color: kMuted),
              ),
              const SizedBox(height: 24),
              _passwordField(
                label: 'Current Password',
                controller: _currentController,
                obscure: _obscureCurrent,
                onToggle: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Enter your current password'
                    : null,
              ),
              const SizedBox(height: 16),
              _passwordField(
                label: 'New Password',
                controller: _newController,
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
                // Same checks the live checklist below shows — both mirror
                // the backend's updatePassword schema.
                validator: validateAgainstPasswordRules,
              ),
              const SizedBox(height: 12),
              // Live checklist: each rule ticks off as it's satisfied, so the
              // user knows what the input expects before pressing Save.
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _newController,
                builder: (context, value, _) =>
                    PasswordRulesChecklist(password: value.text),
              ),
              const SizedBox(height: 16),
              _passwordField(
                label: 'Confirm New Password',
                controller: _confirmController,
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (v) =>
                    v != _newController.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: Obx(
                  () => ElevatedButton(
                    onPressed: (_userController.isLoading.value || _sendingOtp)
                        ? null
                        : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kClay,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: kMuted,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _userController.isLoading.value
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text('Update Password',
                            style: inter(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: inter(fontSize: 15, color: kInk),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: inter(fontSize: 14, color: kMuted),
        filled: true,
        fillColor: kCream,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kIndigo, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kDanger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kDanger, width: 1.5),
        ),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
              color: kMuted, size: 20),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
