import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/utils/fonts.dart';

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

  /// A street address: several words containing letters. "wd23fd" used to be
  /// accepted because the only rule was "not empty".
  address,

  url,
}

// ── Section Title ─────────────────────────────────────────────────────────────

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 10),
        child: Text(
          title,
          // The app's display face. This was Flutter's default, so the
          // listing wizard was the one host flow whose headings did not
          // match the rest of the product.
          style:
              fraunces(fontSize: 18, fontWeight: FontWeight.w700, color: kInk),
        ),
      );
}

/// The label above a group of controls (chips, switches, pickers).
///
/// These were each written inline as
/// `TextStyle(fontSize: 16, fontWeight: FontWeight.bold)` — a dozen copies of
/// the same default-font declaration scattered through the wizard.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.hint});

  final String text;
  final String? hint;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text,
                style: inter(
                    fontSize: 14, fontWeight: FontWeight.w700, color: kInk)),
            if (hint != null) ...[
              const SizedBox(height: 2),
              Text(hint!, style: inter(fontSize: 12, color: kMuted)),
            ],
          ],
        ),
      );
}

/// A selectable pill — the same shape the guest filter sheet uses.
class FormChoiceChip extends StatelessWidget {
  const FormChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? kIndigo.withOpacity(0.12) : kSurface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? kIndigo : kLine,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Text(
          label,
          style: inter(
            fontSize: 13.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? kIndigo : kInk,
          ),
        ),
      ),
    );
  }
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
      case FieldKind.address:
        return TextInputType.streetAddress;
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
      case FieldKind.address:
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
      case FieldKind.address:
        // Same rule as the web wizard: several words, containing letters.
        // Loose enough for "12 MG Road", tight enough to refuse "wd23fd".
        if (value.length < 8 ||
            !RegExp(r'[A-Za-z]{3}').hasMatch(value) ||
            !RegExp(r'\s').hasMatch(value)) {
          return 'Enter the full address — house/flat, street and area';
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
