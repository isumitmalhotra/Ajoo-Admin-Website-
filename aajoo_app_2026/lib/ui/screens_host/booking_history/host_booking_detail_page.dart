import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/data/ApiConstants.dart';
import 'package:rent_home/models/host_booking_history_model.dart';
import 'package:rent_home/models/properties_response_model.dart';
import 'package:rent_home/models/single_property_response.dart';
import 'package:rent_home/service/device_service.dart';
import 'package:rent_home/service/property_service.dart';
import 'package:rent_home/ui/screens_common/auth/auth_controller.dart';
import 'package:rent_home/ui/screens_common/price_negotiation/negotitaion_page.dart';
import 'package:rent_home/ui/screens_host/support/host_support_screen.dart';
import 'package:rent_home/ui/screens_renter/property_details/components/property_tabs.dart';
import 'package:rent_home/utils/fonts.dart';

/// One of the host's bookings, opened from the Bookings list (A-68/A-69).
///
/// Deliberately the mirror of the guest's booking detail: same shape, same
/// seven property panels from PropertyDetailPanels, with the guest in the slot
/// where the guest sees the host. A host looking at a booking had nowhere to
/// go before this — the card showed a name and a phone number and that was
/// the end of it.
class HostBookingDetailPage extends StatefulWidget {
  final HostBookingHistory booking;
  const HostBookingDetailPage({super.key, required this.booking});

  @override
  State<HostBookingDetailPage> createState() => _HostBookingDetailPageState();
}

class _HostBookingDetailPageState extends State<HostBookingDetailPage> {
  final PropertyService _propertyService = PropertyService();
  SinglePropertyData? _single;
  bool _loading = true;

  HostBookingHistory get b => widget.booking;

  bool get _isCancelled =>
      b.bookingStatusBsTitle.toLowerCase().contains('cancel');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // 0 means the server has not been deployed with the widened booking query
    // yet. Without a property id there is nothing to fetch; the booking facts
    // above still render, so the page is useful rather than broken.
    if (b.bookPropId == 0) {
      setState(() => _loading = false);
      return;
    }
    try {
      final resp = await _propertyService.getSingleProperty(b.bookPropId);
      if (!mounted) return;
      setState(() {
        _single = resp.data;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kscaffoldColor,
      appBar: AppBar(
        backgroundColor: kCream,
        foregroundColor: kInk,
        elevation: 0,
        centerTitle: true,
        title: Text('Booking #${b.bookId}',
            style: fraunces(
                fontSize: 17, fontWeight: FontWeight.w600, color: kInk)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _stayCard(),
          const SizedBox(height: 16),
          _actions(),
          if (!_isCancelled) ...[
            const SizedBox(height: 14),
            _guestCard(),
          ],
          const SizedBox(height: 18),
          const Divider(color: kLine, height: 1),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(color: kIndigo)),
            )
          else if (b.bookPropId == 0)
            Text(
              'Property details are unavailable for this booking.',
              style: inter(fontSize: 13.5, color: kMuted),
            )
          else
            // The same seven panels the guest sees, from the same component —
            // the host is looking at their own listing as a guest would.
            PropertyDetailPanels(
              single: _single,
              reviewCount: _single?.reviewCount ?? 0,
              hidden: const {PropertyTab.host},
              fallback: PropertyPanelFallback(
                location: b.propertyAddress,
              ),
            ),
        ],
      ),
    );
  }

  Widget _stayCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (b.propertyName.isNotEmpty) ...[
            Text(b.propertyName,
                style: fraunces(
                    fontSize: 17, fontWeight: FontWeight.w700, color: kInk)),
            if (b.propertyAddress.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(b.propertyAddress,
                  style: inter(fontSize: 12.5, color: kMuted)),
            ],
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              Expanded(
                  child: _fact('CHECK-IN', b.bookDetailsBtBookFrom.isEmpty
                      ? '—'
                      : b.bookDetailsBtBookFrom)),
              const SizedBox(width: 10),
              Expanded(
                  child: _fact('CHECK-OUT', b.bookDetailsBtBookTo.isEmpty
                      ? '—'
                      : b.bookDetailsBtBookTo)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _fact('AMOUNT',
                      '₹ ${(b.bookTotalAmt > 0 ? b.bookTotalAmt : b.bookPrice).toStringAsFixed(0)}')),
              const SizedBox(width: 10),
              Expanded(
                  // The METHOD, not the state. This said "Paid online" on a
                  // booking whose status badge two rows below read "Payment
                  // Pending" — the tile describes how they chose to pay, and
                  // saying "Paid" for an unpaid booking is the kind of
                  // flattering-but-wrong label this sheet keeps turning up.
                  child: _fact('PAYMENT',
                      b.bookIsCod ? 'Pay on arrival' : 'Online')),
            ],
          ),
          if (b.bookNoOfGuests > 0) ...[
            const SizedBox(height: 10),
            _fact('GUESTS', '${b.bookNoOfGuests}'),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Text('Invoice ${b.bookInvoice}',
                  style: inter(fontSize: 12, color: kMuted)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: kIndigo50,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(b.bookingStatusBsTitle.trim(),
                    style: inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: kIndigo600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fact(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kSand,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: kMuted,
                  letterSpacing: 0.8)),
          const SizedBox(height: 4),
          Text(value,
              style: inter(
                  fontSize: 14, fontWeight: FontWeight.w700, color: kInk)),
        ],
      ),
    );
  }

  /// Support, and the guest. Mirrors the guest's own booking page: on a
  /// cancelled booking the guest is not shown at all, and support remains.
  Widget _actions() {
    return Row(
      children: [
        Expanded(
          child: _button(
            icon: Icons.support_agent_outlined,
            label: 'Support',
            onTap: () => Get.to(() => const HostSupportScreen()),
          ),
        ),
        if (!_isCancelled) ...[
          const SizedBox(width: 10),
          Expanded(
            child: _button(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Chat with guest',
              onTap: _openGuestChat,
            ),
          ),
        ],
      ],
    );
  }

  Widget _button({
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
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: kInk)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _guestCard() {
    final guest = b.userDetailsUserFullName.trim();
    final name = guest.isEmpty ? 'Guest' : guest;
    final phone = b.userDetailsUserPnumber.trim();
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
            child: Text(
              name.characters.first.toUpperCase(),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: kInk)),
                const SizedBox(height: 2),
                Text(phone.isEmpty ? 'Your guest' : phone,
                    style: inter(fontSize: 12, color: kMuted)),
              ],
            ),
          ),
          if (phone.isNotEmpty)
            IconButton(
              tooltip: 'Call guest',
              onPressed: () => DeviceService.launchDialPad(phone),
              icon: const Icon(Icons.call_outlined, color: kIndigo600),
            ),
        ],
      ),
    );
  }

  /// The negotiation thread for this property — the same conversation the
  /// guest sees from their side, not a second messaging system.
  Future<void> _openGuestChat() async {
    if (b.bookPropId == 0 || b.bookUserId == 0) {
      Fluttertoast.showToast(
          msg: 'Guest details are unavailable for this booking.');
      return;
    }
    final token = await const FlutterSecureStorage().read(key: "user_token");
    if (token == null) {
      Fluttertoast.showToast(msg: 'Please login again to message the guest.');
      return;
    }
    final hostId = Get.find<AuthController>().userData.value?.userId;
    if (hostId == null) {
      Fluttertoast.showToast(msg: 'Please login again to message the guest.');
      return;
    }
    final s = _single;
    final property = Property(
      propertyId: b.bookPropId,
      propertyName: s?.propertyName ?? b.propertyName,
      propertyAddress: s?.propertyAddress ?? b.propertyAddress,
      propertyDesc: s?.propertyDesc ?? '',
      propertyPrice: s?.propertyPrice ?? b.bookPrice.toStringAsFixed(0),
      propertyCity: s?.propertyCity ?? '',
      propertyLongitude: s?.propertyLongitude ?? '0',
      propertyLatitude: s?.propertyLatitude ?? '0',
      propertyHostId: hostId,
      propertyZip: s?.propertyZip,
      images: s?.images ?? const [],
      categoryTitles: const [],
    );
    if (!mounted) return;
    Get.to(() => PriceNegotiationPage(
          // The host is the sender here; the guest is on the other end.
          userId: hostId.toString(),
          senderId: hostId.toString(),
          receiverId: b.bookUserId.toString(),
          hostId: hostId.toString(),
          propertyId: b.bookPropId.toString(),
          serverUrl: Apiconstants.serverUrl,
          token: token,
          property: property,
          lat: property.propertyLatitude,
          long: property.propertyLongitude,
        ));
  }
}
