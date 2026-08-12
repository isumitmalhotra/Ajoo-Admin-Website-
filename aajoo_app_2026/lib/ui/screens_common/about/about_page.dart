import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/service/static_page_service.dart';
import 'package:rent_home/utils/fonts.dart';

/// About Aajoo — the same page the website shows (A-65).
///
/// It used to render `common/about-us`, an older copy deck the website stopped
/// using: the site says "More Than a Stay. A Place to Belong." with Our Story,
/// Vision, Mission, five values, six differentiators and a closing passage,
/// while the app still said "AAJOO – AAJAO AAJOO MEIN" and listed "Walking
/// Distance Optimization". Two platforms describing two different companies.
///
/// This reads the same CMS page the website reads (`public/cms/about`) over
/// the same spec defaults, so the two now say the same thing — and an admin
/// edit lands on both instead of one.
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

/// The website's spec copy, verbatim, keyed exactly as the web's cmsSchema.
///
/// Defaults, not last-resort fallbacks: the page renders them immediately and
/// swaps in overrides when the CMS answers. A skeleton while the app finds out
/// what its own headings are would be worse than showing the copy it ships
/// with — which is how the website treats the same content.
const Map<String, String> _defaults = {
  'hero.eyebrow': 'About Aajoo',
  'hero.heading': 'More Than a Stay. A Place to Belong.',
  'hero.p1':
      'Every journey begins with a destination, but what truly shapes that journey is where you stay and the people you meet along the way.',
  'hero.p2':
      "A great stay isn't just about four walls or a comfortable bed. It's about feeling welcomed, discovering local stories, experiencing authentic culture, and creating memories that last long after the trip ends. That's the experience Aajoo was built to create.",
  'story.heading': 'Our Story',
  'story.p1':
      'India is home to millions of unique places, diverse cultures, breathtaking landscapes, and incredible hospitality. From family-run homestays and peaceful countryside retreats to modern city apartments and luxury villas, every property has its own story.',
  'story.p2':
      "Yet many remarkable hosts struggle to reach travelers who would genuinely value their hospitality. At the same time, travelers often spend hours searching through endless listings without finding the authentic experiences they're looking for.",
  'story.p3':
      'We believed there had to be a better way. A platform where technology empowers people instead of replacing human connections. A platform where hosts are supported, travelers are inspired, and every booking creates opportunities for local communities. That belief became Aajoo.',
  'vision.heading': 'Our Vision',
  'vision.p1':
      "To become India's most trusted hospitality platform while building a global community where every traveler can discover authentic stays and every host has the opportunity to grow.",
  'vision.p2':
      'We envision a future where technology makes travel more personal, more transparent, and more meaningful — connecting people through genuine hospitality rather than simply facilitating bookings.',
  'mission.heading': 'Our Mission',
  'mission.p1':
      'Our mission is to make discovering and hosting stays simple, transparent, and rewarding. We empower hosts with modern tools that simplify property management, improve visibility, and help grow sustainable businesses.',
  'mission.p2':
      'We help travelers discover unique places, experience local culture, and travel with confidence through trusted accommodations and seamless technology.',
  'mission.p3':
      'Every decision we make is guided by one simple belief: travel should create value for everyone it touches.',
  'values.heading': 'Our Values',
  'values.desc': 'The beliefs behind every stay on Aajoo.',
  'different.heading': 'What Makes Aajoo Different',
  'ahead.heading': 'Looking Ahead',
  'ahead.p1':
      'Aajoo is beginning with stays, but our vision extends far beyond accommodation. We are building a connected travel ecosystem that will bring together accommodations, experiences, local activities, transportation, AI-powered travel assistance, and intelligent recommendations — all within one trusted platform.',
  'ahead.p2':
      'Our ambition is not simply to help people book a place to stay. Our ambition is to redefine how people discover, experience, and remember every journey.',
  'welcome.heading': 'Welcome to Aajoo',
  'welcome.lines':
      'More than a booking platform. More than a travel app.\nA place where hospitality meets technology.\nWhere travelers discover more than destinations.\nWhere hosts build lasting opportunities.\nWhere communities grow stronger.\nWhere every journey begins with trust.\nAnd every stay becomes a story worth sharing.',
  'welcome.signoff': 'Welcome to Aajoo. Welcome Home.',
};

/// Our Values — the five the spec names. Not CMS fields on the website
/// either, so they are held here the same way.
const List<List<String>> _values = [
  [
    'People First',
    'Technology should strengthen human connections, not replace them.'
  ],
  [
    'Trust Above Everything',
    'Every interaction should be honest, transparent, and reliable.'
  ],
  [
    'Simplicity Matters',
    'The best experiences are built through thoughtful and intuitive design.'
  ],
  [
    'Empower Local Communities',
    'Every booking should help local families, entrepreneurs, and destinations thrive.'
  ],
  [
    'Grow Together',
    'When guests, hosts, and communities succeed together, everyone benefits.'
  ],
];

/// What Makes Aajoo Different — the six differentiators, verbatim.
const List<List<String>> _different = [
  [
    'Designed Around People',
    'Every feature begins with understanding the needs of travelers and hosts—not just transactions.'
  ],
  [
    'Flexible Pricing',
    'Our negotiation feature gives guests and hosts the flexibility to agree on a price that works for both, creating a more personalized booking experience.'
  ],
  [
    'Verified & Trusted',
    'We verify listings to build confidence and create a safer experience for everyone on the platform.'
  ],
  [
    'Smart Discovery',
    'Find stays based on destination, travel style, amenities, budget, nearby attractions, and personalized recommendations.'
  ],
  [
    'Technology That Empowers',
    'From property management and bookings to pricing and availability, we provide intuitive tools that help hosts succeed without complexity.'
  ],
  [
    'Community First',
    'Every stay contributes to stronger local tourism, sustainable livelihoods, and authentic travel experiences.'
  ],
];

const List<IconData> _valueIcons = [
  Icons.people_outline,
  Icons.verified_user_outlined,
  Icons.auto_awesome_outlined,
  Icons.favorite_outline,
  Icons.trending_up_outlined,
];

const List<IconData> _differentIcons = [
  Icons.people_outline,
  Icons.currency_rupee_rounded,
  Icons.verified_user_outlined,
  Icons.search_rounded,
  Icons.bolt_outlined,
  Icons.holiday_village_outlined,
];

class _AboutPageState extends State<AboutPage> {
  Map<String, String> _copy = _defaults;

  @override
  void initState() {
    super.initState();
    _loadOverrides();
  }

  Future<void> _loadOverrides() async {
    final overrides = await StaticPageService().getCmsPage('about');
    if (!mounted || overrides.isEmpty) return;
    setState(() => _copy = {..._defaults, ...overrides});
  }

  String _t(String key) => _copy[key] ?? '';

  List<String> _lines(String key) => _t(key)
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(
        backgroundColor: kCream,
        foregroundColor: kInk,
        elevation: 0,
        centerTitle: true,
        title: Text('About Aajoo',
            style: fraunces(
                fontSize: 18, fontWeight: FontWeight.w600, color: kInk)),
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
                fontSize: 27, fontWeight: FontWeight.w700, color: kInk),
          ),
          const SizedBox(height: 14),
          _para(_t('hero.p1')),
          _para(_t('hero.p2')),
          _rule(),
          _heading(_t('story.heading')),
          _para(_t('story.p1')),
          _para(_t('story.p2')),
          _para(_t('story.p3')),
          _rule(),
          _heading(_t('vision.heading')),
          _para(_t('vision.p1')),
          _para(_t('vision.p2')),
          const SizedBox(height: 18),
          _heading(_t('mission.heading')),
          _para(_t('mission.p1')),
          _para(_t('mission.p2')),
          _para(_t('mission.p3')),
          _rule(),
          _heading(_t('values.heading')),
          if (_t('values.desc').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(_t('values.desc'),
                  style: inter(fontSize: 13.5, color: kMuted)),
            ),
          for (var i = 0; i < _values.length; i++)
            _pillar(_valueIcons[i], _values[i][0], _values[i][1]),
          _rule(),
          _heading(_t('different.heading')),
          const SizedBox(height: 4),
          for (var i = 0; i < _different.length; i++)
            _pillar(_differentIcons[i], _different[i][0], _different[i][1]),
          _rule(),
          _heading(_t('ahead.heading')),
          _para(_t('ahead.p1')),
          _para(_t('ahead.p2')),
          _rule(),
          _heading(_t('welcome.heading')),
          for (final line in _lines('welcome.lines'))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(line,
                  style: inter(fontSize: 14, color: kInk2, height: 1.6)),
            ),
          const SizedBox(height: 14),
          Text(
            _t('welcome.signoff'),
            style: fraunces(
                fontSize: 18, fontWeight: FontWeight.w700, color: kIndigo600),
          ),
        ],
      ),
    );
  }

  Widget _heading(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: fraunces(
                fontSize: 20, fontWeight: FontWeight.w700, color: kInk)),
      );

  Widget _para(String text) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child:
          Text(text, style: inter(fontSize: 14, color: kInk2, height: 1.7)),
    );
  }

  Widget _rule() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Divider(color: kLine, height: 1),
      );

  Widget _pillar(IconData icon, String title, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
}
