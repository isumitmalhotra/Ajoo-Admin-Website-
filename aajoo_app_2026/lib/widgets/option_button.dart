import 'package:flutter/material.dart';

class OptionButton extends StatefulWidget {
  final Function(int) onOptionSelected;
  final int initialSelection;

  const OptionButton({
    super.key,
    required this.onOptionSelected,
    this.initialSelection = 0,
  });

  @override
  _OptionButtonState createState() => _OptionButtonState();
}

class _OptionButtonState extends State<OptionButton> {
  late int selectedButton = widget.initialSelection;

  // NOTE: we intentionally do NOT call onOptionSelected() in initState.
  // Doing so reset the parent's selection back to Renter on every (re)mount,
  // which caused "Host" selections to be lost at signup. The parent keeps its
  // own default; we only notify on an actual user tap.

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
