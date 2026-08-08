import 'dart:async';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/controller/map_controller.dart';
import 'package:rent_home/models/properties_response_model.dart';
import 'package:rent_home/widgets/hotel_dialog.dart';
import 'package:shimmer/shimmer.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
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
      if (_controller.isCompleted) {
        final controller = await _controller.future;
        controller.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: pos, zoom: 14.5),
        ));
      }
      // Update selected location marker whenever the position changes
      _updateSelectedLocationMarker(pos);
    });

    // Recreate markers when properties list updates
    ever(mapController.properties, (_) async {
      await createMarkers();
    });
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _showPermissionDeniedDialog();
      setState(() => _isCheckingLocation = false);
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
          Color(0xFF667eea), // Modern blue
          Color(0xFF764ba2), // Modern purple
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

    // Clean price text (remove ₹ if present)
    final cleanPrice = price.replaceAll('₹', '').trim();

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

  void _showPermissionDeniedDialog() {
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
    );
  }

  Future<void> _getUserCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition();
    _initialPosition = LatLng(position.latitude, position.longitude);
    print("User Location: $_initialPosition");
    mapController.currentPosition.value = _initialPosition!;
    setState(() => _isCheckingLocation = false);
    _fetchProperties();
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
          await _createCustomMarkerWithPrice("₹${property.propertyPrice}");

      final Marker marker = Marker(
        markerId: MarkerId(property.propertyId.toString()),
        position: LatLng(
          double.parse(property.propertyLatitude),
          double.parse(property.propertyLongitude),
        ),
        icon: icon,
        onTap: () {
          print(property.distance);
          print(property.toJson());
          _showHotelDetails(
            property.propertyName,
            property.propertyPrice,
            property.images.cast<String>(),
            property.propertyDesc,
            "4.5",
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
        colors: [Color(0xFFff9966), Color(0xFFff5e62)],
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
    final Paint dotPaint = Paint()..color = const Color(0xFFff5e62);
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
                    : GoogleMap(
                        zoomControlsEnabled: false,
                        indoorViewEnabled: true,
                        compassEnabled: false,
                        trafficEnabled: true,
                        buildingsEnabled: true,
                        myLocationButtonEnabled: false,
                        myLocationEnabled: true,
                        mapType: MapType.normal,
                        initialCameraPosition: CameraPosition(
                          target: _initialPosition ??
                              const LatLng(37.427961, -122.085749),
                          zoom: 14.4746,
                        ),
                        onMapCreated: (GoogleMapController controller) {
                          if (!_controller.isCompleted) {
                            _controller.complete(controller);
                          }
                        },
                        markers: markers.values.toSet(),
                        padding: const EdgeInsets.only(top: 50),
                      ),
              ),
            ),
    );
  }
}
