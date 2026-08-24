import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/service/host_service.dart';
import 'package:rent_home/ui/screens_host/earnings/host_statements_screen.dart';
import 'package:rent_home/ui/screens_host/payout/payout_page.dart';
import 'package:rent_home/utils/fonts.dart';

/// What a host has earned — the same figures, from the same endpoint, as the
/// web Earnings page.
///
/// The app had no earnings screen at all. The home card summed
/// /host/transaction-history in the client, which answers a different question
/// (payments received against this host) with a different number, and there
/// was nowhere to see settled vs pending payouts or what is still awaiting
/// collection. This reads /host/earnings/summary, so the two platforms cannot
/// disagree about what a host is owed.
class HostEarningsScreen extends StatefulWidget {
  const HostEarningsScreen({super.key});

  @override
  State<HostEarningsScreen> createState() => _HostEarningsScreenState();
}

class _HostEarningsScreenState extends State<HostEarningsScreen> {
  final HostService _service = HostService();
  final RxBool loading = true.obs;
  final Rx<Map<String, dynamic>> data = Rx<Map<String, dynamic>>({});

  @override
  void initState() {
    super.initState();
    // After the first frame — flipping an observable during build throws
    // "setState() called during build" and leaves the screen spinning.
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    loading.value = true;
    try {
      data.value = await _service.getEarningsSummary();
    } finally {
      loading.value = false;
    }
  }

  static double _n(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('${v ?? ''}') ?? 0;
  }

  static String _inr(num v) {
    final s = v.round().toString();
    if (s.length <= 3) return '₹$s';
    final head = s.substring(0, s.length - 3);
    final tail = s.substring(s.length - 3);
    final buf = StringBuffer();
    for (var i = 0; i < head.length; i++) {
      final fromEnd = head.length - i;
      buf.write(head[i]);
      if (fromEnd > 1 && fromEnd.isOdd) buf.write(',');
    }
    return '₹$buf,$tail';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSand,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
        title: Text('Earnings',
            style:
                inter(fontSize: 17, fontWeight: FontWeight.w700, color: kInk)),
      ),
      body: Obx(() {
        if (loading.value && data.value.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final d = data.value;
        final expected = _n(d['expectedEarnings']);
        final expectedCount = _n(d['expectedCount']).round();
        final history = (d['payoutHistory'] is List)
            ? List<Map<String, dynamic>>.from(
                (d['payoutHistory'] as List).whereType<Map>().map(
                    (e) => Map<String, dynamic>.from(e)))
            : <Map<String, dynamic>>[];

        return RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
            children: [
              Text('Track your revenue and payouts',
                  style: inter(fontSize: 13, color: kMuted)),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                    child: _tile('Total Earnings',
                        _inr(_n(d['totalEarnings'])), kIndigo50, kIndigo)),
                const SizedBox(width: 10),
                Expanded(
                    child: _tile('Settled Payouts',
                        _inr(_n(d['settledPayouts'])), const Color(0xFFEAF6EE), kSuccess)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: _tile('Pending Payouts',
                        _inr(_n(d['pendingPayouts'])), const Color(0xFFFFF6E5), kClay)),
                const SizedBox(width: 10),
                Expanded(
                    child: _tile('Last Payout',
                        _inr(_n(d['lastPayoutAmount'])), const Color(0xFFEEEDFE), const Color(0xFF7C3AED))),
              ]),

              // Pay-at-property money the platform has not received yet. Every
              // figure above counts COLLECTED money only, so a host with a
              // confirmed pay-at-property stay would otherwise see ₹0
              // everywhere with nothing explaining why. Deliberately outside
              // the totals — it is not revenue until the cash is in.
              if (expected > 0) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kLine),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.schedule_rounded, size: 18, color: kClay),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_inr(expected)} awaiting collection',
                                style: inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: kInk)),
                            const SizedBox(height: 3),
                            Text(
                              'Your share of ${expectedCount == 1 ? 'a stay' : '$expectedCount stays'} being paid at the property. '
                              "It isn't counted as earnings until the money reaches the platform, and no payout is scheduled against it.",
                              style: inter(
                                  fontSize: 12.5, color: kMuted, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 18),
              Text('Payout History',
                  style: inter(
                      fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
              const SizedBox(height: 8),
              if (history.isEmpty)
                Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kLine),
                  ),
                  child: Center(
                    child: Text(
                      'No payouts yet. Earnings settle after completed stays.',
                      textAlign: TextAlign.center,
                      style: inter(fontSize: 13, color: kMuted),
                    ),
                  ),
                )
              else
                ...history.map((p) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: kLine),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_inr(_n(p['amount'])),
                                    style: inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: kInk)),
                                const SizedBox(height: 2),
                                Text('${p['reference_id'] ?? '-'}',
                                    style:
                                        inter(fontSize: 12, color: kMuted)),
                                // Why a failed payout failed. "FAILED" on its
                                // own tells a host nothing about whether to
                                // fix their bank details or simply wait.
                                if ((p['failure_reason'] ?? '')
                                    .toString()
                                    .trim()
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    p['failure_reason'].toString(),
                                    style: inter(
                                        fontSize: 12,
                                        color: kDanger,
                                        height: 1.35),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Text('${p['status'] ?? ''}',
                              style: inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  // A failure should not read in the same
                                  // neutral grey as "QUEUED".
                                  color: '${p['status'] ?? ''}'.toUpperCase() ==
                                          'FAILED'
                                      ? kDanger
                                      : kInk2)),
                        ],
                      ),
                    )),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Get.to(() => const HostStatementsScreen()),
                  icon: const Icon(Icons.receipt_long_outlined, size: 18),
                  label: Text('Monthly statements',
                      style:
                          inter(fontSize: 14, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kIndigo,
                    side: const BorderSide(color: kIndigo),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Get.to(() => const PayoutPage()),
                  icon: const Icon(Icons.account_balance_outlined, size: 18),
                  label: Text('Manage payouts',
                      style:
                          inter(fontSize: 14, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kIndigo,
                    side: const BorderSide(color: kIndigo),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _tile(String label, String value, Color bg, Color fg) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kLine),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(9)),
              child: Icon(Icons.currency_rupee_rounded, size: 15, color: fg),
            ),
            const SizedBox(height: 9),
            Text(value,
                style: inter(
                    fontSize: 18, fontWeight: FontWeight.w700, color: kInk)),
            const SizedBox(height: 2),
            Text(label, style: inter(fontSize: 11.5, color: kMuted)),
          ],
        ),
      );
}
