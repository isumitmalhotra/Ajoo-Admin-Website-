import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rent_home/screens/about_page.dart';
import 'package:rent_home/screens/safety_page.dart';
import 'package:rent_home/widgets/bookmark_properties_page.dart';
import 'package:rent_home/widgets/social_row.dart';

import '../controller/auth_controller.dart';

class CustomDrawer extends StatelessWidget {
  final AuthController authController = Get.find<AuthController>();

  CustomDrawer({super.key});

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

  @override
  Widget build(BuildContext context) {
    double safeAreaVerticalPadding = MediaQuery.of(context).padding.top +
        MediaQuery.of(context).padding.bottom;
    final user = authController.userData.value;
    return Drawer(
      child: Obx(() => Column(
            children: <Widget>[
              // Custom profile header
              Container(
                color: Theme.of(context).primaryColor,
                padding: EdgeInsets.fromLTRB(
                    16, safeAreaVerticalPadding + 16, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile picture (using first letter of name if no image)
                    Hero(
                      tag: 'profile_picture',
                      child: CircleAvatar(
                        radius: 30,
                        backgroundImage: user?.attachment is String &&
                                user?.attachment.isNotEmpty
                            ? NetworkImage(user?.attachment)
                            : null,
                        backgroundColor: Colors.white,
                        child: user?.attachment is! String ||
                                user?.attachment.isEmpty
                            ? Text(
                                user!.fullName[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // User details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authController.userData.value?.fullName ?? 'User',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            authController.userData.value?.email ?? '',
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
                      onTap: () =>
                          Get.to(() => const BookmarkedPropertiesPage()),
                    ),
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
                      onTap: _handleLogout,
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
          )),
    );
  }
}
