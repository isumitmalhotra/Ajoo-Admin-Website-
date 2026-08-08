import 'package:get/get.dart';
import 'package:rent_home/models/amenities_model.dart';
import 'package:rent_home/models/category_response_model.dart';
import 'package:rent_home/models/doc_type_response_model.dart';
import 'package:rent_home/models/tags_model.dart';
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
      print('Amenities fetched: ${response.toJson()}');
    } catch (e, stackTrace) {
      print('Error fetching amenities: $e');
      print('Stack trace: $stackTrace');
      amenities.value = null;
    }
  }

  Future<void> fetchTags() async {
    try {
      final response = await commonService.getTags();
      tags.value = response;
      print('Tags fetched: ${response.toJson()}');
    } catch (e, stackTrace) {
      print('Error fetching tags: $e');
      print('Stack trace: $stackTrace');
      tags.value = null;
    }
  }

  Future<void> fetchCategories() async {
    try {
      final response = await commonService.getCategories();
      cats.value = response;
      print("cats Fetched : ${response.toJson()}");
    } catch (err) {
      cats.value = null;
    }
  }

  Future<void> fetchDocTypes() async {
    try {
      print('Fetching document types...');
      isLoading.value = true; 
      final response = await commonService.getDocTypes();
      docTypes.value = response;
      print('Document types fetched: ${response.toJson()}');
    } catch (e, stackTrace) {
      print('Error fetching document types: $e');
      print('Stack trace: $stackTrace');
      docTypes.value = null;
    }
    finally{
      isLoading.value = false;
    }
  }
}
