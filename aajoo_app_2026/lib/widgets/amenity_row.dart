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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: amenities.take(4).map((label) {
        return _AmenityChip(label: label, icon: _iconFor(label));
      }).toList(),
    );
  }
}

class _AmenityChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _AmenityChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
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
          width: 64,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: kMuted,
            ),
          ),
        ),
      ],
    );
  }
}
