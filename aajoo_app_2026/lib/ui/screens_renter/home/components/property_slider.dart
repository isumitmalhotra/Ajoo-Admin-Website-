import 'package:flutter/material.dart';
import 'package:rent_home/data/models/properties_response_model.dart';
import 'package:rent_home/ui/screens_renter/home/components/curated_card.dart';
import 'package:rent_home/ui/screens_renter/home/components/section_header.dart';

/// A horizontal row of properties under a heading with "See all" on the right.
///
/// A-22 and A-24 both ask for the same shape — a slider of 10–12 stays with
/// "See all" top-right — so both use this rather than growing two copies that
/// drift apart, which is exactly how the two category rows and their two icon
/// maps came about on this same screen.
///
/// Renders nothing when the list is empty: a heading over an empty rail reads
/// as broken, where an absent section simply is not there.
class PropertySlider extends StatelessWidget {
  final String title;
  final List<Property> properties;
  final VoidCallback? onSeeAll;
  final ValueChanged<Property> onOpen;

  /// The sheet asks for 10–12 per rail.
  final int max;

  const PropertySlider({
    super.key,
    required this.title,
    required this.properties,
    required this.onOpen,
    this.onSeeAll,
    this.max = 12,
  });

  @override
  Widget build(BuildContext context) {
    if (properties.isEmpty) return const SizedBox.shrink();
    final items = properties.take(max).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title, onViewAll: onSeeAll),
        const SizedBox(height: 12),
        SizedBox(
          height: 268,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => SizedBox(
              width: 200,
              child: CuratedCard(
                property: items[i],
                onTap: () => onOpen(items[i]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
