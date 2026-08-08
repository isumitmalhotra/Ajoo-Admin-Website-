import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';

// ── Section Title ─────────────────────────────────────────────────────────────

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
}

// ── Generic Text Field ────────────────────────────────────────────────────────

class PropertyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int? maxLines;
  final bool isNumeric;
  final bool isRequired;
  final Widget? prefixWidget;

  const PropertyTextField(
    this.controller,
    this.label,
    this.icon, {
    super.key,
    this.maxLines,
    this.isNumeric = false,
    this.isRequired = true,
    this.prefixWidget,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: prefixWidget ?? Icon(icon, color: kInk2, size: 20),
            filled: true,
            fillColor: kSand,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: kLine),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: kLine),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: kIndigo, width: 1.5),
            ),
          ),
          maxLines: maxLines ?? 1,
          keyboardType:
              isNumeric ? TextInputType.number : TextInputType.text,
          validator: (value) {
            if (!isRequired) return null;
            return (value == null || value.isEmpty)
                ? 'Please enter $label'
                : null;
          },
        ),
      );
}

// ── Price Field (₹ prefix) ────────────────────────────────────────────────────

class PriceTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isRequired;

  const PriceTextField(
    this.controller,
    this.label, {
    super.key,
    this.isRequired = true,
  });

  @override
  Widget build(BuildContext context) => PropertyTextField(
        controller,
        label,
        Icons.attach_money,
        isNumeric: true,
        isRequired: isRequired,
        prefixWidget: const Padding(
          padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 30),
          child: Text(
            '₹',
            style: TextStyle(fontSize: 35, color: kInk),
          ),
        ),
      );
}

// ── Dropdown Field ────────────────────────────────────────────────────────────

class PropertyDropdownField extends StatelessWidget {
  final String label;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const PropertyDropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: kCream,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
          ),
          items: items
              .map((value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  ))
              .toList(),
          onChanged: onChanged,
          validator: (value) =>
              value == null ? 'Please select a $label' : null,
        ),
      );
}

// ── Time Picker ───────────────────────────────────────────────────────────────

class PropertyTimePicker extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final ValueChanged<TimeOfDay?> onChanged;

  const PropertyTimePicker({
    super.key,
    required this.label,
    required this.onChanged,
    this.time,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: GestureDetector(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            onChanged(picked);
          },
          child: AbsorbPointer(
            child: TextFormField(
              decoration: InputDecoration(
                labelText:
                    time == null ? label : '$label: ${time!.format(context)}',
                hintText: time?.format(context) ?? 'Select Time',
                filled: true,
                fillColor: kCream,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (value) =>
                  value == null ? 'Please select $label' : null,
              readOnly: true,
            ),
          ),
        ),
      );
}

// ── Tap to Add Photos ─────────────────────────────────────────────────────────

class HostTapToAddPhotosView extends StatelessWidget {
  const HostTapToAddPhotosView({super.key});

  @override
  Widget build(BuildContext context) => const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo, size: 40),
          SizedBox(height: 8),
          Text(
            'Tap to add photos',
            style: TextStyle(color: kMuted, fontSize: 12),
          ),
        ],
      );
}
