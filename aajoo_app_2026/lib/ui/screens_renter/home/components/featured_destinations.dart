// Featured Destinations — the website's rail, on the phone.
//
// Replaces the third property carousel on the home screen ("Find Your Stay").
// The home already carried admin-curated featured stays and two more property
// rails above this point, so a fourth list of the same cards was repetition;
// the website answers "where could I go?" at this spot instead, and the client
// asked for the same here.
//
// Every tile is real: name and count come from /properties/destinations, the
// same endpoint the site reads, so the two can never disagree about which
// places exist or how many stays are in them. A tile with no coordinates is
// not shown, because tapping it could not centre a search anywhere.
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/models/destination_model.dart';
import 'package:rent_home/service/property_service.dart';
import 'package:rent_home/utils/fonts.dart';

class FeaturedDestinations extends StatefulWidget {
  const FeaturedDestinations({super.key, required this.onSelect});

  /// Centre the map/search on this place — same path a search selection takes,
  /// so the rail changes what you are browsing rather than opening a dead end.
  final void Function(Destination destination, LatLng position) onSelect;

  @override
  State<FeaturedDestinations> createState() => _FeaturedDestinationsState();
}

class _FeaturedDestinationsState extends State<FeaturedDestinations> {
  final PropertyService _service = PropertyService();
  List<Destination> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await _service.getDestinations(limit: 8);
    if (!mounted) return;
    setState(() {
      _items = rows.where((d) => d.hasPosition && d.count > 0).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Nothing to show → show nothing. A heading over an empty shelf promises
    // something the catalogue cannot deliver.
    if (!_loading && _items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Featured Destinations',
              style: fraunces(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: kInk,
              ),
            ),
            if (!_loading)
              Text(
                '${_items.length} places',
                style: inter(fontSize: 12, color: kMuted),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Where our hosts are, right now.',
          style: inter(fontSize: 13, color: kMuted),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 132,
          child: _loading
              ? ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, __) => Container(
                    width: 168,
                    decoration: BoxDecoration(
                      color: kIndigo50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) => _DestinationTile(
                    destination: _items[i],
                    onTap: () => widget.onSelect(
                      _items[i],
                      LatLng(_items[i].lat!, _items[i].lng!),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _DestinationTile extends StatelessWidget {
  const _DestinationTile({required this.destination, required this.onTap});

  final Destination destination;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 168,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kLine),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: kIndigo50,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.place_outlined, size: 20, color: kIndigo),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  destination.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: fraunces(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: kInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  destination.staysLabel,
                  style: inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: kClay,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
