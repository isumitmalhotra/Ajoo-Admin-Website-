import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/ui/screens_renter/property_details/components/stay_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/ui/design/amount_breakdown.dart';
import 'package:rent_home/utils/money.dart';
import 'package:rent_home/constants/payment_config.dart';
import 'package:rent_home/ui/screens_renter/booking_controller.dart';
import 'package:rent_home/controller/user_controller.dart';
import 'package:rent_home/ui/screens_common/auth/auth_controller.dart';
import 'package:rent_home/data/models/ongoing_reponse.dart';
import 'package:rent_home/ui/screens_renter/checkout/checkout_page.dart';
import 'package:rent_home/service/device_service.dart';
import 'package:rent_home/utils/support_chat.dart';

// Assuming BookingHistoryData is defined as provided
class OngoingBookingView extends StatefulWidget {
  final Booking booking;

  const OngoingBookingView({super.key, required this.booking});

  @override
  State<OngoingBookingView> createState() => _OngoingBookingViewState();
}

class _OngoingBookingViewState extends State<OngoingBookingView> {
  late Razorpay razorpay;
  late BookingController bookingController;
  final userController = Get.put(UserController());
  final authController = Get.find<AuthController>();
  RxBool isLocationLoading = false.obs;
  @override
  void initState() {
    super.initState();
    bookingController = Get.put<BookingController>(BookingController());
    razorpay = Razorpay();
    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      userController.getProperty(widget.booking.bookingPropertyPropertyId);
    });
  }

  @override
  Widget build(BuildContext context) {
    print(widget.booking.bookingStatusBsTitle);
    return Scaffold(
      backgroundColor: kSand,
      // Was a solid teal slab with white-on-teal text — the pre-redesign
      // header. Every other booking surface (My Bookings, the confirmation
      // screen, Help & Support) sits on Warm Ivory and spends teal on the
      // accent only; this is the same treatment, nothing else touched.
      appBar: AppBar(
        foregroundColor: kInk,
        title: Text(
          'Booking Details',
          style:
              fraunces(fontSize: 18, fontWeight: FontWeight.w700, color: kInk),
        ),
        backgroundColor: kSand,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        child: Obx(() {
          final property = userController.property.value;
          final images = property?.data?.images;
          final imageUrl =
              (images != null && images.isNotEmpty) ? images.first : null;

          return userController.isLoading.value
              ? SizedBox(
                  height: MediaQuery.of(context).size.height - 100,
                  width: MediaQuery.of(context).size.width,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(child: CircularProgressIndicator()),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Property Name
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            kprimaryColor,
                            kprimaryColor.withOpacity(0.9)
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Stack(
                        // crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          imageUrl != null
                              ? Image.network(
                                  imageUrl,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Image.asset(
                                  "assets/home_2.jpg",
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),

                          //overlay
                          Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                colors: [
                                  Colors.black.withOpacity(0.3),
                                  Colors.black.withOpacity(0.8),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ))),
                          SizedBox(
                            height: 200,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Text(
                                    widget.booking.bookingPropertyPropertyName,
                                    style: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        color: Colors.white70,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        widget.booking
                                            .bookingPropertyPropertyName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Booking Details Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: kprimaryColor,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Booking Details',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Booking Info Grid
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMinimalDetailItem(
                                      'Booking ID',
                                      widget.booking.bookId,
                                      Icons.tag,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildMinimalDetailItem(
                                      'Status',
                                      widget.booking.bookingStatusBsTitle,
                                      Icons.info_outline,
                                      isStatus: true,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              _buildMinimalDetailItem(
                                'Invoice',
                                widget.booking.bookInvoice,
                                Icons.receipt_outlined,
                              ),
                              const SizedBox(height: 14),
                              // The total, with the breakdown that makes it
                              // checkable.
                              //
                              // This was a tile reading "Amount ₹4,000" —
                              // `book_price`, the PRE-TAX room subtotal — for
                              // a booking whose confirmation screen had just
                              // said ₹4,200. Same stay, two numbers, neither
                              // labelled, and no way for the guest to tell
                              // which one they owed.
                              AmountBreakdown(
                                roomCharge: widget.booking.bookPrice.toDouble(),
                                taxes: widget.booking.taxesAndFees,
                                discount: widget.booking.bookDiscountAmt,
                                total: widget.booking.bookTotalAmt,
                                totalLabel: widget.booking.bookIsPaid
                                    ? 'Total paid'
                                    : 'Total due',
                                footnote: widget.booking.bookIsPaid
                                    ? null
                                    : (widget.booking.bookIsCod
                                        ? 'Due at the property'
                                        : 'Payment pending'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Property Description

                    Column(children: [
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              /// LEFT SIDE — TEXT (flexible)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Need Help? Contact the Host',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Host Name: ${widget.booking.bookingPropertyHostDetailsUserFullName ?? "N/A"}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 12),

                              /// RIGHT SIDE — BUTTON (fixed)
                              ElevatedButton.icon(
                                onPressed: () {
                                  DeviceService.launchDialPad(
                                    widget.booking
                                        .bookingPropertyHostDetailsUserPnumber,
                                  );
                                },
                                icon: const Icon(Icons.phone),
                                label: const Text("Call"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kprimaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    // The map, in the app.
                    //
                    // This was a button that fetched the coordinates in a
                    // second request and threw the guest out to the Google
                    // Maps app — there was nowhere in Aajoo that showed them
                    // where their stay actually was. The coordinates have
                    // always been in this booking's payload; the model was
                    // dropping them, which is why the extra request existed.
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Where you're staying",
                            style: fraunces(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: kInk),
                          ),
                          if (widget.booking.bookingPropertyAddress.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(widget.booking.bookingPropertyAddress,
                                style: inter(fontSize: 12.5, color: kMuted)),
                          ],
                          const SizedBox(height: 10),
                          StayMap(
                            lat: widget.booking.bookingPropertyLatitude,
                            lng: widget.booking.bookingPropertyLongitude,
                            label: widget.booking.bookingPropertyPropertyName,
                            height: 190,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Action Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // Primary Action Button (Pay Now or Checkout).
                          // COD only: /user/ongoing/bookings/payment/create
                          // refuses anything that isn't pay-at-property, so
                          // offering this on an unpaid ONLINE booking opened
                          // a spinner that could only ever end in
                          // "No Ongoing Booking found".
                          if (!widget.booking.bookIsPaid &&
                              widget.booking.bookIsCod) ...[
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  // Create order on backend then open Razorpay
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                  try {
                                    final order = await bookingController
                                        .createOngoingBookingPayment(
                                            widget.booking.bookId);
                                    Navigator.pop(context);
                                    final orderId =
                                        order['data']?['order']?['id'];
                                    if (orderId == null) {
                                      Fluttertoast.showToast(
                                          msg:
                                              "Failed to create payment order");
                                      return;
                                    }
                                    final amountInPaise = order['data']
                                            ?['order']?['amount'] ??
                                        (widget.booking.bookTotalAmt * 100)
                                            .round();
                                    // A release build carrying a TEST key takes no money while looking
                                    // exactly as if it did (W8 · P0-02). Refuse rather than confirm a
                                    // booking nobody paid for. Debug builds, and any build made with
                                    // --dart-define=ALLOW_TEST_PAYMENTS=true, are unaffected.
                                    if (!PaymentConfig.usableForPayments) {
                                      Fluttertoast.showToast(msg: PaymentConfig.unavailableMessage);
                                      return;
                                    }
                                    razorpay.open({
                                      'key': PaymentConfig.razorpayKey,
                                      'amount': amountInPaise,
                                      'currency': 'INR',
                                      'name': 'Aajoo Home',
                                      'description': 'Payment for booking',
                                      'order_id': orderId,
                                      'prefill': {
                                        'contact': authController
                                                .userData.value?.phoneNumber ??
                                            '',
                                        'email': authController
                                                .userData.value?.email ??
                                            '',
                                        'name': authController
                                                .userData.value?.fullName ??
                                            '',
                                      },
                                    });
                                  } catch (e) {
                                    Navigator.pop(context);
                                    bookingController.showSnackbar(
                                        "Error",
                                        "Failed to initiate payment: ${e.toString()}",
                                        true);
                                  }
                                },
                                icon: const Icon(
                                  Icons.payment,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                label: const Text(
                                  'Pay Now',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kSuccess,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 3,
                                ),
                              ),
                            ),
                          ] else ...[
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Handle Checkout action
                                  Get.to(() => HotelCheckoutPage(
                                        booking: widget.booking,
                                        property: userController
                                            .property.value!.data!,
                                      ));
                                },
                                icon: const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                label: const Text(
                                  'Checkout',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kprimaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 3,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),

                          // Secondary Actions Row

                          Column(
                            children: [
                              Row(
                                children: [
                                  // WhatsApp Support Button
                                  Expanded(
                                    child: SizedBox(
                                      height: 50,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          DeviceService.launchWhatsapp(
                                            phoneNumber: '7973918722',
                                            message: 'hello, i need assistance',
                                          );
                                        },
                                        icon: Image.asset(
                                          "assets/whatsapp.png",
                                          height: 20,
                                          width: 20,
                                          color: Colors.white,
                                        ),
                                        label: const Text(
                                          'WhatsApp',
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF25D366),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          elevation: 2,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  // Bot Support Button
                                  Expanded(
                                    child: SizedBox(
                                      height: 50,
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          // Same signed-in chat as the Support
                                          // screen, and the URL lives in one
                                          // place rather than being pasted here
                                          // a third time.
                                          final url = await supportChatUrl();
                                          Get.toNamed(
                                            '/webview',
                                            arguments: {
                                              'url': url,
                                              'title': 'Support Chat',
                                            },
                                          );
                                        },
                                        icon: const Icon(Icons.support_agent,
                                            size: 20),
                                        label: const Text(
                                          'Support',
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: kIndigo,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          elevation: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Cancel Button (Full Width)
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: Obx(
                                  () => bookingController.isLoading.value
                                      ? const Center(
                                          child: CircularProgressIndicator())
                                      : ElevatedButton.icon(
                                          onPressed: () =>
                                              _showCancelBookingDialog(),
                                          icon: const Icon(Icons.cancel,
                                              size: 20),
                                          label: const Text(
                                            'Cancel Booking',
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: kDanger,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            elevation: 2,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
        }),
      ),
    );
  }

  Widget _buildMinimalDetailItem(String label, String value, IconData icon,
      {bool isStatus = false, bool isPrice = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isStatus)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(value).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _getStatusColor(value),
                ),
              ),
            )
          else if (isPrice)
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: kprimaryColor,
              ),
            )
          else
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'payment pending':
        return Colors.orange;
      case 'booked':
        return kIndigo;
      case 'confirmed':
        return kSuccess;
      case 'cancelled':
        return kDanger;
      default:
        return kprimaryColor;
    }
  }

  Future<void> _showCancelBookingDialog() async {
    // Ask the server what this would refund BEFORE the dialog, so the figure
    // is on screen where the decision is made — the same thing the booking
    // history's dialog has always done.
    final quote =
        await bookingController.cancellationQuote(widget.booking.bookId);
    if (!mounted) return;

    // The server says a cancel is impossible (checked in, completed, past the
    // window). Say so rather than opening a dialog that cannot succeed — and
    // refresh, because the reason is usually that it is already cancelled.
    if (quote != null && !quote.canCancel) {
      userController.getUserHistory();
      bookingController.showSnackbar(
        'This booking cannot be cancelled',
        quote.reason ?? 'This booking can no longer be cancelled.',
        true,
      );
      return;
    }

    String? selectedReason;
    final otherReasonController = TextEditingController();
    // The SAME presets as the booking-history dialog and the website, so a
    // reason means one thing wherever it was picked.
    const reasons = [
      'Plans changed',
      'Found somewhere else',
      'Booked by mistake',
      'Trip cancelled',
      'Other',
    ];

    if (!mounted) return;
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
                      activeColor: kIndigo,
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
                  // The quote call failed. Do not invent a number, and do not
                  // invent a refusal either.
                  Text('Refunds follow the cancellation policy for this stay.',
                      style: inter(fontSize: 12, color: kMuted))
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kCream,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kLine),
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
                              style: inter(
                                  fontSize: 12, color: kMuted, height: 1.4)),
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
              child: Text('Keep booking', style: inter(color: kIndigo)),
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
    final success =
        await bookingController.cancelBooking(widget.booking.bookId, reason);
    // BOTH lists, not just the ongoing one.
    //
    // This refreshed `fetchOngoingBookings` alone, and My Bookings reads
    // `getUserHistory`. So cancelling from here took the stay out of Ongoing
    // and never put it under Cancelled: the tab kept serving the copy it had
    // loaded, and the guest was told the booking was cancelled by a screen
    // that then failed to show it anywhere. That is "I cancelled the stay and
    // it is not updated in the cancelled stays".
    userController.fetchOngoingBookings();
    userController.getUserHistory();
    if (success) {
      // Back to the guest bottom-nav shell (/home) after cancelling.
      Get.offAllNamed('/home');
    }
    // No second error here. The controller already raised one for the same
    // failure, so this added a duplicate dialog behind it and one refusal
    // read as two.
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final result = await bookingController.verifyPayment(
        response.orderId!, response.paymentId!, response.signature!);
    if (result) {
      // Refresh ongoing bookings so other screens reflect latest status
      await userController.fetchOngoingBookings();
      // Optimistically update current view to show paid state
      setState(() {
        widget.booking.bookIsPaid = true;
      });
      Fluttertoast.showToast(msg: "Payment Successful: ${response.paymentId}");
    } else {
      bookingController.showSnackbar(
          "Payment Failed", "Payment has been failed", true);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Fluttertoast.showToast(msg: "Payment Failed: ${response.message}");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Fluttertoast.showToast(msg: "External Wallet: ${response.walletName}");
  }
}

void successDialog(String paymentId, String bookingId, BuildContext context) {
  showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Image.asset("assets/success.image.png", height: 200),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Payment Successful",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text("Booking Id: $bookingId"),
              const SizedBox(height: 16),
              Text("Payment Id: $paymentId"),
            ],
          ),
        );
      });
}
