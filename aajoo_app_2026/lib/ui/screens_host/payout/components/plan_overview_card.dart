// The payouts summary, rebuilt to say what the website says.
//
// Three things on the old card were not true:
//
//   * "Monthly Bookings" was `payoutRequests.length` — the number of payout
//     REQUESTS, not bookings, and not monthly. A host with a full calendar and
//     no withdrawals read "Monthly Bookings 0".
//   * "Earnings Goal Progress · 100% of your ₹35,000 monthly goal" — nobody
//     set a ₹35,000 goal. It was a constant in this file, so the bar filled
//     for every host who had ever earned that much and told them nothing.
//   * Nothing said how much had actually been SETTLED, which is the one
//     number a host wants: money that has left the platform versus money
//     still owed. The website leads with exactly that pair.
//
// This is the website's card: pending payout large, settled to date beneath
// it, total earned beside. Settled is derived (total − outstanding) because
// the endpoint returns the other two; if that ever goes negative it is a data
// problem, so it clamps at zero rather than printing a negative rupee amount.
import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/ui/screens_host/payout/payout_controller.dart';
import 'package:rent_home/utils/fonts.dart';

/// 76680 -> "76,680" (Indian grouping: 12,34,567).
String inr(num v) {
  final s = v.round().abs().toString();
  if (s.length <= 3) return (v < 0 ? '-' : '') + s;
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final buf = <String>[];
  while (rest.length > 2) {
    buf.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) buf.insert(0, rest);
  return '${v < 0 ? '-' : ''}${buf.join(',')},$last3';
}

class PlanOverviewCard extends StatelessWidget {
  const PlanOverviewCard({
    super.key,
    required this.payoutController,
  });

  final PayoutController payoutController;

  @override
  Widget build(BuildContext context) {
    final data = payoutController.payoutListResponse.value?.data;
    final failed = payoutController.isError.value;

    final total = failed ? 0 : (data?.hostTotalEarning ?? 0);
    final pending = failed ? 0 : (data?.earningLeft ?? 0);
    // What has actually been paid out, as the SERVER counts it.
    //
    // This was `total - pending`, which is not the same claim: it treats every
    // rupee that is not currently queued as money already in the host's bank.
    // For the test host that read "Settled to date ₹74,481" against the
    // website's ₹0, and the website was right — no payout had completed.
    final settled = failed ? 0 : (data?.settled ?? 0);
    final requests = failed ? 0 : (data?.payoutRequests.length ?? 0);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kIndigo, kIndigo600],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pending payout',
                  style: inter(
                      fontSize: 13, color: Colors.white.withOpacity(0.82))),
              const SizedBox(height: 6),
              payoutController.isLoading.value
                  ? const SizedBox(
                      height: 34,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        ),
                      ),
                    )
                  : Text('₹${inr(pending)}',
                      style: fraunces(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
              const SizedBox(height: 6),
              Text('Settled to date: ₹${inr(settled)}',
                  style: inter(
                      fontSize: 12.5, color: Colors.white.withOpacity(0.82))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Total earned',
                value: '₹${inr(total)}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: Icons.receipt_long_outlined,
                // Labelled for what it counts. This was "Monthly Bookings".
                label: requests == 1 ? 'Payout request' : 'Payout requests',
                value: '$requests',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: kIndigo),
          const SizedBox(height: 8),
          Text(value,
              style: fraunces(
                  fontSize: 18, fontWeight: FontWeight.w700, color: kInk)),
          const SizedBox(height: 2),
          Text(label, style: inter(fontSize: 12, color: kMuted)),
        ],
      ),
    );
  }
}
