import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/service/device_service.dart';

class SupportAssistantWidget extends StatelessWidget {
  final VoidCallback? onTap;

  const SupportAssistantWidget({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: kprimaryColor,
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(10),
        foregroundColor: Colors.white,
      ),
      icon: const Icon(
        Icons.support_agent_rounded,
        size: 40,
      ),
    );
  }
}

class WhatsappSupportAssistantWidget extends StatelessWidget {
  final VoidCallback? onTap;

  const WhatsappSupportAssistantWidget({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: kprimaryColor,
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(10),
        foregroundColor: Colors.white,
      ),
      icon: Image.asset(
        'assets/whatsapp.png',
        width: 40,
        height: 40,
      ),
    );
  }
}
