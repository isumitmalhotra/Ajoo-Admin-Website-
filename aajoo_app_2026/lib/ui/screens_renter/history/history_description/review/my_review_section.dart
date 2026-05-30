import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/controller/user_controller.dart';
import 'package:rent_home/ui/screens_host/add_property/new_property_controller_legacy.dart';
import 'package:rent_home/data/models/booking_history_response_model.dart';
import 'package:rent_home/ui/screens_renter/history/history_description/property_review_controller.dart';

class MyReviewSection extends StatelessWidget {
  const MyReviewSection({
    super.key,
    required this.propertyId,
    required this.bookingData,
  });

  final int propertyId;
  final BookingHistoryData bookingData;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PropertyReviewController>();
    final UserController userController = Get.put(UserController());
    final myReview = controller.propertyReviewResponse.value.data?.myReview;
    final reviewController = TextEditingController();
    double rating = 0.0;

    if (myReview == null) return const SizedBox.shrink();

    final filtered = myReview.where((e) => e.brPropId == propertyId);

    if (filtered.isEmpty) return const SizedBox.shrink();

    final review = filtered.last;

    return Column(
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            const Text(
              'Your Review',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: () {
                // show dialog to update review
                reviewController.text = controller
                        .propertyReviewResponse.value.data?.myReview
                        ?.where((e) => e.brPropId == propertyId)
                        .last
                        .brDesc ??
                    "";

                rating = double.parse(controller
                        .propertyReviewResponse.value.data?.myReview
                        ?.where((e) => e.brPropId == propertyId)
                        .last
                        .brRating ??
                    "0");
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                        backgroundColor: kCream,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.all(20),
                        content: SingleChildScrollView(
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            Image.asset(
                              'assets/rate_us.jpg', // Placeholder for rating icons similar to the design
                              height: 200,
                            ),
                            const SizedBox(height: 15),
                            const Text(
                              "Enjoyed the stay?",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "Rate the property and share your experience",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 20),
                            RatingBar.builder(
                              initialRating: rating,
                              minRating: 1,
                              direction: Axis.horizontal,
                              allowHalfRating: false,
                              itemCount: 5,
                              itemPadding:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              itemBuilder: (context, _) => const Icon(
                                Icons.star,
                                color: kprimaryColor,
                              ),
                              onRatingUpdate: (ra) {
                                rating = ra;
                              },
                            ),
                            const SizedBox(height: 20),
                            //review input

                            Column(
                              children: [
                                TextField(
                                  controller: reviewController,
                                  maxLines: 4,
                                  decoration: InputDecoration(
                                    hintText: "Write a review",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: () {
                                    // send review to the server
                                    if (rating == 0) {
                                      Get.snackbar(
                                          "Error", "Please rate the property",
                                          snackPosition: SnackPosition.BOTTOM,
                                          backgroundColor:
                                              Colors.red.withOpacity(0.6),
                                          colorText: Colors.white);
                                      return;
                                    }

                                    final review = reviewController.text;
                                    final propertyId = bookingData.bookPropId;
                                    final reviewData = {
                                      "propertyId": propertyId,
                                      "rating": rating,
                                      "description": review,
                                      "reviewId": controller
                                          .propertyReviewResponse
                                          .value
                                          .data
                                          ?.myReview
                                          ?.where(
                                              (e) => e.brPropId == propertyId)
                                          .last
                                          .brId,
                                    };
                                    userController.addReview(reviewData).then(
                                        (_) => controller
                                            .getPropertyReviews(propertyId!));

                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    fixedSize: const Size(double.maxFinite, 40),
                                    backgroundColor: kprimaryColor,
                                    foregroundColor: kcontentColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text("Update Review"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text(
                                    "Not Now",
                                    style: TextStyle(color: kprimaryColor),
                                  ),
                                ),
                              ],
                            ),
                          ]),
                        ));
                  },
                );
              },
              icon: const Icon(Icons.edit),
              color: kprimaryColor,
            )
          ],
        ),
        RatingBarIndicator(
          rating: double.parse(review.brRating ?? "0"),
          itemCount: 5,
          itemSize: 24,
          itemBuilder: (_, __) => const Icon(Icons.star, color: kprimaryColor),
        ),
        const SizedBox(height: 8),
        Text(
          review.brDesc ?? "",
          style: const TextStyle(color: Colors.black),
        ),
      ],
    );
  }
}
