import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/ui/design/aajoo_skin.dart';
import 'package:rent_home/data/models/properties_response_model.dart';
import 'package:rent_home/models/property_offer.dart';
import 'package:rent_home/controller/deals_controller.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/service/bookmark_service.dart';
import 'package:rent_home/utils/money.dart';
import 'package:rent_home/ui/widgets/cancellation_badge.dart';

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

  /// What this card prices with: the guest's own negotiated deal when they
  /// have one for this stay, otherwise the host's running offer.
  ///
  /// Client, 2026-09-16: "I negotiated on a property but did not book. Back
  /// on the home page I should see the changed price — the one I last
  /// accepted, with the discount and all, should show outside too." Every
  /// card priced at the list rate, because a deal is per-guest and the card
  /// never asked for one. The deal is DATE-LOCKED and expires at midnight,
  /// so the card wears it the way it wears a running discount — struck
  /// price, deal price, a "% off" pill — rather than silently printing a
  /// smaller number, and openPropertyById carries the agreed nights.
  ///
  /// Percentage deals only: a negotiated deal is always a percentage of the
  /// room, and an amount coupon cannot be turned into a per-night figure
  /// without knowing the stay.
  PropertyOffer? get _shownOffer {
    if (property.offer != null) return property.offer;
    if (!Get.isRegistered<DealsController>()) return null;
    final deal = Get.find<DealsController>().forProperty(property.propertyId);
    if (deal == null || deal.type != 'percent' || deal.percent <= 0) {
      return null;
    }
    final was = double.tryParse(
            property.propertyPrice.replaceAll(RegExp(r'[^0-9.]'), '')) ??
        0;
    if (was <= 0) return null;
    // Rounded UP, so the card never advertises a nightly price below the one
    // the server will quote. The quote is still the authority.
    final now = (was * (1 - deal.percent / 100)).ceilToDouble();
    return PropertyOffer(
      id: -1,
      title: 'Your negotiated deal',
      was: was,
      now: now,
      percent: deal.percent.round(),
    );
  }

  static const double _imageHeight = 150;
  static const double _textPadding = 13;

  /// The height this card needs, measured with the fonts and the text size
  /// actually in use, for a parent that has to fix it in advance — the home
  /// rail (a horizontal list must know its height) and the Saved grid.
  ///
  /// Both used constants: the rail 268 and the grid an aspect ratio of 0.72.
  /// The image is a fixed 150 and the text does not grow with the tile, so a
  /// ratio is wrong at any width but one, and 268 left ONE pixel of room —
  /// spent the moment a property carries a cancellation policy, whose badge
  /// adds about 21 (Kasauli and Kharar both overflowed by 5 on an iPhone 18
  /// Pro Max), and by any accessibility text size before that. Measuring the
  /// lines makes the height follow the text scale; [_headroom] is real room
  /// for font rounding rather than a single pixel.
  static const double _headroom = 8;

  static double extentFor(BuildContext context,
      {required bool withCancellationBadge}) {
    final scaler = MediaQuery.textScalerOf(context);
    // The card's Text widgets inherit the theme's bodyMedium through Material
    // — including its line height — so the lines are measured in the same
    // style they will be drawn in, not the bare style passed to them.
    final base = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    double line(TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: 'Hg₹', style: base.merge(style)),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      return painter.height;
    }

    final location = math.max(12.0, line(inter(fontSize: 12)));
    final badge = withCancellationBadge
        ? line(inter(fontSize: 10, fontWeight: FontWeight.w700)) + 2 * 2 + 4
        : 0.0;
    final title = line(fraunces(fontSize: 15, fontWeight: FontWeight.w600));
    final priceRow = [
      14.0, // star icon
      line(inter(fontSize: 12.5, fontWeight: FontWeight.w700)),
      line(fraunces(fontSize: 15, fontWeight: FontWeight.w700)),
    ].reduce(math.max);
    return _imageHeight +
        _textPadding * 2 +
        location +
        4 +
        badge +
        title +
        8 +
        priceRow +
        _headroom;
  }

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
                      height: _imageHeight,
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
                  if (_shownOffer != null)
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                            color: const Color(0xF0DC2626),
                            borderRadius: BorderRadius.circular(999)),
                        child: Text('${_shownOffer!.percent}% off',
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
                padding: const EdgeInsets.all(_textPadding),
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
                    if (CancellationBadge.has(property.propertyCancellationPolicy))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: CancellationBadge(property.propertyCancellationPolicy, compact: true),
                      ),
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
                        // Gives way too: at a large text size on a narrow
                        // two-column tile, "★ 4.8 (124)" alone is wider than
                        // the card.
                        if (property.rating != null)
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
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
                          ]),
                            ),
                          )
                        else
                          Text('New',
                              style: inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: skin.muted)),
                        // Text.rich, not RichText: RichText ignores the
                        // reader's text size, so the price stayed small while
                        // the rest of the card grew. And it gives way rather
                        // than overflowing when a struck price and a rating
                        // share a narrow two-column tile.
                        const SizedBox(width: 6),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text.rich(
                          TextSpan(children: [
                            // The old price first, so the eye lands on the
                            // saving before the number being charged.
                            if (_shownOffer != null)
                              TextSpan(
                                  text: '${rupees(_shownOffer!.was)} ',
                                  style: inter(fontSize: 12, color: skin.muted)
                                      .copyWith(
                                          decoration:
                                              TextDecoration.lineThrough)),
                            TextSpan(
                                text: _shownOffer != null
                                    ? rupees(_shownOffer!.now)
                                    : _formattedPrice,
                                style: fraunces(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: skin.ink)),
                            TextSpan(
                                text: '/night',
                                style: inter(fontSize: 11, color: skin.muted)),
                          ]),
                          maxLines: 1,
                        ),
                          ),
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
