import 'package:dio/dio.dart';
import 'package:rent_home/data/ApiConstants.dart';
import 'package:rent_home/data/source/remote/dio_config.dart';
import 'package:rent_home/models/properties_response_model.dart';

/// The homepage content an admin curates at /admin/cms-home.
///
/// The admin CMS wrote to tbl_cms_pages for months with nothing reading it —
/// on either platform. GET /public/homepage is the read side, added 16 Aug,
/// and this is the phone's half of it so the app and the website show the same
/// featured stays and the same banner instead of diverging.
class HomepageBanner {
  final String title;
  final String desc;
  final String? image;
  final String buttonTitle;
  final String buttonUrl;

  const HomepageBanner({
    required this.title,
    required this.desc,
    this.image,
    required this.buttonTitle,
    required this.buttonUrl,
  });

  /// Only worth rendering with a heading; only worth a button with somewhere
  /// to go. A button that leads nowhere is the dead-control bug this whole
  /// sprint has been removing.
  bool get hasButton => buttonTitle.isNotEmpty && buttonUrl.isNotEmpty;
}

class HomepageContent {
  final String featureTitle;
  final String featureDesc;
  final List<Property> featured;
  final HomepageBanner? banner;

  const HomepageContent({
    required this.featureTitle,
    required this.featureDesc,
    required this.featured,
    this.banner,
  });

  static const empty = HomepageContent(
    featureTitle: '',
    featureDesc: '',
    featured: <Property>[],
  );
}

class HomepageCmsService {
  final Dio _dio = Dio();

  HomepageCmsService() {
    DioConfig.apply(_dio, Apiconstants.baseUrl);
  }

  /// Curated homepage content, or `empty` on any failure. Curation is an
  /// enhancement — the home screen's own rails must render regardless.
  Future<HomepageContent> get() async {
    try {
      final response = await _dio.get('/public/homepage');
      final body = response.data;
      if (body is! Map || body['success'] != true) return HomepageContent.empty;

      final data = body['data'];
      if (data is! Map) return HomepageContent.empty;

      final feature = data['feature'];
      final props = <Property>[];
      if (feature is Map && feature['properties'] is List) {
        for (final raw in (feature['properties'] as List)) {
          if (raw is! Map) continue;
          try {
            props.add(Property.fromJson(Map<String, dynamic>.from(raw)));
          } catch (_) {
            // One malformed listing shouldn't cost the whole strip.
          }
        }
      }

      final bannerJson = data['banner'];
      HomepageBanner? banner;
      if (bannerJson is Map && '${bannerJson['title'] ?? ''}'.isNotEmpty) {
        banner = HomepageBanner(
          title: '${bannerJson['title']}',
          desc: '${bannerJson['desc'] ?? ''}',
          image: bannerJson['image']?.toString(),
          buttonTitle: '${bannerJson['buttonTitle'] ?? ''}',
          buttonUrl: '${bannerJson['buttonUrl'] ?? ''}',
        );
      }

      return HomepageContent(
        featureTitle: feature is Map ? '${feature['title'] ?? ''}' : '',
        featureDesc: feature is Map ? '${feature['desc'] ?? ''}' : '',
        featured: props,
        banner: banner,
      );
    } catch (_) {
      return HomepageContent.empty;
    }
  }
}
