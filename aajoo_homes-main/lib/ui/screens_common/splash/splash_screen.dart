import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:rent_home/controller/common_controller.dart';
import '../auth/auth_controller.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({Key? key}) : super(key: key);

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> {
//   final AuthController authController = Get.find<AuthController>();
//   final CommonController commonController = Get.find<CommonController>();

//   int _currentIndex = 0;
//   late Timer _timer;

//   final List<Map<String, String>> _hotelContent = [
//     {
//       'quote': 'Discover Your Perfect Stay with Us',
//       'image': 'assets/hotel_welcome.png'
//     },
//     {
//       'quote': 'Luxury and Comfort Await You',
//       'image': 'assets/hotel_luxury.png'
//     },
//     {
//       'quote': 'Book Your Dream Vacation Today',
//       'image': 'assets/hotel_vacation.png'
//     },
//     {
//       'quote': 'Experience Unmatched Hospitality',
//       'image': 'assets/hotel_hospitality.png'
//     },
//     {
//       'quote': 'Creating Memorable Stays Since 2020',
//       'image': 'assets/hotel_milestone.png'
//     },
//   ];

//   @override
//   void initState() {
//     super.initState();
//     debugPrint("🚀 SplashScreen initState called");

//     _initializeApp();

//     debugPrint("📡 Fetching amenities & tags...");
//     commonController.fetchAmenities();
//     commonController.fetchTags();

//     _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
//       if (mounted) {
//         setState(() {
//           _currentIndex = (_currentIndex + 1) % _hotelContent.length;
//         });
//         debugPrint("🔄 Carousel index changed: $_currentIndex");
//       } else {
//         debugPrint("⚠️ Widget not mounted, timer skipped");
//       }
//     });
//   }

//   Future<void> _initializeApp() async {
//     debugPrint("⚙️ Initializing app...");

//     try {
//       debugPrint("🔐 Checking login status...");
//       final isLoggedIn = await authController.checkLoginStatus();
//       debugPrint("✅ Login status: $isLoggedIn");

//       if (isLoggedIn) {
//         debugPrint("👤 Fetching user details...");
//         authController.getUserDetails();
//         debugPrint("✅ User details fetched");
//       }

//       if (!mounted) {
//         debugPrint("❌ Widget not mounted, aborting navigation");
//         return;
//       }

//       debugPrint("📦 Checking onboarding status...");
//       final hasSeenOnboarding = await _checkOnboardingStatus();
//       debugPrint("✅ Onboarding seen: $hasSeenOnboarding");

//       if (!hasSeenOnboarding) {
//         debugPrint("➡️ Navigating to /onboarding");
//         Get.offAllNamed('/onboarding');
//       } else if (!isLoggedIn) {
//         debugPrint("➡️ Navigating to /login");
//         Get.offAllNamed('/login');
//       } else {
//         final isHost = authController.userData.value?.isHost == true;
//         debugPrint("👤 Is Host: $isHost");

//         if (isHost) {
//           debugPrint("➡️ Navigating to /host/home");
//           Get.offAllNamed('/host/home');
//         } else {
//           debugPrint("➡️ Navigating to /home");
//           Get.offAllNamed('/home');
//         }
//       }
//     } catch (e, stackTrace) {
//       debugPrint("❌ Error during initialization: $e");
//       debugPrint("📍 StackTrace: $stackTrace");

//       if (mounted) {
//         debugPrint("➡️ Navigating to /login (fallback)");
//         Get.offAllNamed('/login');
//       }
//     }
//   }

//   Future<bool> _checkOnboardingStatus() async {
//     debugPrint("🔍 Reading token from secure storage...");

//     const storage = FlutterSecureStorage();
//     final token = await storage.read(key: authController.authService.TOKEN_KEY);

//     debugPrint("🔑 Token: ${token != null ? "EXISTS" : "NULL"}");

//     if (token == null) {
//       debugPrint("❗ No token found → onboarding required");
//       return false;
//     }

//     debugPrint("✅ Token found → onboarding already done");
//     return true;
//   }

//   @override
//   void dispose() {
//     debugPrint("🧹 Disposing SplashScreen & cancelling timer");
//     _timer.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     debugPrint("🎨 SplashScreen build called");

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Lottie.asset(
//               'assets/Animation - 1750412011914.json',
//               width: 200,
//               height: 200,
//               fit: BoxFit.cover,
//             ),
//             const SizedBox(height: 30),
//             AnimatedSwitcher(
//               duration: const Duration(milliseconds: 400),
//               transitionBuilder: (child, animation) {
//                 return FadeTransition(opacity: animation, child: child);
//               },
//               child: Text(
//                 _hotelContent[_currentIndex]['quote']!,
//                 key: ValueKey<int>(_currentIndex),
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                   fontSize: 20,
//                   fontFamily: 'Mon',
//                   color: Colors.orange,
//                   fontWeight: FontWeight.w800,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }
// }

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthController authController = Get.find<AuthController>();
  final CommonController commonController = Get.find<CommonController>();
  int _currentIndex = 0;
  late Timer _timer;

  // List of hotel-themed quotes/milestones and corresponding images
  final List<Map<String, String>> _hotelContent = [
    {
      'quote': 'Discover Your Perfect Stay with Us',
      'image': 'assets/hotel_welcome.png',
    },
    {
      'quote': 'Luxury and Comfort Await You',
      'image': 'assets/hotel_luxury.png',
    },
    {
      'quote': 'Book Your Dream Vacation Today',
      'image': 'assets/hotel_vacation.png',
    },
    {
      'quote': 'Experience Unmatched Hospitality',
      'image': 'assets/hotel_hospitality.png',
    },
    {
      'quote': 'Creating Memorable Stays Since 2020',
      'image': 'assets/hotel_milestone.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeApp();
    commonController.fetchAmenities();
    commonController.fetchTags();

    // Start timer to cycle through quotes and images
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _hotelContent.length;
        });
      }
    });
  }

  Future<void> _initializeApp() async {
    try {
      final isLoggedIn = await authController.checkLoginStatus();
      if (isLoggedIn) {
        authController.getUserDetails();
      }
      if (mounted) {
        final hasSeenOnboarding = await _checkOnboardingStatus();
        if (!hasSeenOnboarding) {
          Get.offAllNamed('/onboarding');
        } else if (!isLoggedIn) {
          Get.offAllNamed('/login');
        } else {
          final isHost = authController.userData.value?.isHost == true;
          if (isHost) {
            Get.offAllNamed('/host/home');
          } else {
            Get.offAllNamed('/home');
          }
        }
      } else {
        debugPrint("❌ Widget not mounted, skipping navigation");
      }
    } catch (e, stackTrace) {
      if (mounted) {
        debugPrint("➡️ Navigating to /login (fallback)");
        //Get.offAllNamed('/login');
      }
    }
  }

  Future<bool> _checkOnboardingStatus() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: authController.authService.TOKEN_KEY);
    if (token == null) {
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel the timer to prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // lottie animation from networl
            Lottie.asset(
              'assets/Animation - 1750412011914.json',
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 30),
            // Animated image carousel

            // Animated quote/milestone text
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Text(
                _hotelContent[_currentIndex]['quote']!,
                textAlign: TextAlign.center,
                key: ValueKey<int>(_currentIndex),
                style: const TextStyle(
                  fontSize: 20,
                  fontFamily: 'Mon',
                  color: Colors.orange,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Loading indicator
          ],
        ),
      ),
    );
  }
}
