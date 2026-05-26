import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/service/device_service.dart';
import 'package:rent_home/ui/screens_renter/home/homescreen.dart';

class BookingSuccessDialog extends StatelessWidget {
  final String paymentId;
  final String bookingId;
  final String lat;
  final String long;

  const BookingSuccessDialog({
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
            "Booking Successful",
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
              CupertinoPageRoute(builder: (_) => Homescreen()),
              (route) => false,
            );
          },
          child: const Text("Close"),
        ),
        ElevatedButton(
          onPressed: () {
            final latitude = double.parse(lat);
            final longitude = double.parse(long);

            if (Platform.isAndroid) {
              DeviceService.launchGoogleMaps(latitude, longitude);
            } else {
              DeviceService.showMapOptions(
                context,
                latitude,
                longitude,
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: kprimaryColor,
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
