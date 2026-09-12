import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rent_home/data/models/properties_response_model.dart';
import 'package:rent_home/ui/screens_common/location_picker/location_permission_denied.dart';
import 'package:rent_home/service/map_service.dart';


import 'package:rent_home/utils/app_log.dart';
class MapController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  /// The last search could not reach the server at all.
  ///
  /// Distinct from "found nothing": the home screen used to tell a guest with
  /// no signal that there were no stays where they stood.
  final RxBool lastSearchFailed = false.obs;
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
  /// Where the guest is, quickly, or the best answer available.
  ///
  /// Client, 2026-09-12: "propertys are not laoding and maps are not coming up
  /// taking very long time". Two faults, and between them they describe that
  /// exactly.
  ///
  /// ONE — the answer to "may we use your location?" was thrown away.
  /// `permission` was read once, `requestPermission()` was called inside an
  /// un-awaited `.then`, and the check below still tested the STALE value. So
  /// on the first run after an install, a guest who tapped Allow got `null`
  /// anyway: the screen said "Location permission denied" and the search ran
  /// from this controller's hardcoded fallback in Delhi NCR, where there are no
  /// listings. Empty home screen, on the one run that makes a first impression.
  /// Reopening the app fixed it, which is why it reads as flaky rather than
  /// broken.
  ///
  /// TWO — `getCurrentPosition()` was called with no time limit and the default
  /// BEST accuracy, which asks the GPS chip for a fresh satellite fix. Indoors
  /// that takes tens of seconds and sometimes never lands, and the whole home
  /// screen is a grey shimmer until it does, because the map is not built until
  /// this returns. A last known position is instant and is easily good enough
  /// to put the map somewhere real and ask what is nearby; the fresh fix then
  /// refines it. Eight seconds and medium accuracy for the case where there is
  /// no last known position: a stay is found by the town it is in, not by the
  /// metre.
  Future<Position?> getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Awaited, and the ANSWER is what the rest of this reads.
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      Get.to(() => const LocationPermissionDeniedPage());
      return null;
    }

    // Instant, and usually minutes old at worst.
    final Position? last = await Geolocator.getLastKnownPosition().catchError(
      (_) => null,
    );
    if (last != null) {
      // Refine in the background. The map is already somewhere sensible, so a
      // slow fix costs the guest nothing; if it lands and it is somewhere else,
      // the screen catches up.
      _refineLocation();
      return last;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (_) {
      // A fix we could not get in time is not an error worth a red screen —
      // the caller falls back to the default centre and the guest can search.
      return null;
    }
  }

  /// A better fix, if one arrives, after the screen has already drawn.
  void _refineLocation() {
    Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 20),
      ),
    ).then((p) {
      final moved = _metresBetween(currentPosition.value, p) > 2000;
      currentPosition.value = LatLng(p.latitude, p.longitude);
      resolveCurrentPlace();
      // Re-search when the guest is somewhere materially different -- or when
      // the first search found nothing at all.
      //
      // The second half matters more than it looks. A last known position can
      // be hours old and a city away: the phone was last fixed at home, the
      // guest is now somewhere else, and the answer to "what is near me" is an
      // empty screen for a place they are not in. Searching twice for nothing
      // is a wasted request; showing an empty home when there are stays around
      // the corner is the complaint we are answering.
      if (moved || properties.isEmpty) getProperties(p.latitude, p.longitude);
    }).catchError((_) {
      // No better answer than the one already on screen. Nothing to say.
    });
  }

  static double _metresBetween(LatLng a, Position b) =>
      Geolocator.distanceBetween(a.latitude, a.longitude, b.latitude, b.longitude);

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

  /// Whether the guest asked for pet-friendly stays only.
  ///
  /// Held here with the rest of the stay so paging the map or changing the
  /// category cannot quietly drop it — the same reason dates and guests live
  /// here rather than in the sheet.
  final RxBool stayPetsOnly = false.obs;

  /// What the guest typed, and the price band they asked for.
  ///
  /// Both live here for the same reason the dates do: every refetch — paging
  /// the map, changing the category, widening the radius — must carry them, or
  /// the guest's search quietly turns into a different one. The price band in
  /// particular used to be applied in Dart to whatever had already been
  /// fetched, so it narrowed a page rather than the catalogue.
  final Rxn<String> searchTerm = Rxn<String>();
  final Rxn<double> stayMinPrice = Rxn<double>();
  final Rxn<double> stayMaxPrice = Rxn<double>();

  void setStay({String? from, String? to, int? guests, bool? petsOnly}) {
    stayFrom.value = (from != null && from.isNotEmpty) ? from : null;
    stayTo.value = (to != null && to.isNotEmpty) ? to : null;
    stayGuests.value = (guests != null && guests > 0) ? guests : 0;
    if (petsOnly != null) stayPetsOnly.value = petsOnly;
  }

  /// The typed term and the price band, set together by the search sheet.
  void setQuery({String? term, double? minPrice, double? maxPrice}) {
    searchTerm.value = (term != null && term.trim().isNotEmpty) ? term.trim() : null;
    stayMinPrice.value = (minPrice != null && minPrice > 0) ? minPrice : null;
    stayMaxPrice.value = (maxPrice != null && maxPrice > 0) ? maxPrice : null;
  }

  /// Widening steps for a search that came back empty, nearest first.
  ///
  /// Measured against the live database from Karnal: 50km answers in ~4s with
  /// a full page, 500km in ~24s with the same page, 20000km in ~92s. So the
  /// walk stops as early as it can, and only reaches for the last one when
  /// there is genuinely nothing on this side of the world.
  static const List<String> _searchRings = ['50', '500', '20000'];

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
      petsAllowed: stayPetsOnly.value,
      from: stayFrom.value,
      to: stayTo.value,
      q: searchTerm.value,
      minPrice: stayMinPrice.value,
      maxPrice: stayMaxPrice.value,
    );

    // Nothing within the default radius does not mean we have nothing. The
    // search is location-based, so a guest in a town whose listings sit a
    // district away — Karnal's are ~37km from its centre — gets an empty
    // result and an app that looks broken rather than merely far away.
    //
    // This used to retry ONCE at radius 20000, which is not "wide", it is the
    // whole planet: that single query takes ~92 SECONDS against the live
    // database and returns the same first page that a 50km query returns in
    // ~4. That was the endless search. Step outwards instead, and stop at the
    // first ring that actually has stays in it — the rings that find nothing
    // cost well under a second each, because the time is spent on matching
    // rows, not on the radius.
    //
    // The last ring is still planetary, deliberately: a tester on an emulator
    // reporting Mountain View has nothing within any sane distance, and one
    // slow answer beats an empty app.
    bool failed(PropertiesResponse? r) =>
        r == null || r.message == MapService.networkFailure;

    if (!failed(response) &&
        response!.data.property.isEmpty &&
        radius.isEmpty) {
      for (final ring in _searchRings) {
        final PropertiesResponse? wider = await mapService.getProperties(
          lat,
          long,
          category: category,
          radius: ring,
          guests: stayGuests.value > 0 ? stayGuests.value : null,
          petsAllowed: stayPetsOnly.value,
          q: searchTerm.value,
          minPrice: stayMinPrice.value,
          maxPrice: stayMaxPrice.value,
          from: stayFrom.value,
          to: stayTo.value,
          // The planetary ring genuinely takes longer than the default
          // receive timeout allows.
          receiveTimeout: ring == _searchRings.last
              ? const Duration(minutes: 3)
              : null,
        );
        // A ring we could not reach ends the walk — the next one would only
        // spend another timeout to fail the same way.
        if (failed(wider)) {
          response = wider;
          break;
        }
        if (wider!.data.property.isNotEmpty) {
          response = wider;
          break;
        }
      }
    }

    final bool unreachable = failed(response);

    isLoading.value = false;
    lastSearchFailed.value = unreachable;
    if (unreachable || response == null) {
      error.value =
          "We couldn't reach the server. Check your connection and try again.";
      return;
    }
    allProperties.assignAll(response.data.property);
    properties.assignAll(response.data.property);
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
      appLog("location permission denied");
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
    stayPetsOnly.value = false;
    searchTerm.value = null;
    stayMinPrice.value = null;
    stayMaxPrice.value = null;
    await getProperties(
      currentPosition.value.latitude,
      currentPosition.value.longitude,
    );
    // Price is a client-side narrowing of what came back, so it is cleared
    // after the refetch rather than before.
    applyPriceFilter();
  }

  /// Price is narrowed by the DATABASE now — see [setQuery].
  ///
  /// This used to sieve `allProperties` in Dart, which searches the page
  /// already fetched rather than the catalogue: a band could report nothing
  /// while the platform held plenty just outside that page, and the count
  /// beside it could only ever describe the page too. Kept as the reset the
  /// callers still expect, so the visible list always mirrors what came back.
  void applyPriceFilter({double? minPrice, double? maxPrice}) {
    properties.assignAll(allProperties);
  }

  Future<void> fetchLuxuryProperties() async {
    try {
      isLoading.value = true;
      final PropertiesResponse? response =
          await mapService.getLuxuryProperties();
      isLoading.value = false;
      if (response != null) {
        properties.assignAll(response.data.property);
        appLog("Luxury Properties: ${properties.length}");
      } else {
        error.value = 'Failed to fetch properties';
      }
    } catch (err) {
      appLog(err);
    }
  }
}
