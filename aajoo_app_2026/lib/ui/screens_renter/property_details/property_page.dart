import 'dart:async';
import 'package:rent_home/ui/screens_renter/home/map/map_controller.dart';
import 'package:rent_home/service/pending_booking.dart';
import 'package:rent_home/ui/screens_renter/property_details/components/booking_confirmed_screen.dart';
import 'package:rent_home/ui/screens_renter/property_details/components/property_tabs.dart';
import 'package:rent_home/ui/screens_renter/blog/blog_screens.dart';
import 'package:rent_home/ui/screens_renter/home/components/home_blog_strip.dart';
import 'package:rent_home/ui/screens_renter/property_details/widgets/traveller_picker.dart';
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
import 'package:rent_home/ui/screens_renter/property_details/widgets/send_offer_sheet.dart';
import 'package:rent_home/utils/nightly_rates.dart';
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
import 'package:rent_home/utils/money.dart';
import 'package:rent_home/utils/rzp_error.dart';
import 'package:rent_home/widgets/amenity_row.dart';
import 'package:rent_home/widgets/host_card.dart';
import 'package:rent_home/widgets/verified_pill.dart';
import 'package:share_plus/share_plus.dart';
import 'package:rent_home/utils/input_sanitizers.dart';
import 'package:rent_home/models/property_offer.dart';
import 'package:rent_home/models/pet_policy.dart';

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
  final double? dealPercent;

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

  /// How many people the stay is for.
  ///
  /// The app never asked, and never sent `no_of_guests`, so every booking made
  /// from the phone stored NULL and no host could see how many were coming —
  /// and a listing that charges beyond an included headcount could not bill it.
  int _guests = 1;

  /// The ceiling the host set, plus any extras they are willing to charge for.
  ///
  /// On the live data a listing can have capacity 8 and "guests included" 8
  /// while allowing 2 more at a price. Stopping at 8 would put those two out of
  /// reach and the charge with them, so the stepper reaches what the host is
  /// actually prepared to take.
  int? get _guestCeiling {
    // The wizard's capacity record first, the legacy table second — the same
    // order the spec row and the web use. Reading only propDetails left a
    // wizard listing with no stated ceiling at all, so the stepper ran away
    // to any number the guest cared to tap while the host had plainly said
    // how many the place sleeps.
    final stated = _single?.capacity?.totalGuests ?? _single?.propDetails?.noOfGuests;
    final base = (stated != null && stated > 0) ? stated : null;
    final rule = _single?.pricing;
    if (rule != null && rule.chargeExtraGuests && rule.maxExtraGuests > 0) {
      final included = rule.guestsIncluded > 0 ? rule.guestsIncluded : (base ?? 0);
      final withExtras = included + rule.maxExtraGuests;
      return withExtras > (base ?? 0) ? withExtras : base;
    }
    return base;
  }

  /// What this party adds, per extra guest per night. Mirrors the web and the
  /// server; the server recomputes it and refuses a price that disagrees.
  double get _partyFee =>
      _single?.pricing?.extraGuestFee(_guests, totalDays) ?? 0;

  /// How many pets are coming.
  ///
  /// Counted apart from guests because they do not occupy beds — the same
  /// reason infants are excluded from the guest total. Shown only where this
  /// host takes pets, and capped at the number they said they would take.
  int _pets = 0;

  PetPolicy get _petPolicy => _single?.pets ?? PetPolicy.none;

  /// What the pets add, per pet per night. The server recomputes this and
  /// refuses a price that disagrees, exactly as it does for the party fee.
  double get _petFee => _petPolicy.feeFor(_pets, totalDays);
  int totalDays = 1;

  /// The Razorpay options last opened, so a refusal can offer "Try again".
  Map<String, dynamic>? _lastPaymentOptions;

  /// Midnight of the same calendar day.
  ///
  /// `selectedDate` starts life as DateTime.now(), so it carries the wall-clock
  /// time the guest opened the page. Differencing that against a picker date
  /// (always midnight) and calling .inDays TRUNCATES the leftover hours: a
  /// 19th→22nd stay booked at 03:25 measured 2 days 20h and billed 2 nights
  /// for 3 nights of occupancy. Normalising both ends makes the count depend
  /// on the dates alone, which is the only thing it should depend on.
  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  static int _nightsBetween(DateTime from, DateTime to) =>
      _dayOnly(to).difference(_dayOnly(from)).inDays;
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
  // Wallet (audit C-9): referral credit the guest can put toward this stay.
  // Balance loads best-effort (0 on any failure = the row never renders);
  // the toggle defaults ON because it is the guest's own money and the split
  // is shown before they pay. Server recomputes the split from the balance
  // it holds — these numbers are display only.
  double _walletBalance = 0;
  bool _useWallet = true;
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

  /// Guests · Bedrooms · Beds · Baths, from whichever source recorded them.
  ///
  /// Wizard listings carry property_capacity; listings from the retired
  /// add-property form carry tbl_property_details, and `bathrooms` lives on the
  /// property row for both. A figure nobody recorded is omitted rather than
  /// shown as zero — "0 bedrooms" is a claim about the stay, "nothing" is not.
  List<Widget> get _specs {
    final cap = _single?.capacity;
    final legacy = _single?.propDetails;

    int? positive(int? v) => (v != null && v > 0) ? v : null;

    final guests = positive(cap?.totalGuests) ?? positive(legacy?.noOfGuests);
    final bedrooms = positive(cap?.bedrooms);
    final beds = positive(cap?.beds) ?? positive(legacy?.noOfBeds);
    final baths = positive(cap?.bathrooms) ?? positive(_single?.bathrooms);

    return [
      if (guests != null)
        _SpecChip(Icons.group_outlined,
            '$guests ${guests == 1 ? "Guest" : "Guests"}'),
      if (bedrooms != null)
        _SpecChip(Icons.meeting_room_outlined,
            '$bedrooms ${bedrooms == 1 ? "Bedroom" : "Bedrooms"}'),
      if (beds != null)
        _SpecChip(Icons.bed_outlined, '$beds ${beds == 1 ? "Bed" : "Beds"}'),
      if (baths != null)
        _SpecChip(Icons.bathtub_outlined,
            '$baths ${baths == 1 ? "Bath" : "Baths"}'),
    ];
  }
  int get _reviewCount => _single?.reviewCount ?? widget.property.reviewCount;

  /// What this stay actually is, for the pill over the hero image. Null when
  /// the listing carries no category — the pill then renders nothing rather
  /// than the literal "Apartment" it used to print on every property.
  ///
  /// `_single.categories` is a List<dynamic> whose entries are maps like
  /// `{cat_id: 5, cat_title: Apartments, cat_slug: apartments}`, so a bare
  /// toString() prints the whole record. The Property fallback holds plain
  /// title strings. Both shapes are handled here.
  String? get _heroCategory {
    String? titleOf(dynamic c) {
      if (c == null) return null;
      if (c is Map) {
        final t = (c['cat_title'] ?? c['title'] ?? '').toString().trim();
        return t.isEmpty ? null : t;
      }
      final s = c.toString().trim();
      return s.isEmpty ? null : s;
    }

    for (final source in [_single?.categories, widget.property.categoryTitles]) {
      if (source == null) continue;
      for (final c in source) {
        final t = titleOf(c);
        if (t != null) return t;
      }
    }
    return null;
  }


  /// Owns this page's scroll, with `keepScrollOffset: false`.
  ///
  /// A Scrollable with no controller stores its offset in PageStorage, keyed
  /// by its position in the widget tree — and every property page has the
  /// same shape, so the bucket is shared. Open a stay, scroll down to the
  /// house rules, go back, open a different stay: the new page restored the
  /// old page's offset and landed you halfway down a listing you had never
  /// seen, past the photographs and the price. Its own controller, told not
  /// to keep the offset, means a stay always opens where it starts.
  /// Set when Book Now was pressed with no check-out date, so the date row
  /// can show itself as the thing standing in the way. Cleared once one is
  /// chosen.
  bool _needsCheckout = false;

  final ScrollController _pageScroll =
      ScrollController(keepScrollOffset: false);

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
    // Wallet balance for the booking sheet — fire and forget.
    BookingService().getWalletBalance().then((b) {
      if (mounted) setState(() => _walletBalance = b);
    });
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
          ? 'Negotiated deal — ${_pct(widget.dealPercent!)}% off'
          : 'Negotiated deal applied';
    }

    // Grey out already-booked nights in the date picker.
    _loadAvailability();

    // Fetch full property details
    _fetchSingleProperty().then((_) => _fetchHost());
  }

  /// A host-set check-in or check-out time, or a sensible default.
  ///
  /// Treats the literal strings "null" and "" as absent: the callers stringify
  /// nullable fields, so absence arrives here as text rather than as null.
  static String _stayTime(String? detail, dynamic fallback) {
    for (final v in [detail, fallback?.toString()]) {
      final t = (v ?? '').trim();
      if (t.isNotEmpty && t.toLowerCase() != 'null') return t;
    }
    return '12:00PM';
  }

  /// DD/MM/YYYY, zero-padded — the field labels promise that shape and the
  /// raw parts gave "24/8/2026" next to a label reading "Book To (DD/MM/YYYY)".
  static String _dmy(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

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

    var from = parse(widget.dealFrom);
    var to = parse(widget.dealTo);

    // What the guest already told the search sheet. "When" and "Who" used to
    // be collected there and dropped — opening a stay asked both again.
    final searched = Get.isRegistered<MapController>()
        ? Get.find<MapController>()
        : null;

    // The party size is independent of where the dates came from: a resumed
    // booking arrives with deal dates AND a remembered party, so reading the
    // guests only when dates were missing silently shrank the party to one.
    final g = searched?.stayGuests.value ?? 0;
    if (g > 0) _guests = g;

    // No deal? Fall back to the dates the guest searched for. A deal still
    // wins, because those are the nights the price was agreed for.
    if (searched != null) {
      from ??= parse(searched.stayFrom.value);
      to ??= parse(searched.stayTo.value);
    }

    if (from != null && to != null && to.isAfter(from)) {
      selectedDate = from;
      selectedDateTo = to;
      totalDays = _nightsBetween(from, to);
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
    if (!mounted) return;
    setState(() {
      _bookedRanges = ranges;
      // A deal prefill (_applyDealDates) lands before this response and enables
      // Book with no availability check at all — the dates were agreed days ago
      // and the host may have blocked or sold them since. Re-check the moment
      // the truth arrives rather than letting the server refuse at payment.
      final from = selectedDate, to = selectedDateTo;
      if (to != null) {
        for (var d = DateTime(from.year, from.month, from.day);
            d.isBefore(to);
            d = DateTime(d.year, d.month, d.day + 1)) {
          if (_isBookedDay(d)) {
            selectedDate = DateTime.now();
            selectedDateTo = null;
            totalDays = 0;
            isButtonEnabled = false;
            _updatePriceString();
            Fluttertoast.showToast(
                msg:
                    "Those dates are no longer available — please pick new dates.");
            break;
          }
        }
      }
    });
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
  /// Who the stay is for. null = the account holder, which is the usual case
  /// and what every booking meant before saved travellers existed.
  int? _travellerId;
  double _couponDiscount = 0;
  double _couponPercent = 0;

  /// A percentage as a person would write it: "10", not "10.0"; "9.38", not
  /// "9.375000000001".
  static String _pct(double v) {
    final rounded = (v * 100).round() / 100;
    return rounded == rounded.roundToDouble()
        ? rounded.toStringAsFixed(0)
        : rounded.toString();
  }
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
    // Percent first. The server-computed absolute was checked BEFORE this and
    // therefore won every time, freezing a percentage coupon's saving at
    // whatever the stay cost when it was applied. A percentage has to follow
    // the stay; only a flat-amount coupon has no percentage to follow it with.
    final base = (double.tryParse(currentPriceString) ?? 0) + _partyFee;
    if (_couponPercent > 0) {
      return (base * _couponPercent / 100).clamp(0, base).toDouble();
    }
    if (_couponDiscount > 0) return _couponDiscount.clamp(0, base).toDouble();
    return 0;
  }

  Timer? _couponRecheck;


  /// The stay changed, so anything priced against it has to be re-priced.
  ///
  /// A coupon is validated server-side against a specific amount, and the
  /// figure that comes back was cached and shown unchanged for the rest of the
  /// session. Add a guest or move the dates and the saving on screen was the
  /// saving for the OLD stay, while /booking/create recomputes against the new
  /// one — so the guest was shown one number and charged another. Re-checking
  /// keeps the two the same, and drops the coupon honestly if the new stay no
  /// longer qualifies (a smaller party can fall under a minimum spend).
  ///
  /// Debounced because the guest stepper fires on every tap.
  /// [_restayed], deferred out of a setState callback.
  ///
  /// The date handlers do their work inside setState; starting a timer that
  /// can call setState again from in there is asking for trouble.
  void _restayedAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _restayed());
  }

  void _restayed() {
    final code = _appliedCoupon;
    if (code == null || code.isEmpty) return;
    _couponRecheck?.cancel();
    _couponRecheck = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      _applyCoupon();
    });
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
    // Validate against room + party charge — the figure the server discounts
    // (booking.controller applies the coupon to the whole chargeable amount).
    // Testing against the room alone could refuse a coupon whose minimum-spend
    // the real booking actually clears, or show a discount capped short.
    final base = (double.tryParse(currentPriceString) ?? 0) + _partyFee;
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
            ? 'Applied — ${_pct(res.percent)}% off (${rupees(res.discount)})'
            : 'Applied — ${rupees(res.discount)} off';
      } else {
        _appliedCoupon = null;
        _couponOk = false;
        _couponMsg = res.message;
      }
    });
  }

  /// The discount running on this listing, if any. Read from the fetched
  /// detail rather than held separately, so it cannot go stale against the
  /// price beside it.
  PropertyOffer? get _offer => _single?.offer;

  /// Drop a pay-at-property selection the offer does not permit.
  ///
  /// The option can be ticked before the detail arrives, and withdrawing the
  /// tile afterwards would leave `isCod` true with nothing on screen saying so
  /// — a booking the server then refuses for a reason the guest cannot see.
  void _reconcilePayMode() {
    if (isCod && _offer != null && !_offer!.allowsCod) {
      setState(() => isCod = false);
    }
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
    _reconcilePayMode();
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
    // Weekend rates, when the host set any. This was currentPrice * totalDays,
    // which threw away the Friday/Saturday/Sunday prices step 4 collects — the
    // guest was quoted the weekday rate for a Saturday and the host was never
    // paid what they had asked for. Falls back to the flat multiplication when
    // the listing has no weekend pricing, or before the detail has loaded.
    final rule = _single?.pricing;
    final weekendTotal = (rule != null && rule.weekendPricing)
        ? rule.quote(selectedDate, selectedDateTo)
        : 0.0;
    final totalPrice =
        weekendTotal > 0 ? weekendTotal : currentPrice * totalDays;
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
                        // A running offer replaces the headline and strikes the
                        // listed price. The figures come from the server —
                        // recomputing a discount here would let this screen and
                        // the checkout disagree about the same stay.
                        if (_offer != null)
                          TextSpan(
                            text: '${rupees(_offer!.was)} ',
                            style: inter(fontSize: 14, color: kMuted)
                                .copyWith(
                                    decoration: TextDecoration.lineThrough),
                          ),
                        TextSpan(
                          text: _offer != null
                              ? rupees(_offer!.now)
                              : rupeesFrom(perNight),
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
                        // The word "total" has to mean the total.
                        //
                        // This printed `currentPriceString` — the PRE-TAX room
                        // subtotal — and labelled it "total", so the bar
                        // pinned to the bottom of every property page said
                        // "₹4,000 total" for a stay the panel above it priced
                        // at ₹4,200. `_confirmedPrice` is the same computation
                        // the booking itself is made with.
                        TextSpan(
                          text: '${rupees(_confirmedPrice.total)} total',
                          style: inter(
                            fontSize: 12,
                            color: kMuted,
                          ).copyWith(decoration: TextDecoration.underline),
                        ),
                        TextSpan(text: ' · incl. taxes · $nights'),
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
                foregroundColor: kAccentInk,
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
                  _dmy(selectedDate),
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
                      _restayedAfterFrame();
                      selectedDateTo ??= picked.add(const Duration(days: 1));
                      // Nights, not calendar days. This was `.inDays + 1`,
                      // which billed a 12th-to-13th stay as two nights — one
                      // more than the guest is there. The negotiated-deal path
                      // in this same file, and the website, have always used
                      // the plain difference, so picking your own dates cost a
                      // night more than arriving on the identical dates from
                      // an accepted offer.
                      totalDays =
                          _nightsBetween(selectedDate, selectedDateTo!);
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
                leading: Icon(Icons.calendar_month,
                    color: _needsCheckout ? kDanger : null),
                tileColor: _needsCheckout ? const Color(0xFFFDECEC) : null,
                shape: _needsCheckout
                    ? RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: kDanger),
                      )
                    : null,
                title: Text(
                  selectedDateTo != null
                      ? _dmy(selectedDateTo!)
                      : 'Book To (DD/MM/YYYY)',
                  style: _needsCheckout
                      ? inter(fontWeight: FontWeight.w600, color: kDanger)
                      : null,
                ),
                subtitle: _needsCheckout
                    ? Text('Pick a check-out date to book',
                        style: inter(fontSize: 11.5, color: kDanger))
                    : null,
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
                      _needsCheckout = false;
                      _restayedAfterFrame();
                      // selectedDate is non-null by design
                      // Nights, not calendar days. This was `.inDays + 1`,
                      // which billed a 12th-to-13th stay as two nights — one
                      // more than the guest is there. The negotiated-deal path
                      // in this same file, and the website, have always used
                      // the plain difference, so picking your own dates cost a
                      // night more than arriving on the identical dates from
                      // an accepted offer.
                      totalDays =
                          _nightsBetween(selectedDate, selectedDateTo!);
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
                  // `?? "12:00PM"` never fired, because every caller passes
                  // these as `something.toString()` — and `null.toString()` is
                  // the STRING "null", which is not null. So a listing with no
                  // check-in time displayed "null / null · set by the host".
                  '${_stayTime(_single?.propDetails?.inTime, widget.inTime)}'
                  ' / '
                  '${_stayTime(_single?.propDetails?.outTime, widget.outTime)}'
                  ' · set by the host',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kLine),
                  boxShadow: kSoftShadow,
                ),
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
                                Text(
                                  'Booking Price',
                                  style: fraunces(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: kInk,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // (Categories moved to main content section)

                                Text(
                                  'Total for selected dates',
                                  style: inter(
                                    fontSize: 14,
                                    color: kMuted,
                                  ),
                                ),
                                Text("Nights: $totalDays",
                                    style: inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
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
                            ),
                            child: Builder(
                              builder: (context) {
                                // One pricing rule, shared with the breakdown
                                // below and the submit handler. The band comes
                                // from the nightly tariff, not the stay total.
                                final p = priceStay(
                                  roomSubtotal: _roomCharge,
                                  perNightTariff: currentPrice,
                                  discount: _discountOnRoom,
                                  extraGuestFee: _partyFee,
                                  petFee: _petFee,
                                  pets: _pets,
                                  nightlyTotal: _nightlyTotal,
                                  longStayLabel: _longStay?.label,
                                );

                                return Text(
                                  rupees(p.total),
                                  style: fraunces(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Who is coming. Capped at the host's stated capacity so
                      // the count cannot climb past what the place sleeps.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Guests',
                                  style: inter(
                                      fontSize: 14, fontWeight: FontWeight.w600)),
                              if (_guestCeiling != null)
                                Text('This place sleeps up to $_guestCeiling',
                                    style: inter(
                                        fontSize: 11.5, color: kMuted)),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                iconSize: 26,
                                onPressed: _guests > 1
                                    ? () {
                                        setState(() => _guests -= 1);
                                        _restayed();
                                      }
                                    : null,
                              ),
                              SizedBox(
                                width: 28,
                                child: Text('$_guests',
                                    textAlign: TextAlign.center,
                                    style: inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                iconSize: 26,
                                onPressed: (_guestCeiling == null ||
                                        _guests < _guestCeiling!)
                                    ? () {
                                        setState(() => _guests += 1);
                                        _restayed();
                                      }
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Pets, only where this host takes them. Their own count
                      // and their own cap: pets do not occupy beds, so they sit
                      // outside the guest ceiling entirely.
                      if (_petPolicy.petsAllowed) ...[
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Pets',
                                      style: inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600)),
                                  Text(
                                    _petPolicy.feePerNight > 0
                                        ? '${rupees(_petPolicy.feePerNight)} per pet, per night'
                                        : 'Assistance animals are always welcome',
                                    style: inter(fontSize: 11.5, color: kMuted),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  iconSize: 26,
                                  onPressed: _pets > 0
                                      ? () {
                                          setState(() => _pets -= 1);
                                          _restayed();
                                        }
                                      : null,
                                ),
                                SizedBox(
                                  width: 28,
                                  child: Text('$_pets',
                                      textAlign: TextAlign.center,
                                      style: inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  iconSize: 26,
                                  // The host's cap when they set one; going
                                  // over it is refused by the server with a
                                  // reason, so stopping here is the kinder
                                  // version of the same rule.
                                  onPressed: (_petPolicy.maxPets <= 0 ||
                                          _pets < _petPolicy.maxPets)
                                      ? () {
                                          setState(() => _pets += 1);
                                          _restayed();
                                        }
                                      : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 8),

                      // Price breakdown
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kCream,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: kLine,
                            width: 1,
                          ),
                        ),
                        child: Builder(
                          builder: (context) {
                            final p = priceStay(
                              roomSubtotal: _roomCharge,
                              perNightTariff: currentPrice,
                              discount: _discountOnRoom,
                              extraGuestFee: _partyFee,
                              petFee: _petFee,
                              pets: _pets,
                              nightlyTotal: _nightlyTotal,
                              longStayLabel: _longStay?.label,
                            );

                            return Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Base Price',
                                      style: inter(
                                        fontSize: 14,
                                        color: kMuted,
                                      ),
                                    ),
                                    Text(
                                      rupees(p.roomSubtotal),
                                      style: inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: kMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                if (p.extraGuestFee > 0) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Extra guests',
                                        style: inter(
                                          fontSize: 14,
                                          color: kMuted,
                                        ),
                                      ),
                                      Text(
                                        rupees(p.extraGuestFee),
                                        style: inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: kMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                // Named the way the extra-guest line above is,
                                // so a total that grew because a dog is coming
                                // is explained rather than mysterious.
                                if (_petFee > 0) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '$_pets pet${_pets == 1 ? '' : 's'} × '
                                          '${rupees(_petPolicy.feePerNight)} × '
                                          '$totalDays night${totalDays == 1 ? '' : 's'}',
                                          style: inter(
                                              fontSize: 14, color: kMuted),
                                        ),
                                      ),
                                      Text(
                                        rupees(_petFee),
                                        style: inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: kMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                // What the host's weekly/monthly price saves
                                // this guest, as a percentage and an amount.
                                //
                                // The room line above is ALREADY the long-stay
                                // rate, so this is not another deduction — it
                                // says what the rate is worth against paying
                                // night by night, which is the thing a guest
                                // booking a month actually wants to know.
                                if (p.longStaySaving > 0) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEAF6EE),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.savings_outlined,
                                            size: 15, color: kSuccess),
                                        const SizedBox(width: 7),
                                        Expanded(
                                          child: Text(
                                            // Names the RIGHT reason. A host
                                            // offer and a long-stay rate both
                                            // reduce the room subtotal, and
                                            // crediting the saving to the wrong
                                            // one tells the guest something
                                            // untrue about why they saved.
                                            'You saved '
                                            '${p.longStaySavingPercent.toStringAsFixed(p.longStaySavingPercent % 1 == 0 ? 0 : 1)}%'
                                            ' — ${rupees(p.longStaySaving)}'
                                            '${_offer != null ? ' with ${_offer!.title.toLowerCase()}' : ' with the ${p.longStayLabel?.toLowerCase() ?? 'long-stay rate'}'}',
                                            style: inter(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                                color: kSuccess,
                                                height: 1.35),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (p.discount > 0) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _couponPercent > 0
                                            ? 'Discount (${_pct(_couponPercent)}% — $_appliedCoupon)'
                                            : 'Discount ($_appliedCoupon)',
                                        style: inter(
                                          fontSize: 14,
                                          color: kSuccess,
                                        ),
                                      ),
                                      Text(
                                        '− ${rupees(p.discount)}',
                                        style: inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: kSuccess,
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
                                      style: inter(
                                        fontSize: 14,
                                        color: kMuted,
                                      ),
                                    ),
                                    Text(
                                      rupees(p.taxes),
                                      style: inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: kMuted,
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
                                    color: kLine,
                                    thickness: 1,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total Amount',
                                      style: fraunces(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: kInk,
                                      ),
                                    ),
                                    Text(
                                      rupees(p.total),
                                      style: inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
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
                                        style: inter(
                                          fontSize: 14,
                                          color: kMuted,
                                        ),
                                      ),
                                      Text(
                                        rupees(p.total * 0.10),
                                        style: inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: kMuted,
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
                                        style: inter(
                                          fontSize: 14,
                                          color: kMuted,
                                        ),
                                      ),
                                      Text(
                                        rupees(p.total * 0.90),
                                        style: inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: kMuted,
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
              // How the stay gets paid for.
              //
              // This was a lone checkbox reading "Make the payment upon
              // arrival": one option, phrased as an opt-out, with the thing it
              // opts out OF never named. A guest could not see that paying
              // online was a choice at all, only that there was a box they
              // might tick. The website asks the same question as two
              // selectable methods (redesign/pages/guest/Payment.tsx) — Pay
              // online / Pay at property, each saying what it means — so this
              // asks it the same way.
              //
              // Pre-booking still has no choice to offer: 10% has to clear
              // online to hold the dates, so the pair is hidden rather than
              // shown with one half disabled.
              if (!isPrebooking) ...[
                _PayMethod(
                  icon: Icons.credit_card,
                  title: 'Pay online',
                  sub: 'UPI, Card, Net Banking · secured by Razorpay',
                  selected: !isCod,
                  onTap: () => setState(() => isCod = false),
                ),
                // Pay at property only where the offer allows it. A discounted
                // stay is paid in full unless whoever created the offer ticked
                // that box, and the server refuses anything else — so the
                // option is withdrawn here with a reason rather than left to
                // fail at the last step.
                if (_offer == null || _offer!.allowsCod) ...[
                  const SizedBox(height: 10),
                  _PayMethod(
                    icon: Icons.payments_outlined,
                    title: 'Pay at property',
                    sub: 'Reserve now, pay on arrival',
                    selected: isCod,
                    onTap: () => setState(() => isCod = true),
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 15, color: kMuted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'This discounted price has to be paid in full — '
                            'pay at property is not available on it.',
                            style: inter(
                                fontSize: 11.5, color: kMuted, height: 1.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
              ],
              // Wallet (audit C-9) — online payments only: cash handed over
              // at a front desk cannot be split against credit held here, so
              // the row disappears when pay-on-arrival is ticked rather than
              // offering something the booking cannot honour.
              if (_walletBalance > 0 && !isCod && !isPrebooking)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: kCream,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kLine),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _useWallet,
                        activeColor: kIndigo,
                        onChanged: (v) => setState(() => _useWallet = v!),
                      ),
                      const Icon(Icons.account_balance_wallet_outlined,
                          size: 17, color: kInk),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Use wallet balance',
                                style: inter(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: kInk)),
                            Text('${rupees(_walletBalance)} available',
                                style:
                                    inter(fontSize: 11.5, color: kMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (isPrebooking)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: kIndigo50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kLine),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline, size: 17, color: kIndigo),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Advance required — 10% online to confirm the '
                          'pre-booking.',
                          style: inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: kInk,
                              height: 1.35),
                        ),
                      ),
                    ],
                  ),
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
                            inputFormatters: AppInputFormatters.upperAlnum(30),
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
              TravellerPicker(
                value: _travellerId,
                onChanged: (id) => setState(() => _travellerId = id),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
onPressed: () async {
                  // Nothing in here may fail silently. Before this, an
                  // exception anywhere in the booking path closed the sheet
                  // with no message at all — the guest tapped Book Now and
                  // simply landed back on the property.
                  try {
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
                      roomSubtotal: _roomCharge,
                      perNightTariff: currentPrice,
                      discount: _discountOnRoom,
                      extraGuestFee: _partyFee,
                      petFee: _petFee,
                      pets: _pets,
                      nightlyTotal: _nightlyTotal,
                      longStayLabel: _longStay?.label,
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
                      // Who is actually staying. Omitted when it is the
                      // account holder; the server re-checks the traveller
                      // belongs to this account before attaching it.
                      if (_travellerId != null) "guestProfileId": _travellerId,
                      // `price` is the PRE-TAX room subtotal. The backend adds
                      // GST itself (calculateBookingtax) and stores the result
                      // as book_total_amt, so sending the taxed total made it
                      // tax the tax — the guest on B618787 was quoted ₹23,020
                      // and the row said ₹24,171. The coupon branch below has
                      // always sent the subtotal; this makes every booking do
                      // what that branch already did.
                      //
                      // Prebooking now sends the REAL room subtotal, like every
                      // other booking, and asks for the deposit through
                      // `payMode` (W2 Phase D).
                      //
                      // It used to send the deposit AS the price, because the
                      // backend had no notion of one — so a prebooked stay was
                      // recorded as costing 10% of its real price, and the host
                      // was owed a tenth of what the guest had agreed to. The
                      // backend computes the deposit itself now, from the full
                      // total, and remembers the balance; so the honest figure
                      // is the one to send.
                      // Room + the party charge. The backend recomputes this
                      // from `no_of_guests` and refuses a price that disagrees,
                      // so the two must be sent together or not at all.
                      "price": p.chargeable,
                      "no_of_guests": _guests,
                      // Declared pets. The server prices them from its own
                      // policy and refuses a pet at a host who does not take
                      // them — but without this the booking records none and
                      // the fee the guest just paid attaches to nothing.
                      "no_of_pets": _pets,
                      "bookFrom": formattedDate,
                      "bookTo": formattedDateTo,
                      "isCod": isCod,
                      // "deposit" charges the confirming percentage now and
                      // leaves the balance due before check-in; the server
                      // works out the amount from its own total, so this only
                      // says which of the two the guest chose.
                      if (isPrebooking && !isCod) "payMode": "deposit",
                      "category": 1,
                      "bookingType": bookingType,
                      // Extra informational fields for server (safe to ignore if unsupported)
                      "isPrebooking": isPrebooking,
                      "totalAmount": finalAmount,
                      "advanceAmount": advanceAmount,
                      // Wallet (audit C-9): a flag, not an amount — the server
                      // decides how much applies from the balance it holds.
                      "useWallet":
                          !isCod && !isPrebooking && _useWallet && _walletBalance > 0,
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
                        guests: _guests,
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
                        // "pending" is not "in review", and telling someone we
                        // are checking their ID when nobody is checking
                        // anything leaves them waiting for a decision that will
                        // never arrive. Didit decides a guest's check on the
                        // spot; "pending" means they opened it and walked away,
                        // so the useful thing to say is that it is unfinished.
                        // Only "in_review" is a real human decision pending.
                        final String title;
                        final String body;
                        if (st == 'in_review') {
                          title = 'Still reviewing your ID';
                          body = "We're checking your ID now. Your dates are "
                              "saved — come back to finish once it's approved.";
                        } else if (st == 'pending' || st == 'partial') {
                          title = 'Verification not finished';
                          body = "You started the check but didn't finish it. "
                              'Your dates are saved — tap Book again to pick up '
                              'where you left off.';
                        } else {
                          title = 'Verification required';
                          body = 'Please verify your identity to continue booking.';
                        }
                        bookingController.showSnackbar(title, body, true);
                        return;
                      }
                    }
                    final bookingResponse =
                        await bookingController.createBooking(bookingData);
                    // The booking exists; nothing left to resume.
                    await PendingBookingStore.clear();
                    // Wallet covered the whole stay: paid, no gateway modal
                    // to open. The success dialog is the same one a verified
                    // online payment reaches.
                    if (bookingResponse.data.booking.walletPaid) {
                      successDialog(
                          "Wallet", bookingResponse.data.booking.bookId);
                    } else if (!isCod) {
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
                      // Kept so a refused payment can be retried against the
                      // same order rather than making the guest start over —
                      // the booking already exists at this point.
                      _lastPaymentOptions = options;
                      try {
                        // A release build carrying a TEST key takes no money while looking
                        // exactly as if it did (W8 · P0-02). Refuse rather than confirm a
                        // booking nobody paid for. Debug builds, and any build made with
                        // --dart-define=ALLOW_TEST_PAYMENTS=true, are unaffected.
                        if (!PaymentConfig.usableForPayments) {
                          Fluttertoast.showToast(msg: PaymentConfig.unavailableMessage);
                          return;
                        }
                        razorpay.open(options);
                      } catch (e) {
                        debugPrint('Error: $e');
                      }
                    } else {
                      // Pay-at-property on an approval-required listing is a
                      // REQUEST. The server says which; saying "confirmed"
                      // regardless is what made the app disagree with the web.
                      successDialog(
                        "N/A",
                        bookingResponse.data.booking.bookId,
                        awaitingApproval:
                            bookingResponse.data.requiresApproval,
                        responseHours: bookingResponse.data.responseHours,
                      );
                    }
                  } else {
                    // "Please select valid dates", as a two-second toast, was
                    // the whole of the feedback here — on the last step of a
                    // checkout, for the one field the guest has to fill and
                    // nothing fills by default. It named neither which date
                    // was missing nor where to set it, and it was gone before
                    // a slow reader finished it, leaving Book Now looking like
                    // a button that does nothing.
                    //
                    // The check-out row marks itself instead, and stays marked
                    // until a date is chosen.
                    setState(() => _needsCheckout = true);
                    bookingController.showSnackbar(
                      'Choose your check-out date',
                      'Pick the date you are leaving — the total updates '
                          'before you book.',
                      true,
                    );
                  }
                  } catch (e) {
                    bookingController.showSnackbar(
                      "Couldn't complete booking",
                      e.toString().replaceFirst('Exception: ', ''),
                      true,
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
                    // One sheet: your price, your dates, an optional message
                    // — the website's "Send an Offer" modal.
                    //
                    // This used to push PriceNegotiationPage, a live socket
                    // chat with a thirty-second countdown, six quick-price
                    // chips and a running offer counter. The countdown implied
                    // a host was about to answer within thirty seconds, which
                    // is not how the server works: it escalates to the host,
                    // notifies them, and waits. Two clients negotiating
                    // through two transports against one engine is how they
                    // came to disagree about the rules.
                    //
                    // An ongoing thread is still readable from the
                    // negotiations list. This is the opening move, and on a
                    // phone it should cost one sheet.
                    final accepted = await showSendOfferSheet(
                      context,
                      propertyId: widget.id,
                      propertyName: _single?.propertyName ?? widget.name,
                      nightlyPrice: currentPrice,
                      initialFrom: selectedDate,
                      initialTo: selectedDateTo,
                    );
                    if (!mounted) return;
                    if (accepted) {
                      // Accepted outright: the server has already minted the
                      // 24-hour coupon, so reload the page's own price and
                      // open the booking panel at it.
                      await _fetchSingleProperty();
                      if (!mounted) return;
                      _toggleExpanded();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kSurface,
                    foregroundColor: kIndigo,
                    elevation: 0,
                    side: const BorderSide(color: kIndigo, width: 1.5),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Negotiate',
                      style: inter(
                          fontSize: 15, fontWeight: FontWeight.w600)),
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
    _couponRecheck?.cancel();
    _animationController.dispose();
    _priceController.dispose();
    _couponController.dispose();
    razorpay.clear();
    _pageScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            controller: _pageScroll,
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
                      //
                      // Read the wizard's capacity record FIRST and only fall
                      // back to the legacy propDetails. A stay listed through
                      // the 5-step wizard has no propDetails row at all, so
                      // this row used to show a single lonely "2 Baths" — the
                      // one figure that lives on the property row itself —
                      // while its guests, bedrooms and beds sat in
                      // property_capacity unread. Bedrooms was never shown on
                      // either platform even though the form has always asked
                      // for it.
                      if (_specs.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        // A Row, not a Wrap: _SpecChip is an Expanded, which is
                        // only legal inside a Flex and throws in a Wrap. Four
                        // equal columns is also the layout this row was drawn
                        // for — it only looked centred because one figure was
                        // arriving and taking the whole width to itself.
                        Row(children: _specs),
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
                      // A-29/A-30/A-31 — the seven sections, stacked, matching
                      // the website. These were behind a tab switcher, which
                      // drew ONE at a time: a host who had filled in amenities,
                      // rules, distances and a full specification opened their
                      // own live listing and saw a heading, a sentence and the
                      // price. The row is a jump nav now, not a switch.
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
                      // Posts written about THIS stay, matching the web. No
                      // "See all": these are not in the platform blog, so a
                      // link to it would go somewhere they cannot be found.
                      // Absent on most stays, and the strip renders nothing
                      // when there are none.
                      HomeBlogStrip(
                        max: 6,
                        title: 'Guides & stories',
                        propertyId: widget.id,
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
        // Two things were wrong with the message people actually forward.
        //
        // "Rating: ${widget.rating} ★" printed the value the CALLER passed in,
        // which is the constant "4.5" — the deal banner hardcodes it and
        // CuratedCard defaults to it. The pills on this screen were fixed to
        // show a real rating or none at all; the share text was the copy that
        // was missed, and it is the one that leaves the platform. A stay with
        // no reviews was being recommended to someone else's WhatsApp at 4.5
        // stars. It now uses the same real rating the page shows, and says
        // nothing when there is nothing to say.
        //
        // The link pointed at https://aajoo.com/property/<id>. That domain does
        // not resolve, and the site's route is /property?id=<id>, so every
        // property anyone shared was a dead link twice over.
        final r = _rating;
        final ratingLine = r == null
            ? 'Newly listed'
            : 'Rating: ${r.toStringAsFixed(1)} ★ ($_reviewCount review${_reviewCount == 1 ? '' : 's'})';
        final shareText = '''
Check out this amazing property on Aajoo!
Name: ${widget.name}
Location: ${widget.location}
Price: ${rupeesFrom(widget.price)}/night
$ratingLine
Description: ${widget.description}
Book now: https://www.aajoohomes.com/property?id=${widget.id}
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
          // Two pills over the hero image, and both used to be fiction.
          //
          // The rating showed "0.0" while the reviews loaded and then a
          // hardcoded "4.2" for any stay with no rating at all — an invented
          // score, on the listing page, above a line that correctly said "New
          // listing". Two answers on one screen, and the flattering one was
          // made up. Same class as the badge that read is_verify: this is the
          // third copy of the invented-rating bug, after widget.rating's
          // constant "4.5" in the hero badge and the meta row.
          //
          // The category said "Apartment" on every property in the catalogue,
          // regardless of what it actually is.
          //
          // Now: the rating pill appears only for a stay someone has really
          // rated, and the category pill prints the listing's own first
          // category, or nothing.
          child: Row(
            children: [
              if (_rating != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        _rating!.toStringAsFixed(1),
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (_heroCategory != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    _heroCategory!,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.white),
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
  /// The host's weekly/monthly rate for the nights currently chosen, or null.
  ///
  /// Step 4 now asks the host what a week and a month COST. Nothing read the
  /// old long-stay fields at all, so a 35-night stay was quoted at the full
  /// nightly rate times thirty-five. The server resolves the identical rate
  /// and refuses a booking whose price disagrees, so this must match it.
  LongStayRate? get _longStay => _single?.pricing?.longStayFor(totalDays);

  /// What the same nights cost night by night — the comparison the saving is
  /// measured against, and what a short stay pays.
  double get _nightlyTotal => double.tryParse(currentPriceString) ?? 0;

  /// What the room actually costs: the host's long-stay rate when the stay is
  /// long enough to earn one, else the nightly total.
  ///
  /// Never MORE than nightly. A host could have saved a long-stay price above
  /// their own nightly rate before the wizard started refusing it, and a guest
  /// must not be charged extra for staying longer.
  double get _roomCharge {
    final rate = _longStay;
    final nightly = _nightlyTotal;
    final base = (rate == null || totalDays <= 0)
        ? nightly
        : (() {
            final atLongStay =
                (rate.nightlyRate * totalDays * 100).roundToDouble() / 100;
            return atLongStay < nightly ? atLongStay : nightly;
          })();

    // A running offer scales the ROOM subtotal — the same thing the server
    // does, and the same ratio the headline above uses. Without this the page
    // showed a discounted per-night rate and then a full-price total three
    // lines below it: 2,560/night and 3,360 total for one night.
    //
    // The extra-guest fee is deliberately left alone; priceStay adds it after
    // this, and the server does not discount it either.
    final o = _offer;
    if (o == null) return base;
    return (base * o.ratio * 100).roundToDouble() / 100;
  }

  /// The price this booking was made at — one computation, used for the
  /// headline figure and for every line of the breakdown beside it, so they
  /// cannot disagree.
  StayPrice get _confirmedPrice => priceStay(
        roomSubtotal: _roomCharge,
        perNightTariff: currentPrice,
        discount: _discountOnRoom,
        extraGuestFee: _partyFee,
        petFee: _petFee,
        pets: _pets,
        nightlyTotal: _nightlyTotal,
        longStayLabel: _longStay?.label,
      );

  void successDialog(
    String paymentId,
    String bookingId, {
    /// The host chose "Approval Required" — this is a request, not a booking.
    bool awaitingApproval = false,
    int responseHours = 24,
  }) {
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
          // The GRAND total, not the room subtotal: a pay-at-property guest
          // owes the taxed amount on arrival, and that is what the server
          // stored. Saying "Rs 6000 due" after quoting Rs 6300 is a different
          // number for the same booking.
          amount: rupees(_confirmedPrice.total),
          // ...and the parts that make it up, so the confirmation shows a
          // breakdown rather than one figure the guest has to trust.
          roomCharge: _confirmedPrice.roomSubtotal,
          extras: _confirmedPrice.extraGuestFee,
          taxes: _confirmedPrice.taxes,
          discount: _confirmedPrice.discount,
          total: _confirmedPrice.total,
          isPayOnArrival: isCod,
          awaitingApproval: awaitingApproval,
          responseHours: responseHours,
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
      // The charge went through and OUR verification did not. Telling the
      // guest "Payment has been failed" is not just unhelpful, it is wrong —
      // their money may well have left. Say what we actually know.
      _showPaymentProblem(
        title: "We couldn't confirm your payment",
        reason: 'Your bank may still have taken it. Do not pay again — check '
            'My Bookings in a few minutes, and contact us if it still looks '
            'unpaid.',
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    // A toast carrying the plugin's raw JSON envelope, for two seconds.
    //
    // The guest was told "Payment Failed: {"error":{"code":...}}" and it was
    // gone before they could read it, with nothing to do next — while the
    // booking sat unpaid and they had no idea it still existed. Razorpay's own
    // sentence goes on screen instead, and it stays there with two ways on.
    _showPaymentProblem(
      title: 'Payment not completed',
      reason: rzpReason(response),
      canRetry: _lastPaymentOptions != null,
    );
  }

  /// Why a payment did not go through, and what to do about it.
  ///
  /// The booking already exists by the time Razorpay opens — it is held,
  /// unpaid — so "try again" and "pay later from My Bookings" are both real
  /// options, and saying so is the difference between a dead end and a detour.
  void _showPaymentProblem({
    required String title,
    required String reason,
    bool canRetry = false,
  }) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title,
            style: fraunces(
                fontSize: 18, fontWeight: FontWeight.w600, color: kInk)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reason,
                style: inter(fontSize: 14, color: kInk, height: 1.45)),
            const SizedBox(height: 12),
            Text(
              'Your booking is held and nothing has been charged. You can pay '
              'for it any time from My Bookings.',
              style: inter(fontSize: 13, color: kMuted, height: 1.45),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Not now',
                style: inter(fontSize: 14, color: kMuted)),
          ),
          if (canRetry)
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                final options = _lastPaymentOptions;
                if (options == null) return;
                try {
                  razorpay.open(options);
                } catch (e) {
                  debugPrint('Retry failed: $e');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kIndigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Try again',
                  style: inter(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
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

/// One payment method, selectable.
///
/// The website's `Method` (redesign/pages/guest/Payment.tsx): a 12px card that
/// takes a 1.5px brand rule and the lightest brand wash when it is the chosen
/// one, and a plain hairline when it is not — so which method is selected is
/// readable without reading, and each says what it actually means rather than
/// leaving the guest to infer it from a single unticked box.
class _PayMethod extends StatelessWidget {
  const _PayMethod({
    required this.icon,
    required this.title,
    required this.sub,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title, sub;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: selected ? kIndigo50 : kSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? kIndigo : kLine,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 20,
                color: selected ? kIndigo : kMuted,
              ),
              const SizedBox(width: 12),
              Icon(icon, size: 20, color: selected ? kIndigo : kInk2),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: kInk)),
                    const SizedBox(height: 2),
                    Text(sub,
                        style: inter(fontSize: 11.5, color: kMuted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
