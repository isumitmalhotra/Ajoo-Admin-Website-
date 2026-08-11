import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/controller/user_controller.dart';
import 'package:rent_home/data/models/booking_history_response_model.dart';
import 'package:rent_home/service/device_service.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/ui/screens_renter/history/history_description/components/property_description_section.dart';
import 'package:rent_home/ui/screens_renter/history/history_description/components/property_details_map_section.dart';
import 'package:rent_home/ui/screens_renter/history/history_description/property_review_controller.dart';
import 'package:rent_home/ui/screens_renter/history/history_description/review/property_review_section.dart';
import 'package:shimmer/shimmer.dart';

class HistoryDescriptionPage extends StatefulWidget {
  const HistoryDescriptionPage({
    super.key,
    required this.bookingData,
    required this.propertyId,
  });

  final BookingHistoryData bookingData;
  final int propertyId;

  @override
  State<HistoryDescriptionPage> createState() => _HistoryDescriptionPageState();
}

class _HistoryDescriptionPageState extends State<HistoryDescriptionPage> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  final UserController userController = Get.put(UserController());
  final PropertyReviewController propertyController =
      Get.put<PropertyReviewController>(
    PropertyReviewController(),
  );
  final reviewController = TextEditingController();
  double rating = 0.0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await userController.getProperty(widget.propertyId);
      // wait a bit to ensure map is rendered
      await Future.delayed(const Duration(milliseconds: 300));

      _moveCameraToProperty();
    });
    propertyController.getPropertyReviews(widget.propertyId);
  }

  // Shown for the moment before the property's own coordinates arrive. This
  // was Mountain View, California — the Android emulator's default — and it was
  // never replaced, because _moveCameraToProperty() had been deleted while its
  // two call sites were left commented out. So a guest opening their booking
  // saw a map of California, permanently, whatever they had booked.
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(28.495000, 77.40905397),
    zoom: 12,
  );

  /// Centre the map on the property once its coordinates have loaded.
  Future<void> _moveCameraToProperty() async {
    try {
      final loc = userController.propertyLocation.value;
      // (0,0) is the null island — a property with no coordinates stored, which
      // is worth leaving alone rather than flying the camera into the Atlantic.
      if (loc.latitude == 0 && loc.longitude == 0) return;
      if (!_controller.isCompleted) return;
      final controller = await _controller.future;
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: loc, zoom: 15)),
      );
    } catch (_) {
      // A map that does not pan is worth less than a screen that crashes.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kscaffoldColor,
      appBar: _appBar(context),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HistoryMapSection(
                  isLoading: userController.isLoading,
                  propertyLocation: userController.propertyLocation,
                  initialPosition: _initialPosition,
                  onMapCreated: (controller) {
                    if (!_controller.isCompleted) {
                      _controller.complete(controller);
                    }
                    // Also move on creation: whichever of the two happens
                    // last — the map being ready, or the property loading —
                    // is the one that lands it in the right place.
                    _moveCameraToProperty();
                  },
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(0.0),
                  child: Obx(
                    () => PropertyDescriptionSection(
                        isLoading: userController.isLoading,
                        // Fall back to the property info stored on the booking
                        // when the live property can't be fetched (e.g. the host
                        // later removed the listing) — so history never goes blank.
                        propertyName:
                            userController.property.value?.data?.propertyName ??
                                widget.bookingData.bookingPropertyPropertyName,
                        propertyAddress: userController
                                .property.value?.data?.propertyAddress ??
                            widget.bookingData.bookingPropertyPropertyAddress,
                        bookingDataWidget:
                            _buildBookingData(widget.bookingData)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    'Rating and Reviews',
                    style: fraunces(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: kInk,
                    ),
                  ),
                ),
                PropertyReviewSection(
                  propertyId: widget.propertyId,
                  bookingData: widget.bookingData,
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          Positioned(
            bottom: 10,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: MediaQuery.of(context).size.width - 32,
                child: Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        DeviceService.launchDialPad(userController
                                .property.value?.data?.propertyContact ??
                            "");
                      },
                      child: Container(
                        height: 52,
                        width: 52,
                        decoration: BoxDecoration(
                          color: kSurface,
                          border: Border.all(color: kIndigo),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: kSoftShadow,
                        ),
                        child: const Icon(
                          Icons.phone,
                          size: 22,
                          color: kIndigo,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () async {
                          final LatLng location =
                              userController.propertyLocation.value;

                          final lat = location.latitude;
                          final lng = location.longitude;

                          DeviceService.showMapOptions(context, lat, lng);
                        },
                        child: Container(
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [kIndigo600, kIndigo],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: kIndigo.withOpacity(0.3),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.directions,
                                  color: kCream, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                "Get Directions",
                                style: inter(
                                  color: kCream,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  AppBar _appBar(BuildContext context) {
    return AppBar(
      title: const Text('History Description'),
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Theme.of(context).scaffoldBackgroundColor,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new),
        onPressed: () {
          // Pop this route directly via the local Navigator (reliable), with
          // Get.back() as a fallback — Get.back() alone was leaving users stuck.
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            Get.back();
          }
        },
      ),
    );
  }

  Widget _buildBookingData(BookingHistoryData booking) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Booking ID: ${booking.bookId}',
          style: fraunces(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: kInk,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _dateTile(
                icon: Icons.login_rounded,
                label: 'CHECK-IN',
                value: booking.bookDetailsBtBookFrom ?? '—',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _dateTile(
                icon: Icons.logout_rounded,
                label: 'CHECK-OUT',
                value: booking.bookDetailsBtBookTo ?? '—',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _statusBadge(booking.bookingStatusBsTitle ?? 'Unknown'),
      ],
    );
  }

  Widget _dateTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kSand,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: kIndigo),
              const SizedBox(width: 5),
              Text(
                label,
                style: inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: kMuted,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            softWrap: true,
            style: inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: kInk,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final s = status.toLowerCase();
    final bool positive = s.contains('paid') ||
        s.contains('confirm') ||
        s.contains('complete') ||
        s.contains('success');
    final bool pending = s.contains('pending') || s.contains('await');
    final Color c = positive ? kSuccess : (pending ? kClay : kIndigo);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: c),
          const SizedBox(width: 6),
          Text(
            status,
            style: inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: c,
            ),
          ),
        ],
      ),
    );
  }
}

class BookingHistoryMapShimmer extends StatelessWidget {
  const BookingHistoryMapShimmer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[50]!,
        child: Container(
          height: double.infinity,
          width: double.infinity,
          color: Colors.grey[300],
        ),
      ),
    );
  }
}
