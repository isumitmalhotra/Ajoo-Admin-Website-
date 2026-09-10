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

/// Bucket a booking into one of the four tabs.
///
/// Status alone is not enough. A stay that has been paid for keeps the status
/// "Paid" for its whole life — nothing moves it on when the guest checks out —
/// so bucketing on the title left finished stays sitting under Upcoming
/// indefinitely, disagreeing with the dashboard count beside it. The dates
/// decide, using the same 2 PM / 11 AM window as the web and the rest of this
/// app; the title only settles what the dates cannot say (cancelled), and is
/// the fallback when they cannot be read.
int bookingTabIndex(String? title,
    {String? from, String? to, StayHours? hours}) {
  final s = (title ?? '').toLowerCase();
  if (s.contains('cancel')) return 3; // Cancelled — dates are irrelevant.

  // A host who has CHECKED THE GUEST IN has said the stay is happening —
  // that beats the clock. Without this, a guest checked in at 9am sat under
  // Upcoming until the listing's check-in hour while their own card read
  // "Staying now": the same card disagreeing with the tab it was filed in.
  final checkedIn = s.contains('check in') || s.contains('check-in');

  if (parseStayDate(from) != null && parseStayDate(to) != null) {
    if (hasEnded(to, hours: hours)) return 2; // Completed
    if (checkedIn || isStaying(from, to, hours: hours)) return 1; // Ongoing
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

  /// Whether the tab has already been moved to the booking a notification
  /// pointed at. Once only — after that the tabs are the reader's to choose.
  bool _tabSnapped = false;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      userController.getUserHistory();
    });
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
  /// The booking a notification pointed at, if this screen was opened by one.
  ///
  /// Guarded exactly as the tab is: as the shell's Bookings tab, Get.arguments
  /// belongs to the shell's route, and an unrelated argument would otherwise
  /// flash a card nobody asked about.
  String? _highlightId(BuildContext context) {
    if (GuestShellScope.maybeOf(context) != null) return null;
    final args = Get.arguments;
    if (args is! Map) return null;
    final id = (args['highlight'] ?? '').toString().trim();
    return id.isEmpty ? null : id;
  }

  /// A card, flashed and scrolled to when it is the one the guest was sent for.
  Widget _maybeHighlight(dynamic booking, String? highlightId) {
    final isTarget = highlightId != null &&
        (booking.bookId ?? '').toString().trim() == highlightId;
    if (!isTarget) return BookingCard(booking: booking);
    final key = GlobalKey();
    // After the frame it is built in — ensureVisible needs a laid-out element,
    // and this is the first moment there is one.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = key.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            duration: const Duration(milliseconds: 400),
            alignment: 0.2,
            curve: Curves.easeOut);
      }
    });
    return BookingCard(key: key, booking: booking, highlight: true);
  }

  /// Open the tab the booking is actually in.
  ///
  /// The tab came from the notification's wording, so "Booking Successfull"
  /// always asked for Upcoming. But a notification outlives the stay it is
  /// about: on build 51, tapping the confirmation for B719836 landed on
  /// Upcoming, which said "No upcoming bookings" — while that very stay sat
  /// under Completed, one tab away, with no sign it was there.
  ///
  /// The bookings are the authority, not the wording. Once they have loaded
  /// the tab follows the one being pointed at; a booking that is not among
  /// them leaves the requested tab alone.
  void _snapToBookingTab(
      BuildContext ctx, List<BookingHistoryData> all, String? highlightId) {
    if (_tabSnapped || highlightId == null || all.isEmpty) return;
    BookingHistoryData? target;
    for (final b in all) {
      if ((b.bookId ?? '').toString().trim() == highlightId) {
        target = b;
        break;
      }
    }
    if (target == null) return;
    _tabSnapped = true;
    final bucket = bookingTabIndex(target.bookingStatusBsTitle,
        from: target.bookDetailsBtBookFrom,
        to: target.bookDetailsBtBookTo,
        hours: target.stayHours);
    final controller = DefaultTabController.maybeOf(ctx);
    if (controller == null || controller.index == bucket) return;
    // Not during a build: this runs inside the Obx that renders the list.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.animateTo(bucket);
    });
  }

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
        // A context BELOW the DefaultTabController, so the list can move the
        // tab once it knows which one holds the booking.
        body: Builder(builder: (ctx) => RefreshIndicator(
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
            _snapToBookingTab(ctx, all, _highlightId(ctx));
            return TabBarView(
              children: List.generate(4, (bucket) {
                final items =
                    all
                        .where((b) =>
                            bookingTabIndex(b.bookingStatusBsTitle,
                                from: b.bookDetailsBtBookFrom,
                                to: b.bookDetailsBtBookTo,
                                hours: b.stayHours) ==
                            bucket)
                        .toList();
                if (items.isEmpty) return _empty(bucket);
                // One column on a phone, two or three across a tablet. The
                // cards are self-contained, so this is a layout change only —
                // same cards, same order, same tap target.
                final columns = context.gridColumns(target: 400, max: 3);
                final highlightId = _highlightId(context);
                // Far enough that a highlighted card a few rows down is built
                // and can be scrolled to, without building the whole list.
                const cache = 2000.0;
                if (columns == 1) {
                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 6, bottom: 20),
                    itemCount: items.length,
                    cacheExtent: cache,
                    itemBuilder: (context, i) => Reveal(
                      delay: Reveal.staggerDelay(i),
                      child: _maybeHighlight(items[i], highlightId),
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
                  cacheExtent: cache,
                  itemBuilder: (context, i) => Reveal(
                    delay: Reveal.staggerDelay(i),
                    child: _maybeHighlight(items[i], highlightId),
                  ),
                );
              }),
            );
          }),
        )),
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
