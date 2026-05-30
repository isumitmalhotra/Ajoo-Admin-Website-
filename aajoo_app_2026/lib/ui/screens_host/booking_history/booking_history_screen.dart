import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/ui/screens_host/host_controller.dart';
import 'package:rent_home/data/models/booking_history_response_model.dart';
import 'package:rent_home/data/models/host_booking_history_model.dart';
// import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:rent_home/ui/screens_host/booking_history/host_booking_history_controller.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  @override
  late final HostBookingHistoryController controller;
  @override
  void initState() {
    super.initState();
    controller = Get.put(HostBookingHistoryController());
    controller.getHostBookingHistory();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSand,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Booking History'),
        backgroundColor: kprimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        Widget content;

        // 🔹 Main content logic
        if (controller.hostBookingHistoryResponse.value == null) {
          content = const Center(child: CircularProgressIndicator());
        } else if (controller.hostBookingHistoryResponse.value!.data!.isEmpty) {
          content = const Center(child: Text("No Booking History"));
        } else {
          content = ListView.builder(
            itemCount:
                controller.hostBookingHistoryResponse.value!.data!.length,
            itemBuilder: (context, index) {
              final booking =
                  controller.hostBookingHistoryResponse.value!.data![index];
              return GestureDetector(
                onTap: () {
                  // Handle tap event
                },
                child: _buildCard(booking, controller),
              );
            },
          );
        }

        // 🔹 Stack for loader overlay
        return Stack(
          children: [
            content,
            if (controller.isSubmittingReview.value)
              Container(
                color: kInk.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        );
      }),
    );
  }
}
// Add this dependency

void _buildReviewDialog(BuildContext context, HostBookingHistory booking,
    HostBookingHistoryController controller) {
  String title = '';
  int rating = 0;
  String description = '';

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Give Review"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title input

            const SizedBox(height: 10),

            // Rating bar
            const Text("Rate user experience"),
            const SizedBox(height: 10),
            RatingBar.builder(
              initialRating: 0,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 5,
              itemSize: 50.0,
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (value) {
                rating = value.toInt();
              },
            ),
            const SizedBox(height: 20),

            // Description input
            TextField(
              decoration: const InputDecoration(
                  hintText: "Enter your review", border: OutlineInputBorder()),
              maxLines: 3,
              onChanged: (value) {
                description = value;
              },
            ),
            const SizedBox(height: 10),

            // Submit button
            ElevatedButton(
              onPressed: () async {
                // Handle review submission with title, rating, and description
                if (rating > 0 && description.isNotEmpty) {
                  final result = await controller.submitReview(
                    rating,
                    booking.bookId,
                    description,
                    "Host review",
                  );

                  Navigator.of(context).pop(); // close dialog

                  if (result.isSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text(result.message ?? "Review added successfully"),
                        backgroundColor: kSuccess,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result.message ?? "Failed to add review"),
                        backgroundColor: kDanger,
                      ),
                    );
                  }
                } else {
                  // Show error or prompt for missing fields
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: kprimaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text("Submit"),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildCard(
    HostBookingHistory booking, HostBookingHistoryController controller) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: kCream,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: kInk.withOpacity(0.06),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔹 Booking ID + Status
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Booking #${booking.bookId}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kprimaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  booking.bookingStatusBsTitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: kprimaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // Invoice
        Text(
          "Invoice: ${booking.bookInvoice}",
          style: TextStyle(fontSize: 13, color: kMuted),
        ),

        const SizedBox(height: 14),

        // 💰 Price + Payment
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "₹ ${booking.bookPrice}",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: kprimaryColor,
              ),
            ),
            Text(
              booking.bookIsCod ? "Cash on Delivery" : "Online Payment",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: kInk2,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 👤 User Details Box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kSand,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booking.userDetailsUserFullName ?? "Unknown User",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "From: ${booking.bookDetailsBtBookFrom}",
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                "To: ${booking.bookDetailsBtBookTo}",
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                "Contact: ${booking.userDetailsUserPnumber}",
                style: TextStyle(fontSize: 13, color: kInk2),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 12),

        // 📅 Date + Action
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Booked on ${booking.bookAddedAt?.day}/${booking.bookAddedAt?.month}/${booking.bookAddedAt?.year}",
              style: TextStyle(fontSize: 12, color: kMuted),
            ),
            if (booking.bookingStatusBsTitle == "Check Out ")
              ElevatedButton(
                onPressed: () {
                  _buildReviewDialog(Get.context!, booking, controller);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kprimaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Give Review",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}
