// Renders one field from the listing schema — the app's half of the pair.
//
// A direct translation of the website's SchemaField.tsx: the same seven field
// types, the same showIf rule, the same Yes/No pair for booleans and the same
// pill row for multiselects. Because the eleven category flows differ only in
// their field definitions, neither client hard-codes them; both just map over
// whatever the server sends.
//
// Where the two differ, it is because a phone is not a browser: a `select` is
// a bottom sheet rather than a dropdown, and `time` opens the platform time
// picker rather than an <input type="time">. What is asked, in what order,
// with what options, is identical.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/models/listing_schema.dart';
import 'package:rent_home/utils/fonts.dart';

class SchemaFieldInput extends StatelessWidget {
  const SchemaFieldInput({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    this.error,
  });

  final SchemaField field;
  final dynamic value;
  final void Function(String key, dynamic value) onChanged;

  /// A per-field message, shown under the control in danger red.
  final String? error;

  void _set(dynamic v) => onChanged(field.key, v);

  @override
  Widget build(BuildContext context) {
    switch (field.type) {
      case FieldType.boolean:
        return _wrap(_boolean());
      case FieldType.select:
        return _wrap(_select(context));
      case FieldType.multiselect:
        return _wrap(_multiselect());
      case FieldType.textarea:
        return _wrap(_text(maxLines: 4));
      case FieldType.time:
        return _wrap(_time(context));
      case FieldType.number:
        return _wrap(_text(numeric: true));
      case FieldType.text:
        return _wrap(_text());
    }
  }

  /// Label, control, help text, error — the shape every field shares.
  Widget _wrap(Widget control) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  field.label,
                  style: inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: kInk),
                ),
              ),
              if (field.required)
                Text(' *', style: inter(fontSize: 13.5, color: kDanger)),
            ],
          ),
          const SizedBox(height: 7),
          control,
          if (field.help != null && field.help!.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(field.help!, style: inter(fontSize: 11.5, color: kMuted)),
          ],
          if (error != null) ...[
            const SizedBox(height: 5),
            Text(error!, style: inter(fontSize: 11.5, color: kDanger)),
          ],
        ],
      ),
    );
  }

  // ── boolean ───────────────────────────────────────────────────────────────

  Widget _boolean() {
    // Booleans arrive as true/false from the host or "1"/"0" from a saved
    // draft; both have to read as on.
    final isOn = value == true || value == '1' || value == 1;
    final isOff = value == false || value == '0' || value == 0;
    return Row(
      children: [
        _Pill(
          label: 'Yes',
          selected: isOn,
          onTap: () => _set(true),
        ),
        const SizedBox(width: 8),
        _Pill(
          label: 'No',
          selected: isOff,
          onTap: () => _set(false),
        ),
      ],
    );
  }

  // ── select ────────────────────────────────────────────────────────────────

  Widget _select(BuildContext context) {
    final current = field.options.where((o) => o.value == value).toList();
    final label = current.isEmpty ? 'Select…' : current.first.label;
    final chosen = current.isNotEmpty;
    return InkWell(
      onTap: () => _openPicker(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: kSand,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: error != null ? kDanger : kLine),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: inter(
                    fontSize: 15, color: chosen ? kInk : kMuted),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 20, color: kMuted),
          ],
        ),
      ),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    // Drop focus before the sheet opens.
    //
    // Without this, whichever field the host last typed in still holds focus
    // while they pick from the sheet. Closing it hands focus straight back,
    // Flutter scrolls that field into view, and the form jumps away from the
    // section they were working in — reported as the page "redirecting to the
    // last entered numeric field" after a dropdown selection. Nothing is
    // scrolling; a text field is simply being re-focused off screen.
    FocusScope.of(context).unfocus();

    // A sheet, not a dropdown. Some of these lists run to a dozen options
    // with long labels, which a Material dropdown truncates.
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kMuted.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(field.label,
                      style: fraunces(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: kInk)),
                ),
              ),
              const Divider(height: 1, color: kLine),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: field.options.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: kLine, indent: 20),
                  itemBuilder: (_, i) {
                    final o = field.options[i];
                    final on = o.value == value;
                    return ListTile(
                      title: Text(o.label,
                          style: inter(
                              fontSize: 15,
                              fontWeight:
                                  on ? FontWeight.w700 : FontWeight.w500,
                              color: on ? kIndigo : kInk)),
                      trailing: on
                          ? const Icon(Icons.check_rounded,
                              size: 20, color: kIndigo)
                          : null,
                      onTap: () => Navigator.pop(ctx, o.value),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) _set(picked);
  }

  // ── multiselect ───────────────────────────────────────────────────────────

  Widget _multiselect() {
    final selected = value is List
        ? (value as List).map((e) => e.toString()).toList()
        : <String>[];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in field.options)
          _Pill(
            label: o.label,
            selected: selected.contains(o.value),
            onTap: () {
              final next = [...selected];
              next.contains(o.value)
                  ? next.remove(o.value)
                  : next.add(o.value);
              _set(next);
            },
          ),
      ],
    );
  }

  // ── time ──────────────────────────────────────────────────────────────────

  Widget _time(BuildContext context) {
    final text = (value ?? '').toString();
    return InkWell(
      onTap: () async {
        final now = TimeOfDay.now();
        final parts = text.split(':');
        final initial = parts.length >= 2
            ? TimeOfDay(
                hour: int.tryParse(parts[0]) ?? now.hour,
                minute: int.tryParse(parts[1]) ?? now.minute)
            : now;
        final picked =
            await showTimePicker(context: context, initialTime: initial);
        if (picked != null) {
          // 24-hour HH:mm, which is what the server stores and what the
          // website's <input type="time"> submits.
          final hh = picked.hour.toString().padLeft(2, '0');
          final mm = picked.minute.toString().padLeft(2, '0');
          _set('$hh:$mm');
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: kSand,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: error != null ? kDanger : kLine),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(text.isEmpty ? 'Select time' : text,
                  style: inter(
                      fontSize: 15, color: text.isEmpty ? kMuted : kInk)),
            ),
            const Icon(Icons.schedule_rounded, size: 19, color: kMuted),
          ],
        ),
      ),
    );
  }

  // ── text / number / textarea ──────────────────────────────────────────────

  Widget _text({bool numeric = false, int maxLines = 1}) {
    return _SchemaTextField(
      // Keyed on the FIELD, never on its value.
      //
      // The value used to be part of this key, to pick up a draft loading over
      // an empty form. But the value also changes on every keystroke — so
      // typing gave the widget a new identity, Flutter threw away its State,
      // its controller and its focus, and built a fresh one. The character
      // landed (the replacement was seeded with it) and everything after it
      // was swallowed, because there was no longer a focused field to receive
      // it. Measured on device: tap, type "1500", and the field holds "1".
      //
      // The draft case is handled where it belongs — didUpdateWidget below,
      // which can tell an outside change from the host's own typing.
      key: ValueKey(field.key),
      initial: (value ?? '').toString(),
      numeric: numeric,
      maxLines: maxLines,
      hasError: error != null,
      onChanged: _set,
    );
  }
}

/// A text field that keeps its own controller so typing does not rebuild the
/// whole step, and reports every keystroke upward.
class _SchemaTextField extends StatefulWidget {
  const _SchemaTextField({
    super.key,
    required this.initial,
    required this.numeric,
    required this.maxLines,
    required this.hasError,
    required this.onChanged,
  });

  final String initial;
  final bool numeric;
  final int maxLines;
  final bool hasError;
  final ValueChanged<String> onChanged;

  @override
  State<_SchemaTextField> createState() => _SchemaTextFieldState();
}

class _SchemaTextFieldState extends State<_SchemaTextField> {
  late final TextEditingController _c =
      TextEditingController(text: widget.initial);
  final FocusNode _focus = FocusNode();

  /// Adopt a value that arrived from OUTSIDE this field.
  ///
  /// A draft loading over an empty form, or the wizard clearing a field, both
  /// arrive as a changed `initial` while the host is not typing. Those should
  /// replace what is in the box.
  ///
  /// While the field HAS focus they must not, because then the new `initial`
  /// is simply an echo of the host's own keystroke coming back around, and
  /// assigning it would reset the cursor to the start of the text mid-word.
  @override
  void didUpdateWidget(covariant _SchemaTextField old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus && widget.initial != _c.text) {
      _c.text = widget.initial;
      _c.selection = TextSelection.collapsed(offset: _c.text.length);
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _c,
      focusNode: _focus,
      maxLines: widget.maxLines,
      keyboardType: widget.numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : (widget.maxLines > 1
              ? TextInputType.multiline
              : TextInputType.text),
      // Digits and at most one decimal point — the same keystroke filtering
      // the website applies, so a number field cannot hold a value the
      // server will reject.
      inputFormatters: widget.numeric
          ? [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              TextInputFormatter.withFunction((old, now) =>
                  '.'.allMatches(now.text).length > 1 ? old : now),
            ]
          : null,
      onChanged: widget.onChanged,
      style: inter(fontSize: 15, color: kInk),
      decoration: InputDecoration(
        filled: true,
        fillColor: kSand,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: widget.hasError ? kDanger : kLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kIndigo, width: 1.6),
        ),
      ),
    );
  }
}

/// The selectable pill used for booleans, multiselects and option groups.
class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListingPill(
        label: label,
        selected: selected,
        onTap: onTap,
      );
}

/// Shared so option groups (amenities, safety, views) look identical to the
/// pills a multiselect field draws — on the website they are the same button.
class ListingPill extends StatelessWidget {
  const ListingPill({
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
