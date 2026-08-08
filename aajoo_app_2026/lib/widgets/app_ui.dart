// Shared UI kit — the modern Sand & Indigo building blocks used across the app
// so every screen looks consistent. Prefer these over ad-hoc Containers/Text.
import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/utils/fonts.dart';

/// Inserts a subtle, INSET hairline between each row (aligned past the icon
/// chip, not edge-to-edge) — the refined iOS/Stripe-style separation.
/// `Column(children: withDividers([...]))`.
List<Widget> withDividers(List<Widget> rows) {
  final out = <Widget>[];
  for (var i = 0; i < rows.length; i++) {
    out.add(rows[i]);
    if (i != rows.length - 1) {
      out.add(Divider(
          height: 1, thickness: 1, indent: 48, color: kLine.withOpacity(0.7)));
    }
  }
  return out;
}

/// Elevated white surface (soft shadow) used to group a section's content.
/// White lifts it off the cream background — the core premium depth.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? kSurface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: kCardShadow,
        ),
        child: child,
      );
}

/// Bold section heading (Fraunces display serif for a premium feel).
class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: fraunces(fontSize: 16.5, fontWeight: FontWeight.w700, color: kInk),
      );
}

/// Big number/label stat tile (e.g. a price).
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  const StatTile(
      {super.key,
      required this.label,
      required this.value,
      this.valueColor = kIndigo});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: kCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: kMuted)),
            const SizedBox(height: 6),
            Text(value,
                style: fraunces(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: valueColor)),
          ],
        ),
      );
}

/// Icon-chip + label + right-aligned value row (premium list style).
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const InfoRow(this.icon, this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: kIndigo.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: kIndigo),
            ),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 13, color: kMuted)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: kInk)),
            ),
          ],
        ),
      );
}

/// Label — value row (no icon).
class KvRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const KvRow(this.label, this.value, {super.key, this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(label,
                  style: const TextStyle(fontSize: 13.5, color: kInk2)),
            ),
            const SizedBox(width: 12),
            Text(value,
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? kInk)),
          ],
        ),
      );
}

/// Small status/label pill. `solid` fills with the colour (for badges over images).
class AppPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool solid;
  const AppPill(this.label, this.color,
      {super.key, this.icon, this.solid = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: solid ? color : color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: solid ? Colors.white : color),
            const SizedBox(width: 5),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: solid ? Colors.white : color)),
        ]),
      );
}

/// Rounded icon + label chip for highlights/facts.
class FactChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const FactChip(this.icon, this.label, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: kSand,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: kIndigo),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w600, color: kInk)),
        ]),
      );
}

/// Empty-state block (icon + title + optional subtitle) for lists with no data.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  const EmptyState(
      {super.key, required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: kCardShadow,
        ),
        child: Column(children: [
          Icon(icon, size: 42, color: kMuted),
          const SizedBox(height: 10),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: kMuted)),
          ],
        ]),
      );
}

/// Full-width primary (filled) button.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  const PrimaryButton(
      {super.key,
      required this.label,
      this.onPressed,
      this.icon,
      this.loading = false});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: loading ? null : onPressed,
          icon: icon == null || loading
              ? const SizedBox.shrink()
              : Icon(icon, size: 18),
          style: ElevatedButton.styleFrom(
            backgroundColor: kprimaryColor,
            foregroundColor: kcontentColor,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          label: loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: kcontentColor))
              : Text(label,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      );
}
