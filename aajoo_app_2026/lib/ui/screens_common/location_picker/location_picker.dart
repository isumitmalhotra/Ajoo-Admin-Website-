import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rent_home/ui/screens_renter/home/map/map_controller.dart';

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final Completer<GoogleMapController> _controller = Completer();
  final MapController mapController = Get.find<MapController>();
  LatLng? _cameraTarget; // Always reflects map center

  @override
  void initState() {
    super.initState();
    _cameraTarget = mapController.currentPosition.value;
  }

  Future<void> _ensurePermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick a location'),
        actions: [
          TextButton(
            onPressed: _cameraTarget == null
                ? null
                : () {
                    Navigator.pop(context, _cameraTarget);
                  },
            child: Text('CONFIRM', style: TextStyle(color: theme.primaryColor)),
          )
        ],
      ),
      body: FutureBuilder(
        future: _ensurePermission(),
        builder: (context, snapshot) {
          return Stack(
            alignment: Alignment.center,
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _cameraTarget ?? const LatLng(28.495000, 77.40905397),
                  zoom: 14.5,
                ),
                zoomControlsEnabled: false,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                onMapCreated: (c) {
                  if (!_controller.isCompleted) _controller.complete(c);
                },
                onCameraMove: (position) {
                  _cameraTarget = position.target;
                },
              ),
              // Center pin
              IgnorePointer(
                ignoring: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Slight bounce/indicator could be added here
                    Icon(
                      Icons.location_pin,
                      size: 48,
                      color: theme.primaryColor,
                    ),
                    Container(
                      width: 2,
                      height: 8,
                      color: Colors.black12,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _cameraTarget == null
            ? null
            : () => Navigator.pop(context, _cameraTarget),
        icon: const Icon(Icons.check),
        label: const Text('Use this location'),
      ),
    );
  }
}
