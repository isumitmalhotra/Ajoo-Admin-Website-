import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/data/models/properties_response_model.dart';
import 'package:rent_home/service/bookmark_service.dart';
import 'package:rent_home/ui/screens_renter/property_details/property_page.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:shimmer/shimmer.dart';

class PreBookingHomeCarousel extends StatefulWidget {
  final List<Property> properties;
  final bool isLoading;
  final String title;
  final VoidCallback? onSeeAll;

  const PreBookingHomeCarousel({
    super.key,
    required this.properties,
    this.isLoading = false,
    this.title = "Featured Properties",
    this.onSeeAll,
  });

  @override
  State<PreBookingHomeCarousel> createState() => _PreBookingHomeCarouselState();
}

class _PreBookingHomeCarouselState extends State<PreBookingHomeCarousel> {
  final BookmarkService _bookmarks = BookmarkService();
  final Set<int> _saved = <int>{};

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final list = await _bookmarks.getBookmarks();
    if (!mounted) return;
    setState(() {
      _saved
        ..clear()
        ..addAll(list.map((p) => p.propertyId));
    });
  }

  Future<void> _toggleSaved(Property property) async {
    // Flip immediately so the tap feels answered, then reconcile with whatever
    // the server actually did.
    setState(() {
      _saved.contains(property.propertyId)
          ? _saved.remove(property.propertyId)
          : _saved.add(property.propertyId);
    });
    await _bookmarks.toggleBookmark(property);
    await _loadSaved();
  }

  /// The listing's own category, or null when it has none — so the badge is
  /// absent rather than asserting something untrue.
  String? _badge(Property property) {
    for (final source in [property.categoryTitles, property.categories]) {
      if (source == null) continue;
      for (final value in source) {
        final label = value.trim();
        if (label.isNotEmpty) return label;
      }
    }
    return null;
  }

  static const List<String> defaultImageUrls = [
    'https://images.unsplash.com/photo-1618773928121-c32242e63f39?w=600&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8aG90ZWx8ZW58MHx8MHx8fDA%3D',
    'https://images.unsplash.com/photo-1455587734955-081b22074882?w=600&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8M3x8aG90ZWx8ZW58MHx8MHx8fDA%3D',
    'https://images.unsplash.com/photo-1495365200479-c4ed1d35e1aa?w=600&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTl8fGhvdGVsfGVufDB8fDB8fHww',
    'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=600&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTZ8fGhvdGVsfGVufDB8fDB8fHww',
    'https://media.istockphoto.com/id/104731717/photo/luxury-resort.jpg?s=612x612&w=0&k=20&c=cODMSPbYyrn1FHake1xYz9M8r15iOfGz9Aosy9Db7mI=',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        if (widget.onSeeAll != null)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: widget.onSeeAll,
                  child: Text(
                    "See All",
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Horizontal Scrollable Row
        SizedBox(
          height: 290,
          child: widget.isLoading
              ? _buildLoadingRow()
              : widget.properties.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      itemCount: widget.properties.length,
                      itemBuilder: (context, index) {
                        final property = widget.properties[index];
                        return _buildPropertyCard(property, index, theme);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildPropertyCard(Property property, int index, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              final imagesSafe =
                  property.images.map((e) => e.toString()).toList();

              return PropertyPage(
                property: property,
                price: property.propertyPrice,
                name: property.propertyName,
                location: property.propertyAddress,
                image: property.coverImage ?? "",
                id: property.propertyId,
                rating: "4.5",
                description: property.propertyDesc,
                lat: property.propertyLatitude,
                long: property.propertyLongitude,
                galleryImages: imagesSafe,
                inTime: property.propDetailsPropDetailInTime,
                outTime: property.propDetailsPropDetailOutTime,
              );
            },
          ),
        );
      },
      child: Container(
        width: 280,
        height: 300, // ✅ KEEP FIXED HEIGHT
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: kCream,
          border: Border.all(color: kLine),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 IMAGE SECTION
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.network(
                    property.coverImage ??
                        defaultImageUrls[index % defaultImageUrls.length],
                    height: 170, // 🔥 reduced slightly for space balance
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 170,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),

                /// ❤️ Favorite Button — saves to the same list the Saved tab
                /// and the property page read. It was an empty handler, so the
                /// heart on every card was decoration.
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: kCream.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _saved.contains(property.propertyId)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () => _toggleSaved(property),
                    ),
                  ),
                ),

                /// 🏷 Category badge — the property's own type.
                ///
                /// This said "Guest Favorite" on every card, unconditionally.
                /// Nothing in the data backs that claim, so every listing on
                /// the home screen was advertised as a guest favourite.
                if (_badge(property) != null)
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: kClay,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _badge(property)!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: kCream,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            /// 🔹 DETAILS SECTION (SAFE)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: SingleChildScrollView(
                  physics:
                      const NeverScrollableScrollPhysics(), // prevent scroll UI
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Title + Rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              property.propertyName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          // Real average, or "New" when unreviewed. This was
                          // a hardcoded 4.5 on every card.
                          Row(
                            children: [
                              if (property.rating != null) ...[
                                Icon(Icons.star,
                                    color: Colors.amber[700], size: 16),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                property.rating != null
                                    ? '${property.ratingLabel} (${property.reviewCount})'
                                    : 'New',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      /// Address
                      Text(
                        "${property.propertyAddress}, ${property.propertyCity}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),

                      const SizedBox(height: 4),

                      // "Free Cancellation" was printed on every card
                      // with no cancellation-policy field behind it. The
                      // real policy is per-property and shown on the
                      // detail page.

                      const SizedBox(height: 6),

                      /// Price
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              "Rs. ${property.propertyPrice}",
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "per night",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* Widget _buildPropertyCard(Property property, int index, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              final imagesSafe =
                  property.images.map((e) => e.toString()).toList();
              return PropertyPage(
                property: property,
                price: property.propertyPrice,
                name: property.propertyName,
                location: property.propertyAddress,
                image: property.coverImage ?? "",
                id: property.propertyId,
                rating: "4.5",
                description: property.propertyDesc,
                lat: property.propertyLatitude,
                long: property.propertyLongitude,
                galleryImages: imagesSafe,
                inTime: property.propDetailsPropDetailInTime,
                outTime: property.propDetailsPropDetailOutTime,
              );
            },
          ),
        );
      },
      child: Container(
        width: 280,
        height: 300,
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: kCream,
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: property.coverImage != null
                            ? DecorationImage(
                                image: NetworkImage(property.coverImage!),
                                fit: BoxFit.cover,
                                onError: (exception, stackTrace) {},
                              )
                            : null,
                      ),
                      child: property.coverImage == null
                          ? Image.network(
                              defaultImageUrls[index % defaultImageUrls.length],
                              fit: BoxFit.cover,
                              height: 180,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : Image.network(
                              property.coverImage!,
                              fit: BoxFit.cover,
                              height: 180,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                            )),
                ),

                //  Favorite Button
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: kCream.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.favorite_border,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () {
                        // Handle favorite action
                      },
                    ),
                  ),
                ),

                //    Guest Favorite Badge
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: kClay,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      "Guest Favorite",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: kCream,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Luxury Badge
              ],
            ),

            // Details Section
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Property Name and Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          property.propertyName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          if (property.rating != null) ...[
                            Icon(
                              Icons.star,
                              color: Colors.amber[700],
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            property.rating != null
                                ? '${property.ratingLabel} (${property.reviewCount})'
                                : 'New',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Address
                  Text(
                    "${property.propertyAddress}, ${property.propertyCity}",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                      // "Free Cancellation" was printed on every card
                      // with no cancellation-policy field behind it. The
                      // real policy is per-property and shown on the
                      // detail page.

                  // Price
                  Row(
                    children: [
                      Text(
                        "Rs. ${property.propertyPrice}",
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "per night",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
*/
  Widget _buildLoadingRow() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          width: 280,
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              decoration: BoxDecoration(
                color: kCream,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: kCardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: kIndigo.withOpacity(0.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.villa_outlined, size: 28, color: kIndigo),
          ),
          const SizedBox(height: 14),
          Text(
            "No stays available yet",
            style: fraunces(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: kInk,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Check back soon for new places to stay",
            style: inter(fontSize: 12.5, color: kMuted),
          ),
        ],
      ),
    );
  }
}
