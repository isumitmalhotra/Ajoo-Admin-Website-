import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/controller/host_controller.dart';
import 'package:rent_home/models/property_review_response_model.dart';
import 'package:rent_home/service/property_service.dart';

class NewPropertyController extends GetxController {
  RxBool isLoading = false.obs;
  RxString propertyName = ''.obs;
  RxString propertyDescription = ''.obs;
  RxString address = ''.obs;
  RxString price = ''.obs;
  RxString minPrice = ''.obs;
  RxString category = ''.obs;
  RxString city = ''.obs;
  RxString state = ''.obs;
  RxString country = ''.obs;
  RxString pincode = ''.obs;
  RxList<String> amenities = <String>[].obs;
  RxString inTime = ''.obs;
  RxString outTime = ''.obs;
  RxString contact = ''.obs;
  RxString email = ''.obs;
  RxDouble latitude = 0.0.obs;
  RxDouble longitude = 0.0.obs;
  RxInt isPetAllowed = 0.obs;
  Rx<List<File>> image = Rx<List<File>>([]);
  RxInt isSmokingAllowed = 0.obs;
  RxString weeklyMinPrice = ''.obs;
  RxString weeklyMaxPrice = ''.obs;
  RxString monthlySecurityAmount = ''.obs;
  // Luxury property flag
  RxBool isLuxury = false.obs;

  // New fields for sharing property
  RxInt bedsNumber = 0.obs;

  // House rules
  RxString propRule = ''.obs;

  // Property documents
  Rx<File?> fireAndSafetyNOC = Rx<File?>(null);
  Rx<File?> jamaBandhiDoc = Rx<File?>(null);
  Rx<File?> nocDocument = Rx<File?>(null);
  Rx<File?> policeVerificationDoc = Rx<File?>(null);

  Rx<ReviewResponse> propertyReviewResponse =
      ReviewResponse(success: false, message: '', data: ReviewData()).obs;
  final PropertyService _propertyService = PropertyService();

  Future<void> getPropertyReviews(int id) async {
    isLoading.value = true;
    final response = await _propertyService.getPropertyReview(id);
    propertyReviewResponse.value = response;
    // print('Property Review Response: ${propertyReviewResponse.value.toJson()}');
    print('Property Review Response: ${propertyReviewResponse.value.data}');
    isLoading.value = false;
  }

  Future<void> likeReview(int id) async {
    await _propertyService.likeReview(id);
  }

  Future<void> dislikeReview(int id) async {
    await _propertyService.dislikeReview(id);
  }

  Map<String, dynamic> _buildBaseFormData() {
    return {
      'property_name': propertyName.value,
      'property_desc': propertyDescription.value,
      'property_address': address.value,
      'property_price': price.value,
      'property_mini_price': minPrice.value,
      'property_category': category.value,
      'property_city': city.value,
      'property_state': 1, //state.value,
      'property_contry': country.value, //country.value,
      'property_zip': pincode.value,
      'property_latitude': latitude.value.toString(),
      'property_longitude': longitude.value.toString(),
      'property_inTime': inTime.value,
      'property_outTime': outTime.value,
      'property_contact': contact.value,
      'property_email': email.value,
      'property_isPetAllow': isPetAllowed.value.toString(),
      'property_isSmoke': isSmokingAllowed.value.toString(),
      'property_amenities': amenities.join(','),
      'weeklyMinPrice': weeklyMinPrice.value,
      'weeklyMaxPrice': weeklyMaxPrice.value,
      'monthlySecurity': monthlySecurityAmount.value,
      'propDetail_no_of_beds': bedsNumber.value.toString(),

      'bedsNumber': bedsNumber.value.toString(),
      // House rules
      'PropRule': propRule.value,
      // Luxury boolean as requested
      'is_luxury': isLuxury.value,
    };
  }

  Future<void> saveProperty() async {
    isLoading.value = true;
    final formData = _buildBaseFormData();

    // Prepare property documents
    List<File> allPropertyDocs = [];
    if (fireAndSafetyNOC.value != null) {
      allPropertyDocs.add(fireAndSafetyNOC.value!);
    }
    if (jamaBandhiDoc.value != null) allPropertyDocs.add(jamaBandhiDoc.value!);
    if (nocDocument.value != null) allPropertyDocs.add(nocDocument.value!);
    if (policeVerificationDoc.value != null) {
      allPropertyDocs.add(policeVerificationDoc.value!);
    }

    print('Form Data: $formData');
    print('Property Images: ${image.value.length}');
    print('Property Documents: ${allPropertyDocs.length}');

    final res = await _propertyService.addProperties(
      image.value,
      formData,
      propertyDocs: allPropertyDocs.isNotEmpty ? allPropertyDocs : null,
    );
    final hostController = Get.find<HostController>();
    if (res) {
      hostController.getHostProperties();

      Get.snackbar('Success', 'Property added successfully',
          backgroundColor: Colors.green, colorText: Colors.white);
    } else {
      Get.snackbar('Error', 'Failed to add property');
    }
    isLoading.value = false;
  }

  Future<void> updateProperty(int propertyId) async {
    isLoading.value = true;
    final formData = _buildBaseFormData();
    formData['propertyId'] = propertyId; // trigger update behavior on backend

    // Collect images & docs (reuse logic but avoid duplicating code)
    List<File> allPropertyDocs = [];
    if (fireAndSafetyNOC.value != null) {
      allPropertyDocs.add(fireAndSafetyNOC.value!);
    }
    if (jamaBandhiDoc.value != null) allPropertyDocs.add(jamaBandhiDoc.value!);
    if (nocDocument.value != null) allPropertyDocs.add(nocDocument.value!);
    if (policeVerificationDoc.value != null) {
      allPropertyDocs.add(policeVerificationDoc.value!);
    }

    print('Update PropertyId: $propertyId');
    print('Update Form Data: $formData');

    final res = await _propertyService.addProperties(
      image.value,
      formData,
      propertyDocs: allPropertyDocs.isNotEmpty ? allPropertyDocs : null,
    );
    final hostController = Get.find<HostController>();
    if (res) {
      hostController.getHostProperties();
      Get.snackbar('Success', 'Property updated successfully',
          backgroundColor: Colors.green, colorText: Colors.white);
    } else {
      Get.snackbar('Error', 'Failed to update property');
    }
    isLoading.value = false;
  }
}
