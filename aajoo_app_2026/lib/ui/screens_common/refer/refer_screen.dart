import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'package:rent_home/constants.dart';
import 'package:rent_home/service/growth_service.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/utils/money.dart';

/// Refer & Earn — the mobile counterpart of the web's /account/refer and
/// /host/refer.
///
/// One screen for both sides, because it is one endpoint:
/// GET /user/referrals/summary answers for a guest and a host alike, and the
/// website reaches it from both places. The app had no route to it at all, so a
/// referral code the backend had been minting since signup was unreachable from
/// the phone.
class ReferScreen extends StatefulWidget {
  const ReferScreen({super.key, this.isHost = false});

  /// Only changes the wording — the data and the reward are the same.
  final bool isHost;

  @override
  State<ReferScreen> createState() => _ReferScreenState();
}

class _ReferScreenState extends State<ReferScreen> {
  ReferralSummary? _s;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await GrowthService.instance.referrals();
    if (!mounted) return;
    setState(() {
      _s = s;
      _loading = false;
    });
  }

  void _copy(String value, String what) {
    Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('$what copied'),
        backgroundColor: kInk,
        behavior: SnackBarBehavior.floating,
      ));
  }

  Future<void> _share() async {
    final s = _s;
    if (s == null || s.link.isEmpty) return;
    final who = widget.isHost ? 'list your place' : 'find a place to stay';
    await Share.share(
      "I'm using Aajoo Homes — you can negotiate the price directly with the "
      "host. Use my code ${s.code} when you sign up and we both get "
      "${rupees(s.rewardPerReferral)} to spend.\n\n"
      "Join and $who: ${s.link}",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSand,
      appBar: AppBar(
        backgroundColor: kSand,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: kInk,
        titleSpacing: 0,
        title: Text('Refer & Earn',
            style:
                fraunces(fontSize: 20, fontWeight: FontWeight.w700, color: kInk)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _s == null
              ? _unavailable()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                    children: [
                      _hero(_s!),
                      const SizedBox(height: 16),
                      _codeCard(_s!),
                      const SizedBox(height: 16),
                      _stats(_s!),
                      const SizedBox(height: 16),
                      _howItWorks(_s!),
                    ],
                  ),
                ),
    );
  }

  Widget _unavailable() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.card_giftcard_outlined, size: 48, color: kMuted),
              const SizedBox(height: 12),
              Text("Couldn't load your referrals",
                  style: fraunces(
                      fontSize: 17, fontWeight: FontWeight.w600, color: kInk)),
              const SizedBox(height: 6),
              Text('Check your connection and pull down to try again.',
                  textAlign: TextAlign.center,
                  style: inter(fontSize: 13.5, color: kMuted, height: 1.5)),
              const SizedBox(height: 14),
              OutlinedButton(onPressed: _load, child: const Text('Try again')),
            ],
          ),
        ),
      );

  Widget _hero(ReferralSummary s) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [kIndigo, Color(0xFF3B3F7A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('GIVE ${rupees(s.rewardPerReferral)}, GET ${rupees(s.rewardPerReferral)}',
                style: inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: kCream.withOpacity(0.75),
                    letterSpacing: 1.4)),
            const SizedBox(height: 8),
            Text(
              widget.isHost
                  ? 'Know someone with a place to list?'
                  : 'Know someone who travels?',
              style: fraunces(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: kCream,
                  height: 1.25),
            ),
            const SizedBox(height: 6),
            Text(
              'They get ${rupees(s.rewardPerReferral)} off their first stay, and '
              'you get ${rupees(s.rewardPerReferral)} in your wallet once they book.',
              style: inter(
                  fontSize: 13, color: kCream.withOpacity(0.9), height: 1.5),
            ),
          ],
        ),
      );

  Widget _codeCard(ReferralSummary s) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kLine),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('YOUR CODE',
                style: inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: kMuted,
                    letterSpacing: 1.2)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: kCream,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kLine),
                    ),
                    child: Text(
                      s.code.isEmpty ? '—' : s.code,
                      style: fraunces(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: kInk,
                          letterSpacing: 2),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed:
                      s.code.isEmpty ? null : () => _copy(s.code, 'Code'),
                  style: IconButton.styleFrom(
                      backgroundColor: kIndigo50, foregroundColor: kIndigo),
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  tooltip: 'Copy code',
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: s.link.isEmpty ? null : _share,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kIndigo,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.ios_share_rounded, size: 18),
                label: Text('Share your invite',
                    style:
                        inter(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            if (s.link.isNotEmpty) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _copy(s.link, 'Link'),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.link_rounded, size: 16, color: kMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(s.link,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: inter(fontSize: 12.5, color: kMuted)),
                      ),
                      Text('Copy',
                          style: inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: kIndigo)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );

  Widget _stats(ReferralSummary s) => Row(
        children: [
          _stat('Invited', '${s.totalReferrals}', kIndigo50, kIndigo),
          const SizedBox(width: 10),
          _stat('Joined', '${s.converted}', const Color(0xFFEAF6EE), kSuccess),
          const SizedBox(width: 10),
          _stat('Earned', rupees(s.rewardsEarned), const Color(0xFFFFF6E5), kClay),
        ],
      );

  Widget _stat(String label, String value, Color bg, Color fg) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: fraunces(
                      fontSize: 18, fontWeight: FontWeight.w700, color: fg)),
              const SizedBox(height: 2),
              Text(label,
                  style: inter(fontSize: 11.5, color: kMuted)),
            ],
          ),
        ),
      );

  Widget _howItWorks(ReferralSummary s) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kLine),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How it works',
                style: fraunces(
                    fontSize: 16, fontWeight: FontWeight.w700, color: kInk)),
            const SizedBox(height: 12),
            _step(1, 'Share your code',
                'Send it to anyone who has not used Aajoo before.'),
            _step(2, 'They sign up with it',
                'The code goes in at registration — it cannot be added later.'),
            _step(
                3,
                'You both get ${rupees(s.rewardPerReferral)}',
                'Yours lands in your wallet once their first stay is confirmed.'),
            if (s.pending > 0) ...[
              const SizedBox(height: 6),
              Text(
                '${s.pending} ${s.pending == 1 ? 'invite is' : 'invites are'} '
                'waiting on a first booking.',
                style: inter(fontSize: 12.5, color: kMuted, height: 1.4),
              ),
            ],
          ],
        ),
      );

  Widget _step(int n, String title, String body) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                  color: kIndigo50, shape: BoxShape.circle),
              child: Text('$n',
                  style: inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: kIndigo)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: kInk)),
                  const SizedBox(height: 2),
                  Text(body,
                      style:
                          inter(fontSize: 12.5, color: kMuted, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      );
}
