import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rent_home/ui/screens_host/add_property/widgets/property_form_widgets.dart';

class PropertyImagePicker extends StatelessWidget {
  final List<XFile> images;
  final ValueChanged<List<XFile>> onChanged;

  const PropertyImagePicker({
    super.key,
    required this.images,
    required this.onChanged,
  });

//  Future<void> _pickImages(BuildContext context) async {
  //   final picker = ImagePicker();
  //   final picked = await picker.pickMultiImage();
  //   if (picked.length <= 6) {
  //     onChanged(picked);
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('You can select up to 6 images only.')),
  //     );
  //   }
  // }

  Future<void> _pickImages(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();

    if (picked.isEmpty) return;

    final updated = List<XFile>.from(images)..addAll(picked);

    if (updated.length <= 6) {
      onChanged(updated);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can select up to 6 images only.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Tap area ─────────────────────────────────────────────────────────
        GestureDetector(
          onTap: () => _pickImages(context),
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: images.length < 2 ? Colors.red : Colors.grey,
                width: images.length < 2 ? 2 : 1,
              ),
            ),
            child: Center(
              child: images.isEmpty
                  ? const HostTapToAddPhotosView()
                  : _ImageThumbnailList(
                      images: images,
                      onRemove: (index) {
                        final updated = List<XFile>.from(images)
                          ..removeAt(index);
                        onChanged(updated);
                      },
                    ),
            ),
          ),
        ),

        // ── Status text ───────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            images.length < 2
                ? 'Please upload at least 2 photos (${images.length}/2)'
                : '✓ Photos uploaded (${images.length}/6)',
            style: TextStyle(
              color: images.length < 2 ? Colors.red : Colors.green,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Thumbnail list ────────────────────────────────────────────────────────────

class _ImageThumbnailList extends StatelessWidget {
  final List<XFile> images;
  final ValueChanged<int> onRemove;

  const _ImageThumbnailList({
    required this.images,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) => ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.all(4.0),
          child: Stack(
            children: [
              Image.file(
                File(images[index].path),
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => onRemove(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
