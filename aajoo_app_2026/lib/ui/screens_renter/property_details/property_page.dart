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
import 'package:rent_home/ui/screens_renter/booking_controller.dart';
import 'package:rent_home/controller/common_controller.dart';
import 'package:rent_home/data/ApiConstants.dart';
import 'package:rent_home/ui/screens_host/add_property/new_property_controller_legacy.dart';
import 'package:rent_home/controller/user_controller.dart';
import 'package:rent_home/data/models/properties_response_model.dart';
import 'package:rent_home/data/models/single_property_response.dart';
import 'package:rent_home/ui/screens_renter/history/history_description/review/all_reviews_list/view_property_all_reviews_page.dart';
import 'package:rent_home/service/bookmark_service.dart';
import 'package:rent_home/service/property_service.dart';
import 'package:rent_home/service/booking_service.dart';
import 'package:rent_home/service/deals_service.dart';
import 'package:rent_home/ui/screens_renter/property_details/components/booking_succes_dialog.dart';
import 'package:rent_home/ui/screens_renter/bookmark_properties/bookmark_properties_page.dart';
import 'package:rent_home/ui/screens_common/price_negotiation/negotitaion_page.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/widgets/amenity_row.dart';
import 'package:rent_home/widgets/host_card.dart';
import 'package:rent_home/widgets/verified_pill.dart';
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
  // Optional negotiated-deal context — set when this page is opened from a
  // "Book now" deal (dashboard/home banner). Pre-fills the agreed dates, shows a
  // deal banner, and applies the coupon at checkout.
  final String? dealCode;
  final String? dealFrom; // DD-MM-YYYY
  final String? dealTo; // DD-MM-YYYY
  final int? dealPercent;

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
    this.dealCode,
    this.dealFrom,
    this.dealTo,
    this.dealPercent,
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

    // Opened from a negotiated deal → pre-fill the agreed stay so the renter can
    // book the exact sanctioned dates at the agreed price in one step.
    _applyDealDates();
    if (hasDeal) {
      _couponController.text = widget.dealCode!;
      _appliedCoupon = widget.dealCode;
      _couponPercent = widget.dealPercent ?? 0;
      _couponOk = true;
      _couponMsg = widget.dealPercent != null
          ? 'Negotiated deal — ${widget.dealPercent}% off'
          : 'Negotiated deal applied';
    }

    // Grey out already-booked nights in the date picker.
    _loadAvailability();

    // Fetch full property details
    _fetchSingleProperty();
  }

  // Parse the deal's DD-MM-YYYY window into the date pickers + totals.
  void _applyDealDates() {
    DateTime? parse(String? s) {
      if (s == null || s.isEmpty) return null;
      final p = s.split('-');
      if (p.length != 3) return null;
      final d = int.tryParse(p[0]), m = int.tryParse(p[1]), y = int.tryParse(p[2]);
      if (d == null || m == null || y == null) return null;
      return DateTime(y, m, d);
    }

    final from = parse(widget.dealFrom);
    final to = parse(widget.dealTo);
    if (from != null && to != null && to.isAfter(from)) {
      selectedDate = from;
      selectedDateTo = to;
      totalDays = to.difference(from).inDays;
      if (totalDays < 1) totalDays = 1;
      isButtonEnabled = true;
      _updatePriceString();
    }
  }

  bool get hasDeal => (widget.dealCode?.isNotEmpty ?? false);

  // ── Availability (grey out already-booked nights) ──────────────────────────
  final BookingService _bookingSvc = BookingService();
  List<DateTimeRange> _bookedRanges = [];
  // Booked ranges are inclusive of check-in, exclusive of check-out (a checkout
  // day is re-bookable) — matches the backend overlap guard.
  bool _isBookedDay(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    for (final r in _bookedRanges) {
      if (!day.isBefore(r.start) && day.isBefore(r.end)) return true;
    }
    return false;
  }

  Future<void> _loadAvailability() async {
    final ranges = await _bookingSvc.getBookedRanges(widget.id);
    if (mounted) setState(() => _bookedRanges = ranges);
  }

  // showDatePicker asserts the initialDate is selectable — nudge it off any
  // booked/past day so opening the picker never throws.
  DateTime _safeInitialDate(DateTime candidate, DateTime first) {
    var d = candidate.isBefore(first) ? first : candidate;
    var guard = 0;
    while (_isBookedDay(d) && guard < 400) {
      d = d.add(const Duration(days: 1));
      guard++;
    }
    return d;
  }

  // ── Coupon at checkout (any code) ──────────────────────────────────────────
  final TextEditingController _couponController = TextEditingController();
  final DealsService _dealsSvc = DealsService();
  String? _appliedCoupon; // code currently applied to the booking
  double _couponDiscount = 0;
  int _couponPercent = 0;
  String _couponMsg = '';
  bool _couponOk = false;
  bool _couponBusy = false;

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _appliedCoupon = null;
        _couponOk = false;
        _couponMsg = '';
      });
      return;
    }
    final base = double.tryParse(currentPriceString) ?? 0;
    setState(() => _couponBusy = true);
    final res = await _dealsSvc.validateCoupon(
        code: code, propertyId: widget.id, amount: base);
    if (!mounted) return;
    setState(() {
      _couponBusy = false;
      if (res.valid) {
        _appliedCoupon = res.code ?? code;
        _couponDiscount = res.discount;
        _couponPercent = res.percent;
        _couponOk = true;
        _couponMsg = res.percent > 0
            ? 'Applied — ${res.percent}% off (₹${res.discount.toStringAsFixed(0)})'
            : 'Applied — ₹${res.discount.toStringAsFixed(0)} off';
      } else {
        _appliedCoupon = null;
        _couponOk = false;
        _couponMsg = res.message;
      }
    });
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
      // M8 — sticky bottom book bar
      final perNight = currentPrice.toStringAsFixed(0);
      final nights = totalDays == 1 ? '1 night' : '$totalDays nights';
      return Container(
        decoration: const BoxDecoration(
          color: kCream,
          border: Border(top: BorderSide(color: kLine, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Color(0x141B2447),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
          16,
          14,
          16,
          14 + MediaQuery.of(context).padding.bottom,
        ),
        child: Row(
          children: [
            // Left — price + total
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '₹$perNight',
                          style: fraunces(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: kInk,
                            height: 1.0,
                          ),
                        ),
                        TextSpan(
                          text: ' /night',
                          style: inter(
                            fontSize: 13,
                            color: kMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  // POC adds a subtle underline on the total amount only.
                  RichText(
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: inter(fontSize: 12, color: kMuted),
                      children: [
                        TextSpan(
                          text: '₹$currentPriceString total',
                          style: inter(
                            fontSize: 12,
                            color: kMuted,
                          ).copyWith(decoration: TextDecoration.underline),
                        ),
                        TextSpan(text: ' · $nights'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Right — clay Reserve button
            ElevatedButton(
              onPressed: _toggleExpanded,
              style: ElevatedButton.styleFrom(
                backgroundColor: kClay,
                foregroundColor: kCream,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Reserve'),
            ),
          ],
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
                    initialDate: _safeInitialDate(selectedDate, DateTime.now()),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    selectableDayPredicate: (d) => !_isBookedDay(d),
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
                    initialDate: _safeInitialDate(
                        selectedDateTo ?? selectedDate, selectedDate),
                    firstDate: selectedDate,
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    selectableDayPredicate: (d) => !_isBookedDay(d),
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
                                // ≤₹7500 => 5%, >₹7500 => 18% (matches backend tariff GST)
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
                            // Below ₹7500 => 5%, >₹7500 => 18% (matches backend tariff GST)
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
              // Coupon at checkout — any code (personal deal or a global coupon).
              // Pre-filled + applied when arriving from a negotiated deal.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: kCream,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _couponOk ? kSuccess : kLine),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_offer, size: 18, color: kMuted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _couponController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              hintText: 'Have a coupon code?',
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                        _couponBusy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : TextButton(
                                onPressed: _applyCoupon,
                                child: Text(_couponOk ? 'Change' : 'Apply',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: kIndigo)),
                              ),
                      ],
                    ),
                    if (_couponMsg.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 26, bottom: 6),
                        child: Text(
                          _couponMsg,
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: _couponOk ? kSuccess : kDanger),
                        ),
                      ),
                  ],
                ),
              ),
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
                    // Below ₹7500 => 5%, >₹7500 => 18% (matches backend tariff GST)
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
                    // Any applied coupon (a negotiated deal OR a code the renter
                    // entered): send the room subtotal (pre-GST) + the code so the
                    // backend applies the discount and adds GST cleanly (like web)
                    // and consumes/validates the coupon. Non-coupon bookings are
                    // untouched.
                    if (_appliedCoupon != null && _appliedCoupon!.isNotEmpty) {
                      bookingData["price"] = basePrice;
                      bookingData["couponCode"] = _appliedCoupon!;
                    }
                    // KYC gate — renters are verified at registration; this
                    // catches anyone who skipped. An unverified guest must
                    // complete DIDIT before booking, then returns here to retry.
                    if (authController.userData.value?.isKycVerified != true) {
                      final verified = await Get.toNamed('/kyc', arguments: {
                        'context': 'renter_kyc',
                        'isHost': false,
                        'returnResult': true,
                      });
                      if (verified != true &&
                          authController.userData.value?.isKycVerified != true) {
                        bookingController.showSnackbar(
                          'Verification required',
                          'Please verify your identity to continue booking.',
                          true,
                        );
                        return;
                      }
                    }
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
                      // Razorpay prefill accepts empty strings — defensive
                      // fallback for dev-skip / session-expired flows.
                      final contact =
                          authController.userData.value?.phoneNumber ?? '';
                      final email =
                          authController.userData.value?.email ?? '';
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
                    final token = await const FlutterSecureStorage()
                        .read(key: "user_token");
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
                    // Guard against null userData (e.g. dev-skip flow) —
                    // negotiation requires a real user id; surface a friendly
                    // toast instead of crashing with a null check.
                    final currentUserId =
                        authController.userData.value?.userId;
                    if (currentUserId == null) {
                      Fluttertoast.showToast(
                        msg:
                            "Please login with a real account to negotiate price",
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
                          userId: currentUserId.toString(),
                          propertyId: widget.id.toString(),
                          serverUrl: Apiconstants
                              .serverUrl, //"https://aajaodev.onrender.com",
                          receiverId: widget.property.propertyHostId.toString(),
                          token: token,
                          lat: widget.lat,
                          senderId: currentUserId.toString(),
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

  @override
  void dispose() {
    _animationController.dispose();
    _priceController.dispose();
    _couponController.dispose();
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
                automaticallyImplyLeading: false,
                backgroundColor: kCream,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      _higlightedPropertyImageHeaderSection(theme),
                      // M6-01 — floating header overlay
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 12,
                        left: 16,
                        right: 16,
                        child: Row(
                          children: [
                            backFromScreen(context),
                            const Spacer(),
                            sharePropertyIcon(),
                            const SizedBox(width: 8),
                            savedIcon(context, theme),
                          ],
                        ),
                      ),
                      // New-design hero rating badge (bottom-left, deep teal).
                      Positioned(
                        left: 16,
                        bottom: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                              color: kIndigo600,
                              borderRadius: BorderRadius.circular(10)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.star,
                                size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(widget.rating,
                                style: inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // M6-02 — title (em-dash splits into italic subtitle)
                      _buildPropertyTitle(widget.name),
                      const SizedBox(height: 10),
                      // Location row
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 18,
                            color: kMuted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.location,
                              style: inter(
                                fontSize: 13,
                                color: kMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // M6-02 — meta row: VerifiedPill + inline rating
                      // (POC has no pill chrome around the rating — plain
                      // "★ 4.92 · 164 reviews" sits beside the verified pill).
                      Row(
                        children: [
                          const VerifiedPill(),
                          const SizedBox(width: 12),
                          const Icon(Icons.star, size: 14, color: kClay),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.rating} · 164',
                            style: inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: kInk,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // M7-01 — host card under the meta row
                      const HostCard(hostName: 'Aajoo Host'),
                      const SizedBox(height: 16),
                      // M7-02 — amenity preview row. Show REAL amenities only;
                      // no fake defaults (the full Amenities section is below).
                      if (widget.property.amenities != null &&
                          widget.property.amenities!.isNotEmpty) ...[
                        AmenityRow(
                          amenities:
                              widget.property.amenities!.take(4).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                      const Divider(color: kLine, height: 1),
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
            // M8 — sticky book bar is flush to the bottom edge; expanded
            // booking sheet still grows upward from here.
            bottom: 0,
            left: 0,
            right: 0,
            child: Obx(() {
              if (bookingController.isLoading.value) {
                return Container(
                  color: kCream,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: kIndigo,
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

  // M6-01 — floating 40×40 cream-90% circle button used in the header overlay.
  Widget _floatingHeaderButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? iconColor,
    String? tooltip,
  }) {
    final btn = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: kCream.withOpacity(0.92),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: kInk.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Icon(icon, size: 20, color: iconColor ?? kInk),
        ),
      ),
    );
    if (tooltip != null) return Tooltip(message: tooltip, child: btn);
    return btn;
  }

  // M6-02 — Fraunces title with em-dash subtitle split (italic em).
  Widget _buildPropertyTitle(String name) {
    final emDashIdx = name.indexOf('—');
    final hyphenIdx = emDashIdx == -1 ? name.indexOf(' - ') : -1;
    final splitIdx = emDashIdx != -1 ? emDashIdx : hyphenIdx;
    final headStyle = fraunces(
      fontSize: 30,
      fontWeight: FontWeight.w500,
      color: kInk,
      height: 1.15,
    );
    if (splitIdx == -1) {
      return Text(name, style: headStyle);
    }
    final head = name.substring(0, splitIdx).trim();
    final tail = name
        .substring(emDashIdx != -1 ? splitIdx + 1 : splitIdx + 3)
        .trim();
    return RichText(
      text: TextSpan(
        style: headStyle,
        children: [
          TextSpan(text: head),
          TextSpan(
            text: '  —  $tail',
            style: fraunces(
              fontSize: 30,
              fontWeight: FontWeight.w400,
              color: kInk2,
              fontStyle: FontStyle.italic,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }

  Widget backFromScreen(BuildContext context) {
    return _floatingHeaderButton(
      icon: Icons.arrow_back_ios_new,
      onPressed: () => Navigator.pop(context),
      tooltip: 'Back',
    );
  }

  Widget sharePropertyIcon() {
    return _floatingHeaderButton(
      icon: Icons.ios_share,
      tooltip: 'Share',
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
    );
  }

  void _showBookmarkSnackBar({
    required BuildContext context,
    required ThemeData theme,
    required String message,
    required bool isAdded,
  }) {
    final messenger = ScaffoldMessenger.of(context);

    final Color accentColor = isAdded ? theme.primaryColor : Colors.redAccent;

    final IconData statusIcon =
        isAdded ? Icons.bookmark_added : Icons.bookmark_remove;

    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 3),
        content: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row
              Row(
                children: [
                  // Status icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      statusIcon,
                      size: 20,
                      color: accentColor,
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Message
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  // Close
                  // InkWell(
                  //   onTap: messenger.hideCurrentSnackBar,
                  //   borderRadius: BorderRadius.circular(20),
                  //   child: const Padding(
                  //     padding: EdgeInsets.all(6),
                  //     child: Icon(Icons.close, size: 18, color: Colors.black54),
                  //   ),
                  // ),
                ],
              ),

              const SizedBox(height: 10),

              // Action row
              Row(
                children: [
                  const Spacer(),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      foregroundColor: accentColor,
                    ),
                    onPressed: () {
                      messenger.hideCurrentSnackBar();
                      Get.to(() => const BookmarkedPropertiesPage());
                    },
                    child: const Text(
                      'VIEW BOOKMARKS',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget savedIcon(BuildContext context, ThemeData theme) {
    return _floatingHeaderButton(
      icon: _isBookmarked ? Icons.favorite : Icons.favorite_outline,
      iconColor: _isBookmarked ? kClay : kInk,
      tooltip: _isBookmarked ? 'Remove bookmark' : 'Save',
      onPressed: () async {
        final bookmarkService = BookmarkService();
        final wasBookmarked = _isBookmarked;

        // Optimistic UI flip so the heart feels instant — revert on failure.
        setState(() => _isBookmarked = !wasBookmarked);

        final ok = await bookmarkService.toggleBookmark(widget.property);

        if (!ok) {
          // Server rejected → revert and tell the user.
          if (mounted) setState(() => _isBookmarked = wasBookmarked);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not update bookmark. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        if (context.mounted) {
          _showBookmarkSnackBar(
            context: context,
            theme: theme,
            message: wasBookmarked
                ? '${widget.name} removed from bookmarks'
                : '${widget.name} added to bookmarks',
            isAdded: !wasBookmarked,
          );
        }
      },
    );
  }

  Stack _higlightedPropertyImageHeaderSection(ThemeData theme) {
    return Stack(
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
                  autoPlayAnimationDuration: const Duration(milliseconds: 800),
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
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(Icons.error, color: Colors.red),
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
                      autoPlayInterval: const Duration(seconds: 2),
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
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) => const Center(
                              child: Icon(Icons.error, color: Colors.red),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Obx(
                      () => propertyController.isLoading.value
                          ? const Text("0.0")
                          : propertyController.propertyReviewResponse.value
                                      .data!.averageRating
                                      .toString() ==
                                  "null"
                              ? Text(
                                  "4.2",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  propertyController.propertyReviewResponse
                                      .value.data!.averageRating
                                      .toString(),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
      barrierDismissible: false,
      builder: (_) => BookingSuccessDialog(
        paymentId: paymentId,
        bookingId: bookingId,
        lat: widget.lat,
        long: widget.long,
      ),
    );

    //  showDialog(
    //   context: context,
    //   builder: (context) {
    //     return AlertDialog(
    //       title: Image.asset("assets/success.image.png", height: 200),
    //       content: Column(
    //         mainAxisSize: MainAxisSize.min,
    //         children: [
    //           const Text(
    //             "Booking Successful",
    //             style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    //           ),
    //           const SizedBox(height: 16),
    //           Text("Booking Id: $bookingId"),
    //           const SizedBox(height: 16),
    //           Text("Payment Id: $paymentId"),
    //         ],
    //       ),
    //       actions: [
    //         TextButton(
    //           onPressed: () {
    //             Navigator.pushAndRemoveUntil(
    //               context,
    //               CupertinoPageRoute(builder: (context) => const Homescreen()),
    //               (route) => false,
    //             );
    //           },
    //           child: const Text("Close"),
    //         ),
    //         ElevatedButton(
    //           onPressed: () async {
    //             final lat = double.parse(widget.lat);
    //             final long = double.parse(widget.long);
    //             if (Platform.isAndroid) {
    //               DeviceService.launchGoogleMaps(lat, long);
    //             }
    //             DeviceService.showMapOptions(context, lat, long);
    //           },
    //           child: const Text("Get Directions"),
    //           style: ElevatedButton.styleFrom(
    //             backgroundColor: kprimaryColor,
    //             minimumSize: const Size(100, 50),
    //             foregroundColor: Colors.white,
    //             shape: RoundedRectangleBorder(
    //               borderRadius: BorderRadius.circular(12),
    //             ),
    //           ),
    //         ),
    //       ],
    //     );
    //   },
    // );
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final result = await bookingController.verifyPayment(
      response.orderId!,
      response.paymentId!,
      response.signature!,
    );
    if (result) {
      Fluttertoast.showToast(msg: "Payment Successful: ${response.paymentId}");
      final bookingId =
          bookingController.bookingResponse.value?.data.booking.bookId;
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
