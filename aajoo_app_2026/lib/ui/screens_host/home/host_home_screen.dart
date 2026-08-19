import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ionicons/ionicons.dart';
import 'package:rent_home/ui/screens_common/auth/auth_controller.dart';
import 'package:rent_home/ui/screens_common/notifications/notification_screen.dart';
import 'package:rent_home/ui/screens_host/host_controller.dart';
import 'package:rent_home/ui/screens_host/listing/listing_wizard_screen.dart';
import 'package:rent_home/ui/screens_host/booking_history/booking_history_screen.dart';
import 'package:rent_home/ui/screens_host/calendar/host_calendar_screen.dart';
import 'package:rent_home/ui/screens_host/ongoing_booking/view_ongoing_booking_page.dart';
import 'package:rent_home/ui/screens_host/payout/payout_page.dart';
import 'package:rent_home/ui/screens_host/support/host_support_screen.dart';
import 'package:rent_home/ui/screens_host/home/components/bookings_trend_card.dart';
import 'package:rent_home/ui/screens_host/home/components/host_home_shimmer.dart';
import 'package:rent_home/ui/screens_host/home/components/host_recent_transaction_item_view.dart';
import 'package:rent_home/ui/screens_host/home/components/host_recent_transaction_loading_view.dart';
import 'package:rent_home/ui/screens_host/home/components/no_ongoing_booking_view.dart';
import 'package:rent_home/ui/screens_host/home/components/no_recent_transaction_view.dart';
import 'package:rent_home/ui/screens_host/home/components/negotiation_card.dart';
import 'package:rent_home/ui/screens_host/negotiations/host_negotiations_screen.dart';
import 'package:rent_home/ui/screens_renter/home/components/home_faq_strip.dart';
import 'package:rent_home/models/host_ongoing_response.dart';
import '../../../constants.dart';
import '../../../utils/fonts.dart';
import '../../motion/aajoo_motion.dart';
import 'package:rent_home/utils/booking_status.dart';
import 'package:rent_home/ui/screens_host/host_tab_provider.dart';
import 'package:provider/provider.dart';

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

  /// Dashboard's slot in the shell's IndexedStack (see host_tab_provider).
  static const int _dashboardTab = 2;
  bool _wasVisible = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The shell keeps every tab alive in an IndexedStack, so initState runs
    // exactly once per session — the figures here were whatever they had been
    // at login. A host who checked a guest in, then came back, still read
    // "Ongoing Stays 0" and reasonably doubted the action. Re-fetch each time
    // this tab becomes the visible one.
    final isVisible =
        context.watch<HostTabProvider>().currentTab == _dashboardTab;
    if (isVisible && !_wasVisible) _refresh();
    _wasVisible = isVisible;
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
      hostController.getNegotiations(),
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
            // Sections arrive as they reach the viewport — the same vocabulary
            // the guest side and the web use. The header is left alone: it is
            // on screen at first paint and fading it in only delays the page.
            children: [
              _header(),
              const SizedBox(height: 18),
              Reveal(child: _greeting(firstName)),
              const SizedBox(height: 16),
              Reveal(delay: Reveal.staggerDelay(1), child: _earningsCard()),
              const SizedBox(height: 16),
              _statGrid(),
              const SizedBox(height: 16),
              // A-72 asked for a weekly/monthly bookings graph. Built from the
              // booking history this screen already loads, so it costs no extra
              // request — and it draws real counts or says there are none,
              // rather than inventing a shape.
              Reveal(
                delay: Reveal.staggerDelay(2),
                child: Obx(() => BookingsTrendCard(
                      bookings: hostController
                              .hostBookingHistoryResponse.value?.data ??
                          const [],
                    )),
              ),
              const SizedBox(height: 22),
              Reveal(
                child: _sectionHeader('Ongoing Bookings',
                    actionLabel: 'View all',
                    // Tab 1 is Ongoing. Without this the link named Ongoing
                    // opened the list on Upcoming.
                    onAction: () => Get.to(
                        () => const BookingHistoryScreen(initialTab: 1))),
              ),
              const SizedBox(height: 10),
              _ongoingList(),
              const SizedBox(height: 18),
              Reveal(child: _boostBanner()),
              const SizedBox(height: 22),
              // A-70 — negotiations, which is what a host actually has to act
              // on. /host/negotiations/list shipped with the feature and
              // nothing called it, so an offer was only ever visible in a push
              // notification; miss it and it was gone.
              Reveal(
                child: _sectionHeader('Negotiations',
                    actionLabel: 'View all',
                    onAction: () =>
                        Get.to(() => const HostNegotiationsScreen())),
              ),
              const SizedBox(height: 10),
              _negotiationsList(),
              const SizedBox(height: 22),
              Reveal(
                child: _sectionHeader('Recent Transactions',
                    actionLabel: 'View all',
                    onAction: () => Get.to(() => const PayoutPage())),
              ),
              const SizedBox(height: 8),
              _transactionsList(),
              const SizedBox(height: 22),
              // A-71 — FAQ closes the page, as on the guest home.
              const Reveal(child: HomeFaqStrip()),
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
      // Count only money that was actually collected. This used to sum EVERY
      // row the endpoint returns, and /host/transaction-history returns every
      // payment record for the host — including "Not Verified Yet", which is a
      // booking whose payment never completed, and rows against bookings that
      // were later cancelled. On the live database that inflated the tile from
      // ₹74,829 collected to ₹1,77,723, and it was labelled "Total Earnings".
      final total = txns
          .where((t) => t.payStatusText.toLowerCase().contains('paid'))
          .fold<double>(0, (sum, t) => sum + (double.tryParse(t.payAmount) ?? 0));
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
                  // Not "Total Earnings": this is the gross collected from
                  // guests, before the 15% platform commission and the GST on
                  // it. The host's net is lower, and lives in the payouts
                  // screen this card opens.
                  Text('Collected from guests',
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
      // totalCount, not properties.length — the list is one page now, so
      // length would report 20 for a host who owns 29,230.
      final properties = hostController.hostPropertyCount;
      final pendingOffers =
          hostController.negotiations.where((n) => n.isPending).length;
      // Tiles arrive in sequence rather than all at once, capped short so the
      // last one never reads as lag.
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: Reveal(
                      delay: Reveal.staggerDelay(0),
                      child: _statCard(Ionicons.calendar_outline, '$bookings',
                          'Total Bookings', _teal50, kIndigo600,
                          onTap: () => Get.to(() => const BookingHistoryScreen())))),
              const SizedBox(width: 12),
              Expanded(
                  child: Reveal(
                      delay: Reveal.staggerDelay(1),
                      child: _statCard(Icons.schedule, '$ongoing',
                          'Ongoing Stays', _orange50, kClay,
                          // Straight to the stay when there is exactly one;
                          // otherwise the bookings list, where they all are.
                          onTap: () {
                            final list = hostController
                                .HostOngoingResponse.value?.data.bookings;
                            if (list != null && list.length == 1) {
                              Get.to(() => ViewOngoingBookingPage(booking: list.first));
                            } else {
                              Get.to(() => const BookingHistoryScreen(
                                  initialTab: 1));
                            }
                          }))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: Reveal(
                      delay: Reveal.staggerDelay(2),
                      // _formatAmount does Indian grouping and is already used for
                      // the earnings figure above. This tile printed the raw
                      // integer, so a host with 29,230 listings read "29230"
                      // directly under "₹72,940".
                      child: _statCard(
                          Ionicons.home_outline,
                          _formatAmount(properties),
                          'Properties', _teal50, kIndigo600,
                          onTap: () => Get.to(() => const ListingWizardScreen())))),
              const SizedBox(width: 12),
              Expanded(
                  child: Reveal(
                      delay: Reveal.staggerDelay(3),
                      // A-74 — this tile counted transactions, which is a
                      // number the host can neither act on nor change, sitting
                      // directly above the transaction list that shows them
                      // anyway. Offers awaiting a reply is the one number on
                      // this dashboard with a decision attached to it.
                      child: _statCard(Icons.handshake_outlined, '$pendingOffers',
                          'Offers to review', _orange50, kClay,
                          onTap: () =>
                              Get.to(() => const HostNegotiationsScreen())))),
            ],
          ),
          const SizedBox(height: 12),
          // The calendar lived only in the drawer and the profile menu, so
          // the team went looking for it and reported it missing. A full-width
          // row on the dashboard, where a host looks first.
          Reveal(
            delay: Reveal.staggerDelay(4),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Get.to(() => const HostCalendarScreen()),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kLine),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _teal50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.calendar_month_outlined,
                          size: 20, color: kIndigo600),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Calendar',
                              style: fraunces(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: kInk)),
                          const SizedBox(height: 2),
                          Text('See your bookings and block dates',
                              style: inter(fontSize: 12.5, color: kMuted)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: kMuted),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  /// A dashboard tile.
  ///
  /// These were plain Containers — they looked like buttons, sat under headings
  /// a host would expect to drill into, and did nothing at all when tapped.
  /// That is what "ongoing stays / property / buttons are not working" meant:
  /// not that the numbers were wrong, but that the tiles were inert. Each one
  /// now opens the screen it describes, with a ripple so it reads as tappable.
  Widget _statCard(
      IconData icon, String value, String label, Color bg, Color fg,
      {VoidCallback? onTap}) {
    final card = Container(
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

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: card,
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
        children: [
          for (final entry in bookings.asMap().entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Reveal(
                delay: Reveal.staggerDelay(entry.key),
                child: _bookingCard(entry.value),
              ),
            ),
        ],
      );
    });
  }

  Widget _bookingCard(Booking b) {
    // "Pending" was read out of the status word, which only some rows carry —
    // a pay-at-property booking stored as "Booking Confirmed" looked settled.
    // The payment flags say it outright.
    final pay = paymentBadge(isPaid: b.bookIsPaid, isCod: b.bookIsCod);
    final status = pay.label;
    final badgeColor = pay.fg;
    final badgeBg = pay.bg;
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
            onPressed: () => Get.to(() => const ListingWizardScreen()),
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

  /// The three most recent negotiations, pending first — the ones with a
  /// decision in them belong at the top of a dashboard.
  Widget _negotiationsList() {
    return Obx(() {
      if (!hostController.negotiationsFetched.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: CircularProgressIndicator(color: kIndigo)),
        );
      }
      final all = hostController.negotiations.toList();
      if (all.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kLine),
          ),
          child: Column(
            children: [
              Icon(Icons.handshake_outlined,
                  size: 34, color: kMuted.withOpacity(0.45)),
              const SizedBox(height: 10),
              Text('No offers yet',
                  style: inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kInk)),
              const SizedBox(height: 4),
              Text('Guests can negotiate your price — offers land here.',
                  textAlign: TextAlign.center,
                  style: inter(fontSize: 12.5, color: kMuted)),
            ],
          ),
        );
      }
      final sorted = [...all]..sort((a, b) {
          if (a.isPending == b.isPending) return 0;
          return a.isPending ? -1 : 1;
        });
      final shown = sorted.take(3).toList();
      return Column(
        children: [
          for (int i = 0; i < shown.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == shown.length - 1 ? 0 : 12),
              child: NegotiationCard(
                n: shown[i],
                onTap: () => Get.to(() => const HostNegotiationsScreen()),
              ),
            ),
        ],
      );
    });
  }

  Widget _transactionsList() {
    return Obx(() {
      if (hostController.loading.value &&
          hostController.transactionHistoryResponse.value == null) {
        return const HostRecentTransactionLoadingView();
      }
      final txns = hostController.transactionHistoryResponse.value?.data ?? [];
      if (txns.isEmpty) return const NoRecentTransactionView();
      // A-71 — five, not the entire payment history down the dashboard. The
      // full list is a tap away on the Payouts screen.
      final shown = txns.take(5).toList();
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: shown.length,
        itemBuilder: (context, index) {
          final t = shown[index];
          final d = t.payAddedAt;
          final formatDate = '${d.day}/${d.month}/${d.year}';
          return HostRecentTransactionItemView(
              transaction: t, formatDate: formatDate);
        },
      );
    });
  }
}
