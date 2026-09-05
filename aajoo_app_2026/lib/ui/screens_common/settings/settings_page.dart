import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/ui/screens_common/auth/auth_controller.dart';
import 'package:rent_home/ui/screens_common/faq/faq_page.dart';
import 'package:rent_home/ui/screens_common/about/about_page.dart';
import 'package:rent_home/ui/screens_common/privacy_policy/privacy-policy_page.dart';
import 'package:rent_home/ui/screens_common/terms_and_conditions/terms_condition_user_page.dart';
import 'package:rent_home/ui/screens_common/settings/change_password_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rent_home/ui/screens_common/cancellation_policy/cancellation_policy_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final authController = Get.find<AuthController>();

  /// Opens the store listing so the guest can leave a rating.
  ///
  /// The tile shipped with an empty `onTap` — every other row in Settings
  /// navigates somewhere, this one silently did nothing when tapped.
  ///
  /// Tries the Play Store app first (`market://`, which opens the listing
  /// directly in the installed store) and falls back to the https listing for
  /// devices without it. If neither opens — which is what happens on a device
  /// with no Play Store, and on any build before the listing is published —
  /// the guest is told rather than left tapping a dead row.
  Future<void> _handleRateApp() async {
    const pkg = 'com.aajoo.aajoohomes';
    final messenger = ScaffoldMessenger.maybeOf(context);
    for (final url in const [
      'market://details?id=$pkg',
      'https://play.google.com/store/apps/details?id=$pkg',
    ]) {
      try {
        if (await launchUrl(Uri.parse(url),
            mode: LaunchMode.externalApplication)) {
          return;
        }
      } catch (_) {
        // try the next form
      }
    }
    messenger?.showSnackBar(
      const SnackBar(content: Text("Couldn't open the store listing.")),
    );
  }

  void _handleLogout() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await authController.logout();
    }
  }

  void _handleDeleteAccount() async {
    // First confirmation dialog
    final firstConfirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Delete Account', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to delete your account?',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Text(
              'This action will permanently:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text('• Delete all your property listings'),
            const Text('• Remove your booking history'),
            const Text('• Delete your profile and personal data'),
            const Text('• Cancel any pending reservations'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone!',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (firstConfirm != true) return;

    // Second confirmation dialog with text input
    final TextEditingController confirmController = TextEditingController();
    final secondConfirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text(
          'Final Confirmation',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To confirm account deletion, please type "DELETE" below:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                hintText: 'Type DELETE here',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                ),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Colors.orange, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Your account will be deleted immediately',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          Obx(() => ElevatedButton(
                onPressed: authController.isLoading.value
                    ? null
                    : () {
                        if (confirmController.text.trim().toUpperCase() ==
                            'DELETE') {
                          Get.back(result: true);
                        } else {
                          Get.snackbar(
                            'Error',
                            'Please type "DELETE" to confirm',
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: authController.isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Delete Account'),
              )),
        ],
      ),
    );

    if (secondConfirm == true) {
      await authController.deleteAccount();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kcontentColor,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: kSand,
        foregroundColor: kInk,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SectionHeader(title: "Account"),
          SettingsTile(
            title: "Change Password",
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ChangePasswordPage()));
            },
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: "Application"),
          SettingsTile(
            title: "About Us",
            onTap: () {
              // Handle About Us action
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const AboutPage()));
            },
          ),
          SettingsTile(
            title: "Terms and Conditions",
            onTap: () {
              // Handle Terms and Conditions action
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const TermsPage()));
            },
          ),
          SettingsTile(
            title: "Privacy Policy",
            onTap: () {
              // Handle Privacy Policy action
              Navigator.push(
                  context,
                  CupertinoPageRoute(
                      builder: (context) => const PrivacyPolicyPage()));
            },
          ),
          SettingsTile(
            title: "Cancellation & Refund Policy",
            onTap: () => Navigator.push(
                context,
                CupertinoPageRoute(
                    builder: (context) => const CancellationPolicyPage())),
          ),
          SettingsTile(
            title: "FAQ",
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const FaqScren()));
            },
          ),
          SettingsTile(
            title: "Contact Us",
            onTap: () => Get.toNamed('/support'),
          ),
          SettingsTile(
            title: "Rate App",
            onTap: _handleRateApp,
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: "Version 1.0.0 (build 25)"),
          LogoutTile(
            onTap: _handleLogout,
          ),
          const SizedBox(height: 20),
          DeleteMyAccoutTile(
            onTap: _handleDeleteAccount,
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
        ),
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;

  const SettingsTile(
      {super.key, required this.title, this.trailing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
          color: kscaffoldColor,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 3),
            )
          ],
          borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
        tileColor: kscaffoldColor,
        title: Text(title),
        trailing: trailing ??
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

class SwitchTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: kprimaryColor,
      ),
    );
  }
}

class LogoutTile extends StatelessWidget {
  final VoidCallback onTap;

  const LogoutTile({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text(
        "Log Out",
        style: TextStyle(color: Colors.red),
      ),
      onTap: onTap,
    );
  }
}

class DeleteMyAccoutTile extends StatelessWidget {
  final VoidCallback onTap;

  const DeleteMyAccoutTile({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text(
        "Delete My Account",
        style: TextStyle(color: Colors.red),
      ),
      onTap: onTap,
    );
  }
}
