import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/constants/payment_config.dart';
import 'package:rent_home/ui/screens_common/auth/auth_controller.dart';
import 'package:rent_home/controller/booking_controller.dart';
import 'package:rent_home/controller/common_controller.dart';
import 'package:rent_home/controller/new_property_controller.dart';
import 'package:rent_home/controller/user_controller.dart';
import 'package:rent_home/models/properties_response_model.dart';
import 'package:rent_home/models/single_property_response.dart';
import 'package:rent_home/screens/Home/homescreen.dart';
import 'package:rent_home/screens/view_property_all_reviews_page.dart';
import 'package:rent_home/service/bookmark_service.dart';
import 'package:rent_home/service/device_service.dart';
import 'package:rent_home/service/property_service.dart';
import 'package:rent_home/widgets/bookmark_properties_page.dart';
import 'package:rent_home/widgets/negotitaion_page.dart';
import 'package:share_plus/share_plus.dart';

class PropertyPage extends StatefulWidget {
  final String image;
  final String name;
  final String price;
  final String description;
  final String rating;
  final int id;
  final String location;
  final String lat;
  final String long;
  final List<String> galleryImages;
  final String? inTime;
  final String? outTime;
  final Property property;
  final bool showNegotiationButton;

  const PropertyPage({
    super.key,
    required this.image,
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.rating,
    required this.lat,
    required this.long,
    required this.galleryImages,
    required this.location,
    this.inTime,
    this.outTime,
    this.showNegotiationButton = true,
    required this.property,
  });

  @override
  _PropertyPageState createState() => _PropertyPageState();
}

class _PropertyPageState extends State<PropertyPage>
    with SingleTickerProviderStateMixin {
  late Razorpay razorpay;
  late double currentPrice;
  int totalDays = 1;
  bool autoAccept = false;
  String currentPriceString = "";
  DateTime selectedDate = DateTime.now();
  bool showPriceAdjuster = false;
  bool isExpanded = false;
  bool showDatePicke = false;
  bool isButtonEnabled = false;
  bool priceConfirmed = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  late TextEditingController _priceController;
  final bookingController = Get.put(BookingController());
  final propertyController =
      Get.put<NewPropertyController>(NewPropertyController());
  bool isCod = false;
  final commonController = Get.find<CommonController>();
  DateTime? selectedDateTo;
  bool _isBookmarked = false;
  String bookingType = 'Daily'; // Default booking type

  // Prebooking mode: if negotiation button is hidden, this page is opened from prebooking
  bool get isPrebooking => !widget.showNegotiationButton;

  // Single property fetch
  final PropertyService _propertyService = PropertyService();
  SinglePropertyData? _single;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    currentPrice = double.parse(widget.price);
    currentPriceString = currentPrice.toStringAsFixed(0);
    _priceController = TextEditingController(text: currentPriceString);
    propertyController.getPropertyReviews(widget.id);
    razorpay = Razorpay();

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    ever(bookingController.isLoading, (value) => {if (value) {}});

    _checkBookmarkStatus();

    // Fetch full property details
    _fetchSingleProperty();
  }

  Future<void> _fetchSingleProperty() async {
    try {
      final resp = await _propertyService.getSingleProperty(widget.id);
      setState(() {
        _single = resp.data;
        // If API provides a price, adopt it as the base
        final apiPrice = _single?.propertyPrice ?? widget.price;
        final parsed = double.tryParse(apiPrice.toString());
        if (parsed != null) {
          currentPrice = parsed;
          _updatePriceString();
        }
      });
    } catch (e) {
      // ignore error; fall back to widget data
    }
  }

  Future<void> _checkBookmarkStatus() async {
    final bookmarkService = BookmarkService();
    _isBookmarked =
        await bookmarkService.isBookmarked(widget.property.propertyId);
    setState(() {});
  }

  void _adjustPrice(double amount) {
    setState(() {
      currentPrice += amount;
      if (currentPrice < 0) {
        currentPrice = 0;
      }
      _updatePriceString();
    });
  }

  void _updatePriceString() {
    double totalPrice;
    if (bookingType == 'Weekly') {
      int totalWeeks = (totalDays / 7).ceil();
      totalPrice = currentPrice * 7 * totalWeeks;
    } else if (bookingType == 'Monthly') {
      int totalMonths = (totalDays / 30).ceil();
      totalPrice = currentPrice * 30 * totalMonths;
    } else {
      totalPrice = currentPrice * totalDays;
    }
    currentPriceString = totalPrice.toStringAsFixed(0);
    _priceController.text = currentPriceString;
  }

  void _toggleExpanded() {
    setState(() {
      if (isExpanded) {
        _animationController.reverse();
      } else {
        _animationController.forward();
      }
      isExpanded = !isExpanded;
    });
  }

  Widget _buildBottomSheet() {
    if (!isExpanded) {
      return GestureDetector(
        onTap: _toggleExpanded,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: kIndigo,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                '₹$currentPriceString',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    const Icon(Icons.person_outline,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 4),
                    const Text('IN/2G', style: TextStyle(color: Colors.white)),
                    const SizedBox(width: 12),
                    Text(
                      bookingType,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.2),
                child: const Icon(Icons.arrow_forward, color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return SizeTransition(
      sizeFactor: _animation,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'View Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: _toggleExpanded,
                    icon: const Icon(Icons.close),
                    color: Colors.grey[600],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Prebooking info banner
              if (isPrebooking)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFEEBA)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF856404)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Prebooking: Pay 10% now to reserve. This advance is non-refundable if you cancel.",
                          style: TextStyle(color: Color(0xFF856404)),
                        ),
                      ),
                    ],
                  ),
                ),
              if (isPrebooking) const SizedBox(height: 16),
              // Booking Type Dropdown
              ListTile(
                leading: const Icon(Icons.category),
                title: DropdownButton<String>(
                  value: bookingType,
                  isExpanded: true,
                  items: ['Daily', 'Weekly', 'Monthly']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      bookingType = newValue!;
                      _updatePriceString();
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                ),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                              primary: kIndigo),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() {
                      selectedDate = picked;
                      selectedDateTo ??= picked.add(const Duration(days: 1));
                      totalDays =
                          selectedDateTo!.difference(selectedDate).inDays + 1;
                      if (totalDays < 1) {
                        totalDays = 1;
                        selectedDateTo =
                            selectedDate.add(const Duration(days: 1));
                      }
                      _updatePriceString();
                      isButtonEnabled = selectedDateTo != null;
                      setState(() {});
                    });
                  }
                },
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: Text(
                  selectedDateTo != null
                      ? '${selectedDateTo!.day}/${selectedDateTo!.month}/${selectedDateTo!.year}'
                      : 'Book To (DD/MM/YYYY)',
                ),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: selectedDate,
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                              primary: kIndigo),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() {
                      selectedDateTo = picked;
                      // selectedDate is non-null by design
                      totalDays =
                          selectedDateTo!.difference(selectedDate).inDays + 1;
                      if (totalDays < 1) {
                        totalDays = 1;
                        selectedDateTo =
                            selectedDate.add(const Duration(days: 1));
                      }
                      _updatePriceString();
                      isButtonEnabled = selectedDateTo != null;
                      setState(() {});
                    });
                  }
                },
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Check-in/Check-out Time'),
                subtitle: Text(
                  "${_single?.propDetails?.inTime ?? widget.inTime ?? "12:00PM"} / ${_single?.propDetails?.outTime ?? widget.outTime ?? "12:00PM"} ",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
              const SizedBox(height: 16),

              const SizedBox(height: 16),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 18, horizontal: 0),
                  child: Column(
                    children: [
                      // Main price row
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: kIndigo.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: const Icon(
                              Icons.currency_rupee,
                              color: kIndigo,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Booking Price',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: kIndigo,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // (Categories moved to main content section)

                                Text(
                                  'Total for selected dates',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text("Total Days of stay: $totalDays",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    )),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 18,
                            ),
                            decoration: BoxDecoration(
                              color: kIndigo,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.pink.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Builder(
                              builder: (context) {
                                final basePrice =
                                    double.parse(currentPriceString);
                                // Dynamic GST calculation based on price
                                // Below ₹7500 => 5%, ₹7500 and above => 12%
                                final gstRate = basePrice <= 7500 ? 0.05 : 0.18;
                                final gstAmount = basePrice * gstRate;
                                const platformFee = 10.0; // ₹10 platform fee
                                final finalPrice =
                                    basePrice + gstAmount + platformFee;

                                return Text(
                                  '₹${finalPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Price breakdown
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: Builder(
                          builder: (context) {
                            final basePrice = double.parse(currentPriceString);
                            // Dynamic GST calculation based on price
                            // Below ₹7500 => 5%, ₹7500 and above => 12%
                            final gstRate = basePrice <= 7500 ? 0.05 : 0.18;
                            final gstAmount = basePrice * gstRate;
                            const platformFee = 10.0; // ₹10 platform fee
                            final finalPrice =
                                basePrice + gstAmount + platformFee;

                            return Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Base Price',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    Text(
                                      '₹${basePrice.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'GST (${(gstRate * 100).toStringAsFixed(0)}%)',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    Text(
                                      '₹${gstAmount.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Platform Fee',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    Text(
                                      '₹${platformFee.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Divider(
                                    color: Colors.grey.shade300,
                                    thickness: 1,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total Amount',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: kIndigo,
                                      ),
                                    ),
                                    Text(
                                      '₹${finalPrice.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: kIndigo,
                                      ),
                                    ),
                                  ],
                                ),
                                // Weekly price info if available from API
                                if (_single?.propDetails?.weeklyMiniPrice !=
                                        null &&
                                    _single!.propDetails!.weeklyMiniPrice!
                                        .isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Divider(color: Colors.grey.shade300),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Weekly Min Price',
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700]),
                                      ),
                                      Text(
                                        '₹${_single!.propDetails!.weeklyMiniPrice}',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[700]),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Weekly Max Price',
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700]),
                                      ),
                                      Text(
                                        '₹${_single!.propDetails!.weeklyMaxPrice ?? "-"}',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[700]),
                                      ),
                                    ],
                                  ),
                                ],
                                if (isPrebooking) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Advance (10%)',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      Text(
                                        '₹${(finalPrice * 0.10).toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Due at Check-in (90%)',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      Text(
                                        '₹${(finalPrice * 0.90).toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              // COD is not applicable in prebooking (10% must be paid now)
              if (!isPrebooking)
                Row(
                  children: [
                    Checkbox(
                      value: isCod,
                      onChanged: (value) {
                        setState(() {
                          isCod = value!;
                        });
                      },
                    ),
                    const Text('Make the payment upon arrival',
                        style: TextStyle(fontSize: 16)),
                  ],
                )
              else
                const Row(
                  children: [
                    Icon(Icons.lock_outline, color: kIndigo),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Advance required: Online payment of 10% to confirm prebooking',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 10),
              // add text showing you can cancel before 30 days without penalty or the advance is non-refundable
              if (isPrebooking)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: const Text(
                    "You can cancel free of cost up to 30 days before check-in. The 10% advance is non-refundable if you cancel later.",
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 10),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (selectedDateTo != null) {
                    _toggleExpanded();
                    String formattedDate =
                        DateFormat('dd-MM-yyyy').format(selectedDate);
                    final AuthController authController =
                        Get.find<AuthController>();
                    String formattedDateTo = selectedDateTo != null
                        ? DateFormat('dd-MM-yyyy').format(selectedDateTo!)
                        : "";
                    // Compute totals
                    final basePrice = double.parse(currentPriceString);
                    // Below ₹7500 => 5%, ₹7500 and above => 12%
                    final gstRate = basePrice <= 7500 ? 0.05 : 0.18;
                    final gstAmount = basePrice * gstRate;
                    const platformFee = 10.0;
                    double finalAmount = basePrice + gstAmount + platformFee;
                    double advanceAmount = (finalAmount * 0.10);

                    // If prebooking, disable COD and charge only 10% now
                    if (isPrebooking) {
                      isCod = false;
                    }

                    var amountToChargeNow =
                        isPrebooking ? advanceAmount : finalAmount;

                    // trip the value to one decimal palce only
                    amountToChargeNow =
                        double.parse(amountToChargeNow.toStringAsFixed(0));
                    finalAmount = double.parse(finalAmount.toStringAsFixed(0));
                    advanceAmount =
                        double.parse(advanceAmount.toStringAsFixed(0));

                    final bookingData = {
                      "propertyId": widget.id,
                      // Send the amount we intend to charge now so backend creates matching order
                      "price": amountToChargeNow,
                      "bookFrom": formattedDate,
                      "bookTo": formattedDateTo,
                      "isCod": isCod,
                      "category": 1,
                      "bookingType": bookingType,
                      // Extra informational fields for server (safe to ignore if unsupported)
                      "isPrebooking": isPrebooking,
                      "totalAmount": finalAmount,
                      "advanceAmount": advanceAmount,
                    };
                    final bookingResponse =
                        await bookingController.createBooking(bookingData);
                    if (!isCod) {
                      final String? orderId =
                          bookingResponse.data.booking.order?.id;
                      if (orderId == null || orderId.isEmpty) {
                        bookingController.showSnackbar(
                          "Payment Error",
                          "Unable to initiate payment order.",
                          true,
                        );
                        return;
                      }
                      final contact =
                          authController.userData.value!.phoneNumber;
                      final email = authController.userData.value!.email;
                      final options = {
                        "key": PaymentConfig.razorpayKey,
                        // Charge either 100% (normal) or 10% (prebooking)
                        "amount": (amountToChargeNow * 100).toInt(),
                        "name": "Aajoo",
                        'description': isPrebooking
                            ? 'Prebooking advance (10%) for Property ID: ${widget.id}'
                            : 'Payment for Order ID: ${widget.id}',
                        'order_id': orderId,
                        'prefill': {'email': email, 'contact': contact},
                        'theme': {'color': '#3399cc'}
                      };
                      try {
                        razorpay.open(options);
                      } catch (e) {
                        debugPrint('Error: $e');
                      }
                    } else {
                      successDialog("N/A", bookingResponse.data.booking.bookId);
                    }
                  } else {
                    Fluttertoast.showToast(
                      msg: "Please select valid dates",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      backgroundColor: Colors.red,
                      textColor: Colors.white,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kIndigo,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  isPrebooking ? 'Pay 10% & Book' : 'Book Now',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              Visibility(
                visible: widget.showNegotiationButton,
                child: ElevatedButton(
                  onPressed: () async {
                    final AuthController authController =
                        Get.find<AuthController>();
                    final token =
                        await const FlutterSecureStorage().read(key: "user_token");
                    if (token == null) {
                      Fluttertoast.showToast(
                        msg: "Please login to negotiate price",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => PriceNegotiationPage(
                          userId:
                              authController.userData.value!.userId.toString(),
                          propertyId: widget.id.toString(),
                          serverUrl: "https://aajaodev.onrender.com",
                          receiverId: widget.property.propertyHostId.toString(),
                          token: token,
                          lat: widget.lat,
                          senderId:
                              authController.userData.value!.userId.toString(),
                          long: widget.long,
                          property: widget.property,
                          hostId: widget.property.propertyHostId.toString(),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    textStyle: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text('Offer Your Price'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    // Prefer categories from single property API, otherwise fall back to list item
    final List<String> catTitles = _single?.categories != null
        ? _single!.categories!
            .map((e) => e is Map
                ? (e['cat_title']?.toString() ?? e.toString())
                : e.toString())
            .toList()
        : [
            ...widget.property.categoryTitles,
            ...?widget.property.categories,
          ];

    if (catTitles.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: catTitles.map((c) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blueGrey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blueGrey.withOpacity(0.3)),
            ),
            child: Text(
              c,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTags() {
    final List<String> tags = _single?.tags != null
        ? _single!.tags!
            .map((e) => e is Map
                ? (e['tag_name']?.toString() ?? e.toString())
                : e.toString())
            .toList()
        : (widget.property.tags ?? []);

    if (tags.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tags.map((t) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Text(
              t,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPriceChip(double price) {
    final bool isSelected = double.parse(currentPriceString) == price;
    return GestureDetector(
      onTap: () {
        setState(() {
          currentPriceString = price.toStringAsFixed(0);
          currentPrice = price /
              (bookingType == 'Weekly'
                  ? 7 * (totalDays / 7).ceil()
                  : bookingType == 'Monthly'
                      ? 30 * (totalDays / 30).ceil()
                      : totalDays);
          _priceController.text = currentPriceString;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? kIndigo : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? kIndigo : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          '₹$price',
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _priceController.dispose();
    razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 400,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      (_single?.images != null && _single!.images!.isNotEmpty)
                          ? CarouselSlider(
                              options: CarouselOptions(
                                aspectRatio: 16 / 16,
                                viewportFraction: 1.0,
                                initialPage: 0,
                                enableInfiniteScroll: true,
                                autoPlay: true,
                                autoPlayInterval: const Duration(seconds: 2),
                                autoPlayAnimationDuration:
                                    const Duration(milliseconds: 800),
                                autoPlayCurve: Curves.fastOutSlowIn,
                                enlargeCenterPage: false,
                                height: 900,
                              ),
                              items: _single!.images!.map((imageUrl) {
                                return Builder(
                                  builder: (BuildContext context) {
                                    return CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      fit: BoxFit.cover,
                                      height: 400,
                                      width: double.infinity,
                                      placeholder: (context, url) =>
                                          const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          const Center(
                                        child: Icon(Icons.error,
                                            color: Colors.red),
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                            )
                          : widget.galleryImages.isNotEmpty
                              ? CarouselSlider(
                                  options: CarouselOptions(
                                    aspectRatio: 16 / 16,
                                    viewportFraction: 1.0,
                                    initialPage: 0,
                                    enableInfiniteScroll: true,
                                    autoPlay: true,
                                    autoPlayInterval:
                                        const Duration(seconds: 2),
                                    autoPlayAnimationDuration:
                                        const Duration(milliseconds: 800),
                                    autoPlayCurve: Curves.fastOutSlowIn,
                                    enlargeCenterPage: false,
                                    height: 900,
                                  ),
                                  items: widget.galleryImages.map((imageUrl) {
                                    return Builder(
                                      builder: (BuildContext context) {
                                        return CachedNetworkImage(
                                          imageUrl: imageUrl,
                                          fit: BoxFit.cover,
                                          height: 400,
                                          width: double.infinity,
                                          placeholder: (context, url) =>
                                              const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              const Center(
                                            child: Icon(Icons.error,
                                                color: Colors.red),
                                          ),
                                        );
                                      },
                                    );
                                  }).toList(),
                                )
                              : CachedNetworkImage(
                                  imageUrl: widget.image,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  placeholder: (context, url) =>
                                      const CircularProgressIndicator(),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error),
                                ),
                      Positioned(
                        bottom: 20,
                        left: 16,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star,
                                      size: 16, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Obx(
                                    () => propertyController.isLoading.value
                                        ? const Text("0.0")
                                        : propertyController
                                                    .propertyReviewResponse
                                                    .value
                                                    .data!
                                                    .averageRating
                                                    .toString() ==
                                                "null"
                                            ? Text(
                                                "4.2",
                                                style: theme
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(
                                                  color: Colors.white,
                                                ),
                                              )
                                            : Text(
                                                propertyController
                                                    .propertyReviewResponse
                                                    .value
                                                    .data!
                                                    .averageRating
                                                    .toString(),
                                                style: theme
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(
                                                  color: Colors.white,
                                                ),
                                              ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    "Apartment",
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                leading: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.white),
                ),
                actions: [
                  IconButton(
                    onPressed: () {
                      final shareText = '''
Check out this amazing property on Aajoo!
Name: ${widget.name}
Location: ${widget.location}
Price: ₹${widget.price}/night
Rating: ${widget.rating} ★
Description: ${widget.description}
Book now: https://aajoo.com/property/${widget.id}
''';
                      Share.share(
                        shareText,
                        subject: 'Check out ${widget.name} on Aajoo!',
                      );
                    },
                    icon: const Icon(Icons.share),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.white),
                  ),
                  IconButton(
                    onPressed: () async {
                      final bookmarkService = BookmarkService();
                      if (_isBookmarked) {
                        await bookmarkService
                            .removeBookmark(widget.property.propertyId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.white,
                            content: Text(
                              '${widget.name} removed from bookmarks',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                            action: SnackBarAction(
                              label: 'View Bookmarks',
                              textColor: theme.primaryColor,
                              onPressed: () {
                                Get.to(() => const BookmarkedPropertiesPage());
                              },
                            ),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      } else {
                        await bookmarkService.addBookmark(widget.property);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.white,
                            content: Text(
                              '${widget.name} added to bookmarks',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                            action: SnackBarAction(
                              label: 'View Bookmarks',
                              textColor: theme.primaryColor,
                              onPressed: () {
                                Get.to(() => const BookmarkedPropertiesPage());
                              },
                            ),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                      setState(() {
                        _isBookmarked = !_isBookmarked;
                      });
                    },
                    icon: Icon(
                      _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color:
                          _isBookmarked ? theme.primaryColor : Colors.grey[400],
                    ),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.white),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.name,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 35,
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              final bookmarkService = BookmarkService();
                              if (_isBookmarked) {
                                await bookmarkService
                                    .removeBookmark(widget.property.propertyId);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: Colors.white,
                                    content: Text(
                                      '${widget.name} removed from bookmarks',
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 16,
                                      ),
                                    ),
                                    action: SnackBarAction(
                                      label: 'View Bookmarks',
                                      textColor: theme.primaryColor,
                                      onPressed: () {
                                        Get.to(
                                            () => const BookmarkedPropertiesPage());
                                      },
                                    ),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              } else {
                                await bookmarkService
                                    .addBookmark(widget.property);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: Colors.white,
                                    content: Text(
                                      '${widget.name} added to bookmarks',
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 16,
                                      ),
                                    ),
                                    action: SnackBarAction(
                                      label: 'View Bookmarks',
                                      textColor: theme.primaryColor,
                                      onPressed: () {
                                        Get.to(
                                            () => const BookmarkedPropertiesPage());
                                      },
                                    ),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                              setState(() {
                                _isBookmarked = !_isBookmarked;
                              });
                            },
                            icon: Icon(
                              _isBookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: _isBookmarked
                                  ? theme.primaryColor
                                  : Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: Wrap(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 20,
                              color: Colors.deepOrangeAccent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.location,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Property Description",
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        _single?.propertyDesc ?? widget.description,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Check In/Out Time",
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            _single?.propDetails?.inTime ?? "Not Available",
                            style: theme.textTheme.bodyLarge,
                          ),
                          const SizedBox(width: 4),
                          const Text("•"),
                          const SizedBox(width: 4),
                          Text(
                            _single?.propDetails?.outTime ?? "Not Available",
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Amenities",
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildAmenities(),
                      const SizedBox(height: 16),
                      Text(
                        "Host Details",
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 2),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 30,
                              backgroundImage: NetworkImage(
                                'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ4YreOWfDX3kK-QLAbAL4ufCPc84ol2MA8Xg&s',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.property.propertyContact ??
                                      "Not Available",
                                  style: context.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _single?.propertyEmail ?? "Not Available",
                                  style: context.textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Property Rules",
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  widget.property
                                              .propDetailsPropDetailIsPetFriendly ==
                                          true
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: widget.property
                                              .propDetailsPropDetailIsPetFriendly ==
                                          true
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                const SizedBox(width: 8),
                                const Text("Pet Friendly"),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  widget.property
                                              .propDetailsPropDetailIsSmoke ==
                                          true
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: widget.property
                                              .propDetailsPropDetailIsSmoke ==
                                          true
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                const SizedBox(width: 8),
                                const Text("Smoking Allowed"),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Gallery",
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildImageGallery(),
                      const SizedBox(height: 16),
                      Text(
                        "Tags",
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTags(),
                      const SizedBox(height: 16),
                      _buildReviews(),
                      const SizedBox(height: 90),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Obx(() {
              if (bookingController.isLoading.value) {
                return FloatingActionButton(
                  onPressed: () {},
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: kcontentColor,
                    ),
                  ),
                );
              } else {
                return _buildBottomSheet();
              }
            }),
          ),
        ],
      ),
      floatingActionButton: priceConfirmed
          ? Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: FloatingActionButton.extended(
                onPressed: () {},
                backgroundColor: Colors.blue,
                label: const Text('Confirm Booking'),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildAmenities() {
    // Check if property has amenities data
    if (widget.property.amenities != null &&
        widget.property.amenities!.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property-specific amenities
          _buildPropertyDataSection("Amenities", widget.property.amenities!),
          const SizedBox(height: 16),

          // Property categories if available
          if (widget.property.categories != null &&
              widget.property.categories!.isNotEmpty) ...[
            _buildPropertyDataSection(
                "Categories", widget.property.categories!),
            const SizedBox(height: 16),
          ],

          // Property tags if available
          if (widget.property.tags != null && widget.property.tags!.isNotEmpty)
            _buildPropertyDataSection("Tags", widget.property.tags!),
        ],
      );
    }

    // Fallback to common tags if no property-specific data
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(
            commonController.tags.value?.data.tags.length ?? 0, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.0),
            child: Chip(
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: Colors.orange.shade100,
                  width: 1.5,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(60)),
              ),
              backgroundColor: Colors.orange.shade100,
              label: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0.0),
                child: Text(
                  commonController.tags.value!.data.tags[index].tagName
                      .toString()
                      .capitalize!,
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPropertyDataSection(String title, List<dynamic> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: items.map<Widget>((item) {
              String displayName = '';
              Color chipColor = Colors.blue.shade100;
              Color textColor = Colors.blue.shade900;

              // Handle different data structures
              if (item is Map<String, dynamic>) {
                // Extract name from different possible fields
                displayName = item['name']?.toString() ??
                    item['title']?.toString() ??
                    item['amenity_name']?.toString() ??
                    item['category_name']?.toString() ??
                    item['tag_name']?.toString() ??
                    'Unknown';
              } else {
                displayName = item.toString();
              }

              // Set different colors for different types
              if (title == 'Categories') {
                chipColor = Colors.green.shade100;
                textColor = Colors.green.shade900;
              } else if (title == 'Tags') {
                chipColor = Colors.purple.shade100;
                textColor = Colors.purple.shade900;
              }

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Chip(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: chipColor,
                      width: 1.5,
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                  ),
                  backgroundColor: chipColor,
                  label: Text(
                    displayName.capitalize ?? displayName,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildImageGallery() {
    return SizedBox(
      height: 100,
      child: ((_single?.images == null || _single!.images!.isEmpty) &&
              widget.galleryImages.isEmpty)
          ? const Center(child: Text("No images available."))
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount:
                  (_single?.images != null && _single!.images!.isNotEmpty)
                      ? _single!.images!.length
                      : widget.galleryImages.length,
              itemBuilder: (context, index) {
                final url =
                    (_single?.images != null && _single!.images!.isNotEmpty)
                        ? _single!.images![index]
                        : widget.galleryImages[index];
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: url,
                      width: 150,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const CircularProgressIndicator(),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildReviews() {
    final propertyController = Get.find<NewPropertyController>();

    return Obx(() {
      final reviewResponse = propertyController.propertyReviewResponse.value;

      if (reviewResponse.data == null ||
          reviewResponse.data!.reviews == null ||
          reviewResponse.data!.reviews!.isEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Reviews",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Center(
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.grey.shade50, Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0.8, end: 1.0),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeInOut,
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: child,
                          );
                        },
                        child: Icon(
                          Icons.star_border,
                          size: 48,
                          color: Colors.amber.shade300,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No Reviews Yet",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Be the first to share your experience!",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }

      return GestureDetector(
        onTap: () => Get.to(() => ViewPropertyAllReviewsPage(
              propertyId: widget.id,
            )),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Reviews",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Center(
              child: Card(
                color: Colors.grey.shade50,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        "${reviewResponse.data?.averageRating?.substring(0, 3)} ★",
                        style: const TextStyle(
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                          color: kprimaryColor,
                        ),
                      ),
                      Text(
                          "${reviewResponse.data?.reviews?.length ?? 0} Reviews"),
                      Column(
                        children: [5, 4, 3, 2, 1].map((rating) {
                          final count =
                              reviewResponse.data?.allRatings?["$rating"] ?? 0;
                          final total =
                              reviewResponse.data?.reviews?.length ?? 1;
                          final percentage = (count / total) * 100;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Text(
                                  "$rating",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Stack(
                                    children: [
                                      Container(
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                      ),
                                      Container(
                                        height: 10,
                                        width:
                                            MediaQuery.of(context).size.width *
                                                (percentage / 100),
                                        decoration: BoxDecoration(
                                          color: kprimaryColor,
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text("$count reviews"),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(),
            ...reviewResponse.data!.reviews!.take(5).map(
                  (review) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              review.userFullName?.toString() ?? "Anonymous",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: List.generate(
                                5,
                                (index) => Icon(
                                  index < double.parse(review.brRating!).floor()
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: kprimaryColor,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(review.brDesc ?? "No description provided."),
                        const Divider(),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      );
    });
  }

  void successDialog(String paymentId, String bookingId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Image.asset("assets/success.image.png", height: 200),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Booking Successful",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text("Booking Id: $bookingId"),
              const SizedBox(height: 16),
              Text("Payment Id: $paymentId"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  CupertinoPageRoute(builder: (context) => const Homescreen()),
                  (route) => false,
                );
              },
              child: const Text("Close"),
            ),
            ElevatedButton(
              onPressed: () async {
                final lat = double.parse(widget.lat);
                final long = double.parse(widget.long);
                if (Platform.isAndroid) {
                  DeviceService.launchGoogleMaps(lat, long);
                }
                DeviceService.showMapOptions(context, lat, long);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kprimaryColor,
                minimumSize: const Size(100, 50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Get Directions"),
            ),
          ],
        );
      },
    );
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final result = await bookingController.verifyPayment(
      response.orderId!,
      response.paymentId!,
      response.signature!,
    );
    if (result) {
      Fluttertoast.showToast(msg: "Payment Successful: ${response.paymentId}");
      final bookingId = bookingController.bookingResponse.value?.data.booking.bookId;
      successDialog(response.paymentId!, bookingId.toString());
      final userController = Get.find<UserController>();
      userController.fetchOngoingBookings();
    } else {
      bookingController.showSnackbar(
        "Payment Failed",
        "Payment has been failed",
        true,
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Fluttertoast.showToast(msg: "Payment Failed: ${response.message}");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Fluttertoast.showToast(msg: "External Wallet: ${response.walletName}");
  }
}
