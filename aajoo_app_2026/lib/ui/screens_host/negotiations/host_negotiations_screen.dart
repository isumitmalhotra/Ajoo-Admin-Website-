import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/models/host_negotiation.dart';
import 'package:rent_home/ui/motion/aajoo_motion.dart';
import 'package:rent_home/ui/screens_host/home/components/negotiation_card.dart';
import 'package:rent_home/ui/screens_host/host_controller.dart';
import 'package:rent_home/utils/fonts.dart';

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
    hostController.getNegotiations();
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
                child: NegotiationCard(n: items[i]),
              ),
            ),
    );
  }
}
