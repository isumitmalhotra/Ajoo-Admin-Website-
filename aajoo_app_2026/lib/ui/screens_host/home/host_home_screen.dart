import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ionicons/ionicons.dart';
import 'package:rent_home/ui/screens_common/auth/auth_controller.dart';
import 'package:rent_home/ui/screens_common/notifications/notification_screen.dart';
import 'package:rent_home/ui/screens_host/host_controller.dart';
import 'package:rent_home/ui/screens_host/add_property/host_property_listing_screen.dart';
import 'package:rent_home/ui/screens_host/booking_history/booking_history_screen.dart';
import 'package:rent_home/ui/screens_host/ongoing_booking/view_ongoing_booking_page.dart';
import 'package:rent_home/ui/screens_host/payout/payout_page.dart';
import 'package:rent_home/ui/screens_host/support/host_support_screen.dart';
import 'package:rent_home/ui/screens_host/home/components/host_home_shimmer.dart';
import 'package:rent_home/ui/screens_host/home/components/host_recent_transaction_item_view.dart';
import 'package:rent_home/ui/screens_host/home/components/host_recent_transaction_loading_view.dart';
import 'package:rent_home/ui/screens_host/home/components/no_ongoing_booking_view.dart';
import 'package:rent_home/ui/screens_host/home/components/no_recent_transaction_view.dart';
import 'package:rent_home/models/host_ongoing_response.dart';
import '../../../constants.dart';
import '../../../utils/fonts.dart';

/// Host Dashboard — re-skinned to the new teal/orange design (scaffold
/// host_dashboard): in-body header, greeting, earnings card, stat grid,
/// ongoing-stays list, boost banner, recent transactions. All figures are wired
/// to real HostController data (ongoing / properties / booking-history /
/// transactions). `onMenuTap` opens the shell's drawer.
class HostHomeScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const HostHomeScreen({super.key, this.onMenuTap});

  @override
  State<HostHomeScreen> createState() => _HostHomeScreenState();
}

class _HostHomeScreenState extends State<HostHomeScreen> {
  final hostController = Get.find<HostController>();
  static const Color _teal50 = kIndigo50;
  static const Color _orange50 = Color(0xFFFFF1E6);

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final auth =
        Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;
    final hostId = auth?.userData.value?.userId ?? 0;
    await Future.wait([
      hostController.getTransactionHistory(),
      hostController.getHostOngoing(hostId),
      hostController.getHostProperties(),
      hostController.getHostBookingHistory(),
    ]);
  }

  String _formatAmount(num v) {
    // Indian-style grouping (₹24,680) without extra deps.
    final s = v.round().toString();
    final buf = StringBuffer();
    final len = s.length;
    for (int i = 0; i < len; i++) {
      buf.write(s[i]);
      final remaining = len - i - 1;
      if (remaining > 0 && (remaining == 3 || (remaining > 3 && (remaining - 3) % 2 == 0))) {
        buf.write(',');
      }
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final auth =
        Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;
    final name = auth?.userData.value?.fullName ?? 'Host';
    final firstName = name.trim().split(' ').first;

    return Scaffold(
      backgroundColor: kscaffoldColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: kIndigo,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _header(),
              const SizedBox(height: 18),
              _greeting(firstName),
              const SizedBox(height: 16),
              _earningsCard(),
              const SizedBox(height: 16),
              _statGrid(),
              const SizedBox(height: 22),
              _sectionHeader('Ongoing Bookings',
                  actionLabel: 'View all',
                  onAction: () => Get.to(() => const BookingHistoryScreen())),
              const SizedBox(height: 10),
              _ongoingList(),
              const SizedBox(height: 18),
              _boostBanner(),
              const SizedBox(height: 22),
              _sectionHeader('Recent Transactions'),
              const SizedBox(height: 8),
              _transactionsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        InkWell(
          onTap: widget.onMenuTap,
          borderRadius: BorderRadius.circular(10),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Ionicons.grid_outline, size: 22, color: kInk),
          ),
        ),
        const SizedBox(width: 12),
        Text('aajoo',
            style: fraunces(
                fontSize: 22, fontWeight: FontWeight.w700, color: kClay)),
        const SizedBox(width: 6),
        Text('Host',
            style: inter(
                fontSize: 13, fontWeight: FontWeight.w600, color: kInk)),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline, size: 21, color: kInk2),
          onPressed: () => Get.to(() => const HostSupportScreen()),
        ),
        IconButton(
          icon: const Icon(Ionicons.notifications_outline,
              size: 22, color: kInk2),
          onPressed: () => Get.to(() => const NotificationsScreen()),
        ),
      ],
    );
  }

  Widget _greeting(String firstName) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(color: _teal50, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            firstName.isNotEmpty ? firstName[0].toUpperCase() : 'H',
            style: fraunces(
                fontSize: 24, fontWeight: FontWeight.w700, color: kIndigo600),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hi, $firstName! 👋',
                  style: fraunces(
                      fontSize: 20, fontWeight: FontWeight.w700, color: kInk)),
              const SizedBox(height: 2),
              Text("Here's what's happening with your properties today.",
                  style: inter(fontSize: 12.5, color: kMuted, height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _earningsCard() {
    return Obx(() {
      final txns = hostController.transactionHistoryResponse.value?.data ?? [];
      final total = txns.fold<double>(
          0, (sum, t) => sum + (double.tryParse(t.payAmount) ?? 0));
      return InkWell(
        onTap: () => Get.to(() => const PayoutPage()),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              color: _teal50, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Earnings',
                      style: inter(fontSize: 12.5, color: kMuted)),
                  const SizedBox(height: 4),
                  Text('₹${_formatAmount(total)}',
                      style: fraunces(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: kInk)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('View Payouts',
                          style: inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: kIndigo600)),
                      const Icon(Icons.chevron_right,
                          size: 16, color: kIndigo600),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Container(
                width: 46,
                height: 46,
                decoration:
                    const BoxDecoration(color: kIndigo, shape: BoxShape.circle),
                child: const Icon(Icons.account_balance_wallet_outlined,
                    color: Colors.white, size: 22),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _statGrid() {
    return Obx(() {
      final bookings = hostController.hostBookingHistoryResponse.value?.data.length ?? 0;
      final ongoing =
          hostController.HostOngoingResponse.value?.data.bookings.length ?? 0;
      final properties = hostController
              .hostPropertiesResponse.value?.data?.properties.length ??
          0;
      final txns = hostController.transactionHistoryResponse.value?.data.length ?? 0;
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _statCard(Ionicons.calendar_outline, '$bookings',
                      'Total Bookings', _teal50, kIndigo600)),
              const SizedBox(width: 12),
              Expanded(
                  child: _statCard(Icons.schedule, '$ongoing',
                      'Ongoing Stays', _orange50, kClay)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _statCard(Ionicons.home_outline, '$properties',
                      'Properties', _teal50, kIndigo600)),
              const SizedBox(width: 12),
              Expanded(
                  child: _statCard(Icons.receipt_long_outlined, '$txns',
                      'Transactions', _orange50, kClay)),
            ],
          ),
        ],
      );
    });
  }

  Widget _statCard(
      IconData icon, String value, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: fg),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: fraunces(
                  fontSize: 22, fontWeight: FontWeight.w700, color: kInk)),
          Text(label, style: inter(fontSize: 12, color: kMuted)),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title,
      {String? actionLabel, VoidCallback? onAction}) {
    return Row(
      children: [
        Text(title,
            style: fraunces(
                fontSize: 18, fontWeight: FontWeight.w700, color: kInk)),
        const Spacer(),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(actionLabel,
                style: inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kIndigo600)),
          ),
      ],
    );
  }

  Widget _ongoingList() {
    return Obx(() {
      if (hostController.loading.value &&
          hostController.HostOngoingResponse.value == null) {
        return const HostHomeShimmer();
      }
      final bookings =
          hostController.HostOngoingResponse.value?.data.bookings ?? [];
      if (bookings.isEmpty) return const NoOngoingBookingView();
      return Column(
        children: bookings
            .map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _bookingCard(b),
                ))
            .toList(),
      );
    });
  }

  Widget _bookingCard(Booking b) {
    final status = b.bookingStatusBsTitle;
    final isPending = status.toLowerCase().contains('pend');
    final badgeColor = isPending ? kClay : kSuccess;
    final badgeBg = isPending ? _orange50 : const Color(0xFFEAF6EE);
    return InkWell(
      onTap: () => Get.to(() => ViewOngoingBookingPage(booking: b)),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kLine),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration:
                  const BoxDecoration(color: _teal50, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(
                b.userDetailsUserFullName.isNotEmpty
                    ? b.userDetailsUserFullName[0].toUpperCase()
                    : '?',
                style: fraunces(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: kIndigo600),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(b.userDetailsUserFullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: fraunces(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: kInk)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(status,
                            style: inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: badgeColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text('#${b.bookId}',
                      style: inter(fontSize: 12, color: kMuted)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.event_outlined,
                          size: 12, color: kMuted),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                            '${b.bookDetailsBtBookFrom} → ${b.bookDetailsBtBookTo}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: inter(fontSize: 11.5, color: kMuted)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: kMuted),
          ],
        ),
      ),
    );
  }

  Widget _boostBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: _orange50, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const Icon(Icons.campaign_outlined, size: 24, color: kClay),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('List a new property',
                    style: fraunces(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: kInk)),
                const SizedBox(height: 2),
                Text('Add another stay and reach more guests.',
                    style: inter(fontSize: 11.5, color: kMuted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Get.to(() => const HostPropertyListingScreen()),
            style: ElevatedButton.styleFrom(
                backgroundColor: kClay,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: Text('List',
                style: inter(fontSize: 12.5, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _transactionsList() {
    return Obx(() {
      if (hostController.loading.value &&
          hostController.transactionHistoryResponse.value == null) {
        return const HostRecentTransactionLoadingView();
      }
      final txns = hostController.transactionHistoryResponse.value?.data ?? [];
      if (txns.isEmpty) return const NoRecentTransactionView();
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: txns.length,
        itemBuilder: (context, index) {
          final t = txns[index];
          final d = t.payAddedAt;
          final formatDate = '${d.day}/${d.month}/${d.year}';
          return HostRecentTransactionItemView(
              transaction: t, formatDate: formatDate);
        },
      );
    });
  }
}
