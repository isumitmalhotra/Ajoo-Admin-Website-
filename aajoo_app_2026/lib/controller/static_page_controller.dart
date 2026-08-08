import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/models/aajoo_about_model.dart';
import 'package:rent_home/models/faq_reponse_model.dart';
import 'package:rent_home/models/terms_condition_user_response_model.dart';
import 'package:rent_home/service/static_page_service.dart';

class StaticPageController extends GetxController {
  final _staticPageService = StaticPageService();
  Rx<AajooModel?> aboutUsData = Rx<AajooModel?>(null);
  Rx<FaqResponse?> faqData = Rx<FaqResponse?>(null);
  Rx<TermsAndCondionResponse?> terms = Rx<TermsAndCondionResponse?>(null);
  Rx<Map<String, dynamic>?> privacyPolicy = Rx<Map<String, dynamic>?>(null);
  Rx<bool> isLoading = false.obs;

  Future<void> getAboutUsData() async {
    try {
      isLoading.value = true;
      final response = await _staticPageService.getAboutUsData();
      aboutUsData.value = response;
    } catch (err) {
      print(err);
      showSnackbar("Error ", "Something went Wrong", true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getFaqData() async {
    try {
      isLoading.value = true;
      final response = await _staticPageService.getFaqData();
      faqData.value = response;
    } catch (err) {
      print(err);
      showSnackbar("Error ", "Something went Wrong", true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getTermsData({bool isHost = false}) async {
    try {
      isLoading.value = true;
      final response =
          await _staticPageService.getTermsAndCondtionData(isHost: isHost);
      terms.value = response;
    } catch (err) {
      print(err);
      showSnackbar("Error ", "Something went Wrong", true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getPrivacyPolicyData(bool isHost) async {
    try {
      isLoading.value = true;
      final response = await _staticPageService.getPrivacyPolicy(isHost);
      privacyPolicy.value = response;
    } catch (err) {
      print(err);
      showSnackbar("Error ", "Something went Wrong", true);
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
