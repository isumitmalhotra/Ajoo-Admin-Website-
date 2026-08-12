import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/data/models/safety_data_model.dart';
import 'package:rent_home/service/static_page_service.dart';
import 'package:rent_home/utils/fonts.dart';

/// Safety — on the current theme (A-65).
///
/// Content still comes from `common/safety`, unchanged. Note for whoever picks
/// this up: the website has no Safety page at all, so "same as the website"
/// could not be satisfied for this one; only the styling was brought into
/// line. See the session notes.
class SafetyPage extends StatefulWidget {
  const SafetyPage({super.key});

  @override
  State<SafetyPage> createState() => _SafetyPageState();
}

class _SafetyPageState extends State<SafetyPage> {
  final _staticPageService = StaticPageService();

  /// Started once, in initState. It used to be called straight from build(),
  /// which re-issued the request on every rebuild — the same mistake the
  /// pre-booking header made with its reverse-geocode.
  late final Future<SafetyDataModel> _safety = _staticPageService.getSafetyData();

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
      body: FutureBuilder<SafetyDataModel>(
        future: _safety,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: kIndigo));
          } else if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  "Couldn't load safety information. Pull back and try again.",
                  textAlign: TextAlign.center,
                  style: inter(fontSize: 13.5, color: kMuted),
                ),
              ),
            );
          }

          final safetyData = snapshot.data!;
          final content = safetyData.safetyData.content.sections;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              // The 200px logo that used to sit here said nothing about
              // safety and pushed the actual guidance below the fold.
              Text(
                safetyData.safetyData.heading.title,
                style: fraunces(
                    fontSize: 24, fontWeight: FontWeight.w700, color: kInk),
              ),
              const SizedBox(height: 8),
              Text(
                safetyData.safetyData.heading.description,
                style: inter(fontSize: 14, color: kMuted, height: 1.6),
              ),
              const SizedBox(height: 22),
              for (final section in content.entries) ...[
                Text(
                  section.key,
                  style: fraunces(
                      fontSize: 18, fontWeight: FontWeight.w700, color: kInk),
                ),
                const SizedBox(height: 10),
                for (final tip in section.value)
                  SafetyTip(
                    icon: Iconsax.shield_tick4,
                    title: tip.keys.first,
                    description: tip.values.first,
                  ),
                const SizedBox(height: 20),
              ],
              if (safetyData.safetyData.conclusion.trim().isNotEmpty) ...[
                const Divider(color: kLine, height: 1),
                const SizedBox(height: 18),
                Text(
                  safetyData.safetyData.conclusion,
                  style: inter(fontSize: 14, color: kInk2, height: 1.7),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class SafetyTip extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const SafetyTip({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
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
                Text(description,
                    style: inter(fontSize: 13, color: kMuted, height: 1.6)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
