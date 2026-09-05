/// Cancellation & Refund Policy v1.0 — what the server says about policies.
///
/// Three shapes, all from the same engine that applies the refunds
/// (utils/cancellationPolicy.js on the backend), so what the app prints is
/// what the guest gets. The app used to keep its own map of policy sentences,
/// and two of them — Firm and Strict — described rules the engine never had.
library;

class CancellationPolicyOption {
  const CancellationPolicyOption({
    required this.key,
    required this.label,
    required this.summary,
    required this.rules,
    this.approvalRequired = false,
    this.tone = 'gray',
  });

  final String key;
  final String label;
  final String summary;
  final List<String> rules;
  final bool approvalRequired;

  /// green · amber · orange · red · black — the document's badge colours.
  final String tone;

  factory CancellationPolicyOption.fromJson(Map<String, dynamic> j) =>
      CancellationPolicyOption(
        key: (j['key'] ?? '').toString(),
        label: (j['label'] ?? '').toString(),
        summary: (j['summary'] ?? '').toString(),
        rules: ((j['rules'] as List?) ?? const []).map((e) => e.toString()).toList(),
        approvalRequired: j['approvalRequired'] == true,
        tone: (j['tone'] ?? 'gray').toString(),
      );
}

class RefundStep {
  const RefundStep({required this.percent, this.until});
  final int percent;

  /// The last moment this percentage still applies (UTC). Null on the final
  /// tier — it runs until check-in.
  final DateTime? until;

  factory RefundStep.fromJson(Map<String, dynamic> j) => RefundStep(
        percent: int.tryParse('${j['percent']}') ?? 0,
        until: j['until'] == null ? null : DateTime.tryParse(j['until'].toString()),
      );
}

/// One stay's refund ladder, as dates.
class CancellationSchedule {
  const CancellationSchedule({
    required this.policy,
    required this.label,
    required this.summary,
    required this.rules,
    required this.steps,
    required this.checkInTime,
    this.freeUntil,
    this.manualReview = false,
    this.tone = 'gray',
  });

  final String policy;
  final String label;
  final String summary;
  final List<String> rules;
  final List<RefundStep> steps;
  final String checkInTime;
  final DateTime? freeUntil;
  final bool manualReview;
  final String tone;

  factory CancellationSchedule.fromJson(Map<String, dynamic> j) =>
      CancellationSchedule(
        policy: (j['policy'] ?? '').toString(),
        label: (j['label'] ?? '').toString(),
        summary: (j['summary'] ?? '').toString(),
        rules: ((j['rules'] as List?) ?? const []).map((e) => e.toString()).toList(),
        steps: ((j['steps'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => RefundStep.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        checkInTime: (j['checkInTime'] ?? '14:00').toString(),
        freeUntil: j['freeUntil'] == null ? null : DateTime.tryParse(j['freeUntil'].toString()),
        manualReview: j['manualReview'] == true,
        tone: (j['tone'] ?? 'gray').toString(),
      );
}

class PolicyBlock {
  const PolicyBlock({required this.key, required this.title, required this.summary, required this.rules, this.suitableFor});
  final String key;
  final String title;
  final String summary;
  final List<String> rules;
  final String? suitableFor;

  factory PolicyBlock.fromJson(Map<String, dynamic> j) => PolicyBlock(
        key: (j['key'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        summary: (j['summary'] ?? '').toString(),
        rules: ((j['rules'] as List?) ?? const []).map((e) => e.toString()).toList(),
        suitableFor: j['suitableFor']?.toString(),
      );
}

class PolicySection {
  const PolicySection({required this.id, required this.title, this.paragraphs = const [], this.bullets = const [], this.after = const [], this.policies = const []});
  final String id;
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;
  final List<String> after;
  final List<PolicyBlock> policies;

  factory PolicySection.fromJson(Map<String, dynamic> j) => PolicySection(
        id: (j['id'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        paragraphs: ((j['paragraphs'] as List?) ?? const []).map((e) => e.toString()).toList(),
        bullets: ((j['bullets'] as List?) ?? const []).map((e) => e.toString()).toList(),
        after: ((j['after'] as List?) ?? const []).map((e) => e.toString()).toList(),
        policies: ((j['policies'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => PolicyBlock.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class CancellationPolicyText {
  const CancellationPolicyText({required this.version, required this.title, required this.company, required this.sections});
  final String version;
  final String title;
  final String company;
  final List<PolicySection> sections;

  factory CancellationPolicyText.fromJson(Map<String, dynamic> j) => CancellationPolicyText(
        version: (j['version'] ?? '1.0').toString(),
        title: (j['title'] ?? 'Cancellation & Refund Policy').toString(),
        company: (j['company'] ?? '').toString(),
        sections: ((j['sections'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => PolicySection.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}
