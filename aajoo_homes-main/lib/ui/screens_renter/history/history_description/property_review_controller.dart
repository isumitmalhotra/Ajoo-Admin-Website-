import 'dart:io';

import 'package:get/get.dart';
import 'package:rent_home/data/models/property_review_response_model.dart';
import 'package:rent_home/service/property_service.dart';

class PropertyReviewController extends GetxController {
  RxBool isLoading = false.obs;
  Rx<ReviewResponse> propertyReviewResponse =
      ReviewResponse(success: false, message: '', data: ReviewData()).obs;
  final PropertyService _propertyService = PropertyService();

  Future<void> getPropertyReviews(int id) async {
    isLoading.value = true;
    final response = await _propertyService.getPropertyReview(id);
    propertyReviewResponse.value = response;
    isLoading.value = false;
  }

  Future<void> likeReview(int id) async {
    await _propertyService.likeReview(id);
  }

  Future<void> dislikeReview(int id) async {
    await _propertyService.dislikeReview(id);
  }
}
