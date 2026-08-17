import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/constants/payment_config.dart';
import 'package:rent_home/controller/booking_controller.dart';
import 'package:rent_home/controller/negotiation_controller.dart';
import 'package:rent_home/models/negotiation_model.dart';
import 'package:rent_home/models/properties_response_model.dart';
import 'package:rent_home/screens/Home/homescreen.dart';
import 'package:rent_home/screens/Host/chat_page.dart';
import 'package:rent_home/service/device_service.dart';
import 'package:rent_home/service/negotitation_service.dart';

import '../controller/auth_controller.dart';
import 'package:rent_home/utils/input_sanitizers.dart';

class PriceNegotiationPage extends StatefulWidget {
  final String userId;
  final String receiverId;
  final String propertyId;
  final String serverUrl;
  final String token;
  final Property property;
  final String lat;
  final String long;
  final String senderId;
  final String hostId;

  const PriceNegotiationPage({
    super.key,
    required this.userId,
    required this.receiverId,
    required this.propertyId,
    required this.serverUrl,
    required this.token,
    required this.property,
    required this.lat,
    required this.long,
    required this.hostId,
    required this.senderId,
  });

  @override
  State<PriceNegotiationPage> createState() => _PriceNegotiationPageState();
}

class _PriceNegotiationPageState extends State<PriceNegotiationPage> {
  late final NegotiationService negotiationService;
  late final NegotiationController negotiationController;
  late final String controllerTag;
  late final AuthController authController;

  // Timer variables
  Timer? _responseTimer;
  final RxBool _showBookingOption = false.obs;
  final RxInt _remainingTime = 30.obs; // 30 seconds
  final RxBool _timerStarted = false.obs;

  // Scroll controller for auto-scroll
  late ScrollController _scrollController;
  late TextEditingController offerController;

  @override
  void initState() {
    super.initState();
    negotiationService = NegotiationService();
    controllerTag = '${widget.userId}_${widget.propertyId}';

    // Initialize scroll controller
    _scrollController = ScrollController();

    negotiationController = Get.put(
      NegotiationController(negotiationService),
      tag: controllerTag,
    );
    negotiationController.currentPrice.value =
        double.tryParse(widget.property.propertyPrice) ?? 250.0;

    negotiationController.connectToSocket(widget.serverUrl, widget.token);

    ever(negotiationController.connectionStatus, (status) {
      if (status == NegotiationConnectionStatus.connected) {
        negotiationController.joinNegotiationRoom(
            widget.userId, widget.propertyId);
        negotiationController.loadNegotiationChat(
          senderId: widget.senderId,
          receiverId: widget.receiverId,
          propertyId: widget.propertyId,
        );

        // Start timer after joining room
        _startResponseTimer();
      }
    });

    // Listen to new messages to reset timer and auto-scroll
    ever(negotiationController.messages, (_) {
      _onNewMessage();
    });
    negotiationController.currentPrice.value =
        double.tryParse(widget.property.propertyPrice) ?? 250.0;
    offerController = TextEditingController(
        text: negotiationController.currentPrice.value.toStringAsFixed(0));
    authController = Get.find<AuthController>();

    Logger().f(
        "Current price initialized to ${negotiationController.currentPrice.value}");
  }

  void _startResponseTimer() {
    if (!_timerStarted.value) {
      _timerStarted.value = true;
      _remainingTime.value = 30; // Reset to 30 seconds
      _showBookingOption.value = false;

      _responseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingTime.value > 0) {
          _remainingTime.value--;
        } else {
          _showBookingOption.value = true;
          timer.cancel();
        }
      });
    }
  }

  void _onNewMessage() {
    // Check if the last message is from host (not from current user)
    final messages = negotiationController.messages;
    final logger = Logger();
    if (messages.isNotEmpty) {
      final lastMessage = messages.last;
      logger.f(
          'Last message from: ${lastMessage.senderId}, Current user: ${widget.userId}, current price: ${negotiationController.currentPrice.value} , last offer price: ${lastMessage.offerPrice}');

      if (lastMessage.isOffer && lastMessage.offerPrice != null) {
        negotiationController.currentPrice.value = lastMessage.offerPrice!;
      }
      logger.f(
          'Updated current price: ${negotiationController.currentPrice.value}');
      if (lastMessage.senderId != widget.userId) {
        // Host responded, reset timer
        _resetTimer();
      } else {
        // User sent message, start/restart timer
        _resetTimer();
        _startResponseTimer();
      }
    }
    _scrollToBottom();
  }

  void _resetTimer() {
    _responseTimer?.cancel();
    _timerStarted.value = false;
    _showBookingOption.value = false;
    _remainingTime.value = 30;
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _scrollToBottom() {
    // Use a slight delay to ensure the UI has updated with the new message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _hideLoadingDialog() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Future<void> _bookProperty(double price, {required bool isCod}) async {
    _showLoadingDialog();
    final bookingController = Get.put(BookingController());
    final authController = Get.find<AuthController>();
    final property = widget.property;

    final now = DateTime.now();
    final bookFrom = DateFormat('dd-MM-yyyy').format(now);
    final bookTo =
        DateFormat('dd-MM-yyyy').format(now.add(const Duration(days: 1)));

    // add gst

    final bookingData = {
      "propertyId": property.propertyId,
      "price": price,
      "bookFrom": bookFrom,
      "bookTo": bookTo,
      "isCod": isCod,
      "category": 1,
      "bookingType": "Daily",
    };

    try {
      final bookingResponse =
          await bookingController.createBooking(bookingData);

      if (!isCod) {
        final orderId = bookingResponse.data.booking.order?.id.toString() ?? '';
        final contact = authController.userData.value!.phoneNumber;
        final email = authController.userData.value!.email;
        print(price);
        final options = {
          "key": PaymentConfig.razorpayKey,
          "amount": price * 100,
          "name": "Aajoo",
          'description': 'Payment for Order ID: ${property.propertyId}',
          'order_id': orderId,
          'prefill': {'email': email, 'contact': contact},
          'theme': {'color': '#3399cc'}
        };
        _hideLoadingDialog();
        try {
          Razorpay razorpay = Razorpay();
          razorpay.open(options);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment error: $e')),
          );
        }
      } else {
        _hideLoadingDialog();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking successful! Pay on arrival.')),
        );
        successDialog("Booking Successful",
            bookingResponse.data.booking.bookId.toString());

        // Navigator.pop(context);
      }
    } catch (e) {
      _hideLoadingDialog();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking error: $e')),
      );
    }
  }

  void successDialog(String paymentId, String bookingId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Image.asset("assets/success.image.png", height: 200),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Payment Successful",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text("Booking Id: $bookingId"),
              const SizedBox(height: 16),
              Text("Payment Id: $paymentId"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  CupertinoPageRoute(builder: (context) => const Homescreen()),
                  (route) => false,
                );
              },
              child: const Text("Close"),
            ),
            ElevatedButton(
              onPressed: () async {
                final lat = double.parse(widget.lat);
                final long = double.parse(widget.long);
                if (Platform.isAndroid) {
                  DeviceService.launchGoogleMaps(lat, long);
                }
                DeviceService.showMapOptions(context, lat, long);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kprimaryColor,
                minimumSize: const Size(100, 50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Get Directions"),
            ),
          ],
        );
      },
    );
  }

  void _showAcceptOfferDialog(double price) async {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Choose Payment Method", style: theme.textTheme.titleLarge),
              const SizedBox(height: 24),
              // add details about gst
              Builder(builder: (_) {
                final gstRate = price <= 7500 ? 0.05 : 0.18;
                final gstAmount = price * gstRate;
                return Text(
                  "GST (${(gstRate * 100).toStringAsFixed(0)}%): ₹${gstAmount.toStringAsFixed(2)}",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }),
              const SizedBox(height: 8),
              Builder(builder: (_) {
                final gstRate = price <= 7500 ? 0.05 : 0.18;
                final total = price * (1 + gstRate);
                return Text(
                  "Total Price: ₹${total.toStringAsFixed(2)} (including GST)",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }),
              const SizedBox(height: 8),

              ElevatedButton.icon(
                icon: const Icon(Icons.money),
                label: const Text("Pay on Arrival (COD)"),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  final gstRate = price <= 7500 ? 0.05 : 0.18;
                  await _bookProperty(price * (1 + gstRate), isCod: true);
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.payment),
                label: const Text("Pay Online (Razorpay)"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  final gstRate = price <= 7500 ? 0.05 : 0.18;
                  await _bookProperty(price * (1 + gstRate), isCod: false);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _responseTimer?.cancel();
    _scrollController.dispose();
    Get.delete<NegotiationController>(tag: controllerTag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(locale: 'en_US', symbol: '₹');

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Obx(() {
        if (negotiationController.isLoading.value) {
          return Center(
              child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.9,
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("assets/happy_tourist.png", height: 150),
                const CircularProgressIndicator(
                  color: kPrimaryColor,
                ),
                const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Text(
                    "Negotiation lets you propose a custom price for this property. Both you and the host can make offers until you agree on a price.\n\nCaution: Only accept offers you are comfortable with. Once you accept, you will proceed to booking and payment. Never share sensitive information in chat.",
                    style: TextStyle(color: Colors.black87, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ));
        } else if (negotiationController.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Negotiation lets you propose a custom price for this property. Both you and the host can make offers until you agree on a price.\n\nCaution: Only accept offers you are comfortable with. Once you accept, you will proceed to booking and payment. Never share sensitive information in chat.",
                  style: TextStyle(color: Colors.black87, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    negotiationController.connectToSocket(
                        widget.serverUrl, widget.token);
                    negotiationController.joinNegotiationRoom(
                        widget.userId, widget.propertyId);
                    negotiationController.loadNegotiationChat(
                      senderId: widget.senderId,
                      receiverId: widget.receiverId,
                      propertyId: widget.propertyId,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Negotiate Price",
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Scrollable Content Area
            Expanded(
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Property Details Sliver App Bar
                  SliverAppBar(
                    expandedHeight: 280,
                    floating: false,
                    pinned: true,
                    backgroundColor: theme.primaryColor,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        negotiationController.disconnectSocket();
                        Navigator.pop(context);
                      },
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        widget.property.propertyName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.primaryColor,
                              theme.primaryColor.withOpacity(0.8),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  widget.property.coverImage != null
                                      ? widget.property.coverImage.toString()
                                      : 'https://images.unsplash.com/photo-1566073771259-6a8506099945',
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.broken_image,
                                      size: 60,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.property.propertyAddress,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        "Base: ${formatter.format(double.parse(widget.property.propertyPrice))}",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.property.propertyDesc,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        // Chat Status Card - shows turn and message limits
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Obx(() {
                            final remainingMessages =
                                negotiationController.getRemainingMessages(
                                    widget.userId, widget.hostId);
                            final whoseTurn = negotiationController
                                .getWhoseTurn(widget.userId, widget.hostId);
                            final totalMessages = negotiationController
                                    .userMessageCount.value +
                                negotiationController.hostMessageCount.value;

                            return Card(
                              elevation: 2,
                              color:
                                  negotiationController.chatLimitReached.value
                                      ? Colors.red[50]
                                      : Colors.blue[50],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: negotiationController
                                          .chatLimitReached.value
                                      ? Colors.red
                                      : Colors.blue,
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          negotiationController
                                                  .chatLimitReached.value
                                              ? Icons
                                                  .chat_bubble_outline_rounded
                                              : Icons.chat,
                                          color: negotiationController
                                                  .chatLimitReached.value
                                              ? Colors.red
                                              : Colors.blue,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            whoseTurn,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                              color: negotiationController
                                                      .chatLimitReached.value
                                                  ? Colors.red[700]
                                                  : Colors.blue[700],
                                              fontWeight: FontWeight.w600,
                                            ),
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
                                          'Messages: $totalMessages/4',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          'Your remaining: $remainingMessages',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (negotiationController
                                        .chatLimitReached.value)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          '⚠️ Chat limit reached! You must accept the latest offer to proceed.',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: Colors.red[700],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),

                        // Timer and Booking Option Card for user
                        Visibility(
                          visible:
                              authController.userData.value?.isUser == true,
                          child: Obx(() {
                            if (_timerStarted.value) {
                              return Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Card(
                                  elevation: 2,
                                  color: _showBookingOption.value
                                      ? Colors.red[50]
                                      : Colors.orange[50],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: _showBookingOption.value
                                          ? Colors.red
                                          : Colors.orange,
                                      width: 1,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: _showBookingOption.value
                                        ? Column(
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(Icons.access_time,
                                                      color: Colors.red,
                                                      size: 20),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    "Host not responding",
                                                    style: theme
                                                        .textTheme.titleMedium
                                                        ?.copyWith(
                                                      color: Colors.red,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                "The host hasn't responded in 30 seconds. You can book directly at the current price.",
                                                style: theme
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(
                                                  color: Colors.red[700],
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              ElevatedButton.icon(
                                                onPressed: () {
                                                  _showAcceptOfferDialog(
                                                      negotiationController
                                                          .currentPrice.value);
                                                },
                                                icon: const Icon(
                                                    Icons.book_online),
                                                label: Text(
                                                    "Book Now at ${formatter.format(negotiationController.currentPrice.value)}"),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                  foregroundColor: Colors.white,
                                                  minimumSize: const Size(
                                                      double.infinity, 45),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : Row(
                                            children: [
                                              const Icon(Icons.timer,
                                                  color: Colors.orange,
                                                  size: 20),
                                              const SizedBox(width: 8),
                                              Text(
                                                "Waiting for host response: ${_formatTime(_remainingTime.value)}",
                                                style: theme
                                                    .textTheme.titleMedium
                                                    ?.copyWith(
                                                  color: Colors.orange[700],
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }),
                        ),
                      ],
                    ),
                  ),

                  // Negotiation Messages
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final message = negotiationController.messages[index];
                        final authController = Get.find<AuthController>();
                        final isUser = message.senderId ==
                            authController.userData.value?.userId.toString();
                        final isAccepted = message.isAccepted;
                        final isOffer = message.isOffer;
                        final acceptedThis =
                            negotiationController.acceptedOfferId.value ==
                                message.messageId;

                        Color bubbleColor;
                        if (isAccepted) {
                          bubbleColor = isUser
                              ? theme.primaryColor.withOpacity(0.85)
                              : Colors.green.shade50;
                        } else {
                          bubbleColor =
                              isUser ? theme.primaryColor : Colors.white;
                        }

                        return Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: bubbleColor,
                              borderRadius: BorderRadius.circular(12),
                              border: isAccepted
                                  ? Border.all(color: Colors.green, width: 2)
                                  : null,
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: isUser
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                if (isOffer)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.local_offer,
                                          size: 16,
                                          color: isUser
                                              ? Colors.white70
                                              : theme.primaryColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        message.offerPrice != null
                                            ? 'Offer: ₹${message.offerPrice!.toStringAsFixed(0)}'
                                            : 'Offer',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isUser
                                                ? Colors.white70
                                                : theme.primaryColor),
                                      ),
                                      if (acceptedThis)
                                        Container(
                                          margin:
                                              const EdgeInsets.only(left: 6),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'ACCEPTED',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                    ],
                                  ),
                                Text(
                                  message.messageText,
                                  style: TextStyle(
                                    color:
                                        isUser ? Colors.white : Colors.black87,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('hh:mm a').format(
                                      DateTime.parse(message.createdAt)
                                          .toLocal()),
                                  style: TextStyle(
                                    color: isUser
                                        ? Colors.white70
                                        : Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: negotiationController.messages.length,
                    ),
                  ),

                  // Add some bottom padding to prevent messages from hiding behind controls
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 16),
                  ),
                ],
              ),
            ),

            // Fixed Negotiation Controls at Bottom
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 8,
                  shadowColor: theme.primaryColor.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          Colors.grey.shade50,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Current Offer Header
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.primaryColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.local_offer,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Current Offer",
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Obx(() => Text(
                                            formatter.format(
                                                negotiationController
                                                    .currentPrice.value),
                                            style: theme.textTheme.titleLarge
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: theme.primaryColor,
                                              fontSize: 24,
                                            ),
                                          )),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Price Range Chips
                          Text(
                            "Quick Price Adjustments",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildPriceChip(
                                  context, "-₹200", -200, Colors.red),
                              _buildPriceChip(
                                  context, "-₹100", -100, Colors.red),
                              _buildPriceChip(
                                  context, "-₹50", -50, Colors.orange),
                              _buildPriceChip(
                                  context, "+₹50", 50, Colors.green),
                              _buildPriceChip(
                                  context, "+₹100", 100, Colors.green),
                              _buildPriceChip(
                                  context, "+₹200", 200, Colors.green),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Custom Offer Section
                          Text(
                            "Custom Offer",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Obx(() => TextField(
                                        controller: offerController,
                                        enabled: !negotiationController
                                                .offerFinalized.value &&
                                            negotiationController
                                                .canUserSendMessage(
                                                    widget.userId,
                                                    widget.hostId),
                                        keyboardType: TextInputType.number,
                                        inputFormatters:
                                            AppInputFormatters.digits(7),
                                        decoration: InputDecoration(
                                          hintText: negotiationController
                                                  .offerFinalized.value
                                              ? "Offer finalized"
                                              : negotiationController
                                                      .chatLimitReached.value
                                                  ? "Chat limit reached"
                                                  : !negotiationController
                                                          .canUserSendMessage(
                                                              widget.userId,
                                                              widget.hostId)
                                                      ? "Wait for response"
                                                      : "Enter your price",
                                          hintStyle: TextStyle(
                                              color: Colors.grey[500]),
                                          prefixIcon: Icon(
                                            Icons.currency_rupee,
                                            color: theme.primaryColor,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                        ),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      )),
                                ),
                                Container(
                                  margin: const EdgeInsets.all(4),
                                  child: ElevatedButton(
                                    onPressed: negotiationController
                                                    .connectionStatus.value ==
                                                NegotiationConnectionStatus
                                                    .connected &&
                                            !negotiationController
                                                .offerFinalized.value &&
                                            negotiationController
                                                .canUserSendMessage(
                                                    widget.userId,
                                                    widget.hostId)
                                        ? () {
                                            final input = double.tryParse(
                                                offerController.text);
                                            if (input != null && input > 0) {
                                              negotiationController
                                                  .sendNegotiationMessage(
                                                propertyId: widget.propertyId,
                                                senderId: widget.senderId,
                                                receiverId: widget.receiverId,
                                                messageText:
                                                    'Offered: ${formatter.format(input)} per night.',
                                                isOffer: true,
                                                offerPrice: input,
                                                context: context,
                                                userId: widget.userId,
                                                hostId: widget.hostId,
                                              );
                                              offerController.clear();
                                              _resetTimer();
                                              _startResponseTimer();
                                              _scrollToBottom();
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        "Please enter a valid price.")),
                                              );
                                            }
                                          }
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: const Icon(Icons.send, size: 20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Obx(() {
                            // If an offer has been finalized show summary (and payment actions for renter)
                            if (negotiationController.offerFinalized.value) {
                              final acceptedMessage = negotiationController
                                  .messages
                                  .firstWhereOrNull((m) =>
                                      m.messageId ==
                                      negotiationController
                                          .acceptedOfferId.value);
                              final price = double.tryParse(
                                      negotiationController
                                          .finalAmount.value) ??
                                  (acceptedMessage?.offerPrice ??
                                      negotiationController.currentPrice.value);
                              final isRenter =
                                  authController.userData.value?.isUser == true;
                              final gstRate = price <= 7500 ? 0.05 : 0.18;
                              final totalWithGst = price * (1 + gstRate);

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: Colors.green.shade50,
                                      border: Border.all(
                                          color: Colors.green, width: 1.5),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.check_circle,
                                            color: Colors.green),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Offer accepted at ₹${price.toStringAsFixed(0)}',
                                                style: theme
                                                    .textTheme.titleMedium
                                                    ?.copyWith(
                                                  color: Colors.green[800],
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'GST will be added during payment.',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: Colors.green[700],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isRenter) ...[
                                    const SizedBox(height: 20),
                                    Text('Complete Booking',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            icon: const Icon(Icons.money),
                                            label: const Text('Pay on Arrival'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 14),
                                            ),
                                            onPressed: () => _bookProperty(
                                                totalWithGst,
                                                isCod: true),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            icon: const Icon(Icons.payment),
                                            label: const Text('Pay Online'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  theme.primaryColor,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 14),
                                            ),
                                            onPressed: () => _bookProperty(
                                                totalWithGst,
                                                isCod: false),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Total with ${(gstRate * 100).toStringAsFixed(0)}% GST: ₹${totalWithGst.toStringAsFixed(2)}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: Colors.grey[700]),
                                    ),
                                  ],
                                ],
                              );
                            }

                            // Show Accept Offer only if the LAST message is an offer from the other user and not accepted
                            // OR if chat limit is reached and there's any unaccepted foreign offer
                            NegotiationMessageModel? latestForeignOffer;
                            if (negotiationController.messages.isNotEmpty) {
                              final currentUserIdStr = authController
                                  .userData.value?.userId
                                  .toString();

                              if (negotiationController
                                  .chatLimitReached.value) {
                                // When chat limit reached, find any unaccepted foreign offer
                                for (int i =
                                        negotiationController.messages.length -
                                            1;
                                    i >= 0;
                                    i--) {
                                  final msg = negotiationController.messages[i];
                                  if (msg.isOffer == true &&
                                      currentUserIdStr != null &&
                                      msg.senderId != currentUserIdStr &&
                                      (msg.isAccepted != true)) {
                                    latestForeignOffer = msg;
                                    break;
                                  }
                                }
                              } else {
                                // Normal case: only show for the last message
                                final lastMsg =
                                    negotiationController.messages.last;
                                if (lastMsg.isOffer == true &&
                                    currentUserIdStr != null &&
                                    lastMsg.senderId != currentUserIdStr &&
                                    (lastMsg.isAccepted != true)) {
                                  latestForeignOffer = lastMsg;
                                }
                              }
                            }

                            final offer = latestForeignOffer;
                            if (offer == null) {
                              return const SizedBox.shrink();
                            }

                            return Container(
                              width: double.infinity,
                              height:
                                  negotiationController.chatLimitReached.value
                                      ? 72
                                      : 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: negotiationController
                                          .chatLimitReached.value
                                      ? [
                                          Colors.red,
                                          Colors.red.withOpacity(0.8)
                                        ]
                                      : [
                                          theme.primaryColor,
                                          theme.primaryColor.withOpacity(0.8)
                                        ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: negotiationController
                                            .chatLimitReached.value
                                        ? Colors.red.withOpacity(0.4)
                                        : theme.primaryColor.withOpacity(0.3),
                                    blurRadius: negotiationController
                                            .chatLimitReached.value
                                        ? 12
                                        : 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: negotiationController
                                                .connectionStatus.value ==
                                            NegotiationConnectionStatus
                                                .connected &&
                                        !negotiationController
                                            .acceptingOffer.value
                                    ? () {
                                        final currentUserIdStr = authController
                                            .userData.value?.userId
                                            .toString();
                                        if (currentUserIdStr != null &&
                                            currentUserIdStr.isNotEmpty) {
                                          negotiationController.acceptOffer(
                                            offer: offer,
                                            currentUserId: currentUserIdStr,
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content: Text(
                                                      'Unable to accept: not authenticated')));
                                        }
                                      }
                                    : null,
                                icon: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    negotiationController.acceptingOffer.value
                                        ? Icons.hourglass_top
                                        : Icons.handshake,
                                    color: theme.primaryColor,
                                    size: 20,
                                  ),
                                ),
                                label: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (negotiationController
                                        .chatLimitReached.value)
                                      Text(
                                        '⚠️ MUST ACCEPT - Chat Limit Reached',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    Text(
                                      negotiationController.acceptingOffer.value
                                          ? 'Accepting...'
                                          : 'Accept Offer ₹${offer.offerPrice?.toStringAsFixed(0) ?? ''}',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: negotiationController
                                                .chatLimitReached.value
                                            ? 14
                                            : 16,
                                      ),
                                    ),
                                  ],
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildPriceChip(
      BuildContext context, String label, double adjustment, Color color) {
    final formatter = NumberFormat.currency(locale: 'en_US', symbol: '₹');

    return Obx(() => FilterChip(
          label: Text(
            label,
            style: TextStyle(
              color: negotiationController.canUserSendMessage(
                      widget.userId, widget.hostId)
                  ? color
                  : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          backgroundColor: negotiationController.canUserSendMessage(
                  widget.userId, widget.hostId)
              ? color.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          selectedColor: color.withOpacity(0.2),
          side: BorderSide(
              color: negotiationController.canUserSendMessage(
                      widget.userId, widget.hostId)
                  ? color
                  : Colors.grey,
              width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          onSelected: negotiationController.connectionStatus.value ==
                      NegotiationConnectionStatus.connected &&
                  !negotiationController.offerFinalized.value &&
                  negotiationController.canUserSendMessage(
                      widget.userId, widget.hostId)
              ? (selected) {
                  final newPrice =
                      negotiationController.currentPrice.value + adjustment;
                  if (newPrice > 0) {
                    negotiationController.sendNegotiationMessage(
                      propertyId: widget.propertyId,
                      senderId: widget.senderId,
                      receiverId: widget.receiverId,
                      messageText:
                          'Offered: ${formatter.format(newPrice)} per night.',
                      isOffer: true,
                      offerPrice: newPrice,
                      context: context,
                      userId: widget.userId,
                      hostId: widget.hostId,
                    );
                    _resetTimer();
                    _startResponseTimer();
                    _scrollToBottom();
                  }
                }
              : null,
        ));
  }
}

// Fixed extension for lastWhereOrNull
extension IterableExtension<T> on Iterable<T> {
  T? lastWhereOrNull(bool Function(T) test) {
    try {
      return lastWhere(test, orElse: () => null as T);
    } catch (e) {
      return null;
    }
  }
}
