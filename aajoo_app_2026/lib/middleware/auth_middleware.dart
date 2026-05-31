import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import '../ui/screens_common/auth/auth_controller.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();

    // Check if user is logged in
    if (!authController.isLoggedIn.value) {
      return const RouteSettings(name: '/login');
    }

    return null; // Allow navigation
  }

  @override
  GetPage? onPageCalled(GetPage? page) {
    Logger().i('🔐 Auth Middleware: Checking authentication for ${page?.name}');
    return super.onPageCalled(page);
  }
}
