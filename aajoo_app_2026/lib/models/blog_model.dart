/// A published blog post, as /blog/search returns it.
///
/// The endpoint returns raw rows, so the joined image arrives under the
/// flattened key "blogImg.afile_path" rather than nested — and it is null for
/// every post today, since none of them have an image attached. The UI shows a
/// placeholder rather than pretending otherwise.
class BlogPost {
  final int id;
  final String title;
  final String shortDesc;
  final String longDesc;
  final String? imageUrl;

  const BlogPost({
    required this.id,
    required this.title,
    required this.shortDesc,
    required this.longDesc,
    this.imageUrl,
  });

  factory BlogPost.fromJson(Map<String, dynamic> json) {
    final img = json['blogImg.afile_path'] ??
        (json['blogImg'] is Map ? json['blogImg']['afile_path'] : null);
    final url = img?.toString().trim();
    return BlogPost(
      id: int.tryParse(json['blog_id']?.toString() ?? '') ?? 0,
      title: (json['blog_title'] ?? '').toString().trim(),
      shortDesc: (json['blog_short_desc'] ?? '').toString().trim(),
      longDesc: (json['blog_long_desc'] ?? '').toString().trim(),
      imageUrl: (url == null || url.isEmpty) ? null : url,
    );
  }
}
