import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/ui/screens_renter/home/components/section_header.dart';
import 'package:rent_home/models/search_property_model.dart';
import 'package:rent_home/service/home_page_search_service.dart';
import 'package:rent_home/ui/screens_renter/home/components/lux_theme.dart';
import 'package:rent_home/utils/fonts.dart';

/// Pre-booking, by area.
///
/// The screen was one flat list of everything. The spec asks for a rail per
/// area — Shimla, Kufri, Mohali, Panchkula, Kharar — with ten to twelve stays
/// in each.
///
/// A rail with nothing in it renders nothing at all rather than a heading over
/// empty space. That matters here: Kufri is on the list and has no listings on
/// the platform today, so its rail simply will not appear until it does.
const List<String> kPreBookingAreas = [
  'Shimla',
  'Kufri',
  'Mohali',
  'Panchkula',
  'Kharar',
  'Chandigarh',
];

/// Category titles kept out of "Browse by category" on both the home and
/// pre-booking screens.
///
/// These are occupancy types from an older catalogue, not property types, and
/// the spec asks for homestays and villas in that row. They are hidden rather
/// than deleted: 10 live properties are still tagged with them, so removing
/// the rows would leave those listings with no category at all.
const Set<String> kHiddenBrowseCategories = {
  'couple',
  'party',
  'single',
  'sharing',
  'resort',
};

/// Loads each area independently, so one slow or empty area cannot hold up the
/// rest of the page.
class AreaRailsController extends GetxController {
  final _service = HomePageSearchService();

  /// area → its properties. Absent means "still loading".
  final RxMap<String, List<SearchPropertyModel>> byArea =
      <String, List<SearchPropertyModel>>{}.obs;
  final RxBool loading = true.obs;

  bool _isLuxury = false;

  Future<void> load({bool isLuxury = false, int perArea = 12}) async {
    _isLuxury = isLuxury;
    loading.value = true;
    byArea.clear();
    await Future.wait(kPreBookingAreas.map((area) async {
      try {
        final res = await _service.getPropertiesByArea(area,
            isLuxury: _isLuxury, limit: perArea);
        byArea[area] = res.data;
      } catch (_) {
        // An area that fails is an area with no rail — never an error screen.
        byArea[area] = const [];
      }
    }));
    loading.value = false;
  }
}

/// One area's horizontal rail.
class AreaRail extends StatelessWidget {
  final String area;
  final List<SearchPropertyModel> properties;
  final bool isLuxury;
  final ValueChanged<SearchPropertyModel> onOpen;
  final VoidCallback? onSeeAll;

  const AreaRail({
    super.key,
    required this.area,
    required this.properties,
    required this.onOpen,
    this.isLuxury = false,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    if (properties.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // One header in both modes. This used to fork — a gold LuxSectionHeader
          // when luxury was on and a hand-rolled Row when it wasn't — so the
          // same rail wore two different type scales and two different link
          // labels depending on the mode. SectionHeader resolves the skin
          // itself, so there is one shape and one "View all".
          SectionHeader(title: area, onViewAll: onSeeAll),
          const SizedBox(height: 10),
          SizedBox(
            height: 232,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: properties.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _AreaCard(
                property: properties[i],
                isLuxury: isLuxury,
                onTap: () => onOpen(properties[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaCard extends StatelessWidget {
  final SearchPropertyModel property;
  final bool isLuxury;
  final VoidCallback onTap;

  const _AreaCard({
    required this.property,
    required this.onTap,
    this.isLuxury = false,
  });

  @override
  Widget build(BuildContext context) {
    final img = property.coverImage;
    final price = property.propertyPrice;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 186,
        child: Container(
          decoration: isLuxury
              ? Lux.card()
              : BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kLine),
                ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 122,
                width: double.infinity,
                child: (img == null || img.isEmpty)
                    ? Container(
                        color: isLuxury ? Lux.surfaceHigh : kSand,
                        alignment: Alignment.center,
                        child: Icon(Icons.photo_outlined,
                            color: isLuxury ? Lux.muted : kMuted, size: 26),
                      )
                    : Image.network(
                        img,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: isLuxury ? Lux.surfaceHigh : kSand,
                          alignment: Alignment.center,
                          child: Icon(Icons.photo_outlined,
                              color: isLuxury ? Lux.muted : kMuted, size: 26),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.propertyName ?? 'Stay',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: isLuxury ? Lux.ink : kInk),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      // Address first, not city. property_city is unreliable
                      // across the imported dataset — a Chandigarh property
                      // comes back with city "Karol Bagh" — and the rail
                      // matched on the ADDRESS, so showing the address is both
                      // more accurate and consistent with why it is in this
                      // rail at all.
                      (property.propertyAddress?.trim().isNotEmpty ?? false)
                          ? property.propertyAddress!
                          : (property.propertyCity ?? ''),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: inter(
                          fontSize: 11.5,
                          color: isLuxury ? Lux.muted : kMuted),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      price == null || price.isEmpty ? '' : '₹$price / night',
                      style: inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isLuxury ? Lux.goldLight : kIndigo),
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
