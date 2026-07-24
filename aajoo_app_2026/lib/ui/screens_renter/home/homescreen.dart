import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/controller/common_controller.dart';
import 'package:rent_home/ui/screens_common/auth/auth_controller.dart';
import 'package:rent_home/ui/screens_renter/home/map/map_controller.dart';
import 'package:rent_home/ui/screens_common/notifications/notication_controller.dart';
import 'package:rent_home/controller/search_controller.dart';
import 'package:rent_home/controller/user_controller.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/ui/screens_renter/home/components/branded_header.dart';
import 'package:rent_home/ui/screens_renter/home/components/curated_card.dart';
import 'package:rent_home/ui/screens_renter/home/components/curated_grid_shimmer.dart';
import 'package:rent_home/ui/screens_renter/home/components/lux_toggle_button.dart';
import 'package:rent_home/ui/screens_renter/home/components/filter_dialog_content.dart';
import 'package:rent_home/ui/screens_renter/home/components/search_pill.dart';
import 'package:rent_home/ui/screens_renter/home/components/search_sheet.dart';
import 'package:rent_home/ui/screens_renter/home/components/section_header.dart';
import 'package:rent_home/ui/screens_renter/home/components/text_category_pills.dart';
import 'package:rent_home/ui/screens_renter/home/components/weekly_hero_card.dart';
import 'package:rent_home/ui/screens_renter/property_details/property_page.dart';
import 'package:rent_home/ui/screens_renter/home/map/map_screen.dart';
import 'package:rent_home/ui/screens_renter/home/ongoing_widget.dart';
import 'package:rent_home/ui/screens_renter/nearby_bookings/pre_booking_screen.dart';
import 'package:rent_home/ui/screens_renter/bookmark_properties/bookmark_properties_page.dart';
import 'package:rent_home/ui/screens_common/notifications/notification_screen.dart';
import 'package:rent_home/service/notification_service.dart';
import 'package:rent_home/ui/screens_renter/home/components/custom_drawer.dart';
import 'package:rent_home/ui/screens_renter/home/components/negotiated_deal_banner.dart';
import 'package:rent_home/controller/deals_controller.dart';
import 'package:rent_home/ui/screens_renter/home/pre_booking_home_carousel/prebooking_home_carousel.dart';
// Removed unused imports

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> with TickerProviderStateMixin {
  int _selectedHotelIndex = -1;
  // M4 — text category pills selection. V1 is purely visual.
  int _propertyType = 0;
  late AnimationController _animationController;
  late Timer _timer;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final DraggableScrollableController _dragController =
      DraggableScrollableController();
  bool isLuxury = false;
  // final _queryController = TextEditingController(); // unused
  final searchController = Get.put(HomeSearchController());

  final mapController = Get.put<MapController>(MapController());
  final userController = Get.put<UserController>(UserController());
  final commonController = Get.put<CommonController>(CommonController());

  // Category mapping for the UI buttons
  final Map<int, String> categoryMap = {
    1: "Family",
    0: "Sharing",
    2: "Couple",
    3: "Party",
    4: "Single",
  };
  final notificationController = Get.put(NotificationController());
  final dealsController = Get.put(DealsController());
  // Cached AuthController lookup so we can gate the API avalanche below on
  // "is there actually a real logged-in user?". For dev-skip users (no
  // userData), the user-scoped calls are skipped entirely — they'd all 401
  // or 404 and just stall the UI on Dio's default timeout.
  final _authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _playAnimation();
    });

    // Categories are public (used by the filter dialog + map) — always fetch.
    commonController.fetchCategories();

    // User-scoped boot-up calls — only fire if we have a real user.
    final hasRealUser = _authController.userData.value != null;
    if (hasRealUser) {
      notificationController.getNotificationData();
      NotificationService().init();
      userController.fetchOngoingBookings();
      userController.getUserReviews();
      searchController.getPreBooking();
      dealsController.load();
    }
  }

  void _showLuxuryModeDialog(
      BuildContext context, bool isLuxury, Function(bool) onSwitch) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              isLuxury ? "Switch to Normal Mode?" : "Switch to Luxury Mode?"),
          content: Text(isLuxury
              ? "Are you sure you want to switch back to normal mode?"
              : "Do you want to enable luxury mode for premium properties?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                onSwitch(!isLuxury); // Toggle the mode
                Navigator.of(context).pop();
              },
              child: const Text("Switch"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer.cancel();
    super.dispose();
  }

  void _playAnimation() {
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      key: _scaffoldKey,
      // POC mobile: no opaque AppBar — the branded header floats over the map.
      drawer: CustomDrawer(),
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(
              child: MapScreen(),
            ),

            // ── Branded header + search pill (top, floating) ──
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BrandedHeader(
                      onMenuTap: () =>
                          _scaffoldKey.currentState?.openDrawer(),
                      onWishlistTap: () => Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => const BookmarkedPropertiesPage(),
                        ),
                      ),
                      onProfileTap: () => Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SearchPill(
                      location: 'Goa',
                      details: 'Any week · 1 guest',
                      // Airbnb-style search modal (Where / When / Who +
                      // suggested destinations + advanced filters).
                      onTap: () => showSearchSheet(context),
                    ),
                    const SizedBox(height: 8),
                    Obx(() => userController.isLoading.value ||
                            userController.ongoingBookings.value == null
                        ? const SizedBox.shrink()
                        : OngoingBookingWidget(
                            userController: userController,
                          )),
                    // Negotiated-deal banner (24h coupon from an accepted offer)
                    // — one tap opens the sanctioned property, dates + coupon
                    // pre-filled. Hidden when there are no active deals.
                    const NegotiatedDealBanner(),
                  ],
                ),
              ),
            ),

            DraggableScrollableSheet(
              controller: _dragController,
              initialChildSize: 0.28,
              minChildSize: 0.25,
              maxChildSize: 0.99,
              snap: true,
              snapSizes: const [0.28, 0.6, 0.99],
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: kCream,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x0A0F172A),
                        blurRadius: 8,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    physics: const ClampingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// 🔹 Drag Handle
                          Center(
                            child: Container(
                              height: 4,
                              width: 40,
                              decoration: BoxDecoration(
                                color: kLine,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),

                          /// 🔹 M3 — Weekly hero card
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: WeeklyHeroCard(),
                          ),

                          /// 🔹 Near by button
                          fetchNearByProperties(theme),

                          const SizedBox(height: 16),

                          /// 🔹 M4 — Category circles
                          TextCategoryPills(
                            selectedIndex: _propertyType,
                            onChanged: (i) =>
                                setState(() => _propertyType = i),
                          ),

                          const SizedBox(height: 16),

                          /// 🔹 Trust bar (new design)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 6),
                            decoration: BoxDecoration(
                                color: kCream,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: kLine)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: const [
                                _TrustItem(Icons.verified_user_outlined,
                                    'Verified\nProperties'),
                                _TrustItem(
                                    Icons.lock_outline, 'Secure\nPayments'),
                                _TrustItem(
                                    Icons.sell_outlined, 'Best Price\nGuarantee'),
                                _TrustItem(Icons.headset_mic_outlined,
                                    '24/7\nSupport'),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          /// 🔹 M5 — Curated for you (2-col grid)
                          Obx(() {
                            if (mapController.isLoading.value) {
                              return const CuratedGridShimmer();
                            }
                            final items = mapController.properties
                                .take(4)
                                .toList();
                            if (items.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SectionHeader(
                                  title: 'Curated for you',
                                  onSeeAll: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const PreBookingScreen(),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  itemCount: items.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 0.72,
                                  ),
                                  itemBuilder: (context, i) {
                                    final p = items[i];
                                    return CuratedCard(
                                      property: p,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => PropertyPage(
                                              property: p,
                                              price: p.propertyPrice,
                                              name: p.propertyName,
                                              location: p.propertyAddress,
                                              image: p.coverImage ?? '',
                                              id: p.propertyId,
                                              rating: '4.5',
                                              description: p.propertyDesc,
                                              lat: p.propertyLatitude,
                                              long: p.propertyLongitude,
                                              galleryImages: p.images
                                                  .map((e) => e.toString())
                                                  .toList(),
                                              inTime: p
                                                  .propDetailsPropDetailInTime,
                                              outTime: p
                                                  .propDetailsPropDetailOutTime,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),
                              ],
                            );
                          }),

                          /// 🔹 Find Your Stay
                          Obx(() {
                            if (mapController.isLoading.value) {
                              return const SizedBox.shrink();
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Find Your Stay",
                                  style: fraunces(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: kInk,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 310,
                                  child: PreBookingHomeCarousel(
                                    properties:
                                        mapController.properties.toList(),
                                  ),
                                ),
                              ],
                            );
                          }),
                          const SizedBox(height: 20),

                          /// Browse by Category
                          Text(
                            "Browse by Category",
                            style: fraunces(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: kInk,
                            ),
                          ),

                          const SizedBox(height: 20),

                          SizedBox(
                            height: 100,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                const SizedBox(width: 10),
                                _hotelTypeBlock(
                                    1, "assets/family.png", "Family"),
                                const SizedBox(width: 20),
                                _hotelTypeBlock(
                                    0, "assets/sharing.png", "Sharing"),
                                const SizedBox(width: 20),
                                _hotelTypeBlock(
                                    2, "assets/couple.png", "Couple"),
                                const SizedBox(width: 20),
                                _hotelTypeBlock(3, "assets/girls.png", "Party"),
                                const SizedBox(width: 20),
                                _hotelTypeBlock(4, "assets/boy.png", "Single"),
                                const SizedBox(width: 10),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          /// 🔹 Action Buttons — Pre-Booking + animated LUX
                          Row(
                            children: [
                              Expanded(
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const PreBookingScreen(),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      height: 48,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [kIndigo600, kIndigo],
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: kIndigo.withOpacity(0.28),
                                            blurRadius: 14,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.event_available,
                                              color: kCream, size: 19),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Pre-Booking',
                                            style: inter(
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.w700,
                                              color: kCream,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              LuxToggleButton(
                                isLuxury: isLuxury,
                                onTap: () {
                                  _showLuxuryModeDialog(
                                    context,
                                    isLuxury,
                                    (val) {
                                      setState(() => isLuxury = val);
                                      mapController.isLuxury.value = isLuxury;
                                      isLuxury
                                          ? mapController
                                              .fetchLuxuryProperties()
                                          : mapController.fetchProperties();
                                    },
                                  );
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          /// 🔹 Reviews (View All visible)
                          buildReviewList(),

                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Padding fetchNearByProperties(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // button to relocate
          const SizedBox(width: 10),
          InkWell(
            onTap: () {
              mapController.fetchProperties();
            },
            child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: kCream,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kLine),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Icon(
                    Icons.my_location,
                    color: theme.primaryColor,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildReviewList() {
    return Obx(
      () => userController.isLoading.value
          ? const CircularProgressIndicator()
          : (userController.userReviews.value == null ||
                  userController.userReviews.value!.data.review.isEmpty)
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      "assets/noreview.png",
                      height: 200,
                      width: double.infinity,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "No reviews yet",
                      style: fraunces(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: kInk,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Guest reviews will appear here",
                      style: inter(fontSize: 12.5, color: kMuted),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Host Reviews",
                        style: fraunces(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: kInk,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount:
                          userController.userReviews.value!.data.review.length >
                                  2
                              ? 2
                              : userController
                                  .userReviews.value!.data.review.length,
                      itemBuilder: (context, index) {
                        final review = userController
                            .userReviews.value!.data.review[index];

                        return Container(
                          decoration: BoxDecoration(
                            color: kSurface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: kCardShadow,
                          ),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            tileColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: Text(review.hruTitle,
                                style: fraunces(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: kInk)),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(review.hruDescription,
                                  style:
                                      inter(fontSize: 12.5, color: kMuted)),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: kClay.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded,
                                      color: kClay, size: 16),
                                  const SizedBox(width: 2),
                                  Text(
                                    review.hruRating.toString(),
                                    style: inter(
                                        fontWeight: FontWeight.w700,
                                        color: kClay,
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    if (userController.userReviews.value!.data.review.length >
                        2)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kCream,
                            foregroundColor: kIndigo,
                            minimumSize: const Size(double.infinity, 50),
                            side: BorderSide(
                                color: Theme.of(context).primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            // TODO: navigate to a full reviews screen when built
                          },
                          child: const Text("View All"),
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _hotelTypeBlock(int index, String image, String type) {
    final selected = index == _selectedHotelIndex;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        setState(() {
          if (_selectedHotelIndex == index) {
            // If already selected, deselect and show all properties
            _selectedHotelIndex = -1;
            mapController.fetchProperties(); // Reset to all properties
          } else {
            // Select new category and filter properties
            _selectedHotelIndex = index;
            _searchByCategory(index);
          }
        });
      },
      child: Column(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(18),
              border: selected
                  ? Border.all(color: kIndigo, width: 2)
                  : null,
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: kIndigo.withOpacity(0.22),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : kSoftShadow,
            ),
            child: Center(
              child: Image.asset(image, height: 42, width: 42),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            type,
            style: inter(
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? kIndigo : kInk2,
            ),
          ),
        ],
      ),
    );
  }

  void _searchByCategory(int categoryIndex) {
    // Map UI category index to actual category ID from API
    int? categoryId = _getCategoryIdFromIndex(categoryIndex);

    if (categoryId != null) {
      // Fetch properties filtered by category
      mapController.getProperties(
        mapController.currentPosition.value.latitude,
        mapController.currentPosition.value.longitude,
        category: categoryId,
      );

      // Show feedback to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Searching ${categoryMap[categoryIndex]} properties...'),
          duration: const Duration(seconds: 2),
          backgroundColor: Theme.of(context).primaryColor,
        ),
      );
    }
  }

  int? _getCategoryIdFromIndex(int uiIndex) {
    // This maps the UI button index to actual category IDs
    // You may need to adjust these IDs based on your API's category structure
    switch (uiIndex) {
      case 0: // Sharing
        return _findCategoryIdByName("Sharing");
      case 1: // Family
        return _findCategoryIdByName("Family");
      case 2: // Couple
        return _findCategoryIdByName("Couple");
      case 3: // Party
        return _findCategoryIdByName("Party");
      case 4: // Single
        return _findCategoryIdByName("Single");
      default:
        return null;
    }
  }

  int? _findCategoryIdByName(String categoryName) {
    try {
      if (commonController.cats.value?.data.categories != null) {
        final category =
            commonController.cats.value!.data.categories.firstWhere(
          (cat) =>
              cat.catTitle.toLowerCase().contains(categoryName.toLowerCase()),
          orElse: () => commonController.cats.value!.data.categories.first,
        );
        return category.catId;
      }
    } catch (e) {
      print('Error finding category ID for $categoryName: $e');
    }

    // Fallback to index-based mapping if category names don't match
    return 1; // Default category ID
  }
}

void showFilterDialog({
  required BuildContext context,
  required Function(int selectedCategory, double selectedRadius, double? weekly,
          double? monthly)
      onApply,
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Filter Options'),
        content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: FilterDialogContent(onApply: onApply)),
        actions: const [],
      );
    },
  );
}

/// Trust-bar item (new design) — icon + 2-line label.
class _TrustItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrustItem(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: kIndigo600),
        const SizedBox(height: 5),
        Text(
          label,
          textAlign: TextAlign.center,
          style: inter(
              fontSize: 10.5, fontWeight: FontWeight.w600, height: 1.2, color: kInk2),
        ),
      ],
    );
  }
}
