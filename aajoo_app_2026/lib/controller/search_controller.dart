import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/models/search_property_model.dart';
import 'package:rent_home/service/home_page_search_service.dart';

class HomeSearchController extends GetxController {
  Rx<bool> isLoading = false.obs;
  Rx<SearchResponse?> searchResponse = Rx<SearchResponse?>(null);
  Rx<SearchResponse?> preBookingResponse = Rx<SearchResponse?>(null);
  Rx<String> query = ''.obs;
  final HomePageSearchService _homePageSearchService = HomePageSearchService();

  Future<void> searchProperty() async {
    isLoading.value = true;
    try {
      final response = await _homePageSearchService.searchProperty(query.value);
      searchResponse.value = response;
    } catch (err) {
      print(err);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getPreBooking({bool isLuxury = false}) async {
    isLoading.value = true;
    try {
      final response =
          await _homePageSearchService.getPreBooking(isLuxury: isLuxury);
      preBookingResponse.value = response;
    } catch (err) {
      print(err);
    } finally {
      isLoading.value = false;
    }
  }

  void showSnackbar(String title, String message, bool isError) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: isError ? Colors.red[100] : Colors.green[100],
      colorText: isError ? Colors.red[900] : Colors.green[900],
      duration: const Duration(seconds: 3),
    );
  }
}
