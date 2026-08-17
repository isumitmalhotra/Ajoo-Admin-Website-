import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rent_home/constants.dart';

/// What a field is allowed to contain.
///
/// The form used to have exactly two settings — text or "numeric", and numeric
/// only changed the keyboard. Nothing stopped a host typing letters into a
/// price, a nine-digit phone number, or "abc" as a PIN code, and nothing
/// checked an email looked like one. The server then rejected the whole
/// listing at the end, after six steps, with one flat error.
enum FieldKind {
  text,

  /// Whole numbers only — beds, guests, floor.
  integer,

  /// Money. Digits and at most one decimal point.
  decimal,

  /// Indian mobile: exactly 10 digits, first digit 6-9.
  phone,

  email,

  /// Indian PIN: exactly 6 digits, cannot start with 0.
  pincode,

  url,
}

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

  /// Kept for the many existing call sites. Equivalent to
  /// `kind: FieldKind.integer`.
  final bool isNumeric;
  final bool isRequired;
  final Widget? prefixWidget;

  /// What the field accepts. Overrides [isNumeric] when set to anything other
  /// than [FieldKind.text].
  final FieldKind? kind;

  const PropertyTextField(
    this.controller,
    this.label,
    this.icon, {
    super.key,
    this.maxLines,
    this.isNumeric = false,
    this.isRequired = true,
    this.prefixWidget,
    this.kind,
  });

  FieldKind get _kind =>
      kind ?? (isNumeric ? FieldKind.integer : FieldKind.text);

  TextInputType get _keyboard {
    switch (_kind) {
      case FieldKind.integer:
      case FieldKind.pincode:
        return TextInputType.number;
      case FieldKind.decimal:
        return const TextInputType.numberWithOptions(decimal: true);
      case FieldKind.phone:
        return TextInputType.phone;
      case FieldKind.email:
        return TextInputType.emailAddress;
      case FieldKind.url:
        return TextInputType.url;
      case FieldKind.text:
        return TextInputType.text;
    }
  }

  /// Stop the wrong characters at the keystroke, so the field cannot hold a
  /// value the validator would later reject.
  List<TextInputFormatter> get _formatters {
    switch (_kind) {
      case FieldKind.integer:
        return [FilteringTextInputFormatter.digitsOnly];
      case FieldKind.pincode:
        return [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ];
      case FieldKind.phone:
        return [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ];
      case FieldKind.decimal:
        // Digits with at most one decimal point — a second '.' is refused
        // outright instead of silently truncated.
        return [
          FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
          TextInputFormatter.withFunction((oldValue, newValue) =>
              '.'.allMatches(newValue.text).length > 1 ? oldValue : newValue),
          LengthLimitingTextInputFormatter(10),
        ];
      case FieldKind.email:
      case FieldKind.url:
        // Format is the validator's job, but whitespace can never be right.
        return [FilteringTextInputFormatter.deny(RegExp(r'\s'))];
      case FieldKind.text:
        return const [];
    }
  }

  String? _validate(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) {
      return isRequired ? 'Please enter $label' : null;
    }
    switch (_kind) {
      case FieldKind.integer:
        final n = int.tryParse(value);
        if (n == null) return '$label must be a whole number';
        if (n < 0) return '$label cannot be negative';
        return null;
      case FieldKind.decimal:
        final n = double.tryParse(value);
        if (n == null) return 'Enter $label as a number';
        if (n < 0) return '$label cannot be negative';
        return null;
      case FieldKind.phone:
        if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
          return 'Enter a 10-digit mobile number';
        }
        return null;
      case FieldKind.pincode:
        if (!RegExp(r'^[1-9]\d{5}$').hasMatch(value)) {
          return 'Enter a valid 6-digit PIN code';
        }
        return null;
      case FieldKind.email:
        if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(value)) {
          return 'Enter a valid email address';
        }
        return null;
      case FieldKind.url:
        final uri = Uri.tryParse(value);
        if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
          return 'Enter a full link, starting with https://';
        }
        return null;
      case FieldKind.text:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            // A required field says so. Every field looked identical before,
            // so the only way to learn which were mandatory was to fill the
            // form, submit, and be sent back.
            label: RichText(
              text: TextSpan(
                text: label,
                style: const TextStyle(color: kMuted, fontSize: 15),
                children: isRequired
                    ? const [
                        TextSpan(
                          text: ' *',
                          style: TextStyle(
                              color: kDanger, fontWeight: FontWeight.w700),
                        ),
                      ]
                    : const [],
              ),
            ),
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
          keyboardType: _keyboard,
          inputFormatters: _formatters,
          validator: _validate,
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
        // Money, so decimals are allowed — integer-only would have refused
        // ₹1499.50. Letters cannot be typed at all now.
        kind: FieldKind.decimal,
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
