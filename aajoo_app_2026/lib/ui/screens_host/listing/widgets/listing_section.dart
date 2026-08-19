// The building blocks the listing wizard repeats — the website's <Section>
// and its checkbox-style option groups, as Flutter widgets.
import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/models/listing_schema.dart';
import 'package:rent_home/ui/screens_host/listing/widgets/schema_field_input.dart';
import 'package:rent_home/utils/fonts.dart';

/// A titled block of the form. Same title/sub pair the website's Section takes.
class ListingSection extends StatelessWidget {
  const ListingSection({
    super.key,
    required this.title,
    this.sub,
    required this.children,
  });

  final String title;
  final String? sub;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: fraunces(
                  fontSize: 17, fontWeight: FontWeight.w700, color: kInk)),
          if (sub != null && sub!.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(sub!, style: inter(fontSize: 12.5, color: kMuted, height: 1.45)),
          ],
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

/// One labelled set of multi-choice options — amenities, safety, views.
///
/// The website renders these as the same pill buttons a `multiselect` field
/// uses, so they are the same widget here too.
class OptionGroupPicker extends StatelessWidget {
  const OptionGroupPicker({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  final String label;
  final List<Option> options;
  final List<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            Text(label,
                style: inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: kInk)),
            const SizedBox(height: 8),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final o in options)
                ListingPill(
                  label: o.label,
                  selected: selected.contains(o.value),
                  onTap: () => onToggle(o.value),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A row of pills for a single choice — used where the website renders a
/// small button group rather than a dropdown (host type, accommodation type).
class SingleChoiceRow extends StatelessWidget {
  const SingleChoiceRow({
    super.key,
    required this.options,
    required this.value,
    required this.onSelect,
  });

  final List<Option> options;
  final String? value;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in options)
          ListingPill(
            label: o.label,
            selected: o.value == value,
            onTap: () => onSelect(o.value),
          ),
      ],
    );
  }
}

/// A labelled on/off switch — the website's house-rule and consent toggles.
class ListingToggle extends StatelessWidget {
  const ListingToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.sub,
  });

  final String label;
  final String? sub;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: kInk)),
                    if (sub != null) ...[
                      const SizedBox(height: 2),
                      Text(sub!,
                          style: inter(fontSize: 12, color: kMuted)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: kIndigo,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A plain labelled text input for the wizard's own fields (the ones not
/// described by the schema — property name, address, capacity numbers).
class ListingTextField extends StatelessWidget {
  const ListingTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.help,
    this.error,
    this.numeric = false,
    this.maxLines = 1,
    this.required = false,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? help;
  final String? error;
  final bool numeric;
  final int maxLines;
  final bool required;
  final TextInputType? keyboardType;
  final List<dynamic>? inputFormatters;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(label,
                    style: inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: kInk)),
              ),
              if (required)
                Text(' *', style: inter(fontSize: 13.5, color: kDanger)),
            ],
          ),
          const SizedBox(height: 7),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType ??
                (numeric ? TextInputType.number : TextInputType.text),
            inputFormatters: inputFormatters?.cast(),
            onChanged: onChanged,
            style: inter(fontSize: 15, color: kInk),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: inter(fontSize: 15, color: kMuted),
              filled: true,
              fillColor: kSand,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: error != null ? kDanger : kLine),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kIndigo, width: 1.6),
              ),
            ),
          ),
          if (help != null) ...[
            const SizedBox(height: 5),
            Text(help!, style: inter(fontSize: 11.5, color: kMuted)),
          ],
          if (error != null) ...[
            const SizedBox(height: 5),
            Text(error!, style: inter(fontSize: 11.5, color: kDanger)),
          ],
        ],
      ),
    );
  }
}
