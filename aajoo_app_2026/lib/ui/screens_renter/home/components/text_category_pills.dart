import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/utils/fonts.dart';

/// AajooHomes category circles — re-skinned to the new teal/orange design
/// (scaffold explore category row): an icon in a teal-50 circle (teal fill when
/// active) with the label below. Constructor + wiring unchanged — the caller
/// passes the real backend categories, the selected index, and onChanged.
class TextCategoryPills extends StatelessWidget {
  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int>? onChanged;

  const TextCategoryPills({
    super.key,
    this.categories = const [
      'All',
      'Villas',
      'Heritage',
      'Beach',
      'Hills',
      'Apartments',
    ],
    this.selectedIndex = 0,
    this.onChanged,
  });

  // Map a backend category name to a representative icon (fallback for unknowns).
  static IconData _iconFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('all') || n.contains('more')) return Icons.grid_view_rounded;
    if (n.contains('homestay') || n == 'home') return Icons.home_outlined;
    if (n.contains('villa')) return Icons.villa_outlined;
    if (n.contains('cottage') || n.contains('cabin')) return Icons.cabin_outlined;
    if (n.contains('apart') || n.contains('flat')) return Icons.apartment_rounded;
    if (n.contains('farm')) return Icons.agriculture_outlined;
    if (n.contains('heritage')) return Icons.account_balance_outlined;
    if (n.contains('beach')) return Icons.beach_access_outlined;
    if (n.contains('hill') || n.contains('mountain')) return Icons.terrain_rounded;
    if (n.contains('boutique') || n.contains('hotel')) return Icons.hotel_outlined;
    if (n.contains('luxury') || n.contains('lux')) return Icons.diamond_outlined;
    if (n.contains('pet')) return Icons.pets_outlined;
    if (n.contains('tree')) return Icons.park_outlined;
    if (n.contains('pg') || n.contains('hostel')) return Icons.meeting_room_outlined;
    return Icons.holiday_village_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final isActive = index == selectedIndex;
          return _CategoryCircle(
            label: categories[index],
            icon: _iconFor(categories[index]),
            isActive: isActive,
            onTap: onChanged == null ? null : () => onChanged!(index),
          );
        },
      ),
    );
  }
}

class _CategoryCircle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback? onTap;

  const _CategoryCircle({
    required this.label,
    required this.icon,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isActive ? kIndigo : kIndigo50,
                shape: BoxShape.circle,
                border: Border.all(
                    color: isActive ? kIndigo : kLine, width: 1),
              ),
              child: Icon(icon,
                  size: 24, color: isActive ? Colors.white : kIndigo600),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: inter(
                fontSize: 11.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? kInk : kInk2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
