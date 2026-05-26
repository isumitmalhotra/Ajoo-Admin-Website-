import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HotelOffersPage extends StatefulWidget {
  const HotelOffersPage({super.key});

  @override
  _HotelOffersPageState createState() => _HotelOffersPageState();
}

class _HotelOffersPageState extends State<HotelOffersPage> {
  // Sample hotel offers data
  List<Map<String, dynamic>> hotelOffers = [
    {
      'name': 'Grand Serenity Hotel',
      'image': 'https://images.unsplash.com/photo-1566073771259-6a8506099945',
      'roomType': 'Deluxe Suite',
      'price': 250.0,
      'rating': 4.5,
    },
    {
      'name': 'Ocean Breeze Resort',
      'image': 'https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9',
      'roomType': 'Premium Room',
      'price': 220.0,
      'rating': 4.2,
    },
    {
      'name': 'Cityscape Inn',
      'image': 'https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9',
      'roomType': 'Standard Room',
      'price': 180.0,
      'rating': 3.8,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    final bookingDetails = {
      'checkIn': DateTime.now(),
      'checkOut': DateTime.now().add(Duration(days: 1)),
      'guests': 2,
      'roomType': 'Deluxe Suite',
    };

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Hotel Offers",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Booking Request Summary
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Your Booking Request",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildDetailRow(
                      icon: Icons.calendar_today,
                      label: "Check-In",
                      value: DateFormat('MMM dd, yyyy').format(DateTime.now()),
                    ),
                    SizedBox(height: 8),
                    _buildDetailRow(
                      icon: Icons.calendar_today,
                      label: "Check-Out",
                      value: DateFormat('MMM dd, yyyy').format(
                        DateTime.now().add(Duration(days: 1)),
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildDetailRow(
                      icon: Icons.hotel,
                      label: "Room Type",
                      value: "AC Deluxe Room",
                    ),
                    SizedBox(height: 8),
                    _buildDetailRow(
                      icon: Icons.person,
                      label: "Guests",
                      value: "4 Adults",
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Offers List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "Available Offers",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: hotelOffers.length,
              itemBuilder: (context, index) {
                final offer = hotelOffers[index];
                return Card(
                  elevation: 4,
                  margin: EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            offer['image'],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                offer['name'],
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                offer['roomType'],
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: List.generate(5, (starIndex) {
                                  return Icon(
                                    starIndex < offer['rating'].floor()
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: 20,
                                  );
                                }),
                              ),
                              SizedBox(height: 4),
                              Text(
                                formatter.format(offer['price']),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            ElevatedButton(
                              onPressed: () =>
                                  _showNegotiationDialog(context, offer, index),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                "Negotiate",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Accepted offer from ${offer['name']} for ${formatter.format(offer['price'])}!",
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                "Accept",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showNegotiationDialog(
      BuildContext context, Map<String, dynamic> offer, int index) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    double negotiationPrice = offer['price'];
    TextEditingController offerController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                "Negotiate with ${offer['name']}",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Current Offer: ${formatter.format(negotiationPrice)}",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setDialogState(() {
                              negotiationPrice -= 10;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            "- \$10",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setDialogState(() {
                              negotiationPrice += 10;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            "+ \$10",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: offerController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "Enter your offer",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    double? customOffer = double.tryParse(offerController.text);
                    if (customOffer != null && customOffer > 0) {
                      negotiationPrice = customOffer;
                    }
                    setState(() {
                      hotelOffers[index]['price'] = negotiationPrice;
                      // Simulate host response
                      hotelOffers[index]['price'] =
                          negotiationPrice * 0.98; // Slight adjustment
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Offered ${formatter.format(negotiationPrice)} to ${offer['name']}. Host countered with ${formatter.format(hotelOffers[index]['price'])}.",
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    "Submit Offer",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(
      {required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
        Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
