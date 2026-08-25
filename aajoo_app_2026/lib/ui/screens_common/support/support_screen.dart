// Contact Support — rebuilt in the current design language.
//
// This page was the last renter-facing screen still wearing the pre-redesign
// look: a solid teal AppBar with white text, Flutter's default typeface, and
// three identical grey-bordered boxes whose only difference was the icon. The
// client's note was that it "looks old", and it did — nothing else the guest
// touches is styled like this any more.
//
// What changed is presentation only. Every action behind it is the same one:
// the same phone number, the same WhatsApp handoff, the same BotPenguin chat
// URL, the same mailto address, the same website, and the same FAQ feed from
// StaticPageController. The one thing that used to be genuinely hard to find —
// the support chat — is now the primary button rather than a small circle
// tucked into the corner of a card, which is what the client asked for.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/controller/static_page_controller.dart';
import 'package:rent_home/service/device_service.dart';
import 'package:rent_home/ui/responsive.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/widgets/social_row.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rent_home/utils/support_chat.dart';

/// One definition, so the mailto link and the address on screen cannot
/// disagree again.
const String _supportEmail = 'aajoolive@gmail.com';
const String _supportPhone = '+91 96252 36254';
const String _whatsappNumber = '7973918722';
const String _chatUrl =
    'https://window-2.botpenguin.com/69803a093817049868bf064f/696f4cdf88f4a8046c67188e';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSand,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: kSand,
        foregroundColor: kInk,
        centerTitle: false,
        titleSpacing: 0,
        title: Text(
          'Help & Support',
          style: fraunces(
              fontSize: 20, fontWeight: FontWeight.w700, color: kInk),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          // On a tablet this column would otherwise run the full 1300px and
          // the FAQ answers would read as one endless line.
          child: ResponsiveBody(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We usually reply within a few minutes.',
                style: inter(fontSize: 14, color: kMuted, height: 1.4),
              ),
              const SizedBox(height: 18),
              const _ChatCard(),
              const SizedBox(height: 14),
              const _ContactChannels(),
              const SizedBox(height: 26),
              const _SectionHeading(
                title: 'Frequently asked questions',
                subtitle: 'Answers to the things guests ask most.',
              ),
              const SizedBox(height: 12),
              const FAQSection(),
              const SizedBox(height: 26),
              const _SectionHeading(
                title: 'Follow Aajoo Homes',
                subtitle: 'New stays and offers, first.',
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kLine),
                ),
                child: const SocialRow(
                  rowAlignment: MainAxisAlignment.spaceEvenly,
                ),
              ),
            ],
          )),
        ),
      ),
    );
  }
}

/// The support button the client asked to be redesigned.
///
/// It was a 42px circle in the bottom-right corner of the phone-number card,
/// which is where you put something you do not want found. Chat is the fastest
/// channel we have, so it leads: full-width, labelled, with WhatsApp beside it
/// as the equal alternative rather than another anonymous circle.
class _ChatCard extends StatelessWidget {
  const _ChatCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kIndigo.withOpacity(0.22)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kIndigo50, kSurface],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: kIndigo,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.support_agent_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chat with support',
                      style: fraunces(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: kInk),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bookings, refunds, payments — any hour.',
                      style: inter(fontSize: 12.5, color: kMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  // Opened as whoever is signed in — see utils/support_chat.
                  // A bare URL made the bot ask a logged-in guest for their
                  // phone number and another OTP, which the website has never
                  // done.
                  onPressed: () async {
                    final url = await supportChatUrl();
                    Get.toNamed('/webview',
                        arguments: {'url': url, 'title': 'Support Chat'});
                  },
                  icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                  label: Text(
                    'Start chat',
                    style:
                        inter(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kIndigo,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: () => DeviceService.launchWhatsapp(
                    phoneNumber: _whatsappNumber,
                    message: 'hello, i need assistance',
                  ),
                  icon: Image.asset('assets/whatsapp.png',
                      width: 18, height: 18),
                  label: Text(
                    'WhatsApp',
                    style:
                        inter(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kInk,
                    side: const BorderSide(color: kLine),
                    backgroundColor: kSurface,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Phone, email and website, as one grouped list rather than three floating
/// cards — the same shape Settings uses, so the app reads as one app.
class _ContactChannels extends StatelessWidget {
  const _ContactChannels();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kLine),
      ),
      child: Column(
        children: [
          _ChannelRow(
            icon: Icons.phone_in_talk_rounded,
            label: 'Call us — 24×7',
            value: _supportPhone,
            onTap: () => launchUrl(
              Uri(scheme: 'tel', path: _supportPhone.replaceAll(' ', '')),
            ),
          ),
          const Divider(height: 1, color: kLine, indent: 62),
          _ChannelRow(
            icon: Icons.mail_outline_rounded,
            label: 'Write to us',
            value: _supportEmail,
            // The link said "naaajoolive@gmail.com" while the row below it
            // displayed "aajoolive@gmail.com" — a typo, so every renter who
            // tapped support email sent it to an address that does not exist
            // and got a bounce. Kept in one place so they cannot drift again.
            onTap: () =>
                launchUrl(Uri(scheme: 'mailto', path: _supportEmail)),
          ),
          const Divider(height: 1, color: kLine, indent: 62),
          _ChannelRow(
            icon: Icons.language_rounded,
            label: 'Visit the website',
            value: 'aajoohomes.com',
            onTap: () => launchUrl(
              Uri.parse('https://aajoohomes.com/'),
              mode: LaunchMode.externalApplication,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: kIndigo50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: kIndigo),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: inter(fontSize: 12.5, color: kMuted)),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: kInk),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: kMuted),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:
              fraunces(fontSize: 18, fontWeight: FontWeight.w700, color: kInk),
        ),
        const SizedBox(height: 3),
        Text(subtitle, style: inter(fontSize: 12.5, color: kMuted)),
      ],
    );
  }
}

class FAQSection extends StatefulWidget {
  const FAQSection({super.key});

  @override
  State<FAQSection> createState() => _FAQSectionState();
}

class _FAQSectionState extends State<FAQSection> {
  late StaticPageController _staticPageController;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<StaticPageController>()) {
      _staticPageController = Get.put(StaticPageController());
    } else {
      _staticPageController = Get.find<StaticPageController>();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _staticPageController.getFaqData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_staticPageController.isLoading.value) {
        return Shimmer.fromColors(
          baseColor: kLine,
          highlightColor: kSand,
          child: Column(
            children: List.generate(
              4,
              (_) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                height: 58,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        );
      }
      final faqData = _staticPageController.faqData.value?.data.faqData;
      final failed = _staticPageController.faqError.value;

      // A request that never landed is not an empty catalogue. The backend
      // cold-starts, and on the first open of a cold app this section reliably
      // timed out — which used to render as "No questions here yet" over a
      // server holding a dozen answers.
      if (failed && (faqData == null || faqData.isEmpty)) {
        return _FaqNotice(
          icon: Icons.wifi_off_rounded,
          title: "Couldn't load the FAQs",
          body: 'Check your connection and try again.',
          onRetry: () => _staticPageController.getFaqData(),
        );
      }
      if (faqData == null || faqData.isEmpty) {
        // An empty shelf, said plainly, with the way out on it — better than
        // the bare "No data available" this used to show.
        return const _FaqNotice(
          icon: Icons.help_outline_rounded,
          title: 'No questions here yet',
          body: 'Chat with us above and we will answer directly.',
        );
      }
      return Column(
        children: [
          for (final faq in faqData)
            FAQTile(question: faq.title, answer: faq.description),
        ],
      );
    });
  }
}

/// A single message where the FAQ list would be — empty, or failed with a
/// way to try again.
class _FaqNotice extends StatelessWidget {
  const _FaqNotice({
    required this.icon,
    required this.title,
    required this.body,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 18),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kLine),
      ),
      child: Column(
        children: [
          Icon(icon, size: 26, color: kMuted),
          const SizedBox(height: 8),
          Text(
            title,
            style: inter(fontSize: 14, fontWeight: FontWeight.w600, color: kInk),
          ),
          const SizedBox(height: 3),
          Text(
            body,
            textAlign: TextAlign.center,
            style: inter(fontSize: 12.5, color: kMuted),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: Text('Retry',
                  style: inter(fontSize: 13, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: kIndigo,
                side: const BorderSide(color: kIndigo),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class FAQTile extends StatefulWidget {
  final String question;
  final String answer;

  const FAQTile({super.key, required this.question, required this.answer});

  @override
  State<FAQTile> createState() => _FAQTileState();
}

class _FAQTileState extends State<FAQTile> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isExpanded ? kIndigo.withOpacity(0.3) : kLine),
      ),
      child: Theme(
        // Kill the default divider lines; the card border is the boundary.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text(
            widget.question,
            style: inter(
                fontSize: 14.5, fontWeight: FontWeight.w600, color: kInk),
          ),
          trailing: AnimatedRotation(
            turns: isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 180),
            child: const Icon(Icons.keyboard_arrow_down_rounded,
                color: kIndigo, size: 22),
          ),
          onExpansionChanged: (value) => setState(() => isExpanded = value),
          children: [
            Text(
              widget.answer,
              style: inter(fontSize: 13.5, color: kInk2, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
