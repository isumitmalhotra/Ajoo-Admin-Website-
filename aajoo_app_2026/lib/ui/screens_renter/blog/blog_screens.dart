import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/models/blog_model.dart';
import 'package:rent_home/ui/screens_renter/property_details/open_property.dart';
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
            BlogCardSlider(post: post, height: 150),
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
/// The post's pictures, as a swipeable slider.
///
/// The web post page got this first; the app read the same posts and showed
/// only the first picture, so a gallery written in the admin was invisible on
/// the device most of these are read on.
///
/// With one picture it renders exactly what [BlogCover] renders, so nothing
/// changes for the posts that have one and the controls stay hidden. No
/// carousel package: a PageView, a dot row and two arrows is the whole thing.
class BlogGallery extends StatefulWidget {
  final BlogPost post;
  final double height;
  const BlogGallery({super.key, required this.post, required this.height});

  @override
  State<BlogGallery> createState() => _BlogGalleryState();
}

class _BlogGalleryState extends State<BlogGallery> {
  final _controller = PageController();
  int _at = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final count = widget.post.images.length;
    if (count < 2) return;
    // Wraps, so the last photo's "next" is the first rather than nothing.
    final next = (_at + delta + count) % count;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Widget _arrow(IconData icon, VoidCallback onTap, Alignment align) {
    return Align(
      alignment: align,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Material(
          color: Colors.white.withOpacity(0.92),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: Icon(icon, size: 20, color: kInk),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shots = widget.post.images;
    if (shots.length < 2) {
      return BlogCover(post: widget.post, height: widget.height);
    }

    final fallback = Container(
      color: kIndigo50,
      alignment: Alignment.center,
      child: Icon(Icons.article_outlined,
          size: widget.height / 4.5, color: kIndigo600),
    );

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: shots.length,
            onPageChanged: (i) => setState(() => _at = i),
            itemBuilder: (_, i) => Image.network(
              shots[i],
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) => fallback,
            ),
          ),
          _arrow(Icons.chevron_left, () => _go(-1), Alignment.centerLeft),
          _arrow(Icons.chevron_right, () => _go(1), Alignment.centerRight),
          Positioned(
            left: 0,
            right: 0,
            bottom: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(shots.length, (i) {
                final on = i == _at;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: on ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: on ? Colors.white : Colors.white.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// A preview card's picture, cycling on its own.
///
/// The post page's slider is driven — arrows, dots, swipe. A card is not: it
/// sits inside a tap target that opens the post, so anything tappable on it
/// would fight the card it lives in. This advances by itself and offers no
/// controls.
///
/// THREE THINGS KEEP IT FROM BEING ANNOYING:
///
///  - A post with one picture never starts a timer. Most posts have one.
///  - It stops when the widget leaves the tree, and Flutter stops the whole
///    ticker when the app is backgrounded, so it costs nothing off-screen.
///  - Cards start on a stagger derived from the post id, so a row of them does
///    not flip in unison like a departures board.
///
/// Crossfade rather than slide: these sit side by side in a horizontal rail,
/// and sideways movement inside a sideways-scrolling strip reads as the strip
/// itself moving.
class BlogCardSlider extends StatefulWidget {
  final BlogPost post;
  final double height;
  final double? width;
  final BorderRadius? radius;

  const BlogCardSlider({
    super.key,
    required this.post,
    required this.height,
    this.width,
    this.radius,
  });

  @override
  State<BlogCardSlider> createState() => _BlogCardSliderState();
}

class _BlogCardSliderState extends State<BlogCardSlider> {
  Timer? _timer;
  Timer? _kickoff;
  int _at = 0;

  @override
  void initState() {
    super.initState();
    final count = widget.post.images.length;
    if (count < 2) return;
    // Derived from the id rather than random, so the same card does not
    // re-stagger every time the list rebuilds.
    final offset = Duration(milliseconds: (widget.post.id % 5) * 400);
    _kickoff = Timer(offset, () {
      if (!mounted) return;
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) return;
        setState(() => _at = (_at + 1) % count);
      });
    });
  }

  @override
  void dispose() {
    _kickoff?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shots = widget.post.images;
    final fallback = Container(
      height: widget.height,
      width: widget.width ?? double.infinity,
      color: kIndigo50,
      alignment: Alignment.center,
      child: Icon(Icons.article_outlined,
          size: widget.height / 4.5, color: kIndigo600),
    );
    if (shots.isEmpty) {
      return BlogCover(post: widget.post, height: widget.height);
    }

    final image = Stack(
      fit: StackFit.expand,
      children: [
        // Every frame stays in the tree and fades. Swapping the URL instead
        // would show an empty box for as long as the next picture takes to
        // arrive, which on a slow connection is most of the four seconds.
        for (var i = 0; i < shots.length; i++)
          AnimatedOpacity(
            opacity: i == _at ? 1 : 0,
            duration: const Duration(milliseconds: 600),
            child: Image.network(
              shots[i],
              height: widget.height,
              width: widget.width ?? double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
            ),
          ),
        if (shots.length > 1)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < shots.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      width: i == _at ? 14 : 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: i == _at
                            ? Colors.white
                            : Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );

    final sized = SizedBox(
      height: widget.height,
      width: widget.width,
      child: image,
    );
    return widget.radius == null
        ? sized
        : ClipRRect(borderRadius: widget.radius!, child: sized);
  }
}

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
            child: BlogGallery(post: post, height: 200),
          ),
          const SizedBox(height: 18),
          ...paras.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(p,
                    style: inter(fontSize: 14.5, color: kInk, height: 1.7)),
              )),

          // The stay this post is about — same card the web shows.
          //
          // A guide written about a particular house ended at the last
          // paragraph with the house named in the prose and unreachable from
          // it; the reader had to go back to search and hope to find it by
          // name.
          if (post.propertyId != null && post.propertyId! > 0) ...[
            const SizedBox(height: 10),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () =>
                    openPropertyById(post.propertyId!, errorTitle: 'Blog'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kInk.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('THE STAY IN THIS STORY',
                                style: inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: kMuted,
                                    letterSpacing: 1.2)),
                            const SizedBox(height: 4),
                            Text(post.propertyName ?? 'View the property',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: fraunces(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: kInk)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 20, color: kInk),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
