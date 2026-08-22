import 'package:flutter/material.dart';
import 'package:rent_home/ui/screens_renter/property_details/widgets/traveller_picker.dart';

/// Confirming a negotiated booking.
///
/// Stateful now only so the sheet can remember who the stay is for. This is
/// the negotiated path's equivalent of the property page's picker — without
/// it, a deal struck in chat could only ever be booked in the account
/// holder's own name, while the same stay booked at list price could not.
class AcceptOfferBottomSheet extends StatefulWidget {
  const AcceptOfferBottomSheet({
    super.key,
    required this.price,
    required this.onPay,
  });

  final double price;
  final Future<void> Function(double totalAmount, bool isCod, int? travellerId) onPay;

  @override
  State<AcceptOfferBottomSheet> createState() => _AcceptOfferBottomSheetState();
}

class _AcceptOfferBottomSheetState extends State<AcceptOfferBottomSheet> {
  int? _travellerId;

  double get price => widget.price;

  // ≤₹7500 => 5%, >₹7500 => 18% (matches backend tariff GST)
  double get _gstRate => price <= 7500 ? 0.05 : 0.18;
  double get _gstAmount => price * _gstRate;
  double get _totalAmount => price * (1 + _gstRate);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        // The picker adds height and can open a keyboard behind this sheet.
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
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
          TravellerPicker(
            value: _travellerId,
            onChanged: (id) => setState(() => _travellerId = id),
          ),
          const SizedBox(height: 16),
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
              await widget.onPay(_totalAmount, true, _travellerId);
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
              await widget.onPay(_totalAmount, false, _travellerId);
            },
          ),
        ],
      ),
    );
  }
}
