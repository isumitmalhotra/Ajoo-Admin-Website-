import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/ui/design/aajoo_skin.dart';
import 'package:rent_home/utils/lux_mode.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton placeholder for the "Curated for you" 2-col grid while the
/// property list is loading. Mirrors [CuratedCard]'s shape (16:11 photo block
/// + two text lines) so the layout doesn't jump when real data arrives.
///
/// Uses the Sand & Indigo shimmer palette (kLine base, kCream highlight) to
/// match HostHomeShimmer / renter history shimmer.
class CuratedGridShimmer extends StatelessWidget {
  /// How many skeleton cards to show (defaults to the 4 the grid renders).
  final int itemCount;

  const CuratedGridShimmer({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    final skin = AajooSkin.of(LuxMode.instance.isOn);
    return Shimmer.fromColors(
      baseColor: skin.isLux ? const Color(0xFF141416) : kLine,
      highlightColor: skin.isLux ? const Color(0xFF1D1D20) : kCream,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section-header placeholder
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _bar(width: 150, height: 18),
              _bar(width: 52, height: 14),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: itemCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemBuilder: (_, __) => const _CardSkeleton(),
          ),
        ],
      ),
    );
  }

  static Widget _bar({required double width, required double height}) {
    final skin = AajooSkin.of(LuxMode.instance.isOn);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: skin.isLux ? const Color(0xFF141416) : kLine,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    final skin = AajooSkin.of(LuxMode.instance.isOn);
    return Container(
      decoration: BoxDecoration(
        color: skin.isLux ? skin.surface : kSurface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: kSoftShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo block
          AspectRatio(
            aspectRatio: 16 / 11,
            child: Container(
                color: skin.isLux ? const Color(0xFF141416) : kLine),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CuratedGridShimmer._bar(width: 54, height: 8),
                const SizedBox(height: 8),
                CuratedGridShimmer._bar(width: double.infinity, height: 12),
                const SizedBox(height: 8),
                CuratedGridShimmer._bar(width: 40, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
