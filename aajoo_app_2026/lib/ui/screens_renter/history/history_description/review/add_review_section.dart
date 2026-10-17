import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/controller/alert_dialog.dart';
import 'package:rent_home/controller/user_controller.dart';

import 'package:rent_home/ui/screens_renter/history/history_description/property_review_controller.dart';

/// "Add Review" under a stay the guest has finished.
///
/// Stateful on purpose. This was a StatelessWidget carrying `double rating = 0`
/// and a TextEditingController as instance fields, which breaks in two ways
/// that both end at the same server error — "rating must be between 1 and 5",
/// seen on the live Play build on 17 October:
///
///   * the star bar opened at `initialRating: 2.0` while the field it wrote to
///     was still 0, so the screen showed two stars and the payload carried
///     none. A guest who accepted the default sent 0 and was refused;
///   * a StatelessWidget is rebuilt whenever its parent rebuilds, and this one
///     sits under the review list it reloads. Each rebuild threw away the
///     instance holding the chosen rating and the typed text and made a fresh
///     one back at 0, so a rating set a moment earlier was gone by the time
///     Submit was pressed.
///
/// Keeping both in [State] fixes the second, and seeding `_rating` from the
/// same constant the bar opens at fixes the first — the number shown and the
/// number sent are now one value.
class AddReviewSection extends StatefulWidget {
  const AddReviewSection({super.key, required this.propertyId});

  final int propertyId;

  @override
  State<AddReviewSection> createState() => _AddReviewSectionState();
}

class _AddReviewSectionState extends State<AddReviewSection> {
  /// What the bar opens at, and therefore what an untouched form submits.
  static const double _initialRating = 2.0;

  final userController = Get.find<UserController>();
  final propertyController = Get.find<PropertyReviewController>();
  final _reviewController = TextEditingController();

  double _rating = _initialRating;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final description = _reviewController.text.trim();

    // The server requires a description too, and refuses an empty one with
    // another raw exception toast. Ask for it here instead.
    if (description.isEmpty) {
      showAlert(
        'Add a few words',
        'Tell other guests what the stay was like before you submit.',
        true,
      );
      return;
    }

    await userController.addReview({
      "propertyId": widget.propertyId,
      "rating": _rating,
      "description": description,
    });
    propertyController.getPropertyReviews(widget.propertyId);
  }

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
          initialRating: _initialRating,
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: true,
          itemCount: 5,
          itemSize: 30,
          itemBuilder: (_, __) => const Icon(Icons.star, color: kprimaryColor),
          onRatingUpdate: (r) => _rating = r,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _reviewController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Write your review...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Obx(() => ElevatedButton(
              onPressed: userController.isLoading.value ? null : _submit,
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
