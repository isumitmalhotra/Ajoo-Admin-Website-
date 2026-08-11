import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/controller/common_controller.dart';
import 'package:rent_home/ui/screens_renter/home/map/map_controller.dart';
import 'package:rent_home/controller/search_controller.dart';
import 'package:rent_home/data/models/search_property_model.dart';
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
  const PreBookingScreen({super.key});

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
  bool isLuxury = false; // Add luxury state

  /// Stay dates chosen up here and carried into the property page, so the
  /// guest is not asked for them twice.
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
          searchController.getPreBooking(isLuxury: val),
          _areaRails.load(isLuxury: val),
        ]);
      },
    );
  }

  Widget _buildSortOption(
      String title, String value, IconData icon, StateSetter setModalState) {
    final isSelected = _sortOption == value;
    return InkWell(
      onTap: () {
        setModalState(() {
          _sortOption = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  void _applySorting() {
    setState(() {
      if (_isSearching) {
        _filteredProperties = _sortProperties(_filteredProperties);
      }
      // The main list will be sorted in the build method
    });
  }

  int _selectedHotelIndex = -1;

  // Add method to filter properties by category
  String _sortOption = 'default';
  List<SearchPropertyModel> _sortProperties(
      List<SearchPropertyModel> properties) {
    switch (_sortOption) {
      case 'price_low_high':
        return List.from(properties)
          ..sort((a, b) {
            final priceA = double.tryParse(a.propertyPrice ?? '0') ?? 0;
            final priceB = double.tryParse(b.propertyPrice ?? '0') ?? 0;
            return priceA.compareTo(priceB);
          });
      case 'price_high_low':
        return List.from(properties)
          ..sort((a, b) {
            final priceA = double.tryParse(a.propertyPrice ?? '0') ?? 0;
            final priceB = double.tryParse(b.propertyPrice ?? '0') ?? 0;
            return priceB.compareTo(priceA);
          });
      default:
        return properties;
    }
  }

  // Updated search function to maintain sorting and work with category filters
  void _searchProperties(String query) {
    if (searchController.preBookingResponse.value?.data == null) return;

    setState(() {
      if (query.isEmpty && _selectedHotelIndex == -1) {
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

        // Apply category filter if a category is selected
        if (_selectedHotelIndex != -1) {
          final categoryName = _getCategoryNameByIndex(_selectedHotelIndex);
          final categoryLower = categoryName.toLowerCase();

          baseResults = baseResults.where((property) {
            if (property.categoryTitles != null) {
              if (property.categoryTitles is String) {
                return property.categoryTitles
                    .toString()
                    .toLowerCase()
                    .contains(categoryLower);
              } else if (property.categoryTitles is List) {
                return (property.categoryTitles as List).any((cat) =>
                    cat.toString().toLowerCase().contains(categoryLower));
              }
            }
            return false;
          }).toList();
        }

        _filteredProperties = _sortProperties(baseResults);
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

  String _getCategoryNameByIndex(int index) => _selectedCategoryTitle;

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
          rating: '0',
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

// Add filter function
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Sort & Filter',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Sort by Price Section
                  const Text(
                    'Sort by Price',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sort options
                  _buildSortOption(
                    'Default',
                    'default',
                    Icons.sort,
                    setModalState,
                  ),
                  _buildSortOption(
                    'Price: Low to High',
                    'price_low_high',
                    Icons.arrow_upward,
                    setModalState,
                  ),
                  _buildSortOption(
                    'Price: High to Low',
                    'price_high_low',
                    Icons.arrow_downward,
                    setModalState,
                  ),

                  const SizedBox(height: 32),

                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _applySorting();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Apply',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // Clear Filters Button
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        setModalState(() {
                          _sortOption = 'default';
                        });
                        _applySorting();
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Clear All',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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

  @override
  void initState() {
    super.initState();
    _areaRails.load(isLuxury: isLuxury);
    searchController.getPreBooking(isLuxury: isLuxury);
    currentLocation = mapController.currentPosition.value;
  }

  @override
  void dispose() {
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
        automaticallyImplyLeading: false,
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
                      Text('Pre-booking near',
                          style: inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isLuxury ? Lux.muted : kMuted)),
                      Text(
                        place.isEmpty ? 'Nearby' : place,
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
                  context, isLuxury, (val) => setState(() => isLuxury = val)),
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
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: ListTile(
                          title: Container(
                            height: 100,
                            width: double.infinity,
                            color: kCream,
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
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Card(
                          child: Container(
                            height: 400,
                            width: double.infinity,
                            color: kCream,
                          ),
                        ),
                      );
                    },
                  );
                }
                if (searchController.preBookingResponse.value!.data.isEmpty) {
                  return SizedBox(
                    height: MediaQuery.of(context).size.height * 0.8,
                    width: double.infinity,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Icon(Icons.search_off, size: 100, color: Colors.grey),
                        SizedBox(height: 16),
                        Text("No PreBooking Properties Found",
                            style: TextStyle(fontSize: 18, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                final properties =
                    searchController.preBookingResponse.value!.data;
                final sortedProperties = _sortProperties(properties);
                final displayProperties =
                    _isSearching ? _filteredProperties : sortedProperties;

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
                          selectedIndex: _selectedHotelIndex + 1,
                          onChanged: (i) {
                            setState(() => _selectedHotelIndex = i - 1);
                            _selectedCategoryTitle =
                                i == 0 ? '' : cats[i - 1].catTitle;
                            _searchProperties(_queryController.text);
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
                        onChanged: (a, b) =>
                            setState(() { _checkIn = a; _checkOut = b; }),
                        onClear: () =>
                            setState(() { _checkIn = null; _checkOut = null; }),
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
                            // Luxury toggle button
                            InkWell(
                              onTap: () {
                                _showLuxuryModeDialog(context, isLuxury, (val) {
                                  setState(() {
                                    isLuxury = val;
                                  });
                                  // Refresh pre-booking data with luxury mode
                                  searchController.getPreBooking(
                                      isLuxury: isLuxury);
                                });
                              },
                              child: Container(
                                height: 56,
                                width: 80,
                                decoration: BoxDecoration(
                                  color: isLuxury
                                      ? theme.primaryColor.withOpacity(0.8)
                                      : theme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: theme.primaryColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Image.asset(
                                      "assets/diamond .png",
                                      height: 20,
                                      width: 20,
                                    ),
                                    Text(
                                      isLuxury ? "NOR" : "LUX",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                        color: isLuxury
                                            ? Colors.white
                                            : theme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _showFilterBottomSheet,
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: _sortOption != 'default'
                                    ? theme.primaryColor
                                    : theme.canvasColor,
                                foregroundColor: _sortOption != 'default'
                                    ? Colors.white
                                    : theme.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: const EdgeInsets.all(16),
                              ),
                              child: Stack(
                                children: [
                                  const Icon(
                                    Iconsax.filter,
                                    size: 24,
                                  ),
                                  if (_sortOption != 'default')
                                    Positioned(
                                      right: -2,
                                      top: -2,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
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

                    // Active filter indicator
                    if (_sortOption != 'default' ||
                        isLuxury ||
                        _selectedHotelIndex != -1)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            // Category filter indicator
                            if (_selectedHotelIndex != -1)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: theme.primaryColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.category,
                                      size: 16,
                                      color: theme.primaryColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Category: ${_getCategoryNameByIndex(_selectedHotelIndex)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.primaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedHotelIndex = -1;
                                        });
                                        _searchProperties(
                                            _queryController.text);
                                      },
                                      child: Icon(
                                        Icons.close,
                                        size: 16,
                                        color: theme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // Luxury mode indicator
                            if (isLuxury)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.amber.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      "assets/diamond .png",
                                      height: 16,
                                      width: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Luxury Mode',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.amber[800],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          isLuxury = false;
                                        });
                                        searchController.getPreBooking(
                                            isLuxury: false);
                                      },
                                      child: Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.amber[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // Sort indicator
                            if (_sortOption != 'default')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: theme.primaryColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _sortOption == 'price_low_high'
                                          ? Icons.arrow_upward
                                          : Icons.arrow_downward,
                                      size: 16,
                                      color: theme.primaryColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _sortOption == 'price_low_high'
                                          ? 'Price: Low to High'
                                          : 'Price: High to Low',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.primaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _sortOption = 'default';
                                        });
                                      },
                                      child: Icon(
                                        Icons.close,
                                        size: 16,
                                        color: theme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                    // Search results info
                    if (_isSearching)
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
                            Text(
                              _filteredProperties.isEmpty
                                  ? 'No results found for "${_queryController.text}"'
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
                    if (_isSearching && _filteredProperties.isEmpty)
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
                              'Try searching with different keywords',
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
                      if (!_isSearching && _selectedHotelIndex == -1)
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
                                    properties:
                                        _areaRails.byArea[area] ?? const [],
                                    onOpen: (p) => _openProperty(p),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: displayProperties.length,
                        itemBuilder: (context, index) {
                          final property = displayProperties[index];
                          return PreBookingCard(
                              property: property, index: index);
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
