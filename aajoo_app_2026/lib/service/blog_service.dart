import 'package:dio/dio.dart';
import 'package:rent_home/data/ApiConstants.dart';
import 'package:rent_home/data/source/remote/dio_config.dart';
import 'package:rent_home/models/blog_model.dart';
import '../utils/service_log.dart';

/// Blog posts for the home screen (A-25).
///
/// The app had no blog layer at all — the backend has had /blog/search the
/// whole time and nothing on the phone called it.
///
/// Note the endpoint returned an empty list until 2026-08-11: its image join
/// was an INNER JOIN, so every imageless post was dropped and all five of them
/// are imageless. Fixed backend-side in models/tbl_blog.js.
class BlogService {
  final Dio _dio = Dio();

  BlogService() {
    DioConfig.apply(_dio, Apiconstants.baseUrl);
  }

  /// Published PLATFORM posts, newest first — the home screen strip.
  ///
  /// Returns an empty list rather than throwing: a blog outage should cost the
  /// home screen one section, not the screen.
  ///
  /// Sends the scope explicitly. Omitting it also yields platform posts today,
  /// because that is the server's default, but relying on a default to mean
  /// "not the other kind" is how the property posts would eventually leak in
  /// here after someone changes it.
  Future<List<BlogPost>> getBlogs({int limit = 5}) =>
      _search(const {'scope': 'platform'}, limit);

  /// Posts written about ONE stay, shown on that property's page.
  ///
  /// Empty for most properties, and that is the normal case — the section is
  /// left out entirely rather than rendered as an empty heading.
  Future<List<BlogPost>> getPropertyBlogs(int propertyId, {int limit = 6}) {
    if (propertyId <= 0) return Future.value(const []);
    return _search({'scope': 'property', 'propertyId': propertyId}, limit);
  }

  Future<List<BlogPost>> _search(Map<String, dynamic> body, int limit) async {
    try {
      final response = await _dio.post('/blog/search', data: body);
      final payload = response.data;
      if (payload is! Map || payload['success'] != true) return const [];

      final data = payload['data'];
      if (data is! List) return const [];

      return data
          .whereType<Map>()
          .map((e) => BlogPost.fromJson(Map<String, dynamic>.from(e)))
          .where((b) => b.title.isNotEmpty)
          .take(limit)
          .toList();
    } catch (e) {
      logServiceError('blog_service:57', e);
      return const [];
    }
  }
}
