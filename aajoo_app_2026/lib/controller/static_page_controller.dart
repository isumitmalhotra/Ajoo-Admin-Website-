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

  /// Did the last FAQ fetch fail?
  ///
  /// Without this the screen cannot tell "the server has no FAQs" from "we
  /// never reached the server", and has to guess — it guessed the first, so a
  /// cold-start timeout rendered as "No questions here yet" while the server
  /// held a full list. A failure is not an empty list and must not claim to
  /// be one.
  Rx<bool> faqError = false.obs;

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
      faqError.value = false;
      final response = await _staticPageService.getFaqData();
      faqData.value = response;
    } catch (err) {
      print(err);
      faqError.value = true;
      // No snackbar. The FAQ list is a secondary section of a page whose main
      // job — phone, chat, email — works regardless; a red toast over a
      // working support page told the guest something was broken when the
      // thing they came for was fine. The section says so itself instead.
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
