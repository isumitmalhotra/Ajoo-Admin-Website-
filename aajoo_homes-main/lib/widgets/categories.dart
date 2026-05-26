import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:ionicons/ionicons.dart';

import '../constants.dart';

class Categories extends StatelessWidget {
  const Categories({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        alignment: Alignment.center,
        height: 90,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            // Icons and labels corresponding to the options
            final List<Map<String, dynamic>> options = [
              {'icon': Ionicons.calendar_outline, 'label': 'Bookings'},
              {'icon': Iconsax.message4, 'label': 'Messages'},
            ];

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Use Icon instead of Image
                Container(
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          kprimaryColor // Set the circular container color to amber
                      ),
                  padding: EdgeInsets.all(
                      15), // Increase padding to make the icon smaller within the circle
                  child: Icon(
                    options[index]['icon'],
                    // size: 30, // Reduce icon size slightly to balance with added padding
                    color: Colors.white, // Adjust icon color as needed
                  ),
                ),

                const SizedBox(height: 5),
                Text(
                  options[index]['label'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          },
          separatorBuilder: (context, index) => const SizedBox(width: 20),
          itemCount: 2, // Adjust this if you have fewer/more options
        ),
      ),
    );
  }
}
