import 'package:flutter/material.dart';

import 'package:rent_home/constants.dart';
import 'package:rent_home/ui/screens_common/support/support_screen.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/ui/responsive.dart';

/// The FAQ, on its own screen.
///
/// Reported 2026-09-10 (bug 27) as "UI issues in Settings > FAQ". Three faults,
/// all from this screen being written before the redesign and never revisited:
///
///   1. NO SCROLL VIEW. `FAQSection` returns a bare Column built to sit inside
///      the Support screen's SingleChildScrollView. Dropped straight into
///      `body:` it cannot scroll, so past four or five questions it simply
///      overflows — the striped RenderFlex banner, and the rest unreachable.
///   2. NO PADDING. Support wraps it in 16px; here the tiles ran edge to edge
///      against both sides of the screen.
///   3. A DIFFERENT SKIN. A raw AppBar in `Theme.primaryColor` with white text,
///      against an app whose every other screen is ink on sand — and
///      `persistentFooterButtons`, a Material pattern used nowhere else here,
///      which pins a bare text button under a permanent divider.
///
/// It now uses the same shell as Help & Support, which is where the identical
/// widget already lived and looked right. ResponsiveBody included for the same
/// reason it is there: on a tablet the answers would otherwise read as one
/// endless line.
class FaqScren extends StatelessWidget {
  const FaqScren({super.key});

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
          'FAQ',
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
                  'The questions guests and hosts ask us most.',
                  style: inter(fontSize: 14, color: kMuted, height: 1.4),
                ),
                const SizedBox(height: 18),
                const FAQSection(),
                const SizedBox(height: 22),
                // In the flow rather than pinned under a divider: it is the
                // way out when the answer is not here, not a permanent
                // fixture competing with the answers themselves.
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SupportScreen()),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      side: const BorderSide(color: kLine),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                    ),
                    child: Text(
                      "Still stuck? Contact support",
                      style: inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: kInk),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
