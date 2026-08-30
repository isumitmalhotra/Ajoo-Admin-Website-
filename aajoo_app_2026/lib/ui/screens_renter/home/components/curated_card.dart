import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/ui/design/aajoo_skin.dart';
import 'package:rent_home/data/models/properties_response_model.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/service/bookmark_service.dart';
import 'package:rent_home/utils/money.dart';

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

  /// Indian digit grouping lives in one place — utils/money.dart.
  ///
  /// This screen carried its own copy of the last-three-then-pairs rule. Two
  /// implementations of the same convention is one waiting to disagree with
  /// the other, and its fallback printed the raw column (paise included) when
  /// the price would not parse.
  String get _formattedPrice => rupeesFrom(property.propertyPrice);

  @override
  Widget build(BuildContext context) {
    final location = property.propertyCity.trim().isNotEmpty
        ? property.propertyCity
        : property.propertyAddress;
    // The card is the surface a guest spends most of their time looking at,
    // so it is the one that most gave away that LUX had not really happened:
    // a wall of white cards on a black sheet. It resolves the skin now — in
    // LUX that is the faint lift of light over the ground with a gold
    // hairline that the site uses, not a painted panel.
    return LuxBuilder(
      builder: (context, skin) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: skin.card(),
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
                                  color: skin.surfaceHigh,
                                  child: Icon(
                                      Icons.image_not_supported_outlined,
                                      color: skin.muted,
                                      size: 30)))
                          : Container(
                              color: skin.surfaceHigh,
                              child: Icon(Icons.home_outlined,
                                  color: skin.muted, size: 30)),
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
                  // Sponsored chip — the disclosure half of paid placement
                  // (Boost). Gold, and NOT the same pill as Verified: a guest
                  // must be able to tell "the platform checked this host"
                  // from "this host paid to be here" at a glance. Sits under
                  // the Verified pill so the two never overlap.
                  if (property.isBoosted)
                    Positioned(
                      top: 38,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                            color: const Color(0xCC92650F),
                            borderRadius: BorderRadius.circular(999)),
                        child: Text('Sponsored',
                            style: inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ),
                    ),
                  // A running discount. Bottom-LEFT, away from Verified and
                  // Sponsored at the top and the heart at top-right: a claim
                  // about money must not be mistakable for a trust badge or
                  // for paid placement. Same reasoning as the web card.
                  if (property.offer != null)
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                            color: const Color(0xF0DC2626),
                            borderRadius: BorderRadius.circular(999)),
                        child: Text('${property.offer!.percent}% off',
                            style: inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
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
                              color: skin.isLux
                                  ? const Color(0xD90E0E10)
                                  : Colors.white.withOpacity(0.92),
                              shape: BoxShape.circle),
                          // Filled when the stay IS saved. This was a constant
                          // outline heart, so a saved stay looked unsaved
                          // everywhere it appeared — including inside Saved
                          // Stays, where every card is saved by definition.
                          // Rebuilt on the service's revision so tapping one
                          // heart updates every copy of that card on screen.
                          child: ValueListenableBuilder<int>(
                            valueListenable: BookmarkService().revision,
                            builder: (_, __, ___) {
                              final saved = BookmarkService()
                                  .isSavedNow(property.propertyId);
                              return Icon(
                                saved
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 16,
                                color: saved
                                    ? skin.accent
                                    : (skin.isLux ? skin.ink : kInk),
                              );
                            },
                          ),
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
                      Icon(Icons.location_on_outlined,
                          size: 12, color: skin.muted),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: inter(fontSize: 12, color: skin.muted)),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text(property.propertyName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: fraunces(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: skin.ink)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // The real average, or "New" when nobody has reviewed
                        // it. This showed a hardcoded 4.5 on every card.
                        if (property.rating != null)
                          Row(children: [
                            Icon(Icons.star_rounded,
                                size: 14, color: skin.accent),
                            const SizedBox(width: 3),
                            Text(property.ratingLabel,
                                style: inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: skin.ink)),
                            const SizedBox(width: 3),
                            Text('(${property.reviewCount})',
                                style: inter(fontSize: 11, color: skin.muted)),
                          ])
                        else
                          Text('New',
                              style: inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: skin.muted)),
                        RichText(
                          text: TextSpan(children: [
                            // The old price first, so the eye lands on the
                            // saving before the number being charged.
                            if (property.offer != null)
                              TextSpan(
                                  text: '${rupees(property.offer!.was)} ',
                                  style: inter(fontSize: 12, color: skin.muted)
                                      .copyWith(
                                          decoration:
                                              TextDecoration.lineThrough)),
                            TextSpan(
                                text: property.offer != null
                                    ? rupees(property.offer!.now)
                                    : _formattedPrice,
                                style: fraunces(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: skin.ink)),
                            TextSpan(
                                text: '/night',
                                style: inter(fontSize: 11, color: skin.muted)),
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
      ),
    );
  }
}
