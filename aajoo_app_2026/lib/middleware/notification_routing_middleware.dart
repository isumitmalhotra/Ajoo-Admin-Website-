import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../ui/screens_common/auth/auth_controller.dart';
import '../service/notification_routing_service.dart';

import 'package:rent_home/utils/app_log.dart';
class NotificationRoutingMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();

    // Check if user is authenticated for protected routes
    if (route != null && _isProtectedRoute(route)) {
      if (!authController.isLoggedIn.value) {
        // Store the intended route for after login
        Get.find<NotificationRoutingService>().setPendingRoute(route);
        return const RouteSettings(name: '/login');
      }
    }

    return null;
  }

  @override
  GetPage? onPageCalled(GetPage? page) {
    appLog('📱 Notification Routing Middleware: Processing ${page?.name}');
    return super.onPageCalled(page);
  }

  bool _isProtectedRoute(String route) {
    const protectedRoutes = [
      '/negotiation',
      '/profile',
      '/host/home',
      '/history',
      '/settings',
    ];

    return protectedRoutes
        .any((protectedRoute) => route.startsWith(protectedRoute));
  }
}
