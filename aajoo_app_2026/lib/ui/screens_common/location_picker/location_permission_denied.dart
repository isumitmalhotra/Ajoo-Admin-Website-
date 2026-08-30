import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rent_home/constants.dart';

class LocationPermissionDeniedPage extends StatelessWidget {
  const LocationPermissionDeniedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No AppBar at all, and no other exit on the page — a guest who declined
      // the location prompt landed here with nowhere to go. Transparent so the
      // page's own layout is untouched; it exists only to carry the arrow, and
      // Flutter draws that only when there is something to pop back to.
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: kInk,
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/nolocation.png"),
            const Text("Location Permission Denied"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await Geolocator.openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: kprimaryColor,
                  foregroundColor: kscaffoldColor,
                  minimumSize: const Size(250, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  )),
              child: const Text("Open Settings"),
            )
          ],
        ),
      ),
    );
  }
}
