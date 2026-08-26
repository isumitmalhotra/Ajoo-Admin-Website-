import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/utils/fonts.dart';

/// LUX mode's own look.
///
/// LUX used to change only which properties came back — the screen around them
/// was pixel-identical to standard mode, so the one thing a guest could tell
/// about "luxury" was that there were fewer listings. Turning it on has to feel
/// like somewhere else.
///
/// Standard is Warm Ivory and Evergreen Teal. LUX is near-black and gold: dark
/// surfaces, gold rules and headings, a slower and heavier motion curve, and a
/// loader that says LUX rather than spinning a teal circle.
///
/// These are deliberately NOT overrides of the k* tokens in constants.dart —
/// eighty-odd files read those, and repainting the app from a mode toggle is
/// how you end up with a teal button on a black sheet. Screens opt in.
class Lux {
  const Lux._();

  // ── Palette ───────────────────────────────────────────────────────────────
  //
  // These are the website's LUXE values, read out of the `html[data-lux]`
  // block in styles/aajoo-system.css. They used to be a warmer set of browns
  // chosen here independently (#12100C / #1C1813 / #F5EFE2), which meant the
  // two platforms shipped two different luxury modes. The site had already
  // moved off the browns and left the reason in the stylesheet — against gold
  // they read muddy rather than luxe — so the app follows.
  //
  // Anything new should prefer AajooSkin (ui/design/aajoo_skin.dart), which
  // carries the same values plus their classic counterparts; these stay
  // because the LUX loader and switch dialog below are LUX-only and have no
  // classic side to resolve against.

  /// Page background — neutral near-black.
  static const Color bg = Color(0xFF0A0A0C);

  /// Raised surfaces (cards, sheets, rails).
  static const Color surface = Color(0xFF141416);

  /// One step up again, for controls sitting on a surface.
  static const Color surfaceHigh = Color(0xFF1A1A1D);

  /// Hairlines — rgba(212,175,55,.24). Gold at low opacity reads richer than
  /// grey on this background.
  static const Color line = Color(0x3DD4AF37);

  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFF6E5A8);
  static const Color goldDeep = Color(0xFFB8860B);

  /// What is legible ON gold. White on #D4AF37 is 1.9:1 — unreadable — so
  /// every filled gold control takes its foreground from here.
  static const Color onGold = Color(0xFF1A1508);

  /// Text on the dark ground.
  static const Color ink = Color(0xFFF2F0EA);
  static const Color muted = Color(0xFFA6A39C);

  /// The gold used for headings and rules — a gradient, so a heading catches
  /// light across its width the way foil stamping does.
  static const LinearGradient goldSheen = LinearGradient(
    colors: [goldDeep, goldLight, gold],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ── Motion ────────────────────────────────────────────────────────────────
  /// LUX moves more slowly and settles rather than snapping. Standard mode's
  /// transitions stay where they are; this is only for LUX surfaces.
  static const Duration slow = Duration(milliseconds: 620);
  static const Curve ease = Curves.easeOutCubic;

  // ── Icons ─────────────────────────────────────────────────────────────────
  /// LUX swaps the outline set for filled/sharper equivalents, so the mode is
  /// legible at a glance even in greyscale.
  static IconData icon(IconData standard) => _iconSwaps[standard] ?? standard;

  static final Map<IconData, IconData> _iconSwaps = {
    Icons.search: Icons.saved_search,
    Icons.location_on_outlined: Icons.place,
    Icons.star_border: Icons.star,
    Icons.favorite_border: Icons.favorite,
    Icons.filter_list: Icons.tune,
    Icons.calendar_today_outlined: Icons.event,
    Icons.king_bed_outlined: Icons.king_bed,
    Icons.bathtub_outlined: Icons.bathtub,
    Icons.group_outlined: Icons.groups,
  };

  /// Heading style for LUX sections — Fraunces in gold.
  static TextStyle heading(double size) => fraunces(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: goldLight,
      );

  static TextStyle body(double size, {Color? color}) =>
      inter(fontSize: size, color: color ?? ink, height: 1.5);

  static TextStyle subtle(double size) => inter(fontSize: size, color: muted);

  /// Card decoration for a LUX listing — dark, gold-edged, softly lit.
  static BoxDecoration card({double radius = 16}) => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: line),
        boxShadow: [
          BoxShadow(
            color: gold.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      );
}

/// The LUX loading state.
///
/// Standard mode shows a teal spinner or a grey shimmer. This spells LUX: a
/// gold wordmark under a slowly rotating diamond, with a sheen crossing the
/// letters. It is the loader the mode-switch shows while the luxury listings
/// come back, so the wait itself tells you the mode changed.
class LuxLoader extends StatefulWidget {
  final String message;
  final double size;

  const LuxLoader({
    super.key,
    this.message = 'Curating luxury stays',
    this.size = 68,
  });

  @override
  State<LuxLoader> createState() => _LuxLoaderState();
}

class _LuxLoaderState extends State<LuxLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          // Triangle wave, so the ring breathes rather than jumping at the loop.
          final pulse = (0.5 - (t - 0.5).abs()) * 2;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Sweeping gold arc.
                    Transform.rotate(
                      angle: t * 2 * math.pi,
                      child: CustomPaint(
                        size: Size.square(widget.size),
                        painter: _ArcPainter(sweep: 0.25 + 0.35 * pulse),
                      ),
                    ),
                    Icon(Icons.diamond,
                        size: widget.size * 0.38,
                        color: Color.lerp(
                            Lux.goldDeep, Lux.goldLight, pulse)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // "LUX" with a sheen band travelling across it.
              ShaderMask(
                shaderCallback: (rect) {
                  final x = -1.4 + 2.8 * t;
                  return LinearGradient(
                    begin: Alignment(x - 0.6, 0),
                    end: Alignment(x + 0.6, 0),
                    colors: const [Lux.goldDeep, Lux.goldLight, Lux.goldDeep],
                  ).createShader(rect);
                },
                child: Text(
                  'LUX',
                  style: fraunces(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ).copyWith(letterSpacing: 8),
                ),
              ),
              const SizedBox(height: 8),
              Text(widget.message,
                  textAlign: TextAlign.center, style: Lux.subtle(12.5)),
            ],
          );
        },
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double sweep;
  const _ArcPainter({required this.sweep});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Lux.gold.withOpacity(0.14);
    canvas.drawArc(rect.deflate(2), 0, 2 * math.pi, false, track);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [Lux.goldDeep, Lux.goldLight, Lux.gold, Lux.goldDeep],
      ).createShader(rect);
    canvas.drawArc(rect.deflate(2), -math.pi / 2, sweep * 2 * math.pi, false, arc);
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.sweep != sweep;
}

/// A LUX section heading — gold, with a hairline rule running off to the right.
class LuxSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const LuxSectionHeader({super.key, required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (r) => Lux.goldSheen.createShader(r),
            child: Text(title,
                style: Lux.heading(17).copyWith(color: Colors.white)),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Divider(color: Lux.line, thickness: 1)),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                  foregroundColor: Lux.gold,
                  visualDensity: VisualDensity.compact),
              child: Text('See all',
                  style: inter(fontSize: 12.5, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

/// The mode switch, and the moment of switching.
///
/// Both screens used a bare Material AlertDialog — same grey box either way,
/// so the one moment that should feel like crossing into a different mode felt
/// like a permissions prompt. This one is dressed for the direction of travel,
/// and switching INTO LUX plays the LUX loader over the screen while the
/// luxury listings come back, so the transition itself carries the mode.
Future<void> showLuxSwitchDialog(
  BuildContext context, {
  required bool isLuxury,
  required Future<void> Function(bool) onSwitch,
}) async {
  final goingLux = !isLuxury;

  final confirmed = await showDialog<bool>(
    context: context,
    barrierColor: (goingLux ? Colors.black : Lux.bg).withOpacity(0.6),
    builder: (ctx) => Dialog(
      backgroundColor: goingLux ? Lux.surface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: goingLux ? Lux.line : kLine),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.diamond,
                size: 34, color: goingLux ? Lux.gold : kIndigo),
            const SizedBox(height: 14),
            Text(
              goingLux ? 'Enter LUX' : 'Back to standard',
              style: goingLux
                  ? Lux.heading(20)
                  : fraunces(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: kInk),
            ),
            const SizedBox(height: 8),
            Text(
              goingLux
                  ? 'A hand-picked collection of the finest stays on Aajoo.'
                  : 'Show every stay again, not only the luxury collection.',
              textAlign: TextAlign.center,
              style: goingLux
                  ? Lux.subtle(13)
                  : inter(fontSize: 13, color: kMuted, height: 1.45),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    style: TextButton.styleFrom(
                        foregroundColor: goingLux ? Lux.muted : kMuted,
                        padding: const EdgeInsets.symmetric(vertical: 13)),
                    child: Text('Not now',
                        style: inter(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: goingLux ? Lux.gold : kIndigo,
                      foregroundColor:
                          goingLux ? Lux.onGold : Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(goingLux ? 'Enter LUX' : 'Switch',
                        style: inter(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  if (confirmed != true) return;

  if (!goingLux) {
    await onSwitch(false);
    return;
  }

  // Going into LUX: hold the LUX loader over the screen until the luxury
  // listings are in, so there is no flash of the standard page mid-switch.
  if (context.mounted) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Lux.bg.withOpacity(0.94),
      builder: (_) => const PopScope(
        canPop: false,
        child: LuxLoader(message: 'Curating your luxury collection'),
      ),
    );
  }
  try {
    await onSwitch(true);
  } finally {
    if (context.mounted && Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
