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
import 'package:rent_home/ui/screens_renter/guest_shell.dart';
import 'package:rent_home/utils/stay_clock.dart';

/// My Bookings — re-skinned to the new design (scaffold bookings_screen): teal
/// app bar + 4 status tabs (Upcoming / Ongoing / Completed / Cancelled). The
/// getUserHistory wiring + BookingCard rows are unchanged; tabs just filter the
/// same real data by status.
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

    if (parseStayDate(from) != null && parseStayDate(to) != null) {
      if (hasEnded(to)) return 2; // Completed
      if (isStaying(from, to)) return 1; // Ongoing
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
          backgroundColor: kIndigo,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text('My Bookings',
              style: fraunces(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            indicatorWeight: 2.5,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: inter(fontSize: 13.5, fontWeight: FontWeight.w700),
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
            final all = (userController.isError.value || history == null)
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
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 6, bottom: 20),
                  itemCount: items.length,
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
        Icon(icons[bucket], size: 64, color: kLine),
        const SizedBox(height: 12),
        Center(
          child: Text('No ${labels[bucket]} bookings',
              style: inter(fontSize: 15, color: kMuted)),
        ),
      ],
    );
  }
}
