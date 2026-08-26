import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:rent_home/controller/deals_controller.dart';
import 'package:rent_home/controller/user_controller.dart';
import 'package:rent_home/ui/design/aajoo_skin.dart';
import 'package:rent_home/ui/screens_renter/home/components/counter_offer_banner.dart';
import 'package:rent_home/ui/screens_renter/home/components/negotiated_deal_banner.dart';
import 'package:rent_home/ui/screens_renter/home/components/resume_booking_banner.dart';
import 'package:rent_home/ui/screens_renter/home/components/stay_banner.dart';
import 'package:rent_home/ui/screens_renter/home/view_ongoing_booking.dart';
import 'package:rent_home/service/pending_booking.dart';

/// Everything the home screen has to tell THIS guest, in one swipeable rail.
///
/// These used to stack: the stay card, then the resume-booking prompt, then
/// the negotiated deal, then the host's counter — four full-width cards in a
/// column, over the map, above the fold. A guest with a stay booked and a
/// counter waiting lost most of the map to a wall of banners, and the last one
/// was usually off screen anyway.
///
/// They are pages now. One is a card; several are a rail you swipe, with dots
/// saying how many there are — the shape the deal banner already implied.
///
/// Liveness is computed HERE, from the same controllers the banners read,
/// because each banner returns an empty box when it has nothing and a rail
/// cannot swipe through invisible pages.
class HomeBannerRail extends StatefulWidget {
  const HomeBannerRail({super.key, required this.userController});

  final UserController userController;

  @override
  State<HomeBannerRail> createState() => _HomeBannerRailState();
}

class _HomeBannerRailState extends State<HomeBannerRail> {
  final _scroll = ScrollController();

  /// Whether a KYC detour left a booking half-finished. Read once — the store
  /// is on disk and the answer does not change while this screen is up,
  /// except when the banner itself clears it.
  bool _hasPending = false;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _loadPending();
    _scroll.addListener(_onScroll);
  }

  Future<void> _loadPending() async {
    final intent = await PendingBookingStore.read();
    if (!mounted) return;
    setState(() => _hasPending = intent != null);
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final width = MediaQuery.of(context).size.width * 0.9;
    final next = (_scroll.offset / width).round();
    if (next != _page) setState(() => _page = next);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deals = Get.isRegistered<DealsController>()
        ? Get.find<DealsController>()
        : Get.put(DealsController());

    return Obx(() {
      final pages = <Widget>[];

      // The guest's own stay — happening now, or the next one booked.
      final all =
          widget.userController.ongoingBookings.value?.data.bookings ?? [];
      final stay = StayBanner.pick(all);
      if (stay != null) {
        pages.add(StayBanner(
          booking: stay,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OngoingBookingView(booking: stay),
            ),
          ),
        ));
      }

      if (deals.activeDeals.isNotEmpty) pages.add(const NegotiatedDealBanner());
      if (deals.awaitingYouCount > 0) pages.add(const CounterOfferBanner());
      if (_hasPending) {
        pages.add(ResumeBookingBanner(onResolved: () {
          if (mounted) setState(() => _hasPending = false);
        }));
      }

      if (pages.isEmpty) return const SizedBox.shrink();
      if (pages.length == 1) {
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: pages.first,
        );
      }

      final width = MediaQuery.of(context).size.width * 0.9;
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          children: [
            // IntrinsicHeight so every page is as tall as the tallest — a
            // PageView needs a fixed height, and guessing one clips whichever
            // banner grows a second line.
            SingleChildScrollView(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              physics: const PageScrollPhysics(),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < pages.length; i++)
                      SizedBox(
                        width: width,
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: i == pages.length - 1 ? 0 : 10),
                          child: pages[i],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            LuxBuilder(
              builder: (context, skin) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < pages.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 5,
                      width: i == _page ? 16 : 5,
                      decoration: BoxDecoration(
                        color: i == _page ? skin.primary : skin.line,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
