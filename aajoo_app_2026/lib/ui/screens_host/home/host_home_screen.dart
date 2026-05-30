import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/service/device_service.dart';
import 'package:rent_home/ui/screens_host/host_controller.dart';
import 'package:rent_home/ui/screens_host/ongoing_booking/view_ongoing_booking_page.dart';
import 'package:rent_home/ui/screens_host/home/components/host_home_shimmer.dart';
import 'package:rent_home/ui/screens_host/home/components/host_recent_transaction_item_view.dart';
import 'package:rent_home/ui/screens_host/home/components/host_recent_transaction_loading_view.dart';
import 'package:rent_home/ui/screens_host/home/components/no_ongoing_booking_view.dart';
import 'package:rent_home/ui/screens_host/home/components/no_recent_transaction_view.dart';
import 'package:rent_home/ui/screens_host/home/components/support_assistant.widget.dart';
import '../../../constants.dart';
import '../../../widgets/hotel_card.dart';
import '../../../widgets/quote_widget.dart';

class HostHomeScreen extends StatefulWidget {
  const HostHomeScreen({super.key});

  @override
  State<HostHomeScreen> createState() => _HostHomeScreenState();
}

class _HostHomeScreenState extends State<HostHomeScreen> {
  final hostController = Get.find<HostController>();

  List<String> imageUrls = [
    "https://dynamic-media-cdn.tripadvisor.com/media/photo-o/22/a1/9c/80/essentia-luxury-hotel.jpg?w=1200&h=-1&s=1",
    "https://dynamic-media-cdn.tripadvisor.com/media/photo-o/0f/17/09/c9/caption.jpg?w=700&h=-1&s=1",
    "https://media-cdn.tripadvisor.com/media/photo-s/10/da/a5/12/deluxe-room.jpg",
  ];

  @override
  void initState() {
    super.initState();
    hostController.getTransactionHistory();
    hostController.getHostOngoing(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kscaffoldColor,
      floatingActionButton: SupportAssistantWidget(
        onTap: () {
          DeviceService.launchWhatsapp(
            phoneNumber: "7973918722",
            message: "hello, i need assistance",
          );
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const QuoteWidget(),
                const SizedBox(height: 20),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Ongoing Bookings",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                ),
                Obx(() {
                  if (hostController.loading.value) {
                    return const HostHomeShimmer();
                  }
                  var ongoingBookings =
                      hostController.HostOngoingResponse.value?.data.bookings ??
                          [];

                  if (ongoingBookings.isEmpty) {
                    return const NoOngoingBookingView();
                  }

                  return SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: ongoingBookings.length,
                      itemBuilder: (context, index) {
                        final booking = ongoingBookings[index];
                        return GestureDetector(
                          onTap: () {
                            Get.to(
                                () => ViewOngoingBookingPage(booking: booking));
                          },
                          child: HotelCard(
                            imageUrl: imageUrls[index % 3],
                            roomNumber: booking.bookId.toString(),
                            bookedTill: booking.userDetailsUserFullName,
                            from: booking.bookDetailsBtBookFrom,
                            to: booking.bookDetailsBtBookTo,
                            status: booking.bookingStatusBsTitle,
                          ),
                        );
                      },
                    ),
                  );
                }),
                const SizedBox(height: 20),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Recent Transactions",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Obx(() {
                  if (hostController.loading.value) {
                    return const HostRecentTransactionLoadingView();
                  }

                  var transactions =
                      hostController.transactionHistoryResponse.value?.data ??
                          [];

                  if (transactions.isEmpty) {
                    return const NoRecentTransactionView();
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      final date = transaction.payAddedAt;
                      final formatDate =
                          "${date.day}/${date.month}/${date.year}";

                      return HostRecentTransactionItemView(
                          transaction: transaction, formatDate: formatDate);
                    },
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
