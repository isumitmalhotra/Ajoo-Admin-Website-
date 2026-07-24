import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/service/device_service.dart';
import 'package:rent_home/ui/screens_renter/home/homescreen.dart';

/// Booking success — re-skinned to the new teal/orange design (scaffold
/// booking_confirmed): green hero check, Booking ID card, Get Directions. Props
/// + Get-Directions / go-home wiring unchanged.
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

  void _goHome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      CupertinoPageRoute(builder: (_) => const Homescreen()),
      (route) => false,
    );
  }

  void _getDirections(BuildContext context) {
    final latitude = double.tryParse(lat) ?? 0;
    final longitude = double.tryParse(long) ?? 0;
    if (Platform.isAndroid) {
      DeviceService.launchGoogleMaps(latitude, longitude);
    } else {
      DeviceService.showMapOptions(context, latitude, longitude);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Green hero check
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: kSuccess,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: kSuccess.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8)),
                ],
              ),
              child: const Icon(Icons.check_rounded,
                  size: 40, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text('Booking Confirmed!',
                style: fraunces(
                    fontSize: 22, fontWeight: FontWeight.w700, color: kInk)),
            const SizedBox(height: 6),
            Text('Your stay is all set. We can’t wait to host you!',
                textAlign: TextAlign.center,
                style: inter(fontSize: 13, color: kMuted, height: 1.4)),
            const SizedBox(height: 18),
            // Booking ID card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: const Color(0xFFE6F5F3),
                  borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Booking ID',
                      style: inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: kIndigo600)),
                  const SizedBox(height: 2),
                  Text(bookingId,
                      style: fraunces(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: kInk)),
                  if (paymentId.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('Payment: $paymentId',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: inter(fontSize: 11, color: kMuted)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Actions
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _getDirections(context),
                icon: const Icon(Icons.navigation_outlined, size: 18),
                label: const Text('Get Directions'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: kIndigo,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle:
                        inter(fontSize: 15, fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _goHome(context),
                style: OutlinedButton.styleFrom(
                    foregroundColor: kInk,
                    side: const BorderSide(color: kLine),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: Text('Go to Home',
                    style: inter(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
