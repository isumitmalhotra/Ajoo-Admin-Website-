import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/service/static_page_service.dart';
import 'package:rent_home/utils/fonts.dart';

/// Safety — the same page the website shows (A-65).
///
/// This used to render `common/safety`, and the website had no Safety page at
/// all, so "same as the website" could not be satisfied in either direction.
/// The website now has one, and both read the same CMS page
/// (`public/cms/safety`) over the same defaults.
///
/// 🔴 The old `common/safety` copy is deliberately NOT carried over. It
/// described a platform that does not exist:
///   - "an in-app emergency button that connects them to local authorities" —
///     there is no such button; the app has an emergency CONTACT field a user
///     fills in themselves.
///   - "We offer insurance plans to hosts" and "Users can opt into protection
///     programs" — there is no insurance product. `pcp_insurance` is a tinyint
///     a host ticks about their own property in the listing wizard.
///   - "Users can report any suspicious behavior directly through the
///     platform" / "Our team continuously monitors reported issues" — there is
///     no report endpoint anywhere in the backend.
///   - "Every host undergoes a rigorous verification process" — ten of 29,232
///     listings are verified.
/// Safety claims that the product does not honour are worse than no page.
/// What is below is what the platform actually does; anything removed can be
/// restored from the admin CMS the day the feature behind it ships.
class SafetyPage extends StatefulWidget {
  const SafetyPage({super.key});

  @override
  State<SafetyPage> createState() => _SafetyPageState();
}

/// Mirrors the `safety` page in the web's cmsSchema.ts, key for key.
const Map<String, String> _defaults = {
  'hero.eyebrow': 'Safety',
  'hero.heading': 'What we do to keep stays safe.',
  'hero.p1':
      "Trust is what makes a stranger's home somewhere you can sleep. These are the checks, protections and habits we build into every booking — and the things we ask of you.",
  'book.heading': 'Before you book',
  'book.verified.t': 'Aajoo Verified listings',
  'book.verified.d':
      'Listings our team has reviewed for quality, safety and hygiene carry an Aajoo Verified badge on the property page. A listing without the badge has not been through that review — we show the badge only where it has been earned.',
  'book.kyc.t': 'Identity checks before booking',
  'book.kyc.d':
      'Guests complete an identity check before a booking is confirmed, so hosts know who is arriving and guests are staying alongside verified travellers.',
  'book.reviews.t': 'Reviews only from real bookings',
  'book.reviews.d':
      'A review can only be written against a booking the reviewer actually made on Aajoo. There is no way to post a review for a stay you never booked.',
  'book.rules.t': 'House rules in the open',
  'book.rules.d':
      "Every listing shows the host's own house rules, check-in and check-out times, and policies before you pay — not after you arrive.",
  'pay.heading': 'Your money',
  'pay.gateway.t': 'Payments we never touch',
  'pay.gateway.d':
      'Card and UPI payments are handled by Razorpay, a PCI-DSS compliant payment gateway. Your card details go to them, not to us, and are never stored on Aajoo.',
  'pay.negotiate.t': 'An agreed price, in writing',
  'pay.negotiate.d':
      'When you negotiate, the price you and the host agree is the price recorded on the booking. What you are charged is what you accepted.',
  'stay.heading': 'During your stay',
  'stay.contact.t': 'Keep an emergency contact on file',
  'stay.contact.d':
      'Add a trusted contact in your profile so someone you choose can be reached if it is ever needed. Set it before you travel, not during.',
  'stay.host.t': 'Reach your host directly',
  'stay.host.d':
      "Every confirmed booking carries the host's contact details and a message thread, so you are never trying to find someone at the door.",
  'stay.support.t': 'Talk to us',
  'stay.support.d':
      'If something is wrong with a stay, contact Aajoo support from the booking itself and we will help sort it out.',
  'emergency.heading': 'In an emergency, call the authorities first',
  'emergency.desc':
      'Aajoo is not an emergency service. If you are in danger, contact the emergency services directly — then tell us, so we can act on the listing.',
  'emergency.lines':
      "112 — National emergency helpline\n100 — Police\n101 — Fire\n102 — Ambulance\n1091 — Women's helpline",
};

/// [icon, title key, description key] per section — same order as the web.
const List<List<String>> _before = [
  ['verified', 'book.verified.t', 'book.verified.d'],
  ['badge', 'book.kyc.t', 'book.kyc.d'],
  ['reviews', 'book.reviews.t', 'book.reviews.d'],
  ['rules', 'book.rules.t', 'book.rules.d'],
];

const List<List<String>> _money = [
  ['card', 'pay.gateway.t', 'pay.gateway.d'],
  ['coins', 'pay.negotiate.t', 'pay.negotiate.d'],
];

const List<List<String>> _during = [
  ['contact', 'stay.contact.t', 'stay.contact.d'],
  ['chat', 'stay.host.t', 'stay.host.d'],
  ['support', 'stay.support.t', 'stay.support.d'],
];

const Map<String, IconData> _icons = {
  'verified': Icons.verified_outlined,
  'badge': Icons.badge_outlined,
  'reviews': Icons.rate_review_outlined,
  'rules': Icons.receipt_long_outlined,
  'card': Icons.credit_card_outlined,
  'coins': Icons.handshake_outlined,
  'contact': Icons.contact_emergency_outlined,
  'chat': Icons.chat_bubble_outline_rounded,
  'support': Icons.support_agent_outlined,
};

class _SafetyPageState extends State<SafetyPage> {
  Map<String, String> _copy = _defaults;

  @override
  void initState() {
    super.initState();
    _loadOverrides();
  }

  Future<void> _loadOverrides() async {
    final overrides = await StaticPageService().getCmsPage('safety');
    if (!mounted || overrides.isEmpty) return;
    setState(() => _copy = {..._defaults, ...overrides});
  }

  String _t(String key) => _copy[key] ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(
        title: Text('Safety',
            style: fraunces(
                fontSize: 18, fontWeight: FontWeight.w600, color: kInk)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: kCream,
        foregroundColor: kInk,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Text(
            _t('hero.eyebrow').toUpperCase(),
            style: inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
                color: kClay),
          ),
          const SizedBox(height: 8),
          Text(
            _t('hero.heading'),
            style: fraunces(
                fontSize: 25, fontWeight: FontWeight.w700, color: kInk),
          ),
          const SizedBox(height: 12),
          Text(_t('hero.p1'),
              style: inter(fontSize: 14, color: kInk2, height: 1.7)),
          const SizedBox(height: 26),
          ..._section(_t('book.heading'), _before),
          ..._section(_t('pay.heading'), _money),
          ..._section(_t('stay.heading'), _during),
          _emergency(),
        ],
      ),
    );
  }

  List<Widget> _section(String heading, List<List<String>> items) => [
        Text(heading,
            style: fraunces(
                fontSize: 19, fontWeight: FontWeight.w700, color: kInk)),
        const SizedBox(height: 12),
        for (final it in items)
          _tile(_icons[it[0]] ?? Icons.shield_outlined, _t(it[1]), _t(it[2])),
        const SizedBox(height: 18),
      ];

  Widget _tile(IconData icon, String title, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kLine),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: kIndigo50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: kIndigo600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: kInk)),
                const SizedBox(height: 4),
                Text(desc,
                    style: inter(fontSize: 13, color: kMuted, height: 1.6)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Last, and plain. This is the one block somebody might be reading in a
  /// hurry, so it does not compete with the cards above it.
  Widget _emergency() {
    final lines = _t('emergency.lines')
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.all(Radius.circular(14)),
        // A rule down the leading edge, so this reads as different in kind
        // from the reassurance above it.
        border: Border(
          top: BorderSide(color: kLine),
          right: BorderSide(color: kLine),
          bottom: BorderSide(color: kLine),
          left: BorderSide(color: kClay, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_t('emergency.heading'),
              style: fraunces(
                  fontSize: 17, fontWeight: FontWeight.w700, color: kInk)),
          const SizedBox(height: 8),
          Text(_t('emergency.desc'),
              style: inter(fontSize: 13.5, color: kMuted, height: 1.6)),
          const SizedBox(height: 14),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.call_outlined, size: 16, color: kClay),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(line,
                        style: inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: kInk)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
