import 'dart:async';
import 'package:rent_home/ui/design/aajoo_skin.dart';
import 'package:rent_home/ui/screens_renter/home/map/lux_map_style.dart';
import 'package:rent_home/utils/lux_mode.dart';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/ui/screens_renter/home/map/map_controller.dart';
import 'package:rent_home/data/models/properties_response_model.dart';
import 'package:rent_home/widgets/hotel_dialog.dart';
import 'package:shimmer/shimmer.dart';
import 'package:rent_home/utils/money.dart';

/// The pin draws its own ₹ glyph, so it wants the digits alone.
String _pinPrice(String raw) => rupeesFrom(raw).replaceAll('₹', '');

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  /// The map controller currently attached to a LIVE platform view.
  ///
  /// The Completer above can only ever be completed once, so the first
  /// GoogleMapController it captured was kept for the rest of the session. When
  /// the platform view was torn down and rebuilt — opening a stay and coming
  /// back does it — onMapCreated handed us a fresh controller and the
  /// `isCompleted` guard threw it away. Every camera move after that went to a
  /// channel with nothing on the other end:
  ///
  ///   PlatformException(channel-error, Unable to establish connection on
  ///   channel "…MapsApi.animateCamera.0")
  ///
  /// which is why searching a city updated the pill, the count and the pins but
  /// left the map sitting on wherever it had been. The exception was unhandled
  /// and async, so it also aborted the rest of that listener silently.
  GoogleMapController? _liveMap;

  /// Where the camera should be once a live map exists.
  ///
  /// A search can land while the view is being rebuilt; without this the move
  /// is simply lost.
  LatLng? _pendingCameraTarget;

  /// Move the camera, tolerating a map that is missing or being replaced.
  Future<void> _moveCamera(LatLng pos, {double zoom = 14.5}) async {
    final controller = _liveMap;
    if (controller == null) {
      _pendingCameraTarget = pos;
      return;
    }
    try {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: pos, zoom: zoom)),
      );
    } on PlatformException {
      // The view behind this controller has gone. Hold the target so the next
      // onMapCreated applies it rather than dropping it.
      _pendingCameraTarget = pos;
    }
  }
  final MapController mapController = Get.find<MapController>();
  Map<String, Marker> markers = {};
  LatLng? _initialPosition;
  bool _isCheckingLocation = true;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();

    ever(mapController.isLuxury, (_) {
      _fetchProperties();
    });

    ever(mapController.error, _handleError);

    // React to external location updates (e.g., from location picker): animate only
    ever(mapController.currentPosition, (LatLng pos) async {
      // Wider than the 14.5 used for "back to me". Searching a town and
      // arriving at street zoom put a single pin in frame with the rest of the
      // results off-screen, which reads as "the search found one place".
      await _moveCamera(pos, zoom: 11.5);
      // Update selected location marker whenever the position changes.
      // Runs unconditionally: it used to sit after an un-guarded animateCamera,
      // so once that started throwing the marker stopped updating too.
      _updateSelectedLocationMarker(pos);
    });

    // Recreate markers when properties list updates
    ever(mapController.properties, (_) async {
      await createMarkers();
    });
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    // ASK, don't just look. checkPermission() reports `denied` while the OS
    // prompt is still on screen waiting to be answered, so this raised our own
    // "Location Permission Denied" dialog on top of the system one — and left
    // it sitting over a map that had resolved and a feed that had already
    // loaded 98 homes. Requesting awaits the person's actual answer.
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _showPermissionDeniedDialog();
      // Declining location used to RETURN here, and _fetchProperties() is only
      // reached from _getUserCurrentLocation() — so the map opened with no
      // properties on it at all, over California (see the fallback below).
      // Somebody who says "not now" should still see stays, just not centred
      // on themselves.
      setState(() => _isCheckingLocation = false);
      _fetchProperties();
      return;
    }

    _getUserCurrentLocation();
  }

  Future<BitmapDescriptor> _createCustomMarkerWithPrice(String price) async {
    const double width = 160.0;
    const double height = 65.0;
    const double triangleHeight = 15.0;

    final PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    // Modern gradient background
    const Rect rect = Rect.fromLTWH(0, 0, width, height);
    final Paint gradientPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          kIndigo, // brand teal
          kIndigo600, // deep teal
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    // Create modern rounded speech bubble
    final Path path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        rect,
        const Radius.circular(32),
      ))
      ..moveTo(width / 2 - 8, height) // Start triangle
      ..lineTo(width / 2 + 8, height) // Bottom right of triangle
      ..lineTo(width / 2, height + triangleHeight) // Tip of triangle
      ..close();

    // Draw shadow first (for depth)
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.save();
    canvas.translate(2, 2); // Shadow offset
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // Draw main bubble with gradient
    canvas.drawPath(path, gradientPaint);

    // Add subtle inner highlight
    final Paint highlightPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.3),
          Colors.white.withOpacity(0.05),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(const Rect.fromLTWH(0, 0, width, height * 0.6));

    final Path highlightPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(4, 4, width - 8, height * 0.5),
        const Radius.circular(28),
      ));
    canvas.drawPath(highlightPath, highlightPaint);

    // Modern border with subtle color
    final Paint borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(path, borderPaint);

    // Draw currency symbol (₹)
    final TextPainter currencyPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    )..text = const TextSpan(
        text: '₹',
        style: TextStyle(
          fontSize: 20.0,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      );

    currencyPainter.layout();

    // Clean price text (remove ₹ if present), then make it money.
    //
    // The API sends a DECIMAL as "3200.00", and the pin printed it verbatim —
    // "₹3200.00" on the map, with paise nobody charges and no thousands
    // separator, next to a web card reading "₹3,200". Rounded to whole rupees
    // and grouped the Indian way, which is what every other price on both
    // platforms does.
    final cleanPrice = _pinPrice(price);

    // Main price text with modern typography
    final TextPainter textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    )..text = TextSpan(
        text: cleanPrice,
        style: const TextStyle(
          fontSize: 22.0,
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      );

    textPainter.layout();

    // Calculate positions for centered layout
    final double totalWidth = currencyPainter.width + textPainter.width + 2;
    final double startX = (width - totalWidth) / 2;
    final double textY = (height - textPainter.height) / 2;

    // Paint currency symbol
    currencyPainter.paint(
      canvas,
      Offset(startX, textY - 1),
    );

    // Paint price text
    textPainter.paint(
      canvas,
      Offset(startX + currencyPainter.width + 2, textY),
    );

    // Add small shine effect at top-left
    final Paint shinePaint = Paint()..color = Colors.white.withOpacity(0.4);
    canvas.drawCircle(
      const Offset(25, 18),
      8,
      shinePaint,
    );

    final Paint innerShinePaint = Paint()
      ..color = Colors.white.withOpacity(0.6);
    canvas.drawCircle(
      const Offset(25, 18),
      4,
      innerShinePaint,
    );

    final img = await pictureRecorder
        .endRecording()
        .toImage(width.toInt(), (height + triangleHeight).toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);

    if (data == null) {
      throw Exception("Failed to create custom marker image");
    }
    return BitmapDescriptor.fromBytes(data.buffer.asUint8List());
  }

  /// Guards against a second copy stacking on the first.
  bool _permissionDialogOpen = false;

  void _showPermissionDeniedDialog() {
    if (_permissionDialogOpen || !mounted) return;
    _permissionDialogOpen = true;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Location Permission Denied"),
        content: const Text(
            "We need location permission to fetch properties. Please grant access."),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await Geolocator.requestPermission();
              _checkLocationPermission();
            },
            child: const Text("Grant Permission"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
        ],
      ),
    ).whenComplete(() => _permissionDialogOpen = false);
  }

  Future<void> _getUserCurrentLocation() async {
    // getCurrentPosition can take a while indoors and can fail outright with
    // GPS off. It was neither time-boxed nor caught, so either case left
    // _isCheckingLocation true forever and the screen sat on its loader with
    // no way out.
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
      _initialPosition = LatLng(position.latitude, position.longitude);
      mapController.currentPosition.value = _initialPosition!;
    } catch (_) {
      // A fix we already had beats no map at all. Falls through to the
      // controller's position if there is no cached one.
      final last =
          await Geolocator.getLastKnownPosition().catchError((_) => null);
      if (last != null) {
        _initialPosition = LatLng(last.latitude, last.longitude);
        mapController.currentPosition.value = _initialPosition!;
      }
    } finally {
      if (mounted) setState(() => _isCheckingLocation = false);
      _fetchProperties();
    }
  }

  // ── Pan-to-search ──────────────────────────────────────────────────────
  // Sliding the map to another area showed no properties there. Nothing was
  // subscribed to camera movement at all: the list was fetched on first load,
  // on the luxury toggle, and when the location picker pushed a new position,
  // and never again. Panning to the next city left you looking at the pins
  // from the last one.
  //
  // The controller already had fetchPropertiesAt(LatLng) for exactly this; it
  // simply had no caller. (Its sibling fetchProperties() re-reads GPS and
  // overwrites the position, so it cannot be used here — it would snap the
  // search straight back to the device.)
  LatLng? _cameraTarget;
  LatLng? _lastFetchCenter;
  bool _areaFetchInFlight = false;

  /// Metres the camera must travel before the area is searched again.
  ///
  /// Also what stops this feeding itself: fetchPropertiesAt writes
  /// currentPosition, the `ever` listener above animates the camera to it, and
  /// that animation raises another idle. That second idle lands ~0 m from the
  /// centre we just fetched, so it falls under the threshold and stops there.
  static const double _refetchThresholdMetres = 1500;

  void _onCameraIdle() {
    final target = _cameraTarget;
    if (target == null || _areaFetchInFlight) return;

    final from = _lastFetchCenter ?? mapController.currentPosition.value;
    final moved = Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      target.latitude,
      target.longitude,
    );
    if (moved < _refetchThresholdMetres) return;

    _lastFetchCenter = target;
    _areaFetchInFlight = true;
    mapController
        .fetchPropertiesAt(target)
        .then((_) => createMarkers())
        .whenComplete(() => _areaFetchInFlight = false);
  }

  void _fetchProperties() {
    Future<void> fetchFunction = mapController.isLuxury.value
        ? mapController.fetchLuxuryProperties()
        : mapController.fetchProperties();

    fetchFunction.then((_) {
      createMarkers();
    });
  }

  void _handleError(String error) {
    if (error == 'Location permission denied') {
      _showPermissionDeniedDialog();
    } else if (error.isNotEmpty) {
      Get.snackbar(error, "Please try again",
          snackPosition: SnackPosition.TOP,
          backgroundColor: kprimaryColor.withOpacity(0.5));
    }
  }

  void _showHotelDetails(
      String name,
      String price,
      List<String> imageUrls,
      String description,
      String rating,
      String coverImage,
      int id,
      String location,
      String lat,
      String long,
      dynamic checkInTime,
      dynamic checkOutTime,
      Property property,
      {String distance = "1.5"}) {
    showDialog(
      context: context,
      builder: (context) => HotelDialog(
        property: property,
        name: name,
        id: id,
        price: price,
        location: location,
        imageUrls: imageUrls,
        lat: lat,
        long: long,
        description: description,
        rating: rating,
        coverImage: coverImage,
        inTime: checkInTime,
        outTime: checkOutTime,
        distance: distance,
      ),
    );
  }

  Future<void> createMarkers() async {
    List<Marker> generatedMarkers = [];

    for (Property property in mapController.properties) {
      final BitmapDescriptor icon =
          // The raw column, so a pin read "₹8000.00" wherever the host had
          // typed decimals and "₹1700" wherever they had not — two formats on
          // one map.
          await _createCustomMarkerWithPrice(rupeesFrom(property.propertyPrice));

      final Marker marker = Marker(
        markerId: MarkerId(property.propertyId.toString()),
        position: LatLng(
          double.parse(property.propertyLatitude),
          double.parse(property.propertyLongitude),
        ),
        icon: icon,
        onTap: () {
          _showHotelDetails(
            property.propertyName,
            property.propertyPrice,
            property.images.cast<String>(),
            property.propertyDesc,
            // Was the constant "4.5" for every pin on the map. The model
            // carries the real average and ratingLabel is empty when nobody
            // has reviewed the stay, so an unrated place now says nothing
            // rather than claiming four and a half stars.
            property.ratingLabel,
            property.coverImage ??
                (property.images.isNotEmpty ? property.images[0] : ""),
            property.propertyId,
            property.propertyAddress,
            property.propertyLatitude,
            property.propertyLongitude,
            property.propDetailsPropDetailInTime,
            property.propDetailsPropDetailOutTime,
            property,
            distance: property.distance.toString(),
          );
        },
      );

      generatedMarkers.add(marker);
    }

    setState(() {
      markers = {
        for (var marker in generatedMarkers) marker.markerId.value: marker
      };
      // Re-add the selected location marker at the current position
      _updateSelectedLocationMarker(mapController.currentPosition.value);
    });
  }

  // Create a distinct custom marker for the selected location (simple pin with gradient)
  Future<BitmapDescriptor> _createSelectedLocationMarkerIcon() async {
    const double size = 110.0;
    const double circleRadius = 38.0;
    const double pointerHeight = 28.0;

    final PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    // Draw shadow
    canvas.save();
    canvas.translate(4, 4);
    final Path pinPathShadow = Path()
      ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(
              size / 2 - circleRadius, 0, circleRadius * 2, circleRadius * 2),
          const Radius.circular(circleRadius)))
      ..moveTo(size / 2 - 12, circleRadius * 2 - 4)
      ..lineTo(size / 2 + 12, circleRadius * 2 - 4)
      ..lineTo(size / 2, circleRadius * 2 + pointerHeight)
      ..close();
    canvas.drawPath(pinPathShadow, shadowPaint);
    canvas.restore();

    // Gradient fill for pin
    const Rect gradientRect = Rect.fromLTWH(size / 2 - circleRadius, 0,
        circleRadius * 2, circleRadius * 2 + pointerHeight - 6);
    final Paint gradientPaint = Paint()
      ..shader = const LinearGradient(
        colors: [kClay, kClay600],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(gradientRect);

    final Path pinPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(
              size / 2 - circleRadius, 0, circleRadius * 2, circleRadius * 2),
          const Radius.circular(circleRadius)))
      ..moveTo(size / 2 - 12, circleRadius * 2 - 4)
      ..lineTo(size / 2 + 12, circleRadius * 2 - 4)
      ..lineTo(size / 2, circleRadius * 2 + pointerHeight)
      ..close();
    canvas.drawPath(pinPath, gradientPaint);

    // Inner white circle
    final Paint innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(
        const Offset(size / 2, circleRadius), circleRadius - 12, innerPaint);

    // Dot in middle
    final Paint dotPaint = Paint()..color = kClay600;
    canvas.drawCircle(const Offset(size / 2, circleRadius), 10, dotPaint);

    final img = await recorder
        .endRecording()
        .toImage(size.toInt(), (circleRadius * 2 + pointerHeight + 6).toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) {
      throw Exception('Failed creating selected location marker icon');
    }
    return BitmapDescriptor.fromBytes(data.buffer.asUint8List());
  }

  // Add or update the selected location marker in the markers map
  Future<void> _updateSelectedLocationMarker(LatLng pos) async {
    try {
      final BitmapDescriptor icon = await _createSelectedLocationMarkerIcon();
      final Marker selectedMarker = Marker(
        markerId: const MarkerId('selected_location'),
        position: pos,
        icon: icon,
        zIndex: 9999,
        anchor: const Offset(0.5, 1.0),
        infoWindow: const InfoWindow(title: 'Selected Location'),
      );
      setState(() {
        markers['selected_location'] = selectedMarker;
      });
    } catch (e) {
      debugPrint('Error updating selected location marker: $e');
    }
  }

  /// Brings the camera back to the guest's own location.
  ///
  /// `myLocationEnabled` was on but `myLocationButtonEnabled` was off and
  /// nothing replaced it, so the blue dot was drawn with no way to return to
  /// it: pan away while browsing and the only recovery was to leave the screen
  /// and come back.
  ///
  /// Takes a fresh fix rather than reusing the stored one, since the point of
  /// pressing it is usually that the guest has physically moved, and writes it
  /// back to the controller so the map and the property search stay centred on
  /// the same coordinates. If the fix fails — permission revoked mid-session,
  /// GPS off — it falls back to the last known position instead of doing
  /// nothing.
  /// Go back to where the guest actually is — and show what is there.
  ///
  /// This used to move the camera and stop. The listings underneath still
  /// belonged to wherever the map had been panned to, so after tapping it the
  /// sheet said "100 homes in Mountain View" while the map was over Kharar,
  /// and every card in the rails was for the old place. Re-centring is a
  /// change of where you are looking, so it re-asks.
  Future<void> _recenter() async {
    LatLng target = mapController.currentPosition.value;
    bool moved = false;
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 6));
      target = LatLng(pos.latitude, pos.longitude);
      moved = true;
    } catch (_) {
      // No fix in six seconds: keep the last known position and still
      // re-centre on it, which is what the guest asked for.
    }

    await _moveCamera(target);
    if (moved) {
      // fetchPropertiesAt writes currentPosition, refreshes the place name and
      // re-runs the search — the same path a destination search takes.
      await mapController.fetchPropertiesAt(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isCheckingLocation
          ? Center(
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[50]!,
                child: Container(
                  height: double.infinity,
                  width: double.infinity,
                  color: Colors.grey[300],
                ),
              ),
            )
          : Obx(
              () => SizedBox(
                height: double.infinity,
                width: double.infinity,
                child: mapController.isLoading.value
                    ? Center(
                        // A light-grey shimmer over the whole viewport is a
                        // white flash on a LUX screen, every time the map
                        // reloads. Same steps the site uses for its LUXE
                        // skeletons (#141416 → #1D1D20).
                        child: ValueListenableBuilder<bool>(
                          valueListenable: LuxMode.instance.on,
                          builder: (context, lux, _) => Shimmer.fromColors(
                            baseColor: lux
                                ? const Color(0xFF141416)
                                : Colors.grey[300]!,
                            highlightColor: lux
                                ? const Color(0xFF1D1D20)
                                : Colors.grey[50]!,
                            child: Container(
                              height: double.infinity,
                              width: double.infinity,
                              color: lux
                                  ? const Color(0xFF141416)
                                  : Colors.grey[300],
                            ),
                          ),
                        ),
                      )
                    : Stack(
                        children: [
                          // The map is the biggest single surface on the home
                          // screen, and in LUX it stayed a daylight street map
                          // behind a black sheet — the loudest part of "LUX
                          // changed nothing". Rebuilt on the preference so the
                          // cartography follows the mode, the same way the
                          // site filters its own tiles. Rebuilding here swaps
                          // a parameter on the existing platform view; it does
                          // not recreate the map or move the camera.
                          ValueListenableBuilder<bool>(
                            valueListenable: LuxMode.instance.on,
                            builder: (context, lux, _) => GoogleMap(
                            style: lux ? luxMapStyle : null,
                            zoomControlsEnabled: false,
                            indoorViewEnabled: true,
                            compassEnabled: false,
                            // Traffic is drawn by the SDK on top of the style,
                            // so on the LUX map its greens and reds are the
                            // brightest thing on a near-black screen — the one
                            // part of the mode the style array cannot reach.
                            trafficEnabled: !lux,
                            buildingsEnabled: true,
                            myLocationButtonEnabled: false,
                            myLocationEnabled: true,
                            mapType: MapType.normal,
                            // The fallback was LatLng(37.427961, -122.085749) —
                            // Mountain View, California, the Android emulator's
                            // default. Any time the position had not resolved, the
                            // map opened on another continent while the property
                            // search ran against the controller's coordinates, so
                            // the map and the pins disagreed by 12,000 km.
                            //
                            // It falls back to the SAME position the properties
                            // were fetched around, so the two can never diverge.
                            // Where the app currently thinks it is looking —
                            // NOT the device's GPS fix.
                            //
                            // _initialPosition is written once, from the first
                            // location read, and never again. Every rebuild of
                            // the platform view therefore reset the camera to
                            // where the phone was, so returning from the search
                            // results threw away the searched place and put the
                            // map back on the device. currentPosition is what
                            // the properties were fetched around, which is the
                            // only position the pins can agree with.
                            initialCameraPosition: CameraPosition(
                              target: mapController.currentPosition.value,
                              zoom: 14.4746,
                            ),
                            onMapCreated: (GoogleMapController controller) {
                              _liveMap = controller;
                              if (!_controller.isCompleted) {
                                _controller.complete(controller);
                              }
                              // Land on wherever the app is currently looking.
                              // A move that arrived while the view was being
                              // rebuilt takes precedence; otherwise the search
                              // centre does, so a map created after a search
                              // never opens somewhere else.
                              final pending = _pendingCameraTarget;
                              _pendingCameraTarget = null;
                              _moveCamera(
                                  pending ?? mapController.currentPosition.value,
                                  zoom: 11.5);
                            },
                            onCameraMove: (CameraPosition p) =>
                                _cameraTarget = p.target,
                            onCameraIdle: _onCameraIdle,
                            markers: markers.values.toSet(),
                            padding: const EdgeInsets.only(top: 50),
                          )),
                          // Top-right, not bottom-right. This screen is only
                          // ever shown inside the renter home, which lays a
                          // draggable "N homes near you" sheet over the lower
                          // third of the map — a bottom-anchored control sits
                          // underneath it and cannot be tapped at all. The top
                          // offset clears the search field and the offer chip
                          // above it.
                          //
                          // It is also where Google's own myLocation button
                          // renders when enabled, so this is the position the
                          // gesture is already learned for.
                          Positioned(
                            right: 16,
                            top: 268,
                            child: _RecenterButton(onPressed: _recenter),
                          ),
                        ],
                      ),
              ),
            ),
    );
  }
}

/// The map's "back to me" control.
///
/// Deliberately a plain button rather than Google's built-in one: the built-in
/// sits under the search chrome at the top of this screen, which is why it was
/// switched off in the first place. This keeps it clear of both the top
/// overlay and the bottom sheet, and shows a spinner while the fix resolves so
/// a slow GPS lock does not read as another dead tap.
class _RecenterButton extends StatefulWidget {
  const _RecenterButton({required this.onPressed});

  final Future<void> Function() onPressed;

  @override
  State<_RecenterButton> createState() => _RecenterButtonState();
}

class _RecenterButtonState extends State<_RecenterButton> {
  bool _busy = false;

  Future<void> _run() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onPressed();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LuxBuilder(
      builder: (context, skin) => Tooltip(
        message: 'Show stays where I am',
        child: Material(
          color: skin.isLux ? skin.surface : Colors.white,
          shape: CircleBorder(
              side: BorderSide(color: skin.isLux ? skin.line : kLine)),
          elevation: skin.isLux ? 0 : 4,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _run,
            child: SizedBox(
              height: 46,
              width: 46,
              child: Center(
                child: _busy
                    ? SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: skin.primary),
                      )
                    : Icon(Icons.my_location,
                        size: 22,
                        color: skin.isLux ? skin.primary : kInk),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
