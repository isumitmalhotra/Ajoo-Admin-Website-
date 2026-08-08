import 'package:flutter/material.dart';
import 'package:rent_home/ui/screens_common/support/support_screen.dart';

class FaqScren extends StatefulWidget {
  const FaqScren({super.key});

  @override
  State<FaqScren> createState() => _FaqScrenState();
}

class _FaqScrenState extends State<FaqScren> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("FAQ"),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: const FAQSection(),
      persistentFooterButtons: [
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SupportScreen(),
              ),
            );
          },
          child: const Text("Contact Support"),
        ),
      ],
    );
  }
}
