import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/service/device_service.dart';
import 'package:rent_home/utils/fonts.dart';

/// The map for a stay you have actually booked.
///
/// Distinct from the property page's approximate area circle on purpose: once
/// a booking exists the exact address is shared, so this drops a real pin at
/// the property and offers directions from it.
///
/// Used by the booking-confirmed screen and the ongoing-booking screen. Both
/// previously had a button that threw you out to the Google Maps app and no
/// map of their own, so there was nowhere in Aajoo that showed you where you
/// were going.
class StayMap extends StatelessWidget {
  final double? lat;
  final double? lng;
  final String? label;
  final double height;

  /// Show the "Get Directions" button under the map.
  final bool showDirections;

  const StayMap({
    super.key,
    required this.lat,
    required this.lng,
    this.label,
    this.height = 200,
    this.showDirections = true,
  });

  bool get _hasLocation {
    final a = lat, b = lng;
    return a != null && b != null && !(a == 0 && b == 0);
  }

  void _directions(BuildContext context) {
    if (!_hasLocation) return;
    if (Platform.isAndroid) {
      DeviceService.launchGoogleMaps(lat!, lng!);
    } else {
      DeviceService.showMapOptions(context, lat!, lng!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasLocation) {
      // Say what is missing rather than showing an empty grey box, and do not
      // offer directions to nowhere — the old button launched Maps at 0,0.
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: kSand,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off_outlined, color: kMuted, size: 26),
              const SizedBox(height: 8),
              Text("The host hasn't pinned this property on the map",
                  textAlign: TextAlign.center,
                  style: inter(fontSize: 12.5, color: kMuted)),
            ],
          ),
        ),
      );
    }

    final at = LatLng(lat!, lng!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: height,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: at, zoom: 15),
              markers: {
                Marker(
                  markerId: const MarkerId('stay'),
                  position: at,
                  infoWindow: InfoWindow(title: label ?? 'Your stay'),
                ),
              },
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              // Lite mode keeps this cheap on a screen that is mostly text and
              // does not need panning; tapping through to Maps is the gesture.
              liteModeEnabled: true,
              onTap: (_) => _directions(context),
            ),
          ),
        ),
        if (showDirections) ...[
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () => _directions(context),
            icon: const Icon(Icons.navigation_outlined, size: 18),
            label: const Text('Get Directions'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kIndigo,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: inter(fontSize: 15, fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ],
    );
  }
}
