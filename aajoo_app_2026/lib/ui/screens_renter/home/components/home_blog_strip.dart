import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/ui/design/aajoo_skin.dart';
import 'package:rent_home/utils/lux_mode.dart';
import 'package:rent_home/models/blog_model.dart';
import 'package:rent_home/service/blog_service.dart';
import 'package:rent_home/ui/screens_renter/home/components/section_header.dart';
import 'package:rent_home/utils/fonts.dart';

/// Blogs on the home screen (A-25): four or five posts, "See all" top-right.
///
/// Loads on its own rather than through a shared controller, because a blog
/// outage should cost this one strip and nothing else on the page. It renders
/// nothing at all when there are no posts — an empty carousel with a heading
/// over it is worse than no heading.
class HomeBlogStrip extends StatefulWidget {
  final VoidCallback? onSeeAll;
  final ValueChanged<BlogPost>? onOpen;

  /// How many posts to show. The home screen wants five; the property page
  /// wants three beside everything else on it.
  final int max;

  /// The property page calls the same strip "From the blog" too, so this only
  /// exists to keep both callers on one widget rather than growing a copy.
  final String title;

  /// Set to show posts written about ONE stay instead of the platform blog.
  ///
  /// The property page used to show the same general posts under every
  /// listing, which is filler: nothing on the strip had anything to do with
  /// the place being looked at. With this set it asks for that property's own
  /// posts, and most properties have none — so the strip renders nothing,
  /// which it already did correctly for an empty list.
  final int? propertyId;

  const HomeBlogStrip({
    super.key,
    this.onSeeAll,
    this.onOpen,
    this.max = 5,
    this.title = 'From the blog',
    this.propertyId,
  });

  @override
  State<HomeBlogStrip> createState() => _HomeBlogStripState();
}

class _HomeBlogStripState extends State<HomeBlogStrip> {
  final _service = BlogService();
  final _posts = <BlogPost>[].obs;
  final _loading = true.obs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = widget.propertyId;
    final list = id != null && id > 0
        ? await _service.getPropertyBlogs(id, limit: widget.max)
        : await _service.getBlogs(limit: widget.max);
    if (!mounted) return;
    _posts.assignAll(list);
    _loading.value = false;
  }

  @override
  Widget build(BuildContext context) {
    final skin = AajooSkin.of(LuxMode.instance.isOn);
    return Obx(() {
      if (_loading.value) return const SizedBox(height: 0);
      if (_posts.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: widget.title,
            onViewAll: widget.onSeeAll,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _posts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _BlogCard(
                post: _posts[i],
                onTap: () => widget.onOpen?.call(_posts[i]),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _BlogCard extends StatelessWidget {
  final BlogPost post;
  final VoidCallback? onTap;
  const _BlogCard({required this.post, this.onTap});

  @override
  Widget build(BuildContext context) {
    final skin = AajooSkin.of(LuxMode.instance.isOn);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 230,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 120,
                width: 230,
                // No post has an image yet, so this is the normal case rather
                // than the exception. A neutral panel, not a stock photograph
                // of somebody else's house.
                child: post.imageUrl == null
                    ? Container(
                        color: kIndigo50,
                        alignment: Alignment.center,
                        child: const Icon(Icons.article_outlined,
                            size: 30, color: kIndigo600),
                      )
                    : Image.network(
                        post.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: kIndigo50,
                          alignment: Alignment.center,
                          child: const Icon(Icons.article_outlined,
                              size: 30, color: kIndigo600),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              post.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: inter(
                  fontSize: 13.5, fontWeight: FontWeight.w700, color: skin.ink),
            ),
            const SizedBox(height: 3),
            Text(
              post.shortDesc,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: inter(fontSize: 12, color: skin.muted, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}
