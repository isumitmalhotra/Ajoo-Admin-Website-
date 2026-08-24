import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/constants/payment_config.dart';
import 'package:rent_home/controller/user_controller.dart';
import 'package:rent_home/ui/screens_renter/booking_controller.dart';
import 'package:rent_home/utils/stay_clock.dart';
import 'package:rent_home/utils/booking_status.dart';
import 'package:rent_home/data/ApiConstants.dart';
import 'package:rent_home/data/models/booking_history_response_model.dart';
import 'package:rent_home/data/models/properties_response_model.dart';
import 'package:rent_home/models/host_profile.dart';
import 'package:rent_home/models/single_property_response.dart';
import 'package:rent_home/service/device_service.dart';
import 'package:rent_home/service/property_service.dart';
import 'package:rent_home/ui/screens_common/auth/auth_controller.dart';
import 'package:rent_home/ui/screens_common/price_negotiation/negotitaion_page.dart';
import 'package:rent_home/ui/screens_common/support/support_screen.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/ui/screens_renter/history/history_description/components/booking_property_gallery.dart';
import 'package:rent_home/ui/screens_renter/history/history_description/components/property_description_section.dart';
import 'package:rent_home/ui/screens_renter/history/history_description/property_review_controller.dart';
import 'package:rent_home/ui/screens_renter/history/history_description/review/property_review_section.dart';
import 'package:rent_home/ui/screens_renter/property_details/components/property_tabs.dart';
import 'package:rent_home/ui/screens_renter/property_details/property_page.dart';
import 'package:rent_home/models/cancellation_quote.dart';
import 'package:rent_home/utils/money.dart';

class HistoryDescriptionPage extends StatefulWidget {
  const HistoryDescriptionPage({
    super.key,
    required this.bookingData,
    required this.propertyId,
  });

  final BookingHistoryData bookingData;
  final int propertyId;

  @override
  State<HistoryDescriptionPage> createState() => _HistoryDescriptionPageState();
}

class _HistoryDescriptionPageState extends State<HistoryDescriptionPage> {
  final UserController userController = Get.put(UserController());
  final BookingController _bookingController = Get.put(BookingController());
  final PropertyReviewController propertyController =
      Get.put<PropertyReviewController>(
    PropertyReviewController(),
  );
  final reviewController = TextEditingController();
  final PropertyService _propertyService = PropertyService();
  double rating = 0.0;

  /// Razorpay for the Pay-now leg. Created once; cleared in dispose so the
  /// event handlers can't outlive the screen.
  late final Razorpay _razorpay;
  bool _payBusy = false;

  /// Who hosts the stay. Fetched separately — the property payload carries only
  /// a host id, which is why the property page had to do the same.
  HostProfile? _host;

  /// A cancelled booking shows a "Book now" button and no host at all: no host
  /// card, no chat, no phone number. The guest is not staying there, so the
  /// host is not theirs to contact.
  bool get _isCancelled =>
      (widget.bookingData.bookingStatusBsTitle ?? '')
          .toLowerCase()
          .contains('cancel');

  SinglePropertyData? get _single => userController.property.value?.data;

  @override
  void initState() {
    super.initState();

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await userController.getProperty(widget.propertyId);
      if (!mounted) return;
      await _fetchHost();
    });
    propertyController.getPropertyReviews(widget.propertyId);
  }

  @override
  void dispose() {
    _razorpay.clear();
    reviewController.dispose();
    super.dispose();
  }

  /// The stay is over once checkout has passed — nothing left to cancel.
  bool get _stayOver => hasEnded(widget.bookingData.bookDetailsBtBookTo);

  bool get _canCancel => !_isCancelled && !_stayOver;

  /// A pay-at-property booking that hasn't been settled yet.
  ///
  /// Paying online is offered for exactly these, at any point in the stay's
  /// life — booked today and paying tomorrow, or settling after checking out.
  /// The whole point of "pay at property" is that the money is still owed, and
  /// paying it through the platform is safer for both sides than cash at a
  /// door: the guest gets a receipt and a trail, the host gets a payout they
  /// don't have to chase. POST /user/ongoing/bookings/payment/create is
  /// COD-only by design, and settling clears the flag so nobody then turns up
  /// expecting cash.
  bool get _owesOnline =>
      !_isCancelled &&
      !widget.bookingData.bookIsPaid &&
      widget.bookingData.bookIsCod;

  Future<void> _fetchHost() async {
    if (_isCancelled) return; // Nothing on this page will show it.
    final hostId = _single?.propertyHostId;
    if (hostId == null || hostId == 0) return;
    final host = await _propertyService.getHostProfile(hostId);
    if (!mounted || host == null) return;
    setState(() => _host = host);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kscaffoldColor,
      appBar: _appBar(context),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // A-63 — the stay's photos, where the map used to be.
                  BookingPropertyGallery(
                    isLoading: userController.isLoading.value,
                    images: _single?.images ?? const [],
                  ),
                  const SizedBox(height: 20),
                  PropertyDescriptionSection(
                      isLoading: userController.isLoading,
                      // Fall back to the property info stored on the booking
                      // when the live property can't be fetched (e.g. the host
                      // later removed the listing) — so history never goes blank.
                      propertyName: _single?.propertyName ??
                          widget.bookingData.bookingPropertyPropertyName,
                      propertyAddress: _single?.propertyAddress ??
                          widget.bookingData.bookingPropertyPropertyAddress,
                      bookingDataWidget: _buildBookingData(widget.bookingData)),
                  // A-61 — help and the host, directly under the booking.
                  _actions(),
                  const SizedBox(height: 8),
                  const Divider(color: kLine, height: 1),
                  const SizedBox(height: 16),
                  // A-62 — the whole property page below all of the above,
                  // from the same component the property detail screen uses.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: PropertyDetailPanels(
                      single: _single,
                      host: _host,
                      reviewCount: _single?.reviewCount ?? 0,
                      // The guest stayed here, so this is where they write the
                      // review — the panel doubles as the review form.
                      experiencesBuilder: () => PropertyReviewSection(
                        propertyId: widget.propertyId,
                        bookingData: widget.bookingData,
                      ),
                      // No host anywhere on a cancelled booking.
                      hidden: _isCancelled ? const {PropertyTab.host} : const {},
                      fallback: PropertyPanelFallback(
                        location: widget
                                .bookingData.bookingPropertyPropertyAddress ??
                            '',
                      ),
                    ),
                  ),
                  const SizedBox(height: 110),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 10,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _isCancelled ? _bookNowBar() : _stayBar(),
            ),
          )
        ],
      ),
    );
  }

  /// The bar for a live booking: reach the host, and get there.
  Widget _stayBar() {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            DeviceService.launchDialPad(_single?.propertyContact ?? "");
          },
          child: Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: kSurface,
              border: Border.all(color: kIndigo),
              borderRadius: BorderRadius.circular(14),
              boxShadow: kSoftShadow,
            ),
            child: const Icon(Icons.phone, size: 22, color: kIndigo),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () async {
              final location = userController.propertyLocation.value;
              DeviceService.showMapOptions(
                  context, location.latitude, location.longitude);
            },
            child: Container(
              height: 52,
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
                    color: kIndigo.withOpacity(0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.directions, color: kCream, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Get Directions",
                    style: inter(
                      color: kCream,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// A cancelled booking gets one action, and it is not about the host.
  Widget _bookNowBar() {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: _bookAgain,
      child: Container(
        height: 52,
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
              color: kIndigo.withOpacity(0.3),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          'Book now',
          style: inter(
              color: kCream, fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  /// A-61 — support, the host chat, and who the host is, under the booking.
  ///
  /// On a cancelled booking only support survives: the spec says no host
  /// details there, and support is the one thing a guest is more likely to
  /// need after a cancellation, not less (a refund is a support question).
  Widget _actions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  icon: Icons.support_agent_outlined,
                  label: 'Support',
                  onTap: () => Get.to(() => const SupportScreen()),
                ),
              ),
              if (!_isCancelled) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _actionButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Chat with host',
                    onTap: _openHostChat,
                  ),
                ),
              ],
            ],
          ),
          if (!_isCancelled) ...[
            const SizedBox(height: 14),
            _hostCard(),
          ],
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: kSurface,
          border: Border.all(color: kLine),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: kIndigo600),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: kInk),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Who the guest is staying with. The same shape as the Host panel below,
  /// deliberately: this one is the summary you get without opening a tab.
  Widget _hostCard() {
    final contact = _single?.propertyContact;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kLine),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: kIndigo,
            backgroundImage: (_host?.image != null)
                ? NetworkImage(_host!.image!)
                : null,
            child: (_host?.image == null)
                ? Text(
                    (_host?.name ?? 'H').trim().characters.first.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hosted by ${_host?.name ?? 'your host'}',
                    style: inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: kInk)),
                const SizedBox(height: 2),
                Text(
                  contact == null || contact.isEmpty
                      ? (_host?.subtitle ?? 'Aajoo host')
                      : contact,
                  style: inter(fontSize: 12, color: kMuted),
                ),
              ],
            ),
          ),
          if (contact != null && contact.isNotEmpty)
            IconButton(
              tooltip: 'Call host',
              onPressed: () => DeviceService.launchDialPad(contact),
              icon: const Icon(Icons.call_outlined, color: kIndigo600),
            ),
        ],
      ),
    );
  }

  /// The listing as the rest of the app models it.
  ///
  /// The booking detail loads a SinglePropertyData; the negotiation chat and
  /// the property page both want a Property. Rather than widen their APIs for
  /// one caller, translate here.
  Property? _propertyModel() {
    final s = _single;
    if (s == null) return null;
    return Property(
      propertyId: s.propertyId ?? widget.propertyId,
      propertyName: s.propertyName ?? '',
      propertyAddress: s.propertyAddress ?? '',
      propertyDesc: s.propertyDesc ?? '',
      propertyPrice: s.propertyPrice ?? '0',
      propertyCity: s.propertyCity ?? '',
      propertyLongitude: s.propertyLongitude ?? '0',
      propertyLatitude: s.propertyLatitude ?? '0',
      propertyHostId: s.propertyHostId ?? 0,
      propertyZip: s.propertyZip,
      propertyContact: s.propertyContact,
      propertyEmail: s.propertyEmail,
      images: s.images ?? const [],
      categoryTitles:
          (s.categories ?? const []).map((c) => c.toString()).toList(),
      amenities: (s.amenities ?? const []).map((a) => a.toString()).toList(),
      rating: s.rating,
      reviewCount: s.reviewCount,
    );
  }

  Future<void> _openHostChat() async {
    final property = _propertyModel();
    if (property == null) {
      Fluttertoast.showToast(msg: 'Still loading this stay — try again.');
      return;
    }
    final token = await const FlutterSecureStorage().read(key: "user_token");
    if (token == null) {
      Fluttertoast.showToast(msg: 'Please login to message the host.');
      return;
    }
    final userId = Get.find<AuthController>().userData.value?.userId;
    if (userId == null) {
      Fluttertoast.showToast(msg: 'Please login to message the host.');
      return;
    }
    if (!mounted) return;
    Get.to(() => PriceNegotiationPage(
          userId: userId.toString(),
          senderId: userId.toString(),
          receiverId: property.propertyHostId.toString(),
          hostId: property.propertyHostId.toString(),
          propertyId: property.propertyId.toString(),
          serverUrl: Apiconstants.serverUrl,
          token: token,
          property: property,
          lat: property.propertyLatitude,
          long: property.propertyLongitude,
        ));
  }

  void _bookAgain() {
    final property = _propertyModel();
    if (property == null) {
      Fluttertoast.showToast(msg: 'Still loading this stay — try again.');
      return;
    }
    Get.to(() => PropertyPage(
          id: property.propertyId,
          image: property.images.isNotEmpty ? property.images.first : '',
          name: property.propertyName,
          price: property.propertyPrice,
          description: property.propertyDesc,
          rating: property.ratingLabel,
          lat: property.propertyLatitude,
          long: property.propertyLongitude,
          location: property.propertyAddress,
          galleryImages: property.images,
          property: property,
        ));
  }

  AppBar _appBar(BuildContext context) {
    return AppBar(
      // "History Description" is the name of a database table, not a thing a
      // guest recognises. It is their booking.
      title: Text('Your booking',
          style:
              fraunces(fontSize: 18, fontWeight: FontWeight.w600, color: kInk)),
      backgroundColor: kCream,
      foregroundColor: kInk,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new),
        onPressed: () {
          // Pop this route directly via the local Navigator (reliable), with
          // Get.back() as a fallback — Get.back() alone was leaving users stuck.
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            Get.back();
          }
        },
      ),
    );
  }

  Widget _buildBookingData(BookingHistoryData booking) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Booking ID: ${booking.bookId}',
          style: fraunces(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: kInk,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _dateTile(
                icon: Icons.login_rounded,
                label: 'CHECK-IN',
                value: booking.bookDetailsBtBookFrom ?? '—',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _dateTile(
                icon: Icons.logout_rounded,
                label: 'CHECK-OUT',
                value: booking.bookDetailsBtBookTo ?? '—',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // What the stay actually cost, and whether it is paid for. The screen
        // showed dates and a status word and nothing else — a guest could not
        // see their own total on their own booking.
        _charges(booking),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // The status badge answers "is this stay on?" and only that; the
            // payment badge answers "has the money arrived?". The stored title
            // used to be whichever one the DB happened to record, so the two
            // badges sometimes said the same thing and sometimes left a
            // question unanswered. See utils/booking_status.dart.
            _statusBadge(lifecycleLabel(
              booking.bookingStatusBsTitle,
              ended: hasEnded(booking.bookDetailsBtBookTo),
              started: isStaying(booking.bookDetailsBtBookFrom,
                  booking.bookDetailsBtBookTo),
            )),
            _payBadge(booking),
          ],
        ),
        // The booking's own actions. This screen showed a pending payment and
        // an upcoming stay and offered no way to act on either — the only
        // cancel/pay UI in the app was on the ongoing screen, which an
        // upcoming booking never reaches.
        if (_owesOnline || _canCancel) ...[
          const SizedBox(height: 14),
          if (_owesOnline) ...[
            _bookingActionButton(
              label: _payBusy
                  ? 'Starting payment…'
                  : (_stayOver ? 'Pay online now' : 'Pay online instead'),
              icon: Icons.payment_rounded,
              filled: true,
              onTap: _payBusy ? null : _payNow,
            ),
            const SizedBox(height: 6),
            Text(
              _stayOver
                  ? 'You chose to pay at the property. You can still settle it here — '
                      'you get a receipt, and the host is paid through Aajoo.'
                  : 'You chose to pay at the property. Paying here instead is safer '
                      'for both of you — no cash on the day, and a receipt for it.',
              style: inter(fontSize: 11.5, color: kMuted, height: 1.45),
            ),
            const SizedBox(height: 8),
          ],
          if (_canCancel)
            _bookingActionButton(
              label: 'Cancel booking',
              icon: Icons.cancel_outlined,
              filled: false,
              danger: true,
              onTap: _showCancelDialog,
            ),
        ],
      ],
    );
  }

  /// The booking's own actions (Pay now / Cancel) — filled or outlined, and
  /// distinct from the neutral Support / Chat tiles further down.
  Widget _bookingActionButton({
    required String label,
    required IconData icon,
    required bool filled,
    bool danger = false,
    VoidCallback? onTap,
  }) {
    final color = danger ? kDanger : kIndigo;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? color : Colors.transparent,
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: filled ? kCream : color),
            const SizedBox(width: 8),
            Text(label,
                style: inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: filled ? kCream : color)),
          ],
        ),
      ),
    );
  }

  // ── Cancel ────────────────────────────────────────────────────────────────

  Future<void> _showCancelDialog() async {
    // Ask what this would refund BEFORE the dialog, so the figure is on the
    // screen where the decision is made. The app used to cancel and only then
    // let the guest discover what they got back.
    final bookId = widget.bookingData.bookId;
    CancellationQuote? quote;
    if (bookId != null) {
      quote = await _bookingController.cancellationQuote(bookId);
    }
    if (!mounted) return;

    // The server says a cancel is impossible (checked in, completed, past the
    // window). Say so instead of opening a dialog that cannot succeed.
    if (quote != null && !quote.canCancel) {
      Fluttertoast.showToast(
          msg: quote.reason ?? 'This booking can no longer be cancelled.');
      return;
    }

    String? selectedReason;
    final otherReasonController = TextEditingController();
    // Same presets as the website, so the stored reasons stay comparable.
    const reasons = [
      'Plans changed',
      'Found somewhere else',
      'Booked by mistake',
      'Trip cancelled',
      'Other',
    ];
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: kSurface,
          title: Text('Cancel this booking?',
              style: fraunces(
                  fontSize: 18, fontWeight: FontWeight.w700, color: kInk)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Please tell us why — this is shared with the host.',
                    style: inter(fontSize: 13, color: kMuted)),
                const SizedBox(height: 6),
                ...reasons.map((reason) => RadioListTile<String>(
                      title: Text(reason, style: inter(fontSize: 14)),
                      value: reason,
                      groupValue: selectedReason,
                      activeColor: kprimaryColor,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      onChanged: (value) =>
                          setDialogState(() => selectedReason = value),
                    )),
                if (selectedReason == 'Other')
                  TextField(
                    controller: otherReasonController,
                    decoration: const InputDecoration(
                        hintText: 'Please specify the reason'),
                  ),
                const SizedBox(height: 10),
                if (quote == null)
                  // The quote call failed. Do not invent a number.
                  Text('Refunds follow the cancellation policy for this stay.',
                      style: inter(fontSize: 12, color: kMuted))
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kCream,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kInk.withOpacity(.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (quote.policyLabel != null)
                          Text(quote.policyLabel!,
                              style: inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: kInk)),
                        const SizedBox(height: 4),
                        Text(
                          !quote.isPaid
                              ? 'Nothing has been charged for this booking yet, so there is nothing to refund.'
                              : quote.manualReview
                                  ? 'Your refund will be reviewed by our team and confirmed to you.'
                                  : 'You would get back ${rupees(quote.refundAmount)}'
                                      '${quote.refundPercent > 0 ? ' (${quote.refundPercent}% of what you paid)' : ''}.',
                          style: inter(fontSize: 13, color: kInk, height: 1.45),
                        ),
                        if (quote.policySummary != null) ...[
                          const SizedBox(height: 4),
                          Text(quote.policySummary!,
                              style: inter(fontSize: 12, color: kMuted, height: 1.4)),
                        ],
                        if (quote.refundNote != null) ...[
                          const SizedBox(height: 4),
                          Text(quote.refundNote!,
                              style: inter(fontSize: 12, color: kMuted, height: 1.4)),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Keep booking',
                  style: TextStyle(color: kprimaryColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: kDanger, foregroundColor: Colors.white),
              onPressed: () async {
                if (selectedReason == null) {
                  Fluttertoast.showToast(msg: 'Please select a reason');
                  return;
                }
                var finalReason = selectedReason!;
                if (selectedReason == 'Other') {
                  if (otherReasonController.text.trim().isEmpty) {
                    Fluttertoast.showToast(msg: 'Please specify the reason');
                    return;
                  }
                  finalReason = otherReasonController.text.trim();
                }
                Navigator.of(dialogContext).pop();
                await _cancelBooking(finalReason);
              },
              child: const Text('Cancel booking'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelBooking(String reason) async {
    final bookId = widget.bookingData.bookId;
    if (bookId == null) return;
    final ok = await _bookingController.cancelBooking(bookId, reason);
    if (!mounted) return;
    if (ok) {
      // Flip the local model so the page redraws as cancelled (badge + Book
      // now bar) without a refetch; the list behind refreshes for real.
      setState(() => widget.bookingData.bookingStatusBsTitle = 'Cancelled');
      userController.getUserHistory();
      Fluttertoast.showToast(msg: 'Booking cancelled');
    }
    // Failure already surfaced by the controller's alert.
  }

  // ── Pay now ───────────────────────────────────────────────────────────────

  Future<void> _payNow() async {
    final bookId = widget.bookingData.bookId;
    if (bookId == null) return;
    setState(() => _payBusy = true);
    try {
      final order = await _bookingController.createOngoingBookingPayment(bookId);
      final orderId = order['data']?['order']?['id'];
      if (orderId == null) {
        Fluttertoast.showToast(msg: 'Failed to create payment order');
        return;
      }
      final fallbackPaise =
          ((widget.bookingData.bookTotalAmt ?? 0) * 100).round();
      final amountInPaise = order['data']?['order']?['amount'] ?? fallbackPaise;
      final auth = Get.find<AuthController>();
      _razorpay.open({
        'key': PaymentConfig.razorpayKey,
        'amount': amountInPaise,
        'currency': 'INR',
        'name': 'Aajoo Homes',
        'description': 'Payment for booking $bookId',
        'order_id': orderId,
        'prefill': {
          'contact': auth.userData.value?.phoneNumber ?? '',
          'email': auth.userData.value?.email ?? '',
          'name': auth.userData.value?.fullName ?? '',
        },
      });
    } catch (e) {
      Fluttertoast.showToast(msg: 'Could not start the payment. Try again.');
    } finally {
      if (mounted) setState(() => _payBusy = false);
    }
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    final ok = await _bookingController.verifyPayment(
        response.orderId!, response.paymentId!, response.signature!);
    if (!mounted) return;
    if (ok) {
      setState(() => widget.bookingData.bookIsPaid = true);
      userController.getUserHistory();
      Fluttertoast.showToast(msg: 'Payment successful');
    } else {
      Fluttertoast.showToast(
          msg: 'Payment received but not yet confirmed — contact support.');
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    Fluttertoast.showToast(
        msg: 'Payment failed: ${response.message ?? 'cancelled'}');
  }

  String _rupees(num? v) => v == null
      ? '—'
      : '₹${v.toStringAsFixed(v % 1 == 0 ? 0 : 2).replaceAllMapped(RegExp(r'(\d)(?=(\d{2})+(\d)(?!\d))'), (m) => '${m[1]},')}';

  Widget _charges(BookingHistoryData booking) {
    final room = booking.book_price is num
        ? (booking.book_price as num)
        : double.tryParse('${booking.book_price ?? ''}');
    final total = booking.bookTotalAmt;
    // Tax is not sent on this endpoint; derive it only when both ends are
    // known, so nothing is invented.
    final tax = (total != null && room != null) ? total - room : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: kSand,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _chargeRow('Room charge', _rupees(room)),
          if (tax != null && tax > 0) ...[
            const SizedBox(height: 6),
            _chargeRow('Taxes & fees', _rupees(tax)),
          ],
          if (booking.bookNoOfGuests != null) ...[
            const SizedBox(height: 6),
            _chargeRow('Guests', '${booking.bookNoOfGuests}'),
          ],
          const SizedBox(height: 8),
          const Divider(color: kLine, height: 1),
          const SizedBox(height: 8),
          _chargeRow('Total', _rupees(total ?? room), bold: true),
        ],
      ),
    );
  }

  Widget _chargeRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: inter(
                fontSize: bold ? 13 : 12.5,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: bold ? kInk : kMuted)),
        Text(value,
            style: inter(
                fontSize: bold ? 14 : 12.5,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                color: kInk)),
      ],
    );
  }

  String _payLabel(BookingHistoryData booking) => booking.bookIsPaid
      ? 'Paid'
      : (booking.bookIsCod ? 'Pay at property' : 'Payment pending');

  Widget _payBadge(BookingHistoryData booking) {
    final paid = booking.bookIsPaid;
    final label = _payLabel(booking);
    final color = paid ? kSuccess : (booking.bookIsCod ? kIndigo : kDanger);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _dateTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kSand,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: kIndigo),
              const SizedBox(width: 5),
              Text(
                label,
                style: inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: kMuted,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            softWrap: true,
            style: inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: kInk,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final s = status.toLowerCase();
    final bool positive = s.contains('paid') ||
        s.contains('confirm') ||
        s.contains('complete') ||
        s.contains('success');
    final bool pending = s.contains('pending') || s.contains('await');
    final Color c = positive ? kSuccess : (pending ? kClay : kIndigo);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: c),
          const SizedBox(width: 6),
          Text(
            status,
            style: inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: c,
            ),
          ),
        ],
      ),
    );
  }
}
