import 'package:geocoding/geocoding.dart';
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

  /// The name of wherever the user actually is — "Kharar", "Gurugram".
  ///
  /// The home screen's search pill was hardcoded to "Goa" while the property
  /// list underneath it was already being fetched around the user's real
  /// coordinates. The listings were right; the label above them named somewhere
  /// the user had never been.
  ///
  /// Resolved with the platform's own geocoder (the `geocoding` package, already
  /// a dependency) — no key, no quota. Empty until it resolves, and the UI falls
  /// back to "Nearby" rather than inventing a place.
  final RxString currentPlace = ''.obs;

  /// Best-effort: a device with no geocoder, permission or network simply
  /// leaves the label alone.
  Future<void> resolveCurrentPlace() async {
    try {
      final marks = await placemarkFromCoordinates(
        currentPosition.value.latitude,
        currentPosition.value.longitude,
      );
      if (marks.isEmpty) return;
      final p = marks.first;
      // locality is the town/city; subAdministrativeArea is the district, the
      // more useful answer when a village has no locality of its own.
      final name = [p.locality, p.subAdministrativeArea, p.administrativeArea]
          .firstWhere((v) => v != null && v.trim().isNotEmpty, orElse: () => null);
      if (name != null) currentPlace.value = name.trim();
    } catch (_) {
      // Leave it empty — the UI shows "Nearby".
    }
  }
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

  /// The stay the guest is searching for, held so it can travel.
  ///
  /// The search sheet collected "When" and "Who" and dropped them: the fetch
  /// ignored them, and opening a stay asked for both again. Kept on the
  /// controller because the property page, the map and the sheet all need the
  /// same answer, and because it must survive the sheet being closed.
  /// Dates are DD-MM-YYYY, the shape the API and both clients use.
  final Rxn<String> stayFrom = Rxn<String>();
  final Rxn<String> stayTo = Rxn<String>();
  final RxInt stayGuests = 0.obs;

  void setStay({String? from, String? to, int? guests}) {
    stayFrom.value = (from != null && from.isNotEmpty) ? from : null;
    stayTo.value = (to != null && to.isNotEmpty) ? to : null;
    stayGuests.value = (guests != null && guests > 0) ? guests : 0;
  }

  Future<void> getProperties(
    double lat,
    double long, {
    int category = 0,
    String radius = "", // default to empty string
  }) async {
    PropertiesResponse? response = await mapService.getProperties(
      lat,
      long,
      category: category,
      radius: radius,
      // Whatever the guest last asked for narrows every fetch, so paging the
      // map or changing the category cannot quietly drop their dates.
      guests: stayGuests.value > 0 ? stayGuests.value : null,
      from: stayFrom.value,
      to: stayTo.value,
    );

    // Nothing within the default radius does not mean we have nothing. The
    // search is location-based, so a guest in any city we do not cover yet —
    // or an emulator still reporting Mountain View — gets an empty result and
    // an app that looks broken rather than merely far away. Retry once, wide,
    // exactly as the web client does.
    if (response != null && response.data.property.isEmpty && radius.isEmpty) {
      final PropertiesResponse? wider = await mapService.getProperties(
        lat,
        long,
        category: category,
        radius: "20000",
        guests: stayGuests.value > 0 ? stayGuests.value : null,
        from: stayFrom.value,
        to: stayTo.value,
      );
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
      // Name it, so the search pill can stop saying "Goa".
      resolveCurrentPlace();
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
      resolveCurrentPlace();
      await getProperties(pos.latitude, pos.longitude,
          category: category, radius: radius);
    } finally {
      isLoading.value = false;
    }
  }

  /// Drop every search narrowing and look again.
  ///
  /// The empty state offers this because the fetch ALREADY retries at a
  /// 20,000km radius — so when nothing comes back, distance is not what is
  /// excluding the stays, the filters are. Widening the radius again would
  /// change nothing and look broken.
  Future<void> clearSearchFilters() async {
    stayFrom.value = null;
    stayTo.value = null;
    stayGuests.value = 0;
    await getProperties(
      currentPosition.value.latitude,
      currentPosition.value.longitude,
    );
    // Price is a client-side narrowing of what came back, so it is cleared
    // after the refetch rather than before.
    applyPriceFilter();
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
