import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:rent_home/constants.dart';
import 'package:rent_home/models/my_review.dart';
import 'package:rent_home/service/user_service.dart';
import 'package:rent_home/utils/fonts.dart';

/// Reviews you've written — the mobile counterpart of the web's /account/reviews.
///
/// The app could already write a review and show it back inside the booking it
/// belonged to, which is the right place to write one. What was missing was the
/// other question: what have I said about the places I've stayed? Answering it
/// meant opening each past stay in turn, and deleting a review meant finding
/// the booking it was on first.
class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  final _service = UserService();

  List<MyReview> _items = const [];
  bool _loading = true;

  /// "You haven't reviewed anything" and "we couldn't ask" look identical on
  /// screen and only one of them is true. The website's version of this page
  /// swallows the error and shows the empty state; this one does not.
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await _service.getMyReviews();
      if (!mounted) return;
      setState(() {
        _items = rows;
        _failed = false;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = const [];
        _failed = true;
        _loading = false;
      });
    }
  }

  Future<void> _delete(MyReview r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete this review?',
            style:
                fraunces(fontSize: 17, fontWeight: FontWeight.w700, color: kInk)),
        content: Text(
          'Your review of ${r.property} stops showing on the listing. '
          'You can write a new one from the stay itself.',
          style: inter(fontSize: 13.5, color: kInk2, height: 1.45),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text('Keep it', style: inter(color: kMuted))),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            style: TextButton.styleFrom(foregroundColor: kDanger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final done = await _service.deleteUserReview(r.id);
    if (!mounted) return;
    if (!done) {
      Get.snackbar('Not deleted', 'That review could not be removed. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: kDanger,
          colorText: Colors.white);
      return;
    }
    setState(() => _items = _items.where((x) => x.id != r.id).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSand,
      appBar: AppBar(
        backgroundColor: kSand,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: kInk,
        titleSpacing: 0,
        title: Text('Your reviews',
            style:
                fraunces(fontSize: 20, fontWeight: FontWeight.w700, color: kInk)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                children: [
                  if (_failed)
                    _card(
                      bg: Colors.red.shade50,
                      child: Text(
                        "We couldn't load your reviews just now. This is a "
                        'failed request, not an empty list — pull down to try '
                        'again.',
                        style: inter(
                            fontSize: 12.5,
                            color: Colors.red.shade700,
                            height: 1.5),
                      ),
                    )
                  else if (_items.isEmpty)
                    _card(
                      child: Column(
                        children: [
                          const Icon(Icons.star_border_rounded,
                              size: 30, color: kClay),
                          const SizedBox(height: 10),
                          Text('No reviews yet',
                              style: fraunces(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: kInk)),
                          const SizedBox(height: 6),
                          Text(
                            'After a completed stay you can share how it went '
                            'from the booking itself.',
                            textAlign: TextAlign.center,
                            style: inter(
                                fontSize: 12.5, color: kMuted, height: 1.5),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    Text(
                      '${_items.length} review${_items.length == 1 ? '' : 's'} '
                      'written',
                      style: inter(fontSize: 13, color: kMuted),
                    ),
                    const SizedBox(height: 12),
                    for (final r in _items) ...[
                      _reviewCard(r),
                      const SizedBox(height: 10),
                    ],
                  ],
                ],
              ),
            ),
    );
  }

  /// Shown when a listing genuinely has no photograph.
  Widget _noPhoto() => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: kLine,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.image_outlined, size: 18, color: kMuted),
      );

  Widget _card({required Widget child, Color? bg}) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bg ?? kCream,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kLine),
        ),
        child: child,
      );

  Widget _reviewCard(MyReview r) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kLine),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The listing's own photo, or a marked blank. Never a stock
                // picture of a different property.
                if (r.image != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      r.image!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _noPhoto(),
                    ),
                  ),
                  const SizedBox(width: 10),
                ] else ...[
                  _noPhoto(),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.property,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: kInk)),
                      if (r.place.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(r.place,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: inter(fontSize: 12, color: kMuted)),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _delete(r),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: kMuted),
                  tooltip: 'Delete this review',
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                for (var i = 0; i < 5; i++)
                  Icon(
                    i < r.rating ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 16,
                    color: i < r.rating ? kClay : kLine,
                  ),
                const SizedBox(width: 8),
                if (r.addedAt != null)
                  Text(DateFormat('d MMM yyyy').format(r.addedAt!.toLocal()),
                      style: inter(fontSize: 11.5, color: kMuted)),
              ],
            ),
            if (r.title.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(r.title,
                  style: inter(
                      fontSize: 13, fontWeight: FontWeight.w600, color: kInk)),
            ],
            if (r.body.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(r.body,
                  style: inter(fontSize: 12.5, color: kInk2, height: 1.5)),
            ],
          ],
        ),
      );
}
