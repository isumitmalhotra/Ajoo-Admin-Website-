import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/controller/user_controller.dart';

import 'package:rent_home/ui/screens_renter/history/history_description/property_review_controller.dart';

class AddReviewSection extends StatelessWidget {
  AddReviewSection({super.key, required this.propertyId});

  final int propertyId;
  final userController = Get.find<UserController>();
  final propertyController = Get.find<PropertyReviewController>();

  final reviewController = TextEditingController();
  double rating = 0;

  @override
  Widget build(BuildContext context) {
    final myReview =
        propertyController.propertyReviewResponse.value.data?.myReview;

    if (myReview != null) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 20),
        const Text(
          'Add Review',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        RatingBar.builder(
          initialRating: 2.0,
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: true,
          itemCount: 5,
          itemSize: 30,
          itemBuilder: (_, __) => const Icon(Icons.star, color: kprimaryColor),
          onRatingUpdate: (r) => rating = r,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: reviewController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Write your review...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Obx(() => ElevatedButton(
              onPressed: userController.isLoading.value
                  ? null
                  : () async {
                      await userController.addReview({
                        "propertyId": propertyId,
                        "rating": rating,
                        "description": reviewController.text,
                      });
                      propertyController.getPropertyReviews(propertyId);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: kprimaryColor,
                fixedSize: const Size(double.infinity, 48),
              ),
              child: userController.isLoading.value
                  ? const CircularProgressIndicator(color: kCream)
                  : const Text("Submit Review",
                      style: TextStyle(color: kCream)),
            )),
      ],
    );
  }
}
