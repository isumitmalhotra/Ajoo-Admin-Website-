import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/data/models/properties_response_model.dart';
import 'package:rent_home/data/models/search_property_model.dart';
import 'package:rent_home/service/bookmark_service.dart';
import 'package:rent_home/ui/design/aajoo_skin.dart';
import 'package:rent_home/ui/screens_renter/property_details/property_page.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/utils/money.dart';

/// The full-width stay card on the Pre-Booking / browse screen.
///
/// WHY THIS WAS REBUILT
///
/// Every other card in the app is the same object: an 18px radius, a photo
/// with a pill over it and a heart, then location · title · rating + price,
/// in Poppins and Manrope on the brand tokens. This one was not. It was the
/// last card still drawing in raw Material — `Colors.black87`,
/// `Colors.grey[600]`, `Colors.green[700]`, `Colors.amber[700]` — and styling
/// its text off `Theme.of(context).textTheme` instead of the app's own type
/// helpers, so on the one screen a guest browses in, the cards belonged to a
/// different product. That is what "the pre-booking design does not match the
/// app theme" is.
///
/// Four things it said were not true, which is worse than a mismatched colour:
///
///   * "Guest Favorite" on EVERY card, with nothing behind it. It is earned
///     now — a real average of 4.5+ over at least three reviews — so the badge
///     means something when it appears.
///   * "★ 4.5" on every card, hardcoded. /properties/list has returned a real
///     `rating` and `reviewCount` per row since the ratings sprint; the card
///     threw them away and printed a constant. Unrated stays read "New",
///     because unrated is unknown, not average.
///   * "Free Cancellation" on every card. No row in this response carries a
///     cancellation policy, so this was a promise made on the platform's
///     behalf that the platform had not agreed to. Gone until the field is.
///   * A price with `TextDecoration.underline`, which reads as a hyperlink.
///
/// And two that were broken rather than untrue: the heart did nothing at all
/// (`onPressed: () { // Handle favorite action }`), and the card opened a
/// property with `pushReplacement`, so Back from a stay left the browse screen
/// entirely instead of returning to the results.
class PreBookingCard extends StatelessWidget {
  const PreBookingCard({
    super.key,
    required this.property,
    this.index,
    this.fill = false,
  });

  final SearchPropertyModel property;
  final int? index;

  /// Let the photo take whatever height is left instead of a fixed 200.
  ///
  /// The tablet branch of the browse screen lays these out in a grid with a
  /// fixed `mainAxisExtent`, and a card that is taller than its tile does not
  /// scroll — it overflows, and Flutter paints the yellow-and-black stripes
  /// over the bottom of it. The old card put a 300px photograph in a 330px
  /// tile with a hundred points of text under it, so on a tablet every card
  /// in the grid was striped. With `fill` the card is exactly as tall as the
  /// tile it is given, whatever that turns out to be.
  final bool fill;

  // NO stock-photo pool. Five Unsplash hotel photographs and an iStock
  // "luxury resort" used to play as a carousel whenever a listing had no cover
  // image — so a property in Karnal advertised itself to guests with pictures
  // of somewhere that does not exist, and the host believed their upload had
  // worked because the card was full of pictures. The web page had the same
  // pool and it was removed there; this is the app's copy.
  //
  // A listing with no photograph must look like a listing with no photograph.

  /// The card's own Property, for navigation and for the bookmark service.
  Property get _asProperty {
    final images =
        (property.images ?? const <String>[]).map((e) => e.toString()).toList();
    final categories = () {
      final ct = property.categoryTitles;
      if (ct == null) return <String>[];
      if (ct is List) return ct.map((e) => e.toString()).toList();
      return <String>[ct.toString()];
    }();

    return Property(
      propertyId: property.propertyId,
      propertyName: property.propertyName ?? 'Unnamed Property',
      propertyAddress: property.propertyAddress ?? 'No address',
      propertyDesc: property.propertyDesc ?? 'No description',
      propertyPrice: property.propertyPrice ?? '0.0',
      propertyCity: property.propertyCity ?? 'Unknown City',
      propertyLongitude: property.propertyLongitude ?? '0',
      propertyLatitude: property.propertyLatitude ?? '0',
      propertyHostId: property.propertyHostId,
      propertyZip: property.propertyZip,
      propertyContact: property.propertyContact,
      propDetailsPropDetailIsPetFriendly:
          property.propDetailsPropDetailIsPetFriendly,
      propDetailsPropDetailIsSmoke: property.propDetailsPropDetailIsSmoke,
      propDetailsPropDetailInTime: property.propDetailsPropDetailInTime,
      propDetailsPropDetailOutTime: property.propDetailsPropDetailOutTime,
      propDetailsPropDetailExtra: property.propDetailsPropDetailExtra,
      coverImage: property.coverImage,
      images: images,
      categoryTitles: categories,
    );
  }

  /// Earned, not printed on everything: a real average of 4.5 or better over
  /// enough reviews for the average to mean anything.
  bool get _isGuestFavourite =>
      (property.rating ?? 0) >= 4.5 && property.reviewCount >= 3;

  void _open(BuildContext context) {
    final p = _asProperty;
    final images = p.images ?? const <String>[];
    // push, not pushReplacement — Back belongs to the results you came from.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PropertyPage(
          property: p,
          price: property.propertyPrice.toString(),
          name: property.propertyName.toString(),
          location: property.propertyAddress.toString(),
          image: property.coverImage.toString(),
          id: property.propertyId!,
          rating: property.rating?.toStringAsFixed(1) ?? '',
          description: property.propertyDesc.toString(),
          lat: property.propertyLatitude.toString(),
          long: property.propertyLongitude.toString(),
          galleryImages: images,
          showNegotiationButton: false,
          inTime: property.propDetailsPropDetailInTime.toString(),
          outTime: property.propDetailsPropDetailOutTime.toString(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LuxBuilder(
      builder: (context, skin) => FadeInUp(
        duration: const Duration(milliseconds: 300),
        delay: Duration(milliseconds: 100 * (index ?? 0)),
        child: Padding(
          padding: EdgeInsets.only(bottom: fill ? 0 : 16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _open(context),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: skin.card(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
                  children: [
                    if (fill)
                      Expanded(child: _photo(skin))
                    else
                      _photo(skin),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: _details(skin),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _photo(AajooSkin skin) {
    final url = property.coverImage;
    return Stack(
      fit: fill ? StackFit.expand : StackFit.loose,
      children: [
        SizedBox(
          height: fill ? null : 200,
          width: double.infinity,
          child: (url != null && url.isNotEmpty)
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _noPhoto(skin),
                )
              : _noPhoto(skin),
        ),

        // Earned badges, top-left, stacked so they cannot overlap. "Luxury"
        // used to sit at top-right, directly under the heart — two controls
        // fighting for the same 40 points of corner.
        Positioned(
          top: 12,
          left: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (property.isLuxury == 1)
                _Badge(
                  label: 'Luxury',
                  icon: Icons.diamond_outlined,
                  bg: const Color(0xFFD4AF37),
                  fg: const Color(0xFF1A1508),
                ),
              if (_isGuestFavourite) ...[
                if (property.isLuxury == 1) const SizedBox(height: 6),
                _Badge(
                  label: 'Guest favourite',
                  icon: Icons.workspace_premium_outlined,
                  bg: kInk.withOpacity(0.72),
                  fg: Colors.white,
                ),
              ],
            ],
          ),
        ),

        Positioned(
          top: 10,
          right: 10,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => BookmarkService().toggleBookmark(_asProperty),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: skin.isLux
                      ? const Color(0xD90E0E10)
                      : Colors.white.withOpacity(0.92),
                  shape: BoxShape.circle,
                ),
                child: ValueListenableBuilder<int>(
                  valueListenable: BookmarkService().revision,
                  builder: (_, __, ___) {
                    final saved =
                        BookmarkService().isSavedNow(property.propertyId);
                    return Icon(
                      saved ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: saved ? skin.accent : (skin.isLux ? skin.ink : kInk),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _noPhoto(AajooSkin skin) => Container(
        color: skin.surfaceHigh,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_not_supported_outlined,
                  size: 28, color: skin.muted),
              const SizedBox(height: 8),
              Text('No photos yet',
                  style: inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: skin.muted)),
            ],
          ),
        ),
      );

  Widget _details(AajooSkin skin) {
    final address = [
      property.propertyAddress?.trim(),
      property.propertyCity?.trim(),
    ].where((e) => e != null && e.isNotEmpty).join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_on_outlined, size: 13, color: skin.muted),
            const SizedBox(width: 3),
            Expanded(
              child: Text(
                address.isEmpty ? 'Location not given' : address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: inter(fontSize: 12.5, color: skin.muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                property.propertyName ?? 'Unnamed Property',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: fraunces(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w600,
                    color: skin.ink),
              ),
            ),
            const SizedBox(width: 10),
            // The row's own rating, or "New". Not a constant 4.5.
            if (property.rating != null)
              Row(
                children: [
                  Icon(Icons.star_rounded, size: 15, color: skin.accent),
                  const SizedBox(width: 3),
                  Text(property.rating!.toStringAsFixed(1),
                      style: inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: skin.ink)),
                  if (property.reviewCount > 0) ...[
                    const SizedBox(width: 3),
                    Text('(${property.reviewCount})',
                        style: inter(fontSize: 11.5, color: skin.muted)),
                  ],
                ],
              )
            else
              Text('New',
                  style: inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: skin.muted)),
          ],
        ),
        if (property.propDetailsPropDetailInTime != null &&
            property.propDetailsPropDetailOutTime != null) ...[
          const SizedBox(height: 6),
          Text(
            'Check-in ${property.propDetailsPropDetailInTime} · '
            'Check-out ${property.propDetailsPropDetailOutTime}',
            style: inter(fontSize: 11.5, color: skin.muted),
          ),
        ],
        const SizedBox(height: 10),
        RichText(
          text: TextSpan(children: [
            // A running offer replaces the price and strikes the old one, the
            // same as the home card and the web. Search results are where most
            // guests meet a listing first, so a discount that shows on the
            // detail page but not here is a discount nobody finds.
            if (property.offer != null)
              TextSpan(
                text: '${rupees(property.offer!.was)} ',
                style: inter(fontSize: 13, color: skin.muted)
                    .copyWith(decoration: TextDecoration.lineThrough),
              ),
            TextSpan(
              text: property.offer != null
                  ? rupees(property.offer!.now)
                  : property.propertyPrice == null
                      ? 'Price on request'
                      : rupeesFrom(property.propertyPrice),
              style: fraunces(
                  fontSize: 18, fontWeight: FontWeight.w700, color: skin.ink),
            ),
            if (property.propertyPrice != null)
              TextSpan(
                text: ' /night',
                style: inter(fontSize: 12, color: skin.muted),
              ),
          ]),
        ),
      ],
    );
  }
}

/// One pill over the photo. Shaped after the reference app's `Badgee`:
/// 999 radius, 11px Manrope w600, icon at 12.
class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
  });

  final String label;
  final IconData icon;
  final Color bg, fg;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
            Text(label,
                style: inter(
                    fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
          ],
        ),
      );
}
