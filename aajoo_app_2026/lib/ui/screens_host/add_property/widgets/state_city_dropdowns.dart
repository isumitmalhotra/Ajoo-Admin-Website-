import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/data/ApiConstants.dart';
import 'package:rent_home/data/source/remote/dio_config.dart';

/// Linked State → City dropdowns for address forms — the same reference data
/// the website's forms use (/public/locations/*, 37 states and UTs, ~1,480
/// cities), so both platforms offer one address vocabulary.
///
/// Free-text state/city fields are how the catalogue accumulated thousands of
/// junk city labels; a dropdown makes the typo impossible. The map picker
/// still writes whatever it resolves into the SAME controllers — a value the
/// list doesn't know is shown as an extra "(from map)" entry rather than being
/// wiped — and the city list ends with "Other — type it in", because no city
/// list is ever complete and a missing village must not block a listing.
///
/// Wraps the two existing TextEditingControllers so the form's save and
/// validation logic stay untouched.
class StateCityDropdowns extends StatefulWidget {
  final TextEditingController stateController;
  final TextEditingController cityController;

  const StateCityDropdowns({
    super.key,
    required this.stateController,
    required this.cityController,
  });

  @override
  State<StateCityDropdowns> createState() => _StateCityDropdownsState();
}

class _StateCityDropdownsState extends State<StateCityDropdowns> {
  static List<String>? _statesCache;
  static final Map<String, List<String>> _cityCache = {};

  final Dio _dio = Dio();
  List<String> _states = [];
  List<String> _cities = [];
  bool _loadingCities = false;
  bool _cityManual = false;
  static const _other = '__other__';

  @override
  void initState() {
    super.initState();
    DioConfig.apply(_dio, Apiconstants.baseUrl);
    _loadStates();
    // The map picker writes into these controllers from outside; rebuild so
    // the dropdowns follow it.
    widget.stateController.addListener(_onExternalChange);
    widget.cityController.addListener(_onExternalChange);
    if (widget.stateController.text.trim().isNotEmpty) {
      _loadCities(widget.stateController.text.trim());
    }
  }

  void _onExternalChange() {
    if (!mounted) return;
    final st = widget.stateController.text.trim();
    if (st.isNotEmpty && !_cityCache.containsKey(st.toLowerCase())) {
      _loadCities(st);
    } else {
      setState(() {
        _cities = _cityCache[st.toLowerCase()] ?? [];
      });
    }
  }

  Future<void> _loadStates() async {
    if (_statesCache != null) {
      setState(() => _states = _statesCache!);
      return;
    }
    try {
      final res = await _dio.get('/public/locations/states');
      final body = res.data;
      final list = (body is Map && body['success'] == true)
          ? List<String>.from(body['data']?['states'] ?? [])
          : <String>[];
      _statesCache = list;
      if (mounted) setState(() => _states = list);
    } catch (_) {
      if (mounted) setState(() => _states = []);
    }
  }

  Future<void> _loadCities(String state) async {
    final key = state.toLowerCase();
    if (_cityCache.containsKey(key)) {
      setState(() => _cities = _cityCache[key]!);
      return;
    }
    setState(() => _loadingCities = true);
    try {
      final res = await _dio.get('/public/locations/cities',
          queryParameters: {'state': state});
      final body = res.data;
      final list = (body is Map && body['success'] == true)
          ? List<String>.from(body['data']?['cities'] ?? [])
          : <String>[];
      _cityCache[key] = list;
    } catch (_) {
      _cityCache[key] = [];
    }
    if (mounted) {
      setState(() {
        _cities = _cityCache[key]!;
        _loadingCities = false;
      });
    }
  }

  /// The stored value, or the list entry differing only in case.
  String? _match(List<String> list, String value) {
    if (value.isEmpty) return null;
    for (final v in list) {
      if (v.toLowerCase() == value.toLowerCase()) return v;
    }
    return null;
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: kSand,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kLine),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  @override
  Widget build(BuildContext context) {
    final stateText = widget.stateController.text.trim();
    final cityText = widget.cityController.text.trim();
    final stateValue = _match(_states, stateText) ?? (stateText.isEmpty ? null : stateText);
    final cityValue = _match(_cities, cityText) ?? (cityText.isEmpty ? null : cityText);

    final stateItems = <DropdownMenuItem<String>>[
      // A map-resolved state the list doesn't know stays selectable.
      if (stateText.isNotEmpty && _match(_states, stateText) == null)
        DropdownMenuItem(value: stateText, child: Text('$stateText (from map)')),
      ..._states.map((s) => DropdownMenuItem(value: s, child: Text(s))),
    ];

    final cityItems = <DropdownMenuItem<String>>[
      if (cityText.isNotEmpty && _match(_cities, cityText) == null)
        DropdownMenuItem(value: cityText, child: Text('$cityText (from map)')),
      ..._cities.map((c) => DropdownMenuItem(value: c, child: Text(c))),
      const DropdownMenuItem(value: _other, child: Text('Other — type it in')),
    ];

    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: stateValue,
          isExpanded: true,
          decoration: _dec('State *'),
          items: stateItems,
          validator: (v) => (v == null || v.isEmpty) ? 'Please select State' : null,
          onChanged: (v) {
            if (v == null) return;
            widget.stateController.text = v;
            widget.cityController.text = '';
            _cityManual = false;
            _loadCities(v);
          },
        ),
        const SizedBox(height: 12),
        if (_cityManual)
          TextFormField(
            initialValue: cityText,
            decoration: _dec('City *').copyWith(
              helperText: 'Not on the list — typed manually',
              suffixIcon: IconButton(
                icon: const Icon(Icons.list, size: 18),
                tooltip: 'Pick from the list instead',
                onPressed: () => setState(() {
                  _cityManual = false;
                  widget.cityController.text = '';
                }),
              ),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter City' : null,
            onChanged: (v) => widget.cityController.text = v,
          )
        else
          DropdownButtonFormField<String>(
            value: cityValue,
            isExpanded: true,
            decoration: _dec('City *').copyWith(
              helperText: stateText.isEmpty
                  ? 'Choose a state first'
                  : _loadingCities
                      ? 'Loading cities…'
                      : null,
            ),
            items: cityItems,
            validator: (v) => (v == null || v.isEmpty) ? 'Please select City' : null,
            onChanged: stateText.isEmpty
                ? null
                : (v) {
                    if (v == null) return;
                    if (v == _other) {
                      setState(() {
                        _cityManual = true;
                        widget.cityController.text = '';
                      });
                    } else {
                      widget.cityController.text = v;
                    }
                  },
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  void dispose() {
    widget.stateController.removeListener(_onExternalChange);
    widget.cityController.removeListener(_onExternalChange);
    super.dispose();
  }
}
