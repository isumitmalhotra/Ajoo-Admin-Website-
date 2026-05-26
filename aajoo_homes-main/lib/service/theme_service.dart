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
    useMaterial3: true,
    fontFamily: 'Montserrat', 
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xffBF5973),
    ),

    primaryColor: const Color(0xffC14464),
    scaffoldBackgroundColor: kscaffoldColor,
    cardColor: kscaffoldColor,
    canvasColor: kcontentColor,

    textTheme: ThemeData.light().textTheme.apply(
          fontFamily: 'Montserrat',
          bodyColor: Colors.black,
          displayColor: Colors.black,
        ),
  );


  ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Montserrat', 

    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xffBF5973),
      brightness: Brightness.dark,
    ),

    primaryColor: kprimaryColor,
    scaffoldBackgroundColor: Colors.grey.shade900,
    cardColor: Colors.grey.shade600,

    textTheme: ThemeData.dark().textTheme.apply(
          fontFamily: 'Montserrat',
          bodyColor: kprimaryColor,
          displayColor: kprimaryColor,
        ),

    drawerTheme: DrawerThemeData(
      backgroundColor: Colors.grey.shade800,
      scrimColor: Colors.white,
    ),
  );

}
