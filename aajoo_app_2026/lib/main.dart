import 'package:firebase_core/firebase_core.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:rent_home/ui/screens_common/web_view/chat_web_view.dart';
import 'package:rent_home/utils/lux_mode.dart';
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

import 'package:rent_home/data/ApiConstants.dart';

import 'binding/init_binding.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// A release build must name its endpoint (P0-01, FE-01).
  ///
  /// The default host is compiled out of release builds, so a release APK put
  /// together without `--dart-define=API_BASE_URL=…` has nowhere to talk to.
  /// Say so on the screen rather than starting: an app that silently talks to
  /// nowhere looks exactly like a broken network, and costs a day to diagnose
  /// from a tester's "it isn't loading". Debug builds are unaffected.
  if (!Apiconstants.isConfigured) {
    runApp(const _BuildConfigurationError());
    return;
  }

  // Firebase must never be able to stop the app from starting.
  //
  // This was an unguarded `await` before runApp(): on a handset with old,
  // broken or absent Google Play Services — common on budget and older
  // Samsung devices — initializeApp() throws or simply never returns, and
  // because runApp() sat behind it the app rendered NOTHING. The user stares
  // at the launch screen for ever, on a device where everything except push
  // notifications would have worked perfectly.
  //
  // Bounded and caught: if Firebase is unavailable we lose push, and we open.
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
        .timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('Firebase unavailable, starting without it: $e');
  }

  Get.put(ThemeService());

  // The stored LUXE preference, read alongside startup rather than in front of
  // it. Not awaited on purpose: a wedged Keystore must not hold the first
  // frame, and the screens listen to LuxMode, so a `true` arriving a beat late
  // re-skins them rather than being missed. Same order the website resolves
  // it in.
  unawaited(LuxMode.instance.load());

  runApp(const MyApp());
}

/// Shown instead of the app when the build was assembled without an endpoint.
///
/// Deliberately plain: no theme, no Get, no network — the point is that it
/// renders under any circumstances and names the missing flag.
class _BuildConfigurationError extends StatelessWidget {
  const _BuildConfigurationError();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.settings_ethernet, color: Colors.white70, size: 44),
                SizedBox(height: 18),
                Text(
                  'This build is not configured',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 12),
                Text(
                  'It was compiled without an API endpoint, so it has nothing '
                  'to connect to.\n\n'
                  'Rebuild with:\n'
                  'flutter build apk --dart-define=API_BASE_URL=https://…',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
      // The app's ambient typeface.
      //
      // This was Montserrat — a THIRD family, on top of the Poppins and
      // Manrope the design system actually specifies, and registered at one
      // weight only. It matters far more than it looks: a `Text` merges its
      // style onto the ambient one, so every `TextStyle(fontSize: 18,
      // fontWeight: bold)` written without a font — and there are around 250
      // of them, 42 on the property page alone — rendered in Montserrat
      // Regular. Bold never came out bold, and the booking panel sat in a
      // different face from the heading directly above it. That is the font
      // difference visible between the top and the bottom of a property page.
      //
      // Poppins rather than Manrope for the ambient default because Poppins
      // ships as four static weights: `fontWeight` on a bare TextStyle picks
      // a real file. Manrope is a variable font and needs `fontVariations`
      // (see utils/fonts.dart), which a bare TextStyle cannot carry, so bold
      // would silently stay at 400 — swapping one weight bug for another.
      // Screens that use fraunces()/inter() are unaffected and keep the
      // proper Poppins-display / Manrope-body pairing.
      theme: themeService.lightTheme.copyWith(
        textTheme: themeService.lightTheme.textTheme.apply(
          fontFamily: 'Poppins',
        ),
      ),
      darkTheme: themeService.darkTheme.copyWith(
        textTheme: themeService.darkTheme.textTheme.apply(
          fontFamily: 'Poppins',
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
