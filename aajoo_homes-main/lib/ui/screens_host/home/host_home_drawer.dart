import 'package:flutter/material.dart';
import 'package:rent_home/ui/screens_common/auth/auth_controller.dart';
import 'package:rent_home/ui/screens_host/add_property/host_property_listing_screen.dart';
import 'package:rent_home/ui/screens_host/host_tab_provider.dart';
import 'package:rent_home/ui/unused_screens/chat/chat_page.dart';
import 'package:rent_home/ui/screens_common/privacy_policy/privacy-policy_page.dart';
import 'package:rent_home/ui/screens_host/booking_history/booking_history_screen.dart';
import 'package:rent_home/ui/screens_host/payout/payout_page.dart';
import 'package:rent_home/ui/screens_host/support/host_support_screen.dart';
import 'package:ionicons/ionicons.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';

class HostHomeDrawer extends StatelessWidget {
  const HostHomeDrawer({
    super.key,
    required this.authController,
    required this.hostTabProvider,
  });

  final AuthController authController;
  final HostTabProvider hostTabProvider;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: kPrimaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Text("Welcome,",
                    style: TextStyle(color: Colors.white, fontSize: 20)),
                Text(authController.userData.value!.fullName,
                    style: const TextStyle(color: Colors.white, fontSize: 28)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Ionicons.person_outline),
            title: const Text("Profile"),
            onTap: () {
              hostTabProvider.setTab(5);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Iconsax.home),
            title: const Text("Home"),
            onTap: () {
              hostTabProvider.setTab(2);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_home_outlined),
            title: const Text("Add Property"),
            onTap: () {
              Navigator.pop(context);
              hostTabProvider.resetToHome();
              Get.to(() => const HostPropertyListingScreen());
            },
          ),
          ListTile(
            leading: const Icon(Ionicons.list),
            title: const Text("Booking History"),
            onTap: () {
              Navigator.pop(context);
              hostTabProvider.resetToHome();
              Get.to(() => const BookingHistoryScreen());
            },
          ),
          ListTile(
              leading: const Icon(Iconsax.document4),
              title: const Text("Invoices"),
              onTap: () {
                hostTabProvider.setTab(7);
                Navigator.pop(context);
              }),
          ListTile(
            leading: const Icon(Iconsax.money_recive4),
            title: const Text("Payout"),
            onTap: () {
              Navigator.pop(context);
              hostTabProvider.resetToHome();
              Get.to(() => const PayoutPage());
            },
          ),
          ListTile(
            leading: const Icon(Iconsax.shield),
            title: const Text("Privacy Policy"),
            onTap: () {
              Navigator.pop(context);
              hostTabProvider.resetToHome();
              Get.to(() => const PrivacyPolicyPage());
            },
          ),
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: const Text("Host Support"),
            onTap: () {
              Navigator.pop(context);
              Get.to(() => const HostSupportScreen());
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () => Get.toNamed('/settings'),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                // color: kprimaryColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                // tileColor: kprimaryColor.withOpacity(0.3),
                leading: const Icon(Iconsax.logout),
                title: const Text("Logout"),
                onTap: () {
                  authController.logout();
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
