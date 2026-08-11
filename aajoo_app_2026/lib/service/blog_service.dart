import 'package:dio/dio.dart';
import 'package:rent_home/data/ApiConstants.dart';
import 'package:rent_home/data/source/remote/dio_config.dart';
import 'package:rent_home/models/blog_model.dart';

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

  /// Published posts, newest first. Returns an empty list rather than throwing:
  /// a blog outage should cost the home screen one section, not the screen.
  Future<List<BlogPost>> getBlogs({int limit = 5}) async {
    try {
      final response = await _dio.post('/blog/search', data: {});
      final body = response.data;
      if (body is! Map || body['success'] != true) return const [];

      final data = body['data'];
      if (data is! List) return const [];

      return data
          .whereType<Map>()
          .map((e) => BlogPost.fromJson(Map<String, dynamic>.from(e)))
          .where((b) => b.title.isNotEmpty)
          .take(limit)
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
