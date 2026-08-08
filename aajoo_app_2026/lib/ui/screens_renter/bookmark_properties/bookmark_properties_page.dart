import 'package:flutter/material.dart';
import '../../motion/aajoo_motion.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/data/models/properties_response_model.dart';
import 'package:rent_home/ui/screens_renter/home/components/curated_card.dart';
import 'package:rent_home/ui/screens_renter/property_details/property_page.dart';
import 'package:rent_home/service/bookmark_service.dart';

/// Saved Stays — re-skinned to the new design (scaffold saved_screen): a 2-column
/// grid of the shared CuratedCard. Bookmark load/remove + property navigation
/// wiring unchanged.
class BookmarkedPropertiesPage extends StatefulWidget {
  const BookmarkedPropertiesPage({super.key});

  @override
  State<BookmarkedPropertiesPage> createState() =>
      _BookmarkedPropertiesPageState();
}

class _BookmarkedPropertiesPageState extends State<BookmarkedPropertiesPage> {
  final BookmarkService _bookmarkService = BookmarkService();
  List<Property> _bookmarks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks(forceRefresh: true);
  }

  Future<void> _loadBookmarks({bool forceRefresh = false}) async {
    if (mounted) setState(() => _loading = true);
    final bookmarks =
        await _bookmarkService.getBookmarks(forceRefresh: forceRefresh);
    if (!mounted) return;
    setState(() {
      _bookmarks = bookmarks;
      _loading = false;
    });
  }

  Future<void> _removeBookmark(Property property) async {
    final ok = await _bookmarkService.toggleBookmark(property);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _bookmarks.removeWhere((p) => p.propertyId == property.propertyId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property removed from saved')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not remove. Please try again.'),
          backgroundColor: kDanger,
        ),
      );
    }
  }

  void _openProperty(Property property) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PropertyPage(
          property: property,
          price: property.propertyPrice.toString(),
          name: property.propertyName.toString(),
          location: property.propertyAddress.toString(),
          image: property.coverImage.toString(),
          id: property.propertyId,
          rating: "4.5",
          description: property.propertyDesc.toString(),
          lat: property.propertyLatitude.toString(),
          long: property.propertyLongitude.toString(),
          galleryImages: property.images,
          inTime: property.propDetailsPropDetailInTime?.toString(),
          outTime: property.propDetailsPropDetailOutTime?.toString(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kscaffoldColor,
      appBar: AppBar(
        title: Text('Saved Stays',
            style: fraunces(
                fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: kIndigo,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadBookmarks(forceRefresh: true),
        child: _loading && _bookmarks.isEmpty
            ? const Center(child: CircularProgressIndicator(color: kIndigo))
            : _bookmarks.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: _buildEmptyState(),
                      ),
                    ],
                  )
                : GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: _bookmarks.length,
                    itemBuilder: (context, index) {
                      final property = _bookmarks[index];
                      // Cards arrive in a short cascade, the same entrance the
                      // web uses for a results grid.
                      return Reveal(
                        delay: Reveal.staggerDelay(index),
                        child: CuratedCard(
                          property: property,
                          onTap: () => _openProperty(property),
                          onFavoriteTap: () => _removeBookmark(property),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite_border, size: 72, color: kLine),
          const SizedBox(height: 14),
          Text('No saved stays yet',
              style: fraunces(
                  fontSize: 18, fontWeight: FontWeight.w600, color: kInk)),
          const SizedBox(height: 6),
          Text('Tap the heart on any stay to save it here.',
              textAlign: TextAlign.center,
              style: inter(fontSize: 13, color: kMuted)),
        ],
      ),
    );
  }
}
