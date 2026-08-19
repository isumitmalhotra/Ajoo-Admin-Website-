import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/widgets/app_ui.dart' show withDividers;
import 'package:rent_home/ui/screens_host/host_controller.dart';
import 'package:rent_home/data/models/host_ongoing_response.dart';
import 'package:rent_home/service/device_service.dart';

class ViewOngoingBookingPage extends StatefulWidget {
  final Booking booking;

  const ViewOngoingBookingPage({super.key, required this.booking});

  @override
  State<ViewOngoingBookingPage> createState() => _ViewOngoingBookingPageState();
}

class _ViewOngoingBookingPageState extends State<ViewOngoingBookingPage> {
  final hostController = Get.find<HostController>();

  @override
  Widget build(BuildContext context) {
    // Avoid accessing first when list could be empty
    try {
      if (widget.booking.attachments.isNotEmpty) {
        print(widget.booking.attachments.first);
      } else {
        print("No attachments for this booking");
      }
    } catch (_) {}
    return Scaffold(
      appBar: AppBar(
        foregroundColor: kInk,
        title: Text(
          'Booking Details',
          style:
              fraunces(fontSize: 18, fontWeight: FontWeight.w700, color: kInk),
        ),
        backgroundColor: kSand,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.white),
            onPressed: () {
              DeviceService()
                  .launchPhone(widget.booking.userDetailsUserPnumber);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Guest Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kprimaryColor, kprimaryColor.withOpacity(0.8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Text(
                          widget.booking.userDetailsUserFullName.isNotEmpty
                              ? widget.booking.userDetailsUserFullName[0]
                                  .toUpperCase()
                              : 'G',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: kprimaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.booking.userDetailsUserFullName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.phone,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.booking.userDetailsUserPnumber,
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
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Booking Details Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Booking Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kprimaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...withDividers([
                          _buildDetailRow(
                            'Booking ID',
                            widget.booking.bookId,
                            Icons.confirmation_number,
                          ),
                          _buildDetailRow(
                            'Status',
                            widget.booking.bookingStatusBsTitle,
                            Icons.info,
                            statusColor: _getStatusColor(
                                widget.booking.bookingStatusBsTitle),
                          ),
                          _buildDetailRow(
                            'Check-in Date',
                            _formatDate(widget.booking.bookDetailsBtBookFrom),
                            Icons.login,
                          ),
                          _buildDetailRow(
                            'Check-out Date',
                            _formatDate(widget.booking.bookDetailsBtBookTo),
                            Icons.logout,
                          ),
                          _buildDetailRow(
                            'Duration',
                            _calculateDuration(
                              widget.booking.bookDetailsBtBookFrom,
                              widget.booking.bookDetailsBtBookTo,
                            ),
                            Icons.schedule,
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Guest Contact Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Guest Contact',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kprimaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: kprimaryColor.withOpacity(0.1),
                            child: const Icon(
                              Icons.phone,
                              color: kprimaryColor,
                            ),
                          ),
                          title: const Text('Phone Number'),
                          subtitle: Text(widget.booking.userDetailsUserPnumber),
                          trailing: IconButton(
                            icon: const Icon(Icons.call, color: kSuccess),
                            onPressed: () {
                              DeviceService().launchPhone(
                                  widget.booking.userDetailsUserPnumber);
                            },
                          ),
                        ),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: kSuccess.withOpacity(0.1),
                            child: const Icon(
                              Icons.chat,
                              color: kSuccess,
                            ),
                          ),
                          title: const Text('WhatsApp'),
                          subtitle: const Text('Send message'),
                          trailing: IconButton(
                            icon: Image.asset(
                              "assets/whatsapp.png",
                              width: 24,
                              height: 24,
                              color: kSuccess,
                            ),
                            onPressed: () {
                              DeviceService.launchWhatsapp(
                                phoneNumber:
                                    widget.booking.userDetailsUserPnumber,
                                message:
                                    "Hello ${widget.booking.userDetailsUserFullName}, regarding your booking ${widget.booking.bookId}",
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Attachments (if any)
            if (widget.booking.attachments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Attachments',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: kprimaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Add attachment widgets here if needed
                          Text(
                              '${widget.booking.attachments.length} attachment(s)'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        DeviceService()
                            .launchPhone(widget.booking.userDetailsUserPnumber);
                      },
                      icon: const Icon(Icons.call, color: Colors.white),
                      label: const Text('Call Guest'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kSuccess,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        DeviceService.launchWhatsapp(
                          phoneNumber: widget.booking.userDetailsUserPnumber,
                          message:
                              "Hello ${widget.booking.userDetailsUserFullName}, regarding your booking ${widget.booking.bookId}",
                        );
                      },
                      icon: Image.asset(
                        "assets/whatsapp.png",
                        width: 20,
                        height: 20,
                        color: Colors.white,
                      ),
                      label: const Text('Message on WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kprimaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon,
      {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kprimaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: kprimaryColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12.5, color: kMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: statusColor ?? kInk,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _calculateDuration(String fromDate, String toDate) {
    try {
      final from = DateTime.parse(fromDate);
      final to = DateTime.parse(toDate);
      final difference = to.difference(from).inDays;
      return '$difference ${difference == 1 ? 'day' : 'days'}';
    } catch (e) {
      return 'N/A';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'paid':
        return Colors.green;
      case 'pending':
      case 'payment pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'checked in':
        return Colors.blue;
      case 'checked out':
        return Colors.purple;
      default:
        return Colors.black87;
    }
  }
}
