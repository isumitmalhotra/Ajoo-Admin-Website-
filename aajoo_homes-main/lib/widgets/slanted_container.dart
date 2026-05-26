import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:rent_home/ui/screens_renter/home/map/map_controller.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SlantedContainerWithFilterIcon extends StatefulWidget {
  const SlantedContainerWithFilterIcon({super.key});

  @override
  State<SlantedContainerWithFilterIcon> createState() =>
      _SlantedContainerWithFilterIconState();
}

class _SlantedContainerWithFilterIconState
    extends State<SlantedContainerWithFilterIcon> {
  RxString currentLocation = " - ".obs; // Observable for current location
  final mapController =
      Get.find<MapController>(); // Assumes MapController is set up properly
  bool _isDebouncing = false;

  Future<String> getAddress(double lat, double long) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, long);
      Placemark place = placemarks[0];
      return "${place.street}, ${place.locality}";
    } catch (e) {
      print("Error getting address: $e");
      return " - ";
    }
  }

  @override
  void initState() {
    super.initState();

    // Listener for changes in mapController's currentPosition
    ever(mapController.currentPosition, (val) {
      getAddress(val.latitude, val.longitude).then((value) {
        currentLocation.value = value; // Update observable
      });
    });
  }

  // Calculate dynamic text length based on available width
  int _calculateMaxTextLength(double containerWidth) {
    // Adjust these values based on your font sizes and padding
    const double charWidth = 8.0; // Estimated average character width
    const double iconWidth = 18.0; // Icon size
    const double iconPadding = 4.0; // Space between icon and text

    // Calculate available space for text
    double availableTextSpace = containerWidth - iconWidth - iconPadding;

    // Calculate how many characters can fit
    return max(10, (availableTextSpace / charWidth).floor());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive container width (min 200, max 80% of screen width)
    final containerWidth = min(210.0, screenWidth * 0.8);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate max characters based on available width
        final maxTextLength = _calculateMaxTextLength(containerWidth);

        return GestureDetector(
          onTap: () async {
            // Debounce rapid taps
            if (_isDebouncing) return;
            _isDebouncing = true;
            Future.delayed(const Duration(milliseconds: 800), () {
              _isDebouncing = false;
            });
            // Open location picker and get selected LatLng
            final result =
                await Navigator.pushNamed(context, '/location-picker');
            if (result is LatLng) {
              // Show loading overlay while fetching
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                    const Center(child: CircularProgressIndicator()),
              );
              await mapController.fetchPropertiesAt(result);
              Navigator.of(context).pop(); // remove loading
              final addr = await getAddress(result.latitude, result.longitude);
              currentLocation.value = addr;
            }
          },
          child: ClipPath(
            child: Container(
              width: containerWidth,
              decoration: BoxDecoration(
                color: theme.canvasColor,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.symmetric(
                vertical: 12,
                horizontal: min(40.0, screenWidth * 0.06), // Responsive padding
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "Current location",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black.withOpacity(0.7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.black,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Obx(
                          () => Text(
                            _formatLocationText(
                                currentLocation.value, maxTextLength),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Format location text with proper ellipsis
  String _formatLocationText(String location, int maxLength) {
    if (location.length <= maxLength) {
      return location;
    }
    return "${location.substring(0, maxLength - 3)}...";
  }
}
