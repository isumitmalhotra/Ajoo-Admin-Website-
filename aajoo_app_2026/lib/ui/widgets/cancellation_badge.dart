import 'package:flutter/material.dart';
import 'package:rent_home/utils/fonts.dart';

/// The card badge from the policy document: 🟢 Flexible · 🟡 Moderate ·
/// 🟠 Firm · 🔴 Strict. A guest comparing two stays should not have to open
/// each to learn what cancelling would cost.
class CancellationBadge extends StatelessWidget {
  const CancellationBadge(this.policyKey, {super.key, this.compact = false});

  final String? policyKey;
  final bool compact;

  static const _spec = <String, (String, Color, Color)>{
    'flexible': ('Flexible cancellation', Color(0xFF15803D), Color(0xFFECFDF5)),
    'moderate': ('Moderate cancellation', Color(0xFFB45309), Color(0xFFFFFBEB)),
    'firm': ('Firm cancellation', Color(0xFFC2410C), Color(0xFFFFF7ED)),
    'strict': ('Strict cancellation', Color(0xFFB91C1C), Color(0xFFFEF2F2)),
    'super_strict': ('Special cancellation terms', Color(0xFF111827), Color(0xFFF3F4F6)),
  };

  /// True when there is something to draw — lets a caller skip its spacer.
  static bool has(String? key) => key != null && _spec.containsKey(key.trim().toLowerCase());

  @override
  Widget build(BuildContext context) {
    final spec = _spec[(policyKey ?? '').trim().toLowerCase()];
    if (spec == null) return const SizedBox.shrink();
    final (label, fg, bg) = spec;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: compact ? 2 : 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: inter(fontSize: compact ? 10 : 10.5, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}
