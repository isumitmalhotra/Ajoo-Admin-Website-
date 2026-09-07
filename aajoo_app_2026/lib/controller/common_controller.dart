import 'package:get/get.dart';
import 'package:rent_home/models/amenities_model.dart';
import 'package:rent_home/models/category_response_model.dart';
import 'package:rent_home/models/doc_type_response_model.dart';
import 'package:rent_home/models/tags_model.dart';
import 'package:rent_home/service/common_service.dart';

import 'package:rent_home/utils/app_log.dart';
class CommonController extends GetxController {
  final CommonService commonService = CommonService();
  final Rx<AmenitiesResponse?> amenities = Rx<AmenitiesResponse?>(null);
  final Rx<TagsResponse?> tags = Rx<TagsResponse?>(null);
  final Rx<CategoryResponse?> cats = Rx<CategoryResponse?>(null);
  final Rx<DocTypeResponse?> docTypes = Rx<DocTypeResponse?>(null);
  RxBool isLoading = false.obs;
  @override
  void onInit() {
    super.onInit();
    fetchAmenities();
    fetchTags();
    fetchCategories();
    fetchDocTypes();
  }

  Future<void> fetchAmenities() async {
    try {
      final response = await commonService.getAmenities();
      amenities.value = response;
      appLog('Amenities fetched: ${response.toJson()}');
    } catch (e, stackTrace) {
      appLog('Error fetching amenities: $e');
      appLog('Stack trace: $stackTrace');
      amenities.value = null;
    }
  }

  Future<void> fetchTags() async {
    try {
      final response = await commonService.getTags();
      tags.value = response;
      appLog('Tags fetched: ${response.toJson()}');
    } catch (e, stackTrace) {
      appLog('Error fetching tags: $e');
      appLog('Stack trace: $stackTrace');
      tags.value = null;
    }
  }

  Future<void> fetchCategories() async {
    try {
      final response = await commonService.getCategories();
      cats.value = response;
      appLog("cats Fetched : ${response.toJson()}");
    } catch (err) {
      cats.value = null;
    }
  }

  Future<void> fetchDocTypes() async {
    try {
      appLog('Fetching document types...');
      isLoading.value = true; 
      final response = await commonService.getDocTypes();
      docTypes.value = response;
      appLog('Document types fetched: ${response.toJson()}');
    } catch (e, stackTrace) {
      appLog('Error fetching document types: $e');
      appLog('Stack trace: $stackTrace');
      docTypes.value = null;
    }
    finally{
      isLoading.value = false;
    }
  }
}
