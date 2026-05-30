import 'package:animate_do/animate_do.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/data/models/properties_response_model.dart';
import 'package:rent_home/data/models/search_property_model.dart';
import 'package:rent_home/ui/screens_renter/property_details/property_page.dart';

class PreBookingCard extends StatefulWidget {
  const PreBookingCard({super.key, required this.property, this.index});
  final SearchPropertyModel property;
  final int? index;

  @override
  State<PreBookingCard> createState() => _PreBookingCardState();
}

class _PreBookingCardState extends State<PreBookingCard> {
  static const List<String> defaultImageUrls = [
    'https://images.unsplash.com/photo-1618773928121-c32242e63f39?w=600&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8aG90ZWx8ZW58MHx8MHx8fDA%3D',
    'https://images.unsplash.com/photo-1455587734955-081b22074882?w=600&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8M3x8aG90ZWx8ZW58MHx8MHx8fDA%3D',
    'https://images.unsplash.com/photo-1495365200479-c4ed1d35e1aa?w=600&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTl8fGhvdGVsfGVufDB8fDB8fHww',
    'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=600&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTZ8fGhvdGVsfGVufDB8fDB8fHww',
    'https://media.istockphoto.com/id/104731717/photo/luxury-resort.jpg?s=612x612&w=0&k=20&c=cODMSPbYyrn1FHake1xYz9M8r15iOfGz9Aosy9Db7mI=',
  ];

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final index = widget.index ?? 0;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        // Normalize possibly dynamic lists before navigation
        final List<String> imagesSafe =
            (property.images ?? []).map((e) => e.toString()).toList();
        final List<String> categoryTitlesSafe = () {
          final ct = property.categoryTitles;
          if (ct == null) return <String>[];
          if (ct is List) {
            return ct.map((e) => e.toString()).toList();
          }
          return <String>[ct.toString()];
        }();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PropertyPage(
              property: Property(
                propertyId: property.propertyId,
                propertyName: property.propertyName ?? "Unnamed Property",
                propertyAddress: property.propertyAddress ?? "No address",
                propertyDesc: property.propertyDesc ?? "No description",
                propertyPrice: property.propertyPrice ?? "0.0",
                propertyCity: property.propertyCity ?? "Unknown City",
                propertyLongitude: property.propertyLongitude ?? "0",
                propertyLatitude: property.propertyLatitude ?? "0",
                propertyHostId: property.propertyHostId,
                propertyZip: property.propertyZip,
                propertyContact: property.propertyContact,
                propDetailsPropDetailIsPetFriendly:
                    property.propDetailsPropDetailIsPetFriendly,
                propDetailsPropDetailIsSmoke:
                    property.propDetailsPropDetailIsSmoke,
                propDetailsPropDetailInTime:
                    property.propDetailsPropDetailInTime,
                propDetailsPropDetailOutTime:
                    property.propDetailsPropDetailOutTime,
                propDetailsPropDetailExtra: property.propDetailsPropDetailExtra,
                coverImage: property.coverImage,
                images: imagesSafe,
                categoryTitles: categoryTitlesSafe,
              ),
              price: property.propertyPrice.toString(),
              name: property.propertyName.toString(),
              location: property.propertyAddress.toString(),
              image: property.coverImage.toString(),
              id: property.propertyId!,
              rating: "4.5",
              description: property.propertyDesc.toString(),
              lat: property.propertyLatitude.toString(),
              long: property.propertyLongitude.toString(),
              galleryImages: imagesSafe,
              showNegotiationButton: false,
              inTime: property.propDetailsPropDetailInTime.toString(),
              outTime: property.propDetailsPropDetailOutTime.toString(),
            ),
          ),
        );
      },
      child: FadeInUp(
        duration: const Duration(milliseconds: 300),
        delay: Duration(milliseconds: 100 * index),
        child: Card(
          elevation: 1,
          color: kCream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: kCream,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Container(
                        height: 300,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(16),
                              top: Radius.circular(16)),
                          border: Border.all(
                            color: kLine,
                            width: 1,
                          ),
                          image: property.coverImage != null
                              ? DecorationImage(
                                  image: property.coverImage != null
                                      ? NetworkImage(property.coverImage!)
                                      : const AssetImage(
                                              "assets/aajoo_new_logo.png")
                                          as ImageProvider,
                                  fit: BoxFit.cover,
                                  onError: (exception, stackTrace) =>
                                      CarouselSlider(
                                        items: defaultImageUrls
                                            .map((url) => Image.network(
                                                  url,
                                                  fit: BoxFit.cover,
                                                ))
                                            .toList(),
                                        options: CarouselOptions(
                                          height: 400,
                                          autoPlay: true,
                                          aspectRatio: 16 / 9,
                                          viewportFraction: 1.0,
                                        ),
                                      ))
                              : null,
                        ),
                        child: property.coverImage == null
                            ? CarouselSlider(
                                items: defaultImageUrls
                                    .map((url) => Image.network(
                                          url,
                                          fit: BoxFit.cover,
                                        ))
                                    .toList(),
                                options: CarouselOptions(
                                  height: 400,
                                  autoPlay: true,
                                  autoPlayInterval:
                                      Duration(seconds: (1.4 * index).toInt()),
                                  aspectRatio: 16 / 9,
                                  viewportFraction: 1.0,
                                ),
                              )
                            : null,
                      ),
                    ),

                    Positioned(
                      right: 16,
                      child: IconButton(
                        icon: const Icon(
                          Icons.favorite_border,
                          color: kCream,
                        ),
                        onPressed: () {
                          // Handle favorite action
                        },
                      ),
                    ),
                    Positioned(
                        left: 16,
                        top: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: kClay,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text("Guest Favorite",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: kCream,
                                fontWeight: FontWeight.bold,
                              )),
                        )),
                    // Luxury Badge
                    if (property.isLuxury == 1)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: kClay,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            "Luxury",
                            style: TextStyle(
                              color: kCream,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                // Details Section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Property Name
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            property.propertyName ?? "Unnamed Property",
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Row(children: [
                            Icon(
                              Icons.star,
                              color: Colors.amber[700],
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "4.5",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ]),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Address and City
                      Row(
                        children: [
                          Text(
                            "${property.propertyAddress ?? 'No address'}, ${property.propertyCity ?? 'Unknown City'}",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text("Free Cancellation",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          )),
                      // show check-in and check-out times if available
                      if (property.propDetailsPropDetailInTime != null &&
                          property.propDetailsPropDetailOutTime != null)
                        Text(
                          "Check-in: ${property.propDetailsPropDetailInTime} | Check-out: ${property.propDetailsPropDetailOutTime}",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),

                      //desc

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  "Rs. ${property.propertyPrice ?? 'N/A'}",
                                  style: const TextStyle(
                                    decoration: TextDecoration.underline,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "for a night",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Amenities
                      // Wrap(
                      //   spacing: 12,
                      //   runSpacing: 8,
                      //   children: [
                      //     if (property
                      //             .propDetailsPropDetailInTime !=
                      //         null)
                      //       _buildAmenityChip(Icons.access_time,
                      //           "Check-in: ${property.propDetailsPropDetailInTime}"),
                      //     if (property
                      //             .propDetailsPropDetailOutTime !=
                      //         null)
                      //       _buildAmenityChip(Icons.access_time,
                      //           "Check-out: ${property.propDetailsPropDetailOutTime}"),
                      //   ],
                      // ),
                      const SizedBox(height: 16),
                      // View Details Button
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
