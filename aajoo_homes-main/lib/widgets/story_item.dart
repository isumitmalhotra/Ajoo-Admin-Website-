import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class StoryItem extends StatefulWidget {
  final int index;

  const StoryItem({Key? key, required this.index}) : super(key: key);

  @override
  _StoryItemState createState() => _StoryItemState();
}

class _StoryItemState extends State<StoryItem> {
  bool isLiked = false; // Track the heart icon's state

  // List of image URLs
  final List<String> imageUrls = [
    'https://i.pinimg.com/564x/f0/30/08/f03008c04c5976c7f33f39a1e92478e7.jpg',
    'https://i.pinimg.com/736x/57/9f/ab/579fab191909c1ef88032213f29aeb86.jpg',
    'https://i.pinimg.com/enabled_hi/564x/85/c4/1c/85c41c018c11c3aea1fc044cc704f0e3.jpg',
    'https://i.pinimg.com/564x/a1/58/a4/a158a46c1d3d4dbe88a2c70020abb5dd.jpg',
    'https://i.pinimg.com/736x/b8/0d/8c/b80d8c2bcfc97b4ea2394826353288b9.jpg',
    'https://i.pinimg.com/564x/4f/25/4f/4f254f918b0e9ab03d70dffbdb83dd7c.jpg',
    'https://i.pinimg.com/564x/64/7e/11/647e11eea3b100c74e579d2b8ae24b95.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 120,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[300],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            // Clip the image to fit the container's border
            child: CachedNetworkImage(
              imageUrl: imageUrls[widget.index % imageUrls.length], // Use the index to select the image
              fit: BoxFit.cover,
              // Ensures the image fits the container
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(), // Placeholder widget while the image loads
              ),
              errorWidget: (context, url, error) =>
              const Icon(Icons.error), // Error widget
            ),
          ),
        ),
        Positioned(
          top: 7,
          left: 15,
          child: GestureDetector(
            onTap: () {
              setState(() {
                isLiked = !isLiked; // Toggle heart icon color on tap
              });
            },
            child: Icon(
              Icons.favorite,
              color: isLiked ? Colors.red : Colors.white, // Change color based on state
              size: 24,
            ),
          ),
        ),
        Positioned(
          top: 35,
          left: 20,
          right: 20,
          child: Center(
            child: Icon(
              Icons.play_arrow,
              color: Colors.white.withOpacity(0.8), // Slightly transparent white play icon
              size: 50, // Size of the play icon
            ),
          ),
        ),
      ],
    );
  }
}
