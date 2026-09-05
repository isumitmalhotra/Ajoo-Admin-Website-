// Where is the property? — the map, on the phone.
//
// The listing wizard asked hosts to TYPE their state, city, district, village,
// PIN and street, and never captured a coordinate at all. A listing created on
// the app therefore had no pin, and a property with no pin cannot be returned
// by any location search: it exists in the catalogue and is invisible in the
// one place guests look. The website has had this picker for months; this is
// the same gesture, and it fills the same six fields.
//
// Two deliberate choices:
//
//   • The pin is FIXED at the centre and the map moves under it. Dragging a
//     marker on a phone means putting a fingertip on the exact thing it is
//     meant to hide; moving the map is the pattern every map app on the device
//     already uses.
//   • The address is looked up for the point actually chosen, even when a
//     search suggestion appears to carry one. Suggestions come back with an
//     empty address whenever the backend answers from Google's legacy Text
//     Search, which cannot return address components — and which generation
//     answers is a console setting no client can see. Trusting the suggestion
//     is exactly what left the website's form blank.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/service/geocode_service.dart';
import 'package:rent_home/utils/fonts.dart';

/// Open the picker. Resolves to the chosen address, or null if it was closed.
Future<PickedAddress?> showListingLocationPicker(
  BuildContext context, {
  double? initialLat,
  double? initialLng,
}) {
  return showModalBottomSheet<PickedAddress>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => _LocationPickerSheet(
      initialLat: initialLat,
      initialLng: initialLng,
    ),
  );
}

class _LocationPickerSheet extends StatefulWidget {
  const _LocationPickerSheet({this.initialLat, this.initialLng});

  final double? initialLat;
  final double? initialLng;

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  /// India's rough centre — only ever used when the host has no saved pin and
  /// no location permission, so the map opens on the country rather than on
  /// the Gulf of Guinea, which is where (0, 0) is.
  static const LatLng _fallback = LatLng(22.9734, 78.6569);

  GoogleMapController? _map;
  late LatLng _target;
  final _searchController = TextEditingController();

  List<GeoPlace> _hits = const [];
  bool _searching = false;
  bool _resolving = false;
  PickedAddress? _resolved;
  String _note = '';

  Timer? _searchDebounce;
  Timer? _idleDebounce;

  /// Guards a slow reply for a pin the host has already moved away from.
  int _lookupSeq = 0;

  @override
  void initState() {
    super.initState();
    final lat = widget.initialLat, lng = widget.initialLng;
    final hasPin = lat != null && lng != null && (lat != 0 || lng != 0);
    _target = hasPin ? LatLng(lat, lng) : _fallback;
    if (hasPin) {
      _lookup(_target);
    } else {
      // No saved pin: offer the host's own position rather than making them
      // pan across the country. Silent if permission is refused — the search
      // box and the map still work.
      _useMyLocation(silent: true);
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _idleDebounce?.cancel();
    _searchController.dispose();
    _map?.dispose();
    super.dispose();
  }

  // ── Lookup ────────────────────────────────────────────────────────────────

  Future<void> _lookup(LatLng at) async {
    final seq = ++_lookupSeq;
    setState(() {
      _resolving = true;
      _note = '';
    });
    final found = await GeocodeService.instance.reverse(at.latitude, at.longitude);
    if (!mounted || seq != _lookupSeq) return;
    setState(() {
      _resolving = false;
      // The pin counts even when the lookup fails or finds nothing: the
      // coordinates are the one thing the form cannot do without, and the host
      // can still type the address themselves.
      _resolved = found ?? PickedAddress(lat: at.latitude, lng: at.longitude);
      if (found == null) {
        _note = "We couldn't look this spot up. The pin is saved — fill the "
            'address in yourself.';
      } else if (found.isEmpty) {
        _note = 'No address on record for this exact spot. The pin is saved.';
      }
    });
  }

  void _moveTo(LatLng at, {double zoom = 16}) {
    setState(() => _target = at);
    _map?.animateCamera(CameraUpdate.newLatLngZoom(at, zoom));
    _lookup(at);
  }

  // ── Search ────────────────────────────────────────────────────────────────

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    final q = value.trim();
    if (q.length < 3) {
      setState(() => _hits = const []);
      return;
    }
    // One request per pause, not one per keystroke.
    _searchDebounce = Timer(const Duration(milliseconds: 450), () async {
      if (!mounted) return;
      setState(() => _searching = true);
      final found = await GeocodeService.instance.search(q);
      if (!mounted || _searchController.text.trim() != q) return;
      setState(() {
        _hits = found;
        _searching = false;
      });
    });
  }

  Future<void> _useMyLocation({bool silent = false}) async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!silent && mounted) {
          setState(() => _note =
              'Location is off. Search for the town instead, or move the map.');
        }
        return;
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      _moveTo(LatLng(p.latitude, p.longitude));
    } catch (_) {
      if (!silent && mounted) {
        setState(() => _note = "Couldn't find you. Search for the town instead.");
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Container(
      height: height * 0.92,
      decoration: const BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        children: [
          _header(),
          _searchBar(),
          Expanded(child: _map_(context)),
          _footer(),
        ],
      ),
    );
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 8, 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Where is the property?',
                      style: fraunces(
                          fontSize: 18, fontWeight: FontWeight.w700, color: kInk)),
                  const SizedBox(height: 2),
                  Text('Search, or move the map under the pin.',
                      style: inter(fontSize: 12.5, color: kMuted)),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => _useMyLocation(),
              icon: const Icon(Icons.my_location_rounded, size: 17),
              label: Text('My location',
                  style: inter(fontSize: 12.5, fontWeight: FontWeight.w600)),
              style: TextButton.styleFrom(foregroundColor: kprimaryColor),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, color: kInk2),
              tooltip: 'Close',
            ),
          ],
        ),
      );

  Widget _searchBar() => Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          textInputAction: TextInputAction.search,
          style: inter(fontSize: 14, color: kInk),
          decoration: InputDecoration(
            hintText: 'Search a town, area or landmark',
            hintStyle: inter(fontSize: 13.5, color: kMuted),
            prefixIcon: const Icon(Icons.search_rounded, color: kMuted, size: 20),
            suffixIcon: _searching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : (_searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _hits = const []);
                        },
                      )),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kLine),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kLine),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kprimaryColor, width: 1.4),
            ),
          ),
        ),
      );

  Widget _map_(BuildContext context) => Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: _target, zoom: 15),
              onMapCreated: (c) => _map = c,
              myLocationButtonEnabled: false,
              myLocationEnabled: false,
              zoomControlsEnabled: false,
              // The map moves under a fixed pin, so the camera IS the answer.
              onCameraMove: (pos) => _target = pos.target,
              onCameraIdle: () {
                _idleDebounce?.cancel();
                _idleDebounce =
                    Timer(const Duration(milliseconds: 400), () => _lookup(_target));
              },
              onTap: _moveTo,
            ),
          ),
          // The pin itself: dead centre, lifted by half its height so the point
          // sits on the coordinate rather than the middle of the teardrop.
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 34),
                child: Icon(Icons.location_on,
                    size: 44,
                    color: kprimaryColor,
                    shadows: [
                      Shadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2))
                    ]),
              ),
            ),
          ),
          if (_hits.isNotEmpty) _suggestions(),
        ],
      );

  Widget _suggestions() => Positioned(
        left: 12,
        right: 12,
        top: 0,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _hits.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: kLine),
              itemBuilder: (_, i) {
                final p = _hits[i];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.place_outlined, size: 19, color: kMuted),
                  title: Text(p.shortName,
                      style: inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: kInk)),
                  subtitle: p.context.isEmpty
                      ? null
                      : Text(p.context,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: inter(fontSize: 11.5, color: kMuted)),
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    _searchController.text = p.shortName;
                    setState(() => _hits = const []);
                    // Look the CHOSEN point up rather than trusting whatever
                    // address the suggestion carried — see the note at the top.
                    _moveTo(LatLng(p.lat, p.lng));
                  },
                );
              },
            ),
          ),
        ),
      );

  Widget _footer() {
    final a = _resolved;
    final line = _resolving
        ? 'Looking up this spot…'
        : (a?.label.isNotEmpty == true
            ? a!.label
            : 'Move the map to place the pin.');
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: kLine)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(Icons.place_rounded, size: 16, color: kprimaryColor),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(line,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: inter(fontSize: 12.5, color: kInk2)),
              ),
            ],
          ),
          if (_note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(_note, style: inter(fontSize: 11.5, color: kMuted)),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              // Enabled as soon as there is a pin. An address we could not
              // resolve must not block a listing — the fields are editable.
              onPressed: (a == null || _resolving)
                  ? null
                  : () => Navigator.pop(context, a),
              icon: const Icon(Icons.check_rounded, size: 19),
              label: Text('Use this location',
                  style: inter(fontSize: 14.5, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kprimaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: kLine,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
