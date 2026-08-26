import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/ui/design/aajoo_skin.dart';
import 'package:rent_home/utils/fonts.dart';

/// AajooHomes search pill — matches the POC mobile search row.
///
///   ┌───────────────────────────────────────────────────────┐
///   │ 🔍   **Goa** · 22–25 May · 3 guests                   │
///   └───────────────────────────────────────────────────────┘
///
/// Single tap opens whatever search/filter flow the caller wires up.
class SearchPill extends StatelessWidget {
  /// Bold location label (e.g. "Goa", "Nearby"). Defaults to "Where to?".
  final String location;

  /// Free-text trailing details ("22–25 May · 3 guests").
  ///
  /// Null or empty renders no second line and the pill centres on the place.
  /// The default used to be the literal string "Any week · 1 guest", which the
  /// home screen then passed explicitly as well — so the subtitle said the
  /// same thing forever regardless of what had been searched. A summary that
  /// cannot change is not a summary.
  final String? details;

  final VoidCallback? onTap;

  const SearchPill({
    super.key,
    this.location = 'Where to?',
    this.details,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // The pill is the brightest object on the map, so in LUX a white capsule
    // with a teal button was the first thing that said the mode had not
    // taken. Skinned like the site's own search bar: the near-black surface,
    // a gold hairline, and the mode's own placeholder ink.
    return LuxBuilder(
      builder: (context, skin) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            decoration: BoxDecoration(
              color: skin.isLux ? skin.surface : kSurface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: skin.line),
              boxShadow: skin.shadow,
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                Icon(Icons.location_on_outlined,
                    color: skin.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: skin.ink)),
                      if (details != null && details!.isNotEmpty)
                        Text(details!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: inter(
                                fontSize: 12, color: skin.placeholder)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      color: skin.primary, shape: BoxShape.circle),
                  child: Icon(Icons.search,
                      color: skin.onPrimary, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
