import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/utils/fonts.dart';

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
            child: Column(
              children: [
                const Icon(
                  Iconsax.activity4,
                  size: 30,
                  color: kMuted,
                ),
                const SizedBox(
                  height: 10,
                ),
                Text("No Ongoing Bookings",
                    style: inter(fontSize: 14, color: kMuted)),
              ],
            )));
  }
}
