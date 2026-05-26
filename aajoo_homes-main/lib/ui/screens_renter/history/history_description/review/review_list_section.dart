import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/ui/screens_host/add_property/new_property_controller_legacy.dart';
import 'package:rent_home/ui/screens_renter/history/history_description/property_review_controller.dart';

class ReviewsListSection extends StatelessWidget {
  ReviewsListSection({super.key});

  final PropertyReviewController controller =
      Get.find<PropertyReviewController>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reviews = controller.propertyReviewResponse.value.data?.reviews;

    /// 🟡 Empty state
    if (reviews == null || reviews.isEmpty) {
      return Column(
        children: [
          Image.asset('assets/noreview.png', height: 160),
          const SizedBox(height: 8),
          Text(
            "No reviews yet",
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      );
    }

    /// 🟢 Reviews list
    return Column(
      children: reviews.take(5).map((review) {
        return Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 0,
                vertical: 4,
              ),
              title: Text(
                review.userFullName ?? "Anonymous",
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  review.brDesc ?? "",
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < double.parse(review.brRating ?? '0')
                        ? Icons.star
                        : Icons.star_border,
                    size: 16,
                    color: kprimaryColor,
                  ),
                ),
              ),
            ),

            /// 🔹 Divider between reviews
            const Divider(
              thickness: 1,
              height: 16,
            ),
          ],
        );
      }).toList(),
    );
  }
}
