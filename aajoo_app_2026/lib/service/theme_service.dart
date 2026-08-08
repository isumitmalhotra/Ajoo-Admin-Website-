import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/utils/fonts.dart';

class ThemeService extends GetxController {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String _key = 'isDarkMode';

  // Observable variable to track the theme
  var isDarkMode = false.obs;

  // Constructor to initialize the theme mode
  ThemeService({bool loadFromStorage = true}) {
    if (loadFromStorage) {
      _loadTheme();
    }
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
    colorScheme: ColorScheme.fromSeed(
      seedColor: kIndigo, // Ocean Teal — regenerates the M3 scheme around teal
    ),
    useMaterial3: true,
    // Poppins (display) + Manrope (body) — matches the web design system.
    textTheme: interTextTheme(),
    primaryColor: kprimaryColor,
    scaffoldBackgroundColor: kscaffoldColor,
    cardColor: kCream,
    canvasColor: kcontentColor,
  );

  ThemeData darkTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: kIndigo, // teal seed, dark brightness
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      textTheme: interTextTheme(const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
        bodySmall: TextStyle(color: Colors.white),
      )),
      primaryColor: kprimaryColor,
      scaffoldBackgroundColor: const Color(0xFF111827), // brand navy, one step below the card
      cardColor: kInk, // Charcoal Navy — the brand's dark surface
      drawerTheme: const DrawerThemeData(
        backgroundColor: kInk,
        scrimColor: Colors.black54,
      ));
}
