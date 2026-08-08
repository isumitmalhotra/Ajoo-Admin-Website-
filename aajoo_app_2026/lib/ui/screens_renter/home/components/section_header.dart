import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/utils/fonts.dart';

/// AajooHomes section header — Fraunces title on the left, "See all →" on
/// the right.
///
///   ┌──────────────────────────────────────────────────────┐
///   │  Curated for you                            See all →│
///   └──────────────────────────────────────────────────────┘
///
/// `onSeeAll` is optional. If null, the link is hidden.
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  final String seeAllLabel;

  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
    this.seeAllLabel = 'See all',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(
            title,
            style: fraunces(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: kInk,
              height: 1.2,
            ),
          ),
        ),
        if (onSeeAll != null)
          InkWell(
            onTap: onSeeAll,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    seeAllLabel,
                    style: inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kIndigo,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: kIndigo,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
