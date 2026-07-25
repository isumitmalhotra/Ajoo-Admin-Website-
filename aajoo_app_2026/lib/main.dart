import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:rent_home/ui/screens_common/web_view/chat_web_view.dart';
import 'package:rent_home/ui/screens_host/host_tab_provider.dart';
import 'package:rent_home/ui/screens_common/faq/faq_page.dart';
import 'package:rent_home/firebase_options.dart';
import 'package:rent_home/ui/screens_common/auth/login_signup/auth_page.dart';
import 'package:rent_home/ui/screens_common/auth/forgot_password/forget_password_page.dart';
import 'package:rent_home/ui/screens_common/auth/verify/verify_page.dart';
import 'package:rent_home/ui/screens_common/auth/kyc/didit_kyc_screen.dart';
import 'package:rent_home/ui/screens_renter/home/homescreen.dart';
import 'package:rent_home/ui/screens_renter/guest_shell.dart';
import 'package:rent_home/ui/unused_screens/chat/chat_page.dart';
import 'package:rent_home/ui/screens_host/home/main_screen.dart';
import 'package:rent_home/ui/screens_renter/history/history_page.dart';
import 'package:rent_home/ui/screens_common/notifications/notification_screen.dart';
import 'package:rent_home/ui/screens_common/onboarding/onboarding.dart';
import 'package:rent_home/ui/screens_renter/profile/profile_screen.dart';
import 'package:rent_home/ui/screens_common/settings/settings_page.dart';
import 'package:rent_home/ui/screens_common/splash/splash_screen.dart';
import 'package:rent_home/ui/screens_common/support/support_screen.dart';
import 'package:rent_home/service/theme_service.dart';
import 'package:rent_home/ui/screens_common/price_negotiation/negotiation_wrapper.dart';
import 'package:rent_home/middleware/auth_middleware.dart';
import 'package:rent_home/middleware/notification_routing_middleware.dart';
import 'package:rent_home/ui/screens_common/location_picker/location_picker.dart';
import 'package:rent_home/ui/screens_renter/bookmark_properties/bookmark_properties_page.dart';
import 'package:rent_home/controller/alert_dialog.dart';

import 'binding/init_binding.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
      .whenComplete(() {});
  Get.put(ThemeService());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeService themeService = Get.find();
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const SplashScreen()),
        GetPage(name: '/onboarding', page: () => OnboardingPage()),
        GetPage(
            name: '/forgot-password', page: () => const ForgetPasswordPage()),
        GetPage(
            name: '/profile',
            page: () => const ProfileScreen(),
            middlewares: [AuthMiddleware()]),
        GetPage(name: '/login', page: () => const AuthPage()),
        GetPage(
            name: '/home',
            page: () => const GuestShell(),
            middlewares: [AuthMiddleware()]),
        GetPage(
            name: '/host/home',
            page: () => const MainScreen(),
            middlewares: [AuthMiddleware()]),
        GetPage(name: '/verify', page: () => VerifyPage()),
        GetPage(name: '/kyc', page: () => const DiditKycScreen()),
        GetPage(name: '/support', page: () => const SupportScreen()),
        GetPage(
            name: "/settings",
            page: () => const SettingsPage(),
            middlewares: [AuthMiddleware()]),
        GetPage(
            name: "/history",
            page: () => const HistoryPage(),
            middlewares: [AuthMiddleware()]),
        GetPage(name: "/faq", page: () => const FaqScren()),
        GetPage(
            name: "/bookmarkProperties",
            page: () => const BookmarkedPropertiesPage()),
        GetPage(
            name: "/negotiation",
            page: () => const NegotiationPageWrapper(),
            middlewares: [NotificationRoutingMiddleware()]),
        GetPage(
            name: '/location-picker', page: () => const LocationPickerPage()),
        GetPage(name: '/notifications', page: () => const NotificationsScreen()),
        GetPage(
          name: '/webview',
          page: () => const WebViewScreen(),
        ),
      ],
      initialBinding: InitBinding(),
      theme: themeService.lightTheme.copyWith(
        textTheme: themeService.lightTheme.textTheme.apply(
          fontFamily: 'Montserrat',
        ),
      ),
      darkTheme: themeService.darkTheme.copyWith(
        textTheme: themeService.darkTheme.textTheme.apply(
          fontFamily: 'Montserrat',
        ),
      ),
      themeMode:
          (themeService.isDarkMode.value ? ThemeMode.dark : ThemeMode.light),
      builder: (context, child) {
        return MultiProvider(
          providers: [
            Provider(create: (_) => ChatProvider()),
            ChangeNotifierProvider(create: (_) => HostTabProvider()),
          ],
          child: child!,
        );
      },
    );
  }
}
