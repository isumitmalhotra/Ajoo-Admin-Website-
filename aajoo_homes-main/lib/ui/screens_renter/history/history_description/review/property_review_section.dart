import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/ui/screens_host/add_property/new_property_controller_legacy.dart';
import 'package:rent_home/data/models/booking_history_response_model.dart';
import 'package:rent_home/ui/screens_renter/history/history_description/review/all_reviews_list/view_property_all_reviews_page.dart';
import 'package:rent_home/ui/screens_renter/history/history_description/property_review_controller.dart';
import 'package:rent_home/ui/screens_renter/history/history_description/review/add_review_section.dart';
import 'package:rent_home/ui/screens_renter/history/history_description/review/my_review_section.dart';
import 'package:rent_home/ui/screens_renter/history/history_description/review/rating_summary_section.dart';
import 'package:rent_home/ui/screens_renter/history/history_description/review/review_list_section.dart';
import 'package:rent_home/ui/screens_renter/history/history_description/review/review_section_shimmer.dart';

class PropertyReviewSection extends StatelessWidget {
  const PropertyReviewSection({
    super.key,
    required this.propertyId,
    required this.bookingData,
  });

  final int propertyId;
  final BookingHistoryData bookingData;

  @override
  Widget build(BuildContext context) {
    final propertyController = Get.find<PropertyReviewController>();

    return Obx(() {
      if (propertyController.isLoading.value) {
        return const ReviewSectionShimmer();
      }

      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                Get.to(
                    () => ViewPropertyAllReviewsPage(propertyId: propertyId));
              },
              child: RatingSummarySection(),
            ),
            AddReviewSection(propertyId: propertyId),
            ReviewsListSection(),
            MyReviewSection(
              propertyId: propertyId,
              bookingData: bookingData,
            ),
          ],
        ),
      );
    });
  }
}
