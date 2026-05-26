import 'package:flutter/material.dart';
import 'package:rent_home/ui/screens_common/price_negotiation/negotiation_controller.dart';
import 'package:rent_home/ui/screens_common/price_negotiation/negotitaion_page.dart';

class NegotiationScreenLoadErrorView extends StatelessWidget {
  const NegotiationScreenLoadErrorView({
    super.key,
    required this.negotiationController,
    required this.widget,
    required this.theme,
  });

  final NegotiationController negotiationController;
  final PriceNegotiationPage widget;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Negotiation lets you propose a custom price for this property. Both you and the host can make offers until you agree on a price.\n\nCaution: Only accept offers you are comfortable with. Once you accept, you will proceed to booking and payment. Never share sensitive information in chat.",
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              negotiationController.connectToSocket(
                  widget.serverUrl, widget.token);
              negotiationController.joinNegotiationRoom(
                  widget.userId, widget.propertyId);
              negotiationController.loadNegotiationChat(
                senderId: widget.senderId,
                receiverId: widget.receiverId,
                propertyId: widget.propertyId,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Negotiate Price",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
