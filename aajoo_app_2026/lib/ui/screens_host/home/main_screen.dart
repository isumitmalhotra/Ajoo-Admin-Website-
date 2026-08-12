import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:rent_home/ui/screens_host/host_tab_provider.dart';
import 'package:rent_home/ui/screens_host/host_controller.dart';
import 'package:rent_home/ui/screens_host/home/host_home_drawer.dart';
import 'package:rent_home/ui/screens_host/add_property/host_property_listing_screen.dart';
import 'package:rent_home/ui/screens_host/booking_history/booking_history_screen.dart';
import 'package:rent_home/ui/screens_host/invoices/invoice_page.dart';
import 'package:rent_home/ui/screens_host/profile/host_profile.dart';
import 'package:rent_home/ui/screens_host/support/host_messages_screen.dart';
import 'package:rent_home/service/notification_service.dart';
import '../../../constants.dart';
import '../../../utils/fonts.dart';
import '../../screens_common/auth/auth_controller.dart';
import 'host_home_screen.dart';

/// Host shell — new teal/orange design (scaffold host_shell): a bottom nav with
/// a raised center "Add Property" FAB. Backed by HostTabProvider (so the drawer +
/// add-property `resetToHome()` still drive it) and the existing wired screens.
///
/// Provider tab-ids → IndexedStack slots: 2=Dashboard, 3=Bookings, 6=Support,
/// 5=Profile, 7=Invoices (Invoices reachable via the drawer only). The center
/// FAB pushes the Add-Property flow rather than being a tab.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final HostController hostController = Get.put(HostController());
  final authController = Get.find<AuthController>();

  late final List<Widget> _screens = [
    HostHomeScreen(onMenuTap: _openDrawer), // slot 0 · tab 2
    const BookingHistoryScreen(), // slot 1 · tab 3
    // A-75 — Messages, not Support. Support is still here, pinned at the top
    // of it; the guest conversations that had no home in the app are below.
    const HostMessagesScreen(), // slot 2 · tab 6
    const HostProfilePage(), // slot 3 · tab 5
    InvoicePage(), // slot 4 · tab 7 (drawer only)
  ];

  static const Map<int, int> _tabToIndex = {2: 0, 3: 1, 6: 2, 5: 3, 7: 4};

  @override
  void initState() {
    super.initState();
    NotificationService().init();
  }

  void _openDrawer() {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      _scaffoldKey.currentState?.closeDrawer();
    } else {
      _scaffoldKey.currentState?.openDrawer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hostTabProvider = context.watch<HostTabProvider>();
    final currentTab = hostTabProvider.currentTab;
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        final provider = context.read<HostTabProvider>();
        if (provider.currentTab != 2) {
          provider.resetToHome();
        } else {
          Get.back();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: kscaffoldColor,
        drawer: HostHomeDrawer(
            authController: authController, hostTabProvider: hostTabProvider),
        body: IndexedStack(
          index: _tabToIndex[currentTab] ?? 0,
          children: _screens,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Get.to(() => const HostPropertyListingScreen()),
          backgroundColor: kIndigo600,
          elevation: 2,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _bottomBar(currentTab),
      ),
    );
  }

  Widget _bottomBar(int currentTab) {
    return BottomAppBar(
      color: kSurface,
      elevation: 8,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(2, currentTab, Ionicons.grid_outline, 'Dashboard'),
            _navItem(3, currentTab, Ionicons.calendar_outline, 'Bookings'),
            const SizedBox(
              width: 48,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 30),
                  child: Text('Add',
                      style: TextStyle(fontSize: 10, color: kMuted)),
                ),
              ),
            ),
            _navItem(6, currentTab, Icons.chat_bubble_outline, 'Messages'),
            _navItem(5, currentTab, Ionicons.person_outline, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int tabId, int currentTab, IconData icon, String label) {
    final active = currentTab == tabId;
    final color = active ? kIndigo600 : kMuted;
    return Expanded(
      child: InkWell(
        onTap: () => context.read<HostTabProvider>().setTab(tabId),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(label,
                style:
                    inter(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}
