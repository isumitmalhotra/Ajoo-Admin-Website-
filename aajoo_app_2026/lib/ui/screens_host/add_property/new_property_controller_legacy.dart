import 'dart:io';
import 'dart:convert';

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
  // Selected category IDs (mapped from the type chips) → posted as
  // property_category[] so the listing links to admin categories + filters.
  RxList<int> categoryIds = <int>[].obs;
  // Selected amenity + tag IDs from the admin-managed lists (/common/*) →
  // posted as property_amenities[] / property_tag[] (join tables).
  RxList<int> amenityIds = <int>[].obs;
  RxList<int> tagIds = <int>[].obs;
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

  // ---- Host onboarding (H1) parity fields — mirror the web wizard so the
  // backend stores the same 22 columns + typed docs. Empty values are tolerated
  // by the backend schema (number fields transform "" → undefined).
  RxString propertyType = ''.obs; // Entire home / Private room / PG / Villa ...
  RxString bookingPref = ''.obs; // instant | request
  RxString areaLocality = ''.obs;
  RxString landmark = ''.obs;
  RxString floorNo = ''.obs;
  RxString bathrooms = ''.obs;
  RxString securityDeposit = ''.obs;
  RxString weekendPrice = ''.obs;
  RxString extraGuestCharge = ''.obs;
  RxString cleaningFee = ''.obs;
  RxString minBookingAmount = ''.obs;
  RxString videoUrl = ''.obs;
  RxBool coupleFriendly = false.obs;
  RxBool localIdAllowed = false.obs;
  RxString quietHours = ''.obs;
  RxString ownershipType = ''.obs;
  RxBool selfDeclaration = false.obs;

  // PG sub-form (when propertyType is a PG/hostel)
  RxBool isPgSelected = false.obs;
  RxString pgRoomType = ''.obs;
  RxString pgMonthlyRent = ''.obs;
  RxString pgDeposit = ''.obs;
  RxBool pgFoodIncluded = false.obs;
  RxString pgGenderPref = ''.obs;
  RxString pgCurfew = ''.obs;
  RxString pgVisitorPolicy = ''.obs;
  RxString pgLockInMonths = ''.obs;

  // Party sub-form (isPartySelected above gates it)
  RxString partyMaxPeople = ''.obs;
  RxString partyCharges = ''.obs;
  RxBool partyLoudMusic = false.obs;
  RxString partyEndTime = ''.obs;

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
      // Array → Dio sends repeated property_category fields → backend links them.
      'property_category': categoryIds.toList(),
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
      // Admin amenity IDs → join table (so the detail page's amenities populate).
      'property_amenities': amenityIds.toList(),
      // Admin tag IDs → property_tag join.
      'property_tag': tagIds.toList(),
      // Per-property amenities as JSON (what the detail page renders, like web).
      'property_amenities_json': jsonEncode(
          amenities.map((a) => {'key': a, 'label': a, 'qty': 1}).toList()),
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
      // ---- H1 parity fields (mirror the web host wizard) ----
      'property_type': propertyType.value,
      'category_tier': isLuxury.value ? 'LUX' : 'Standard',
      'booking_pref': bookingPref.value,
      'area_locality': areaLocality.value,
      'landmark': landmark.value,
      'floor_no': floorNo.value,
      'bathrooms': bathrooms.value,
      'security_deposit': securityDeposit.value,
      'weekend_price': weekendPrice.value,
      'extra_guest_charge': extraGuestCharge.value,
      'cleaning_fee': cleaningFee.value,
      'min_booking_amount': minBookingAmount.value,
      'video_url': videoUrl.value,
      'couple_friendly': coupleFriendly.value,
      'local_id_allowed': localIdAllowed.value,
      'quiet_hours': quietHours.value,
      'ownership_type': ownershipType.value,
      'self_declaration': selfDeclaration.value,
      if (isPgSelected.value)
        'pg_settings_json': jsonEncode({
          'roomType': pgRoomType.value.isEmpty ? null : pgRoomType.value,
          'monthlyRent': _numOrNull(pgMonthlyRent.value),
          'deposit': _numOrNull(pgDeposit.value),
          'foodIncluded': pgFoodIncluded.value,
          'genderPref': pgGenderPref.value.isEmpty ? null : pgGenderPref.value,
          'curfew': pgCurfew.value.isEmpty ? null : pgCurfew.value,
          'visitorPolicy':
              pgVisitorPolicy.value.isEmpty ? null : pgVisitorPolicy.value,
          'lockInMonths': _numOrNull(pgLockInMonths.value),
        }),
      if (isPartySelected.value)
        'party_settings_json': jsonEncode({
          'allow': true,
          'maxPeople': _numOrNull(partyMaxPeople.value),
          'charges': _numOrNull(partyCharges.value),
          'loudMusic': partyLoudMusic.value,
          'endTime': partyEndTime.value.isEmpty ? null : partyEndTime.value,
        }),
    };
  }

  num? _numOrNull(String v) => v.trim().isEmpty ? null : num.tryParse(v.trim());

  Future<ActionResult> saveProperty() async {
    try {
      isLoading.value = true;
      final formData = _buildBaseFormData();

      // 📄 Typed property documents — keep a parallel type list aligned to the
      // files so the backend records each as a typed verification document
      // (mirrors the web wizard's property_doc_types/states arrays).
      final List<File> allPropertyDocs = [];
      final List<String> docTypes = [];
      void addDoc(File? f, String type) {
        if (f != null) {
          allPropertyDocs.add(f);
          docTypes.add(type);
        }
      }

      addDoc(fireAndSafetyNOC.value, 'fire_safety_noc');
      addDoc(jamaBandhiDoc.value, 'ownership');
      addDoc(nocDocument.value, 'noc');
      addDoc(policeVerificationDoc.value, 'police_verification');

      if (isPartySelected.value && partyLicenseDoc.value == null) {
        return ActionResult(
          isSuccess: false,
          message: 'Please upload the Party License document',
        );
      }
      addDoc(partyLicenseDoc.value, 'party_license');

      if (docTypes.isNotEmpty) {
        formData['property_doc_types'] = jsonEncode(docTypes);
        formData['property_doc_states'] =
            jsonEncode(List.filled(docTypes.length, ''));
      }

      final res = await _propertyService.addProperties(
        image.value,
        formData,
        propertyDocs: allPropertyDocs.isNotEmpty ? allPropertyDocs : null,
      );

      if (!res) {
        // Show what the server actually said — a missing field, a rejected
        // value, a rate limit. "Failed to add property" on its own told the
        // host nothing and made this undiagnosable from a bug report.
        return ActionResult(
          isSuccess: false,
          message: _propertyService.lastAddError ?? 'Failed to add property',
        );
      }

      // 🔁 Refresh host properties (side-effect OK)
      final hostController = Get.find<HostController>();
      hostController.getHostProperties();

      // Host submissions go to PENDING admin approval (is_active=0 server-side).
      return ActionResult(
        isSuccess: true,
        message: 'Listing submitted — pending admin approval',
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

    // On UPDATE, never overwrite existing values with blanks. The edit screen
    // doesn't (yet) expose every field, so drop empty strings / empty arrays —
    // Sequelize only updates keys that are present, so absent = keep existing.
    // (propertyId + booleans + real numbers are preserved.)
    formData.removeWhere((k, v) =>
        k != 'propertyId' &&
        (v == null ||
            (v is String && v.trim().isEmpty) ||
            (v is List && v.isEmpty)));

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
