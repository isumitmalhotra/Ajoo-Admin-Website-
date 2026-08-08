import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/controller/common_controller.dart';
import 'package:rent_home/controller/map_controller.dart';
import 'package:rent_home/controller/notication_controller.dart';
import 'package:rent_home/controller/search_controller.dart';
import 'package:rent_home/controller/user_controller.dart';
import 'package:rent_home/screens/Home/map_screen.dart';
import 'package:rent_home/screens/Home/ongoing_widget.dart';
import 'package:rent_home/screens/Home/pre_booking_screen.dart';
import 'package:rent_home/screens/notification_screen.dart';
import 'package:rent_home/service/notification_service.dart';
import 'package:rent_home/widgets/custom_drawer.dart';
import 'package:rent_home/widgets/prebooking_home_carousel.dart';
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
    userController.fetchOngoingBookings();
    searchController.getPreBooking();

    // Initialize categories for search functionality
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
      appBar: AppBar(
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
                    builder: (BuildContext context) => const NotificationsScreen(),
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
      ),
      drawer: CustomDrawer(),
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(
              child: MapScreen(),
            ),
            // // Top Bar
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

            // Bottom Sheet with Swipe
            DraggableScrollableSheet(
              controller: _dragController,
              initialChildSize: 0.28,
              minChildSize: 0.25,
              maxChildSize: 0.72,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
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
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
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
                      ),
                      const SizedBox(height: 10),
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.topCenter,
                        children: [
                          // Main Bottom Sheet Content
                          Container(
                            height: size.height * 0.7,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(40.0),
                                topRight: Radius.circular(40.0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 5,
                                  offset: Offset(0, -5),
                                ),
                              ],
                            ),
                            child: SingleChildScrollView(
                              controller: scrollController,
                              // physics: const NeverScrollableScrollPhysics(),
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Column(
                                children: [
                                  // Drag handle
                                  Container(
                                    height: 4,
                                    width: 40,
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 0),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const SizedBox(
                                            height: 10,
                                          ),

                                          Obx(() {
                                            if (mapController.isLoading.value) {
                                              return const SizedBox.shrink();
                                            } else {
                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Find Your Stay",
                                                    style: theme
                                                        .textTheme.headlineSmall
                                                        ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: 310,
                                                    child:
                                                        PreBookingHomeCarousel(
                                                            properties:
                                                                mapController
                                                                    .properties
                                                                    .toList()),
                                                  ),
                                                ],
                                              );
                                            }
                                          }),
                                          const SizedBox(height: 10),
                                          Text(
                                            "Browse by Category",
                                            style: theme.textTheme.headlineSmall
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          SizedBox(
                                            height: 100,
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                children: [
                                                  const SizedBox(width: 20),
                                                  _hotelTypeBlock(
                                                      1,
                                                      "assets/family.png",
                                                      "Family"),
                                                  const SizedBox(width: 20),
                                                  _hotelTypeBlock(
                                                      0,
                                                      "assets/sharing.png",
                                                      "Sharing"),
                                                  const SizedBox(width: 20),
                                                  _hotelTypeBlock(
                                                      2,
                                                      "assets/couple.png",
                                                      "Couple"),
                                                  const SizedBox(width: 20),
                                                  _hotelTypeBlock(
                                                      3,
                                                      "assets/girls.png",
                                                      "Party"),
                                                  const SizedBox(width: 20),
                                                  _hotelTypeBlock(
                                                      4,
                                                      "assets/boy.png",
                                                      "Single"),
                                                  const SizedBox(width: 20),
                                                ],
                                              ),
                                            ),
                                          ),

                                          const SizedBox(height: 30),
                                          // Search ba

                                          // Find home button row
                                          Row(
                                            children: [
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: InkWell(
                                                  onTap: () {
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                const PreBookingScreen()));
                                                  },
                                                  child: Container(
                                                    height: 50,
                                                    decoration: BoxDecoration(
                                                      color: theme.primaryColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                    child: const Center(
                                                      child: Text(
                                                        "Pre Booking",
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 20),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              InkWell(
                                                onTap: () {
                                                  _showLuxuryModeDialog(
                                                      context, isLuxury, (val) {
                                                    setState(() {
                                                      isLuxury = val;
                                                    });
                                                    mapController.isLuxury
                                                        .value = isLuxury;
                                                    if (isLuxury) {
                                                      mapController
                                                          .fetchLuxuryProperties();
                                                    } else {
                                                      mapController
                                                          .fetchProperties();
                                                    }
                                                  });
                                                },
                                                child: Container(
                                                  height: 50,
                                                  width: 100,
                                                  decoration: BoxDecoration(
                                                    color: isLuxury
                                                        ? theme.primaryColor
                                                            .withOpacity(0.8)
                                                        : theme.primaryColor
                                                            .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceEvenly,
                                                      children: [
                                                        Center(
                                                          child: Image.asset(
                                                            "assets/diamond .png",
                                                            height: 40,
                                                          ),
                                                        ),
                                                        Text(
                                                          isLuxury
                                                              ? "NOR"
                                                              : "LUX",
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w900,
                                                              fontSize: 20,
                                                              color: isLuxury
                                                                  ? Colors.white
                                                                  : theme
                                                                      .primaryColor),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          // Image row
                                          const SizedBox(height: 20),

                                          // const SizedBox(height: 20),
                                          buildReviewList(),
                                          const SizedBox(height: 40),
                                        ]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Lottie Animation positioned above the sheet
                        ],
                      ),
                    ],
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
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin:
                              const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                          child: ListTile(
                            tileColor: Colors.grey[400],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
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
                            backgroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            side: BorderSide(
                                color: Theme.of(context).primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
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
                  ? theme.primaryColor.withOpacity(0.6)
                  : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.primaryColor,
                width: 2,
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
        actions: const [],
      );
    },
  );
}

class FilterDialogContent extends StatefulWidget {
  final Function(int selectedCategory, double selectedRadius,
      double? weeklyPrice, double? monthlyPrice) onApply;

  const FilterDialogContent({super.key, required this.onApply});

  @override
  State<FilterDialogContent> createState() => _FilterDialogContentState();
}

class _FilterDialogContentState extends State<FilterDialogContent> {
  String? selectedCategory;
  double selectedRadius = 1.0;
  double weeklyPrice = 500.0; // Default weekly price
  double monthlyPrice = 2000.0; // Default monthly price
  bool weeklyAny = false;
  bool monthlyAny = false;

  final CommonController commonController = Get.put(CommonController());

  @override
  void initState() {
    super.initState();
    commonController.fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Obx(() {
        // Handle loading state
        if (commonController.cats.value == null) {
          return const Center(
            child: CircularProgressIndicator(
              color: kprimaryColor,
            ),
          );
        }

        // Handle empty categories
        if (commonController.cats.value!.data.categories.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'No categories available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        // Initialize selectedCategory if not set
        selectedCategory ??=
            commonController.cats.value!.data.categories[0].catTitle;

        return Container(
          padding: const EdgeInsets.all(20.0),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Filter Properties',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(height: 20),

              // Category Dropdown
              // _buildSectionTitle('Property Category'),
              // Container(
              //   padding: const EdgeInsets.symmetric(horizontal: 12),
              //   decoration: BoxDecoration(
              //     border:
              //         Border.all(color: theme.primaryColor.withOpacity(0.3)),
              //     borderRadius: BorderRadius.circular(10),
              //   ),
              //   child: DropdownButton<String>(
              //     isExpanded: true,
              //     focusColor: Colors.transparent,
              //     value: selectedCategory,
              //     icon: Icon(Icons.arrow_drop_down, color: theme.primaryColor),
              //     iconSize: 24,
              //     underline: const SizedBox(),
              //     onChanged: (String? newValue) {
              //       setState(() {
              //         selectedCategory = newValue!;
              //       });
              //     },
              //     items: commonController.cats.value!.data.categories
              //         .map<DropdownMenuItem<String>>((category) {
              //       return DropdownMenuItem<String>(
              //         value: category.catTitle,
              //         child: Text(
              //           category.catTitle.capitalizeFirst!,
              //           style: TextStyle(
              //             fontSize: 16,
              //             color: theme.primaryColor,
              //           ),
              //         ),
              //       );
              //     }).toList(),
              //   ),
              // ),
              const SizedBox(height: 20),

              // Radius Slider
              _buildSectionTitle('Search Radius (km)'),
              _buildSlider(
                value: selectedRadius,
                min: 1,
                max: 15,
                divisions: 14,
                label: '${selectedRadius.round()} km',
                onChanged: (double newValue) {
                  setState(() {
                    selectedRadius = newValue;
                  });
                },
              ),

              // Weekly Price Slider
              _buildSectionTitle('Weekly Price (₹)'),
              _buildSlider(
                value: weeklyAny ? 500.0 : weeklyPrice,
                min: 100,
                max: 5000,
                divisions: 49,
                label: weeklyAny ? 'Any' : '₹${weeklyPrice.round()}',
                onChanged: (double newValue) {
                  setState(() {
                    weeklyPrice = newValue;
                  });
                },
                allowAny: true,
                onAnyToggle: (bool isAny) {
                  setState(() {
                    weeklyAny = isAny;
                  });
                },
                anyChecked: weeklyAny,
              ),

              // Monthly Price Slider
              _buildSectionTitle('Monthly Price (₹)'),
              _buildSlider(
                value: monthlyAny ? 2000.0 : monthlyPrice,
                min: 500,
                max: 20000,
                divisions: 39,
                label: monthlyAny ? 'Any' : '₹${monthlyPrice.round()}',
                onChanged: (double newValue) {
                  setState(() {
                    monthlyPrice = newValue;
                  });
                },
                allowAny: true,
                onAnyToggle: (bool isAny) {
                  setState(() {
                    monthlyAny = isAny;
                  });
                },
                anyChecked: monthlyAny,
              ),

              const SizedBox(height: 20),

              // Buttons
              Column(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: theme.primaryColor,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      int selectedCategoryId = commonController
                          .cats.value!.data.categories
                          .firstWhere((category) =>
                              category.catTitle == selectedCategory)
                          .catId;

                      widget.onApply(
                        selectedCategoryId,
                        selectedRadius,
                        weeklyAny ? null : weeklyPrice,
                        monthlyAny ? null : monthlyPrice,
                      );
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Apply',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 50),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Cancel',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSlider({
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required Function(double) onChanged,
    bool allowAny = false,
    Function(bool)? onAnyToggle,
    bool anyChecked = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            if (allowAny)
              Row(
                children: [
                  const Text(
                    'Any',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  Checkbox(
                    value: anyChecked,
                    onChanged: (bool? isChecked) {
                      onAnyToggle?.call(isChecked ?? false);
                    },
                    activeColor: Theme.of(context).primaryColor,
                  ),
                ],
              ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: label,
          onChanged: (double newValue) {
            onChanged(newValue);
          },
          activeColor: Theme.of(context).primaryColor,
          inactiveColor: Theme.of(context).primaryColor.withOpacity(0.2),
        ),
      ],
    );
  }
}
