import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/models/properties_response_model.dart';
import 'package:rent_home/ui/design/aajoo_skin.dart';
import 'package:rent_home/ui/screens_renter/property_details/property_page.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/utils/money.dart';
import 'package:shimmer/shimmer.dart';

/// The card that opens when a guest taps a pin on the map.
///
/// WHAT WAS WRONG WITH IT
///
/// It was the last screen in the app still wearing the pre-redesign look: a
/// 10px dialog, 22px bold `Colors.black87` for the name, "Price: ₹1,500" as a
/// sentence, `Colors.black54` body copy, an auto-playing carousel, and a bare
/// teal circle-arrow in the corner. Nothing on it came from the design system,
/// so tapping a pin took you out of the app's own visual language.
///
/// It also carried a **stock-photo pool**: five Unsplash hotel photographs and
/// an iStock "luxury resort", played as a carousel whenever a listing had no
/// image of its own. That is the same bug that was removed from the browse
/// card and from the website — a stay in Karnal advertising itself with
/// pictures of somewhere that does not exist, while the host believes their
/// upload worked. A listing with no photograph now looks like a listing with
/// no photograph.
///
/// Four tap targets used to push the same PropertyPage with four separately
/// written argument lists, which is four places for them to drift apart. There
/// is one now.
class HotelDialog extends StatelessWidget {
  final String name;
  final String price;
  final List<String> imageUrls;
  final String description;
  final String rating;
  final String location;
  final String coverImage;
  final int id;
  final String lat;
  final String long;
  final dynamic inTime;
  final dynamic outTime;
  final String distance;
  final Property property;

  HotelDialog({
    super.key,
    required this.name,
    required this.location,
    required this.lat,
    required this.long,
    required this.price,
    required this.imageUrls,
    required this.description,
    required this.rating,
    required this.coverImage,
    required this.id,
    required this.inTime,
    required this.outTime,
    this.distance = "1.5",
    required this.property,
  });

  final String formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

  /// The stay's own photographs, in order, with no invented ones.
  List<String> get _photos {
    final own = [
      if (coverImage.trim().isNotEmpty) coverImage.trim(),
      ...imageUrls.where((e) => e.trim().isNotEmpty),
    ];
    // De-duplicated: the cover is usually also the first gallery image.
    return own.toSet().toList();
  }

  /// "0.7 km away" — or nothing, when the distance is not a number.
  ///
  /// This used to be `distance.substring(0, 3)`, which throws a RangeError on
  /// any distance shorter than three characters and prints "12." for a
  /// two-digit one.
  String? get _distanceLabel {
    final km = double.tryParse(distance.trim());
    if (km == null || km <= 0) return null;
    return km < 1
        ? '${(km * 1000).round()} m away'
        : '${km.toStringAsFixed(1)} km away';
  }

  void _open(BuildContext context) {
    final photos = _photos;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PropertyPage(
          property: property,
          image: photos.isEmpty ? '' : photos.first,
          galleryImages: photos,
          name: name,
          description: description,
          rating: rating,
          price: price,
          id: id,
          location: location,
          lat: lat,
          long: long,
          inTime: inTime ?? formattedDate,
          outTime: outTime ?? formattedDate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LuxBuilder(
      builder: (context, skin) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: skin.card(radius: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _photo(context, skin),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _titleRow(skin),
                      const SizedBox(height: 8),
                      _priceRow(skin),
                      if (description.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          description.trim(),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: inter(
                              fontSize: 13.5, color: skin.muted, height: 1.5),
                        ),
                      ],
                      if ((property.tags ?? const []).isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _tags(skin),
                      ],
                      if (_distanceLabel != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.near_me_outlined,
                                size: 15, color: skin.primary),
                            const SizedBox(width: 6),
                            Text(
                              '${_distanceLabel!} from where you are looking',
                              style: inter(fontSize: 12.5, color: skin.muted),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: GuestSelectionContainer(
                              property: property,
                              skin: skin,
                              onSelectionConfirmed: (_) {},
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () => _open(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: skin.primary,
                                  foregroundColor: skin.onPrimary,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                ),
                                child: Text('View stay',
                                    style: inter(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600)),
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

  Widget _photo(BuildContext context, AajooSkin skin) {
    final photos = _photos;
    return GestureDetector(
      onTap: () => _open(context),
      child: SizedBox(
        height: 180,
        width: double.infinity,
        child: photos.isEmpty
            ? Container(
                color: skin.surfaceHigh,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.image_not_supported_outlined,
                          size: 26, color: skin.muted),
                      const SizedBox(height: 6),
                      Text('No photos yet',
                          style: inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: skin.muted)),
                    ],
                  ),
                ),
              )
            : PageView(
                children: photos
                    .map((url) => CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _shimmer(skin),
                          errorWidget: (_, __, ___) => Container(
                            color: skin.surfaceHigh,
                            child: Icon(Icons.broken_image_outlined,
                                color: skin.muted),
                          ),
                        ))
                    .toList(),
              ),
      ),
    );
  }

  Widget _titleRow(AajooSkin skin) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: fraunces(
                  fontSize: 18, fontWeight: FontWeight.w700, color: skin.ink),
            ),
          ),
          if (double.tryParse(rating) != null &&
              double.parse(rating) > 0) ...[
            const SizedBox(width: 10),
            Row(
              children: [
                Icon(Icons.star_rounded, size: 15, color: skin.accent),
                const SizedBox(width: 3),
                Text(double.parse(rating).toStringAsFixed(1),
                    style: inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: skin.ink)),
              ],
            ),
          ],
        ],
      );

  Widget _priceRow(AajooSkin skin) => Row(
        children: [
          Icon(Icons.location_on_outlined, size: 14, color: skin.muted),
          const SizedBox(width: 3),
          Expanded(
            child: Text(location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: inter(fontSize: 12.5, color: skin.muted)),
          ),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: rupeesFrom(price),
                style: fraunces(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: skin.ink),
              ),
              TextSpan(
                text: ' /night',
                style: inter(fontSize: 11.5, color: skin.muted),
              ),
            ]),
          ),
        ],
      );

  Widget _tags(AajooSkin skin) => Wrap(
        spacing: 6,
        runSpacing: 6,
        children: (property.tags ?? const [])
            .map((t) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: skin.primaryWash,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(t.toString(),
                      style: inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: skin.primary)),
                ))
            .toList(),
      );

  Widget _shimmer(AajooSkin skin) => Shimmer.fromColors(
        baseColor: skin.isLux ? const Color(0xFF141416) : Colors.grey[300]!,
        highlightColor:
            skin.isLux ? const Color(0xFF1D1D20) : Colors.grey[100]!,
        child: Container(color: skin.surfaceHigh),
      );
}

/// How many people are coming.
///
/// Rebuilt to the website's GuestSelector (redesign/components/GuestSelector.tsx)
/// so the same question is asked the same way on both platforms:
///
///   • Adults (13 or above), Children (2–12), Infants (under 2).
///   • The count that matters is adults + children. Infants are collected but
///     never counted, because a cot is not a bed.
///   • A child or an infant pulls in an adult — a child cannot be the one
///     making the booking.
///
/// It used to be a blue info panel, an Adults stepper on its own, and a green
/// "Total Guests: 1 / 2" bar, in `Colors.blue` and `Colors.green` — three raw
/// Material colours on a screen that has none.
class GuestSelectionContainer extends StatefulWidget {
  final Function(int guests) onSelectionConfirmed;
  final Property property;
  final AajooSkin skin;

  const GuestSelectionContainer({
    super.key,
    required this.onSelectionConfirmed,
    required this.property,
    required this.skin,
  });

  @override
  State<GuestSelectionContainer> createState() =>
      _GuestSelectionContainerState();
}

class _GuestSelectionContainerState extends State<GuestSelectionContainer> {
  int _adults = 1;
  int _children = 0;
  int _infants = 0;

  /// The ceiling this popup can honestly offer.
  ///
  /// The real number is `property_capacity`, and it is only on the
  /// single-property response — the map's Property has no capacity field at
  /// all. So this stays the category heuristic it has always been, and the
  /// sheet no longer states it as a fact about the property ("Regular Property
  /// - Max 2 guests"); the property page, which does have the record, is where
  /// the real limit is enforced.
  int get _ceiling {
    final category =
        (widget.property.categoryTitles ?? const []).join(',').toLowerCase();
    return category.contains('family') ? 4 : 2;
  }

  int get _total => _adults + _children;

  String get _label {
    final parts = <String>['$_total guest${_total == 1 ? '' : 's'}'];
    if (_infants > 0) {
      parts.add('$_infants infant${_infants == 1 ? '' : 's'}');
    }
    return parts.join(', ');
  }

  void _openSheet() {
    final skin = widget.skin;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final headroom = (_ceiling - _total).clamp(0, _ceiling);

          void set(void Function() change) {
            setSheet(change);
            setState(() {});
          }

          return Container(
            decoration: BoxDecoration(
              color: skin.sheet,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
              border: Border(top: BorderSide(color: skin.line)),
            ),
            padding: EdgeInsets.fromLTRB(
                20, 14, 20, 20 + MediaQuery.of(ctx).padding.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: skin.line,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Who is coming?',
                    style: fraunces(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: skin.ink)),
                const SizedBox(height: 4),
                Text('This stay sleeps up to $_ceiling.',
                    style: inter(fontSize: 13, color: skin.muted)),
                const SizedBox(height: 8),
                _Stepper(
                  skin: skin,
                  label: 'Adults',
                  sub: 'Ages 13 or above',
                  value: _adults,
                  min: (_children > 0 || _infants > 0) ? 1 : 0,
                  max: _adults + headroom,
                  onChanged: (v) => set(() => _adults = v),
                ),
                Divider(color: skin.line, height: 1),
                _Stepper(
                  skin: skin,
                  label: 'Children',
                  sub: 'Ages 2 – 12',
                  value: _children,
                  max: _children + headroom,
                  onChanged: (v) => set(() {
                    _children = v;
                    if (_children > 0 && _adults == 0) _adults = 1;
                  }),
                ),
                Divider(color: skin.line, height: 1),
                _Stepper(
                  skin: skin,
                  label: 'Infants',
                  sub: 'Under 2 · not counted towards the limit',
                  value: _infants,
                  max: 5,
                  onChanged: (v) => set(() {
                    _infants = v;
                    if (_infants > 0 && _adults == 0) _adults = 1;
                  }),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _total == 0
                        ? null
                        : () {
                            widget.onSelectionConfirmed(_total);
                            Navigator.of(ctx).pop();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: skin.primary,
                      foregroundColor: skin.onPrimary,
                      disabledBackgroundColor: skin.line,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                        _total == 0 ? 'Add at least one guest' : 'Confirm',
                        style: inter(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final skin = widget.skin;
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: _openSheet,
        style: OutlinedButton.styleFrom(
          foregroundColor: skin.ink,
          side: BorderSide(color: skin.line),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline, size: 17, color: skin.muted),
            const SizedBox(width: 6),
            Flexible(
              child: Text(_label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: skin.ink)),
            ),
          ],
        ),
      ),
    );
  }
}

/// One − / n / + row. Shaped after the website's Stepper.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.skin,
    required this.label,
    required this.sub,
    required this.value,
    required this.max,
    required this.onChanged,
    this.min = 0,
  });

  final AajooSkin skin;
  final String label, sub;
  final int value, min, max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final canDown = value > min;
    final canUp = value < max;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: skin.ink)),
                const SizedBox(height: 2),
                Text(sub, style: inter(fontSize: 12, color: skin.muted)),
              ],
            ),
          ),
          _round(Icons.remove, canDown, () => onChanged(value - 1)),
          SizedBox(
            width: 40,
            child: Text('$value',
                textAlign: TextAlign.center,
                style: inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: skin.ink)),
          ),
          _round(Icons.add, canUp, () => onChanged(value + 1)),
        ],
      ),
    );
  }

  Widget _round(IconData icon, bool enabled, VoidCallback onTap) => InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: enabled ? skin.muted : skin.line),
          ),
          child: Icon(icon,
              size: 17, color: enabled ? skin.ink : skin.line),
        ),
      );
}
