import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/ui/design/aajoo_skin.dart';
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

  /// Unread notifications, shown on the bell.
  ///
  /// The bell was silent: it opened the list and gave no sign there was
  /// anything in it, so a guest had no reason to tap it and no way to know
  /// they had been told something. Passed in rather than read from the
  /// controller here, so this widget stays state-free and the number has one
  /// owner.
  final int unreadCount;

  const BrandedHeader({
    super.key,
    this.onWishlistTap,
    this.onNotificationsTap,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return LuxBuilder(builder: (context, skin) => Padding(
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
                const _LogoMark(),
                const SizedBox(width: 10),
                // "aajoo" + "homes" italic. Both take the skin — the wordmark
                // sat in Charcoal Navy over the LUX header, which is nearly
                // the header's own colour and read as a smudge.
                RichText(
                  text: TextSpan(
                    style: fraunces(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: skin.ink,
                    ),
                    children: [
                      const TextSpan(text: 'aajoo'),
                      TextSpan(
                        text: 'homes',
                        style: fraunces(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.italic,
                          color: skin.accent,
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
            skin: skin,
          ),
          const SizedBox(width: 8),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _HeaderIconButton(
                icon: unreadCount > 0
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_none,
                onTap: onNotificationsTap,
                tooltip: unreadCount > 0
                    ? '$unreadCount unread notification${unreadCount == 1 ? '' : 's'}'
                    : 'Notifications',
                skin: skin,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    height: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(9),
                      // A ring in the header's own colour, so the badge reads
                      // as sitting on the bell rather than behind it.
                      border: Border.all(color: skin.surface, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ));
  }
}

/// 34×34 indigo-gradient square with "A" — matches POC exactly.
class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return LuxBuilder(builder: (context, skin) => Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: skin.isLux
              ? const [Color(0xFFD4AF37), Color(0xFFB8860B)]
              : const [kIndigo, kIndigo600],
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
            color: skin.isLux ? skin.onPrimary : kCream,
            letterSpacing: -0.04,
          ),
        ),
      ),
    ));
  }
}

/// Cream circle button used in the header (heart, profile).
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final AajooSkin skin;

  const _HeaderIconButton({
    required this.icon,
    required this.skin,
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
            color: skin.isLux ? skin.surface : kCream,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: skin.line),
          ),
          child: Icon(icon, color: skin.ink, size: 20),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: child);
    }
    return child;
  }
}
