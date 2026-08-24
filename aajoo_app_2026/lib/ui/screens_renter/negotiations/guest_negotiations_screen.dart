import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/controller/deals_controller.dart';
import 'package:rent_home/models/guest_negotiation.dart';
import 'package:rent_home/models/negotiated_deal.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/ui/screens_renter/property_details/open_property.dart';

/// The guest's own view of every price negotiation they are in.
///
/// This screen did not exist. A guest could send an offer and then had no way
/// at all to see what became of it — the host had a negotiations screen, the
/// admin had a list, the guest had a write-only door. Worse, when a host
/// COUNTERED, the only signal was a live socket event: present the app and you
/// saw it, miss the moment and the counter was invisible for good.
///
/// Both sides can now see the same conversation, and the guest can answer.
/// Mirrors the web page at /account/negotiations.
class GuestNegotiationsScreen extends StatefulWidget {
  const GuestNegotiationsScreen({super.key});

  @override
  State<GuestNegotiationsScreen> createState() =>
      _GuestNegotiationsScreenState();
}

class _GuestNegotiationsScreenState extends State<GuestNegotiationsScreen> {
  /// Book an accepted deal — the stay opens with the agreed nights and the
  /// deal's coupon pre-filled, exactly like tapping the home-screen banner.
  ///
  /// The coupon lives on DealsController (it is minted server-side when the
  /// host accepts); the negotiation row itself only knows the dates. When the
  /// coupon has already expired the stay still opens on the agreed dates —
  /// the server would refuse the dead code anyway, and an open listing beats
  /// a dead button.
  Future<void> _bookDeal(GuestNegotiation n) async {
    final deals = Get.isRegistered<DealsController>()
        ? Get.find<DealsController>()
        : null;
    NegotiatedDeal? deal;
    if (deals != null) {
      for (final d in deals.activeDeals) {
        if (d.propertyId == n.propertyId) {
          deal = d;
          break;
        }
      }
    }
    await openPropertyById(
      n.propertyId,
      dealCode: deal?.code,
      dealFrom: deal?.bookFrom ?? n.bookFrom,
      dealTo: deal?.bookTo ?? n.bookTo,
      dealPercent: deal?.percent,
      errorTitle: 'Deal',
    );
  }

  final DealsController c = Get.isRegistered<DealsController>()
      ? Get.find<DealsController>()
      : Get.put(DealsController());

  /// Which tab: 0 all, 1 your move, 2 waiting on host, 3 accepted.
  final RxInt tab = 0.obs;

  /// The offer currently being answered, so only that card shows a spinner.
  final RxnInt busyOfferId = RxnInt();

  @override
  void initState() {
    super.initState();
    // After the first frame: loadNegotiations() flips an observable
    // synchronously, and doing that from initState marks the Obx dirty while
    // the framework is still building it, which throws "setState() called
    // during build" and leaves the screen spinning forever. Same trap the host
    // screen documents.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      c.loadNegotiations();
    });
  }

  static String _inr(num n) {
    final s = n.round().toString();
    // Indian grouping: last three, then pairs.
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

  static const _months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  /// "26-08-2026" → "26 Aug 2026"
  static String _pretty(String? dmy) {
    if (dmy == null || dmy.isEmpty) return '';
    final p = dmy.split('-');
    if (p.length != 3) return dmy;
    final d = int.tryParse(p[0]), m = int.tryParse(p[1]), y = int.tryParse(p[2]);
    if (d == null || m == null || y == null || m < 1 || m > 12) return dmy;
    return '$d ${_months[m]} $y';
  }

  static ({String label, Color fg, Color bg}) _statusChip(String status) {
    switch (status) {
      case 'awaiting_you':
        return (label: 'Your move', fg: kInk, bg: kClay);
      case 'accepted':
        return (label: 'Accepted', fg: Colors.white, bg: kSuccess);
      case 'declined':
        return (label: 'Declined', fg: Colors.white, bg: kDanger);
      case 'expired':
        return (label: 'Expired', fg: kMuted, bg: kLine);
      default:
        return (label: 'Waiting on host', fg: kInk2, bg: kLine);
    }
  }

  /// Counter back. A negotiation used to be one round each way and then
  /// stuck — the only answers to a host's counter were yes and no.
  Future<void> _openCounter(GuestNegotiation n) async {
    final id = n.actionableOfferId;
    if (id == null) return;
    final priceCtl = TextEditingController();
    final msgCtl = TextEditingController();
    final err = RxnString();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 18,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Counter this offer',
                style: inter(
                    fontSize: 17, fontWeight: FontWeight.w700, color: kInk)),
            const SizedBox(height: 3),
            Text(
                '${n.hostName} · ${n.propertyName} · '
                '${n.maxRounds - n.roundsYou} of ${n.maxRounds} offers left',
                style: inter(fontSize: 12.5, color: kMuted)),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _tile('Host offered', n.latestPrice, kClay)),
              const SizedBox(width: 10),
              Expanded(child: _tile('Listed at', n.listedPrice, kInk)),
            ]),
            const SizedBox(height: 14),
            Text('Your counter price per night (₹) *',
                style: inter(
                    fontSize: 13, fontWeight: FontWeight.w600, color: kInk)),
            const SizedBox(height: 6),
            TextField(
              controller: priceCtl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: (n.latestPrice * 0.92).round().toString(),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            Text('Message to the host (optional)',
                style: inter(
                    fontSize: 13, fontWeight: FontWeight.w600, color: kInk)),
            const SizedBox(height: 6),
            TextField(
              controller: msgCtl,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: "e.g. That's a little over my budget.",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
              ),
            ),
            Obx(() => err.value == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(err.value!,
                        style: inter(fontSize: 12.5, color: kDanger)),
                  )),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: const BorderSide(color: kLine),
                    foregroundColor: kInk2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11)),
                  ),
                  child: Text('Cancel',
                      style: inter(
                          fontSize: 13.5, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final v = double.tryParse(priceCtl.text.trim());
                    if (v == null || v <= 0) {
                      err.value =
                          'Enter the price per night you want to counter with.';
                      return;
                    }
                    // A guest counters DOWN. Going up is arguing against
                    // yourself, and it is irreversible once sent.
                    if (v >= n.latestPrice) {
                      err.value =
                          'That is at or above the ${_inr(n.latestPrice)} the host offered — accept it instead.';
                      return;
                    }
                    Navigator.pop(ctx);
                    _sendCounter(id, v, msgCtl.text.trim());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kIndigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11)),
                  ),
                  child: Text('Send counter',
                      style: inter(
                          fontSize: 13.5, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
    priceCtl.dispose();
    msgCtl.dispose();
  }

  static Widget _tile(String label, double value, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: kSand, borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(),
                style: inter(fontSize: 10.5, color: kMuted)),
            Text('${_inr(value)} /night',
                style: inter(
                    fontSize: 15.5, fontWeight: FontWeight.w700, color: fg)),
          ],
        ),
      );

  Future<void> _sendCounter(int offerId, double price, String message) async {
    busyOfferId.value = offerId;
    try {
      final err = await c.respond(offerId, 'counter',
          counterPrice: price, message: message);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err ?? 'Counter sent — the host has been told.'),
        backgroundColor: err != null ? kDanger : kSuccess,
      ));
    } finally {
      busyOfferId.value = null;
    }
  }

  Future<void> _respond(GuestNegotiation n, String action) async {
    final id = n.actionableOfferId;
    if (id == null) return;
    busyOfferId.value = id;
    try {
      final err = await c.respond(id, action);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err ??
            (action == 'accept'
                ? 'Deal accepted — book within 24 hours to keep this price.'
                : 'Offer declined.')),
        backgroundColor: err != null ? kDanger : kSuccess,
      ));
    } finally {
      busyOfferId.value = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSand,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
        title: Text('My Negotiations',
            style: inter(fontSize: 17, fontWeight: FontWeight.w700, color: kInk)),
      ),
      body: Obx(() {
        if (c.negotiationsLoading.value && c.negotiations.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = c.negotiations;
        const filters = [null, 'awaiting_you', 'awaiting_host', 'accepted'];
        final want = filters[tab.value];
        final visible =
            want == null ? all : all.where((n) => n.status == want).toList();

        return RefreshIndicator(
          onRefresh: c.loadNegotiations,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
            children: [
              Text("Offers you've sent, and what the host said back",
                  style: inter(fontSize: 13, color: kMuted)),
              const SizedBox(height: 12),
              _tabs(all),
              const SizedBox(height: 14),
              if (visible.isEmpty)
                _empty(all.isEmpty)
              else
                ...visible.map(_thread),
            ],
          ),
        );
      }),
    );
  }

  Widget _tabs(List<GuestNegotiation> all) {
    final counts = [
      all.length,
      all.where((n) => n.status == 'awaiting_you').length,
      all.where((n) => n.status == 'awaiting_host').length,
      all.where((n) => n.status == 'accepted').length,
    ];
    const labels = ['All', 'Your move', 'Waiting on host', 'Accepted'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(labels.length, (i) {
          final on = tab.value == i;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => tab.value = i,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                decoration: BoxDecoration(
                  color: on ? kIndigo : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: on ? kIndigo : kLine),
                ),
                child: Text('${labels[i]} (${counts[i]})',
                    style: inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: on ? Colors.white : kInk2)),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _empty(bool none) => Container(
        margin: const EdgeInsets.only(top: 30),
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kLine),
        ),
        child: Column(
          children: [
            const Icon(Icons.handshake_outlined, size: 34, color: kMuted),
            const SizedBox(height: 10),
            Text(none ? 'No negotiations yet' : 'Nothing in this tab',
                style: inter(
                    fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
            const SizedBox(height: 6),
            Text(
              none
                  ? 'Found a stay you like? Send the host an offer instead of paying the listed price.'
                  : 'Try another tab.',
              textAlign: TextAlign.center,
              style: inter(fontSize: 13, color: kMuted, height: 1.5),
            ),
          ],
        ),
      );

  Widget _thread(GuestNegotiation n) {
    final chip = _statusChip(n.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(n.propertyName,
                    style: inter(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: kInk)),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                    color: chip.bg, borderRadius: BorderRadius.circular(999)),
                child: Text(chip.label,
                    style: inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: chip.fg)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [
              if (n.propertyCity != null) n.propertyCity!,
              'Listed at ${_inr(n.listedPrice)}/night',
            ].join(' · '),
            style: inter(fontSize: 12.5, color: kMuted),
          ),
          if (n.bookFrom != null && n.bookTo != null) ...[
            const SizedBox(height: 3),
            Text('${_pretty(n.bookFrom)} → ${_pretty(n.bookTo)}',
                style: inter(fontSize: 12.5, color: kMuted)),
          ],
          const SizedBox(height: 12),

          // The exchange itself, in order. Neither side could see this before.
          ...n.messages.map((m) => Align(
                alignment:
                    m.mine ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 9),
                  constraints: const BoxConstraints(maxWidth: 260),
                  decoration: BoxDecoration(
                    color: m.mine ? kIndigo50 : kSand,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kLine),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.mine ? 'You offered' : 'Host countered',
                          style: inter(fontSize: 11, color: kMuted)),
                      const SizedBox(height: 2),
                      Text('${_inr(m.price)} /night',
                          style: inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: kInk)),
                      if (m.message.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        // inter() has no fontStyle; copyWith carries the
                        // italic without losing the font variations it sets.
                        Text('“${m.message}”',
                            style: inter(
                                    fontSize: 12.5, color: kMuted, height: 1.4)
                                .copyWith(fontStyle: FontStyle.italic)),
                      ],
                    ],
                  ),
                ),
              )),

          if (n.awaitingYou && n.actionableOfferId != null) ...[
            const Divider(height: 22, color: kLine),
            Obx(() {
              final busy = busyOfferId.value == n.actionableOfferId;
              return Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: busy ? null : () => _respond(n, 'accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kIndigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11)),
                      ),
                      child: busy
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text('Accept ${_inr(n.latestPrice)}/night',
                              style: inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700)),
                    ),
                  ),
                  if (n.canCounter) ...[
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: busy ? null : () => _openCounter(n),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kIndigo,
                        side: const BorderSide(color: kIndigo),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11)),
                      ),
                      child: Text('Counter',
                          style: inter(
                              fontSize: 13.5, fontWeight: FontWeight.w600)),
                    ),
                  ],
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: busy ? null : () => _respond(n, 'decline'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kInk2,
                      side: const BorderSide(color: kLine),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11)),
                    ),
                    child: Text('Decline',
                        style: inter(
                            fontSize: 13.5, fontWeight: FontWeight.w600)),
                  ),
                ],
              );
            }),
            const SizedBox(height: 6),
            Text(
              n.canCounter
                  ? '${n.maxRounds - n.roundsYou} of your ${n.maxRounds} offers left'
                  : "You've used all ${n.maxRounds} of your offers",
              style: inter(fontSize: 11.5, color: kMuted),
            ),
          ] else if (n.status == 'accepted') ...[
            const Divider(height: 22, color: kLine),
            // The web's accepted state books the deal from right here; this
            // screen only SAID the deal existed and left the guest to go find
            // the listing again by hand.
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: kInk,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _bookDeal(n),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text('Book at the agreed price',
                    style: inter(fontSize: 13.5, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),
            Text('Your deal is applied at checkout and is valid for 24 hours.',
                style: inter(fontSize: 12, color: kMuted)),
            const SizedBox(height: 4),
            // An accepted PRICE is not a confirmed BOOKING — most hosts still
            // review the request — and "Accepted" here next to "Pending" in
            // bookings read as the two screens disagreeing about one thing.
            // Same wording as the web.
            Text(
              'This is the price agreed, not a confirmed stay. You still book it, '
              'and unless the host has instant booking on, they confirm the dates '
              'afterwards — so a booking can read "Pending" for a while with the '
              'deal already accepted.',
              style: inter(fontSize: 11.5, color: kMuted, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}
