import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/models/cancellation_policy.dart';
import 'package:rent_home/service/cancellation_policy_service.dart';
import 'package:rent_home/ui/widgets/load_failed.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/utils/service_log.dart';

/// Cancellation & Refund Policy v1.0 — the full text, from the server, so the
/// app and the website read the same words. Linked from the listing's
/// "Things to know", the reserve sheet, Settings and the host menu.
class CancellationPolicyPage extends StatefulWidget {
  const CancellationPolicyPage({super.key, this.scrollToPolicy});

  /// A policy key to draw attention to, e.g. the listing the guest came from.
  final String? scrollToPolicy;

  @override
  State<CancellationPolicyPage> createState() => _CancellationPolicyPageState();
}

class _CancellationPolicyPageState extends State<CancellationPolicyPage> {
  CancellationPolicyText? _doc;
  bool _loading = true;

  static const _tone = <String, Color>{
    'green': Color(0xFF15803D),
    'amber': Color(0xFFB45309),
    'orange': Color(0xFFC2410C),
    'red': Color(0xFFB91C1C),
    'black': Color(0xFF111827),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await CancellationPolicyService.instance.text();
    if (!mounted) return;
    setState(() {
      _doc = d;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSand,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Cancellation & Refunds'),
        backgroundColor: kSand,
        foregroundColor: kInk,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kprimaryColor))
          : _doc == null
              ? LoadFailed(
                  title: "Couldn't load the policy",
                  message: ServiceErrors.lastFor('cancellationPolicyText') ??
                      'Something went wrong loading this. Try again.',
                  onRetry: () async {
                    setState(() => _loading = true);
                    await _load();
                  },
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    Text('${_doc!.company} · Version ${_doc!.version}',
                        style: inter(fontSize: 12.5, color: kMuted)),
                    const SizedBox(height: 6),
                    Text(
                      'The policy a host selects is shown before you book and becomes part of your booking agreement.',
                      style: inter(fontSize: 13.5, color: kInk2, height: 1.5),
                    ),
                    for (final s in _doc!.sections) _section(s),
                  ],
                ),
    );
  }

  Widget _section(PolicySection s) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.title, style: inter(fontSize: 15.5, fontWeight: FontWeight.w700, color: kInk)),
          for (final p in s.paragraphs) ...[
            const SizedBox(height: 8),
            Text(p, style: inter(fontSize: 13.5, color: kInk2, height: 1.55)),
          ],
          for (final b in s.bullets) _bullet(b),
          for (final p in s.after) ...[
            const SizedBox(height: 8),
            Text(p, style: inter(fontSize: 13.5, color: kInk2, height: 1.55)),
          ],
          for (final p in s.policies) _policy(p),
        ],
      ),
    );
  }

  Widget _bullet(String text) => Padding(
        padding: const EdgeInsets.only(top: 6, left: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('•  ', style: inter(fontSize: 13.5, color: kInk2)),
            Expanded(child: Text(text, style: inter(fontSize: 13.5, color: kInk2, height: 1.5))),
          ],
        ),
      );

  Widget _policy(PolicyBlock p) {
    final highlight = widget.scrollToPolicy != null && widget.scrollToPolicy == p.key;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFF0FDF4) : kSand,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: highlight ? kprimaryColor : kLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p.title,
              style: inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: _tone[_toneFor(p.key)] ?? kInk)),
          const SizedBox(height: 4),
          Text(p.summary, style: inter(fontSize: 13, color: kMuted, height: 1.45)),
          for (final r in p.rules) _bullet(r),
          if (p.suitableFor != null) ...[
            const SizedBox(height: 8),
            Text('Suitable for: ${p.suitableFor}', style: inter(fontSize: 12, color: kMuted)),
          ],
        ],
      ),
    );
  }

  static String _toneFor(String key) => const {
        'flexible': 'green',
        'moderate': 'amber',
        'firm': 'orange',
        'strict': 'red',
        'super_strict': 'black',
      }[key] ?? 'gray';
}
