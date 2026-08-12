import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:shimmer/shimmer.dart';

/// The stay's own photos at the head of a booking (A-63).
///
/// This slot held a Google Map. A guest opening a booking they have already
/// made knows where it is — what they want to see is the place. The map has
/// not been thrown away: it is still under the Location tab in the panels
/// below, and the confirmed and ongoing screens still lead with it, because
/// there the guest is travelling to the stay rather than looking back at it.
///
/// No photos means no gallery — a stock image here would be a picture of
/// somewhere the guest did not stay.
class BookingPropertyGallery extends StatefulWidget {
  final List<String> images;
  final bool isLoading;

  const BookingPropertyGallery({
    super.key,
    required this.images,
    this.isLoading = false,
  });

  @override
  State<BookingPropertyGallery> createState() => _BookingPropertyGalleryState();
}

class _BookingPropertyGalleryState extends State<BookingPropertyGallery> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Shimmer.fromColors(
        baseColor: kLine,
        highlightColor: kSand,
        child: Container(height: 260, width: double.infinity, color: kLine),
      );
    }

    if (widget.images.isEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        color: kSand,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: kIndigo.withOpacity(0.07),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_outlined,
                    color: kIndigo, size: 26),
              ),
              const SizedBox(height: 12),
              Text(
                'No photos for this stay',
                style: inter(
                    fontSize: 13.5, fontWeight: FontWeight.w600, color: kMuted),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => CachedNetworkImage(
              imageUrl: widget.images[i],
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder: (_, __) => Container(color: kSand),
              errorWidget: (_, __, ___) => Container(
                color: kSand,
                child: const Icon(Icons.image_not_supported_outlined,
                    color: kMuted),
              ),
            ),
          ),
          if (widget.images.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length.clamp(0, 8),
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 6,
                    width: i == _page ? 18 : 6,
                    decoration: BoxDecoration(
                      color: i == _page ? Colors.white : Colors.white54,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
          if (widget.images.length > 1)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${_page + 1}/${widget.images.length}',
                  style: inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
