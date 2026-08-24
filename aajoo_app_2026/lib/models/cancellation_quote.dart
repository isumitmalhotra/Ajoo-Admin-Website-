/// What a guest gets back if they cancel — read BEFORE the cancel, not after.
///
/// The web has always shown this ahead of the confirm dialog; the app went
/// straight from "Cancel booking" to cancelling, so a guest gave up a stay
/// without being told what they would be refunded. That is the kind of gap
/// that turns into a dispute rather than a bug report.
class CancellationQuote {
  const CancellationQuote({
    required this.canCancel,
    this.reason,
    this.policyLabel,
    this.policySummary,
    this.refundPercent = 0,
    this.refundAmount = 0,
    this.refundNote,
    this.manualReview = false,
    this.isPaid = false,
  });

  /// False when the stay has checked in, completed, or is past cancelling.
  final bool canCancel;

  /// Why not, when [canCancel] is false — shown verbatim.
  final String? reason;

  final String? policyLabel;
  final String? policySummary;
  final int refundPercent;
  final double refundAmount;
  final String? refundNote;

  /// The refund needs a human decision; do not promise a figure.
  final bool manualReview;

  /// An unpaid (pay-at-property) booking has nothing to refund.
  final bool isPaid;

  static String? _s(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  factory CancellationQuote.fromJson(Map<String, dynamic> j) =>
      CancellationQuote(
        // Default TRUE only when the server said so; anything unparseable
        // should not silently unlock a cancel.
        canCancel: j['canCancel'] == true,
        reason: _s(j['reason']),
        policyLabel: _s(j['policyLabel']),
        policySummary: _s(j['policySummary']),
        refundPercent: (j['refundPercent'] as num?)?.toInt() ?? 0,
        refundAmount: (j['refundAmount'] as num?)?.toDouble() ??
            double.tryParse(_s(j['refundAmount']) ?? '') ??
            0,
        refundNote: _s(j['refundNote']),
        manualReview: j['manualReview'] == true,
        isPaid: j['isPaid'] == true,
      );
}
