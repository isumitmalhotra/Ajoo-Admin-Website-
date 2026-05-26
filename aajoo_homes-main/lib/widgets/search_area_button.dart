import 'package:flutter/material.dart';

class SearchButton extends StatefulWidget {
  @override
  _SearchButtonState createState() => _SearchButtonState();
}

class _SearchButtonState extends State<SearchButton> {
  bool _isLoading = false;

  void _onPressed() {
    setState(() {
      _isLoading = true; // Start showing the progress indicator
    });

    // Wait for 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _isLoading = false; // Stop showing the progress indicator
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _onPressed,
      child: Material(
        elevation: 5,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white70,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.grey,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Find my home",
                  style: TextStyle(fontSize: 15),
                ),

                if (_isLoading)
                  Padding(
                    padding: const EdgeInsets.only(left: 7),
                    child: const SizedBox(
                      height: 10,
                      width: 10,
                      child: CircularProgressIndicator(strokeWidth: 2 ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
