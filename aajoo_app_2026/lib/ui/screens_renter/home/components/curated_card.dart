import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/data/models/properties_response_model.dart';
import 'package:rent_home/utils/fonts.dart';

/// AajooHomes property card — re-skinned to the new teal/orange design
/// (scaffold property_card.dart): white bordered card, image with a badge +
/// heart, then location · title · rating + price row. Constructor + real data
/// fields unchanged so every caller stays wired.
class CuratedCard extends StatelessWidget {
  final Property property;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final String rating;

  const CuratedCard({
    super.key,
    required this.property,
    this.onTap,
    this.onFavoriteTap,
    this.rating = '4.5',
  });

  String get _formattedPrice {
    final raw = property.propertyPrice.split('.').first.trim();
    if (raw.isEmpty || int.tryParse(raw) == null) {
      return '₹${property.propertyPrice}';
    }
    final n = int.parse(raw);
    final s = n.toString();
    if (s.length <= 3) return '₹$s';
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final buf = StringBuffer();
    while (rest.length > 2) {
      buf.write(',');
      buf.write(rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    return '₹$rest${buf.toString().split('').reversed.join('')},$last3';
  }

  @override
  Widget build(BuildContext context) {
    final location = property.propertyCity.trim().isNotEmpty
        ? property.propertyCity
        : property.propertyAddress;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: kLine),
            boxShadow: kSoftShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with badge + heart
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(18)),
                    child: SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: (property.coverImage != null &&
                              property.coverImage!.isNotEmpty)
                          ? Image.network(property.coverImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                  color: kSand,
                                  child: const Icon(
                                      Icons.image_not_supported_outlined,
                                      color: kMuted,
                                      size: 30)))
                          : Container(
                              color: kSand,
                              child: const Icon(Icons.home_outlined,
                                  color: kMuted, size: 30)),
                    ),
                  ),
                  // Verified badge (dark pill, top-left)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                          color: kInk.withOpacity(0.72),
                          borderRadius: BorderRadius.circular(999)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.verified,
                            size: 11, color: Colors.white),
                        const SizedBox(width: 4),
                        Text('Verified',
                            style: inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ]),
                    ),
                  ),
                  // Heart (top-right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onFavoriteTap,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.92),
                              shape: BoxShape.circle),
                          child: const Icon(Icons.favorite_border,
                              size: 16, color: kInk),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Text
              Padding(
                padding: const EdgeInsets.all(13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: kMuted),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: inter(fontSize: 12, color: kMuted)),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text(property.propertyName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: fraunces(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: kInk)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // The real average, or "New" when nobody has reviewed
                        // it. This showed a hardcoded 4.5 on every card.
                        if (property.rating != null)
                          Row(children: [
                            const Icon(Icons.star_rounded,
                                size: 14, color: kClay),
                            const SizedBox(width: 3),
                            Text(property.ratingLabel,
                                style: inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(width: 3),
                            Text('(${property.reviewCount})',
                                style: inter(fontSize: 11, color: kMuted)),
                          ])
                        else
                          Text('New',
                              style: inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: kMuted)),
                        RichText(
                          text: TextSpan(children: [
                            TextSpan(
                                text: _formattedPrice,
                                style: fraunces(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: kInk)),
                            TextSpan(
                                text: '/night',
                                style: inter(fontSize: 11, color: kMuted)),
                          ]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
