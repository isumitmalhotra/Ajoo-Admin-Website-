import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rent_home/constants.dart';

class LocationPermissionDeniedPage extends StatelessWidget {
  const LocationPermissionDeniedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
