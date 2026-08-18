import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/data/models/booking_history_response_model.dart';
import 'package:rent_home/ui/screens_renter/history/history_description/history_description_page.dart';
import '../../../../utils/booking_status.dart';
import '../../../../utils/stay_clock.dart';

class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.booking,
  });

  final BookingHistoryData booking;

  @override
  Widget build(BuildContext context) {
    // Lifecycle and payment are separate questions; see utils/booking_status.
    final life = lifecycleLabel(
      booking.bookingStatusBsTitle,
      ended: hasEnded(booking.bookDetailsBtBookTo),
      started: isStaying(
          booking.bookDetailsBtBookFrom, booking.bookDetailsBtBookTo),
    );
    final pay =
        paymentBadge(isPaid: booking.bookIsPaid, isCod: booking.bookIsCod);
    final bookedDate = booking.bookAddedAt is DateTime
        ? booking.bookAddedAt as DateTime
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: kCream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kLine, width: 1),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Booked Date
            if (bookedDate != null)
              Text(
                "Booked on: ${DateFormat.yMMMMEEEEd().format(bookedDate)}",
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),

            const SizedBox(height: 8),

            /// Property Name
            Text(
              booking.bookingPropertyPropertyName ?? '',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            /// Address
            Text(
              booking.bookingPropertyPropertyAddress ?? '',
              style: TextStyle(color: Colors.grey[700], fontSize: 15),
            ),

            const Divider(height: 24),

            /// Booking Dates
            Row(
              children: [
                Expanded(
                  child: _dateText("From", booking.bookDetailsBtBookFrom),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _dateText("To", booking.bookDetailsBtBookTo),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// Amount & Status
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kSand,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Amount: ₹${booking.book_price ?? 0}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // "Paid" and "Booking Confirmed" were shown in the same slot
                  // as if they were the same kind of answer. They are not — one
                  // is about the money, the other about the stay — so the card
                  // now shows both, each in its own place.
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        life,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: lifecycleColors(life).$2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pay.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: pay.fg,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            /// View Details Button
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                onPressed: () {
                  Get.to(
                    () => HistoryDescriptionPage(
                      bookingData: booking,
                      propertyId: booking.bookPropId!,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kprimaryColor,
                  foregroundColor: kcontentColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("View Details"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helpers

  Widget _dateText(String label, String? value) {
    return Text(
      "$label: ${value ?? '-'}",
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    );
  }

}
