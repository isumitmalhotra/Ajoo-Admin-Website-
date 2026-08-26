import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/ui/design/aajoo_skin.dart';
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
    // The tab bar is the one surface that is on screen no matter which tab you
    // are on, so leaving it white was the last thing that gave LUX away: a
    // bright strip pinned to the bottom of an otherwise black screen. It takes
    // the skin like everything else, and its destinations are built rather
    // than const so the icons can follow the mode.
    return LuxBuilder(builder: (context, skin) => Scaffold(
      backgroundColor: skin.page,
      body: GuestShellScope(
        goToTab: _goToTab,
        child: IndexedStack(index: _index, children: _screens),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: skin.isLux ? skin.sheet : Colors.white,
          border: Border(top: BorderSide(color: skin.line)),
          boxShadow: const [
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
                  color: states.contains(WidgetState.selected)
                      ? skin.ink
                      : skin.muted,
                )),
          ),
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            backgroundColor: skin.isLux ? skin.sheet : Colors.white,
            elevation: 0,
            height: 64,
            indicatorColor: skin.primaryWash,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              _tab(skin, Icons.home_outlined, Icons.home_rounded, 'Home'),
              _tab(skin, Icons.grid_view_outlined, Icons.grid_view_rounded,
                  'Dashboard'),
              _tab(skin, Icons.calendar_today_outlined,
                  Icons.calendar_today_rounded, 'Bookings'),
              _tab(skin, Icons.favorite_border, Icons.favorite_rounded,
                  'Saved'),
              _tab(skin, Icons.person_outline, Icons.person_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    ));
  }

  NavigationDestination _tab(
    AajooSkin skin,
    IconData icon,
    IconData selected,
    String label,
  ) =>
      NavigationDestination(
        icon: Icon(icon, color: skin.muted),
        selectedIcon: Icon(selected, color: skin.primary),
        label: label,
      );
}
