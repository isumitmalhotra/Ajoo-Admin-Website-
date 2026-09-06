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
  /// The first picture — the card thumbnail.
  final String? imageUrl;

  /// Every picture on the post, oldest first.
  ///
  /// A post used to carry one cover; it carries a gallery now, and the post
  /// screen shows it as a slider. The API still sends the flattened
  /// "blogImg.afile_path" for the first one, so an older build keeps working.
  final List<String> images;

  /// The stay a property post is about.
  ///
  /// The API sends both — blog_property_id, and the name resolved alongside it
  /// — and this model dropped them, so a guide written about a particular
  /// house had no way to reach the house. Same gap the web had.
  final int? propertyId;
  final String? propertyName;

  const BlogPost({
    required this.id,
    required this.title,
    required this.shortDesc,
    required this.longDesc,
    this.imageUrl,
    this.images = const [],
    this.propertyId,
    this.propertyName,
  });

  factory BlogPost.fromJson(Map<String, dynamic> json) {
    final raw = json['images'];
    final gallery = raw is List
        ? raw
            .map((e) => (e is Map ? e['url'] : e)?.toString().trim() ?? '')
            .where((u) => u.isNotEmpty)
            .toList()
        : <String>[];
    final img = json['blogImg.afile_path'] ??
        (json['blogImg'] is Map ? json['blogImg']['afile_path'] : null);
    final url = gallery.isNotEmpty ? gallery.first : img?.toString().trim();
    return BlogPost(
      id: int.tryParse(json['blog_id']?.toString() ?? '') ?? 0,
      title: (json['blog_title'] ?? '').toString().trim(),
      shortDesc: (json['blog_short_desc'] ?? '').toString().trim(),
      longDesc: (json['blog_long_desc'] ?? '').toString().trim(),
      imageUrl: (url == null || url.isEmpty) ? null : url,
      images: gallery.isNotEmpty
          ? gallery
          : (url == null || url.isEmpty) ? const [] : [url],
      propertyId: int.tryParse(json['blog_property_id']?.toString() ?? ''),
      propertyName: (json['blog_property_name']?.toString().trim().isEmpty ?? true)
          ? null
          : json['blog_property_name'].toString().trim(),
    );
  }
}
