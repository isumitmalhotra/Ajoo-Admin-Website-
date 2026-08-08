import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/utils/fonts.dart';

/// Gold luxury accents (introduced for LUX mode; complements Sand & Indigo).
const Color kGold = Color(0xFFD4AF37);
const Color kGoldLight = Color(0xFFF6E5A8);
const Color kGoldDeep = Color(0xFFB8860B);

/// Animated **LUX** toggle — a premium pill with a continuous gold sheen sweep
/// and a soft glow pulse, mirroring the web's luxury-mode flourish.
///
/// • Inactive (normal mode): light surface, gold border, indigo "LUX".
/// • Active (luxury mode):   deep-indigo gradient, gold glow, gold "NOR".
class LuxToggleButton extends StatefulWidget {
  final bool isLuxury;
  final VoidCallback onTap;
  final double height;
  final double width;

  const LuxToggleButton({
    super.key,
    required this.isLuxury,
    required this.onTap,
    this.height = 48,
    this.width = 112,
  });

  @override
  State<LuxToggleButton> createState() => _LuxToggleButtonState();
}

class _LuxToggleButtonState extends State<LuxToggleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lux = widget.isLuxury;
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          // sheen band travels from off-left to off-right across the pill
          final sheenX = -1.6 + 3.2 * t;
          // triangle wave 0 → 1 → 0 for the glow pulse
          final glow = (0.5 - (t - 0.5).abs()) * 2;
          return Container(
            height: widget.height,
            width: widget.width,
            decoration: BoxDecoration(
              color: lux ? null : kSurface,
              gradient: lux
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [kIndigo600, kIndigo],
                    )
                  : null,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: kGold.withOpacity(lux ? 0.9 : 0.65),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: kGold.withOpacity((lux ? 0.32 : 0.16) + 0.28 * glow),
                  blurRadius: 14 + 10 * glow,
                  spreadRadius: lux ? 1 : 0,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // moving gold sheen
                  Align(
                    alignment: Alignment(sheenX, 0),
                    child: FractionallySizedBox(
                      widthFactor: 0.42,
                      heightFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              kGoldLight.withOpacity(lux ? 0.5 : 0.38),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // content
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.diamond,
                          size: 17,
                          color: lux ? kGoldLight : kGoldDeep,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          lux ? 'NOR' : 'LUX',
                          style: inter(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: lux ? kGoldLight : kIndigo,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
