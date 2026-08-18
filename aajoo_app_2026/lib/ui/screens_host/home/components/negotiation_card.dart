import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/models/host_negotiation.dart';
import 'package:rent_home/utils/fonts.dart';

/// One negotiation, as the host sees it (A-70).
///
/// Leads with what the host has to decide: who, on which property, how much
/// below asking, and for which nights. The offer price is the loudest thing on
/// the card because it is the only number the host is being asked about.
class NegotiationCard extends StatelessWidget {
  final HostNegotiation n;
  final VoidCallback? onTap;

  /// The host's decision, taken ON the card: 'accept' | 'decline' | 'counter'.
  /// The buttons render only while the offer is pending AND a handler is
  /// given — the dashboard's compact list passes none and stays read-only.
  /// The card was pure display before this, which meant the app could SHOW
  /// offers but the host had no way to answer one anywhere in the app.
  final Future<void> Function(String action)? onRespond;

  const NegotiationCard({super.key, required this.n, this.onTap, this.onRespond});

  static String _money(double v) {
    final s = v.round().toString();
    final buf = StringBuffer();
    final len = s.length;
    for (int i = 0; i < len; i++) {
      buf.write(s[i]);
      final remaining = len - i - 1;
      if (remaining > 0 &&
          (remaining == 3 || (remaining > 3 && (remaining - 3) % 2 == 0))) {
        buf.write(',');
      }
    }
    return buf.toString();
  }

  (Color, Color, String) get _status {
    switch (n.status.toLowerCase()) {
      case 'accepted':
        return (const Color(0xFFEAF6EE), kSuccess, 'Accepted');
      case 'declined':
      case 'rejected':
        return (const Color(0xFFFDECEC), kDanger, 'Declined');
      case 'countered':
        return (const Color(0xFFEFF3F8), kInk2, 'Countered');
      default:
        return (const Color(0xFFFFF1E6), kClay, 'Awaiting you');
    }
  }

  @override
  Widget build(BuildContext context) {
    final (badgeBg, badgeFg, badgeText) = _status;
    final off = n.discountPercent;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: n.isPending ? kClay : kLine),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(n.propertyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: fraunces(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: kInk)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(badgeText,
                      style: inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: badgeFg)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('${n.renterName} offered',
                style: inter(fontSize: 12.5, color: kMuted)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('₹${_money(n.offerPrice)}',
                    style: fraunces(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: kInk)),
                const SizedBox(width: 8),
                if (n.originalPrice > 0)
                  Text('was ₹${_money(n.originalPrice)}',
                      style: inter(fontSize: 12.5, color: kMuted).copyWith(
                          decoration: TextDecoration.lineThrough)),
                const Spacer(),
                // Only where there is a real asking price to compare against —
                // a "0% off" on a listing with no price reads as full price.
                if (off != null && off > 0)
                  Text('${off.round()}% below',
                      style: inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: kClay)),
              ],
            ),
            if (n.bookFrom != null && n.bookTo != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 14, color: kMuted),
                  const SizedBox(width: 6),
                  Text('${n.bookFrom} → ${n.bookTo}',
                      style: inter(fontSize: 12.5, color: kInk2)),
                ],
              ),
            ],
            if (n.message.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kSand,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(n.message.trim(),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: inter(fontSize: 12.5, color: kInk2, height: 1.5)),
              ),
            ],
            if (onRespond != null && n.isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _action(
                      label: 'Accept',
                      icon: Icons.check_rounded,
                      filled: true,
                      color: kSuccess,
                      onTap: () => onRespond!('accept'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _action(
                      label: 'Counter',
                      icon: Icons.swap_horiz_rounded,
                      filled: false,
                      color: kIndigo,
                      onTap: () => onRespond!('counter'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _action(
                      label: 'Decline',
                      icon: Icons.close_rounded,
                      filled: false,
                      color: kDanger,
                      onTap: () => onRespond!('decline'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _action({
    required String label,
    required IconData icon,
    required bool filled,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? color : Colors.transparent,
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: filled ? Colors.white : color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: filled ? Colors.white : color)),
            ),
          ],
        ),
      ),
    );
  }
}
