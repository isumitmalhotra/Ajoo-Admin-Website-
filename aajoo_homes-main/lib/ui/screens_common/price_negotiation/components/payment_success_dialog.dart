import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rent_home/ui/unused_screens/chat/chat_page.dart';
import 'package:rent_home/service/device_service.dart';
import 'package:rent_home/ui/screens_renter/home/homescreen.dart';

class PaymentSuccessDialog extends StatelessWidget {
  final String paymentId;
  final String bookingId;
  final double lat;
  final double long;

  const PaymentSuccessDialog({
    super.key,
    required this.paymentId,
    required this.bookingId,
    required this.lat,
    required this.long,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Image.asset(
        "assets/success.image.png",
        height: 200,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Payment Successful",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text("Booking Id: $bookingId"),
          const SizedBox(height: 16),
          Text("Payment Id: $paymentId"),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              CupertinoPageRoute(
                builder: (context) => const Homescreen(),
              ),
              (route) => false,
            );
          },
          child: const Text("Close"),
        ),
        ElevatedButton(
          onPressed: () async {
            if (Platform.isAndroid) {
              DeviceService.launchGoogleMaps(lat, long);
            }
            DeviceService.showMapOptions(context, lat, long);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            minimumSize: const Size(100, 50),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text("Get Directions"),
        ),
      ],
    );
  }
}
