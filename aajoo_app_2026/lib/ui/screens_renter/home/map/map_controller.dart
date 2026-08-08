import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rent_home/data/models/properties_response_model.dart';
import 'package:rent_home/ui/screens_common/location_picker/location_permission_denied.dart';
import 'package:rent_home/service/map_service.dart';

class MapController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxList<Property> properties = <Property>[].obs;
  final RxList<Property> allProperties = <Property>[].obs;

  final MapService mapService = MapService();
  final Rx<LatLng> currentPosition = const LatLng(28.495000, 77.40905397).obs;
  final Rx<bool> isLuxury = false.obs;
  Future<Position?> getCurrentLocation() async {
    final LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission().then((val) => {
            if (val == LocationPermission.denied ||
                val == LocationPermission.deniedForever)
              {
                Get.to(() => const LocationPermissionDeniedPage()),
              }
            else
              {
                // get current location
                Geolocator.getCurrentPosition().then((value) => {
                      currentPosition.value =
                          LatLng(value.latitude, value.longitude)
                    })
              }
          });
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      return null;
    }
    return await Geolocator.getCurrentPosition();
  }

  Future<void> getProperties(
    double lat,
    double long, {
    int category = 0,
    String radius = "", // default to empty string
  }) async {
    PropertiesResponse? response = await mapService
        .getProperties(lat, long, category: category, radius: radius);

    // Nothing within the default radius does not mean we have nothing. The
    // search is location-based, so a guest in any city we do not cover yet —
    // or an emulator still reporting Mountain View — gets an empty result and
    // an app that looks broken rather than merely far away. Retry once, wide,
    // exactly as the web client does.
    if (response != null && response.data.property.isEmpty && radius.isEmpty) {
      final PropertiesResponse? wider = await mapService
          .getProperties(lat, long, category: category, radius: "20000");
      if (wider != null && wider.data.property.isNotEmpty) {
        response = wider;
      }
    }

    isLoading.value = false;
    if (response != null) {
      allProperties.assignAll(response.data.property);
      properties.assignAll(response.data.property);
    } else {
      error.value = 'Failed to fetch properties';
    }
  }

  Future<void> fetchProperties({
    int category = 0,
    String radius = "", // default to empty string
  }) async {
    isLoading.value = true;
    final Position? position = await getCurrentLocation();
    if (position != null) {
      currentPosition.value = LatLng(position.latitude, position.longitude);
    } else {
      print("location permission denied");
      error.value = 'Location permission denied';
    }
    await getProperties(
      currentPosition.value.latitude,
      currentPosition.value.longitude,
      category: category,
      radius: radius,
    );
    isLoading.value = false;
  }

  // Fetch properties for a specific coordinates and update state
  Future<void> fetchPropertiesAt(LatLng pos,
      {int category = 0, String radius = ""}) async {
    try {
      isLoading.value = true;
      currentPosition.value = pos;
      await getProperties(pos.latitude, pos.longitude,
          category: category, radius: radius);
    } finally {
      isLoading.value = false;
    }
  }

  // Frontend price filter (min/max) without new API calls
  void applyPriceFilter({double? minPrice, double? maxPrice}) {
    if (minPrice == null && maxPrice == null) {
      properties.assignAll(allProperties);
      return;
    }
    final filtered = allProperties.where((p) {
      // Sanitize price like '₹1,200' -> '1200'
      final raw = p.propertyPrice.toString();
      final cleaned = raw.replaceAll(RegExp(r'[^0-9\.]'), '');
      final price = double.tryParse(cleaned) ?? 0.0;
      final okMin = minPrice == null || price >= minPrice;
      final okMax = maxPrice == null || price <= maxPrice;
      return okMin && okMax;
    }).toList();
    properties.assignAll(filtered);
  }

  Future<void> fetchLuxuryProperties() async {
    try {
      isLoading.value = true;
      final PropertiesResponse? response =
          await mapService.getLuxuryProperties();
      isLoading.value = false;
      if (response != null) {
        properties.assignAll(response.data.property);
        print("Luxury Properties: ${properties.length}");
      } else {
        error.value = 'Failed to fetch properties';
      }
    } catch (err) {
      print(err);
    }
  }
}
