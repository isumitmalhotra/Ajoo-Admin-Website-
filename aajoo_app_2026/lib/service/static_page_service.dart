import 'package:dio/dio.dart';
import 'package:rent_home/models/aajoo_about_model.dart';
import 'package:rent_home/models/faq_reponse_model.dart';
import 'package:rent_home/models/safety_data_model.dart';
import 'package:rent_home/models/terms_condition_user_response_model.dart';
import 'package:rent_home/data/ApiConstants.dart';

class StaticPageService {
  final Dio _dio = Dio();
  final String baseUrl = '${Apiconstants.baseUrl}/';
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

  /// Editor overrides for a CMS page, the same source the website reads.
  ///
  /// Never throws and never returns null: a page built on this renders its
  /// spec defaults and is complete without the network. Blank overrides are
  /// dropped — a field saved as an empty string would otherwise erase a
  /// heading with nothing on the page to explain why.
  Future<Map<String, String>> getCmsPage(String page) async {
    try {
      final response = await _dio.get("public/cms/$page");
      final data = response.data is Map ? response.data['data'] : null;
      if (data is Map) {
        final out = <String, String>{};
        data.forEach((k, v) {
          final s = v?.toString() ?? '';
          if (s.trim().isNotEmpty) out[k.toString()] = s;
        });
        return out;
      }
    } catch (_) {
      // The page keeps its defaults. Failing here would blank About over a
      // CMS problem, which is worse than ignoring the CMS.
    }
    return const {};
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
