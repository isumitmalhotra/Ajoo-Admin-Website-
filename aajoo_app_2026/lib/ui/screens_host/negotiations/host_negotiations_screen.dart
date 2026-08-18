import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/models/host_negotiation.dart';
import 'package:rent_home/ui/motion/aajoo_motion.dart';
import 'package:rent_home/ui/screens_host/home/components/negotiation_card.dart';
import 'package:rent_home/ui/screens_host/host_controller.dart';
import 'package:rent_home/controller/alert_dialog.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/utils/input_sanitizers.dart';

/// Every negotiation on the host's properties (A-70).
///
/// `/host/negotiations/list` shipped with the negotiation feature and nothing
/// in the app ever called it, so the only way a host learned about an offer
/// was the push notification — miss it and the offer was effectively
/// invisible. Awaiting-you first, because that is the only tab with a decision
/// in it.
class HostNegotiationsScreen extends StatefulWidget {
  const HostNegotiationsScreen({super.key});

  @override
  State<HostNegotiationsScreen> createState() => _HostNegotiationsScreenState();
}

class _HostNegotiationsScreenState extends State<HostNegotiationsScreen> {
  final hostController = Get.put(HostController());

  @override
  void initState() {
    super.initState();
    // AFTER the first frame. getNegotiations() flips negotiationsFetched
    // synchronously, and doing that from initState marks the Obx below dirty
    // while the framework is still building it — Flutter throws
    // "setState() called during build", the fetch never completes, and the
    // screen spins forever.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      hostController.getNegotiations();
    });
  }

  /// Answer an offer. Accept and decline confirm first — both are final for
  /// the guest — and a counter asks for the number before anything is sent.
  Future<void> _respond(HostNegotiation n, String action) async {
    double? counterPrice;
    String? message;

    if (action == 'counter') {
      final result = await _askCounter(n);
      if (result == null) return; // backed out
      counterPrice = result.$1;
      message = result.$2;
    } else {
      final confirmed = await _confirm(n, action);
      if (confirmed != true) return;
    }

    try {
      final res = await hostController.hostService.respondNegotiation(
        offerId: n.offerId,
        action: action,
        counterPrice: counterPrice,
        message: message,
      );
      if (!mounted) return;
      if (res.ok) {
        showAlert(
          'Negotiations',
          action == 'accept'
              ? (res.couponCode != null
                  ? 'Offer accepted — the guest has a 24-hour deal (${res.couponCode}) for the agreed price and dates.'
                  : 'Offer accepted — the guest has a 24-hour deal for the agreed price and dates.')
              : action == 'counter'
                  ? 'Counter sent — the guest decides next.'
                  : 'Offer declined.',
          false,
        );
        // Refetch rather than patch: accepting mints a coupon and countering
        // creates a NEW offer row, so the list the server holds is not the
        // list we could reconstruct here.
        await hostController.getNegotiations();
      } else {
        showAlert('Negotiations', res.message ?? 'Could not send your response.',
            true);
      }
    } catch (e) {
      if (!mounted) return;
      showAlert('Negotiations',
          e.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''), true);
    }
  }

  Future<bool?> _confirm(HostNegotiation n, String action) {
    final accepting = action == 'accept';
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text(accepting ? 'Accept this offer?' : 'Decline this offer?',
            style: fraunces(
                fontSize: 17, fontWeight: FontWeight.w700, color: kInk)),
        content: Text(
          accepting
              ? 'You will host ${n.renterName} at ₹${n.offerPrice.round()}/night'
                  '${n.bookFrom != null ? ' for ${n.bookFrom} → ${n.bookTo}' : ''}. '
                  'They get a one-time deal valid for 24 hours.'
              : '${n.renterName} will be told the offer was declined. '
                  'You can still counter instead.',
          style: inter(fontSize: 13.5, color: kInk2, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Back', style: inter(color: kMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: accepting ? kSuccess : kDanger,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(accepting ? 'Accept' : 'Decline'),
          ),
        ],
      ),
    );
  }

  /// (price, message) or null when the host backs out.
  Future<(double, String?)?> _askCounter(HostNegotiation n) {
    final priceController = TextEditingController();
    final messageController = TextEditingController();
    String? error;
    return showDialog<(double, String?)>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: kSurface,
          title: Text('Counter the offer',
              style: fraunces(
                  fontSize: 17, fontWeight: FontWeight.w700, color: kInk)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${n.renterName} offered ₹${n.offerPrice.round()}/night'
                '${n.originalPrice > 0 ? ' against your ₹${n.originalPrice.round()}' : ''}.',
                style: inter(fontSize: 13, color: kMuted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                inputFormatters: AppInputFormatters.digits(7),
                decoration: InputDecoration(
                  labelText: 'Your price per night (₹)',
                  errorText: error,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: messageController,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Message (optional)',
                  counterText: '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Back', style: inter(color: kMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: kIndigo, foregroundColor: Colors.white),
              onPressed: () {
                final value = double.tryParse(priceController.text.trim());
                if (value == null || value <= 0) {
                  setDialogState(() => error = 'Enter a price');
                  return;
                }
                // A counter BELOW the guest's own offer would be arguing
                // against yourself — the server takes it, but it can only
                // ever be a slip.
                if (value < n.offerPrice) {
                  setDialogState(() => error =
                      'That is below their ₹${n.offerPrice.round()} offer');
                  return;
                }
                Navigator.of(ctx).pop((value, messageController.text));
              },
              child: const Text('Send counter'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: kscaffoldColor,
        appBar: AppBar(
          backgroundColor: kCream,
          foregroundColor: kInk,
          elevation: 0,
          centerTitle: true,
          title: Text('Negotiations',
              style: fraunces(
                  fontSize: 18, fontWeight: FontWeight.w600, color: kInk)),
          bottom: TabBar(
            isScrollable: false,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(width: 2, color: kIndigo600),
              insets: EdgeInsets.symmetric(horizontal: 4),
            ),
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: kLine,
            dividerHeight: 1,
            labelColor: kInk,
            unselectedLabelColor: kMuted,
            labelStyle: inter(fontSize: 13.5, fontWeight: FontWeight.w600),
            unselectedLabelStyle: inter(fontSize: 13.5),
            tabs: const [
              Tab(text: 'Awaiting you'),
              Tab(text: 'All'),
            ],
          ),
        ),
        body: Obx(() {
          if (!hostController.negotiationsFetched.value) {
            return const Center(
                child: CircularProgressIndicator(color: kIndigo));
          }
          final all = hostController.negotiations.toList();
          final pending = all.where((n) => n.isPending).toList();
          return TabBarView(
            children: [
              _list(pending, 'No offers waiting on you'),
              _list(all, 'No negotiations yet'),
            ],
          );
        }),
      ),
    );
  }

  Widget _list(List<HostNegotiation> items, String emptyText) {
    return RefreshIndicator(
      color: kIndigo,
      onRefresh: hostController.getNegotiations,
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 110),
                Icon(Icons.handshake_outlined,
                    size: 60, color: kMuted.withOpacity(0.45)),
                const SizedBox(height: 12),
                Center(
                  child: Text(emptyText,
                      style: inter(fontSize: 15, color: kMuted)),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => Reveal(
                delay: Reveal.staggerDelay(i),
                child: NegotiationCard(
                  n: items[i],
                  onRespond: (action) => _respond(items[i], action),
                ),
              ),
            ),
    );
  }
}
