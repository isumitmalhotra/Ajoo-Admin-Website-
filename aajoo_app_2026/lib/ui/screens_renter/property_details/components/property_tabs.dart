import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rent_home/constants.dart';
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

  const PropertyTabBar({
    super.key,
    required this.active,
    required this.onChanged,
    this.reviewCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: PropertyTab.values.map((t) {
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
