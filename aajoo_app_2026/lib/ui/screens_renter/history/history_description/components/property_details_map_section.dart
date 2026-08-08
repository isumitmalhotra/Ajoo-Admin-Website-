import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/ui/screens_renter/history/history_description/history_description_page.dart';
import 'package:rent_home/utils/fonts.dart';

class HistoryMapSection extends StatelessWidget {
  const HistoryMapSection({
    super.key,
    required this.isLoading,
    required this.propertyLocation,
    required this.initialPosition,
    required this.onMapCreated,
  });

  final RxBool isLoading;
  final Rx<LatLng> propertyLocation;
  final CameraPosition initialPosition;
  final void Function(GoogleMapController) onMapCreated;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      width: double.infinity,
      color: kSand,
      child: Obx(
        () {
          if (isLoading.value) {
            return const BookingHistoryMapShimmer();
          }

          final location = propertyLocation.value;

          // 🔒 VERY IMPORTANT GUARD
          if (location.latitude == 0.0 && location.longitude == 0.0) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: kIndigo.withOpacity(0.07),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_off_outlined,
                        color: kIndigo, size: 26),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Location not available",
                    style: inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: kMuted,
                    ),
                  ),
                ],
              ),
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
