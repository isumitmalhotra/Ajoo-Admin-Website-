import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/ui/design/aajoo_skin.dart';
import 'package:rent_home/utils/lux_mode.dart';
import 'package:rent_home/controller/common_controller.dart';
import 'package:rent_home/ui/screens_renter/home/map/map_controller.dart';
import 'package:rent_home/controller/search_controller.dart';
import 'package:rent_home/data/models/search_property_model.dart';
import 'package:rent_home/ui/responsive.dart';
import 'package:rent_home/ui/screens_renter/home/components/lux_theme.dart';
import 'package:rent_home/ui/screens_renter/home/components/lux_toggle_button.dart';
import 'package:rent_home/ui/screens_renter/home/components/search_sheet.dart';
import 'package:rent_home/ui/screens_renter/home/components/text_category_pills.dart';
import 'package:rent_home/ui/screens_renter/nearby_bookings/area_rails.dart';
import 'package:rent_home/ui/screens_renter/nearby_bookings/pre_booking_card.dart';
import 'package:rent_home/ui/screens_renter/nearby_bookings/stay_dates_bar.dart';
import 'package:rent_home/ui/screens_renter/property_details/property_page.dart';
import 'package:rent_home/models/properties_response_model.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:shimmer/shimmer.dart';

class PreBookingScreen extends StatefulWidget {
  /// Open showing the stays around one searched place.
  ///
  /// The search sheet used to close onto whatever screen you were on and
  /// change the numbers in place, so a guest who typed a city and pressed
  /// Search saw the sheet vanish and nothing obviously happen. Passing the
  /// search here makes it land somewhere: a results screen headed by the place
  /// searched, listing the stays around it, with the sort and filter controls
  /// this screen already carries.
  const PreBookingScreen({
    super.key,
    this.searchPlace,
    this.searchCenter,
    this.searchRadiusKm = 50,
    this.categoryId,
    this.categoryTitle,
  });

  /// Name of the place searched, for the header. Null = the old behaviour,
  /// "near me".
  final String? searchPlace;

  /// Where to look. Null loads the generic list, as before.
  final LatLng? searchCenter;

  /// How far around [searchCenter] to look.
  final int searchRadiusKm;

  /// Open already narrowed to one property type.
  ///
  /// The home screen's category row used to call
  /// `mapController.getProperties(category: id)` and show a snackbar. That
  /// re-filtered two rails most of the way down the page — well below the
  /// fold, under the trust bar and the editor's picks — so from where the
  /// guest was standing, tapping "Villas" printed "Showing Villas" and
  /// changed nothing they could see. The website sends the same tap to a
  /// filtered search page; so does this now.
  final int? categoryId;
  final String? categoryTitle;

  @override
  State<PreBookingScreen> createState() => _PreBookingScreenState();
}

class _PreBookingScreenState extends State<PreBookingScreen> {
  final _queryController = TextEditingController();
  final _focusNode = FocusNode();
  final searchController = Get.find<HomeSearchController>();
  final mapController = Get.find<MapController>();
  final commonController = Get.find<CommonController>();

  // Add these variables for search functionality
  List<SearchPropertyModel> _filteredProperties = [];
  bool _isSearching = false;
  /// Mirrors the one preference, rather than being a second copy of it.
  ///
  /// This screen used to start at `false` whatever the guest had chosen on the
  /// home screen, so walking from a LUX home into Pre-Booking landed you back
  /// in the standard skin with the standard listings — the mode was per-screen
  /// and lasted exactly as long as the screen did. It now seeds from LuxMode
  /// and follows it, so the switch works from either end.
  bool isLuxury = LuxMode.instance.isOn;

  // Sort & Filter, matching the website's Explore sidebar.
  //
  // The sheet used to offer one control — sort by price — while the site let
  // you narrow by price band, guest rating and property type. Same four sort
  // orders and the same rating bands are used here so a guest who filters on
  // the site and then opens the app sees the same set, not a different one.
  //
  // These filter the rows already fetched rather than re-querying: the screen
  // holds the whole page of listings in memory, so narrowing is instant and
  // works offline, and nothing about how properties are loaded changes.
  double? _priceMin;
  double? _priceMax;
  double _minRating = 0;

  /// True when anything other than the default ordering is in play, i.e. when
  /// the result list is a narrowed view rather than simply everything.
  bool get _hasActiveFilters =>
      _priceMin != null || _priceMax != null || _minRating > 0;

  /// How many filters are on — drives the count badge on the Filter button,
  /// so an active filter can never be invisible (the commonest cause of
  /// "where did my properties go?").
  int get _activeFilterCount =>
      (_priceMin != null ? 1 : 0) +
      (_priceMax != null ? 1 : 0) +
      (_minRating > 0 ? 1 : 0) +
      (_selectedHotelIndex != -1 ? 1 : 0) +
      (_sortOption != 'default' ? 1 : 0);

  /// Stay dates chosen up here and carried into the property page, so the
  /// guest is not asked for them twice.
  /// How many people the stay is for, carried in from the search sheet.
  int _guests = 0;

  DateTime? _checkIn;
  DateTime? _checkOut;

  /// One rail per area (Shimla, Kufri, Mohali, Panchkula, Kharar...), each
  /// loaded independently.
  final _areaRails = Get.put(AreaRailsController(), tag: 'prebooking');

  /// See kHiddenBrowseCategories — shared with the home screen so the two
  /// browse rows cannot drift apart, which is exactly what happened when this
  /// screen and the home screen each kept their own category list.
  static const _hiddenCategories = kHiddenBrowseCategories;

  Future<String> getAddress(double lat, double long) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, long);
      Placemark place = placemarks[0];
      return "${place.street}, ${place.subLocality},${place.locality}";
    } catch (e) {
      print("Error getting address: $e");
      return " - ";
    }
  }

  Future<void> _showLuxuryModeDialog(
      BuildContext context, bool isLuxury, Function(bool) onSwitch) {
    return showLuxSwitchDialog(
      context,
      isLuxury: isLuxury,
      onSwitch: (val) async {
        onSwitch(val);
        await Future.wait([
          _loadResults(isLuxury: val),
          _areaRails.load(isLuxury: val),
        ]);
      },
    );
  }

  /// One sort row. Takes the *pending* selection and a setter rather than
  /// reading `_sortOption` directly, so the sheet can stage a choice and only
  /// commit it on Apply.
  Widget _buildSortOption(
    String title,
    String value,
    IconData icon,
    StateSetter setModalState,
    String current,
    ValueChanged<String> onSelect,
  ) {
    final isSelected = current == value;
    final accent = isLuxury ? Lux.gold : kIndigo;
    final ink = isLuxury ? Lux.ink : kInk;
    final muted = isLuxury ? Lux.muted : kMuted;
    return InkWell(
      onTap: () => onSelect(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: isSelected ? accent.withOpacity(0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accent : (isLuxury ? Lux.line : kLine),
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? accent : muted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: inter(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? accent : ink,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, size: 20, color: accent),
          ],
        ),
      ),
    );
  }

  /// Re-run the whole narrowing pipeline against the freshly-loaded page.
  ///
  /// This used to sort `_filteredProperties` in place and leave the main list
  /// to the build method, which meant a filter only ever applied while a
  /// search was active — pick "Price: Low to High" with an empty search box
  /// and nothing happened. Everything now goes through one path.
  void _applySorting() => _searchProperties(_queryController.text);

  int _selectedHotelIndex = -1;

  /// The category the API is filtering on, or null for everything.
  int? _activeCategoryId;

  /// Which pill to light up, resolved by TITLE rather than by the index the
  /// caller happened to pass — the screen can be opened with a category name
  /// before the category list has loaded, and the two orders need not agree.
  int _pillIndex(List<dynamic> cats) {
    if (_selectedCategoryTitle.isEmpty) return 0;
    final i = cats.indexWhere((c) =>
        c.catTitle.toString().toLowerCase() ==
        _selectedCategoryTitle.toLowerCase());
    return i < 0 ? 0 : i + 1;
  }

  // Add method to filter properties by category
  String _sortOption = 'default';

  static double _priceOf(SearchPropertyModel p) =>
      double.tryParse(p.propertyPrice ?? '0') ?? 0;

  /// Price band and guest rating, applied to whatever list is handed in.
  ///
  /// An unrated stay has rating `null`, not 0, so a "4.0+" filter drops it —
  /// same rule the website applies. Claiming an unreviewed stay clears a
  /// rating bar would be inventing a review.
  List<SearchPropertyModel> _filterProperties(
      List<SearchPropertyModel> properties) {
    if (!_hasActiveFilters) return properties;
    return properties.where((p) {
      final price = _priceOf(p);
      if (_priceMin != null && price < _priceMin!) return false;
      if (_priceMax != null && price > _priceMax!) return false;
      if (_minRating > 0 && (p.rating == null || p.rating! < _minRating)) {
        return false;
      }
      return true;
    }).toList();
  }

  List<SearchPropertyModel> _sortProperties(
      List<SearchPropertyModel> properties) {
    switch (_sortOption) {
      case 'price_low_high':
        return List.from(properties)
          ..sort((a, b) => _priceOf(a).compareTo(_priceOf(b)));
      case 'price_high_low':
        return List.from(properties)
          ..sort((a, b) => _priceOf(b).compareTo(_priceOf(a)));
      case 'rating':
        // Unrated stays sort last rather than ahead of a 5.0 — the same rule
        // the backend uses for sort_by=rating.
        return List.from(properties)
          ..sort((a, b) => (b.rating ?? -1).compareTo(a.rating ?? -1));
      default:
        return properties;
    }
  }

  // Updated search function to maintain sorting and work with category filters
  void _searchProperties(String query) {
    if (searchController.preBookingResponse.value?.data == null) return;

    setState(() {
      if (query.isEmpty && _selectedHotelIndex == -1 && !_hasActiveFilters) {
        _isSearching = false;
        _filteredProperties.clear();
      } else {
        _isSearching = true;

        List<SearchPropertyModel> baseResults =
            searchController.preBookingResponse.value!.data;

        // Apply text search filter if query is not empty
        if (query.isNotEmpty) {
          final searchLower = query.toLowerCase();
          baseResults = baseResults.where((property) {
            final nameMatch =
                property.propertyName?.toLowerCase().contains(searchLower) ??
                    false;
            final addressMatch =
                property.propertyAddress?.toLowerCase().contains(searchLower) ??
                    false;
            final cityMatch =
                property.propertyCity?.toLowerCase().contains(searchLower) ??
                    false;
            final descMatch =
                property.propertyDesc?.toLowerCase().contains(searchLower) ??
                    false;

            return nameMatch || addressMatch || cityMatch || descMatch;
          }).toList();
        }

        // NO category sieve here.
        //
        // The API narrows by category now (see _loadResults), so what is in
        // `preBookingResponse` is already the chosen type. Filtering it again
        // on `category_titles` would silently drop the matches: a row can come
        // back from the type filter with its titles unpopulated, and this
        // returned `false` for exactly that case — so the server would answer
        // with twelve villas and the screen would show none of them.

        _filteredProperties = _sortProperties(_filterProperties(baseResults));
      }
    });
  }

  /// The category the guest picked, by title.
  ///
  /// This used to be a switch over five hardcoded indexes returning "Sharing",
  /// "Family", "Couple", "Party", "Single" — names that had to agree with a
  /// hardcoded tile row AND with tbl_categories, and did not. The pills carry
  /// the real title now, so there is nothing to keep in step.
  String _selectedCategoryTitle = '';

  /// Open a stay from an area rail, carrying the dates chosen up here.
  ///
  /// dealFrom/dealTo is the property page's existing "open with these dates
  /// already selected" input, so the guest is not asked for them a second
  /// time and the stay is priced the moment the page loads.
  void _openProperty(SearchPropertyModel p) {
    final images = (p.images ?? const [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();
    final cats = () {
      final ct = p.categoryTitles;
      if (ct == null) return <String>[];
      if (ct is List) return ct.map((e) => e.toString()).toList();
      return <String>[ct.toString()];
    }();

    Get.to(() => PropertyPage(
          property: Property(
            propertyId: p.propertyId,
            propertyName: p.propertyName ?? 'Unnamed Property',
            propertyAddress: p.propertyAddress ?? '',
            propertyDesc: p.propertyDesc ?? '',
            propertyPrice: p.propertyPrice ?? '0.0',
            propertyCity: p.propertyCity ?? '',
            propertyLongitude: p.propertyLongitude ?? '0',
            propertyLatitude: p.propertyLatitude ?? '0',
            propertyHostId: p.propertyHostId,
            propertyZip: p.propertyZip,
            propertyContact: p.propertyContact,
            propDetailsPropDetailIsPetFriendly:
                p.propDetailsPropDetailIsPetFriendly,
            propDetailsPropDetailIsSmoke: p.propDetailsPropDetailIsSmoke,
            propDetailsPropDetailInTime: p.propDetailsPropDetailInTime,
            propDetailsPropDetailOutTime: p.propDetailsPropDetailOutTime,
            propDetailsPropDetailExtra: p.propDetailsPropDetailExtra,
            coverImage: p.coverImage,
            images: images,
            categoryTitles: cats,
          ),
          price: p.propertyPrice ?? '0',
          name: p.propertyName ?? 'Stay',
          location: p.propertyAddress ?? '',
          image: p.coverImage ?? '',
          id: p.propertyId!,
          // The real average, not a hardcoded '0' — the response has carried
          // it all along. An unrated stay stays at '0' so the card can tell
          // "no reviews yet" from "reviewed badly".
          rating: p.rating == null ? '0' : p.rating!.toStringAsFixed(1),
          description: p.propertyDesc ?? '',
          lat: p.propertyLatitude ?? '0',
          long: p.propertyLongitude ?? '0',
          galleryImages: images,
          showNegotiationButton: false,
          inTime: p.propDetailsPropDetailInTime,
          outTime: p.propDetailsPropDetailOutTime,
          dealFrom: _checkIn == null ? null : StayDatesBar.api(_checkIn!),
          dealTo: _checkOut == null ? null : StayDatesBar.api(_checkOut!),
        ));
  }

  /// Sort & Filter — the website's Explore sidebar, as a sheet.
  ///
  /// Sort, price band, guest rating and property type, in that order, with the
  /// same options and the same wording the site uses. Property type reads and
  /// writes the very same selection as the category pills on the screen behind
  /// it, so the two can never disagree about what is selected.
  ///
  /// The sheet scrolls and is height-capped, because it now holds four
  /// sections: on a short handset a fixed-height sheet would push Apply off
  /// the bottom, which is exactly the kind of thing that makes a filter look
  /// broken when it is only unreachable.
  void _showFilterBottomSheet() {
    // Edit in a scratch copy, commit on Apply. Tapping outside to dismiss then
    // leaves the list exactly as it was, rather than half-applying whatever
    // was touched on the way past.
    String sort = _sortOption;
    double? priceMin = _priceMin;
    double? priceMax = _priceMax;
    double minRating = _minRating;
    int categoryIndex = _selectedHotelIndex;

    final minCtrl = TextEditingController(
        text: priceMin == null ? '' : priceMin.toStringAsFixed(0));
    final maxCtrl = TextEditingController(
        text: priceMax == null ? '' : priceMax.toStringAsFixed(0));

    final cats = (commonController.cats.value?.data.categories ?? [])
        .where((c) =>
            !_hiddenCategories.contains(c.catTitle.trim().toLowerCase()))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isLuxury ? Lux.surface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final ink = isLuxury ? Lux.ink : kInk;
        final muted = isLuxury ? Lux.muted : kMuted;
        final accent = isLuxury ? Lux.gold : kIndigo;

        return StatefulBuilder(
          builder: (context, setModalState) {
            void apply() {
              setState(() {
                _sortOption = sort;
                _priceMin = priceMin;
                _priceMax = priceMax;
                _minRating = minRating;
                if (_selectedHotelIndex != categoryIndex) {
                  _selectedHotelIndex = categoryIndex;
                  _selectedCategoryTitle =
                      categoryIndex == -1 ? '' : cats[categoryIndex].catTitle;
                  _activeCategoryId =
                      categoryIndex == -1 ? null : cats[categoryIndex].catId;
                }
              });
              Navigator.pop(context);
              // Re-ask, rather than narrowing the sixty rows already here.
              // The price band and the rating floor are the API's job now, so
              // "under ₹1,000" searches the catalogue instead of searching
              // whatever this screen happened to have fetched.
              _loadResults().then((_) {
                if (mounted) _applySorting();
              });
            }

            return SafeArea(
              top: false,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Grab handle — the sheet is draggable, so say so.
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 4),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: muted.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Sort & Filter',
                              style: fraunces(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: ink,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.close, color: muted),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                        children: [
                          _filterHeading('Sort by', ink),
                          _buildSortOption('Recommended', 'default',
                              Icons.auto_awesome, setModalState, sort,
                              (v) => setModalState(() => sort = v)),
                          _buildSortOption('Price: Low to High',
                              'price_low_high', Icons.arrow_upward,
                              setModalState, sort,
                              (v) => setModalState(() => sort = v)),
                          _buildSortOption('Price: High to Low',
                              'price_high_low', Icons.arrow_downward,
                              setModalState, sort,
                              (v) => setModalState(() => sort = v)),
                          _buildSortOption('Rating', 'rating',
                              Icons.star_border_rounded, setModalState, sort,
                              (v) => setModalState(() => sort = v)),

                          const SizedBox(height: 20),
                          _filterHeading('Price range (per night)', ink),
                          Row(
                            children: [
                              Expanded(
                                child: _priceField(
                                  controller: minCtrl,
                                  hint: 'Min',
                                  ink: ink,
                                  muted: muted,
                                  accent: accent,
                                  onChanged: (v) => priceMin =
                                      v.trim().isEmpty ? null : double.tryParse(v),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: Text('to', style: inter(color: muted)),
                              ),
                              Expanded(
                                child: _priceField(
                                  controller: maxCtrl,
                                  hint: 'Max',
                                  ink: ink,
                                  muted: muted,
                                  accent: accent,
                                  onChanged: (v) => priceMax =
                                      v.trim().isEmpty ? null : double.tryParse(v),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),
                          _filterHeading('Guest rating', ink),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final band in const [
                                ['Any', 0.0],
                                ['4.5+ Excellent', 4.5],
                                ['4.0+ Very Good', 4.0],
                                ['3.5+ Good', 3.5],
                              ])
                                _filterChip(
                                  label: band[0] as String,
                                  selected: minRating == band[1] as double,
                                  accent: accent,
                                  ink: ink,
                                  muted: muted,
                                  onTap: () => setModalState(
                                      () => minRating = band[1] as double),
                                ),
                            ],
                          ),

                          if (cats.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _filterHeading('Property type', ink),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _filterChip(
                                  label: 'All',
                                  selected: categoryIndex == -1,
                                  accent: accent,
                                  ink: ink,
                                  muted: muted,
                                  onTap: () =>
                                      setModalState(() => categoryIndex = -1),
                                ),
                                for (var i = 0; i < cats.length; i++)
                                  _filterChip(
                                    label: cats[i].catTitle,
                                    selected: categoryIndex == i,
                                    accent: accent,
                                    ink: ink,
                                    muted: muted,
                                    onTap: () =>
                                        setModalState(() => categoryIndex = i),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Actions pinned below the scroll area, so Apply is
                    // reachable however long the list of types gets.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setModalState(() {
                                  sort = 'default';
                                  priceMin = null;
                                  priceMax = null;
                                  minRating = 0;
                                  categoryIndex = -1;
                                  minCtrl.clear();
                                  maxCtrl.clear();
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: ink,
                                side: BorderSide(
                                    color: isLuxury ? Lux.line : kLine),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text('Clear all',
                                  style: inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: apply,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor:
                                    isLuxury ? Lux.bg : Colors.white,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text('Show stays',
                                  style: inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      minCtrl.dispose();
      maxCtrl.dispose();
    });
  }

  String _sortLabel(String value) {
    switch (value) {
      case 'price_low_high':
        return 'Price: Low to High';
      case 'price_high_low':
        return 'Price: High to Low';
      case 'rating':
        return 'Top rated';
      default:
        return 'Recommended';
    }
  }

  /// "₹2,000–₹5,000", or an open-ended band when only one end is set.
  String _priceLabel() {
    String r(double v) => '₹${v.toStringAsFixed(0)}';
    if (_priceMin != null && _priceMax != null) {
      return '${r(_priceMin!)}–${r(_priceMax!)}';
    }
    if (_priceMin != null) return 'Above ${r(_priceMin!)}';
    return 'Under ${r(_priceMax!)}';
  }

  /// A dismissable chip describing one active filter.
  Widget _activeChip({
    required IconData icon,
    required String label,
    required VoidCallback onClear,
    bool gold = false,
  }) {
    final tone = gold ? kClay : (isLuxury ? Lux.gold : kIndigo);
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.only(left: 11, right: 6),
      decoration: BoxDecoration(
        color: tone.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: tone),
          const SizedBox(width: 5),
          Text(
            label,
            style: inter(
                fontSize: 12.5, fontWeight: FontWeight.w600, color: tone),
          ),
          IconButton(
            onPressed: onClear,
            icon: Icon(Icons.close_rounded, size: 15, color: tone),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            tooltip: 'Remove $label',
          ),
        ],
      ),
    );
  }

  Widget _filterHeading(String text, Color ink) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: inter(fontSize: 14, fontWeight: FontWeight.w700, color: ink),
        ),
      );

  Widget _priceField({
    required TextEditingController controller,
    required String hint,
    required Color ink,
    required Color muted,
    required Color accent,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      // Digits only. A price box that accepts "1,2OO" parses to null and
      // silently drops the filter the guest thought they had set.
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged,
      style: inter(fontSize: 15, color: ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: inter(fontSize: 15, color: muted),
        prefixText: '₹ ',
        prefixStyle: inter(fontSize: 15, color: muted),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isLuxury ? Lux.line : kLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 1.6),
        ),
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required Color accent,
    required Color ink,
    required Color muted,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? accent : (isLuxury ? Lux.line : kLine),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Text(
          label,
          style: inter(
            fontSize: 13.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? accent : ink,
          ),
        ),
      ),
    );
  }

  // Add clear search function
  void _clearSearch() {
    _queryController.clear();
    _focusNode.unfocus();
    setState(() {
      _selectedHotelIndex = -1; // Clear category selection
      _isSearching = false;
      _filteredProperties.clear();
    });
  }

  LatLng currentLocation = const LatLng(28.495000, 77.40905397);

  /// Re-skin and re-fetch when the preference changes anywhere in the app.
  void _onLuxChanged() {
    final on = LuxMode.instance.isOn;
    if (!mounted || on == isLuxury) return;
    setState(() => isLuxury = on);
    _loadResults(isLuxury: on);
    _areaRails.load(isLuxury: on);
  }

  @override
  void initState() {
    super.initState();
    // Opened from a category tap: show that pill as chosen, and ask the API
    // for that type rather than filtering whatever happened to come back.
    if ((widget.categoryTitle ?? '').isNotEmpty) {
      _selectedCategoryTitle = widget.categoryTitle!;
      _selectedHotelIndex = 0;
      _activeCategoryId = widget.categoryId;
    }
    LuxMode.instance.on.addListener(_onLuxChanged);
    _areaRails.load(isLuxury: isLuxury);
    currentLocation = widget.searchCenter ?? mapController.currentPosition.value;

    // Carry the search's When and Who onto this screen.
    //
    // The dates bar kept its own state starting at null, and nothing ever
    // seeded it, so a guest who picked 1–3 Sep and two guests in the search
    // sheet arrived here at "Add dates" and was asked all over again — and the
    // results underneath were not narrowed by either. The controller has held
    // all three since the sheet ran setStay(); this reads them.
    _checkIn = _parseDmy(mapController.stayFrom.value);
    _checkOut = _parseDmy(mapController.stayTo.value);
    _guests = mapController.stayGuests.value;

    _loadResults();
  }

  /// Change the party size, then refetch with it.
  Future<void> _pickGuests() async {
    final chosen = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: isLuxury ? Lux.bg : kCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        int local = _guests < 1 ? 1 : _guests;
        return StatefulBuilder(
          builder: (ctx, setSheet) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Who',
                    style: fraunces(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: isLuxury ? Lux.ink : kInk)),
                const SizedBox(height: 4),
                Text('How many guests are coming?',
                    style: inter(
                        fontSize: 13,
                        color: isLuxury ? Lux.muted : kMuted)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        local == 1 ? '1 guest' : '$local guests',
                        style: inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isLuxury ? Lux.ink : kInk),
                      ),
                    ),
                    IconButton(
                      onPressed:
                          local > 1 ? () => setSheet(() => local--) : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    IconButton(
                      onPressed:
                          local < 20 ? () => setSheet(() => local++) : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(local),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLuxury ? Lux.gold : kIndigo,
                      foregroundColor: isLuxury ? Lux.ink : kCream,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Apply',
                        style: inter(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (chosen == null || chosen == _guests) return;
    setState(() => _guests = chosen);
    _syncStayAndReload();
  }

  /// Push this screen's stay back onto the controller and refetch.
  ///
  /// The controller is what the map, the property page and checkout all read,
  /// so changing the dates here has to update them too — otherwise opening a
  /// stay from this list would ask for dates the guest has already given twice.
  void _syncStayAndReload() {
    mapController.setStay(
      from: _checkIn == null ? null : StayDatesBar.api(_checkIn!),
      to: _checkOut == null ? null : StayDatesBar.api(_checkOut!),
      guests: _guests > 0 ? _guests : null,
    );
    _loadResults();
  }

  /// DD-MM-YYYY, the shape the whole platform stores stay dates in.
  static DateTime? _parseDmy(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    final parts = s.split('-');
    if (parts.length != 3) return null;
    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (d == null || m == null || y == null) return null;
    return DateTime(y, m, d);
  }

  /// Load the list this screen is showing.
  ///
  /// With a searched place it asks for stays around THOSE coordinates; without
  /// one it keeps the previous behaviour. Before this the request sent empty
  /// coordinates either way, so the heading named a place the results had
  /// nothing to do with.
  /// Nothing matched — said in terms of what the guest actually chose.
  ///
  /// "No PreBooking Properties Found" told them nothing: not which of their
  /// four possible narrowings emptied the list, and not how to undo it.
  Widget _noResults() {
    final skin = AajooSkin.of(isLuxury);
    final narrowings = <String>[
      if (_selectedCategoryTitle.isNotEmpty) _selectedCategoryTitle,
      if (_queryController.text.trim().isNotEmpty)
        '"${_queryController.text.trim()}"',
      if (_priceMin != null || _priceMax != null) 'your price range',
      if (_minRating > 0) '${_minRating.toStringAsFixed(1)}★ and above',
      if (isLuxury) 'LUX',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: skin.muted),
          const SizedBox(height: 14),
          Text(
            narrowings.isEmpty
                ? 'No stays here yet'
                : 'No stays match ${narrowings.join(' + ')}',
            textAlign: TextAlign.center,
            style: fraunces(
                fontSize: 17, fontWeight: FontWeight.w600, color: skin.ink),
          ),
          const SizedBox(height: 6),
          Text(
            narrowings.isEmpty
                ? 'Try another destination, or widen the dates.'
                : 'Try a wider search, or clear what you have narrowed by.',
            textAlign: TextAlign.center,
            style: inter(fontSize: 13.5, color: skin.muted, height: 1.5),
          ),
          if (narrowings.isNotEmpty) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedHotelIndex = -1;
                  _selectedCategoryTitle = '';
                  _activeCategoryId = null;
                  _queryController.clear();
                  _priceMin = null;
                  _priceMax = null;
                  _minRating = 0;
                  _sortOption = 'default';
                  _isSearching = false;
                  _filteredProperties.clear();
                });
                if (isLuxury) LuxMode.instance.set(false);
                _loadResults(isLuxury: false, categoryId: null);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: skin.primary,
                side: BorderSide(color: skin.primary),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: Text('Clear everything',
                  style: inter(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _loadResults({bool? isLuxury, int? categoryId}) {
    final centre = widget.searchCenter;
    return searchController.getPreBooking(
      isLuxury: isLuxury ?? this.isLuxury,
      latitude: centre?.latitude,
      longitude: centre?.longitude,
      radiusKm: widget.searchRadiusKm,
      // The API narrows by type, price band and rating now, so the list that
      // comes back IS the filtered list. `_activeCategoryId` is the pill's own
      // id, which is why changing any of these re-asks rather than sieving
      // what is already here.
      categoryId: categoryId ?? _activeCategoryId,
      minPrice: _priceMin,
      maxPrice: _priceMax,
      minRating: _minRating > 0 ? _minRating : null,
      // Narrow by the stay the guest actually asked for. Without these the
      // list showed places already booked for those nights, and places too
      // small for the party, and only refused at checkout.
      guests: _guests > 0 ? _guests : null,
      from: _checkIn == null ? null : StayDatesBar.api(_checkIn!),
      to: _checkOut == null ? null : StayDatesBar.api(_checkOut!),
    );
  }

  @override
  void dispose() {
    LuxMode.instance.on.removeListener(_onLuxChanged);
    _queryController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: isLuxury ? Lux.bg : null,
      appBar: AppBar(
        toolbarHeight: 76,
        elevation: 0,
        // Was `false`, which left the search results with no way back to the
        // home screen they were opened from — and this screen is pushed from
        // six places. `true` is not merely the default: Flutter draws the
        // arrow only when the route can actually pop, so the one case where
        // this is shown as a root still gets no stray button.
        automaticallyImplyLeading: true,
        backgroundColor: isLuxury ? Lux.bg : kCream,
        foregroundColor: isLuxury ? Lux.ink : Colors.black87,
        // The location was a FutureBuilder that reverse-geocoded on every
        // rebuild and could not be changed — it printed where the phone was
        // and that was that. Same editable pill the home screen uses, so
        // tapping it opens the destination search.
        title: Obx(() {
          final place = mapController.currentPlace.value;
          return InkWell(
            onTap: () => showSearchSheet(context),
            borderRadius: BorderRadius.circular(999),
            child: Row(
              children: [
                Icon(
                  isLuxury
                      ? Lux.icon(Icons.location_on_outlined)
                      : Icons.location_on_outlined,
                  size: 20,
                  color: isLuxury ? Lux.gold : kIndigo,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          widget.searchPlace != null
                              ? 'Stays in'
                              : 'Pre-booking near',
                          style: inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isLuxury ? Lux.muted : kMuted)),
                      Text(
                        widget.searchPlace ??
                            (place.isEmpty ? 'Nearby' : place),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: isLuxury ? Lux.ink : kInk),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down,
                    size: 18, color: isLuxury ? Lux.muted : kMuted),
              ],
            ),
          );
        }),
        titleSpacing: 16,
        centerTitle: false,
        // The mode switch, top right beside the search. This was a hand-rolled
        // pill using theme.primaryColor and an asset called "diamond .png"
        // (with a space in the filename); the home screen's animated toggle is
        // the real one.
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: LuxToggleButton(
              isLuxury: isLuxury,
              height: 42,
              width: 96,
              onTap: () => _showLuxuryModeDialog(
                  context, isLuxury, (val) => LuxMode.instance.set(val)),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(6.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Obx(() {
                if (searchController.preBookingResponse.value == null) {
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: 10,
                    itemBuilder: (context, index) {
                      return Shimmer.fromColors(
                        baseColor: isLuxury
                            ? const Color(0xFF141416)
                            : Colors.grey[300]!,
                        highlightColor: isLuxury
                            ? const Color(0xFF1D1D20)
                            : Colors.grey[100]!,
                        child: ListTile(
                          title: Container(
                            height: 100,
                            width: double.infinity,
                            color: isLuxury ? Lux.surface : kCream,
                          ),
                        ),
                      );
                    },
                  );
                }
                if (searchController.isLoading.value) {
                  // LUX gets its own loader — a gold LUX wordmark rather than
                  // the grey shimmer, so the wait itself says the mode changed.
                  if (isLuxury) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 80),
                      child: LuxLoader(),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 7,
                    itemBuilder: (context, index) {
                      return Shimmer.fromColors(
                        baseColor: isLuxury
                            ? const Color(0xFF141416)
                            : Colors.grey[300]!,
                        highlightColor: isLuxury
                            ? const Color(0xFF1D1D20)
                            : Colors.grey[100]!,
                        child: Card(
                          color: isLuxury ? Lux.surface : kCream,
                          child: Container(
                            height: 400,
                            width: double.infinity,
                            color: isLuxury ? Lux.surface : kCream,
                          ),
                        ),
                      );
                    },
                  );
                }
                // NO early return for an empty result.
                //
                // This used to hand back a full-height "No PreBooking
                // Properties Found" panel INSTEAD of the page, which took the
                // category pills, the dates bar, the search field and the
                // filter button off screen with it. So the one moment a guest
                // most needs those controls — they have just narrowed to
                // something with nothing in it — was the one moment the screen
                // removed them, leaving Back as the only way out. The empty
                // state is a message where the list goes, and the controls
                // stay where they are.

                final properties =
                    searchController.preBookingResponse.value!.data;
                final sortedProperties =
                    _sortProperties(_filterProperties(properties));
                final displayProperties =
                    _isSearching ? _filteredProperties : sortedProperties;
                // Browsing (no search term, no category pill) keeps the area
                // rails on screen, filters or not.
                final railsVisible =
                    _queryController.text.isEmpty && _selectedHotelIndex == -1;

                return Column(
                  children: [
                    // Browse by category — the platform's real property
                    // types, read from the same source the home screen uses.
                    //
                    // This was five hardcoded image tiles for Family, Sharing,
                    // Couple, Party and Single: occupancy types, not property
                    // types, and their filter matched category TITLES that
                    // three of them did not even correspond to. The spec asks
                    // for homestays and villas here.
                    Obx(() {
                      final cats = (commonController
                                  .cats.value?.data.categories ??
                              [])
                          .where((c) => !_hiddenCategories
                              .contains(c.catTitle.trim().toLowerCase()))
                          .toList();
                      if (cats.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: TextCategoryPills(
                          categories: ['All', ...cats.map((c) => c.catTitle)],
                          selectedIndex: _pillIndex(cats),
                          onChanged: (i) {
                            setState(() {
                              _selectedHotelIndex = i - 1;
                              _selectedCategoryTitle =
                                  i == 0 ? '' : cats[i - 1].catTitle;
                              _activeCategoryId =
                                  i == 0 ? null : cats[i - 1].catId;
                            });
                            // Re-ask the API. Sieving the page we already hold
                            // is what made this look broken: most of the
                            // catalogue carries no category, so narrowing 60
                            // rows by type returned nothing nearly every time.
                            _loadResults().then((_) {
                              if (mounted) {
                                _searchProperties(_queryController.text);
                              }
                            });
                          },
                        ),
                      );
                    }),

                    // Check-in / check-out. Pre-booking had no date input at
                    // all — you found a stay, opened it, and only then were
                    // asked when you wanted it.
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 8.0),
                      child: StayDatesBar(
                        checkIn: _checkIn,
                        checkOut: _checkOut,
                        isLuxury: isLuxury,
                        onChanged: (a, b) {
                          setState(() { _checkIn = a; _checkOut = b; });
                          _syncStayAndReload();
                        },
                        onClear: () {
                          setState(() { _checkIn = null; _checkOut = null; });
                          _syncStayAndReload();
                        },
                      ),
                    ),

                    // Who, beside When. The search sheet asks for a party size
                    // and this screen showed no sign of it, so a guest who said
                    // "4 guests" could not tell whether the list in front of
                    // them respected that. Tapping it changes the party and
                    // refetches.
                    if (_guests > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: InkWell(
                            onTap: _pickGuests,
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isLuxury ? Lux.bg : kCream,
                                border: Border.all(
                                    color: isLuxury
                                        ? Lux.gold.withOpacity(.4)
                                        : kLine),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.person_outline,
                                      size: 16,
                                      color: isLuxury ? Lux.gold : kIndigo),
                                  const SizedBox(width: 6),
                                  Text(
                                    _guests == 1 ? '1 guest' : '$_guests guests',
                                    style: inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isLuxury ? Lux.ink : kInk),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.keyboard_arrow_down,
                                      size: 16,
                                      color: isLuxury ? Lux.muted : kMuted),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _queryController,
                                focusNode: _focusNode,
                                decoration: InputDecoration(
                                  hintText:
                                      "Search by name, location, or description...",
                                  hintStyle: TextStyle(color: Colors.grey[500]),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: _isSearching
                                        ? theme.primaryColor
                                        : Colors.grey[600],
                                  ),
                                  suffixIcon: _isSearching
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: _clearSearch,
                                          color: Colors.grey[600],
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide(
                                        color: theme.primaryColor, width: 2),
                                  ),
                                ),
                                onChanged: _searchProperties,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // The LUX/NOR pill used to sit here, beside the
                            // filter button. It was removed on the client's
                            // instruction: luxury is a mode for the whole app,
                            // switched from the home screen, not a filter you
                            // set per search — and sitting in the filter row it
                            // read as one. Nothing about luxury mode itself
                            // changed; `isLuxury` still skins this screen and
                            // still scopes what it loads.
                            ElevatedButton(
                              onPressed: _showFilterBottomSheet,
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: _activeFilterCount > 0
                                    ? theme.primaryColor
                                    : theme.canvasColor,
                                foregroundColor: _activeFilterCount > 0
                                    ? Colors.white
                                    : theme.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: const EdgeInsets.all(16),
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  const Icon(
                                    Iconsax.filter,
                                    size: 24,
                                  ),
                                  // How many filters are on, not merely that
                                  // some are. A bare dot leaves the guest
                                  // opening the sheet to find out.
                                  if (_activeFilterCount > 0)
                                    Positioned(
                                      right: -6,
                                      top: -6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5, vertical: 1),
                                        constraints: const BoxConstraints(
                                            minWidth: 16, minHeight: 16),
                                        decoration: BoxDecoration(
                                          color: isLuxury ? Lux.gold : kClay,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          '$_activeFilterCount',
                                          textAlign: TextAlign.center,
                                          style: inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: isLuxury
                                                ? Lux.bg
                                                : Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // What is currently narrowing the list, one chip each,
                    // every one dismissable.
                    //
                    // This was a fixed Row of three hardcoded chips, so the
                    // new price and rating filters would have applied with
                    // nothing on screen to say so, and a fourth chip would
                    // have overflowed the row. It scrolls now, and the sort
                    // chip no longer assumes the sort is by price — picking
                    // "Rating" used to label itself "Price: High to Low".
                    if (_activeFilterCount > 0 || isLuxury)
                      SizedBox(
                        height: 44,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            if (_selectedHotelIndex != -1)
                              _activeChip(
                                icon: Icons.category_outlined,
                                label: _selectedCategoryTitle,
                                onClear: () {
                                  setState(() {
                                    _selectedHotelIndex = -1;
                                    _selectedCategoryTitle = '';
                                    _activeCategoryId = null;
                                  });
                                  // Clearing the type is a change of question,
                                  // so it re-asks the API rather than sieving
                                  // the narrowed page we are already holding.
                                  _loadResults(categoryId: null).then((_) {
                                    if (mounted) {
                                      _searchProperties(_queryController.text);
                                    }
                                  });
                                },
                              ),
                            if (isLuxury)
                              _activeChip(
                                icon: Icons.diamond_outlined,
                                label: 'Luxury Mode',
                                gold: true,
                                onClear: () => LuxMode.instance.set(false),
                              ),
                            if (_sortOption != 'default')
                              _activeChip(
                                icon: _sortOption == 'price_low_high'
                                    ? Icons.arrow_upward
                                    : _sortOption == 'price_high_low'
                                        ? Icons.arrow_downward
                                        : Icons.star_border_rounded,
                                label: _sortLabel(_sortOption),
                                onClear: () {
                                  setState(() => _sortOption = 'default');
                                  _applySorting();
                                },
                              ),
                            if (_priceMin != null || _priceMax != null)
                              _activeChip(
                                icon: Icons.payments_outlined,
                                label: _priceLabel(),
                                onClear: () {
                                  setState(() {
                                    _priceMin = null;
                                    _priceMax = null;
                                  });
                                  _applySorting();
                                },
                              ),
                            if (_minRating > 0)
                              _activeChip(
                                icon: Icons.star_rounded,
                                label: '${_minRating.toStringAsFixed(1)}+',
                                onClear: () {
                                  setState(() => _minRating = 0);
                                  _applySorting();
                                },
                              ),
                          ],
                        ),
                      ),

                    // Search results info.
                    //
                    // Only when the area rails are down. This line counts the
                    // main list alone, so with the rails up it sat above a
                    // screen full of matching stays announcing "No stays match
                    // these filters" — a count for one section, read as a
                    // verdict on the page.
                    if (_isSearching && !railsVisible)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            // Name what actually emptied the list. With
                            // filters in play the old line read: No results
                            // found for "" — an empty search term blamed for
                            // a price band's doing.
                            Text(
                              _filteredProperties.isEmpty
                                  ? (_queryController.text.isNotEmpty
                                      ? 'No results found for "${_queryController.text}"'
                                      : 'No stays match these filters')
                                  : '${_filteredProperties.length} result(s) found',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Properties list
                    // The full-screen "nothing here" only takes over when
                    // there is nothing else on the page to look at. While the
                    // area rails are up — which is whenever the guest is
                    // browsing rather than searching a term — an empty main
                    // list is just an empty section, and blanking the rails
                    // to announce it would hide the very stays that do match.
                    if (_isSearching && _filteredProperties.isEmpty && !railsVisible)
                      SizedBox(
                        height: 300,
                        width: double.infinity,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No properties found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _queryController.text.isNotEmpty
                                  ? 'Try searching with different keywords'
                                  : 'Try widening your filters',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      // Area rails — Shimla, Kufri, Mohali, Panchkula, Kharar
                      // and Chandigarh, ten to twelve stays each. Only shown
                      // when the guest is browsing rather than searching, and
                      // each rail hides itself when its area has no listings
                      // (Kufri has none on the platform today).
                      // Gated on the SEARCH BOX, not on `_isSearching`.
                      //
                      // `_isSearching` now also goes true for a price or
                      // rating filter, and gating the rails on it made the
                      // whole area section vanish the moment one was set: a
                      // guest who asked for stays under ₹1,000 watched the
                      // ₹900 Shimla stays disappear and got "No properties
                      // found". A filter narrows what is shown; it does not
                      // delete the shelf. The rails stay and their contents
                      // are filtered instead.
                      if (railsVisible)
                        Obx(() {
                          if (_areaRails.loading.value) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: isLuxury
                                  ? const LuxLoader(
                                      message: 'Curating luxury stays by area')
                                  : const Center(
                                      child: CircularProgressIndicator(
                                          color: kIndigo)),
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final area in kPreBookingAreas)
                                  AreaRail(
                                    area: area,
                                    isLuxury: isLuxury,
                                    // Same price/rating narrowing as the main
                                    // list, so one filter means one thing
                                    // everywhere on this screen. A rail whose
                                    // stays are all filtered out hides itself,
                                    // which it already did for empty areas.
                                    properties: _sortProperties(
                                      _filterProperties(
                                          _areaRails.byArea[area] ?? const []),
                                    ),
                                    onOpen: (p) => _openProperty(p),
                                  ),
                              ],
                            ),
                          );
                        }),
                      if (displayProperties.isEmpty)
                        _noResults()
                      // One card per row on a phone, two or three across a
                      // tablet — the same cards, just not stretched to the
                      // full width of a 10" screen.
                      else if (context.gridColumns(target: 400, max: 3) == 1)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: displayProperties.length,
                          itemBuilder: (context, index) {
                            final property = displayProperties[index];
                            return PreBookingCard(
                                property: property, index: index);
                          },
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: displayProperties.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                context.gridColumns(target: 400, max: 3),
                            mainAxisExtent: 340,
                          ),
                          itemBuilder: (context, index) {
                            final property = displayProperties[index];
                            return PreBookingCard(
                                property: property, index: index, fill: true);
                          },
                        ),
                    ],
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

}
