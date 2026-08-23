// Host Support — same design language as the guest Help & Support screen.
//
// This wore the pre-redesign skin: a solid teal AppBar with white text,
// Flutter's default typeface, and four near-identical grey boxes whose only
// difference was the icon. Nothing else a host touches looks like that.
//
// Every channel behind it is unchanged — the same dedicated line, the same
// WhatsApp handoff, the same BotPenguin chat, the same management email, the
// same emergency number, the same host portal, and the same eight answers.
// What moved is the emphasis: chat leads, and the emergency line is the one
// thing on the page allowed to be loud, because it is the only one that is
// actually an emergency.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/service/device_service.dart';
import 'package:rent_home/ui/responsive.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/ui/screens_host/support/host_tickets_screen.dart';
import 'package:url_launcher/url_launcher.dart';

const String _hostLine = '+91 96252 36254';
const String _emergencyLine = '+91 93172 36254';
const String _hostEmail = 'aajoolive@gmail.com';
const String _whatsappNumber = '7973918722';
const String _chatUrl =
    'https://window-2.botpenguin.com/69803a093817049868bf064f/696f4cdf88f4a8046c67188e';

class HostSupportScreen extends StatelessWidget {
  const HostSupportScreen({super.key});

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
          'Host Support',
          style:
              fraunces(fontSize: 20, fontWeight: FontWeight.w700, color: kInk),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          child: ResponsiveBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A team that only handles hosts. Usually a few minutes.',
                  style: inter(fontSize: 14, color: kMuted, height: 1.4),
                ),
                const SizedBox(height: 18),
                const _HostChatCard(),
                const SizedBox(height: 14),
                // A tracked ticket, for anything chat cannot settle in one
                // go. The endpoints shipped with the web host portal and the
                // app never called them, so an issue raised from a phone left
                // no record and no thread to follow.
                Builder(
                  builder: (ctx) => SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(ctx).push(MaterialPageRoute(
                          builder: (_) => const HostTicketsScreen())),
                      icon: const Icon(Icons.confirmation_number_outlined,
                          size: 18),
                      label: Text('Raise a support ticket',
                          style:
                              inter(fontSize: 14, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kIndigo,
                        side: const BorderSide(color: kIndigo),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const _HostChannels(),
                const SizedBox(height: 14),
                const _EmergencyCard(),
                const SizedBox(height: 26),
                Text(
                  'Host questions',
                  style: fraunces(
                      fontSize: 18, fontWeight: FontWeight.w700, color: kInk),
                ),
                const SizedBox(height: 3),
                Text(
                  'Listing, commission, payouts and cancellations.',
                  style: inter(fontSize: 12.5, color: kMuted),
                ),
                const SizedBox(height: 12),
                const HostFAQSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Chat first, WhatsApp beside it — the two fastest ways to reach a human.
class _HostChatCard extends StatelessWidget {
  const _HostChatCard();

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
                child: const Icon(Icons.headset_mic_rounded,
                    color: Colors.white, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Host support team',
                      style: fraunces(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: kInk),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Listings, bookings, payouts — any hour.',
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
                  onPressed: () => Get.toNamed(
                    '/webview',
                    arguments: {'url': _chatUrl, 'title': 'Support Chat'},
                  ),
                  icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                  label: Text('Start chat',
                      style: inter(fontSize: 15, fontWeight: FontWeight.w700)),
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
                  icon:
                      Image.asset('assets/whatsapp.png', width: 18, height: 18),
                  label: Text('WhatsApp',
                      style: inter(fontSize: 14, fontWeight: FontWeight.w600)),
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

class _HostChannels extends StatelessWidget {
  const _HostChannels();

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
            label: 'Dedicated host line',
            value: _hostLine,
            onTap: () => launchUrl(
              Uri(scheme: 'tel', path: _hostLine.replaceAll(' ', '')),
            ),
          ),
          const Divider(height: 1, color: kLine, indent: 62),
          _ChannelRow(
            icon: Icons.mail_outline_rounded,
            label: 'Property management support',
            value: _hostEmail,
            onTap: () => launchUrl(Uri(scheme: 'mailto', path: _hostEmail)),
          ),
          const Divider(height: 1, color: kLine, indent: 62),
          _ChannelRow(
            icon: Icons.insights_rounded,
            label: 'Host portal — full analytics',
            value: 'aajoohomes.com/host',
            onTap: () => launchUrl(
              Uri.parse('https://aajoohomes.com/host'),
              mode: LaunchMode.externalApplication,
            ),
          ),
        ],
      ),
    );
  }
}

/// The one card allowed to shout. A guest locked out at midnight is not the
/// same class of problem as a question about commission, and the page should
/// not pretend otherwise.
class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => launchUrl(
        Uri(scheme: 'tel', path: _emergencyLine.replaceAll(' ', '')),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: kDanger.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kDanger.withOpacity(0.28)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: kDanger.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.emergency_rounded,
                  size: 18, color: kDanger),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Emergency at a property',
                      style: inter(fontSize: 12.5, color: kMuted)),
                  const SizedBox(height: 2),
                  Text(
                    _emergencyLine,
                    style: inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kDanger),
                  ),
                ],
              ),
            ),
            const Icon(Icons.call_rounded, size: 19, color: kDanger),
          ],
        ),
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

class HostFAQSection extends StatelessWidget {
  const HostFAQSection({super.key});

  /// Host-specific answers. These are written here rather than fetched
  /// because /common/faq carries the GUEST questions — a host asking about
  /// commission should not be told how to book a stay.
  static const List<Map<String, String>> hostFAQs = [
    {
      'question': 'How do I list my property on Aajoo Homes?',
      'answer':
          'To list your property, go to the "Add Property" section in your host dashboard. Fill in all required details including property photos, amenities, pricing, and availability. Our team will review and approve your listing within 24-48 hours.'
    },
    {
      'question': 'What commission does Aajoo Homes charge?',
      'answer':
          'Aajoo Homes charges a competitive commission rate of 15-20% depending on your property type and location. This includes marketing, customer support, payment processing, and platform maintenance.'
    },
    {
      'question': 'How do I manage bookings and check-ins?',
      'answer':
          'Use the host dashboard to view all bookings, manage availability, and communicate with guests. You can update booking status, handle check-ins/check-outs, and resolve any issues through the platform.'
    },
    {
      'question': 'When do I receive payments for bookings?',
      'answer':
          'Payments are processed within 24-48 hours after successful guest check-in. Funds are transferred to your registered bank account. You can track all transactions in the "Earnings" section of your dashboard.'
    },
    {
      'question': 'How do I handle cancellations?',
      'answer':
          'Cancellation policies are set when you list your property. The platform automatically handles cancellations according to your policy. You will be notified of any cancellations and refunds will be processed accordingly.'
    },
    {
      'question': 'What support is available for property maintenance issues?',
      'answer':
          'Contact our emergency support line for urgent property issues. For regular maintenance, you can schedule services through our partner network or handle them independently and update the property status accordingly.'
    },
    {
      'question': 'How do I update my property details or pricing?',
      'answer':
          'Log into your host dashboard and navigate to "My Properties". Select the property you want to edit and update details, photos, pricing, or availability. Changes are reflected immediately on the platform.'
    },
    {
      'question': 'What happens if there are issues with guests?',
      'answer':
          'Report any guest-related issues through the support system. Our team mediates between hosts and guests to resolve conflicts. For serious violations, we may take action including guest account suspension.'
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final faq in hostFAQs)
          HostFAQTile(
            question: faq['question']!,
            answer: faq['answer']!,
          ),
      ],
    );
  }
}

class HostFAQTile extends StatefulWidget {
  final String question;
  final String answer;

  const HostFAQTile({super.key, required this.question, required this.answer});

  @override
  State<HostFAQTile> createState() => _HostFAQTileState();
}

class _HostFAQTileState extends State<HostFAQTile> {
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
