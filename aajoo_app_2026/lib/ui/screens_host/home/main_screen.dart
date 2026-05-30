import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:rent_home/ui/screens_host/host_tab_provider.dart';
import 'package:rent_home/ui/screens_host/host_controller.dart';
import 'package:rent_home/ui/screens_host/home/host_home_drawer.dart';
import 'package:rent_home/ui/screens_host/invoices/invoice_page.dart';
import 'package:rent_home/ui/screens_common/notifications/notification_screen.dart';
import 'package:rent_home/service/notification_service.dart';
import '../../../constants.dart';
import '../../screens_common/auth/auth_controller.dart';
import 'host_home_screen.dart';
import '../profile/host_profile.dart';
import 'components/dummy_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Widget> screens = [
    const DummyScreen(),
    const DummyScreen(),
    const HostHomeScreen(),
    const DummyScreen(),
    const DummyScreen(),
    HostProfilePage(),
    const DummyScreen(),
    InvoicePage()
  ];

  final HostController hostController = Get.put(HostController());

  final authController = Get.find<AuthController>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // hostController.getHostOngoing(authController.userData.value!.userId);
    NotificationService().init();
  }

  @override
  Widget build(BuildContext context) {
    final hostTabProvider = context.watch<HostTabProvider>();
    final currentTab = hostTabProvider.currentTab;
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        final hostTabProvider = context.read<HostTabProvider>();
        if (hostTabProvider.currentTab != 2) {
          // If not on Home tab → go to Home
          hostTabProvider.resetToHome();
        } else {
          // If already on Home tab → exit app
          Get.back(); // or SystemNavigator.pop()
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          actions: [
            IconButton(
              icon: const Icon(Ionicons.notifications_outline),
              onPressed: () {
                Get.to(() => NotificationsScreen());
              },
            ),
          ],
          toolbarHeight: 80,
          title: hostHomeTitleView(currentTab),
          backgroundColor: kprimaryColor,
          foregroundColor: kcontentColor,
          leading: IconButton(
            icon: const Icon(Ionicons.grid_outline),
            onPressed: () {
              if (_scaffoldKey.currentState!.isDrawerOpen) {
                _scaffoldKey.currentState!.closeDrawer();
              } else {
                _scaffoldKey.currentState!.openDrawer();
              }
            },
          ),
        ),
        drawer: HostHomeDrawer(
            authController: authController, hostTabProvider: hostTabProvider),
        body: RefreshIndicator(
          onRefresh: () async {
            final user = authController.userData.value;
            if (user != null && user.userId != null) {
              hostController.getHostOngoing(user.userId!);
            }
            hostController.getHostProperties();
            hostController.getTransactionHistory();
            hostController.getHostBookingHistory();
          },
          child: Consumer<HostTabProvider>(
            builder: (context, hostTabProvider, child) {
              return IndexedStack(
                  index: hostTabProvider.currentTab, children: screens);
            },
          ),
        ),
      ),
    );
  }

  Column hostHomeTitleView(int currentTab) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        currentTab == 6
            ? const Text("Payout",
                style: TextStyle(color: Colors.white, fontSize: 16))
            : currentTab == 4
                ? const Text("Privacy Policy",
                    style: TextStyle(color: Colors.white, fontSize: 16))
                : Visibility(
                    visible: currentTab != 6 && currentTab != 4,
                    child: Text(authController.userData.value!.fullName,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 30)),
                  ),
      ],
    );
  }
}
