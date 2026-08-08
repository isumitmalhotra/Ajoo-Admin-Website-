import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:rent_home/models/ongoing_reponse.dart';
import 'package:rent_home/models/single_property_response.dart';
import 'package:dio/dio.dart' as dio;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:lottie/lottie.dart';

class HotelCheckoutPage extends StatefulWidget {
  const HotelCheckoutPage(
      {super.key, required this.property, required this.booking});
  final SinglePropertyData property;
  final Booking booking;

  @override
  _HotelCheckoutPageState createState() => _HotelCheckoutPageState();
}

class _HotelCheckoutPageState extends State<HotelCheckoutPage> {
  DateTime checkInDate = DateTime.now();
  DateTime checkOutDate = DateTime.now().add(const Duration(days: 1));
  String roomType = "Deluxe Suite"; // Placeholder, update if available in model
  int guests = 1; // Placeholder, update if available in model
  double propertyRating = 3.0;
  double hostRating = 3.0;
  double platformRating = 3.0;
  TextEditingController reviewController = TextEditingController();
  String selectedPaymentMethod = "Credit Card";
  List<File> selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  final dio.Dio _dio = dio.Dio();
  final int maxImages = 5; // Image limit
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Attempt to parse inTime and outTime if available
    if (widget.property.propDetails?.inTime != null) {
      try {
        checkInDate = DateFormat('yyyy-MM-dd')
            .parse(widget.property.propDetails!.inTime!);
      } catch (e) {
        print('Error parsing inTime: $e');
      }
    }
    if (widget.property.propDetails?.outTime != null) {
      try {
        checkOutDate = DateFormat('yyyy-MM-dd')
            .parse(widget.property.propDetails!.outTime!);
      } catch (e) {
        print('Error parsing outTime: $e');
      }
    }
    _dio.interceptors.add(PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        compact: true,
        error: true,
        maxWidth: 90));
  }

  Future<void> _pickImages() async {
    if (selectedImages.length >= maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum $maxImages images allowed')),
      );
      return;
    }

    final List<XFile> images = await _picker.pickMultiImage();

    if (images.isNotEmpty) {
      List<File> newImages = images.map((xFile) => File(xFile.path)).toList();

      // Check if adding new images would exceed the limit
      if (selectedImages.length + newImages.length > maxImages) {
        int remainingSlots = maxImages - selectedImages.length;
        newImages = newImages.take(remainingSlots).toList();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Only $remainingSlots more images can be added')),
        );
      }

      setState(() {
        selectedImages.addAll(newImages);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
    });
  }

  void _showLoadingDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Loading',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) {
        return Center(
          child: Container(
            width: 160,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  'assets/Animation - 1750412011914.json',
                  width: 100,
                  height: 100,
                  repeat: true,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Submitting...',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: child,
        );
      },
    );
  }

  Future<void> _submitReview() async {
    if (_isSubmitting) return; // guard
    setState(() => _isSubmitting = true);
    _showLoadingDialog();

    final token = await const FlutterSecureStorage().read(key: 'user_token');
    const url = 'https://aajaodev.onrender.com/review/user/checkout';
    Logger().f("Submitting review to $url with token $token");

    try {
      dio.FormData formData = dio.FormData.fromMap({
        'propertyId': widget.property.propertyId ?? 1,
        'hostId': widget.property.propertyHostId ?? 1,
        'desription': reviewController.text,
        'propertyRating': propertyRating.toInt(),
        'hostRating': hostRating.toInt(),
        'bookingId': widget.booking.bookId.toString(),
        'platformRating': platformRating.toInt(),
      });

      for (int i = 0; i < selectedImages.length; i++) {
        formData.files.add(MapEntry(
          'userReview_img',
          await dio.MultipartFile.fromFile(
            selectedImages[i].path,
            filename: selectedImages[i].path.split('/').last,
          ),
        ));
      }

      Logger().f("FormData prepared with ${formData.files.length} images");
      Logger().f("FormData prepared with ${formData.fields.toString()} fields");

      final response = await _dio.post(
        url,
        data: formData,
        options: dio.Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final responseData = response.data;
      final success =
          (response.statusCode == 200 || response.statusCode == 201) &&
              responseData['success'] == true;

      if (success) {
        setState(() {
          propertyRating = 1.0;
          hostRating = 1.0;
          platformRating = 1.0;
          reviewController.clear();
          selectedImages.clear();
        });
        Navigator.of(context, rootNavigator: true).maybePop(); // close loader
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!')),
        );
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const ThankYouDialog(),
        );
      } else {
        Navigator.of(context, rootNavigator: true).maybePop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed: ${responseData['message'] ?? response.statusCode}')),
        );
      }
    } catch (e) {
      Navigator.of(context, rootNavigator: true).maybePop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit review: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    // Calculate price breakdown
    final roomCharges = widget.booking.bookPrice.toDouble();
    // GST: ≤₹7500 => 5%, >₹7500 => 18% (matches backend tariff GST)
    final gstRate = roomCharges <= 7500 ? 0.05 : 0.18;
    final taxesAndFees = roomCharges * gstRate;
    final totalPrice = roomCharges + taxesAndFees;

    // Determine image URL
    final imageUrl = widget.property.images?.isNotEmpty ?? false
        ? widget.property.images!.first
        : widget.booking.propertyImage ??
            'https://images.unsplash.com/photo-1566073771259-6a8506099945';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
        ),
        title: Text(
          "Checkout",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: AbsorbPointer(
        absorbing: _isSubmitting,
        child: Opacity(
          opacity: _isSubmitting ? 0.6 : 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hotel Header
                Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        Image.network(
                          imageUrl,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.network(
                            'https://images.unsplash.com/photo-1566073771259-6a8506099945',
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black54],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.property.propertyName ??
                                      widget
                                          .booking.bookingPropertyPropertyName,
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.property.propertyAddress ??
                                      'No address available',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Booking Details
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Booking Details",
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          icon: Icons.confirmation_number,
                          label: "Booking ID",
                          value: widget.booking.bookId,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          icon: Icons.calendar_today,
                          label: "Check-In",
                          value: DateFormat('MMM dd, yyyy').format(checkInDate),
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          icon: Icons.calendar_today,
                          label: "Check-Out",
                          value:
                              DateFormat('MMM dd, yyyy').format(checkOutDate),
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          icon: Icons.hotel,
                          label: "Room Type",
                          value: roomType,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          icon: Icons.person,
                          label: "Guests",
                          value: "$guests Adults",
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          icon: Icons.info,
                          label: "Status",
                          value: widget.booking.bookingStatusBsTitle,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Price Breakdown
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Price Breakdown",
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildPriceRow(
                            "Room Charges", formatter.format(roomCharges)),
                        const SizedBox(height: 8),
                        _buildPriceRow(
                            "Taxes & Fees (${(gstRate * 100).toStringAsFixed(0)}%)",
                            formatter.format(taxesAndFees)),
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),
                        _buildPriceRow("Total", formatter.format(totalPrice),
                            isTotal: true),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Review Section
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Rate Your Experience",
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text("Property Rating",
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[700])),
                        const SizedBox(height: 8),
                        _buildRatingSlider(
                          value: propertyRating,
                          onChanged: (value) {
                            setState(() {
                              propertyRating = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        Text("Host Rating",
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[700])),
                        const SizedBox(height: 8),
                        _buildRatingSlider(
                          value: hostRating,
                          onChanged: (value) {
                            setState(() {
                              hostRating = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        Text("Platform Rating",
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[700])),
                        const SizedBox(height: 8),
                        _buildRatingSlider(
                          value: platformRating,
                          onChanged: (value) {
                            setState(() {
                              platformRating = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: reviewController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: "Share your feedback (optional)",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Add Photos (Optional)',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800])),
                            Text('${selectedImages.length}/$maxImages',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[600])),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (selectedImages.length < maxImages)
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: _pickImages,
                              icon: const Icon(Icons.add_photo_alternate,
                                  color: Colors.blue),
                              label: const Text('Add Photos',
                                  style: TextStyle(color: Colors.blue)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.blue),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        if (selectedImages.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: selectedImages.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(selectedImages[index],
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () => _removeImage(index),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                                color: Colors.red,
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                            child: const Icon(Icons.close,
                                                color: Colors.white, size: 16),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _isSubmitting
                          ? const Row(
                              key: ValueKey('loading'),
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white)),
                                ),
                                SizedBox(width: 12),
                                Text('Submitting...',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                              ],
                            )
                          : Text(
                              'Checkout Now',
                              key: const ValueKey('text'),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingSlider({
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        // Emoji display
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getEmojiColor(value).withOpacity(0.1),
            border: Border.all(
              color: _getEmojiColor(value),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              _getEmoji(value),
              style: const TextStyle(fontSize: 36),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Rating value display
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star,
              color: _getEmojiColor(value),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              value.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _getEmojiColor(value),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              "/ 5.0",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 8,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
            activeTrackColor: _getEmojiColor(value),
            inactiveTrackColor: Colors.grey[300],
            thumbColor: _getEmojiColor(value),
            overlayColor: _getEmojiColor(value).withOpacity(0.2),
            valueIndicatorColor: _getEmojiColor(value),
            valueIndicatorTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: Slider(
            value: value,
            min: 1.0,
            max: 5.0,
            divisions: 8, // This gives us 0.5 increments
            onChanged: onChanged,
            label: value.toStringAsFixed(1),
          ),
        ),

        // Rating labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Poor",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                "Average",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                "Excellent",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getEmoji(double rating) {
    if (rating < 3.0) {
      return "😞"; // Sad face for < 3 stars
    } else if (rating == 3.0) {
      return "😐"; // Normal face for 3 stars
    } else {
      return "😊"; // Happy face for > 3 stars
    }
  }

  Color _getEmojiColor(double rating) {
    if (rating < 3.0) {
      return Colors.red; // Red for sad
    } else if (rating == 3.0) {
      return Colors.orange; // Orange for normal
    } else {
      return Colors.green; // Green for happy
    }
  }

  Widget _buildDetailRow(
      {required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.black87 : Colors.grey[700],
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? Colors.black87 : Colors.grey[700],
          ),
        ),
      ],
    );
  }
}

class ThankYouDialog extends StatelessWidget {
  const ThankYouDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text(
        "Thank You!",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: const Text(
        "We appreciate your feedback. Your review has been submitted.",
        style: TextStyle(fontSize: 16),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context); // Close dialog
            Get.offAndToNamed("/home"); // Navigate to root route
          },
          child: Text(
            "OK",
            style: TextStyle(
              color: theme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
