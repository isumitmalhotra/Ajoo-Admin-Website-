import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rent_home/ui/screens_renter/dashboard/dashboard_screen.dart';
import 'package:rent_home/ui/screens_common/about/about_page.dart';
import 'package:rent_home/ui/screens_renter/safety/safety_page.dart';
import 'package:rent_home/widgets/social_row.dart';

import '../../../screens_common/auth/auth_controller.dart';

class CustomDrawer extends StatelessWidget {
  final AuthController authController = Get.find<AuthController>();

  CustomDrawer({super.key});

  void showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await authController.logout();
                  Get.offAllNamed('/login');
                } catch (e) {
                  Get.snackbar('Error', 'Failed to logout: $e');
                }
                // logout logic here
              },
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double safeAreaVerticalPadding = MediaQuery.of(context).padding.top +
        MediaQuery.of(context).padding.bottom;
    return Drawer(
      child: Obx(() {
        // Resolve user fields reactively so the avatar + name update when
        // userData lands after login. All fields are null-safe — the drawer
        // also has to render in the dev-skip flow where userData is null.
        final user = authController.userData.value;
        final name = (user?.fullName ?? '').trim();
        final displayName = name.isEmpty ? 'User' : name;
        final initial =
            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
        final attachmentRaw = user?.attachment;
        final hasImage =
            attachmentRaw is String && attachmentRaw.isNotEmpty;

        return Column(
          children: <Widget>[
            // Custom profile header
            Container(
              color: Theme.of(context).primaryColor,
              padding: EdgeInsets.fromLTRB(
                  16, safeAreaVerticalPadding + 16, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile picture (image if attachment is a valid URL, else
                  // first-letter fallback — also covers the null-user case).
                  Hero(
                    tag: 'profile_picture',
                    child: CircleAvatar(
                      radius: 30,
                      backgroundImage:
                          hasImage ? NetworkImage(attachmentRaw) : null,
                      backgroundColor: Colors.white,
                      child: hasImage
                          ? null
                          : Text(
                              initial,
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // User details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

              // Drawer items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(Icons.dashboard_outlined),
                      title: const Text('Dashboard'),
                      onTap: () {
                        Navigator.of(context).pop();
                        Get.to(() => const RenterDashboardScreen());
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.person_outline,
                      ),
                      title: const Text('Profile'),
                      onTap: () => Get.toNamed('/profile'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.history),
                      title: const Text('History'),
                      onTap: () => Get.toNamed('/history'),
                    ),
                    ListTile(
                        leading: const Icon(Iconsax.bookmark4),
                        title: const Text('Bookmarks'),
                        onTap: () => Get.toNamed('/bookmarkProperties')),
                    ListTile(
                      leading: const Icon(Icons.security),
                      title: const Text('Safety'),
                      onTap: () => Get.to(() => const SafetyPage()),
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings),
                      title: const Text('Settings'),
                      onTap: () => Get.toNamed('/settings'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: const Text('Help & Support'),
                      onTap: () => Get.toNamed('/support'),
                    ),
                    // ListTile(
                    //   leading: const Icon(Icons.brightness_6),
                    //   title: const Text('Theme'),
                    //   onTap: () {},
                    // ),

                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('About'),
                      onTap: () => Get.to(() => const AboutPage()),
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('Logout'),
                      textColor: Colors.red,
                      iconColor: Colors.red,
                      onTap: () => {showLogoutDialog(context)},
                    ),
                    // ListTile(
                    //   leading: const Icon(Iconsax.building4),
                    //   title: const Text('DEMO Checkout'),
                    //   textColor: Colors.green,
                    //   iconColor: Colors.green,
                    //   onTap: () {
                    //     Get.to(() => const HotelCheckoutPage());
                    //   },
                    // ),
                  ],
                ),
              ),

              // // Host/User switch button
              // if (authController.userData.value != null) ...[
              //   Padding(
              //     padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 25),
              //     child: OptionButton(
              //       onOptionSelected: (option) {
              //         // Handle switching between host and user
              //         print('Selected option: $option');
              //       },
              //     ),
              //   ),
              // ],

              // Social media icons
              const SocialRow(),
              const SizedBox(height: 16),
            ],
          );
        }),
    );
  }
}
