import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/utils/fonts.dart';

class NoRecentTransactionView extends StatelessWidget {
  const NoRecentTransactionView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
        child: SizedBox(
      height: 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.empty_wallet4, color: kMuted),
          const SizedBox(height: 10),
          Text("No Recent Transactions",
              style: inter(fontSize: 14, color: kMuted)),
        ],
      ),
    ));
  }
}
