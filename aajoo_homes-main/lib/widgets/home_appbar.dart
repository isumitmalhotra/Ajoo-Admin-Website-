import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ionicons/ionicons.dart';
import 'package:rent_home/ui/screens_common/auth/auth_controller.dart';

import '../constants.dart';

class HomeAppBar extends StatelessWidget {
  HomeAppBar({
    super.key,
  });
  final authController = Get.find<AuthController>();
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {},
          style: IconButton.styleFrom(
            backgroundColor: kcontentColor,
            padding: const EdgeInsets.all(15),
          ),
          iconSize: 30,
          icon: const Icon(Ionicons.grid_outline),
        ),
        SizedBox(
          width: 20,
        ),

        // Centered Greeting with Two Lines
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hello,",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                authController.userData.value?.fullName ?? "username",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
        ),

        IconButton(
          onPressed: () {},
          style: IconButton.styleFrom(
            backgroundColor: kcontentColor,
            padding: const EdgeInsets.all(15),
          ),
          iconSize: 30,
          icon: const Icon(Ionicons.notifications_outline),
        ),
      ],
    );
  }
}
