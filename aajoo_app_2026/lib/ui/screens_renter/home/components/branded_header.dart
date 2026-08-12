import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/utils/fonts.dart';

/// AajooHomes branded header — matches the POC mobile header.
///
/// Layout (left → right):
///   [ 34×34 indigo-gradient logo mark "A" ]  [ "aajoo`homes`" wordmark ]   ...spacer...   [ 🤍 heart ]  [ 🔔 notifications ]
///
/// All actions are exposed via callbacks; this widget owns no state.
class BrandedHeader extends StatelessWidget {
  final VoidCallback? onWishlistTap;
  /// Opens notifications. Was named onProfileTap and paired with a person
  /// icon, while the handler behind it pushed NotificationsScreen — the icon
  /// said "profile", the tooltip said "Profile", and the tap did neither.
  final VoidCallback? onNotificationsTap;

  const BrandedHeader({
    super.key,
    this.onWishlistTap,
    this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          // Branding, and only branding. This used to be the app's menu
          // button — an unlabelled logo that opened a drawer (A-64). Nothing
          // said it was tappable, so the pages behind it were effectively
          // hidden; they are on the profile tab now.
          Padding(
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
          const Spacer(),
          _HeaderIconButton(
            icon: Icons.favorite_outline,
            onTap: onWishlistTap,
            tooltip: 'Wishlist',
          ),
          const SizedBox(width: 8),
          _HeaderIconButton(
            icon: Icons.notifications_none,
            onTap: onNotificationsTap,
            tooltip: 'Notifications',
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
