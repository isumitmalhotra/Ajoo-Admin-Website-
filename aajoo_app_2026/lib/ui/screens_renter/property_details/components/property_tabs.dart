import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/models/host_profile.dart';
import 'package:rent_home/models/single_property_response.dart';
import 'package:rent_home/utils/fonts.dart';

/// The seven detail sections, one at a time (A-29/A-30/A-31).
///
/// The app printed all of this down one very long scroll: description, then
/// check-in times, then amenities, then host, then rules, then gallery, then
/// tags, then reviews — and it was missing the map and the cancellation policy
/// the website shows. The spec asks for the website's shape instead: tap About
/// and you get the description and nothing else.
///
/// Everything here is driven by the listing. Where a host has entered nothing,
/// the panel says so rather than filling the space with defaults — the page
/// used to promise every stay had WiFi and free parking.
enum PropertyTab { about, amenities, rules, location, experiences, host, policies }

const _tabLabels = <PropertyTab, String>{
  PropertyTab.about: 'About',
  PropertyTab.amenities: 'Amenities',
  PropertyTab.rules: 'House Rules',
  PropertyTab.location: 'Location',
  // A-32 — "Guest experiences", not "Reviews".
  PropertyTab.experiences: 'Guest experiences',
  PropertyTab.host: 'Host',
  PropertyTab.policies: 'Policies',
};

class PropertyTabBar extends StatelessWidget {
  final PropertyTab active;
  final ValueChanged<PropertyTab> onChanged;
  final int reviewCount;

  /// Which tabs to draw, in order. Defaults to all seven; the booking detail
  /// drops Host on a cancelled booking.
  final List<PropertyTab>? only;

  const PropertyTabBar({
    super.key,
    required this.active,
    required this.onChanged,
    this.reviewCount = 0,
    this.only,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: (only ?? PropertyTab.values).map((t) {
          final selected = t == active;
          final label = t == PropertyTab.experiences && reviewCount > 0
              ? '${_tabLabels[t]} ($reviewCount)'
              : _tabLabels[t]!;
          return GestureDetector(
            onTap: () => onChanged(t),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    width: 2,
                    color: selected ? kIndigo600 : Colors.transparent,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: selected ? kInk : kMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Small shared heading used inside the panels.
class PanelTitle extends StatelessWidget {
  final String text;
  const PanelTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: fraunces(fontSize: 17, fontWeight: FontWeight.w600, color: kInk),
        ),
      );
}

class PanelEmpty extends StatelessWidget {
  final String text;
  const PanelEmpty(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(text, style: inter(fontSize: 13, color: kMuted, height: 1.5)),
      );
}

/// A rule line: a tick for what is allowed, a cross for what is not.
class RuleLine extends StatelessWidget {
  final bool ok;
  final String text;
  const RuleLine({super.key, required this.ok, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(ok ? Icons.check_circle_outline : Icons.cancel_outlined,
                size: 18, color: ok ? kIndigo600 : kMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: inter(fontSize: 13.5, color: kInk, height: 1.45)),
            ),
          ],
        ),
      );
}

/// A-34/A-35 — how far the airport, hospital, bus stand and the rest are.
///
/// Renders nothing when the host entered no distances, which is every listing
/// created before the listing wizard. Showing "0 km" for those would be
/// inventing the answer.
class NearbySection extends StatelessWidget {
  final List<NearbyGroup> groups;
  const NearbySection({super.key, required this.groups});

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        const PanelTitle("What's nearby"),
        ...groups.map((g) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    g.label.toUpperCase(),
                    style: inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .4,
                        color: kMuted),
                  ),
                  const SizedBox(height: 6),
                  ...g.places.map((p) => Container(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: kLine)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(p.place,
                                  style: inter(fontSize: 13.5, color: kInk)),
                            ),
                            Text(p.distanceLabel,
                                style: inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: kMuted)),
                          ],
                        ),
                      )),
                ],
              ),
            )),
      ],
    );
  }
}

/// The approximate area, same promise the website makes: the precise address is
/// only shared after booking.
class PropertyAreaMap extends StatelessWidget {
  final double? lat;
  final double? lng;
  const PropertyAreaMap({super.key, this.lat, this.lng});

  @override
  Widget build(BuildContext context) {
    final la = lat, ln = lng;
    if (la == null || ln == null || (la == 0 && ln == 0)) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: kSand,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text('Location not available',
              style: inter(fontSize: 13, color: kMuted)),
        ),
      );
    }
    final at = LatLng(la, ln);
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 200,
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: at, zoom: 13),
              // A pin on the exact coordinates would give away the address the
              // caption promises to withhold; a circle shows the area instead.
              circles: {
                Circle(
                  circleId: const CircleId('area'),
                  center: at,
                  radius: 700,
                  fillColor: kIndigo600.withOpacity(.14),
                  strokeColor: kIndigo600.withOpacity(.5),
                  strokeWidth: 2,
                ),
              },
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              liteModeEnabled: true,
            ),
            Positioned(
              left: 10,
              bottom: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Exact location shared after booking',
                    style: inter(fontSize: 11, color: kInk)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Turns the listing's rules into display lines.
///
/// Structured rules from the wizard win where present; the legacy pet/smoking
/// flags carry it otherwise. A rule the host never answered is left out — it is
/// not a "no".
List<Widget> buildRuleLines({
  required PropertyHouseRules? rules,
  required String? checkIn,
  required String? checkOut,
  required bool legacyPetFriendly,
  required bool legacySmoking,
  required bool hasLegacyFlags,
}) {
  final lines = <Widget>[];
  if (checkIn != null || checkOut != null) {
    final parts = [
      if (checkIn != null) 'Check-in from $checkIn',
      if (checkOut != null) 'Check-out by $checkOut',
    ];
    lines.add(RuleLine(ok: true, text: parts.join(' · ')));
  }

  void add(bool? v, String yes, String no) {
    if (v == null) return;
    lines.add(RuleLine(ok: v, text: v ? yes : no));
  }

  if (rules != null) {
    add(
      rules.petsAllowed,
      rules.petFee != null && rules.petFee! > 0
          ? 'Pets welcome (₹${rules.petFee!.round()} pet fee)'
          : 'Pets welcome',
      'No pets',
    );
    add(rules.smoking, 'Smoking allowed', 'No smoking indoors');
    add(rules.parties, 'Parties and events allowed', 'No parties or events');
    add(rules.alcohol, 'Alcohol permitted', 'No alcohol');
    add(rules.visitors, 'Visitors allowed', 'No outside visitors');
    add(rules.loudMusic, 'Loud music allowed', 'No loud music');
    add(rules.cookingAllowed, 'Cooking allowed', 'No cooking');
    add(rules.commercialShoot, 'Commercial shoots allowed',
        'No commercial shoots');
    if (rules.quietHours != null && rules.quietHours!.isNotEmpty) {
      lines.add(RuleLine(ok: true, text: 'Quiet hours ${rules.quietHours}'));
    }
    if (rules.selfCheckin == true) {
      lines.add(const RuleLine(ok: true, text: 'Self check-in'));
    }
    if (rules.caretakerAvailable == true) {
      lines.add(const RuleLine(ok: true, text: 'Caretaker on site'));
    }
    if (rules.damageDeposit == true) {
      lines.add(const RuleLine(
          ok: true, text: 'A refundable damage deposit applies'));
    }
  } else if (hasLegacyFlags) {
    lines.add(RuleLine(
        ok: legacyPetFriendly,
        text: legacyPetFriendly ? 'Pets welcome' : 'No pets'));
    lines.add(RuleLine(
        ok: legacySmoking,
        text: legacySmoking ? 'Smoking allowed' : 'No smoking indoors'));
  }
  return lines;
}

/// Everything the panels need that does not come from the single-property
/// payload.
///
/// The property page reaches this screen with a full Property already in hand
/// and falls back to it when the detail fetch fails; the booking-history
/// detail arrives with only a booking row. Both cases are "use this when the
/// listing did not say", so they go through one object.
class PropertyPanelFallback {
  final String description;
  final String location;
  final List<dynamic>? amenities;
  final String? latitude;
  final String? longitude;
  final String? contact;
  final bool? petFriendly;
  final bool? smoking;

  const PropertyPanelFallback({
    this.description = '',
    this.location = '',
    this.amenities,
    this.latitude,
    this.longitude,
    this.contact,
    this.petFriendly,
    this.smoking,
  });
}

/// The tab bar and its seven panels, as one widget.
///
/// This lived as ~240 lines of private methods on _PropertyPageState. The
/// booking-history detail needs the same seven sections under the booking
/// (A-62), and a second copy of the panels is a second place for the "empty
/// means hidden, never zero" rules to rot — the fake amenity list and the
/// invented house rules removed in batch 1 were exactly that kind of drift.
/// One implementation, two callers.
class PropertyDetailPanels extends StatefulWidget {
  final SinglePropertyData? single;
  final HostProfile? host;
  final int reviewCount;
  final PropertyPanelFallback fallback;

  /// Guest experiences differs per screen — the property page lists the
  /// listing's reviews with a "see all" route, the booking detail offers the
  /// review the guest can write for the stay they just had. Supplied by the
  /// caller rather than reimplemented here.
  ///
  /// A builder, not a Widget: the property page's version calls Get.find at
  /// build time, and building it eagerly would run that on every rebuild
  /// whatever tab is open — including when the controller is not registered.
  final Widget Function()? experiencesBuilder;

  /// Tabs to leave out. The booking detail hides Host on a cancelled booking,
  /// where the spec says the host must not be shown at all.
  final Set<PropertyTab> hidden;

  const PropertyDetailPanels({
    super.key,
    required this.single,
    this.host,
    this.reviewCount = 0,
    this.fallback = const PropertyPanelFallback(),
    this.experiencesBuilder,
    this.hidden = const {},
  });

  @override
  State<PropertyDetailPanels> createState() => _PropertyDetailPanelsState();
}

class _PropertyDetailPanelsState extends State<PropertyDetailPanels> {
  late PropertyTab _tab = _visible.first;

  List<PropertyTab> get _visible =>
      PropertyTab.values.where((t) => !widget.hidden.contains(t)).toList();

  @override
  void didUpdateWidget(covariant PropertyDetailPanels old) {
    super.didUpdateWidget(old);
    // A booking can flip to cancelled while this page is open, taking the Host
    // tab with it. Sitting on a tab that no longer exists would render nothing.
    if (widget.hidden.contains(_tab)) {
      setState(() => _tab = _visible.first);
    }
  }

  SinglePropertyData? get _s => widget.single;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PropertyTabBar(
          active: _tab,
          reviewCount: widget.reviewCount,
          onChanged: (t) => setState(() => _tab = t),
          only: _visible,
        ),
        const SizedBox(height: 16),
        _panel(),
      ],
    );
  }

  Widget _panel() {
    switch (_tab) {
      case PropertyTab.about:
        return _about();
      case PropertyTab.amenities:
        return _amenities();
      case PropertyTab.rules:
        return _rules();
      case PropertyTab.location:
        return _location();
      case PropertyTab.experiences:
        return widget.experiencesBuilder?.call() ?? const SizedBox.shrink();
      case PropertyTab.host:
        return _hostPanel();
      case PropertyTab.policies:
        return _policies();
    }
  }

  Widget _about() {
    final desc = (_s?.propertyDesc ?? widget.fallback.description).trim();
    final inTime = _s?.propDetails?.inTime;
    final outTime = _s?.propDetails?.outTime;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PanelTitle('About this stay'),
        if (desc.isEmpty)
          const PanelEmpty("The host hasn't written a description yet.")
        else
          Text(desc, style: inter(fontSize: 14, color: kInk, height: 1.65)),
        if (inTime != null || outTime != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.schedule_outlined, size: 18, color: kIndigo600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  [
                    if (inTime != null) 'Check-in from $inTime',
                    if (outTime != null) 'Check-out by $outTime',
                  ].join(' · '),
                  style: inter(fontSize: 13.5, color: kInk),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _amenities() {
    // Real amenities only — never the global tag list, which puts somebody
    // else's tags under this stay's heading.
    final list = _s?.amenities ?? widget.fallback.amenities;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PanelTitle('What this place offers'),
        if (list == null || list.isEmpty)
          const PanelEmpty(
              "The host hasn't listed amenities for this stay yet.")
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: list
                .map((a) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: kIndigo50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_outline,
                              size: 15, color: kIndigo600),
                          const SizedBox(width: 6),
                          Text(a.toString(),
                              style: inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: kIndigo600)),
                        ],
                      ),
                    ))
                .toList(),
          ),
      ],
    );
  }

  Widget _rules() {
    final legacyPet =
        (_s?.propDetails?.isPetFriendly ?? widget.fallback.petFriendly) == true;
    final legacySmoke =
        (_s?.propDetails?.isSmoke ?? widget.fallback.smoking) == true;
    final lines = buildRuleLines(
      rules: _s?.houseRules,
      checkIn: _s?.propDetails?.inTime,
      checkOut: _s?.propDetails?.outTime,
      legacyPetFriendly: legacyPet,
      legacySmoking: legacySmoke,
      hasLegacyFlags: _s != null,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PanelTitle('House rules'),
        if (lines.isEmpty)
          const PanelEmpty(
              "The host hasn't published house rules for this stay.")
        else
          ...lines,
      ],
    );
  }

  Widget _location() {
    final lat =
        double.tryParse(_s?.propertyLatitude ?? widget.fallback.latitude ?? '');
    final lng = double.tryParse(
        _s?.propertyLongitude ?? widget.fallback.longitude ?? '');
    // The caller's own label wins where it has one — the property page passes
    // the location string it was opened with, which is what it displayed
    // before these panels moved out of it. The listing's address is the
    // fallback, for callers (the booking detail) that have no label of theirs.
    final where = widget.fallback.location.trim().isNotEmpty
        ? widget.fallback.location
        : (_s?.propertyAddress ?? '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PanelTitle("Where you'll be"),
        if (where.trim().isNotEmpty)
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: kMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(where, style: inter(fontSize: 13, color: kMuted)),
              ),
            ],
          ),
        const SizedBox(height: 12),
        PropertyAreaMap(lat: lat, lng: lng),
        NearbySection(groups: _s?.nearby ?? const []),
      ],
    );
  }

  Widget _hostPanel() {
    final host = widget.host;
    final contact = _s?.propertyContact ?? widget.fallback.contact;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: kIndigo,
                backgroundImage: (host?.image != null)
                    ? CachedNetworkImageProvider(host!.image!)
                    : null,
                child: (host?.image == null)
                    ? Text(
                        (host?.name ?? 'H')
                            .trim()
                            .characters
                            .first
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hosted by ${host?.name ?? 'your host'}',
                        style: inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: kInk)),
                    const SizedBox(height: 2),
                    Text(host?.subtitle ?? 'Aajoo host',
                        style: inter(fontSize: 12, color: kMuted)),
                  ],
                ),
              ),
            ],
          ),
          if (contact != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.call_outlined, size: 16, color: kMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Listing contact: $contact',
                      style: inter(fontSize: 12.5, color: kMuted)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _policies() {
    final inTime = _s?.propDetails?.inTime;
    final outTime = _s?.propDetails?.outTime;
    final security = _s?.propDetails?.monthlySecurity;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PanelTitle('Policies'),
        const RuleLine(
            ok: true,
            text: 'Free cancellation up to 48 hours before check-in.'),
        if (inTime != null || outTime != null)
          RuleLine(
            ok: true,
            text: [
              if (inTime != null) 'Check-in $inTime',
              if (outTime != null) 'Check-out $outTime',
            ].join(' · '),
          ),
        if (security != null && security.isNotEmpty && security != '0')
          RuleLine(ok: true, text: 'Security deposit ₹$security'),
        const RuleLine(ok: true, text: 'Secure payment via trusted gateways.'),
        const RuleLine(
            ok: true, text: 'Price negotiable — send the host an offer.'),
      ],
    );
  }
}
