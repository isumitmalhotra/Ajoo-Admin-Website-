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
import 'package:rent_home/service/host_service.dart';
import 'package:rent_home/utils/stay_clock.dart';
import 'package:rent_home/ui/screens_common/auth/auth_controller.dart';
import 'package:rent_home/ui/screens_common/price_negotiation/negotitaion_page.dart';
import 'package:rent_home/ui/screens_host/support/host_support_screen.dart';
import 'package:rent_home/ui/screens_renter/property_details/components/property_tabs.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/utils/booking_status.dart';
import 'package:rent_home/ui/screens_host/booking_history/widgets/staying_guest_card.dart';
import 'package:rent_home/utils/money.dart';

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

  bool get _isCheckedIn {
    final t = b.bookingStatusBsTitle.toLowerCase();
    return t.contains('check in') || t.contains('check-in');
  }

  /// Offer Check-in from the START OF THE CHECK-IN DAY until checkout.
  ///
  /// Deliberately NOT isStaying(), which only turns true at the 14:00 check-in
  /// hour: a guest who arrives at noon could then be checked in from the
  /// website (which allows it from midnight) and from the API (same rule), but
  /// not from the phone in the host's hand. Same rule everywhere.
  /// A booking still waiting on this host.
  ///
  /// "Pending"/"Payment Pending" is what a request looks like before the host
  /// accepts it — and nearly every listing needs accepting, because only 8 of
  /// 29,252 properties carry booking rules and the backend defaults the rest
  /// to approval.
  /// The lifecycle label this booking is showing right now.
  ///
  /// Derived, not raw: a request waiting on the host carries the bare status
  /// "Booked" (5) and only lifecycleLabel turns that into "Awaiting approval"
  /// — see utils/booking_status.dart, which documents "Booked" as the state a
  /// request waits in FOR that approval. Matching the raw title instead is how
  /// the first version of this button never appeared.
  String get _stage => lifecycleLabel(
        b.bookingStatusBsTitle,
        ended: hasEnded(b.bookDetailsBtBookTo),
        started: isStaying(b.bookDetailsBtBookFrom, b.bookDetailsBtBookTo),
      );

  bool get _needsApproval =>
      b.bookPriId != null && _stage == 'Awaiting approval';

  Future<void> _confirmBooking() async {
    final id = b.bookPriId;
    if (_confirming || id == null) return;
    setState(() => _confirming = true);
    try {
      await HostService().confirmBooking(id);
      // Same trick as check-in: update the chip so the page tells the truth
      // without a refetch.
      setState(() => b.bookingStatusBsTitle = 'Booking Confirmed');
      Fluttertoast.showToast(
          msg: "Booking confirmed — the guest has been told.");
    } catch (e) {
      Fluttertoast.showToast(
          msg: e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  /// A booking this host can still call off: live, not already checked in,
  /// not already cancelled.
  /// A live booking the host can still call off. Uses the same derived stage,
  /// so the two buttons can never disagree about what state this is in.
  bool get _canHostCancel {
    const live = {'Awaiting approval', 'Confirmed', 'Payment pending'};
    return live.contains(_stage);
  }

  Future<void> _hostCancel() async {
    if (_cancelling) return;
    final reason = await _askCancelReason();
    // Empty means they backed out — the backend requires a reason anyway.
    if (reason == null || reason.trim().isEmpty) return;
    setState(() => _cancelling = true);
    try {
      await HostService().cancelBooking(b.bookId, reason.trim());
      setState(() => b.bookingStatusBsTitle = 'Cancelled');
      Fluttertoast.showToast(
          msg: "Booking cancelled — the guest has been told why.");
    } catch (e) {
      Fluttertoast.showToast(
          msg: e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  /// The guest is told this verbatim, so it is typed rather than picked from
  /// presets — a host's reason for calling off a stay is specific.
  Future<String?> _askCancelReason() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        // The refusal is shown UNDER the field, not thrown as a toast.
        //
        // An empty reason used to be refused with a Fluttertoast, which on
        // Android renders behind the dialog scrim and is gone in two seconds —
        // so pressing "Cancel booking" looked like a dead button. Every other
        // form in this app marks the field itself; this one does now too.
        String? problem;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            backgroundColor: Colors.white,
            title: Text('Cancel this booking?',
                style: fraunces(fontSize: 17, fontWeight: FontWeight.w700)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The guest is refunded under the property policy and told why. '
                  'Please give them a reason.',
                  style: inter(fontSize: 13, color: kMuted, height: 1.45),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: controller,
                  maxLength: 255,
                  maxLines: 3,
                  minLines: 2,
                  onChanged: (_) {
                    if (problem != null) setDialogState(() => problem = null);
                  },
                  decoration: InputDecoration(
                    hintText:
                        'e.g. an unexpected repair has made the place unusable',
                    border: const OutlineInputBorder(),
                    errorText: problem,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Keep booking'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: kDanger, foregroundColor: Colors.white),
                onPressed: () {
                  if (controller.text.trim().isEmpty) {
                    setDialogState(() =>
                        problem = 'Please give the guest a reason.');
                    return;
                  }
                  Navigator.of(ctx).pop(controller.text);
                },
                child: const Text('Cancel booking'),
              ),
            ],
          ),
        );
      },
    );
  }

  /// The states the SERVER will accept a check-in for.
  ///
  /// markBookingCheckIn refuses anything outside paid / booked / confirmed —
  /// you cannot walk a guest in on a booking nobody has paid for and no host
  /// has approved. The button used to be offered on the dates alone, so it
  /// appeared on a Payment Pending stay and answered a tap with "Booking not
  /// found or not eligible for check-in" in a toast the host would not catch.
  /// Better not to offer the action than to offer one that cannot work.
  static const _checkInStatuses = {'paid', 'booked', 'booking confirmed'};

  bool get _canCheckIn {
    if (_isCancelled || _isCheckedIn) return false;
    final title = (b.bookingStatusBsTitle ?? '').trim().toLowerCase();
    if (!_checkInStatuses.contains(title)) return false;
    final from = parseStayDate(b.bookDetailsBtBookFrom);
    if (from == null) return false;
    final today = DateTime.now();
    final startedToday = !DateTime(from.year, from.month, from.day)
        .isAfter(DateTime(today.year, today.month, today.day));
    return startedToday && !hasEnded(b.bookDetailsBtBookTo);
  }

  bool _checkingIn = false;
  bool _confirming = false;
  bool _cancelling = false;

  Future<void> _markCheckedIn() async {
    if (_checkingIn) return;
    setState(() => _checkingIn = true);
    try {
      await HostService().markBookingCheckIn(b.bookId);
      // The status chip above reads from the model; update it so the page
      // tells the truth without a refetch.
      setState(() => b.bookingStatusBsTitle = 'Check In');
      Fluttertoast.showToast(
          msg: "Guest checked in — they've been sent a welcome note.");
    } catch (e) {
      // A failure here is worth reading — it names a state the host has to act
      // on — so it does not go out as a toast.
      if (mounted) {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Text("Couldn't check the guest in",
                style: fraunces(fontSize: 17, fontWeight: FontWeight.w700)),
            content: Text(e.toString().replaceFirst('Exception: ', ''),
                style: inter(fontSize: 13.5, height: 1.45)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _checkingIn = false);
    }
  }

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
                  child: _fact(
                      'AMOUNT',
                      // Grouped like every other price in the app: this read
                      // "₹ 5250" beside a list card saying "₹ 5,250".
                      rupees(b.bookTotalAmt > 0
                          ? b.bookTotalAmt
                          : b.bookPrice))),
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
                // Lifecycle only — the money gets its own chip beside it, so
                // neither question is answered by guessing at the other.
                child: Text(
                    lifecycleLabel(b.bookingStatusBsTitle,
                        ended: hasEnded(b.bookDetailsBtBookTo),
                        started: isStaying(b.bookDetailsBtBookFrom,
                            b.bookDetailsBtBookTo)),
                    style: inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: kIndigo600)),
              ),
              const SizedBox(width: 6),
              Builder(builder: (_) {
                final pay =
                    paymentBadge(isPaid: b.bookIsPaid, isCod: b.bookIsCod);
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: pay.bg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(pay.label,
                      style: inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: pay.fg)),
                );
              }),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Who is actually turning up, when the booking was made for somebody
        // other than the account holder. Renders nothing otherwise.
        StayingGuestCard(bookingId: b.bookId),
        // Approve the request. The web has always had this; the app had no
        // way to accept a booking at all, so a host working from the phone
        // could not complete the loop.
        if (_needsApproval) ...[
          ElevatedButton.icon(
            onPressed: _confirming ? null : _confirmBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: kIndigo,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: Text(_confirming ? 'Confirming…' : 'Confirm this booking',
                style: inter(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 10),
        ],
        if (_canCheckIn) ...[
          // The arrival control the host portal never had: one tap says
          // "the guest is here", flips the booking to Check In everywhere
          // (both apps read it as "Staying now") and thanks the guest by
          // email.
          ElevatedButton.icon(
            onPressed: _checkingIn ? null : _markCheckedIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: kIndigo,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.meeting_room_outlined, size: 18),
            label: Text(
                _checkingIn ? 'Checking in…' : 'Mark guest as checked-in',
                style: inter(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 10),
        ],
        // Calling off a stay — the counterpart of Confirm. The web has had it
        // all along; the app could only check a guest in.
        if (_canHostCancel) ...[
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: _cancelling ? null : _hostCancel,
            style: TextButton.styleFrom(foregroundColor: kDanger),
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: Text(_cancelling ? 'Cancelling…' : 'Cancel this booking',
                style: inter(fontSize: 13.5, fontWeight: FontWeight.w600)),
          ),
        ],
        _actionsRow(),
      ],
    );
  }

  Widget _actionsRow() {
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
