import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/ui/design/amount_breakdown.dart';
import 'package:rent_home/ui/screens_renter/property_details/components/stay_map.dart';
import 'package:rent_home/utils/fonts.dart';

/// Booking confirmed.
///
/// This was a dialog. Two problems with that: it showed no map — so the one
/// screen where a guest most wants to see where they are going had only a
/// button that threw them out to the Google Maps app — and being a dialog it
/// depended on the property page's BuildContext still being mounted when
/// Razorpay handed control back, which is why the confirmation sometimes did
/// not appear at all on a card payment.
///
/// A route has neither problem. It is pushed with Get.to, so it survives the
/// payment sheet closing, and it has room for the map, the stay dates and what
/// happens next.
class BookingConfirmedScreen extends StatelessWidget {
  final String bookingId;
  final String paymentId;
  final String propertyName;
  final String? address;
  final double? lat;
  final double? lng;
  final String? checkIn;
  final String? checkOut;
  final String? amount;

  /// The charges behind [amount]. When these are supplied the screen shows the
  /// breakdown rather than a bare figure — a guest reading "₹4,200 due at the
  /// property" on the one screen that confirms their booking should be able to
  /// see what the ₹4,200 is made of without going looking for it.
  final double? roomCharge;
  final double? extras;
  final double? taxes;
  final double? discount;
  final double? total;

  /// Pay-on-arrival bookings are confirmed but not paid; say which.
  final bool isPayOnArrival;

  /// The host still has to approve this. Passed through from the booking
  /// response's `requiresApproval`.
  final bool awaitingApproval;

  /// Hours the host has to respond — their own configured window.
  final int responseHours;

  const BookingConfirmedScreen({
    super.key,
    required this.bookingId,
    this.paymentId = '',
    this.propertyName = '',
    this.address,
    this.lat,
    this.lng,
    this.checkIn,
    this.checkOut,
    this.amount,
    this.roomCharge,
    this.extras,
    this.taxes,
    this.discount,
    this.total,
    this.isPayOnArrival = false,
    this.awaitingApproval = false,
    this.responseHours = 24,
  });

  void _goHome() => Get.offAllNamed('/home');

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Backing out to the booking sheet would invite a second booking of a
      // stay that is already paid for.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goHome();
      },
      child: Scaffold(
        backgroundColor: kCream,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: kSuccess,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: kSuccess.withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8)),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 40, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              // A host who chose "Approval Required" reviews the request
              // first. Telling the guest their stay was "all set" while the
              // host had not yet seen it was simply untrue.
              Text(awaitingApproval ? 'Request sent!' : 'Booking Confirmed!',
                  textAlign: TextAlign.center,
                  style: fraunces(
                      fontSize: 23, fontWeight: FontWeight.w700, color: kInk)),
              const SizedBox(height: 6),
              Text(
                awaitingApproval
                    ? 'Your request has gone to the host. They have $responseHours hours to respond, and you\'ll be told either way.'
                    : isPayOnArrival
                        ? 'Your stay is reserved. Pay when you arrive.'
                        : 'Your stay is all set. A confirmation is on its way to your email.',
                textAlign: TextAlign.center,
                style: inter(fontSize: 13, color: kMuted, height: 1.45),
              ),
              const SizedBox(height: 20),

              // Booking reference
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: kIndigo50, borderRadius: BorderRadius.circular(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Booking ID',
                        style: inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: kIndigo600)),
                    const SizedBox(height: 2),
                    Text(bookingId,
                        style: fraunces(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: kInk)),
                    if (paymentId.isNotEmpty && paymentId != 'N/A') ...[
                      const SizedBox(height: 6),
                      Text('Payment: $paymentId',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: inter(fontSize: 11, color: kMuted)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // The stay itself
              if (propertyName.isNotEmpty ||
                  checkIn != null ||
                  amount != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kLine),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (propertyName.isNotEmpty) ...[
                        Text(propertyName,
                            style: inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: kInk)),
                        if (address != null && address!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(address!,
                              style: inter(fontSize: 12, color: kMuted)),
                        ],
                        const SizedBox(height: 10),
                      ],
                      if (checkIn != null || checkOut != null)
                        _row(Icons.calendar_today_outlined,
                            [checkIn, checkOut].whereType<String>().join('  →  ')),
                      if (total != null && roomCharge != null) ...[
                        const SizedBox(height: 12),
                        AmountBreakdown(
                          roomCharge: roomCharge!,
                          extras: extras ?? 0,
                          taxes: taxes,
                          discount: discount ?? 0,
                          total: total!,
                          dense: true,
                          totalLabel:
                              isPayOnArrival ? 'Total due' : 'Total paid',
                          footnote: isPayOnArrival
                              ? 'Due at the property on arrival'
                              : null,
                        ),
                      ] else if (amount != null) ...[
                        const SizedBox(height: 8),
                        _row(
                            Icons.currency_rupee,
                            isPayOnArrival
                                ? '$amount — due at the property'
                                : '$amount paid'),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Where you're going.
              Text('Getting there',
                  style: fraunces(
                      fontSize: 16, fontWeight: FontWeight.w600, color: kInk)),
              const SizedBox(height: 10),
              StayMap(lat: lat, lng: lng, label: propertyName, height: 200),

              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: _goHome,
                style: OutlinedButton.styleFrom(
                    foregroundColor: kInk,
                    side: const BorderSide(color: kLine),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: Text('Go to Home',
                    style: inter(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 16, color: kMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: inter(fontSize: 13, color: kInk)),
          ),
        ],
      );
}
