import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/data/models/host_booking_history_model.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:rent_home/ui/screens_host/booking_history/host_booking_history_controller.dart';

/// Host Bookings — re-skinned to the new design (scaffold host_bookings): teal
/// app bar + 4 status tabs (Upcoming/Ongoing/Completed/Cancelled) filtering the
/// real HostBookingHistory data. Card + review dialog wiring unchanged.
class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  late final HostBookingHistoryController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(HostBookingHistoryController());
    controller.getHostBookingHistory();

    // Only surface real review-submission errors. Fetch errors are folded
    // into the empty state to avoid scary red snackbars on first load.
    ever(controller.errorMessage, (String? message) {
      if (message != null && message.isNotEmpty) {
        Get.snackbar(
          "Error",
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: kDanger,
          colorText: Colors.white,
          margin: const EdgeInsets.all(12),
        );
      }
    });
  }

  @override
  void dispose() {
    Get.delete<HostBookingHistoryController>();
    super.dispose();
  }

  // Bucket a booking by its status title into one of the four tabs.
  int _bucket(String? title) {
    final s = (title ?? '').toLowerCase();
    if (s.contains('cancel')) return 3; // Cancelled
    if (s.contains('complet') ||
        s.contains('checkout') ||
        s.contains('check out') ||
        s.contains('checked-out')) {
      return 2; // Completed
    }
    if (s.contains('running') ||
        s.contains('checkin') ||
        s.contains('check in') ||
        s.contains('checked-in') ||
        s.contains('ongoing') ||
        s.contains('stay')) {
      return 1; // Ongoing
    }
    return 0; // Upcoming
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: kscaffoldColor,
        appBar: AppBar(
          backgroundColor: kIndigo,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text('Bookings',
              style: fraunces(
                  fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            indicatorWeight: 2.5,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: inter(fontSize: 13.5, fontWeight: FontWeight.w700),
            unselectedLabelStyle: inter(fontSize: 13.5),
            tabs: const [
              Tab(text: 'Upcoming'),
              Tab(text: 'Ongoing'),
              Tab(text: 'Completed'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        body: Obx(() {
          final isInitialLoad =
              !controller.hasFetched.value && controller.loading.value;
          final all =
              controller.hostBookingHistoryResponse.value?.data ?? const [];

          Widget content;
          if (isInitialLoad) {
            content = const Center(
                child: CircularProgressIndicator(color: kIndigo));
          } else {
            content = TabBarView(
              children: List.generate(4, (bucket) {
                final items =
                    all.where((b) => _bucket(b.bookingStatusBsTitle) == bucket).toList();
                return RefreshIndicator(
                  color: kIndigo,
                  onRefresh: controller.getHostBookingHistory,
                  child: items.isEmpty
                      ? _empty(bucket)
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          itemCount: items.length,
                          itemBuilder: (context, index) =>
                              _buildCard(items[index], controller),
                        ),
                );
              }),
            );
          }

          return Stack(
            children: [
              content,
              if (controller.isSubmittingReview.value)
                Container(
                  color: kInk.withOpacity(0.3),
                  child: const Center(
                      child: CircularProgressIndicator(color: kIndigo)),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _empty(int bucket) {
    const labels = ['upcoming', 'ongoing', 'completed', 'cancelled'];
    const icons = [
      Icons.event_available_outlined,
      Icons.meeting_room_outlined,
      Icons.check_circle_outline,
      Icons.cancel_outlined,
    ];
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),
        Icon(icons[bucket], size: 60, color: kLine),
        const SizedBox(height: 12),
        Center(
          child: Text('No ${labels[bucket]} bookings',
              style: inter(fontSize: 15, color: kMuted)),
        ),
      ],
    );
  }

  // Status → badge colors.
  (Color, Color) _statusColors(String status) {
    final b = _bucket(status);
    switch (b) {
      case 1:
        return (const Color(0xFFEAF6EE), kSuccess); // Ongoing
      case 2:
        return (const Color(0xFFEFF3F8), kInk2); // Completed
      case 3:
        return (const Color(0xFFFDECEC), kDanger); // Cancelled
      default:
        return (const Color(0xFFFFF1E6), kClay); // Upcoming
    }
  }

  Widget _buildCard(
      HostBookingHistory booking, HostBookingHistoryController controller) {
    final (badgeBg, badgeFg) = _statusColors(booking.bookingStatusBsTitle);
    final guest = booking.userDetailsUserFullName.trim().isEmpty
        ? "Guest"
        : booking.userDetailsUserFullName;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: booking id + status
          Row(
            children: [
              Text("Booking #${booking.bookId}",
                  style: fraunces(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: kInk)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: badgeBg, borderRadius: BorderRadius.circular(20)),
                child: Text(booking.bookingStatusBsTitle.trim(),
                    style: inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: badgeFg)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text("Invoice: ${booking.bookInvoice}",
              style: inter(fontSize: 12.5, color: kMuted)),
          const SizedBox(height: 14),
          // Price + payment mode
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("₹ ${booking.bookPrice}",
                  style: fraunces(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: kIndigo600)),
              Text(booking.bookIsCod ? "Cash on Delivery" : "Online Payment",
                  style: inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: kInk2)),
            ],
          ),
          const SizedBox(height: 14),
          // Guest details box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: kcontentColor, borderRadius: BorderRadius.circular(12)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                      color: kIndigo50, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(
                    guest.isNotEmpty ? guest[0].toUpperCase() : '?',
                    style: fraunces(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: kIndigo600),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(guest,
                          style: fraunces(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: kInk)),
                      const SizedBox(height: 4),
                      Text(
                          "${booking.bookDetailsBtBookFrom}  →  ${booking.bookDetailsBtBookTo}",
                          style: inter(fontSize: 12.5, color: kInk2)),
                      const SizedBox(height: 3),
                      Text("Contact: ${booking.userDetailsUserPnumber}",
                          style: inter(fontSize: 12, color: kMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Date + action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Booked ${booking.bookAddedAt?.day}/${booking.bookAddedAt?.month}/${booking.bookAddedAt?.year}",
                style: inter(fontSize: 12, color: kMuted),
              ),
              if (_bucket(booking.bookingStatusBsTitle) == 2)
                ElevatedButton(
                  onPressed: () =>
                      _buildReviewDialog(Get.context!, booking, controller),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kClay,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text("Give Review",
                      style:
                          inter(fontSize: 13, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

void _buildReviewDialog(BuildContext context, HostBookingHistory booking,
    HostBookingHistoryController controller) {
  int rating = 0;
  String description = '';

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text("Give Review",
            style: fraunces(
                fontSize: 18, fontWeight: FontWeight.w700, color: kInk)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            Text("Rate the guest experience",
                style: inter(fontSize: 13, color: kMuted)),
            const SizedBox(height: 10),
            RatingBar.builder(
              initialRating: 0,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 5,
              itemSize: 44.0,
              itemBuilder: (context, _) =>
                  const Icon(Icons.star_rounded, color: kClay),
              onRatingUpdate: (value) => rating = value.toInt(),
            ),
            const SizedBox(height: 18),
            TextField(
              decoration: InputDecoration(
                hintText: "Write your review",
                hintStyle: inter(fontSize: 13, color: kMuted),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kLine)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kIndigo, width: 1.5)),
              ),
              maxLines: 3,
              onChanged: (value) => description = value,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (rating > 0 && description.isNotEmpty) {
                    final result = await controller.submitReview(
                      rating,
                      booking.bookId,
                      description,
                      "Host review",
                    );
                    Navigator.of(context).pop();
                    if (result.isSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              result.message ?? "Review added successfully"),
                          backgroundColor: kSuccess,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text(result.message ?? "Failed to add review"),
                          backgroundColor: kDanger,
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill all fields')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: kIndigo,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text("Submit",
                    style: inter(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      );
    },
  );
}
