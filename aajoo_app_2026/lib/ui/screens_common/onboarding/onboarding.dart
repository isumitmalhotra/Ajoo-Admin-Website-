// Onboarding / Getting Started — re-skinned to the new teal/orange design
// (scaffold getting_started.dart). Layout adopted; navigation stays the working
// app's real routes (Get.offAllNamed('/login')).
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/utils/fonts.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  void _goLogin() => Get.offAllNamed('/login');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(children: [
            // Header — brand + language pill
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    const CircleAvatar(
                        radius: 17,
                        backgroundColor: Colors.transparent,
                        backgroundImage:
                            AssetImage('assets/aajoo_new_logo.png')),
                    const SizedBox(width: 8),
                    Text('aajoo',
                        style: fraunces(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: kIndigo)),
                  ]),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        border: Border.all(color: kLine),
                        borderRadius: BorderRadius.circular(999)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.language, size: 14, color: kInk2),
                      const SizedBox(width: 5),
                      Text('EN',
                          style: inter(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      const Icon(Icons.keyboard_arrow_down,
                          size: 16, color: kInk2),
                    ]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Hero image
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset('assets/home_1.jpg',
                    height: 236, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        height: 236, color: kSand,
                        child: const Icon(Icons.home, size: 48, color: kMuted))),
              ),
            ),
            const SizedBox(height: 24),
            // Headline
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: fraunces(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    color: kInk),
                children: [
                  const TextSpan(text: 'Discover stays\nthat feel like '),
                  TextSpan(
                      text: 'home',
                      style: fraunces(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: kClay,
                          fontStyle: FontStyle.italic)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                  'Verified homestays, villas, cottages and unique stays across India.',
                  textAlign: TextAlign.center,
                  style: inter(fontSize: 14, color: kMuted)),
            ),
            const SizedBox(height: 24),
            // Role cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Expanded(
                    child: _RoleCard(
                        icon: Icons.work_outline,
                        title: 'Explore Stays',
                        desc: 'Find your perfect stay for your next trip.',
                        cta: 'Start Exploring',
                        color: kIndigo600,
                        bg: const Color(0xFFE6F5F3),
                        accent: false,
                        onTap: _goLogin)),
                const SizedBox(width: 14),
                Expanded(
                    child: _RoleCard(
                        icon: Icons.home_outlined,
                        title: 'Become a Host',
                        desc: 'List your property and start earning.',
                        cta: 'Start Hosting',
                        color: kClay,
                        bg: const Color(0xFFFFF1E3),
                        accent: true,
                        onTap: _goLogin)),
              ]),
            ),
            const SizedBox(height: 20),
            // Trust bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(14)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  _Trust(Icons.verified_user_outlined, 'Verified\nProperties',
                      kIndigo600),
                  _Trust(Icons.lock_outline, 'Secure\nPayments', kIndigo600),
                  _Trust(Icons.star_border, 'Trusted\nHosts', kClay),
                ],
              ),
            ),
            const SizedBox(height: 22),
            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                const Expanded(child: Divider(color: kLine)),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or continue with',
                        style: inter(fontSize: 12, color: kMuted))),
                const Expanded(child: Divider(color: kLine)),
              ]),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(children: [
                _ContinueButton(
                    icon: Icons.g_mobiledata,
                    label: 'Continue with Google',
                    onTap: _goLogin),
                const SizedBox(height: 12),
                _ContinueButton(
                    icon: Icons.phone_outlined,
                    label: 'Continue with Mobile Number',
                    onTap: _goLogin),
              ]),
            ),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.verified_user_outlined,
                  size: 14, color: kIndigo600),
              const SizedBox(width: 6),
              Text('We never share your personal details',
                  style: inter(fontSize: 12, color: kMuted)),
            ]),
            const SizedBox(height: 14),
            Text('Privacy Policy   •   Terms & Conditions   •   Help Center',
                style: inter(fontSize: 11, color: kMuted)),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title, desc, cta;
  final Color color, bg;
  final bool accent;
  final VoidCallback onTap;
  const _RoleCard(
      {required this.icon,
      required this.title,
      required this.desc,
      required this.cta,
      required this.color,
      required this.bg,
      required this.accent,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Column(children: [
        Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 26)),
        const SizedBox(height: 12),
        Text(title,
            style: fraunces(
                fontSize: 16.5, fontWeight: FontWeight.w600, color: color)),
        const SizedBox(height: 6),
        Text(desc,
            textAlign: TextAlign.center,
            style: inter(fontSize: 12, color: kMuted, height: 1.4)),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
                backgroundColor: accent ? kClay : kIndigo600,
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(cta,
                  style: inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward, size: 15, color: Colors.white),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _Trust extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Trust(this.icon, this.label, this.color);
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: inter(fontSize: 11, fontWeight: FontWeight.w600, height: 1.2)),
      ]);
}

class _ContinueButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ContinueButton(
      {required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
              foregroundColor: kInk,
              side: const BorderSide(color: kLine),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 20, color: kIndigo600),
            const SizedBox(width: 10),
            Text(label,
                style: inter(fontSize: 14, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}
