import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class NoOngoingBookingView extends StatelessWidget {
  const NoOngoingBookingView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Container(
            alignment: Alignment.center,
            constraints: const BoxConstraints(minHeight: 150),
            child: const Column(
              children: [
                Icon(
                  Iconsax.activity4,
                  size: 30,
                ),
                SizedBox(
                  height: 10,
                ),
                Text("No Ongoing Bookings"),
              ],
            )));
  }
}
