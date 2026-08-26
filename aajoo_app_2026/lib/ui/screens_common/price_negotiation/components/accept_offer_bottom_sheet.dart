import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/ui/screens_renter/property_details/widgets/traveller_picker.dart';
import 'package:rent_home/utils/money.dart';

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
            // Paise are never shown anywhere in the product; this printed
            // "₹1440.00" while the same figure read "₹1,440" at checkout.
            "GST (${(_gstRate * 100).toStringAsFixed(0)}%): ${rupees(_gstAmount)}",
            style: theme.textTheme.titleMedium?.copyWith(
              color: kDanger,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            "Total Price: ${rupees(_totalAmount)} (including GST)",
            style: theme.textTheme.titleMedium?.copyWith(
              color: kSuccess,
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
              backgroundColor: kSuccess,
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
