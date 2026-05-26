import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/ui/screens_common/location_picker/location_permission_denied.dart';
import 'package:rent_home/ui/screens_host/add_property/new_property_controller_legacy.dart';

class PickLocationScreen extends StatefulWidget {
  const PickLocationScreen({super.key});

  @override
  State<PickLocationScreen> createState() => _PickLocationScreenState();
}

class _PickLocationScreenState extends State<PickLocationScreen> {
  final controller = Get.find<NewPropertyController>();
  LatLng? currentPosition;
  GoogleMapController? _googleMapController;

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _showPermissionDeniedDialog();
    } else if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      final pos = await Geolocator.getCurrentPosition();
      currentPosition = LatLng(pos.latitude, pos.longitude);
      setState(() {});
      _moveCameraToCurrentPosition(); // Update map camera
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Location Permission Denied"),
          content: const Text(
              "We need location permission to fetch properties. Please grant access."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _requestLocationPermission();
              },
              child: const Text("Grant Permission"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      final pos = await Geolocator.getCurrentPosition();
      currentPosition = LatLng(pos.latitude, pos.longitude);
      setState(() {});
      _moveCameraToCurrentPosition(); // Update map camera
    } else {
      if (permission == LocationPermission.deniedForever) {
        Get.to(() => const LocationPermissionDeniedPage());
      } else {
        Get.snackbar("Permission Denied", "Location permission is required",
            snackPosition: SnackPosition.TOP,
            backgroundColor: kprimaryColor.withOpacity(0.5));
      }
    }
  }

  void _moveCameraToCurrentPosition() {
    if (_googleMapController != null && currentPosition != null) {
      _googleMapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: currentPosition!,
            zoom: 16,
          ),
        ),
      );
    }
  }

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(30.7316, 76.7055),
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              height: double.infinity,
              width: double.infinity,
              color: Colors.grey,
              child: GoogleMap(
                zoomControlsEnabled: false,
                compassEnabled: true,
                myLocationButtonEnabled: true,
                myLocationEnabled: true,
                mapType: MapType.normal,
                initialCameraPosition: _kGooglePlex,
                onMapCreated: (GoogleMapController controller) {
                  _googleMapController = controller;
                  _moveCameraToCurrentPosition(); // Move to current position on map creation
                },
                onCameraMove: (position) {
                  controller.latitude.value = position.target.latitude;
                  controller.longitude.value = position.target.longitude;
                },
                padding: const EdgeInsets.only(top: 50),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Container(
                height: 50,
                width: 50,
                child: Image.asset(
                  "assets/pin.png",
                  height: 30,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kprimaryColor,
                    foregroundColor: kcontentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () {
                    Get.back();
                    print("Latitude: ${controller.latitude.value}");
                    print("Longitude: ${controller.longitude.value}");
                  },
                  child: const Text("Select Location"),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _googleMapController?.dispose();
    super.dispose();
  }
}
