import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/ui/screens_renter/home/homescreen.dart';
import 'package:rent_home/ui/screens_renter/dashboard/dashboard_screen.dart';
import 'package:rent_home/ui/screens_renter/history/history_page.dart';
import 'package:rent_home/ui/screens_renter/bookmark_properties/bookmark_properties_page.dart';
import 'package:rent_home/ui/screens_renter/profile/profile_screen.dart';

/// Lets a tab move the shell to another tab.
///
/// Without this a tab wanting to send you "back to Home" could only call
/// Navigator.pop — which, from inside the shell, pops the shell's own route and
/// leaves an empty navigator: a black screen with nothing to go back to. The
/// dashboard's "Find a stay" did exactly that.
class GuestShellScope extends InheritedWidget {
  const GuestShellScope({
    super.key,
    required this.goToTab,
    required super.child,
  });

  /// 0 Home · 1 Dashboard · 2 Bookings · 3 Saved · 4 Profile.
  final void Function(int index) goToTab;

  /// Null when the screen is not inside the shell — it can also be pushed on
  /// its own from the drawer, where popping is the right move.
  static GuestShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GuestShellScope>();

  @override
  bool updateShouldNotify(GuestShellScope oldWidget) => false;
}

/// Guest bottom-nav shell (new design, scaffold guest_shell) — 5 tabs:
/// Home · Dashboard · Bookings · Saved · Profile, in an IndexedStack so each
/// keeps its state. Each tab is the existing (already-wired) screen; the shell
/// only adds the bottom nav. Route `/home` points here (see main.dart).
class GuestShell extends StatefulWidget {
  final int initialIndex;
  const GuestShell({super.key, this.initialIndex = 0});

  @override
  State<GuestShell> createState() => _GuestShellState();
}

class _GuestShellState extends State<GuestShell> {
  late int _index = widget.initialIndex.clamp(0, 4);

  final List<Widget> _screens = const [
    Homescreen(),
    RenterDashboardScreen(),
    HistoryPage(),
    BookmarkedPropertiesPage(),
    ProfileScreen(),
  ];

  void _goToTab(int index) {
    if (!mounted) return;
    setState(() => _index = index.clamp(0, _screens.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kscaffoldColor,
      body: GuestShellScope(
        goToTab: _goToTab,
        child: IndexedStack(index: _index, children: _screens),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: kLine)),
          boxShadow: [
            BoxShadow(
                color: Color(0x140F172A), blurRadius: 14, offset: Offset(0, -3)),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.resolveWith((states) => inter(
                  fontSize: 11,
                  fontWeight: states.contains(WidgetState.selected)
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: states.contains(WidgetState.selected) ? kInk : kMuted,
                )),
          ),
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            backgroundColor: Colors.white,
            elevation: 0,
            height: 64,
            indicatorColor: kIndigo50,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.home_outlined, color: kMuted),
                  selectedIcon: Icon(Icons.home_rounded, color: kIndigo),
                  label: 'Home'),
              NavigationDestination(
                  icon: Icon(Icons.grid_view_outlined, color: kMuted),
                  selectedIcon: Icon(Icons.grid_view_rounded, color: kIndigo),
                  label: 'Dashboard'),
              NavigationDestination(
                  icon: Icon(Icons.calendar_today_outlined, color: kMuted),
                  selectedIcon: Icon(Icons.calendar_today_rounded, color: kIndigo),
                  label: 'Bookings'),
              NavigationDestination(
                  icon: Icon(Icons.favorite_border, color: kMuted),
                  selectedIcon: Icon(Icons.favorite_rounded, color: kIndigo),
                  label: 'Saved'),
              NavigationDestination(
                  icon: Icon(Icons.person_outline, color: kMuted),
                  selectedIcon: Icon(Icons.person_rounded, color: kIndigo),
                  label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}
