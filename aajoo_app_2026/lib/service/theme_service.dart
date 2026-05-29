import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rent_home/constants.dart';

class ThemeService extends GetxController {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  final String _key = 'isDarkMode';

  // Observable variable to track the theme
  var isDarkMode = false.obs;

  // Constructor to initialize the theme mode
  ThemeService() {
    _loadTheme();
  }

  // Load theme from secure storage
  Future<void> _loadTheme() async {
    String? storedValue = await _storage.read(key: _key);
    isDarkMode.value = storedValue == 'true';
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  // Toggle theme and save the new state
  void toggleTheme() async {
    isDarkMode.value = !isDarkMode.value;
    await _storage.write(key: _key, value: isDarkMode.value.toString());
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  ThemeData lightTheme = ThemeData(
    fontFamily: "Mon",
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1B2447),
    ),
    useMaterial3: true,
    textTheme: GoogleFonts.latoTextTheme(),
    primaryColor: kprimaryColor,
    scaffoldBackgroundColor: kscaffoldColor,
    cardColor: kCream,
    canvasColor: kcontentColor,
  );

  ThemeData darkTheme = ThemeData(
    fontFamily: "Mon",
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1B2447),
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    textTheme: GoogleFonts.latoTextTheme(const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
      bodySmall: TextStyle(color: Colors.white),
    )),
    primaryColor: kprimaryColor,
    scaffoldBackgroundColor: Colors.grey.shade900,
    cardColor: Colors.grey.shade800,
    drawerTheme: DrawerThemeData(
      backgroundColor: Colors.grey.shade800,
      scrimColor: Colors.white,
    ));
}
