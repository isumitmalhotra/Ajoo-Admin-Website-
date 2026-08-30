import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/ui/screens_renter/home/components/home_banner_rail.dart';
import 'package:rent_home/ui/design/aajoo_skin.dart';
import 'package:rent_home/utils/lux_mode.dart';
import 'package:rent_home/ui/screens_renter/home/components/pre_booking_button.dart';
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
import 'package:rent_home/ui/screens_renter/home/components/home_cms_sections.dart';
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
import 'package:rent_home/ui/screens_renter/home/components/negotiated_deal_banner.dart';
import 'package:rent_home/ui/screens_renter/home/components/counter_offer_banner.dart';
import 'package:rent_home/controller/deals_controller.dart';
import 'package:rent_home/ui/screens_renter/home/components/featured_destinations.dart';
// Removed unused imports

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> with TickerProviderStateMixin {
  /// Whether the reviews strip is showing everything or just the first two.
  ///
  /// "View All" used to be wired to an empty handler with a comment about a
  /// screen that was never built (FE-13) — a button that looks like it works,
  /// does nothing, and teaches a guest not to trust the next one. Every review
  /// is already loaded, so the honest thing is to show them here.
  bool _showAllReviews = false;

  // Which category pill is selected. 0 = "All"; anything higher indexes the
  // API category list. This used to be paired with a second _selectedHotelIndex
  // for the duplicate lower row, and the two could disagree about what was
  // filtered.
  int _propertyType = 0;

  /// The category the guest is filtering by, or null for "All". Held so an
  /// empty result can name it — 16 of 29,241 live properties carry any
  /// category at all, so most filters legitimately return nothing and the
  /// screen has to say why rather than look broken.
  late AnimationController _animationController;
  late Timer _timer;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final DraggableScrollableController _dragController =
      DraggableScrollableController();
  // `bool isLuxury` used to live here, and a second copy lived on the
  // pre-booking screen. Neither was persisted and neither could see the
  // other, which is why turning LUX on changed the pill and nothing else.
  // The preference is LuxMode now and this screen reads it through
  // LuxBuilder — see utils/lux_mode.dart.
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
    //
    // Which listings depends on the mode. Now that LUX is a remembered
    // preference rather than a per-screen boolean, a guest who left in LUX
    // comes back to a black-and-gold home — and it would be showing the whole
    // catalogue underneath, because the fetch on this line never asked. The
    // preference may also still be reading from storage at this point, hence
    // the listener: whichever way round they land, the listings match the skin.
    mapController.isLuxury.value = LuxMode.instance.isOn;
    _fetchForMode();
    LuxMode.instance.on.addListener(_onLuxChanged);

    // User-scoped boot-up calls — only fire if we have a real user.
    final hasRealUser = _authController.userData.value != null;
    if (hasRealUser) {
      notificationController.getNotificationData();
      NotificationService().init();
      userController.fetchOngoingBookings();
      userController.getUserReviews();
      searchController.getPreBooking();
      dealsController.load();
      // The banner below needs the conversation, not just the coupon it may
      // eventually become.
      dealsController.loadNegotiations();
    }
  }

  /// Ask for the listings the current mode wants.
  Future<void> _fetchForMode() => LuxMode.instance.isOn
      ? mapController.fetchLuxuryProperties()
      : mapController.fetchProperties();

  /// The preference changed — here, or on any other screen.
  void _onLuxChanged() {
    if (!mounted) return;
    final on = LuxMode.instance.isOn;
    if (mapController.isLuxury.value == on) return;
    mapController.isLuxury.value = on;
    _fetchForMode();
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
    LuxMode.instance.on.removeListener(_onLuxChanged);
    _animationController.dispose();
    _timer.cancel();
    super.dispose();
  }

  void _playAnimation() {
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return LuxBuilder(builder: (context, skin) => _buildHome(context, skin));
  }

  Widget _buildHome(BuildContext context, AajooSkin skin) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: skin.page,
      // POC mobile: no opaque AppBar — the branded header floats over the map.
      // A-64: the drawer that used to hang here is gone. Its entries live on
      // the profile screen, which is a tab, rather than behind a logo tap
      // nothing marked as a menu.
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
                          // Was a hardcoded "Any week · 1 guest" that never
                          // changed, whatever you searched — it described no
                          // actual state, so it was decoration dressed as a
                          // summary. Removed; the pill now carries the place,
                          // which IS live. (Client sheet Common: "in search bar
                          // show current location and remove any week or guest".)
                          details: null,
                          // Airbnb-style search modal (Where / When / Who +
                          // suggested destinations + advanced filters).
                          onTap: () => showSearchSheet(context),
                        )),
                    // Everything this guest needs told, as one swipeable rail:
                    // their stay, a negotiated deal, a host's counter, a
                    // booking a KYC detour interrupted.
                    //
                    // These were four separate full-width cards stacked in a
                    // column over the map. Two of them at once buried the map
                    // the screen is built around, and the fourth was off the
                    // bottom of the fold. More importantly the stay card only
                    // appeared while the guest was PHYSICALLY IN the property
                    // (OngoingBookingWidget filters on isStaying), so booking
                    // somewhere for next week put nothing here at all — see
                    // StayBanner, which shows the stay in progress or the next
                    // one coming.
                    HomeBannerRail(userController: userController),
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
                  decoration: BoxDecoration(
                    color: skin.sheet,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                    boxShadow: skin.isLux
                        ? const [
                            BoxShadow(
                              color: Color(0x2ED4AF37),
                              blurRadius: 18,
                              offset: Offset(0, -6),
                            ),
                          ]
                        : const [
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
                                color: skin.isLux ? skin.primary : kLine,
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
                                  unreachable:
                                      mapController.lastSearchFailed.value,
                                  // The card lives inside this sheet, and the
                                  // sheet is the list of the very homes it is
                                  // counting — so "N homes near you ↗" opens
                                  // them by expanding to full height, rather
                                  // than pushing a second screen showing the
                                  // same results.
                                  onTap: () => _dragController.animateTo(
                                    0.99,
                                    duration: const Duration(milliseconds: 280),
                                    curve: Curves.easeOutCubic,
                                  ),
                                  // Nothing found: the card offers a way on
                                  // instead of expanding an empty list.
                                  onWiden: mapController.clearSearchFilters,
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
                              categories: [
                                'All',
                                ...cats.map((c) => c.catTitle)
                              ],
                              selectedIndex: _propertyType,
                              onChanged: (i) {
                                final cat = i == 0 ? null : cats[i - 1];
                                setState(() => _propertyType = i);
                                if (cat == null) {
                                  // "All" is a reset, and resets in place.
                                  mapController.fetchProperties();
                                } else {
                                  _browseCategory(cat.catId, cat.catTitle);
                                }
                              },
                            );
                          }),

                          const SizedBox(height: 16),

                          // A-21: Pre-Booking and LUX sit directly under the
                          // category row now. They were near the bottom of the
                          // page, below the property grids, which is past the
                          // point most people stop scrolling.
                          /// 🔹 Pre-Booking + the LUX switch.
                          ///
                          /// Pre-Booking was a full-bleed teal slab with its
                          /// own drop shadow, sitting next to a glowing gold
                          /// pill: two maximum-weight controls side by side,
                          /// each shouting over the other, and neither
                          /// matching the reference app's button — which is
                          /// radius 12, a 1.5px brand rule, and Manrope
                          /// 14.5/w600 on a plain surface.
                          ///
                          /// It is that button now. Only one thing in the row
                          /// is loud, and it is the mode switch, because the
                          /// mode switch is what changes the whole screen. The
                          /// slab also stayed teal in LUX, where every other
                          /// surface had gone black — it takes the skin now,
                          /// like everything else here.
                          Row(
                            children: [
                              Expanded(
                                child: PreBookingButton(
                                  skin: skin,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const PreBookingScreen(),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              LuxToggleButton(
                                isLuxury: skin.isLux,
                                onTap: () => _showLuxuryModeDialog(
                                  context,
                                  skin.isLux,
                                  (val) {
                                    LuxMode.instance.set(val);
                                    mapController.isLuxury.value = val;
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          /// 🔹 Trust bar (new design)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 6),
                            decoration: BoxDecoration(
                                color: skin.isLux ? skin.surface : kCream,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: skin.line)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _TrustItem(Icons.verified_user_outlined,
                                    'Verified\nProperties', skin),
                                _TrustItem(
                                    Icons.lock_outline, 'Secure\nPayments', skin),
                                _TrustItem(Icons.sell_outlined,
                                    'Best Price\nGuarantee', skin),
                                _TrustItem(Icons.headset_mic_outlined,
                                    '24/7\nSupport', skin),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          /// 🔹 Admin-curated blocks — featured stays and the
                          /// promotional banner, edited at /admin/cms-home.
                          /// Placed ahead of the algorithmic rails on purpose:
                          /// curation before algorithm, same as the website.
                          HomeCmsSections(onOpen: _openProperty),

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

                            // Trending — the same cut the website makes on
                            // the same single fetch: paid placement first,
                            // then standing. It re-sorts by how a stay is
                            // doing rather than how close it is, so it is a
                            // genuinely different list from "near you" and not
                            // the same twelve cards twice.
                            final trending = [...all]..sort((a, b) {
                                if (a.isBoosted != b.isBoosted) {
                                  return a.isBoosted ? -1 : 1;
                                }
                                final ar = a.rating ?? 0;
                                final br = b.rating ?? 0;
                                if (br != ar) return br.compareTo(ar);
                                return b.reviewCount.compareTo(a.reviewCount);
                              });

                            // One rail per property type, grouped from that
                            // same fetch — the website's per-category
                            // sections, which the phone did not have. Four is
                            // the floor: a rail of one reads as a broken
                            // section rather than a category, and the ring row
                            // at the top still offers every category anyway.
                            final byCategory = <String, List<Property>>{};
                            for (final p in all) {
                              for (final raw in (p.categoryTitles ?? const [])) {
                                final label = raw.toString().trim();
                                if (label.isEmpty) continue;
                                if (kHiddenBrowseCategories
                                    .contains(label.toLowerCase())) {
                                  continue;
                                }
                                (byCategory[label] ??= <Property>[]).add(p);
                              }
                            }
                            final categoryRails = byCategory.entries
                                .where((e) => e.value.length >= 4)
                                .toList()
                              ..sort((a, b) =>
                                  b.value.length.compareTo(a.value.length));

                            void browse({int? categoryId, String? title}) =>
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PreBookingScreen(
                                      searchPlace: mapController
                                              .currentPlace.value.isEmpty
                                          ? null
                                          : mapController.currentPlace.value,
                                      searchCenter:
                                          mapController.currentPosition.value,
                                      categoryId: categoryId,
                                      categoryTitle: title,
                                    ),
                                  ),
                                );

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                PropertySlider(
                                  title: 'Stays near you',
                                  properties: nearby,
                                  onSeeAll: browse,
                                  onOpen: _openProperty,
                                ),
                                const SizedBox(height: 24),
                                PropertySlider(
                                  title: 'Trending stays',
                                  properties: trending,
                                  onSeeAll: browse,
                                  onOpen: _openProperty,
                                ),
                                const SizedBox(height: 24),
                                PropertySlider(
                                  title: 'Curated for you',
                                  properties: curated,
                                  onSeeAll: browse,
                                  onOpen: _openProperty,
                                ),
                                const SizedBox(height: 24),
                                for (final entry in categoryRails.take(4)) ...[
                                  PropertySlider(
                                    title: entry.key,
                                    properties: entry.value,
                                    onSeeAll: () => browse(
                                        categoryId: _categoryIdFor(entry.key),
                                        title: entry.key),
                                    onOpen: _openProperty,
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ],
                            );
                          }),

                          /// 🔹 Featured Destinations — the website's rail.
                          ///
                          /// This slot used to hold a THIRD property carousel
                          /// ("Find Your Stay"), under admin-curated featured
                          /// stays and two more rails of the same cards. The
                          /// site answers "where could I go?" here instead, and
                          /// the client asked for the same on the phone.
                          FeaturedDestinations(
                            onSelect: (destination, position) {
                              // Same path a search selection takes: recentre
                              // and refetch, so the rail changes what you are
                              // browsing rather than opening a dead end.
                              mapController.fetchPropertiesAt(position);
                              // ...and drop the sheet so the guest can see it
                              // happen. The map is several screens above this
                              // rail, so without this the tap moved a map
                              // nobody could see and read as doing nothing.
                              _dragController.animateTo(
                                0.28,
                                duration: const Duration(milliseconds: 320),
                                curve: Curves.easeOutCubic,
                              );
                            },
                          ),
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
                            onSeeAll: () =>
                                Get.to(() => const BlogListScreen()),
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
    final skin = AajooSkin.of(LuxMode.instance.isOn);
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
                        color: skin.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Guest reviews will appear here",
                      style: inter(fontSize: 12.5, color: skin.muted),
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
                          color: skin.ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _showAllReviews
                          ? userController.userReviews.value!.data.review.length
                          : (userController
                                      .userReviews.value!.data.review.length >
                                  2
                              ? 2
                              : userController
                                  .userReviews.value!.data.review.length),
                      itemBuilder: (context, index) {
                        final review = userController
                            .userReviews.value!.data.review[index];

                        return Container(
                          decoration: skin.card(radius: 16),
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
                                    color: skin.ink)),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(review.hruDescription,
                                  style: inter(
                                      fontSize: 12.5, color: skin.muted)),
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
                          onPressed: () =>
                              setState(() => _showAllReviews = !_showAllReviews),
                          child: Text(_showAllReviews
                              ? "Show fewer"
                              : "View all ${userController.userReviews.value!.data.review.length} reviews"),
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
  /// A category title back to its id, so a per-category rail's "View all"
  /// opens the same server-filtered browse the ring row does. Returns null
  /// when the categories have not loaded, which browses unfiltered rather
  /// than filtering by a wrong id.
  int? _categoryIdFor(String title) {
    final cats = commonController.cats.value?.data.categories ?? const [];
    for (final c in cats) {
      if (c.catTitle.trim().toLowerCase() == title.trim().toLowerCase()) {
        return c.catId;
      }
    }
    return null;
  }

  /// Open browse, narrowed to one property type.
  ///
  /// This was `_filterByCategoryId`, and it did two things that between them
  /// made the category row read as dead. It re-fetched the map controller's
  /// list — which feeds two rails most of the way down the page, below the
  /// trust bar and the editor's picks, so nothing the guest could see changed
  /// — and it said "Showing Villas" in a snackbar over the part of the screen
  /// that had not changed. The website sends this tap to a filtered search
  /// page; so does this.
  void _browseCategory(int categoryId, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PreBookingScreen(
          searchPlace: mapController.currentPlace.value.isEmpty
              ? null
              : mapController.currentPlace.value,
          searchCenter: mapController.currentPosition.value,
          categoryId: categoryId,
          categoryTitle: title,
        ),
      ),
    );
    // The row goes back to "All" on the way out: the home screen itself is not
    // filtered — the screen we just opened is — and leaving a pill lit here
    // would claim otherwise when the guest comes back.
    setState(() => _propertyType = 0);
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
  final AajooSkin skin;
  const _TrustItem(this.icon, this.label, this.skin);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: skin.isLux ? skin.primary : kIndigo600),
        const SizedBox(height: 5),
        Text(
          label,
          textAlign: TextAlign.center,
          style: inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              height: 1.2,
              color: skin.isLux ? skin.ink : kInk2),
        ),
      ],
    );
  }
}
