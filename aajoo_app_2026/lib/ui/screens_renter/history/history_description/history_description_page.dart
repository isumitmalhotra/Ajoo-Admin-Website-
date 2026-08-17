import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/controller/user_controller.dart';
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
  final PropertyReviewController propertyController =
      Get.put<PropertyReviewController>(
    PropertyReviewController(),
  );
  final reviewController = TextEditingController();
  final PropertyService _propertyService = PropertyService();
  double rating = 0.0;

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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await userController.getProperty(widget.propertyId);
      if (!mounted) return;
      await _fetchHost();
    });
    propertyController.getPropertyReviews(widget.propertyId);
  }

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
            _statusBadge(booking.bookingStatusBsTitle ?? 'Unknown'),
            // Only when it says something the status doesn't already say —
            // "Paid" beside "Paid" is two badges carrying one fact.
            if (_payLabel(booking).toLowerCase() !=
                (booking.bookingStatusBsTitle ?? '').trim().toLowerCase())
              _payBadge(booking),
          ],
        ),
      ],
    );
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
