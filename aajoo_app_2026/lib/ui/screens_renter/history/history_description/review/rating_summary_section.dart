import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/ui/screens_renter/history/history_description/property_review_controller.dart';

class RatingSummarySection extends StatelessWidget {
  RatingSummarySection({super.key});

  final controller = Get.find<PropertyReviewController>();

  @override
  Widget build(BuildContext context) {
    final data = controller.propertyReviewResponse.value.data;

    if (data == null) return const SizedBox.shrink();

    return Column(
      children: [
        Text(
          "${data.averageRating?.substring(0, 3) ?? '0'} ★",
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: kprimaryColor,
          ),
        ),
        const Text("Rating are from people who stayed here before"),
        Column(
          children: [5, 4, 3, 2, 1].map((rating) {
            final count = controller.propertyReviewResponse.value.data
                    ?.allRatings?["$rating"] ??
                0;
            final total =
                controller.propertyReviewResponse.value.data?.reviews?.length ??
                    1;
            final percentage = (count / total) * 100;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Text("$rating",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        Container(
                          height: 10,
                          width: MediaQuery.of(context).size.width *
                              (percentage / 100),
                          decoration: BoxDecoration(
                            color: kprimaryColor,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text("$count reviews"),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
