import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/utils/fonts.dart';

/// AajooHomes branded header — matches the POC mobile header.
///
/// Layout (left → right):
///   [ 34×34 indigo-gradient logo mark "A" ]  [ "aajoo`homes`" wordmark ]   ...spacer...   [ 🤍 heart ]  [ 👤 profile ]
///
/// All actions are exposed via callbacks; this widget owns no state.
class BrandedHeader extends StatelessWidget {
  final VoidCallback? onMenuTap; // also doubles as logo tap (open drawer)
  final VoidCallback? onWishlistTap;
  final VoidCallback? onProfileTap;

  const BrandedHeader({
    super.key,
    this.onMenuTap,
    this.onWishlistTap,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          // Logo mark + wordmark — tapping opens the drawer.
          InkWell(
            onTap: onMenuTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LogoMark(),
                  const SizedBox(width: 10),
                  // "aajoo" (indigo) + "homes" (clay italic) — POC pairing.
                  RichText(
                    text: TextSpan(
                      style: fraunces(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: kInk,
                      ),
                      children: [
                        const TextSpan(text: 'aajoo'),
                        TextSpan(
                          text: 'homes',
                          style: fraunces(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.italic,
                            color: kClay,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          _HeaderIconButton(
            icon: Icons.favorite_outline,
            onTap: onWishlistTap,
            tooltip: 'Wishlist',
          ),
          const SizedBox(width: 8),
          _HeaderIconButton(
            icon: Icons.person_outline,
            onTap: onProfileTap,
            tooltip: 'Profile',
          ),
        ],
      ),
    );
  }
}

/// 34×34 indigo-gradient square with "A" — matches POC exactly.
class _LogoMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kIndigo, kIndigo600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: kInk.withOpacity(0.18),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'A',
          style: fraunces(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: kCream,
            letterSpacing: -0.04,
          ),
        ),
      ),
    );
  }
}

/// Cream circle button used in the header (heart, profile).
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;

  const _HeaderIconButton({
    required this.icon,
    this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: kCream,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kLine),
          ),
          child: Icon(icon, color: kInk, size: 20),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: child);
    }
    return child;
  }
}
