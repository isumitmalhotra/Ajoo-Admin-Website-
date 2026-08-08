import 'package:flutter/material.dart';
import 'package:rent_home/screens/Home/homescreen.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = [
   const Homescreen(),
    const Placeholder(),
    const Placeholder(),
    const Placeholder(),
    const Placeholder(),
  ];
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomAppBar(
        color: Colors.white70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            buildNavBarItem(Icons.home, 'Home', 0),
            buildNavBarItem(Icons.message, 'My Task', 1),
            const SizedBox(width: 20),
            buildNavBarItem(Icons.bookmark, 'Message', 3),
            buildNavBarItem(Icons.person, 'Profile', 4),
          ],
        ),
      ),
      floatingActionButton:  ClipOval(
        child: Material(
          color: Theme.of(context).primaryColor,
          elevation: 10,
          child: const InkWell(
            child: SizedBox(
              width: 56,
              height: 56,
              child: Icon(
                Icons.search,
                size: 28,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget buildNavBarItem(IconData icon, String label, int index) {
    return InkWell(
      onTap: () => _onItemTapped(index),
      child:
          Icon(
            icon,
            color: _selectedIndex == index
                ? Theme.of(context).primaryColor
                : Colors.grey,
          ),

    );
  }
}