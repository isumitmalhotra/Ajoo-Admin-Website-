import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/data/ApiConstants.dart';
import 'package:rent_home/data/source/remote/dio_config.dart';
import 'package:rent_home/ui/screens_common/location_picker/location_permission_denied.dart';
import 'package:rent_home/ui/screens_host/add_property/new_property_controller_legacy.dart';

/// One search suggestion from the backend's geocode proxy — the same
/// /public/geocode/search the website's picker uses, so both platforms agree
/// on what a place search finds. Keyless (OSM/Nominatim via our server), so it
/// works even if the Google tiles key ever lapses.
class _PlaceHit {
  final double lat;
  final double lng;
  final String label;
  const _PlaceHit(this.lat, this.lng, this.label);
}

class PickLocationScreen extends StatefulWidget {
  const PickLocationScreen({super.key});

  @override
  State<PickLocationScreen> createState() => _PickLocationScreenState();
}

class _PickLocationScreenState extends State<PickLocationScreen> {
  final controller = Get.find<NewPropertyController>();
  LatLng? currentPosition;
  GoogleMapController? _googleMapController;

  // ── Place search ──────────────────────────────────────────────────────────
  // The picker used to be tap-and-drag only: a host listing a property in
  // another town had to fling the map across the country by hand.
  final _searchController = TextEditingController();
  final Dio _dio = Dio();
  Timer? _debounce;
  List<_PlaceHit> _hits = [];
  bool _searching = false;

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    if (q.trim().length < 3) {
      setState(() => _hits = []);
      return;
    }
    // Debounced hard — the backend paces Nominatim at one request a second.
    _debounce = Timer(const Duration(milliseconds: 550), () async {
      setState(() => _searching = true);
      try {
        final res = await _dio.get('/public/geocode/search',
            queryParameters: {'q': q.trim()});
        final body = res.data;
        final places = (body is Map && body['success'] == true)
            ? (body['data']?['places'] as List? ?? [])
            : [];
        if (!mounted) return;
        setState(() {
          _hits = places
              .whereType<Map>()
              .map((p) => _PlaceHit(
                    (p['lat'] as num).toDouble(),
                    (p['lng'] as num).toDouble(),
                    '${p['label'] ?? ''}',
                  ))
              .toList();
        });
      } catch (_) {
        if (mounted) setState(() => _hits = []);
      } finally {
        if (mounted) setState(() => _searching = false);
      }
    });
  }

  void _goToHit(_PlaceHit h) {
    FocusScope.of(context).unfocus();
    setState(() {
      _hits = [];
      _searchController.text = h.label.split(',').first;
    });
    // The camera move triggers onCameraMove, which is what feeds lat/lng to
    // the controller — same path as a manual drag, so nothing else changes.
    _googleMapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(h.lat, h.lng), zoom: 16),
      ),
    );
  }

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
    DioConfig.apply(_dio, Apiconstants.baseUrl);
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
              child: SizedBox(
                height: 50,
                width: 50,
                child: Image.asset(
                  "assets/pin.png",
                  height: 30,
                ),
              ),
            ),
            // Search overlay — type a town or landmark instead of dragging the
            // map across the country. Same backend search as the website.
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  Material(
                    elevation: 3,
                    borderRadius: BorderRadius.circular(12),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search a town, area or landmark…',
                        prefixIcon: _searching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2)),
                              )
                            : const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _hits = []);
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  if (_hits.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      constraints: const BoxConstraints(maxHeight: 220),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: kSoftShadow,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _hits.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: kLine),
                        itemBuilder: (_, i) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.place_outlined,
                              size: 18, color: kIndigo),
                          title: Text(_hits[i].label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13)),
                          onTap: () => _goToHit(_hits[i]),
                        ),
                      ),
                    ),
                ],
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
    _debounce?.cancel();
    _searchController.dispose();
    _googleMapController?.dispose();
    super.dispose();
  }
}
