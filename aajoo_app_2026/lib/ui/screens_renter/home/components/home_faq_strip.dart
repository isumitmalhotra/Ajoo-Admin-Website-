import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/models/faq_reponse_model.dart';
import 'package:rent_home/service/static_page_service.dart';
import 'package:rent_home/ui/screens_renter/home/components/section_header.dart';
import 'package:rent_home/utils/fonts.dart';

/// FAQs at the foot of the home screen (A-26) — the last thing on the page.
///
/// Shows the first few of the 41 published questions as an accordion, with
/// "See all" going to the full FAQ screen. Loads independently so a failure
/// costs this strip and nothing above it, and renders nothing when there are
/// no questions rather than leaving a heading over empty space.
class HomeFaqStrip extends StatefulWidget {
  final int max;
  final VoidCallback? onSeeAll;
  const HomeFaqStrip({super.key, this.max = 5, this.onSeeAll});

  @override
  State<HomeFaqStrip> createState() => _HomeFaqStripState();
}

class _HomeFaqStripState extends State<HomeFaqStrip> {
  final _service = StaticPageService();
  final _items = <FaqDatum>[].obs;
  final _loading = true.obs;
  final _openIndex = (-1).obs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _service.getFaqData();
      if (!mounted) return;
      _items.assignAll(res.data.faqData.take(widget.max));
    } catch (_) {
      // Leave it empty — the section hides itself below.
    } finally {
      if (mounted) _loading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_loading.value || _items.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Frequently asked',
            onSeeAll: widget.onSeeAll,
          ),
          const SizedBox(height: 8),
          ...List.generate(_items.length, (i) {
            final item = _items[i];
            final open = _openIndex.value == i;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kLine),
              ),
              child: Theme(
                // The default divider lines fight the card border.
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  key: ValueKey('faq_$i'),
                  initiallyExpanded: open,
                  onExpansionChanged: (v) => _openIndex.value = v ? i : -1,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                  childrenPadding:
                      const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  title: Text(
                    item.title,
                    style: inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: kInk),
                  ),
                  iconColor: kIndigo600,
                  collapsedIconColor: kMuted,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item.description,
                        style: inter(
                            fontSize: 12.5, color: kMuted, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      );
    });
  }
}
