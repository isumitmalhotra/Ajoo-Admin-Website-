import 'package:rent_home/service/pending_booking.dart';
import 'package:rent_home/ui/screens_renter/property_details/components/booking_confirmed_screen.dart';
import 'package:rent_home/ui/screens_renter/property_details/components/property_tabs.dart';
import 'package:rent_home/ui/screens_renter/blog/blog_screens.dart';
import 'package:rent_home/ui/screens_renter/home/components/home_blog_strip.dart';
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
import 'package:rent_home/utils/booking_pricing.dart';
import 'package:rent_home/ui/screens_common/auth/auth_controller.dart';
import 'package:rent_home/ui/screens_renter/booking_controller.dart';
import 'package:rent_home/controller/common_controller.dart';
import 'package:rent_home/data/ApiConstants.dart';
import 'package:rent_home/ui/screens_host/add_property/new_property_controller_legacy.dart';
import 'package:rent_home/controller/user_controller.dart';
import 'package:rent_home/data/models/properties_response_model.dart';
import 'package:rent_home/data/models/single_property_response.dart';
import 'package:rent_home/models/host_profile.dart';
import 'package:rent_home/ui/screens_renter/history/history_description/review/all_reviews_list/view_property_all_reviews_page.dart';
import 'package:rent_home/service/bookmark_service.dart';
import 'package:rent_home/service/property_service.dart';
import 'package:rent_home/service/booking_service.dart';
import 'package:rent_home/service/deals_service.dart';
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
  /// How the guest describes the stay. A label only — see _updatePriceString.
  /// "Weekly" is gone; the spec asks for per-night and monthly.
  String bookingType = 'Per night';
  static const List<String> _stayTypes = ['Per night', 'Monthly'];

  // Prebooking mode: if negotiation button is hidden, this page is opened from prebooking
  bool get isPrebooking => !widget.showNegotiationButton;

  // Single property fetch
  final PropertyService _propertyService = PropertyService();
  SinglePropertyData? _single;
  HostProfile? _host;

  /// Prefer the detail payload's aggregate; fall back to whatever the list
  /// already gave us so the rating does not flicker in on load.
  double? get _rating => _single?.rating ?? widget.property.rating;
  int get _reviewCount => _single?.reviewCount ?? widget.property.reviewCount;


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
    _fetchSingleProperty().then((_) => _fetchHost());
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

  /// The reduction to show against the room total. Both fields were being
  /// written and never read, so the app validated a coupon, said "Applied —
  /// 10% off" in the coupon box, and then quoted a price with nothing taken
  /// off — while the backend went ahead and applied it. The quote was wrong in
  /// the guest's favour, which is still wrong.
  ///
  /// `_couponDiscount` is the amount the server itself computed, so it wins.
  /// A deal arriving via `widget.dealPercent` only carries a percentage, hence
  /// the fallback.
  double get _discountOnRoom {
    if (_appliedCoupon == null || _appliedCoupon!.isEmpty) return 0;
    if (_couponDiscount > 0) return _couponDiscount;
    final base = double.tryParse(currentPriceString) ?? 0;
    return _couponPercent > 0 ? base * _couponPercent / 100 : 0;
  }

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

  /// Who actually hosts this place.
  ///
  /// The property payload has no host name — only an id — so the page used to
  /// print the literal string "Aajoo Host" for every listing, and below it the
  /// property's phone number styled as if it were the host's name. This is the
  /// same endpoint the web's property detail has always used.
  Future<void> _fetchHost() async {
    final hostId = _single?.propertyHostId ?? widget.property.propertyHostId;
    if (hostId == 0) return;
    final host = await _propertyService.getHostProfile(hostId);
    if (!mounted || host == null) return;
    setState(() => _host = host);
  }

  Future<void> _checkBookmarkStatus() async {
    final bookmarkService = BookmarkService();
    _isBookmarked =
        await bookmarkService.isBookmarked(widget.property.propertyId);
    setState(() {});
  }

  /// The stay total: the host's nightly rate times the nights actually picked.
  ///
  /// This used to branch on the stay type, and it was charging people for
  /// nights they had not booked. "Monthly" did `rate * 30 * ceil(days/30)`, so
  /// a two-night stay priced at thirty nights; "Weekly" did the same at seven.
  /// The figure fed `price` on the booking, so the guest was charged it.
  ///
  /// The stay type was never anything but a label: `bookingType` is not
  /// declared in the backend's createBooking schema, and validation runs with
  /// stripUnknown, so the server has never once received it. It now labels the
  /// stay and nothing else — the dates and the host's rate set the price.
  void _updatePriceString() {
    final totalPrice = currentPrice * totalDays;
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
              color: Color(0x140F172A),
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
              // "Negotiate & Reserve" — the sheet it opens offers both, and
              // negotiating is the thing that makes this platform different.
              child: Text(widget.showNegotiationButton
                  ? 'Negotiate & Reserve'
                  : 'Reserve'),
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
                  items: _stayTypes
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  // No _updatePriceString here on purpose: picking "Monthly"
                  // must not move the price. The dates and the host's rate do
                  // that, and this used to multiply the total by thirty.
                  onChanged: (String? newValue) {
                    setState(() => bookingType = newValue!);
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
                      // Nights, not calendar days. This was `.inDays + 1`,
                      // which billed a 12th-to-13th stay as two nights — one
                      // more than the guest is there. The negotiated-deal path
                      // in this same file, and the website, have always used
                      // the plain difference, so picking your own dates cost a
                      // night more than arriving on the identical dates from
                      // an accepted offer.
                      totalDays =
                          selectedDateTo!.difference(selectedDate).inDays;
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
                      // Nights, not calendar days. This was `.inDays + 1`,
                      // which billed a 12th-to-13th stay as two nights — one
                      // more than the guest is there. The negotiated-deal path
                      // in this same file, and the website, have always used
                      // the plain difference, so picking your own dates cost a
                      // night more than arriving on the identical dates from
                      // an accepted offer.
                      totalDays =
                          selectedDateTo!.difference(selectedDate).inDays;
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
              // Set by the host and not negotiable, so no chevron: the two
              // rows above it use the same arrow to open a date picker, and
              // this one opened nothing. It looked broken rather than fixed.
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Check-in/Check-out Time'),
                subtitle: Text(
                  "${_single?.propDetails?.inTime ?? widget.inTime ?? "12:00PM"} / ${_single?.propDetails?.outTime ?? widget.outTime ?? "12:00PM"} · set by the host",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                                Text("Nights: $totalDays",
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
                                // One pricing rule, shared with the breakdown
                                // below and the submit handler. The band comes
                                // from the nightly tariff, not the stay total.
                                final p = priceStay(
                                  roomSubtotal:
                                      double.parse(currentPriceString),
                                  perNightTariff: currentPrice,
                                  discount: _discountOnRoom,
                                );

                                return Text(
                                  '₹${p.total.toStringAsFixed(0)}',
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
                            final p = priceStay(
                              roomSubtotal: double.parse(currentPriceString),
                              perNightTariff: currentPrice,
                              discount: _discountOnRoom,
                            );

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
                                      '₹${p.roomSubtotal.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                                if (p.discount > 0) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _couponPercent > 0
                                            ? 'Discount ($_couponPercent% — $_appliedCoupon)'
                                            : 'Discount ($_appliedCoupon)',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.green,
                                        ),
                                      ),
                                      Text(
                                        '− ₹${p.discount.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'GST (${p.taxPct}%)',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    Text(
                                      '₹${p.taxes.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                                // The "Platform Fee ₹10" row that used to sit
                                // here was never charged by anything — not the
                                // backend, not the web. Showing a fee nobody
                                // collects is worse than showing no fee.
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
                                      '₹${p.total.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: kIndigo,
                                      ),
                                    ),
                                  ],
                                ),
                                // "Weekly Min Price" and "Weekly Max Price"
                                // used to print below the total. Those are the
                                // host's own pricing band — the floor and
                                // ceiling they will negotiate between — and
                                // showing a guest the minimum the host would
                                // accept, right under what they are being
                                // asked to pay, gives away the host's position
                                // in a negotiation this platform is built on.
                                // The guest sees the price for their dates and
                                // nothing else.
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
                                        '₹${(p.total * 0.10).toStringAsFixed(0)}',
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
                                        '₹${(p.total * 0.90).toStringAsFixed(0)}',
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
                    final p = priceStay(
                      roomSubtotal: double.parse(currentPriceString),
                      perNightTariff: currentPrice,
                      discount: _discountOnRoom,
                    );
                    final double finalAmount =
                        double.parse(p.total.toStringAsFixed(0));
                    final double advanceAmount =
                        double.parse((p.total * 0.10).toStringAsFixed(0));

                    // If prebooking, disable COD and charge only 10% now
                    if (isPrebooking) {
                      isCod = false;
                    }

                    final bookingData = {
                      "propertyId": widget.id,
                      // `price` is the PRE-TAX room subtotal. The backend adds
                      // GST itself (calculateBookingtax) and stores the result
                      // as book_total_amt, so sending the taxed total made it
                      // tax the tax — the guest on B618787 was quoted ₹23,020
                      // and the row said ₹24,171. The coupon branch below has
                      // always sent the subtotal; this makes every booking do
                      // what that branch already did.
                      //
                      // Prebooking is left on its old footing on purpose. It
                      // charges a 10% deposit, but the backend has no notion of
                      // one: it reads `price` as the room subtotal whatever we
                      // send. Sending the subtotal here would charge a deposit
                      // guest the full stay; sending the deposit records the
                      // room as costing 10% of its real price, which is what it
                      // does today. Neither is right, and choosing between them
                      // is not a bugfix — it needs an `advanceAmount` the
                      // backend actually understands. Until then this path
                      // keeps its existing behaviour rather than silently
                      // changing what a guest is charged.
                      "price": isPrebooking ? advanceAmount : p.roomSubtotal,
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
                    // entered): the backend applies the discount to the subtotal
                    // and adds GST, and consumes/validates the coupon.
                    if (_appliedCoupon != null && _appliedCoupon!.isNotEmpty) {
                      bookingData["couponCode"] = _appliedCoupon!;
                    }
                    // KYC gate — renters are verified at registration; this
                    // catches anyone who skipped. An unverified guest must
                    // complete DIDIT before booking, then returns here to retry.
                    if (authController.userData.value?.isKycVerified != true) {
                      // Remember the booking before handing control away.
                      // DIDIT opens in the system browser, and Android is free
                      // to destroy this activity while the guest is over
                      // there — they come back to a fresh app with an empty
                      // navigation stack and their dates gone. The home screen
                      // offers to resume from this.
                      await PendingBookingStore.save(PendingBooking(
                        propertyId: widget.id,
                        propertyName: _single?.propertyName ?? widget.name,
                        bookFrom: formattedDate,
                        bookTo: formattedDateTo,
                        couponCode: _appliedCoupon,
                        isCod: isCod,
                        savedAt: DateTime.now(),
                      ));
                      final verified = await Get.toNamed('/kyc', arguments: {
                        'context': 'renter_kyc',
                        'isHost': false,
                        'returnResult': true,
                      });
                      if (verified != true &&
                          authController.userData.value?.isKycVerified != true) {
                        // Say which of the three things actually happened. This
                        // was one flat "Verification required" for all of them,
                        // including the case where the guest HAD just completed
                        // KYC and was waiting on review — which reads as though
                        // the app ignored what they had just done.
                        //
                        // Their dates, guests and coupon are still on this
                        // screen; nothing is lost by staying here.
                        final st = (authController
                                    .userData.value?.verificationStatus ??
                                '')
                            .toLowerCase();
                        final inReview =
                            st == 'in_review' || st == 'pending' || st == 'partial';
                        bookingController.showSnackbar(
                          inReview ? 'Still reviewing your ID' : 'Verification required',
                          inReview
                              ? "We're checking your ID now. Your dates are saved — "
                                  "come back to finish once it's approved."
                              : 'Please verify your identity to continue booking.',
                          true,
                        );
                        return;
                      }
                    }
                    final bookingResponse =
                        await bookingController.createBooking(bookingData);
                    // The booking exists; nothing left to resume.
                    await PendingBookingStore.clear();
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
                        // Take the amount from the order the backend just
                        // created (paise, as Razorpay returns it) rather than
                        // recomputing it here. When an order_id is supplied
                        // Razorpay charges the ORDER's amount regardless of
                        // what this field says, so a locally-computed figure
                        // could only ever disagree with what is really taken —
                        // which is how a guest came to be shown one number and
                        // charged another.
                        "amount": bookingResponse.data.booking.order?.amount ??
                            (finalAmount * 100).toInt(),
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
                  child: const Text('Negotiate'),
                ),
              ),
            ],
          ),
        ),
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
                      // Hero rating badge — only when the stay has a real
                      // rating. It printed widget.rating, which callers pass
                      // as the constant "4.5", so every listing wore a score
                      // nobody had given it. The meta row below was fixed
                      // earlier; this second copy was missed.
                      if (_rating != null)
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
                            Text(_rating!.toStringAsFixed(1),
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
                      // Specs row (real data from GET /properties/:id).
                      if (_single != null &&
                          (_single!.propDetails?.noOfGuests != null ||
                              _single!.propDetails?.noOfBeds != null ||
                              _single!.bathrooms != null)) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            if (_single!.propDetails?.noOfGuests != null)
                              _SpecChip(Icons.group_outlined,
                                  '${_single!.propDetails!.noOfGuests} Guests'),
                            if (_single!.propDetails?.noOfBeds != null)
                              _SpecChip(Icons.bed_outlined,
                                  '${_single!.propDetails!.noOfBeds} ${_single!.propDetails!.noOfBeds == 1 ? "Bed" : "Beds"}'),
                            if (_single!.bathrooms != null)
                              _SpecChip(Icons.bathtub_outlined,
                                  '${_single!.bathrooms} ${_single!.bathrooms == 1 ? "Bath" : "Baths"}'),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),
                      // M6-02 — meta row: VerifiedPill + inline rating
                      // (POC has no pill chrome around the rating — plain
                      // "★ 4.92 · 164 reviews" sits beside the verified pill).
                      // Real average and review count. This read
                      // "${widget.rating} · 164" — a rating passed in as the
                      // constant "4.5" and a review count that was literally
                      // the number 164 typed into the layout.
                      Row(
                        children: [
                          // A-27 — driven by verification_status. This read
                          // isVerify, which is 1 on 29,229 of the 29,232 live
                          // listings, so the pill appeared on every stay
                          // nobody had reviewed.
                          if (_single?.isVerified == true) ...[
                            const VerifiedPill(),
                            const SizedBox(width: 12),
                          ],
                          if (_rating != null) ...[
                            const Icon(Icons.star, size: 14, color: kClay),
                            const SizedBox(width: 4),
                            Text(
                              '${_rating!.toStringAsFixed(1)} · '
                              '$_reviewCount review${_reviewCount == 1 ? '' : 's'}',
                              style: inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: kInk,
                              ),
                            ),
                          ] else
                            Text(
                              'New listing',
                              style: inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: kMuted,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // "Aajoo Verified Home" trust card — only for listings
                      // admin has actually verified. Gating this on isVerify
                      // was no gate at all (see above): the card claiming a
                      // listing was checked for quality, safety and hygiene
                      // showed on all 29,219 that had not been.
                      if (_single?.isVerified == true)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: kIndigo50,
                            borderRadius: BorderRadius.circular(14)),
                        child: Row(children: [
                          const Icon(Icons.verified_user_outlined,
                              size: 24, color: kIndigo600),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Aajoo Verified Home',
                                    style: fraunces(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: kInk)),
                                Text('Verified for quality, safety and hygiene.',
                                    style:
                                        inter(fontSize: 11.5, color: kMuted)),
                              ],
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 18),
                      // M7-01 — host card under the meta row
                      HostCard(
                        hostName: _host?.name ?? 'your host',
                        photoUrl: _host?.image,
                        tagline: _host?.subtitle ?? 'Verified Aajoo host',
                      ),
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
                      const SizedBox(height: 12),
                      // A-29/A-30/A-31 — the seven sections as tabs, matching
                      // the website. Everything below this used to render at
                      // once down one very long scroll.
                      PropertyDetailPanels(
                        single: _single,
                        host: _host,
                        reviewCount: _reviewCount,
                        experiencesBuilder: _buildReviews,
                        fallback: PropertyPanelFallback(
                          description: widget.description,
                          location: widget.location,
                          amenities: widget.property.amenities,
                          latitude: widget.property.propertyLatitude,
                          longitude: widget.property.propertyLongitude,
                          contact: widget.property.propertyContact,
                          petFriendly:
                              widget.property.propDetailsPropDetailIsPetFriendly,
                          smoking: widget.property.propDetailsPropDetailIsSmoke,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // A-33 — the gallery sits below the panels, so it is
                      // reachable whichever section is open.
                      Text(
                        "Gallery",
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildImageGallery(),
                      const SizedBox(height: 24),
                      // A-36 — the blog, from the property page.
                      HomeBlogStrip(
                        max: 3,
                        title: 'From the blog',
                        onSeeAll: () => Get.to(() => const BlogListScreen()),
                        onOpen: (post) => Get.to(() => BlogPostScreen(post: post)),
                      ),
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
      // A "Confirm Booking" FAB used to live here, gated on `priceConfirmed` —
      // a field set to false at declaration and never assigned anywhere. It
      // could never appear, and its handler was empty, so the day someone set
      // that flag it would have shipped a booking button that does nothing.
      // Booking is confirmed from the bottom sheet below.
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

  /// Booking confirmed.
  ///
  /// Pushes a route rather than showing a dialog. The dialog needed this
  /// page's BuildContext to still be mounted when Razorpay handed control
  /// back, which is why the confirmation could fail to appear on a card
  /// payment — "booking confirm page is missing in real time booking". A route
  /// does not depend on that, and it has room for the map.
  void successDialog(String paymentId, String bookingId) {
    Get.to(() => BookingConfirmedScreen(
          bookingId: bookingId,
          paymentId: paymentId,
          propertyName: _single?.propertyName ?? widget.name,
          address: _single?.propertyAddress ?? widget.location,
          // Prefer the detail payload's coordinates: widget.lat/long are
          // passed in as strings by every caller and are empty on some of
          // them, which is how Get Directions ended up launching Maps at 0,0.
          lat: double.tryParse(_single?.propertyLatitude ?? widget.lat),
          lng: double.tryParse(_single?.propertyLongitude ?? widget.long),
          checkIn: _fmtStayDate(selectedDate),
          checkOut: selectedDateTo == null ? null : _fmtStayDate(selectedDateTo!),
          amount: '₹$currentPriceString',
          isPayOnArrival: isCod,
        ));
  }

  String _fmtStayDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

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

/// Spec chip (guests/beds/baths) on Property Details — icon + label, equal width.
class _SpecChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SpecChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: kIndigo600),
          const SizedBox(height: 5),
          Text(label,
              textAlign: TextAlign.center,
              style: inter(
                  fontSize: 12, fontWeight: FontWeight.w600, color: kInk2)),
        ],
      ),
    );
  }
}
