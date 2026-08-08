import 'package:get/get.dart';
import '../service/auth_service.dart';
import 'package:rent_home/controller/common_controller.dart';
import 'package:rent_home/controller/negotiation_controller.dart';
import 'package:rent_home/ui/screens_host/payout/payout_controller.dart';
import 'package:rent_home/controller/user_controller.dart';
import 'package:rent_home/service/negotitation_service.dart';
import 'package:rent_home/service/notification_routing_service.dart';
import 'package:rent_home/service/notification_service.dart';

import 'package:rent_home/ui/screens_common/auth/auth_controller.dart';

class InitBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AuthController(), permanent: true);
    // One-time cleanup for installs upgrading from the build that stored the
    // user's password on the device. Harmless when there is nothing to remove.
    AuthService().purgeStoredPassword();
    Get.put(CommonController(), permanent: true);
    Get.put(PayoutController(), permanent: true);
    Get.put(UserController(), permanent: true);
    Get.put(NotificationRoutingService(), permanent: true);
    Get.put(NotificationService(), permanent: true);
    // Ensure NotificationService sets up listeners immediately
    Get.find<NotificationService>().init();
    Get.put(NegotiationController(NegotiationService()), permanent: true);
  }
}
