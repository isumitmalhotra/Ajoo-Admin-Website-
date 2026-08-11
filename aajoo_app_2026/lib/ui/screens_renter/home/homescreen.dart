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
import 'package:rent_home/ui/screens_renter/home/components/curated_grid_shimmer.dart';
import 'package:rent_home/ui/screens_renter/home/components/lux_theme.dart';
import 'package:rent_home/ui/screens_renter/nearby_bookings/area_rails.dart';
import 'package:rent_home/ui/screens_renter/home/components/lux_toggle_button.dart';
import 'package:rent_home/ui/screens_renter/home/components/filter_dialog_content.dart';
import 'package:rent_home/ui/screens_renter/home/components/search_pill.dart';
import 'package:rent_home/ui/screens_renter/home/components/search_sheet.dart';
import 'package:rent_home/ui/screens_renter/home/components/text_category_pills.dart';
import 'package:rent_home/ui/screens_renter/home/components/home_faq_strip.dart';
import 'package:rent_home/ui/screens_renter/blog/blog_screens.dart';
import 'package:rent_home/ui/screens_renter/home/components/resume_booking_banner.dart';
import 'package:rent_home/ui/screens_renter/home/components/home_blog_strip.dart';
import 'package:rent_home/data/models/properties_response_model.dart';
import 'package:rent_home/ui/screens_renter/home/components/property_slider.dart';
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
  // Which category pill is selected. 0 = "All"; anything higher indexes the
  // API category list. This used to be paired with a second _selectedHotelIndex
  // for the duplicate lower row, and the two could disagree about what was
  // filtered.
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

    // So are the listings. Nothing fetched them on load: mapController
    // .properties only filled when someone tapped the locate button or a
    // category, so a first-time visitor's home screen asked for stays exactly
    // never and sat on "No stays available yet" while the website showed the
    // same catalogue fine.
    mapController.fetchProperties();

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

  /// The LUX switch. Was a bare Material AlertDialog — the same grey box in
  /// both directions, so the one moment that should feel like crossing into a
  /// different mode felt like a permissions prompt. See lux_theme.dart.
  Future<void> _showLuxuryModeDialog(
      BuildContext context, bool isLuxury, Function(bool) onSwitch) {
    return showLuxSwitchDialog(
      context,
      isLuxury: isLuxury,
      onSwitch: (val) async {
        onSwitch(val);
        // Hold the LUX loader up until the listings are actually in, so the
        // switch never flashes the standard page mid-transition.
        await (val
            ? mapController.fetchLuxuryProperties()
            : mapController.fetchProperties());
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
                      onNotificationsTap: () => Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Was hardcoded to "Goa" while the properties underneath
                    // were already being fetched around the user's real
                    // coordinates — the listings were right and the label above
                    // them named somewhere they had never been. "Nearby" until
                    // the geocoder answers, rather than inventing a place.
                    Obx(() => SearchPill(
                      location: mapController.currentPlace.value.isEmpty
                          ? 'Nearby'
                          : mapController.currentPlace.value,
                      details: 'Any week · 1 guest',
                      // Airbnb-style search modal (Where / When / Who +
                      // suggested destinations + advanced filters).
                      onTap: () => showSearchSheet(context),
                    )),
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
                    // Offers to reopen a booking that a KYC detour
                    // interrupted; renders nothing when there isn't one.
                    const ResumeBookingBanner(),
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

                          /// 🔹 M3 — hero card, fed from what the search
                          /// actually returned and where the user actually is.
                          /// It used to render "1,240 verified homes" and
                          /// "18 new in Goa this week" on every device.
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Obx(() => WeeklyHeroCard(
                                  homesNearby: mapController.properties.length,
                                  region: mapController.currentPlace.value,
                                )),
                          ),

                          /// 🔹 Near by button

                          const SizedBox(height: 16),

                          /// 🔹 Categories — ONE row, from the API, that filters.
                          ///
                          /// There used to be two category rows on this screen.
                          /// This one showed a HARDCODED list — 'All', 'Villas',
                          /// 'Heritage', 'Beach', 'Hills', 'Apartments', where
                          /// Beach and Hills are not categories at all — and its
                          /// onChanged only set a local int, so tapping it
                          /// filtered nothing. The real categories were in a
                          /// second "Browse by Category" row further down, with
                          /// a SEPARATE icon map that disagreed with this one
                          /// (a cottage was a cabin here and a cottage there).
                          ///
                          /// The lower row is gone and this one does the work.
                          Obx(() {
                            // Occupancy types left over from an older
                            // catalogue — couple, party, Resort — are filtered
                            // out of browse. NOT deleted: 10 live properties
                            // are still tagged with them and dropping the rows
                            // would leave those uncategorised.
                            final cats = (commonController
                                        .cats.value?.data.categories ??
                                    [])
                                .where((c) => !kHiddenBrowseCategories
                                    .contains(c.catTitle.trim().toLowerCase()))
                                .toList();
                            if (cats.isEmpty) return const SizedBox.shrink();
                            return TextCategoryPills(
                              // "All" first, then whatever the platform
                              // actually offers.
                              categories: ['All', ...cats.map((c) => c.catTitle)],
                              selectedIndex: _propertyType,
                              onChanged: (i) {
                                setState(() => _propertyType = i);
                                if (i == 0) {
                                  mapController.fetchProperties();
                                } else {
                                  final cat = cats[i - 1];
                                  _filterByCategoryId(cat.catId, cat.catTitle);
                                }
                              },
                            );
                          }),

                          const SizedBox(height: 16),

                          // A-21: Pre-Booking and LUX sit directly under the
                          // category row now. They were near the bottom of the
                          // page, below the property grids, which is past the
                          // point most people stop scrolling.
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
                                    },
                                  );
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

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

                          /// 🔹 A-22 / A-23 / A-24 — two property rails.
                          ///
                          /// Both were one 2-column grid of FOUR headed
                          /// "Curated for you". The sheet asks for two sliders
                          /// of 10-12 with "See all" top-right, so both use the
                          /// shared PropertySlider rather than two copies that
                          /// can drift apart — which is precisely how this
                          /// screen ended up with two category rows and two
                          /// disagreeing icon maps.
                          Obx(() {
                            if (mapController.isLoading.value) {
                              return const CuratedGridShimmer();
                            }
                            final all = mapController.properties.toList();
                            if (all.isEmpty) return const SizedBox.shrink();

                            // Nearest first — the search returns them ordered
                            // by distance, so this really is "near you".
                            final nearby = all.take(12).toList();

                            // "Curated" has no personalisation behind it. The
                            // platform collects no preference signal, so there
                            // is nothing to tailor to a person. What it CAN do
                            // honestly is lead with the stays that present
                            // best: rated first (the model carries a real
                            // rating and review count), then the ones with a
                            // photo. Deterministic, and it uses nothing that
                            // was invented. Worth revisiting when there is a
                            // genuine signal to rank on.
                            final curated = [...all]..sort((a, b) {
                                double score(Property p) =>
                                    (p.rating ?? 0) * 2 +
                                    (p.reviewCount > 0 ? 1 : 0) +
                                    ((p.coverImage ?? '').isNotEmpty ? 1 : 0);
                                return score(b).compareTo(score(a));
                              });

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                PropertySlider(
                                  title: 'Properties in your current location',
                                  properties: nearby,
                                  onSeeAll: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const PreBookingScreen()),
                                  ),
                                  onOpen: _openProperty,
                                ),
                                const SizedBox(height: 24),
                                PropertySlider(
                                  title: 'Curated for you',
                                  properties: curated,
                                  onSeeAll: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const PreBookingScreen()),
                                  ),
                                  onOpen: _openProperty,
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

                          // The second category row lived here. It duplicated
                          // the one at the top of this screen, with its own
                          // icon map that disagreed with it, and the client saw
                          // the same categories twice on one page. Folded into
                          // the row above.


                          /// 🔹 Reviews
                          buildReviewList(),

                          const SizedBox(height: 24),

                          /// 🔹 A-25 — blogs, four or five. The app had no blog
                          /// layer at all; the endpoint has existed the whole
                          /// time and nothing on the phone ever called it.
                          ///
                          /// No "See all" and no tap target yet, deliberately:
                          /// there is no /blog route in this app to send anyone
                          /// to. A link that goes nowhere is worse than no link
                          /// — that is the dead-control bug this sheet reports
                          /// elsewhere. The strip reads, and the handlers go in
                          /// with the blog screen (S0-BLOG-1).
                          // "See all" and the cards had nowhere to go until
                          // the blog screens existed.
                          HomeBlogStrip(
                            onSeeAll: () => Get.to(() => const BlogListScreen()),
                            onOpen: (post) =>
                                Get.to(() => BlogPostScreen(post: post)),
                          ),

                          const SizedBox(height: 24),

                          /// 🔹 A-26 — FAQs, and the page ends here.
                          HomeFaqStrip(
                            max: 5,
                            onSeeAll: () => Get.toNamed('/faq'),
                          ),

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

  /// An icon per spec category. The web uses photography; on a phone a glyph
  /// stays legible at 64px and cannot go missing like an asset can.


  /// `catId` is the real tbl_categories id, so filtering needs no name lookup.


  /// Open a property. One place, so a rail cannot drift from another in what
  /// it passes through — the previous inline version hardcoded `rating: '4.5'`
  /// for every stay on the screen.
  void _openProperty(Property p) {
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
          // ratingLabel is '' when the property has no rating, which lets the
          // detail page say "New". The inline version this replaced passed a
          // hardcoded '4.5' for every stay on the screen — a score nobody had
          // given, on a platform with no reviews in it.
          rating: p.ratingLabel,
          description: p.propertyDesc,
          lat: p.propertyLatitude,
          long: p.propertyLongitude,
          galleryImages: p.images.map((e) => e.toString()).toList(),
          inTime: p.propDetailsPropDetailInTime,
          outTime: p.propDetailsPropDetailOutTime,
        ),
      ),
    );
  }

  /// Filter by a real category id. The old path mapped a UI index to a name,
  /// searched the API for it, and fell back to the FIRST category when the
  /// name was not found — so a retired category quietly filtered by something
  /// else entirely instead of failing.
  void _filterByCategoryId(int categoryId, String title) {
    mapController.getProperties(
      mapController.currentPosition.value.latitude,
      mapController.currentPosition.value.longitude,
      category: categoryId,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Showing $title'),
        duration: const Duration(seconds: 2),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
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
