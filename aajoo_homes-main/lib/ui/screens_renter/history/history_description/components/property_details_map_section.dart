import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rent_home/ui/screens_renter/history/history_description/history_description_page.dart';

class HistoryMapSection extends StatelessWidget {
  const HistoryMapSection({
    super.key,
    required this.isLoading,
    required this.propertyLocation,
    required this.initialPosition,
    required this.onMapCreated,
  });

  final RxBool isLoading;
  final Rxn<LatLng> propertyLocation;
  final CameraPosition initialPosition;
  final void Function(GoogleMapController) onMapCreated;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade500, width: 2),
      ),
      child: Obx(
        () {
          if (isLoading.value) {
            return const BookingHistoryMapShimmer();
          }

          final location = propertyLocation.value;

          // 🔒 VERY IMPORTANT GUARD
          if (location == null ||
              (location.latitude == 0.0 && location.longitude == 0.0)) {
            return const Center(
              child: Text("Location not available"),
            );
          }

          return GoogleMap(
            zoomControlsEnabled: false,
            compassEnabled: false,
            myLocationButtonEnabled: false,
            myLocationEnabled: false,
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: location,
              zoom: 16,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('property'),
                position: location,
              ),
            },
            onMapCreated: onMapCreated,
          );
        },
      ),
    );
  }
}
