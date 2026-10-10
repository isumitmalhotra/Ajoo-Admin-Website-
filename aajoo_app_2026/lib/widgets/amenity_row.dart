import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/utils/fonts.dart';

/// AajooHomes amenity row — POC mobile property detail amenity strip.
///
///   ┌────┐  ┌────┐  ┌────┐  ┌────┐
///   │ 🏊 │  │ 🛏 │  │ 📶 │  │ ❄ │
///   └────┘  └────┘  └────┘  └────┘
///     Pool   4 BR   Wi-Fi   AC
///
/// Four icon-only square chips evenly spaced across the row. Label text
/// sits below each chip (Inter 11 kMuted) — small, secondary; the icon
/// carries the meaning.
///
/// Accepts a label list. Each label maps to a Material icon via
/// `_iconFor(label)`; unknown labels fall back to a checkmark.
class AmenityRow extends StatelessWidget {
  final List<String> amenities;

  const AmenityRow({
    super.key,
    this.amenities = const ['Pool', '4 BR', 'Wi-Fi', 'AC'],
  });

  static IconData _iconFor(String label) {
    final l = label.toLowerCase();
    if (l.contains('wifi') || l.contains('wi-fi') || l.contains('internet')) {
      return Icons.wifi;
    }
    if (l.contains('pool') || l.contains('swim')) return Icons.pool;
    if (l.contains('ac') || l.contains('air')) return Icons.ac_unit;
    if (l.contains('br') || l.contains('bed') || l.contains('room')) {
      return Icons.king_bed_outlined;
    }
    if (l.contains('park')) return Icons.local_parking;
    if (l.contains('tv')) return Icons.tv;
    if (l.contains('kitchen') || l.contains('cook')) return Icons.kitchen;
    if (l.contains('breakfast') || l.contains('coffee')) {
      return Icons.local_cafe_outlined;
    }
    if (l.contains('pet')) return Icons.pets;
    if (l.contains('gym')) return Icons.fitness_center;
    return Icons.check_circle_outline;
  }

  @override
  Widget build(BuildContext context) {
    if (amenities.isEmpty) return const SizedBox.shrink();
    // The label had a fixed 64 and one line, so anything past ~9 characters
    // was cut: "Fire exting…", "Dining tab…" on Green Hills Kasauli (iOS
    // Simulator, 2026-10-09; Android draws the same). It now gets two lines
    // and the width of its quarter of the row, up to 84 — wide enough that a
    // word like "extinguisher" is never split, and never wider than a quarter
    // so four of them still fit a 320-wide Android screen.
    return LayoutBuilder(builder: (context, constraints) {
      final quarter = constraints.maxWidth / 4;
      final labelWidth = (quarter - 4).clamp(56.0, 84.0);
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: amenities.take(4).map((label) {
          return _AmenityChip(
              label: label, icon: _iconFor(label), labelWidth: labelWidth);
        }).toList(),
      );
    });
  }
}

class _AmenityChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final double labelWidth;

  const _AmenityChip(
      {required this.label, required this.icon, required this.labelWidth});

  @override
  Widget build(BuildContext context) {
    final style = inter(fontSize: 11, fontWeight: FontWeight.w500, color: kMuted);
    // At a large text size one word can outgrow a quarter of the row on any
    // phone ("extinguisher" is ~88 wide at ×1.3), and Flutter would then
    // split it mid-word. These labels grow with the reader's text size only
    // as far as their longest word still fits; the full amenities list below
    // scales without limit.
    // Measured in the style the Text will actually draw with: it inherits the
    // theme's body style, letter-spacing included.
    final drawn = DefaultTextStyle.of(context).style.merge(style);
    final longestWord = label.split(' ').map((w) {
      final p = TextPainter(
        text: TextSpan(text: w, style: drawn),
        textDirection: TextDirection.ltr,
      )..layout();
      return p.width;
    }).fold<double>(0, (a, b) => a > b ? a : b);
    final fitScale = longestWord > 0 ? labelWidth / longestWord : 1.0;
    final scaler =
        MediaQuery.textScalerOf(context).clamp(maxScaleFactor: fitScale);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: kCream,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kLine),
          ),
          child: Icon(icon, size: 22, color: kInk),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: labelWidth,
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            textScaler: scaler,
            style: style,
          ),
        ),
      ],
    );
  }
}
