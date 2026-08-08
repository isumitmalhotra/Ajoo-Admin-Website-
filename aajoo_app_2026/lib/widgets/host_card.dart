import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/utils/fonts.dart';

/// AajooHomes host card — POC mobile property detail "Hosted by" block.
///
///   ┌──────────────────────────────────────────────────┐
///   │ [● Avatar]    Hosted by Priya                    │
///   │   ✓ badge    Superhost · Replies in 1 hr         │
///   └──────────────────────────────────────────────────┘
///
/// Pure presentation widget — caller supplies name, photo, and tagline.
class HostCard extends StatelessWidget {
  final String hostName;
  final String? photoUrl;
  final String tagline;
  final bool isVerified;

  const HostCard({
    super.key,
    required this.hostName,
    this.photoUrl,
    this.tagline = 'Superhost · Replies in 1 hr',
    this.isVerified = true,
  });

  String get _initial =>
      hostName.trim().isEmpty ? 'A' : hostName.trim()[0].toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Container(
      // POC-style card chrome around the host row.
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kLine),
        boxShadow: [
          BoxShadow(
            color: kInk.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar + verified check badge — soft coral background with
          // white initial (POC styling). Photo overrides background when set.
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _avatarBg,
                    shape: BoxShape.circle,
                    image: (photoUrl != null && photoUrl!.isNotEmpty)
                        ? DecorationImage(
                            image: NetworkImage(photoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: (photoUrl == null || photoUrl!.isEmpty)
                      ? Center(
                          child: Text(
                            _initial,
                            style: fraunces(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: kCream,
                            ),
                          ),
                        )
                      : null,
                ),
                if (isVerified)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: kSuccess,
                        shape: BoxShape.circle,
                        border: Border.all(color: kCream, width: 2),
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 10,
                        color: kCream,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Name + tagline
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hosted by $hostName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: fraunces(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: kInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tagline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: inter(
                    fontSize: 13,
                    color: kMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Soft coral — derived from kClay but desaturated so it doesn't compete
  // with the clay Reserve CTA. Falls in the same warm family.
  static const Color _avatarBg = Color(0xFFD58866);
}
