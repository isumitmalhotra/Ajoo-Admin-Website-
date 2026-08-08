import 'package:flutter/material.dart';

class AcceptOfferBottomSheet extends StatelessWidget {
  const AcceptOfferBottomSheet({
    super.key,
    required this.price,
    required this.onPay,
  });

  final double price;
  final Future<void> Function(double totalAmount, bool isCod) onPay;

  // ≤₹7500 => 5%, >₹7500 => 18% (matches backend tariff GST)
  double get _gstRate => price <= 7500 ? 0.05 : 0.18;
  double get _gstAmount => price * _gstRate;
  double get _totalAmount => price * (1 + _gstRate);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Choose Payment Method",
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 24),

          /// GST info
          Text(
            "GST (${(_gstRate * 100).toStringAsFixed(0)}%): ₹${_gstAmount.toStringAsFixed(2)}",
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            "Total Price: ₹${_totalAmount.toStringAsFixed(2)} (including GST)",
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          /// COD
          ElevatedButton.icon(
            icon: const Icon(Icons.money),
            label: const Text("Pay on Arrival (COD)"),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.green,
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await onPay(_totalAmount, true);
            },
          ),

          const SizedBox(height: 16),

          /// Online payment
          ElevatedButton.icon(
            icon: const Icon(Icons.payment),
            label: const Text("Pay Online (Razorpay)"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await onPay(_totalAmount, false);
            },
          ),
        ],
      ),
    );
  }
}
