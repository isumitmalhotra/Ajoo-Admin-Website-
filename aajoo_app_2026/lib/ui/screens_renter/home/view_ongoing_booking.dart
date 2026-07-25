import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/constants/payment_config.dart';
import 'package:rent_home/ui/screens_renter/booking_controller.dart';
import 'package:rent_home/controller/user_controller.dart';
import 'package:rent_home/ui/screens_common/auth/auth_controller.dart';
import 'package:rent_home/data/models/ongoing_reponse.dart';
import 'package:rent_home/ui/screens_renter/checkout/checkout_page.dart';
import 'package:rent_home/service/device_service.dart';

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
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text(
          'Booking Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: kprimaryColor,
        elevation: 0,
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

                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMinimalDetailItem(
                                      'Invoice',
                                      widget.booking.bookInvoice,
                                      Icons.receipt_outlined,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildMinimalDetailItem(
                                      'Amount',
                                      '₹${widget.booking.bookPrice}',
                                      Icons.currency_rupee,
                                      isPrice: true,
                                    ),
                                  ),
                                ],
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
                    // Location Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: Obx(() => ElevatedButton.icon(
                              onPressed: isLocationLoading.value
                                  ? null
                                  : () async {
                                      try {
                                        isLocationLoading.value = true;
                                        final latLong = await bookingController
                                            .getPropertyLatLong(widget.booking
                                                .bookingPropertyPropertyId);
                                        final latitude = double.tryParse(
                                                latLong['latitude']) ??
                                            0.0;
                                        final longitude = double.tryParse(
                                                latLong['longitude']) ??
                                            0.0;

                                        if (latitude != 0.0 &&
                                            longitude != 0.0) {
                                          DeviceService.launchGoogleMaps(
                                              latitude, longitude);
                                        } else {
                                          bookingController.showSnackbar(
                                              "Error",
                                              "Location not available",
                                              true);
                                        }
                                      } catch (e) {
                                        bookingController.showSnackbar(
                                            "Error",
                                            "Failed to get location: ${e.toString()}",
                                            true);
                                      } finally {
                                        isLocationLoading.value = false;
                                      }
                                    },
                              icon: isLocationLoading.value
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.location_on,
                                      color: Colors.white,
                                    ),
                              label: Text(isLocationLoading.value
                                  ? 'Getting Location...'
                                  : 'View Property Location'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isLocationLoading.value
                                    ? kprimaryColor.withOpacity(0.7)
                                    : kprimaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 15),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            )),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // Primary Action Button (Pay Now or Checkout)
                          if (!widget.booking.bookIsPaid) ...[
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
                                        (widget.booking.bookPrice * 100)
                                            .round();
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
                                  backgroundColor: Colors.green,
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
                                        onPressed: () {
                                          Get.toNamed(
                                            '/webview',
                                            arguments: {
                                              'url':
                                                  'https://window-2.botpenguin.com/69803a093817049868bf064f/696f4cdf88f4a8046c67188e',
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
                                          backgroundColor: Colors.blue,
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
                                            backgroundColor: Colors.red,
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
        return Colors.blue;
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return kprimaryColor;
    }
  }

  void _showCancelBookingDialog() {
    String? selectedReason;
    final TextEditingController otherReasonController = TextEditingController();
    final List<String> reasons = [
      "Changed my mind",
      "Found a better price",
      "Driver is taking too long",
      "Booked by mistake",
      "Other"
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 28),
                SizedBox(width: 10),
                Text(
                  'Cancel Booking',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Please select a reason for cancellation:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...reasons.map((reason) {
                    return RadioListTile<String>(
                      title: Text(reason),
                      value: reason,
                      groupValue: selectedReason,
                      activeColor: kprimaryColor,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        setState(() {
                          selectedReason = value;
                        });
                      },
                    );
                  }),
                  if (selectedReason == "Other")
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: TextField(
                        controller: otherReasonController,
                        decoration: InputDecoration(
                          hintText: "Please specify the reason",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Important: You will not be refunded as the booking is confirmed.',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Keep Booking',
                  style: TextStyle(
                    color: kprimaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedReason == null) {
                    Fluttertoast.showToast(msg: "Please select a reason");
                    return;
                  }
                  String finalReason = selectedReason!;
                  if (selectedReason == "Other") {
                    if (otherReasonController.text.trim().isEmpty) {
                      Fluttertoast.showToast(msg: "Please specify the reason");
                      return;
                    }
                    finalReason = otherReasonController.text.trim();
                  }

                  Navigator.of(context).pop();
                  await _cancelBooking(finalReason);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Cancel Anyway'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _cancelBooking(String reason) async {
    final success =
        await bookingController.cancelBooking(widget.booking.bookId, reason);
    userController.fetchOngoingBookings();
    if (success) {
      // Back to the guest bottom-nav shell (/home) after cancelling.
      Get.offAllNamed('/home');
    } else {
      bookingController.showSnackbar("Error", "Failed to cancel booking", true);
    }
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
