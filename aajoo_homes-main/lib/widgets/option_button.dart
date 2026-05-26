import 'package:flutter/material.dart';

class OptionButton extends StatefulWidget {
  final Function(int) onOptionSelected;

  const OptionButton({
    super.key,
    required this.onOptionSelected,
  });

  @override
  _OptionButtonState createState() => _OptionButtonState();
}

class _OptionButtonState extends State<OptionButton> {
  int selectedButton = 0; // Default selection

  @override
  void initState() {
    super.initState();
    // Notify parent of initial selection
    widget.onOptionSelected(selectedButton);
  }

  void _handleSelection(int option) {
    setState(() {
      selectedButton = option;
    });
    widget.onOptionSelected(option);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: theme.primaryColor),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _handleSelection(0),
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selectedButton == 0
                        ? theme.primaryColor
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    'Renter',
                    style: TextStyle(
                      color: selectedButton == 0
                          ? Colors.white
                          : theme.primaryColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => _handleSelection(1),
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selectedButton == 1
                        ? theme.primaryColor
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    'Host',
                    style: TextStyle(
                      color: selectedButton == 1
                          ? Colors.white
                          : theme.primaryColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
