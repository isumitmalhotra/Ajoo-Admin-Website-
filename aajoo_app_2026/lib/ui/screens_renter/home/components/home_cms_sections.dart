import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/models/properties_response_model.dart';
import 'package:rent_home/service/homepage_cms_service.dart';
import 'package:rent_home/ui/screens_renter/home/components/property_slider.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:url_launcher/url_launcher.dart';

/// The two admin-curated blocks on the home screen: a hand-picked stay rail
/// and a promotional banner, both edited at /admin/cms-home on the website.
///
/// Parity with the web homepage, which grew the same two sections on the same
/// day. Before this the CMS existed on the admin side only — an editor whose
/// changes could not appear anywhere, on either platform.
///
/// Loads independently, like HomeBlogStrip: a CMS outage should cost these two
/// blocks and nothing else on the screen. Renders nothing until content exists,
/// so a client who never opens the editor sees no empty headings.
class HomeCmsSections extends StatefulWidget {
  final ValueChanged<Property> onOpen;

  const HomeCmsSections({super.key, required this.onOpen});

  @override
  State<HomeCmsSections> createState() => _HomeCmsSectionsState();
}

class _HomeCmsSectionsState extends State<HomeCmsSections> {
  final _service = HomepageCmsService();
  HomepageContent _content = HomepageContent.empty;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await _service.get();
    if (!mounted) return;
    setState(() => _content = c);
  }

  Future<void> _openBannerLink(String url) async {
    // Relative paths are a website convention the admin may well type
    // ("/explore"); there is no in-app route to map them onto, so only
    // absolute links are followed rather than opening something wrong.
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return;
    // Not gated on canLaunchUrl: on Android 11+ that resolves against a
    // package-visibility list and answers false for apps this one hasn't
    // declared, which is how several buttons in this app came to do nothing.
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final featured = _content.featured;
    final banner = _content.banner;
    if (featured.isEmpty && banner == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (featured.isNotEmpty) ...[
          PropertySlider(
            title: _content.featureTitle.isNotEmpty
                ? _content.featureTitle
                : 'Featured stays',
            properties: featured,
            onOpen: widget.onOpen,
            // No "See all": these are a fixed hand-picked set, not the head of
            // a longer list, so there is nowhere for it to lead.
          ),
          const SizedBox(height: 24),
        ],
        if (banner != null) ...[
          _Banner(banner: banner, onTapLink: _openBannerLink),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  final HomepageBanner banner;
  final ValueChanged<String> onTapLink;

  const _Banner({required this.banner, required this.onTapLink});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: kSoftShadow,
        border: Border.all(color: kLine),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (banner.image != null && banner.image!.isNotEmpty)
            Image.network(
              banner.image!,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              // A broken image URL should cost the picture, not the banner.
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  banner.title,
                  style: fraunces(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: kInk,
                    height: 1.25,
                  ),
                ),
                if (banner.desc.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    banner.desc,
                    style: const TextStyle(
                        fontSize: 13.5, color: kMuted, height: 1.5),
                  ),
                ],
                if (banner.hasButton) ...[
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: () => onTapLink(banner.buttonUrl),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kIndigo,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      banner.buttonTitle,
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
