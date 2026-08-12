import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:ionicons/ionicons.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/ui/screens_common/auth/auth_controller.dart';
import 'package:rent_home/ui/screens_common/privacy_policy/privacy-policy_page.dart';
import 'package:rent_home/ui/screens_common/terms_and_conditions/terms_condition_user_page.dart';
import 'package:rent_home/ui/screens_host/add_property/host_property_listing_screen.dart';
import 'package:rent_home/ui/screens_host/booking_history/booking_history_screen.dart';
import 'package:rent_home/ui/screens_host/negotiations/host_negotiations_screen.dart';
import 'package:rent_home/ui/screens_host/payout/add_payout_account_page.dart';
import 'package:rent_home/ui/screens_host/payout/payout_page.dart';
import 'package:rent_home/ui/screens_host/support/host_support_screen.dart';
import 'package:rent_home/utils/fonts.dart';

/// Every page a host can reach, declared once (A-78).
///
/// The home drawer and the profile page both need this list. Two hand-written
/// copies is how the guest side ended up with a drawer and a profile that
/// disagreed about which pages existed — the drawer had Safety and About, the
/// profile did not, and the drawer opened only by tapping an unlabelled logo.
/// One list, both surfaces.
class HostMenuEntry {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool danger;

  const HostMenuEntry({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.danger = false,
  });
}

List<HostMenuEntry> hostMenuEntries({VoidCallback? beforeNavigate}) {
  void go(Widget Function() page) {
    beforeNavigate?.call();
    Get.to(page);
  }

  return [
    HostMenuEntry(
      icon: Icons.add_home_outlined,
      label: 'Add Property',
      subtitle: 'List a new stay',
      onTap: () => go(() => const HostPropertyListingScreen()),
    ),
    HostMenuEntry(
      icon: Ionicons.list,
      label: 'Bookings',
      subtitle: 'Upcoming, ongoing and past stays',
      onTap: () => go(() => const BookingHistoryScreen()),
    ),
    HostMenuEntry(
      icon: Icons.handshake_outlined,
      label: 'Negotiations',
      subtitle: 'Offers from guests',
      onTap: () => go(() => const HostNegotiationsScreen()),
    ),
    HostMenuEntry(
      icon: Iconsax.money_recive4,
      label: 'Payouts',
      subtitle: 'What you have earned and been paid',
      onTap: () => go(() => const PayoutPage()),
    ),
    HostMenuEntry(
      icon: Iconsax.bank,
      label: 'Bank Account',
      subtitle: 'Where your payouts land',
      onTap: () => go(() => const AddPayoutAccountPage()),
    ),
    HostMenuEntry(
      icon: Icons.support_agent,
      label: 'Messages',
      subtitle: 'Aajoo support and your guests',
      onTap: () => go(() => const HostSupportScreen()),
    ),
    HostMenuEntry(
      icon: Icons.settings,
      label: 'Settings',
      subtitle: 'Account preferences',
      onTap: () {
        beforeNavigate?.call();
        Get.toNamed('/settings');
      },
    ),
    HostMenuEntry(
      icon: Iconsax.document_text,
      label: 'Host Terms & Conditions',
      onTap: () => go(() => const TermsPage(isHost: true)),
    ),
    HostMenuEntry(
      icon: Iconsax.shield,
      label: 'Privacy Policy',
      onTap: () => go(() => const PrivacyPolicyPage()),
    ),
    HostMenuEntry(
      icon: Iconsax.logout,
      label: 'Logout',
      subtitle: 'Sign out of this device',
      danger: true,
      onTap: () {
        beforeNavigate?.call();
        if (Get.isRegistered<AuthController>()) {
          Get.find<AuthController>().logout();
        }
      },
    ),
  ];
}

/// The menu as rows on a page.
class HostMenuList extends StatelessWidget {
  final VoidCallback? beforeNavigate;
  const HostMenuList({super.key, this.beforeNavigate});

  @override
  Widget build(BuildContext context) {
    final entries = hostMenuEntries(beforeNavigate: beforeNavigate);
    return Column(
      children: [
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: kSurface,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: e.onTap,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kLine),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: e.danger
                              ? kDanger.withOpacity(0.08)
                              : kIndigo50,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(e.icon,
                            size: 19,
                            color: e.danger ? kDanger : kIndigo600),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.label,
                                style: inter(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: e.danger ? kDanger : kInk)),
                            if (e.subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(e.subtitle!,
                                  style:
                                      inter(fontSize: 12, color: kMuted)),
                            ],
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          size: 14, color: e.danger ? kDanger : kMuted),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The same menu as a right-hand drawer, opened from the profile header
/// (A-79).
class HostMenuDrawer extends StatelessWidget {
  const HostMenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: kCream,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 10),
              child: Row(
                children: [
                  Text('Menu',
                      style: fraunces(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: kInk)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: kInk2),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(color: kLine, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  // Close the drawer before navigating: popping after the push
                  // races the navigation, which is what made the old host
                  // drawer's Logout unreliable.
                  HostMenuList(
                      beforeNavigate: () => Navigator.of(context).pop()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
