import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/ui/screens_host/add_property/new_property_controller_legacy.dart';
import 'package:rent_home/controller/user_controller.dart';
import 'package:rent_home/data/models/booking_history_response_model.dart';
import 'package:rent_home/ui/screens_renter/history/history_description/review/all_reviews_list/view_property_all_reviews_page.dart';
import 'package:rent_home/service/device_service.dart';
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

      // _moveCameraToProperty();
    });
    propertyController.getPropertyReviews(widget.propertyId);
  }

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  Future<void> _moveCameraToProperty() async {
    if (!_controller.isCompleted) return;
    final controller = await _controller.future;
    final LatLng target = userController.propertyLocation.value;
    if (target.latitude == 0.0 && target.longitude == 0.0) return;

    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(target, 16),
    );
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
                    // _moveCameraToProperty();
                  },
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(0.0),
                  child: Obx(
                    () => PropertyDescriptionSection(
                        isLoading: userController.isLoading,
                        propertyName:
                            userController.property.value?.data?.propertyName,
                        propertyAddress: userController
                            .property.value?.data?.propertyAddress,
                        bookingDataWidget:
                            _buildBookingData(widget.bookingData)),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Rating and Reviews',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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
                      onTap: () {
                        DeviceService.launchDialPad(userController
                                .property.value?.data?.propertyContact ??
                            "");
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: kcontentColor,
                          border: Border.all(color: kprimaryColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.phone,
                          size: 35,
                          color: kprimaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () async {
                        final LatLng location =
                            userController.propertyLocation.value;

                        if (location == null) {
                          return; // or show fallback UI
                        }

                        final lat = location.latitude;
                        final lng = location.longitude;

                        DeviceService.showMapOptions(context, lat, lng);
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width - 100,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: kprimaryColor,
                          border: Border.all(color: kprimaryColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "Get Directions",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: kcontentColor,
                            fontSize: 24,
                            fontWeight: FontWeight.normal,
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
          Get.back();
        },
      ),
    );
  }

  Widget _buildBookingData(BookingHistoryData booking) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking ID: ${booking.bookId}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: kSand,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    'From: ${booking.bookDetailsBtBookFrom}',
                    softWrap: true,
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: kSand,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'To: ${booking.bookDetailsBtBookTo}',
                    softWrap: true,
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Booking status: ${booking.bookingStatusBsTitle}',
            style: const TextStyle(
              color: kprimaryColor,
              fontWeight: FontWeight.normal,
              fontSize: 18,
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
