import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/ui/screens_host/add_property/new_property_controller_legacy.dart';
import 'package:rent_home/ui/screens_renter/history/history_description/property_review_controller.dart';

class ViewPropertyAllReviewsPage extends StatefulWidget {
  const ViewPropertyAllReviewsPage({super.key, required this.propertyId});
  final int propertyId;

  @override
  State<ViewPropertyAllReviewsPage> createState() =>
      _ViewPropertyAllReviewsPageState();
}

class _ViewPropertyAllReviewsPageState
    extends State<ViewPropertyAllReviewsPage> {
  final propertyController = Get.put(PropertyReviewController());

  @override
  void initState() {
    super.initState();
    // Ensures API call runs after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      propertyController.getPropertyReviews(widget.propertyId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.close),
        ),
        backgroundColor: kscaffoldColor,
        foregroundColor: kprimaryColor,
      ),
      body: GetBuilder<PropertyReviewController>(
        builder: (_) {
          if (propertyController.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final reviewData =
              propertyController.propertyReviewResponse.value.data;

          if (reviewData == null || reviewData.reviews == null) {
            return const Center(child: Text("No reviews available."));
          }
          print("Review Data: ${reviewData.allRatings}");

          return SingleChildScrollView(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(
                  reviewData.averageRating ?? "0.0",
                  reviewData.allRatings?.length ?? 0,
                ),
                const SizedBox(height: 20),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reviewData.reviews!.length,
                  itemBuilder: (context, index) {
                    final review = reviewData.reviews![index];

                    return Card(
                      elevation: 0,
                      color: kscaffoldColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User Name & Verified Badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  review.userFullName ?? "Unknown",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: kSuccess,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.verified,
                                          color: kCream, size: 16),
                                      SizedBox(width: 4),
                                      Text(
                                        "Verified stay",
                                        style: TextStyle(fontSize: 12, color: kCream),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 4),

                            // Star Ratings
                            RatingBarIndicator(
                              rating: double.parse(review.brRating ?? "0"),
                              itemBuilder: (context, _) => const Icon(
                                Icons.star,
                                color: kprimaryColor,
                              ),
                              itemCount: 5,
                              itemSize: 18,
                            ),

                            const SizedBox(height: 8),

                            // Review Text
                            Text(
                              review.brDesc ?? "",
                              style: const TextStyle(fontSize: 14),
                            ),

                            const SizedBox(height: 4),

                            // Date
                            Text(
                              "${review.brAddedAt?.toString().substring(0, 10) ?? ""}",
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),

                            const SizedBox(height: 8),

                            // Like/Dislike Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        propertyController
                                            .likeReview(review.brId!);
                                      },
                                      icon: const Icon(
                                          Icons.thumb_up_alt_outlined),
                                    ),
                                    Text("${review.like ?? 0}"),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () {
                                        propertyController
                                            .dislikeReview(review.brId!);
                                      },
                                      icon: const Icon(
                                          Icons.thumb_down_alt_outlined),
                                    ),
                                    Text("${review.dislike ?? 0}"),
                                  ],
                                ),
                                const Text(
                                  "Reviewed on Aajoo",
                                  style: TextStyle(
                                    color: kprimaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(String averageRating, int totalReviews) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RatingBarIndicator(
            rating: double.tryParse(averageRating) ?? 0.0,
            itemBuilder: (context, _) =>
                const Icon(Icons.star, color: kprimaryColor),
            itemCount: 5,
            itemSize: 30,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                averageRating.substring(
                    0, averageRating.length >= 3 ? 3 : averageRating.length),
                style:
                    const TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
              ),
              Text(
                '($totalReviews Reviews)',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
