import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/ui/screens_common/auth/auth_controller.dart';
import 'negotitaion_page.dart';
import '../../../data/models/properties_response_model.dart';

class NegotiationPageWrapper extends StatelessWidget {
  const NegotiationPageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Get arguments passed from notification or regular navigation
    final args = Get.arguments as Map<String, dynamic>?;

    if (args == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Invalid navigation data',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Please try again from the notifications.'),
            ],
          ),
        ),
      );
    }

    // Validate required parameters
    final String? userId = args['userId'];
    final String? receiverId = args['receiverId'];
    final String? propertyId = args['propertyId'];
    final String? serverUrl = args['serverUrl'];
    final String? token = args['token'];
    final Property? property = args['property'];
    final String? lat = args['lat'];
    final String? long = args['long'];
    final String? hostId = args['hostId'];
    final String? senderId = args['senderId'];
    if (userId == null ||
        receiverId == null ||
        propertyId == null ||
        serverUrl == null ||
        token == null ||
        property == null ||
        lat == null ||
        long == null ||
        hostId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_outlined,
                  size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'Missing Required Data',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Some required information is missing.'),
              const SizedBox(height: 16),
              Text('Debug Info: ${args.keys.join(', ')}'),
            ],
          ),
        ),
      );
    }

    return PriceNegotiationPage(
      userId: userId,
      receiverId: receiverId,
      propertyId: propertyId,
      serverUrl: serverUrl,
      token: token,
      property: property,
      lat: lat,
      long: long,
      senderId: senderId!,
      hostId: hostId,
    );
  }
}
