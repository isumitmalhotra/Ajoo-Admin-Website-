import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/utils/fonts.dart';

/// AajooHomes verified pill — kSuccess dot + label on a cream pill.
///
///   ( ● Verified )    or    ( ● Visited 12 May )
///
/// Used on the property detail meta row and anywhere we surface the
/// "this listing is verified" promise.
class VerifiedPill extends StatelessWidget {
  final String label;
  final EdgeInsetsGeometry padding;

  const VerifiedPill({
    super.key,
    this.label = 'Verified',
    this.padding =
        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        // Soft green tint — derived from kSuccess at low opacity over cream.
        // Matches the POC's light-green "verified" chip.
        color: kSuccess.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: kSuccess,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kSuccess,
            ),
          ),
        ],
      ),
    );
  }
}
