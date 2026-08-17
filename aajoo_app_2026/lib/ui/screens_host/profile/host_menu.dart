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
import 'package:rent_home/ui/screens_host/calendar/host_calendar_screen.dart';
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
      icon: Ionicons.calendar_outline,
      label: 'Calendar',
      subtitle: 'Bookings and blocked dates',
      onTap: () => go(() => const HostCalendarScreen()),
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
    // The host menu ended at Logout, so the only way back to the guest side of
    // the app was to sign out and sign in again. AuthController.switchMode and
    // /user/switch-mode already exist and the guest side already offers the
    // reverse — this was simply never wired up here.
    HostMenuEntry(
      icon: Iconsax.repeat,
      label: 'Switch to guest',
      subtitle: 'Browse and book stays',
      onTap: () {
        beforeNavigate?.call();
        if (Get.isRegistered<AuthController>()) {
          Get.find<AuthController>().switchMode(false);
        }
      },
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

/// Open the host menu from the profile header (A-79).
///
/// Two earlier attempts did not work on device, and both are worth recording
/// so nobody re-tries them:
///
///  1. A Scaffold `endDrawer` on the profile page. The page is a child of the
///     shell's IndexedStack, so its Scaffold is nested inside MainScreen's —
///     and a nested Scaffold never gets a drawer surface. The button was
///     inert.
///  2. A showGeneralDialog panel wrapping [Drawer]. A Drawer outside a
///     Scaffold has no drawer scope to attach to and rendered nothing.
///
/// A modal sheet needs no Scaffold ancestor and no drawer scope, so it works
/// wherever the page is mounted. The button stays where the client asked for
/// it — top-right of the profile.
Future<void> showHostMenu(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: kCream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (sheetContext) => SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
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
                    onPressed: () => Navigator.of(sheetContext).pop(),
                  ),
                ],
              ),
            ),
            const Divider(color: kLine, height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                children: [
                  // Close before navigating: popping after the push races the
                  // navigation, which is what made the old host drawer's
                  // Logout unreliable.
                  HostMenuList(
                      beforeNavigate: () => Navigator.of(sheetContext).pop()),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
