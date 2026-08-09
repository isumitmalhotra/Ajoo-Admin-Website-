import 'package:flutter/material.dart';
import '../../../utils/stay_clock.dart';
import '../../motion/aajoo_motion.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/controller/deals_controller.dart';
import 'package:rent_home/controller/user_controller.dart';
import 'package:rent_home/models/ongoing_reponse.dart';
import 'package:rent_home/service/bookmark_service.dart';
import 'package:rent_home/ui/screens_common/auth/auth_controller.dart';
import 'package:rent_home/ui/screens_renter/home/components/negotiated_deal_banner.dart';

/// Renter account dashboard — the mobile mirror of the web GuestDashboard.
/// Welcome header, negotiated-deal banner, at-a-glance stats (Upcoming / Saved /
/// Reviews / Total Spent), an upcoming-stays list, and quick actions. Opened
/// from the home drawer. All data comes from the same controllers/services the
/// rest of the renter app already uses.
class RenterDashboardScreen extends StatefulWidget {
  const RenterDashboardScreen({super.key});

  @override
  State<RenterDashboardScreen> createState() => _RenterDashboardScreenState();
}

class _RenterDashboardScreenState extends State<RenterDashboardScreen> {
  final UserController userController = Get.isRegistered<UserController>()
      ? Get.find<UserController>()
      : Get.put(UserController());
  final DealsController dealsController = Get.isRegistered<DealsController>()
      ? Get.find<DealsController>()
      : Get.put(DealsController());
  final AuthController authController = Get.find<AuthController>();
  final NumberFormat _fmt =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  int _savedCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    userController.fetchOngoingBookings();
    userController.getUserHistory();
    userController.getUserReviews();
    dealsController.load();
    try {
      final saved = await BookmarkService().getBookmarks();
      if (mounted) setState(() => _savedCount = saved.length);
    } catch (_) {}
  }

  double _totalSpent() {
    final hist = userController.bookingHistory.value?.data ?? [];
    double sum = 0;
    for (final b in hist) {
      final s = (b.bookingStatusBsTitle ?? '').toLowerCase();
      if (s.contains('cancel') || s.contains('pending')) continue;
      sum += double.tryParse(b.book_price?.toString() ?? '0') ?? 0;
    }
    return sum;
  }

  static String _pretty(String? dmy) {
    if (dmy == null || dmy.isEmpty) return '';
    try {
      final p = dmy.split('-');
      return DateFormat('d MMM')
          .format(DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0])));
    } catch (_) {
      return dmy;
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstName =
        (authController.userData.value?.fullName ?? '').trim().split(' ').first;
    return Scaffold(
      backgroundColor: kscaffoldColor,
      appBar: AppBar(
        backgroundColor: kIndigo,
        foregroundColor: kCream,
        title: const Text('Dashboard'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            // Welcome header
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [kIndigo, kIndigo600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, ${firstName.isEmpty ? 'there' : firstName}! 👋',
                    style: const TextStyle(
                        color: kCream,
                        fontSize: 19,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text('Ready for your next memorable stay?',
                      style: TextStyle(color: Color(0xFFD9DCEA), fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Negotiated deals (24h coupons from accepted offers)
            const NegotiatedDealBanner(),
            const SizedBox(height: 16),

            // Stats
            Obx(() {
              // /user/ongoing/bookings returns anything not yet finished —
              // both a stay in progress and one still to come — so the count
              // has to split them. Calling the whole list "Upcoming" counted a
              // guest's current stay as a future one.
              final allActive =
                  userController.ongoingBookings.value?.data.bookings ?? [];
              final upcoming = allActive
                  .where((b) => isUpcoming(b.bookDetails?.btBookFrom))
                  .length;
              final reviews =
                  userController.userReviews.value?.data.review.length ?? 0;
              final spent = _totalSpent();
              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.7,
                // Tiles arrive in sequence rather than all at once — the same
                // short cascade the web dashboard uses.
                children: [
                  Reveal(
                    delay: Reveal.staggerDelay(0),
                    child: _statCard('Upcoming Stays', '$upcoming',
                        Icons.event_available, () => Get.toNamed('/history')),
                  ),
                  Reveal(
                    delay: Reveal.staggerDelay(1),
                    child: _statCard('Saved Stays', '$_savedCount',
                        Icons.favorite_border,
                        () => Get.toNamed('/bookmarkProperties')),
                  ),
                  Reveal(
                    delay: Reveal.staggerDelay(2),
                    child: _statCard('Reviews', '$reviews', Icons.star_border,
                        () => Get.toNamed('/history')),
                  ),
                  Reveal(
                    delay: Reveal.staggerDelay(3),
                    child: _statCard('Total Spent', _fmt.format(spent),
                        Icons.account_balance_wallet_outlined,
                        () => Get.toNamed('/history')),
                  ),
                ],
              );
            }),
            const SizedBox(height: 20),

            // Upcoming stays list
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Upcoming Stays',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700, color: kInk)),
                TextButton(
                    onPressed: () => Get.toNamed('/history'),
                    child: const Text('View all',
                        style: TextStyle(color: kIndigo))),
              ],
            ),
            const SizedBox(height: 4),
            Obx(() {
              final list =
                  userController.ongoingBookings.value?.data.bookings ?? [];
              if (userController.isLoading.value && list.isEmpty) {
                return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()));
              }
              if (list.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                      color: kCream,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kLine)),
                  child: Row(
                    children: [
                      const Icon(Icons.luggage, color: kMuted),
                      const SizedBox(width: 12),
                      const Expanded(
                          child: Text('No upcoming stays yet.',
                              style: TextStyle(color: kMuted))),
                      TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Find a stay',
                              style: TextStyle(color: kIndigo))),
                    ],
                  ),
                );
              }
              return Column(
                children:
                    list.take(3).map((b) => _upcomingTile(b)).toList(),
              );
            }),
            const SizedBox(height: 20),

            // Quick actions
            const Text('Quick Actions',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700, color: kInk)),
            const SizedBox(height: 10),
            _quickAction(Icons.search, 'Find a stay',
                'Explore for your next trip', () => Navigator.of(context).pop()),
            _quickAction(Icons.favorite_border, 'Saved stays',
                'Your saved properties', () => Get.toNamed('/bookmarkProperties')),
            _quickAction(Icons.receipt_long, 'Booking history',
                'Past & current bookings', () => Get.toNamed('/history')),
            _quickAction(Icons.support_agent, 'Help & Support',
                'Get help, raise a ticket', () => Get.toNamed('/support')),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: kCream,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kLine)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: kInk)),
                ),
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                      color: kSand, borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, size: 16, color: kIndigo),
                ),
              ],
            ),
            Text(label,
                style: const TextStyle(fontSize: 12, color: kMuted)),
          ],
        ),
      ),
    );
  }

  Widget _upcomingTile(Booking b) {
    final img = b.propertyImage?.toString() ?? '';
    final from = _pretty(b.bookDetails?.btBookFrom);
    final to = _pretty(b.bookDetails?.btBookTo);
    final status = b.bookingStatusBsTitle;
    return GestureDetector(
      onTap: () => Get.toNamed('/history'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: kCream,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kLine)),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: (img.isNotEmpty)
                  ? Image.network(img,
                      width: 64,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imgFallback())
                  : _imgFallback(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.bookingPropertyPropertyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: kInk)),
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.calendar_today, size: 11, color: kMuted),
                    const SizedBox(width: 4),
                    Text('$from → $to',
                        style: const TextStyle(fontSize: 12, color: kMuted)),
                  ]),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: kSuccess.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999)),
                  child: Text(status,
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: kSuccess)),
                ),
                const SizedBox(height: 6),
                Text(_fmt.format(b.bookPrice),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: kInk)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _imgFallback() => Container(
      width: 64,
      height: 60,
      color: kSand,
      child: const Icon(Icons.home, color: kMuted));

  Widget _quickAction(
      IconData icon, String title, String sub, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: kCream,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kLine)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                  color: kSand, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: kIndigo),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: kInk)),
                  Text(sub,
                      style: const TextStyle(fontSize: 11.5, color: kMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: kMuted),
          ],
        ),
      ),
    );
  }
}
