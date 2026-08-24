import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/data/models/properties_response_model.dart';
import 'package:rent_home/ui/screens_renter/home/map/map_controller.dart';
import 'package:rent_home/utils/fonts.dart';

/// AajooHomes search sheet — Airbnb-style search modal.
///
///   Header: Search title + close
///   "Where to?" Fraunces big heading
///   Where: cream pill text input (filters suggestions as you type)
///   Suggested destinations: derived live from mapController.allProperties
///       (grouped by city), with "Nearby" at top using current GPS center
///   When: collapsed row → showDateRangePicker
///   Who:  collapsed row → guest stepper bottom sheet
///   Advanced filters: expandable section with existing radius/price sliders
///   Bottom action bar: Clear all + Search button
///
/// V1 behaviour:
///   - Where & Suggested → re-centers map via `fetchPropertiesAt(LatLng)`
///   - Price sliders → `applyPriceFilter(minPrice, maxPrice)`
///   - Radius → passed through to fetch
///   - When/Who → recorded on MapController (setStay) and sent with every
///     fetch as `from`/`to`/`guests`, and carried onto the property page so
///     checkout is not asked the same two questions again.
///     (This comment used to say the API had no date or guest params. It has
///     had all three for a while — see schema/properties.schema.js — so the
///     answers were being collected from the guest and thrown away.)
Future<void> showSearchSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: kInk.withOpacity(0.4),
    builder: (_) => const SearchSheet(),
  );
}

class SearchSheet extends StatefulWidget {
  const SearchSheet({super.key});

  @override
  State<SearchSheet> createState() => _SearchSheetState();
}

/// Distinct destination derived from the property list.
class _Destination {
  final String city;
  final LatLng position;
  final int count;
  final String? subtitle;

  const _Destination({
    required this.city,
    required this.position,
    required this.count,
    this.subtitle,
  });
}

class _SearchSheetState extends State<SearchSheet> {
  final MapController mapController = Get.find<MapController>();

  final TextEditingController _whereController = TextEditingController();
  String _whereQuery = '';

  // Selection state
  _Destination? _selected;
  DateTimeRange? _dateRange;
  int _guests = 1;

  // Advanced filter state (mirrors FilterDialogContent defaults)
  double _radius = 1.0;
  double _weeklyPrice = 500.0;
  double _monthlyPrice = 2000.0;
  bool _weeklyAny = true;
  bool _monthlyAny = true;
  bool _advancedExpanded = false;

  @override
  void dispose() {
    _whereController.dispose();
    super.dispose();
  }

  /// Group `allProperties` by city, count, take a representative lat/lng
  /// from the first property in each group. Sort by count desc.
  List<_Destination> _deriveDestinations() {
    final all = mapController.allProperties.isEmpty
        ? mapController.properties
        : mapController.allProperties;
    final Map<String, List<Property>> byCity = {};
    for (final p in all) {
      final c = p.propertyCity.trim();
      if (c.isEmpty) continue;
      byCity.putIfAbsent(c, () => []).add(p);
    }
    final destinations = byCity.entries.map((e) {
      final first = e.value.first;
      final lat = double.tryParse(first.propertyLatitude) ?? 0.0;
      final lng = double.tryParse(first.propertyLongitude) ?? 0.0;
      return _Destination(
        city: e.key,
        position: LatLng(lat, lng),
        count: e.value.length,
        subtitle:
            '${e.value.length} stay${e.value.length == 1 ? '' : 's'}',
      );
    }).toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return destinations;
  }

  List<_Destination> _filteredDestinations() {
    final all = _deriveDestinations();
    if (_whereQuery.trim().isEmpty) return all;
    final q = _whereQuery.trim().toLowerCase();
    return all.where((d) => d.city.toLowerCase().contains(q)).toList();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _dateRange,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kIndigo,
              onPrimary: kCream,
              surface: kCream,
              onSurface: kInk,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  Future<void> _pickGuests() async {
    final result = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: kCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        int local = _guests;
        return StatefulBuilder(
          builder: (ctx, setSheet) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Who',
                  style: fraunces(
                      fontSize: 22, fontWeight: FontWeight.w500, color: kInk),
                ),
                const SizedBox(height: 4),
                Text(
                  'How many guests are coming?',
                  style: inter(fontSize: 13, color: kMuted),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        local == 1 ? '1 guest' : '$local guests',
                        style: inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: kInk),
                      ),
                    ),
                    _RoundIconButton(
                      icon: Icons.remove,
                      onTap: local > 1
                          ? () => setSheet(() => local--)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 30,
                      child: Text('$local',
                          textAlign: TextAlign.center,
                          style: inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: kInk)),
                    ),
                    const SizedBox(width: 12),
                    _RoundIconButton(
                      icon: Icons.add,
                      onTap: local < 16
                          ? () => setSheet(() => local++)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, local),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kIndigo,
                      foregroundColor: kCream,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Save',
                        style: inter(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
                SizedBox(height: MediaQuery.of(ctx).padding.bottom),
              ],
            ),
          ),
        );
      },
    );
    if (result != null) setState(() => _guests = result);
  }

  void _clearAll() {
    setState(() {
      _selected = null;
      _whereController.clear();
      _whereQuery = '';
      _dateRange = null;
      _guests = 1;
      _radius = 1.0;
      _weeklyPrice = 500.0;
      _monthlyPrice = 2000.0;
      _weeklyAny = true;
      _monthlyAny = true;
    });
  }

  /// DD-MM-YYYY — the shape the API and the web client both use.
  String _dmy(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

  Future<void> _onSearch() async {
    final radiusStr = _radius > 0 ? _radius.round().toString() : '';

    // Record what the guest actually asked for BEFORE fetching.
    //
    // "When" and "Who" were captured into local state here and never used —
    // the fetch ignored them, so a stay already booked for those nights still
    // appeared and a party of six was offered places that sleep two; and
    // opening a stay asked for both all over again. The controller holds them
    // now, so they narrow the search and travel to the property page.
    mapController.setStay(
      from: _dateRange == null ? null : _dmy(_dateRange!.start),
      to: _dateRange == null ? null : _dmy(_dateRange!.end),
      guests: _guests,
    );

    if (_selected != null) {
      await mapController.fetchPropertiesAt(_selected!.position,
          radius: radiusStr);
    } else {
      await mapController.fetchProperties(radius: radiusStr);
    }
    mapController.applyPriceFilter(
      minPrice: _weeklyAny ? null : _weeklyPrice,
      maxPrice: _monthlyAny ? null : _monthlyPrice,
    );
    if (mounted) Navigator.of(context).pop();
  }

  String get _whenLabel {
    if (_dateRange == null) return 'Any dates';
    final fmt = DateFormat('d MMM');
    return '${fmt.format(_dateRange!.start)} – ${fmt.format(_dateRange!.end)}';
  }

  String get _whoLabel => _guests == 1 ? '1 guest' : '$_guests guests';

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Container(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.92),
      decoration: const BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _header(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Where to?',
                    style: fraunces(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      color: kInk,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _whereInput(),
                  const SizedBox(height: 20),
                  _suggestedSection(),
                  const SizedBox(height: 20),
                  const Divider(color: kLine, height: 1),
                  const SizedBox(height: 8),
                  _summaryRow(
                    label: 'When',
                    value: _whenLabel,
                    onTap: _pickDateRange,
                  ),
                  const Divider(color: kLine, height: 1),
                  _summaryRow(
                    label: 'Who',
                    value: _whoLabel,
                    onTap: _pickGuests,
                  ),
                  const Divider(color: kLine, height: 1),
                  const SizedBox(height: 8),
                  _advancedFilters(),
                ],
              ),
            ),
          ),
          _bottomBar(),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 12, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: kInk),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              'Search',
              textAlign: TextAlign.center,
              style: inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: kInk,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _whereInput() {
    return Container(
      decoration: BoxDecoration(
        color: kCream,
        border: Border.all(color: kLine),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: kInk.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _whereController,
        onChanged: (v) => setState(() => _whereQuery = v),
        style: inter(fontSize: 14, color: kInk, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Search destinations',
          hintStyle: inter(fontSize: 14, color: kMuted),
          prefixIcon: const Icon(Icons.search, color: kInk, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        ),
      ),
    );
  }

  Widget _suggestedSection() {
    return Obx(() {
      // Re-evaluate when the property list changes.
      mapController.allProperties.length; // explicit dep on the RxList
      final destinations = _filteredDestinations();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suggested destinations',
            style: inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: kMuted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          _suggestionTile(
            icon: Icons.near_me_outlined,
            title: 'Nearby',
            subtitle: "Find what's around you",
            isSelected: _selected == null && _whereQuery.isEmpty,
            onTap: () {
              setState(() {
                _selected = null;
                _whereController.clear();
                _whereQuery = '';
              });
            },
          ),
          if (destinations.isEmpty) ...[
            const SizedBox(height: 16),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  _whereQuery.trim().isEmpty
                      ? 'No listings yet — try Nearby to discover stays.'
                      : 'No matches for “${_whereQuery.trim()}”',
                  textAlign: TextAlign.center,
                  style: inter(fontSize: 13, color: kMuted),
                ),
              ),
            ),
          ] else
            ...destinations.map(
              (d) => _suggestionTile(
                icon: Icons.location_city_outlined,
                title: d.city,
                subtitle: d.subtitle ?? '',
                isSelected: _selected?.city == d.city,
                onTap: () {
                  setState(() {
                    _selected = d;
                    _whereController.text = d.city;
                    _whereQuery = d.city;
                  });
                },
              ),
            ),
        ],
      );
    });
  }

  Widget _suggestionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected ? kIndigo : kSand,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSelected ? kIndigo : kLine),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? kCream : kInk2,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: kInk,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: inter(fontSize: 12, color: kMuted),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: kInk,
                ),
              ),
            ),
            Text(
              value,
              style: inter(fontSize: 14, color: kMuted),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: kMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _advancedFilters() {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 12),
        initiallyExpanded: _advancedExpanded,
        onExpansionChanged: (v) => setState(() => _advancedExpanded = v),
        title: Text(
          'Advanced filters',
          style: inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: kInk,
          ),
        ),
        iconColor: kInk,
        collapsedIconColor: kInk,
        children: [
          _sliderBlock(
            label: 'Search radius',
            valueLabel: '${_radius.round()} km',
            value: _radius,
            min: 1,
            max: 15,
            divisions: 14,
            onChanged: (v) => setState(() => _radius = v),
          ),
          _sliderBlock(
            label: 'Weekly price',
            valueLabel: _weeklyAny ? 'Any' : '₹${_weeklyPrice.round()}',
            value: _weeklyAny ? 500 : _weeklyPrice,
            min: 100,
            max: 5000,
            divisions: 49,
            onChanged: (v) => setState(() => _weeklyPrice = v),
            anyChecked: _weeklyAny,
            onAnyToggle: (v) => setState(() => _weeklyAny = v ?? false),
          ),
          _sliderBlock(
            label: 'Monthly price',
            valueLabel:
                _monthlyAny ? 'Any' : '₹${_monthlyPrice.round()}',
            value: _monthlyAny ? 2000 : _monthlyPrice,
            min: 500,
            max: 20000,
            divisions: 39,
            onChanged: (v) => setState(() => _monthlyPrice = v),
            anyChecked: _monthlyAny,
            onAnyToggle: (v) => setState(() => _monthlyAny = v ?? false),
          ),
        ],
      ),
    );
  }

  Widget _sliderBlock({
    required String label,
    required String valueLabel,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    bool? anyChecked,
    ValueChanged<bool?>? onAnyToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: inter(
                      fontSize: 13,
                      color: kInk,
                      fontWeight: FontWeight.w500),
                ),
              ),
              Text(valueLabel,
                  style: inter(
                      fontSize: 13,
                      color: kMuted,
                      fontWeight: FontWeight.w500)),
              if (onAnyToggle != null) ...[
                const SizedBox(width: 8),
                Text('Any',
                    style: inter(fontSize: 12, color: kMuted)),
                Checkbox(
                  value: anyChecked ?? false,
                  onChanged: onAnyToggle,
                  activeColor: kIndigo,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: kIndigo,
              inactiveTrackColor: kLine,
              thumbColor: kIndigo,
              overlayColor: kIndigo.withOpacity(0.12),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: kCream,
        border: Border(top: BorderSide(color: kLine, width: 1)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: _clearAll,
            style: TextButton.styleFrom(foregroundColor: kInk),
            child: Text(
              'Clear all',
              style: inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kInk,
                // Add underline for visual cue without using a separate widget.
              ).copyWith(decoration: TextDecoration.underline),
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _onSearch,
            icon: const Icon(Icons.search, size: 18, color: kCream),
            label: Text(
              'Search',
              style: inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: kCream),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: kClay,
              foregroundColor: kCream,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _RoundIconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: kCream,
            border: Border.all(color: disabled ? kLine : kInk),
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
              size: 18, color: disabled ? kMuted : kInk),
        ),
      ),
    );
  }
}
