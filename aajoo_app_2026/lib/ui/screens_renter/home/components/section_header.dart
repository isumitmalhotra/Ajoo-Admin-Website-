import 'package:flutter/material.dart';

import 'package:rent_home/ui/design/aajoo_skin.dart';
import 'package:rent_home/utils/fonts.dart';

/// AajooHomes section header — the title on the left, "View all ›" on the
/// right.
///
///   ┌──────────────────────────────────────────────────────┐
///   │  Featured stays                            View all ›│
///   └──────────────────────────────────────────────────────┘
///
/// Shaped after the reference app's `SectionHeader` (lib/widgets/widgets.dart):
/// Poppins 18/w700 title, a Manrope 13/w600 link and a chevron, in the brand
/// colour. It read "See all →" at 22/w500 before, which is the one place the
/// two designs disagreed about the same control.
///
/// `onViewAll` is optional. When it is null the link is hidden — a rail that
/// is the whole of its list has nowhere to lead, and a link that goes nowhere
/// is worse than no link.
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;
  final String viewAllLabel;

  const SectionHeader({
    super.key,
    required this.title,
    this.onViewAll,
    this.viewAllLabel = 'View all',
  });

  @override
  Widget build(BuildContext context) {
    return LuxBuilder(
      builder: (context, skin) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: fraunces(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: skin.ink,
                height: 1.25,
              ),
            ),
          ),
          if (onViewAll != null)
            InkWell(
              onTap: onViewAll,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      viewAllLabel,
                      style: inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: skin.primary,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 17, color: skin.primary),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
