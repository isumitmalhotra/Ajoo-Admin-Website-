import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/controller/booking_controller.dart';
import 'package:rent_home/controller/user_controller.dart';
import 'package:rent_home/models/ongoing_reponse.dart';
import 'package:rent_home/screens/Home/view_ongoing_booking.dart';
import 'package:rent_home/service/device_service.dart';

class OngoingBookingWidget extends StatefulWidget {
  final UserController userController;

  const OngoingBookingWidget({
    super.key,
    required this.userController,
  });

  @override
  _OngoingBookingWidgetState createState() => _OngoingBookingWidgetState();
}

class _OngoingBookingWidgetState extends State<OngoingBookingWidget> {
  // bool _isLoading = true; // Flag to manage loading state (unused)

  @override
  void initState() {
    super.initState();
    // _fetchOngoingBookings(); // Call the fetch function on widget initialization
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    final bookings =
        widget.userController.ongoingBookings.value?.data.bookings ?? [];
    final latestBooking = bookings.isNotEmpty ? bookings.first : null;
    final hasMultipleBookings = bookings.length > 1;

    // Show loading indicator while fetching data

    // Get the latest ongoing booking

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Booking card
        _buildBookingCard(context, latestBooking),
        if (hasMultipleBookings) _buildViewAllButton(context),
      ],
    );
  }

  Widget _buildViewAllButton(BuildContext context) {
    return InkWell(
      onTap: () {
        _showAllBookingsBottomSheet(context);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            "View all",
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).primaryColor,
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down,
            color: Theme.of(context).primaryColor,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Booking? booking) {
    final theme = Theme.of(context);

    // If no booking, show a friendly placeholder
    if (booking == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OngoingBookingView(booking: booking),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.canvasColor,
          borderRadius: const BorderRadius.only(
            bottomRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Property details
            Row(
              children: [
                // Property image

                const SizedBox(width: 12),
                // Property name and status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Wrap(
                        children: [
                          Text(
                            booking.bookingPropertyPropertyName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(width: 8),
                          Text("(${booking.bookingStatusBsTitle})",
                              style: TextStyle(
                                color:
                                    booking.bookingStatusBsTitle == "Completed"
                                        ? Colors.green
                                        : booking.bookingStatusBsTitle ==
                                                "Cancelled"
                                            ? Colors.red
                                            : Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Booking Id: ${booking.bookId}",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (booking.bookDetails != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          "From: ${booking.bookDetails!.btBookFrom} To: ${booking.bookDetails!.btBookTo}",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    // Show loading dialog
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return const Dialog(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 20, horizontal: 24),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(width: 20),
                                Text("Getting property location..."),
                              ],
                            ),
                          ),
                        );
                      },
                    );

                    try {
                      // Simulate fetching property data
                      Map mapdata =
                          await BookingController().getPropertyLatLong(
                        booking.bookingPropertyPropertyId,
                      );

                      if (mapdata.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Invalid property coordinates")),
                        );
                        return;
                      }

                      //   Close loading dialog
                      Navigator.of(context, rootNavigator: true).pop();

                      // Simulate coordinates (replace with actual data)
                      var lat = mapdata['latitude'];
                      var long = mapdata['longitude'];

                      if (lat == "0.0" || long == "0.0") {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Invalid property coordinates")),
                        );
                        return;
                      }
                      print("Coordinates: $lat, $long");
                      final latitude = double.tryParse(lat.toString()) ?? 0.0;
                      final longitude = double.tryParse(long.toString()) ?? 0.0;
                      DeviceService.showMapOptions(
                          context, latitude, longitude);
                    } catch (e) {
                      // Close loading dialog if still showing
                      if (Navigator.canPop(context)) {
                        Navigator.of(context, rootNavigator: true).pop();
                      }

                      // Show error message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                "Failed to get directions: ${e.toString()}")),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: theme.primaryColor,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    backgroundColor: theme.primaryColor.withOpacity(0.1),
                    foregroundColor: theme.primaryColor,
                  ),
                  child: RotatedBox(
                    quarterTurns: 0,
                    child: Icon(
                      Icons.directions,
                      size: 20,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.arrow_right_sharp,
                  color: kprimaryColor,
                  size: 24,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAllBookingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final bookings =
            widget.userController.ongoingBookings.value?.data.bookings ?? [];
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "All Ongoing Stays",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: bookings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.event_busy,
                                size: 36, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(
                              'No ongoing bookings',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: bookings.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _buildBookingCard(
                            context,
                            bookings[index],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
    );
  }

  // Helper method to parse dates in format dd-MM-yyyy
  DateTime _parseDate(String dateString) {
    final parts = dateString.split('-');
    if (parts.length != 3) {
      return DateTime.now(); // Fallback to today if parse fails
    }

    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);

    return DateTime(year, month, day);
  }
}
