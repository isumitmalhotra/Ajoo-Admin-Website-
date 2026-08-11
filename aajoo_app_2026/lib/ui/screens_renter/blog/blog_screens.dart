import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/models/blog_model.dart';
import 'package:rent_home/service/blog_service.dart';
import 'package:rent_home/utils/fonts.dart';

/// The blog, on the phone.
///
/// The home screen grew a blog strip with a "See all" that went nowhere and
/// cards that did nothing when tapped — there was no blog screen to go to.
/// These two are it: a list, and a post.
///
/// Post bodies render as TEXT. They are written from the admin dashboard, and
/// the day someone pastes markup into one, an HTML renderer here would render
/// it. Paragraph breaks are kept.
class BlogListScreen extends StatefulWidget {
  const BlogListScreen({super.key});

  @override
  State<BlogListScreen> createState() => _BlogListScreenState();
}

class _BlogListScreenState extends State<BlogListScreen> {
  final _service = BlogService();
  List<BlogPost>? _posts;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _service.getBlogs(limit: 100);
    if (!mounted) return;
    setState(() => _posts = list);
  }

  @override
  Widget build(BuildContext context) {
    final posts = _posts;
    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(
        backgroundColor: kCream,
        elevation: 0,
        foregroundColor: kInk,
        title: Text('Blog',
            style: fraunces(
                fontSize: 18, fontWeight: FontWeight.w600, color: kInk)),
      ),
      body: posts == null
          ? const Center(child: CircularProgressIndicator(color: kIndigo))
          : posts.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No posts published yet — check back soon.',
                      textAlign: TextAlign.center,
                      style: inter(fontSize: 13.5, color: kMuted),
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: kIndigo,
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: posts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (_, i) => _BlogListCard(post: posts[i]),
                  ),
                ),
    );
  }
}

class _BlogListCard extends StatelessWidget {
  final BlogPost post;
  const _BlogListCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Get.to(() => BlogPostScreen(post: post)),
      child: Container(
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kLine),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BlogCover(post: post, height: 150),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.title,
                      style: inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: kInk)),
                  const SizedBox(height: 4),
                  Text(post.shortDesc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: inter(fontSize: 12.5, color: kMuted, height: 1.4)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text('Read more',
                          style: inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: kIndigo600)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward,
                          size: 14, color: kIndigo600),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cover image, or a tinted panel. No post has an image yet, so the panel is
/// the normal case rather than the exception.
class BlogCover extends StatelessWidget {
  final BlogPost post;
  final double height;
  const BlogCover({super.key, required this.post, required this.height});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      height: height,
      width: double.infinity,
      color: kIndigo50,
      alignment: Alignment.center,
      child: Icon(Icons.article_outlined,
          size: height / 4.5, color: kIndigo600),
    );
    if (post.imageUrl == null) return fallback;
    return Image.network(
      post.imageUrl!,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

class BlogPostScreen extends StatelessWidget {
  final BlogPost post;
  const BlogPostScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final paras = post.longDesc
        .split(RegExp(r'\n{2,}'))
        .where((p) => p.trim().isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(
        backgroundColor: kCream,
        elevation: 0,
        foregroundColor: kInk,
        title: Text('Blog',
            style: fraunces(
                fontSize: 18, fontWeight: FontWeight.w600, color: kInk)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
        children: [
          Text(post.title,
              style: fraunces(
                  fontSize: 22, fontWeight: FontWeight.w600, color: kInk)),
          if (post.shortDesc.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(post.shortDesc,
                style: inter(fontSize: 14, color: kMuted, height: 1.5)),
          ],
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BlogCover(post: post, height: 200),
          ),
          const SizedBox(height: 18),
          ...paras.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(p,
                    style: inter(fontSize: 14.5, color: kInk, height: 1.7)),
              )),
        ],
      ),
    );
  }
}
