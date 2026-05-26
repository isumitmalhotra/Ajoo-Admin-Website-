import 'package:flutter/material.dart';
import 'package:rent_home/ui/unused_screens/chat/chat_page.dart';

class NegotiationScreenLoadView extends StatelessWidget {
  const NegotiationScreenLoadView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Container(
      height: MediaQuery.of(context).size.height * 0.9,
      width: MediaQuery.of(context).size.width * 0.9,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset("assets/happy_tourist.png", height: 150),
          const CircularProgressIndicator(
            color: kPrimaryColor,
          ),
          const Padding(
            padding: EdgeInsets.all(10.0),
            child: const Text(
              "Negotiation lets you propose a custom price for this property. Both you and the host can make offers until you agree on a price.\n\nCaution: Only accept offers you are comfortable with. Once you accept, you will proceed to booking and payment. Never share sensitive information in chat.",
              style: const TextStyle(color: Colors.black87, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    ));
  }
}
