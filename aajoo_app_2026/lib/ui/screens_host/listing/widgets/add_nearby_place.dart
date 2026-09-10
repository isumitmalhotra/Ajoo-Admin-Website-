/// "Add a place" — the one thing Google cannot do for a host.
///
/// The suggestion picker asks Google what is around a property, which is very
/// good for hospitals and shopping malls and poor for the things a guest
/// actually books a homestay for: the family temple two villages over, the
/// trout stream, the viewpoint everyone local knows and nobody has ever added
/// to Maps. A host who wanted one of those had a separate grid of bare
/// kilometre boxes further down the step, disconnected from the section it
/// belonged to and with nowhere to put the name.
///
/// THE POSITION IS ASKED FOR, not assumed. Typing a name still runs it through
/// the place search, so a landmark Maps DOES know keeps its coordinates —
/// which is what lets the guest page offer directions to it, and what lets the
/// distance be measured rather than guessed.
///
/// THE NAME STAYS THE HOST'S. Choosing a match supplies the position and
/// nothing else. On the website this briefly rewrote the box with the
/// geocoder's first comma-part, so "Gurdwara Nada Sahib" became "Chaunki" —
/// the hamlet it stands in. The host had named it correctly and the form
/// replaced it with something no guest would recognise.
///
/// Only when nothing matches does the host type the distance, and then the
/// entry is marked as theirs: source "manual", which the guest page shows as
/// "Host provided".
///
/// A PICKED POSITION SURVIVES AN EDIT TO THE NAME. Every keystroke used to
/// detach it while leaving the measured distance in the box, so a host who
/// picked "Gurdwara Nada Sahib" and then added a word ended up saving a
/// distance that looked measured with no position behind it — no directions
/// for the guest, and nothing on screen saying so. Picking a match is an
/// explicit act; typing in a name box is not. Only three things detach a
/// position now: emptying the name (an unambiguous start-over), picking a
/// different match, and the "Not this place" control.
///
/// AND THE POSITION IS NAMED. "Found on the map" never said WHICH map point,
/// so a wrong one was invisible. The geocoder's own label is shown, which is
/// exactly the text that makes a mismatch obvious — "Chaunki, Panchkula" under
/// a name reading "Gurdwara Nada Sahib" is a question the host can answer.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/service/geocode_service.dart';
import 'package:rent_home/utils/fonts.dart';

/// Kilometres between two points, near enough for a "3.2 km" label.
double nearbyDistanceKm(double aLat, double aLng, double bLat, double bLng) {
  const r = 6371.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(bLat - aLat);
  final dLng = rad(bLng - aLng);
  final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(aLat)) *
          math.cos(rad(bLat)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  final km = 2 * r * math.asin(math.sqrt(h));
  return (km * 10).round() / 10;
}

class AddNearbyPlace extends StatefulWidget {
  const AddNearbyPlace({
    super.key,
    required this.propertyLat,
    required this.propertyLng,
    required this.onAdd,
    this.search,
  });

  final double? propertyLat;
  final double? propertyLng;

  /// {name, km, lat, lng} — lat/lng null when nothing matched.
  final void Function(Map<String, dynamic> place) onAdd;

  /// The place lookup. Defaults to the real one; a test supplies its own so
  /// the attach/detach rules can be driven without a network or a singleton.
  final Future<List<GeoPlace>> Function(String query)? search;

  @override
  State<AddNearbyPlace> createState() => _AddNearbyPlaceState();
}

class _AddNearbyPlaceState extends State<AddNearbyPlace> {
  final _name = TextEditingController();
  final _km = TextEditingController();
  bool _open = false;
  bool _busy = false;
  List<GeoPlace> _hits = const [];
  GeoPlace? _chosen;
  Timer? _debounce;

  /// The exact text a match was picked for, so the search does not immediately
  /// re-fire and reopen the list over the choice just made. Any further typing
  /// differs from it and searching resumes — which is how a host corrects a
  /// wrong pick without having to detach it first.
  String? _suppressFor;

  @override
  void dispose() {
    _debounce?.cancel();
    _name.dispose();
    _km.dispose();
    super.dispose();
  }

  void _onTyped(String v) {
    _debounce?.cancel();
    final text = v.trim();
    // Emptying the box is the one unambiguous start-over, and the only edit
    // that detaches a position on its own.
    if (text.isEmpty) setState(() => _chosen = null);
    if (text.length < 3 || text == _suppressFor) {
      setState(() => _hits = const []);
      return;
    }
    // Debounced: this is a billed lookup, and a host types a place name one
    // word at a time.
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      if (!mounted) return;
      setState(() => _busy = true);
      final lookup = widget.search ?? GeocodeService.instance.search;
      final r = await lookup(text);
      if (!mounted) return;
      setState(() {
        _hits = r.take(5).toList();
        _busy = false;
      });
    });
  }

  void _pick(GeoPlace p) {
    setState(() {
      _chosen = p;
      _hits = const [];
      _suppressFor = _name.text.trim();
      // Measured, not typed, whenever both ends are known. The NAME is left
      // alone — see the note at the top of this file.
      final lat = widget.propertyLat;
      final lng = widget.propertyLng;
      if (lat != null && lng != null) {
        _km.text = nearbyDistanceKm(lat, lng, p.lat, p.lng).toString();
      }
    });
  }

  /// Detach the position, keeping the distance.
  ///
  /// The number may well still be right, and the host has said nothing to
  /// suggest otherwise — clearing it would throw away work to prove a point.
  /// What changes is the claim: with no position the entry is a hand-typed
  /// distance, which is what the line under the field now says.
  void _detach() {
    setState(() {
      _chosen = null;
      _suppressFor = null;
    });
  }

  void _reset() {
    _name.clear();
    _km.clear();
    setState(() {
      _open = false;
      _hits = const [];
      _chosen = null;
      _suppressFor = null;
    });
  }

  void _submit() {
    final name = _name.text.trim();
    final km = double.tryParse(_km.text.trim());
    if (name.isEmpty || km == null || km < 0) return;
    widget.onAdd({
      'name': name.length > 160 ? name.substring(0, 160) : name,
      'km': (km * 100).round() / 100,
      'lat': _chosen?.lat,
      'lng': _chosen?.lng,
    });
    _reset();
  }

  @override
  Widget build(BuildContext context) {
    if (!_open) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(() => _open = true),
          icon: const Icon(Icons.add_rounded, size: 16),
          label: Text('Add a place',
              style: inter(fontSize: 12.5, fontWeight: FontWeight.w600)),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSand,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Place name',
              style: inter(
                  fontSize: 12.5, fontWeight: FontWeight.w600, color: kInk)),
          const SizedBox(height: 6),
          TextField(
            controller: _name,
            maxLength: 160,
            onChanged: _onTyped,
            decoration: const InputDecoration(
              counterText: '',
              hintText: 'e.g. Baba Balak Nath Temple',
              isDense: true,
            ),
          ),
          if (_chosen != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Found on the map: ${_chosen!.label}\n'
                    'Guests will get directions to it.',
                    style: inter(fontSize: 11.5, color: kMuted, height: 1.35),
                  ),
                ),
                TextButton(
                  onPressed: _detach,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('Not this place',
                      style:
                          inter(fontSize: 11.5, fontWeight: FontWeight.w600)),
                ),
              ],
            )
          else
            Text(
              "We'll look it up as you type. If it isn't on the map, type "
              'the distance yourself.',
              style: inter(fontSize: 11.5, color: kMuted, height: 1.35),
            ),
          if (_busy)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child:
                  Text('Searching…', style: inter(fontSize: 12, color: kMuted)),
            ),
          for (final h in _hits)
            InkWell(
              onTap: () => _pick(h),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: kLine)),
                ),
                child: Text(h.label,
                    style: inter(fontSize: 12.5, color: kInk, height: 1.35)),
              ),
            ),
          const SizedBox(height: 10),
          Text('Distance (km)',
              style: inter(
                  fontSize: 12.5, fontWeight: FontWeight.w600, color: kInk)),
          const SizedBox(height: 6),
          TextField(
            controller: _km,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(hintText: 'km', isDense: true),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ElevatedButton(onPressed: _submit, child: const Text('Add')),
              const SizedBox(width: 8),
              TextButton(onPressed: _reset, child: const Text('Cancel')),
            ],
          ),
        ],
      ),
    );
  }
}
