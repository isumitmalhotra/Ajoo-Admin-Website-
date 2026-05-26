import 'dart:io';

import 'package:get/get.dart';
import 'package:rent_home/controller/alert_dialog.dart';
import 'package:rent_home/ui/screens_host/host_controller.dart';
import 'package:rent_home/data/models/action_result.dart';
import 'package:rent_home/data/models/property_review_response_model.dart';
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
  RxInt numberOfBeds = 0.obs;
  RxInt numberOfGuests = 0.obs;
  // Luxury property flag
  RxBool isLuxury = false.obs;

  // House rules
  RxString propRule = ''.obs;

  // Property documents
  Rx<File?> fireAndSafetyNOC = Rx<File?>(null);
  Rx<File?> jamaBandhiDoc = Rx<File?>(null);
  Rx<File?> nocDocument = Rx<File?>(null);
  Rx<File?> policeVerificationDoc = Rx<File?>(null);
  Rx<File?> partyLicenseDoc = Rx<File?>(null);
  RxBool isPartySelected = false.obs;

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
      'propDetail_no_of_beds': numberOfBeds.value.toString(),

      'bedsNumber': numberOfBeds.value.toString(),
      'numberOfGuests': numberOfGuests.value.toString(),
      // House rules
      'PropRule': propRule.value,
      // Luxury boolean as requested
      'is_luxury': isLuxury.value,
    };
  }

  Future<ActionResult> saveProperty() async {
    try {
      isLoading.value = true;
      final formData = _buildBaseFormData();
      // 📄 Prepare property documents
      final List<File> allPropertyDocs = [];
      if (fireAndSafetyNOC.value != null) {
        allPropertyDocs.add(fireAndSafetyNOC.value!);
      }
      if (jamaBandhiDoc.value != null) {
        allPropertyDocs.add(jamaBandhiDoc.value!);
      }
      if (nocDocument.value != null) {
        allPropertyDocs.add(nocDocument.value!);
      }
      if (policeVerificationDoc.value != null) {
        allPropertyDocs.add(policeVerificationDoc.value!);
      }

      if (isPartySelected.value && partyLicenseDoc.value == null) {
        return ActionResult(
          isSuccess: false,
          message: 'Please upload the Party License document',
        );
      }

      if (isPartySelected.value && partyLicenseDoc.value != null) {
        allPropertyDocs.add(partyLicenseDoc.value!);
      }

      final res = await _propertyService.addProperties(
        image.value,
        formData,
        propertyDocs: allPropertyDocs.isNotEmpty ? allPropertyDocs : null,
      );

      if (!res) {
        return ActionResult(
          isSuccess: false,
          message: 'Failed to add property',
        );
      }

      // 🔁 Refresh host properties (side-effect OK)
      final hostController = Get.find<HostController>();
      hostController.getHostProperties();

      return ActionResult(
        isSuccess: true,
        message: 'Property added successfully',
      );
    } catch (e) {
      return ActionResult(
        isSuccess: false,
        message: 'Something went wrong',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProperty(int propertyId) async {
    isLoading.value = true;
    final formData = _buildBaseFormData();
    formData['propertyId'] = propertyId; // trigger update behavior on backend

    // Collect images & docs (reuse logic but avoid duplicating code)
    List<File> allPropertyDocs = [];
    if (fireAndSafetyNOC.value != null)
      allPropertyDocs.add(fireAndSafetyNOC.value!);
    if (jamaBandhiDoc.value != null) allPropertyDocs.add(jamaBandhiDoc.value!);
    if (nocDocument.value != null) allPropertyDocs.add(nocDocument.value!);
    if (policeVerificationDoc.value != null)
      allPropertyDocs.add(policeVerificationDoc.value!);

    final res = await _propertyService.addProperties(
      image.value,
      formData,
      propertyDocs: allPropertyDocs.isNotEmpty ? allPropertyDocs : null,
    );
    final hostController = Get.find<HostController>();
    if (res) {
      hostController.getHostProperties();
      showAlert('Success', 'Property updated successfully', false);
    } else {
      showAlert('Error', 'Failed to update property', true);
    }
    isLoading.value = false;
  }
}
