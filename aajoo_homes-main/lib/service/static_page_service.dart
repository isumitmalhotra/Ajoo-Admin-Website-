import 'package:rent_home/data/source/remote/api_client/api_client.dart';
import 'package:rent_home/data/models/aajoo_about_model.dart';
import 'package:rent_home/data/models/faq_reponse_model.dart';
import 'package:rent_home/data/models/safety_data_model.dart';
import 'package:rent_home/data/models/terms_condition_user_response_model.dart';

class StaticPageService {
  final ApiClient apiClient = ApiClient();
  StaticPageService();

  Future<AajooModel> getAboutUsData() async {
    try {
      final response = await apiClient.get("/common/about-us");
      return AajooModel.fromJson(response);
    } catch (err) {
      throw err;
    }
  }

  Future<SafetyDataModel> getSafetyData() async {
    try {
      final response = await apiClient.get("/common/safety");
      return SafetyDataModel.fromJson(response);
    } catch (err) {
      throw err;
    }
  }

  Future<FaqResponse> getFaqData() async {
    try {
      final response = await apiClient.get("/common/faq");
      return FaqResponse.fromJson(response);
    } catch (err) {
      throw err;
    }
  }

  Future<TermsAndCondionResponse> getTermsAndCondtionData() async {
    try {
      final response = await apiClient.get("/common/term-condition-user");
      return TermsAndCondionResponse.fromJson(response);
    } catch (err) {
      throw err;
    }
  }

  Future<Map<String, dynamic>> getPrivacyPolicy(bool isHost) async {
    try {
      final response = await apiClient.post("/common/privacy-policy", data: {
        "isHost": isHost,
      });
      return response;
    } catch (err) {
      throw err;
    }
  }
}
