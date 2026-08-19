import 'package:flutter/material.dart';
import '../../motion/aajoo_motion.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/controller/user_controller.dart';
import 'package:rent_home/models/booking_history_response_model.dart';
import 'package:rent_home/ui/screens_renter/history/components/booking_cart.dart';
import 'package:rent_home/ui/screens_renter/history/components/renter_history_list_shimmer.dart';
import 'package:rent_home/ui/responsive.dart';
import 'package:rent_home/ui/screens_renter/guest_shell.dart';
import 'package:rent_home/utils/stay_clock.dart';

/// My Bookings — 4 status tabs (Upcoming / Ongoing / Completed / Cancelled)
/// over the same getUserHistory data; the tabs only filter, they never refetch.
///
/// Header and tabs follow the current theme: Warm Ivory surface, ink text, teal
/// as an accent under the selected label. It wore a solid teal app bar with
/// white-on-teal tabs until 2026-08-13 — the pre-redesign skin.
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final UserController userController = Get.put(UserController());

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      userController.getUserHistory();
    });
  }

  /// Bucket a booking into one of the four tabs.
  ///
  /// Status alone is not enough. A stay that has been paid for keeps the status
  /// "Paid" for its whole life — nothing moves it on when the guest checks out —
  /// so bucketing on the title left finished stays sitting under Upcoming
  /// indefinitely, disagreeing with the dashboard count beside it. The dates
  /// decide, using the same 2 PM / 11 AM window as the web and the rest of this
  /// app; the title only settles what the dates cannot say (cancelled), and is
  /// the fallback when they cannot be read.
  int _bucket(String? title, {String? from, String? to}) {
    final s = (title ?? '').toLowerCase();
    if (s.contains('cancel')) return 3; // Cancelled — dates are irrelevant.

    // A host who has CHECKED THE GUEST IN has said the stay is happening —
    // that beats the clock. Without this, a guest checked in at 9am sat under
    // Upcoming until the 2pm check-in hour while their own card read
    // "Staying now": the same card disagreeing with the tab it was filed in.
    final checkedIn = s.contains('check in') || s.contains('check-in');

    if (parseStayDate(from) != null && parseStayDate(to) != null) {
      if (hasEnded(to)) return 2; // Completed
      if (checkedIn || isStaying(from, to)) return 1; // Ongoing
      return 0; // Upcoming
    }

    // No usable dates — fall back to whatever the status says.
    if (s.contains('complet') || s.contains('checkout') || s.contains('checked-out')) {
      return 2;
    }
    if (s.contains('running') || s.contains('checkin') ||
        s.contains('checked-in') || s.contains('ongoing') || s.contains('stay')) {
      return 1;
    }
    return 0;
  }

  static const List<String> _tabNames = [
    'Upcoming',
    'Ongoing',
    'Completed',
    'Cancelled',
  ];

  /// A notification can ask for a specific tab — a cancellation should open on
  /// Cancelled, not on Upcoming where the stay is no longer listed.
  ///
  /// Only when opened as its own route. As the shell's Bookings tab, Get
  /// .arguments belongs to the shell's route, not to this screen, so reading it
  /// here would let an unrelated argument choose the tab.
  int _initialTab(BuildContext context) {
    if (GuestShellScope.maybeOf(context) != null) return 0;
    final args = Get.arguments;
    if (args is! Map) return 0;
    final wanted = (args['tab'] ?? '').toString().toLowerCase();
    final index = _tabNames.indexWhere((t) => t.toLowerCase() == wanted);
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      initialIndex: _initialTab(context),
      child: Scaffold(
        backgroundColor: kscaffoldColor,
        appBar: AppBar(
          backgroundColor: kCream,
          foregroundColor: kInk,
          elevation: 0,
          centerTitle: true,
          title: Text('My Bookings',
              style: fraunces(
                  fontSize: 18, fontWeight: FontWeight.w600, color: kInk)),
          // The header was a solid teal slab with white-on-teal tabs — the
          // skin this app wore before the redesign. Everything built since
          // (the property detail tabs, the blog, the confirmed screen) sits on
          // Warm Ivory and spends teal only on the accent. Same treatment as
          // PropertyTabBar so the two tab rows in the app read as one idea:
          // ink for the selected label, muted for the rest, and a short teal
          // rule under the word rather than a full-width bar.
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
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            overlayColor: WidgetStatePropertyAll(kIndigo.withOpacity(0.04)),
            labelStyle: inter(fontSize: 13.5, fontWeight: FontWeight.w600),
            unselectedLabelStyle: inter(fontSize: 13.5),
            tabs: [for (final name in _tabNames) Tab(text: name)],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () async => userController.getUserHistory(),
          child: Obx(() {
            if (userController.isLoading.value) {
              return const RenterHistoryListShimmerView();
            }
            final history = userController.bookingHistory.value;
            // Only THIS screen's own failure blanks this screen. It used to
            // read the controller-wide isError, so an unrelated failure
            // elsewhere hid every booking behind "No upcoming bookings".
            if (userController.historyError.value && history == null) {
              return _loadFailed();
            }
            final all = history == null
                ? <BookingHistoryData>[]
                : List<BookingHistoryData>.from(history.data);
            all.sort((a, b) {
              final da = DateTime.tryParse(a.bookAddedAt.toString());
              final db = DateTime.tryParse(b.bookAddedAt.toString());
              if (da == null || db == null) return 0;
              return db.compareTo(da);
            });
            return TabBarView(
              children: List.generate(4, (bucket) {
                final items =
                    all
                        .where((b) =>
                            _bucket(b.bookingStatusBsTitle,
                                from: b.bookDetailsBtBookFrom,
                                to: b.bookDetailsBtBookTo) ==
                            bucket)
                        .toList();
                if (items.isEmpty) return _empty(bucket);
                // One column on a phone, two or three across a tablet. The
                // cards are self-contained, so this is a layout change only —
                // same cards, same order, same tap target.
                final columns = context.gridColumns(target: 400, max: 3);
                if (columns == 1) {
                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 6, bottom: 20),
                    itemCount: items.length,
                    itemBuilder: (context, i) => Reveal(
                      delay: Reveal.staggerDelay(i),
                      child: BookingCard(booking: items[i]),
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.only(top: 6, bottom: 20),
                  itemCount: items.length,
                  gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    // Tall enough for the photo plus two lines of address; the
                    // card sizes itself and this only reserves the space.
                    mainAxisExtent: 348,
                  ),
                  itemBuilder: (context, i) => Reveal(
                    delay: Reveal.staggerDelay(i),
                    child: BookingCard(booking: items[i]),
                  ),
                );
              }),
            );
          }),
        ),
      ),
    );
  }

  /// A failed request is not an empty list, and must not claim to be one.
  Widget _loadFailed() {
    return ListView(
      children: [
        const SizedBox(height: 90),
        Icon(Icons.wifi_off_rounded, size: 64, color: kMuted.withOpacity(0.45)),
        const SizedBox(height: 12),
        Center(
          child: Text("Couldn't load your bookings",
              style: inter(fontSize: 15, fontWeight: FontWeight.w600, color: kInk)),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text('Check your connection and try again.',
              style: inter(fontSize: 13, color: kMuted)),
        ),
        const SizedBox(height: 14),
        Center(
          child: OutlinedButton.icon(
            onPressed: () => userController.getUserHistory(),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
          ),
        ),
      ],
    );
  }

  Widget _empty(int bucket) {
    const labels = ['upcoming', 'ongoing', 'completed', 'cancelled'];
    const icons = [
      Icons.event_available_outlined,
      Icons.luggage_outlined,
      Icons.check_circle_outline,
      Icons.cancel_outlined,
    ];
    return ListView(
      children: [
        const SizedBox(height: 90),
        // kLine is a border colour: #EAE4DA on the #FAF8F4 scaffold is about
        // 1.15:1, so this icon was very nearly invisible.
        Icon(icons[bucket], size: 64, color: kMuted.withOpacity(0.45)),
        const SizedBox(height: 12),
        Center(
          child: Text('No ${labels[bucket]} bookings',
              style: inter(fontSize: 15, color: kMuted)),
        ),
      ],
    );
  }
}
