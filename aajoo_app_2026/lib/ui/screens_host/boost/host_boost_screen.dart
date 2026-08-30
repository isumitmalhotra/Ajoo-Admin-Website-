import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'package:rent_home/constants.dart';
import 'package:rent_home/constants/payment_config.dart';
import 'package:rent_home/service/growth_service.dart';
import 'package:rent_home/service/host_service.dart';
import 'package:rent_home/ui/screens_common/auth/auth_controller.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/utils/money.dart';
import 'package:rent_home/utils/rzp_error.dart';

/// Boost — paid placement, the mobile counterpart of the web's /host/boost.
///
/// A host could not buy placement from the phone at all: /host/boost/list,
/// /order and /verify shipped with the web portal and the app had no reader.
///
/// The three plans and their wording are the website's, because a host who
/// reads one price on the site and another here has been told two different
/// things about the same product. The AMOUNT charged is always the one the
/// server puts in the Razorpay order, never a figure computed here.
class HostBoostScreen extends StatefulWidget {
  const HostBoostScreen({super.key});

  @override
  State<HostBoostScreen> createState() => _HostBoostScreenState();
}

class _BoostPlan {
  const _BoostPlan(this.key, this.name, this.price, this.duration, this.features);
  final String key;
  final String name;
  final num price;
  final String duration;
  final List<String> features;
}

class _HostBoostScreenState extends State<HostBoostScreen> {
  // Mirrors src/redesign/pages/host/Boost.tsx.
  static const _plans = [
    _BoostPlan('starter', 'Starter', 499, 'week', [
      'Top of search for 7 days',
      '“Sponsored” badge on your listing',
      'Ranks above all unboosted stays',
    ]),
    _BoostPlan('growth', 'Growth', 1499, 'month', [
      'Top of search for 30 days',
      '“Sponsored” badge on your listing',
      'Ranks above Starter boosts',
    ]),
    _BoostPlan('pro', 'Pro', 3999, 'quarter', [
      'Top of search for 90 days',
      '“Sponsored” badge on your listing',
      'Ranks above Growth and Starter',
      'First on the Explore homepage',
    ]),
  ];

  late final Razorpay _razorpay;
  List<BoostRecord> _boosts = const [];
  List<({int id, String name})> _properties = const [];
  // Only a page of listings is fetched: this host owns 29,230, and a dropdown
  // is not the place to enumerate them.
  static const _propertyPageSize = 50;
  int? _propertyId;
  bool _loading = true;
  String? _busyPlan;

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
    final boosts = await GrowthService.instance.boosts();
    // Boosting an unpublished listing buys placement for something guests
    // cannot open, so only live ones are offered.
    final res = await HostService()
        .getHostProperties(limit: _propertyPageSize, status: 'active');
    final props = (res.data?.properties ?? const [])
        .map((p) => (id: p.propertyId, name: p.propertyName))
        .toList();
    if (!mounted) return;
    setState(() {
      _boosts = boosts;
      _properties = props;
      _propertyId ??= props.isEmpty ? null : props.first.id;
      _loading = false;
    });
  }

  Future<void> _buy(_BoostPlan plan) async {
    final propId = _propertyId;
    if (propId == null) return;
    setState(() => _busyPlan = plan.key);
    final order =
        await GrowthService.instance.orderBoost(propertyId: propId, plan: plan.key);
    if (!mounted) return;

    if (!order.ok) {
      setState(() => _busyPlan = null);
      _say('Could not start that boost', order.error ?? 'Please try again.');
      return;
    }

    final auth = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>().userData.value
        : null;
    try {
      // A release build carrying a TEST key takes no money while looking
      // exactly as if it did (W8 · P0-02). Refuse rather than confirm a
      // booking nobody paid for. Debug builds, and any build made with
      // --dart-define=ALLOW_TEST_PAYMENTS=true, are unaffected.
      if (!PaymentConfig.usableForPayments) {
        Fluttertoast.showToast(msg: PaymentConfig.unavailableMessage);
        return;
      }
      _razorpay.open({
        'key': PaymentConfig.razorpayKey,
        // The ORDER's amount is what Razorpay actually charges when an order
        // id is supplied, so sending anything computed here could only ever
        // disagree with what is taken.
        'amount': order.amountPaise,
        'order_id': order.orderId,
        'name': 'Aajoo',
        'description': '${plan.name} boost',
        'prefill': {
          'email': auth?.email ?? '',
          'contact': auth?.phoneNumber ?? '',
        },
        'theme': {'color': '#3399cc'},
      });
    } catch (e) {
      if (mounted) {
        setState(() => _busyPlan = null);
        _say('Could not open payment', e.toString());
      }
    }
  }

  Future<void> _onPaid(PaymentSuccessResponse r) async {
    final err = await GrowthService.instance.verifyBoost(
      orderId: r.orderId ?? '',
      paymentId: r.paymentId ?? '',
      signature: r.signature ?? '',
    );
    if (!mounted) return;
    setState(() => _busyPlan = null);
    if (err != null) {
      // The charge may well have gone through, so do not tell them it failed.
      _say("We couldn't confirm that payment",
          'Your bank may still have taken it. Do not pay again — check back in '
          'a few minutes, and contact us if the boost has not started.');
      return;
    }
    await _load();
    if (mounted) {
      _say('Boost is live',
          'Your listing now ranks above unboosted stays for the length of the plan.');
    }
  }

  void _onFailed(PaymentFailureResponse r) {
    if (!mounted) return;
    setState(() => _busyPlan = null);
    // Razorpay's own sentence, not the plugin's raw JSON envelope.
    _say('Payment not completed', rzpReason(r));
  }

  void _say(String title, String body) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title,
            style:
                fraunces(fontSize: 17, fontWeight: FontWeight.w700, color: kInk)),
        content: Text(body,
            style: inter(fontSize: 13.5, color: kInk, height: 1.45)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK')),
        ],
      ),
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
        title: Text('Boost',
            style:
                fraunces(fontSize: 20, fontWeight: FontWeight.w700, color: kInk)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                children: [
                  Text(
                    'A boosted stay sits at the top of search with a Sponsored '
                    'badge, above every unboosted one.',
                    style: inter(fontSize: 13.5, color: kMuted, height: 1.45),
                  ),
                  const SizedBox(height: 16),
                  _propertyPicker(),
                  const SizedBox(height: 16),
                  ..._plans.map(_planCard),
                  if (_boosts.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Your boosts',
                        style: fraunces(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: kInk)),
                    const SizedBox(height: 10),
                    ..._boosts.map(_boostRow),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _propertyPicker() {
    if (_properties.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCream,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kLine),
        ),
        child: Text(
          'You need a published listing before you can boost one.',
          style: inter(fontSize: 13.5, color: kMuted, height: 1.4),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kLine),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _propertyId,
          isExpanded: true,
          style: inter(fontSize: 14, color: kInk),
          hint: Text('Choose a listing',
              style: inter(fontSize: 14, color: kMuted)),
          items: _properties
              .map((p) => DropdownMenuItem(
                    value: p.id,
                    child: Text(p.name, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _propertyId = v),
        ),
      ),
    );
  }

  Widget _planCard(_BoostPlan p) {
    final busy = _busyPlan == p.key;
    final disabled = _propertyId == null || _busyPlan != null;
    final popular = p.key == 'growth';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: popular ? kIndigo : kLine, width: popular ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(p.name,
                  style: fraunces(
                      fontSize: 18, fontWeight: FontWeight.w700, color: kInk)),
              if (popular) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: kIndigo50,
                      borderRadius: BorderRadius.circular(999)),
                  child: Text('Most popular',
                      style: inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: kIndigo)),
                ),
              ],
              const Spacer(),
              Text(rupees(p.price),
                  style: fraunces(
                      fontSize: 20, fontWeight: FontWeight.w700, color: kInk)),
              Text(' /${p.duration}',
                  style: inter(fontSize: 12, color: kMuted)),
            ],
          ),
          const SizedBox(height: 12),
          ...p.features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 16, color: kSuccess),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(f,
                          style: inter(
                              fontSize: 13, color: kInk2, height: 1.35)),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: disabled ? null : () => _buy(p),
              style: ElevatedButton.styleFrom(
                backgroundColor: popular ? kIndigo : kInk,
                foregroundColor: Colors.white,
                disabledBackgroundColor: kLine,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('Boost with ${p.name}',
                      style:
                          inter(fontSize: 14.5, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _boostRow(BoostRecord b) {
    final s = b.status.toLowerCase();
    final Color fg = s == 'active'
        ? kSuccess
        : (s == 'failed' ? kDanger : kMuted);
    final Color bg = s == 'active'
        ? const Color(0xFFEAF6EE)
        : (s == 'failed' ? const Color(0xFFFDECEC) : kCream);
    final fmt = DateFormat('d MMM');

    return Container(
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
                Text(b.propertyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kInk)),
                const SizedBox(height: 2),
                Text(
                  [
                    '${b.plan[0].toUpperCase()}${b.plan.substring(1)} · ${rupees(b.amount)}',
                    if (b.start != null && b.end != null)
                      '${fmt.format(b.start!)} → ${fmt.format(b.end!)}',
                  ].join('  ·  '),
                  style: inter(fontSize: 12, color: kMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(999)),
            child: Text(b.status.toUpperCase(),
                style: inter(
                    fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
          ),
        ],
      ),
    );
  }
}
