import 'package:get/get.dart';
import 'package:rent_home/data/models/amenities_model.dart';
import 'package:rent_home/data/models/category_response_model.dart';
import 'package:rent_home/data/models/doc_type_response_model.dart';
import 'package:rent_home/data/models/tags_model.dart';
import 'package:rent_home/service/common_service.dart';

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
    } catch (e) {
      amenities.value = null;
    }
  }

  Future<void> fetchTags() async {
    try {
      final response = await commonService.getTags();
      tags.value = response;
    } catch (e) {
      tags.value = null;
    }
  }

  Future<void> fetchCategories() async {
    try {
      final response = await commonService.getCategories();
      cats.value = response;
    } catch (err) {
      cats.value = null;
    }
  }

  Future<void> fetchDocTypes() async {
    try {
      isLoading.value = true;
      final response = await commonService.getDocTypes();
      docTypes.value = response;
    } catch (e) {
      docTypes.value = null;
    } finally {
      isLoading.value = false;
    }
  }
}
