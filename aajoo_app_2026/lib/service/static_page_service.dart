import 'package:dio/dio.dart';
import 'package:rent_home/models/aajoo_about_model.dart';
import 'package:rent_home/models/faq_reponse_model.dart';
import 'package:rent_home/models/safety_data_model.dart';
import 'package:rent_home/models/terms_condition_user_response_model.dart';

class StaticPageService {
  final Dio _dio = Dio();
  final String baseUrl = 'https://aajaodev.onrender.com/';
  String? _token;

  StaticPageService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.contentType = 'application/json';
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        return handler.next(options);
      },
    ));
  }

  Future<AajooModel> getAboutUsData() async {
    try {
      final response = await _dio.get("common/about-us");
      print(response.data);
      return AajooModel.fromJson(response.data);
    } catch (err) {
      rethrow;
    }
  }

  Future<SafetyDataModel> getSafetyData() async {
    try {
      final response = await _dio.get("common/safety");
      return SafetyDataModel.fromJson(response.data);
    } catch (err) {
      rethrow;
    }
  }

  Future<FaqResponse> getFaqData() async {
    try {
      final response = await _dio.get("common/faq");
      return FaqResponse.fromJson(response.data);
    } catch (err) {
      rethrow;
    }
  }

  Future<TermsAndCondionResponse> getTermsAndCondtionData(
      {bool isHost = false}) async {
    try {
      final endpoint =
          isHost ? "common/term-condition-host" : "common/term-condition-user";
      final response = await _dio.get(endpoint);
      return TermsAndCondionResponse.fromJson(response.data);
    } catch (err) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPrivacyPolicy(bool isHost) async {
    try {
      final response = await _dio.post("common/privacy-policy", data: {
        "isHost": isHost,
      });
      return response.data;
    } catch (err) {
      rethrow;
    }
  }
}
