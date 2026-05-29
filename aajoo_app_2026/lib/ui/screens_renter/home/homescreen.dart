import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/controller/common_controller.dart';
import 'package:rent_home/ui/screens_renter/home/map/map_controller.dart';
import 'package:rent_home/ui/screens_common/notifications/notication_controller.dart';
import 'package:rent_home/controller/search_controller.dart';
import 'package:rent_home/controller/user_controller.dart';
import 'package:rent_home/ui/screens_renter/home/components/filter_dialog_content.dart';
import 'package:rent_home/ui/screens_renter/home/map/map_screen.dart';
import 'package:rent_home/ui/screens_renter/home/ongoing_widget.dart';
import 'package:rent_home/ui/screens_renter/nearby_bookings/pre_booking_screen.dart';
import 'package:rent_home/ui/screens_common/notifications/notification_screen.dart';
import 'package:rent_home/service/notification_service.dart';
import 'package:rent_home/ui/screens_renter/home/components/custom_drawer.dart';
import 'package:rent_home/ui/screens_renter/home/pre_booking_home_carousel/prebooking_home_carousel.dart';
import 'package:rent_home/widgets/slanted_container.dart';
// Removed unused imports

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> with TickerProviderStateMixin {
  int _selectedHotelIndex = -1;
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
  @override
  void initState() {
    super.initState();
    notificationController.getNotificationData();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _playAnimation();
    });
    NotificationService().init();
    userController.fetchOngoingBookings();
    userController.getUserReviews();
    searchController.getPreBooking();
    commonController.fetchCategories();
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      key: _scaffoldKey,
      appBar: _renterHomeAppBar(theme, context),
      drawer: CustomDrawer(),
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(
              child: MapScreen(),
            ),
            // Top Bar
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Obx(() => userController.isLoading.value ||
                        userController.ongoingBookings.value == null
                    ? const SizedBox.shrink()
                    : OngoingBookingWidget(
                        userController: userController,
                      )),
              ],
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
                        color: Color(0x0A1B2447),
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

                          /// 🔹 Near by button
                          fetchNearByProperties(theme),

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
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
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
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
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

                          /// 🔹 Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.primaryColor,
                                    foregroundColor: kCream,
                                    minimumSize:
                                        const Size(double.infinity, 45),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const PreBookingScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text("Pre Booking",
                                      style: TextStyle(
                                          fontSize: 18, color: kCream)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              InkWell(
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
                                child: Container(
                                  height: 45,
                                  width: 100,
                                  decoration: BoxDecoration(
                                    color: isLuxury
                                        ? theme.primaryColor.withOpacity(0.8)
                                        : theme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Image.asset(
                                        "assets/diamond .png",
                                        height: 30,
                                      ),
                                      Text(
                                        isLuxury ? "NOR" : "LUX",
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: isLuxury
                                              ? Colors.white
                                              : theme.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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

  AppBar _renterHomeAppBar(ThemeData theme, BuildContext context) {
    return AppBar(
      toolbarHeight: 80,
      backgroundColor: theme.canvasColor,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: InkWell(
          onTap: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          child: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: theme.canvasColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Icon(
                Icons.menu,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
      centerTitle: true,
      title: const SlantedContainerWithFilterIcon(),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (BuildContext context) => NotificationsScreen(),
                ),
              );
            },
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: theme.canvasColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Obx(
                  () => Badge(
                    label: notificationController.notificationCount.value > 0
                        ? Text(
                            notificationController.notificationCount.value
                                .toString(),
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          )
                        : null,
                    child: const Icon(
                      Iconsax.notification4,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        InkWell(
          onTap: () {
            showFilterDialog(
              context: context,
              onApply: (int selectedCategory, double selectedRadius,
                  double? weeklyPrice, double? monthlyPrice) async {
                // radius: send empty string by default; if user picked, send value
                final radiusStr = (selectedRadius > 0)
                    ? selectedRadius.round().toString()
                    : "";

                await mapController.fetchProperties(
                  category: selectedCategory,
                  radius: radiusStr,
                );

                // Frontend-only price filtering: weekly as min, monthly as max
                mapController.applyPriceFilter(
                  minPrice: weeklyPrice,
                  maxPrice: monthlyPrice,
                );
              },
            );
          },
          child: Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: theme.canvasColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: Icon(
                  Iconsax.filter_add4,
                  color: Colors.black,
                  size: 25,
                ),
              ),
            ),
          ),
        ),
      ],
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
                      height: 300,
                      width: double.infinity,
                    ),
                    const Text("No Reviews Yet"),
                  ],
                )
              : Column(
                  children: [
                    const Text(
                      "Host Reviews",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                            color: kCream,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kLine),
                          ),
                          margin: const EdgeInsets.symmetric(
                              vertical: 5, horizontal: 4),
                          child: ListTile(
                            tileColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            title: Text(review.hruTitle,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(review.hruDescription),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  review.hruRating.toString(),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.yellow[700],
                                      fontSize: 20),
                                ),
                                Icon(Icons.star, color: Colors.yellow[700]),
                              ],
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
                            // Navigate to a screen showing all reviews
                            // Example: Get.to(() => AllReviewsScreen());
                            print("View All Reviews Clicked");
                          },
                          child: const Text("View All"),
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _hotelTypeBlock(int index, String image, String type) {
    final theme = Theme.of(context);
    return InkWell(
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
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: index == _selectedHotelIndex
                  ? theme.primaryColor.withOpacity(0.15)
                  : kCream,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: index == _selectedHotelIndex
                    ? theme.primaryColor
                    : kLine,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Image.asset(image, height: 45, width: 45),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            type,
            style: TextStyle(
              fontWeight: index == _selectedHotelIndex
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: index == _selectedHotelIndex
                  ? theme.primaryColor
                  : Colors.black87,
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
        actions: [],
      );
    },
  );
}
