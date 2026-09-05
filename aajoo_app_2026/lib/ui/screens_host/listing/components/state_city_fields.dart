import 'package:flutter/material.dart';

import 'package:rent_home/constants.dart';
import 'package:rent_home/service/locations_service.dart';
import 'package:rent_home/utils/fonts.dart';

/// Linked State → City pickers, fed by the reference tables.
///
/// The mobile wizard typed both by hand while the website picked them, which is
/// how the catalogue filled with junk labels — and a stay typed "hariyana"
/// never turns up when a guest searches Haryana. The Dart counterpart of the
/// web's StateCityFields, with the same three behaviours that matter:
///
///   * picking a state loads its cities and clears a city from another state;
///   * "Other — type it in" stays available, because no city list is complete
///     and a missing village must not block a listing;
///   * a value already on the record that is not in the list is kept and shown
///     rather than silently wiped — drafts and the map picker both write these.
class StateCityFields extends StatefulWidget {
  const StateCityFields({
    super.key,
    required this.state,
    required this.city,
    required this.onState,
    required this.onCity,
    this.stateError,
    this.cityError,
  });

  final String? state;
  final String? city;
  final ValueChanged<String> onState;
  final ValueChanged<String> onCity;
  final String? stateError;
  final String? cityError;

  @override
  State<StateCityFields> createState() => _StateCityFieldsState();
}

class _StateCityFieldsState extends State<StateCityFields> {
  static const _other = '__other__';

  List<String> _states = const [];
  List<String> _cities = const [];
  bool _loadingStates = true;
  bool _loadingCities = false;

  /// True once the guest chose "Other", so the free-text box stays open even
  /// after they clear what they typed.
  bool _cityIsFreeText = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  @override
  void didUpdateWidget(covariant StateCityFields old) {
    super.didUpdateWidget(old);
    // The state can change from OUTSIDE the dropdown — the map picker writes
    // state and city together when a pin lands in another state. The city list
    // is only reloaded by the dropdown's own handler, so without this the
    // options underneath stayed those of the previous state. The picked city
    // still showed (see _withCurrent), but opening the list offered the wrong
    // towns.
    //
    // The city is NOT cleared here. A state that arrived with its own city is
    // not an orphaned city, and clearing it is exactly the bug the website had:
    // the pin filled the city and the state-change handler wiped it a moment
    // later.
    final next = widget.state?.trim() ?? '';
    final prev = old.state?.trim() ?? '';
    if (next != prev && next.isNotEmpty) {
      _cityIsFreeText = false;
      _loadCities(next);
    }
  }

  Future<void> _boot() async {
    final states = await LocationsService.instance.states();
    if (!mounted) return;
    setState(() {
      _states = states;
      _loadingStates = false;
    });
    final s = widget.state?.trim() ?? '';
    if (s.isNotEmpty) await _loadCities(s);
  }

  Future<void> _loadCities(String state) async {
    setState(() => _loadingCities = true);
    final cities = await LocationsService.instance.cities(state);
    if (!mounted) return;
    setState(() {
      _cities = cities;
      _loadingCities = false;
      final c = widget.city?.trim() ?? '';
      // A city already on the record that this state does not list is treated
      // as free text rather than thrown away.
      if (c.isNotEmpty && !cities.contains(c)) _cityIsFreeText = true;
    });
  }

  /// The options for a dropdown, with [current] added when the list does not
  /// contain it — so an existing value can never vanish just because the
  /// reference table has moved on.
  List<String> _withCurrent(List<String> options, String? current) {
    final c = current?.trim() ?? '';
    if (c.isEmpty || options.contains(c)) return options;
    return [c, ...options];
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state?.trim() ?? '';
    final city = widget.city?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('State', required: true),
        const SizedBox(height: 6),
        _loadingStates
            ? _loadingBox()
            : _states.isEmpty
                // The list could not be fetched. Typing is better than a dead
                // form, so fall back rather than block.
                ? _freeText(
                    value: state,
                    hint: 'State',
                    onChanged: widget.onState,
                    error: widget.stateError,
                  )
                : _dropdown(
                    value: state.isEmpty ? null : state,
                    items: _withCurrent(_states, state),
                    hint: 'Choose a state',
                    error: widget.stateError,
                    onChanged: (v) {
                      if (v == null) return;
                      widget.onState(v);
                      // A city from the old state is no longer valid.
                      if (city.isNotEmpty) widget.onCity('');
                      setState(() {
                        _cityIsFreeText = false;
                        _cities = const [];
                      });
                      _loadCities(v);
                    },
                  ),
        const SizedBox(height: 14),
        _label('City', required: true),
        const SizedBox(height: 6),
        if (state.isEmpty)
          _hintBox('Choose a state first')
        else if (_loadingCities)
          _loadingBox()
        else if (_cityIsFreeText || _cities.isEmpty)
          _freeText(
            value: city,
            hint: 'City or town',
            onChanged: widget.onCity,
            error: widget.cityError,
            // Only offer the way back when there is a list to go back to.
            onBackToList: _cities.isEmpty
                ? null
                : () => setState(() {
                      _cityIsFreeText = false;
                      widget.onCity('');
                    }),
          )
        else
          _dropdown(
            value: city.isEmpty ? null : city,
            items: [..._withCurrent(_cities, city), _other],
            hint: 'Choose a city',
            error: widget.cityError,
            labelFor: (v) => v == _other ? 'Other — type it in' : v,
            onChanged: (v) {
              if (v == null) return;
              if (v == _other) {
                setState(() => _cityIsFreeText = true);
                widget.onCity('');
                return;
              }
              widget.onCity(v);
            },
          ),
      ],
    );
  }

  Widget _label(String text, {bool required = false}) => RichText(
        text: TextSpan(
          text: text,
          style: inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: kInk),
          children: required
              ? [
                  TextSpan(
                      text: ' *',
                      style: inter(fontSize: 13.5, color: kDanger)),
                ]
              : const [],
        ),
      );

  InputDecoration _decoration(String? error) => InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: error == null ? kLine : kDanger),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: error == null ? kIndigo : kDanger),
        ),
        errorText: error,
      );

  Widget _dropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
    String? error,
    String Function(String)? labelFor,
  }) =>
      DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: _decoration(error),
        hint: Text(hint, style: inter(fontSize: 14, color: kMuted)),
        style: inter(fontSize: 14, color: kInk),
        items: items
            .map((v) => DropdownMenuItem(
                  value: v,
                  child: Text(labelFor?.call(v) ?? v,
                      overflow: TextOverflow.ellipsis),
                ))
            .toList(),
        onChanged: onChanged,
      );

  Widget _freeText({
    required String value,
    required String hint,
    required ValueChanged<String> onChanged,
    String? error,
    VoidCallback? onBackToList,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            initialValue: value,
            decoration: _decoration(error).copyWith(hintText: hint),
            style: inter(fontSize: 14, color: kInk),
            onChanged: onChanged,
          ),
          if (onBackToList != null)
            TextButton(
              onPressed: onBackToList,
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: Text('Pick from the list instead',
                  style: inter(fontSize: 12.5, color: kIndigo)),
            ),
        ],
      );

  Widget _loadingBox() => Container(
        height: 52,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kLine),
        ),
        child: Row(
          children: [
            const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 10),
            Text('Loading…', style: inter(fontSize: 13.5, color: kMuted)),
          ],
        ),
      );

  Widget _hintBox(String text) => Container(
        height: 52,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: kCream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kLine),
        ),
        child: Text(text, style: inter(fontSize: 13.5, color: kMuted)),
      );
}
