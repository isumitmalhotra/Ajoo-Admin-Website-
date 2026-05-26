import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class NoRecentTransactionView extends StatelessWidget {
  const NoRecentTransactionView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
        child: SizedBox(
      height: 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.empty_wallet4),
          Text("No Recent Transactions"),
        ],
      ),
    ));
  }
}
