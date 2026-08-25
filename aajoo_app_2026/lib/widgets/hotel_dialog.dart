import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/controller/common_controller.dart';
import 'package:rent_home/models/properties_response_model.dart';
import 'package:shimmer/shimmer.dart';

// The REDESIGNED property page. This dialog is opened from the map on the
// current home screen, but it used to push `screens/property_page.dart` — the
// pre-redesign layout. So the homepage looked new and the property page you
// reached from it looked old, which is exactly what the client reported.
// Same constructor, same Property model (data/models re-exports it), so this
// is only a matter of pointing at the right screen.
import 'package:rent_home/ui/screens_renter/property_details/property_page.dart';
import 'package:rent_home/utils/money.dart';

class HotelDialog extends StatelessWidget {
  final String name;
  final String price;
  final List<String> imageUrls;
  final String description;
  final String rating;
  final String location;
  final String coverImage;
  final int id;
  final String lat;
  final String long;
  final dynamic inTime;
  final dynamic outTime;
  final String distance;
  final Property property;
  HotelDialog({
    super.key,
    required this.name,
    required this.location,
    required this.lat,
    required this.long,
    required this.price,
    required this.imageUrls,
    required this.description,
    required this.rating,
    required this.coverImage,
    required this.id,
    required this.inTime,
    required this.outTime,
    this.distance = "1.5",
    required this.property,
  });

  // Define default image URLs to use when imageUrls is empty
  static const List<String> defaultImageUrls = [
    'https://images.unsplash.com/photo-1618773928121-c32242e63f39?w=600&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8aG90ZWx8ZW58MHx8MHx8fDA%3D',
    'https://images.unsplash.com/photo-1455587734955-081b22074882?w=600&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8M3x8aG90ZWx8ZW58MHx8MHx8fDA%3D',
    'https://images.unsplash.com/photo-1495365200479-c4ed1d35e1aa?w=600&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTl8fGhvdGVsfGVufDB8fDB8fHww',
    'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=600&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTZ8fGhvdGVsfGVufDB8fDB8fHww',
    'https://media.istockphoto.com/id/104731717/photo/luxury-resort.jpg?s=612x612&w=0&k=20&c=cODMSPbYyrn1FHake1xYz9M8r15iOfGz9Aosy9Db7mI=',
  ];

  final formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
  final CommonController commonController = Get.find<CommonController>();

  @override
  Widget build(BuildContext context) {
    print("Amentitiess---${commonController.amenities.value.toString()}");
    // Determine which images to use for the carousel
    final List<String> carouselImages =
        imageUrls.isEmpty ? defaultImageUrls : imageUrls;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carousel Slider for Images
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) => PropertyPage(
                        property: property,
                        image: carouselImages[0],
                        name: name,
                        description: description,
                        rating: rating,
                        lat: lat,
                        long: long,
                        price: price,
                        galleryImages: carouselImages,
                        id: id,
                        location: location,
                        inTime: inTime ?? formattedDate,
                        outTime: outTime ?? formattedDate),
                  ),
                );
              },
              child: Container(
                child: CarouselSlider(
                  options: CarouselOptions(
                    height: 170.0,
                    enlargeCenterPage: false,
                    enableInfiniteScroll: true,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 5),
                  ),
                  items: carouselImages.map((url) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (context, url) => _buildShimmerEffect(),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Hotel Name and Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (BuildContext context) => PropertyPage(
                            property: property,
                            image: carouselImages[0],
                            name: name,
                            description: description,
                            lat: lat,
                            long: long,
                            id: id,
                            rating: rating,
                            price: price,
                            galleryImages: carouselImages,
                            location: location,
                            inTime: inTime,
                            outTime: outTime,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Hotel Price
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) => PropertyPage(
                      property: property,
                      image: carouselImages[0],
                      id: id,
                      name: name,
                      description: description,
                      lat: lat,
                      long: long,
                      rating: rating,
                      price: price,
                      galleryImages: carouselImages,
                      location: location,
                      inTime: inTime,
                      outTime: outTime,
                    ),
                  ),
                );
              },
              child: Text(
                "Price: ${rupeesFrom(price)}",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                textAlign: TextAlign.left,
              ),
            ),
            const SizedBox(height: 10),

            // Hotel Description
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) => PropertyPage(
                      property: property,
                      image: carouselImages[0],
                      name: name,
                      description: description,
                      rating: rating,
                      price: price,
                      id: id,
                      galleryImages: carouselImages,
                      location: location,
                      lat: lat,
                      long: long,
                      inTime: inTime,
                      outTime: outTime,
                    ),
                  ),
                );
              },
              child: Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 6.0,
              runSpacing: 6.0,
              children: List<Widget>.generate(
                property.tags?.length ?? 0,
                (int index) {
                  return Chip(
                    shape: RoundedRectangleBorder(
                        side: BorderSide(color: kprimaryColor.withAlpha(80)),
                        borderRadius: BorderRadius.circular(12)),
                    label: Text(
                      property.tags?[index].toString() ?? '',
                      style: const TextStyle(
                        color: kprimaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: kprimaryColor.withAlpha(50),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // distance
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Icon(Iconsax.location4, color: kprimaryColor, size: 15),
                const SizedBox(width: 5),
                Text(
                  "${distance.substring(0, 3)} km away from your location",
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Action Buttons and Avatar
            // SingleChildScrollView(
            //   scrollDirection: Axis.horizontal,
            //   child: Row(
            //     children: List.generate(
            //         commonController.tags.value!.data.tags.length, (index) {
            //       return Padding(
            //         padding: const EdgeInsets.symmetric(horizontal: 4.0),
            //         child: Chip(
            //           shape: const RoundedRectangleBorder(
            //               borderRadius: BorderRadius.all(Radius.circular(10))),
            //           backgroundColor: Colors.orange.shade900,
            //           label: Text(
            //               commonController.tags.value!.data.tags[index].tagName,
            //               style: const TextStyle(
            //                 color: Colors.white,
            //                 fontSize: 14,
            //                 fontWeight: FontWeight.w600,
            //               )),
            //         ),
            //       );
            //     }),
            //   ),
            // ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: GuestSelectionContainer(
                    property: property,
                    onSelectionConfirmed: (guests) {
                      // Handle the confirmed guest selection if needed
                      print('Selected $guests guests');
                    },
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(25),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (BuildContext context) => PropertyPage(
                          property: property,
                          image: carouselImages[0],
                          id: id,
                          location: location,
                          lat: lat,
                          long: long,
                          name: name,
                          description: description,
                          rating: rating,
                          price: price,
                          galleryImages: carouselImages,
                          inTime: inTime,
                          outTime: outTime,
                        ),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 25,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Shimmer Effect Widget for image loading
  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class GuestSelectionContainer extends StatefulWidget {
  final Function(int guests) onSelectionConfirmed;
  final Property property; // Add property to determine category

  const GuestSelectionContainer({
    super.key,
    required this.onSelectionConfirmed,
    required this.property,
  });

  @override
  _GuestSelectionContainerState createState() =>
      _GuestSelectionContainerState();
}

class _GuestSelectionContainerState extends State<GuestSelectionContainer> {
  int adultCount = 1;
  int childrenCount = 0;

  // Get maximum guests based on property category
  int get maxGuests {
    final category = widget.property.categoryTitles.join(',').toLowerCase();
    if (category.contains('family')) {
      return 4; // 2 adults + 2 children for family properties
    }
    return 2; // Maximum 2 guests for regular properties
  }

  // Get total guest count
  int get totalGuests => adultCount + childrenCount;

  // Check if property is family category
  bool get isFamilyProperty {
    final category = widget.property.categoryTitles.join(',').toLowerCase();
    return category.contains('family');
  }

  void _showGuestAndDaysSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Property Category Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isFamilyProperty
                              ? Icons.family_restroom
                              : Icons.person,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isFamilyProperty
                              ? 'Family Property - Max 4 guests (2 adults + 2 children)'
                              : 'Regular Property - Max 2 guests',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Adults Selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Adults',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: adultCount > 1
                                ? () {
                                    setModalState(() {
                                      adultCount--;
                                    });
                                  }
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(
                            '$adultCount',
                            style: const TextStyle(fontSize: 18),
                          ),
                          IconButton(
                            onPressed: (totalGuests < maxGuests)
                                ? () {
                                    setModalState(() {
                                      adultCount++;
                                    });
                                  }
                                : null,
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Children Selection (only for family properties)
                  if (isFamilyProperty) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Children',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: childrenCount > 0
                                  ? () {
                                      setModalState(() {
                                        childrenCount--;
                                      });
                                    }
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text(
                              '$childrenCount',
                              style: const TextStyle(fontSize: 18),
                            ),
                            IconButton(
                              onPressed: (totalGuests < maxGuests)
                                  ? () {
                                      setModalState(() {
                                        childrenCount++;
                                      });
                                    }
                                  : null,
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Total Guests Display
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'Total Guests: $totalGuests / $maxGuests',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Confirm Button
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          // Update the parent widget's state
                          widget.onSelectionConfirmed(totalGuests);
                        });
                        Navigator.pop(context); // Close the bottom sheet
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Confirm',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showGuestAndDaysSelection(context),
      child: Container(
        height: 50,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey.withOpacity(0.4),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person,
                color: Colors.black54,
              ),
              const SizedBox(width: 5),
              Text(
                isFamilyProperty && childrenCount > 0
                    ? "$adultCount Adult${adultCount > 1 ? 's' : ''} + $childrenCount Child${childrenCount > 1 ? 'ren' : ''}"
                    : "$totalGuests Guest${totalGuests > 1 ? 's' : ''}",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
