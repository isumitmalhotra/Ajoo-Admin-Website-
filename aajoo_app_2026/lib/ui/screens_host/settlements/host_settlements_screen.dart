import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'package:rent_home/constants.dart';
import 'package:rent_home/constants/payment_config.dart';
import 'package:rent_home/service/host_dues_service.dart';
import 'package:rent_home/ui/screens_common/auth/auth_controller.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/utils/money.dart';
import 'package:rent_home/utils/rzp_error.dart';

/// Settlements — the mobile counterpart of the web's /host/settlements.
///
/// On a pay-at-property booking the guest hands the whole amount to the host,
/// so Aajoo's share has to come back the other way. Dues have been raised
/// against those bookings since the settlement engine shipped; without this
/// screen a host who works from their phone would have met the charge for the
/// first time as a smaller payout.
///
/// Two things it has to do beyond showing a number. Show the working, because
/// "you owe ₹6,099" against cash a host already holds is not checkable. And
/// say what they keep — the same rupees an online booking of that value would
/// have left them — because the fear this screen invites is that taking cash
/// costs them more.
class HostSettlementsScreen extends StatefulWidget {
  const HostSettlementsScreen({super.key});

  @override
  State<HostSettlementsScreen> createState() => _HostSettlementsScreenState();
}

class _HostSettlementsScreenState extends State<HostSettlementsScreen> {
  late final Razorpay _razorpay;

  HostDues? _dues;
  bool _loading = true;
  bool _paying = false;

  /// A failed request and "nothing owed" look identical on screen, and only
  /// one of them is good news. Kept apart deliberately.
  bool _failed = false;

  /// Which stay is opened up. Only one at a time — the breakdown is six lines.
  int? _open;

  /// What the current checkout is settling. Held so verify closes exactly the
  /// dues that were charged, not whatever is outstanding by the time the
  /// gateway calls back.
  List<int> _settling = const [];

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaid)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _onFailed);
    _load();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _load() async {
    final d = await HostDuesService.instance.load();
    if (!mounted) return;
    setState(() {
      _dues = d;
      _failed = d == null;
      _loading = false;
    });
  }

  Future<void> _pay() async {
    final owed = _dues?.payableNow ?? 0;
    if (owed <= 0) return;

    setState(() => _paying = true);
    final order = await HostDuesService.instance.startPayment();
    if (!mounted) return;

    if (!order.ok) {
      setState(() => _paying = false);
      _say('Could not start the payment', order.error ?? 'Please try again.');
      return;
    }

    // A release build carrying a TEST key takes no money while looking exactly
    // as if it did (W8 · P0-02). Refuse rather than record a settlement nobody
    // paid for.
    if (!PaymentConfig.usableForPayments) {
      setState(() => _paying = false);
      Fluttertoast.showToast(msg: PaymentConfig.unavailableMessage);
      return;
    }

    _settling = order.dueIds;
    final auth = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>().userData.value
        : null;
    try {
      _razorpay.open({
        'key': PaymentConfig.razorpayKey,
        // The ORDER's amount is what Razorpay charges once an order id is
        // supplied. Anything computed here could only disagree with it.
        'amount': order.amountPaise,
        'order_id': order.orderId,
        'name': 'Aajoo',
        'description': 'Pay-at-property settlement',
        'prefill': {
          'email': auth?.email ?? '',
          'contact': auth?.phoneNumber ?? '',
        },
        'theme': {'color': '#0F766E'},
      });
    } catch (e) {
      if (mounted) {
        setState(() => _paying = false);
        _say('Could not open payment', e.toString());
      }
    }
  }

  Future<void> _onPaid(PaymentSuccessResponse r) async {
    final err = await HostDuesService.instance.verify(
      orderId: r.orderId ?? '',
      paymentId: r.paymentId ?? '',
      signature: r.signature ?? '',
      dueIds: _settling,
    );
    if (!mounted) return;
    setState(() => _paying = false);
    if (err != null) {
      // The money has left their account. Telling them it failed would be
      // false, and would invite a second payment.
      _say("We couldn't confirm that payment",
          'Your bank may still have taken it. Do not pay again — check back in '
          'a few minutes, and contact us if it has not appeared as settled.');
      return;
    }
    await _load();
    if (mounted) _say('Thank you', 'Your settlement is recorded.');
  }

  void _onFailed(PaymentFailureResponse r) {
    if (!mounted) return;
    setState(() => _paying = false);
    _say('Payment not completed', rzpReason(r));
  }

  void _say(String title, String body) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title,
            style: fraunces(fontSize: 17, fontWeight: FontWeight.w700, color: kInk)),
        content: Text(body, style: inter(fontSize: 13.5, color: kInk, height: 1.45)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  /// Stay dates arrive as DD-MM-YYYY text, as everywhere else in this backend.
  String _stay(HostDue d) {
    String one(String v) {
      final p = v.split('-');
      if (p.length != 3) return v;
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final m = int.tryParse(p[1]) ?? 0;
      if (m < 1 || m > 12) return v;
      return '${p[0]} ${months[m - 1]}';
    }

    if (d.stayFrom.isEmpty && d.stayTo.isEmpty) return '';
    if (d.stayTo.isEmpty) return one(d.stayFrom);
    return '${one(d.stayFrom)} – ${one(d.stayTo)}';
  }

  @override
  Widget build(BuildContext context) {
    final d = _dues;
    return Scaffold(
      backgroundColor: kSand,
      appBar: AppBar(
        backgroundColor: kSand,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: kInk,
        titleSpacing: 0,
        title: Text('Settlements',
            style: fraunces(fontSize: 20, fontWeight: FontWeight.w700, color: kInk)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                children: [
                  if (_failed) _errorCard() else ...[
                    _headline(d!),
                    const SizedBox(height: 18),
                    if (d.items.isNotEmpty) ...[
                      _sectionTitle('Outstanding'),
                      const SizedBox(height: 10),
                      ...(<HostDue>[
                        ...d.items.where((i) => i.payableNow),
                        ...d.items.where((i) => !i.payableNow),
                      ]).map(_dueCard),
                    ] else
                      _allClear(),
                    if (d.settled.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _sectionTitle('Settled'),
                      const SizedBox(height: 10),
                      ...d.settled.map(_settledRow),
                    ],
                    const SizedBox(height: 18),
                    _explainer(d),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _errorCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kDangerBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Could not load your settlements',
                style: fraunces(fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
            const SizedBox(height: 6),
            // Never "nothing owed": that is the one wrong answer this screen
            // can give, and it is the reassuring one.
            Text('This is a failed request, not an empty list. Pull down to try again.',
                style: inter(fontSize: 13, color: kInk2, height: 1.45)),
          ],
        ),
      );

  Widget _headline(HostDues d) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kIndigo,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payable now',
                style: inter(fontSize: 12.5, color: Colors.white70)),
            const SizedBox(height: 6),
            Text(rupees(d.payableNow),
                style: fraunces(
                    fontSize: 30, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 4),
            Text(
              d.upcoming > 0
                  ? '${rupees(d.upcoming)} more falls due as those stays begin'
                  : 'Nothing else pending',
              style: inter(fontSize: 12, color: Colors.white70),
            ),
            if (d.payableNow > 0) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _paying ? null : _pay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: kIndigo,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _paying ? 'Opening…' : 'Settle ${rupees(d.payableNow)}',
                    style: inter(fontSize: 14, fontWeight: FontWeight.w700, color: kIndigo),
                  ),
                ),
              ),
            ],
          ],
        ),
      );

  Widget _sectionTitle(String s) => Text(s,
      style: fraunces(fontSize: 17, fontWeight: FontWeight.w700, color: kInk));

  Widget _allClear() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: BoxDecoration(
          color: kCream,
          border: Border.all(color: kLine),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline, color: kSuccess, size: 26),
            const SizedBox(height: 8),
            Text('Nothing owed. Every pay-at-property booking is settled.',
                textAlign: TextAlign.center,
                style: inter(fontSize: 13, color: kMuted, height: 1.45)),
          ],
        ),
      );

  Widget _dueCard(HostDue d) {
    final open = _open == d.dueId;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kCream,
        border: Border.all(color: kLine),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _open = open ? null : d.dueId),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.bookingCode,
                            style: inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: kInk)),
                        const SizedBox(height: 2),
                        Text(
                          _stay(d).isEmpty ? d.property : '${d.property} · ${_stay(d)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: inter(fontSize: 12, color: kMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(rupees(d.amount),
                          style: inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: kInk)),
                      const SizedBox(height: 3),
                      _pill(d.payableNow ? 'Payable now' : 'From check-in',
                          d.payableNow),
                    ],
                  ),
                  Icon(open ? Icons.expand_less : Icons.expand_more,
                      size: 20, color: kMuted),
                ],
              ),
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
                  const Divider(color: kLine, height: 1),
                  const SizedBox(height: 10),
                  _line('Aajoo commission', '15% of the room total', d.commission),
                  _line('GST on commission', '18%', d.gstOnCommission),
                  _line('Accommodation GST', 'we remit this', d.accommodationGst),
                  const SizedBox(height: 6),
                  const Divider(color: kLine, height: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Due to Aajoo',
                          style: inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: kInk)),
                      Text(rupees(d.amount),
                          style: inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: kInk)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // The reassurance, stated with its own arithmetic beside it.
                  Text(
                    'You collected ${rupees(d.collectedFromGuest)} from the guest, so '
                    'you keep ${rupees(d.hostKeeps)} — the same as an online booking '
                    'of this value.',
                    style: inter(fontSize: 11.5, color: kMuted, height: 1.5),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _line(String label, String hint, num value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(children: [
                  TextSpan(text: label, style: inter(fontSize: 12.5, color: kMuted)),
                  TextSpan(
                      text: ' · $hint',
                      style: inter(fontSize: 11, color: kMuted)),
                ]),
              ),
            ),
            Text(rupees(value), style: inter(fontSize: 12.5, color: kInk2)),
          ],
        ),
      );

  Widget _pill(String text, bool warn) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: warn ? kWarningBg : kIndigo50,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(text,
            style: inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: warn ? kWarningText : kIndigo600)),
      );

  Widget _settledRow(SettledDue s) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: kCream,
          border: Border.all(color: kLine),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.bookingCode,
                      style: inter(
                          fontSize: 13, fontWeight: FontWeight.w700, color: kInk)),
                  const SizedBox(height: 2),
                  // "Paid by you" and "Deducted from a payout" are the same
                  // rupees and very different facts.
                  Text(s.how, style: inter(fontSize: 11.5, color: kMuted)),
                ],
              ),
            ),
            Text(rupees(s.amount),
                style: inter(
                    fontSize: 13.5, fontWeight: FontWeight.w700, color: kSuccess)),
          ],
        ),
      );

  Widget _explainer(HostDues d) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kIndigo50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Why this is here',
                style: fraunces(fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
            const SizedBox(height: 6),
            Text(
              'When a guest pays at your property, the whole amount goes to you — '
              'including Aajoo’s commission and the GST we have to remit. This is '
              'that share coming back. You keep exactly what you would have kept '
              'on an online booking of the same value.',
              style: inter(fontSize: 12.5, color: kInk2, height: 1.5),
            ),
            const SizedBox(height: 12),
            Text('If you don’t settle',
                style: fraunces(fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
            const SizedBox(height: 6),
            // Said plainly. A host discovering this from a smaller payout is
            // the outcome the screen exists to prevent.
            Text(
              '${d.note} Oldest first, and only whole settlements — a payout that '
              'can’t cover one leaves it here rather than part-paying it.',
              style: inter(fontSize: 12.5, color: kInk2, height: 1.5),
            ),
          ],
        ),
      );
}
