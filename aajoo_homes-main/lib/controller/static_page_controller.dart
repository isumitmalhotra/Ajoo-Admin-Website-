import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/controller/alert_dialog.dart';
import 'package:rent_home/data/models/aajoo_about_model.dart';
import 'package:rent_home/data/models/faq_reponse_model.dart';
import 'package:rent_home/data/models/terms_condition_user_response_model.dart';
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
      print(response);
    } catch (err) {
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
      print(response);
    } catch (err) {
      showSnackbar("Error ", "Something went Wrong", true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getTermsData() async {
    try {
      isLoading.value = true;
      final response = await _staticPageService.getTermsAndCondtionData();
      terms.value = response;
      print(response);
    } catch (err) {
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
      showSnackbar("Error ", "Something went Wrong ${err}", true);
    } finally {
      isLoading.value = false;
    }
  }

  void showSnackbar(String title, String message, bool isError) {
    showAlert(title, message, isError);
  }
}
