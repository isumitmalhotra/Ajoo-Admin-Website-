import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rent_home/controller/user_controller.dart';
import 'package:rent_home/ui/screens_renter/history/components/booking_cart.dart';
import 'package:rent_home/ui/screens_renter/history/components/renter_history_list_shimmer.dart';
import 'package:shimmer/shimmer.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: _appBar(context),
        body: RefreshIndicator(
          onRefresh: () async {
            userController.getUserHistory();
          },
          child: Obx(() {
            if (userController.isLoading.value) {
              return const RenterHistoryListShimmerView();
            }
            if (userController.isError.value) {
              return const Center(child: Text('Error fetching data'));
            }

            final history = userController.bookingHistory.value;
            if (history == null || history.data.isEmpty) {
              return noHistoryView();
            }

            history.data.sort((a, b) {
              final dateA = DateTime.tryParse(a.bookAddedAt.toString());
              final dateB = DateTime.tryParse(b.bookAddedAt.toString());

              if (dateA == null || dateB == null) return 0;
              return dateB.compareTo(dateA);
            });

            return ListView.builder(
              itemCount: history.data.length,
              itemBuilder: (context, index) {
                final booking = history.data[index];
                return BookingCard(booking: booking);
              },
            );
          }),
        ));
  }

  AppBar _appBar(BuildContext context) {
    return AppBar(
      title: Text(
        'History',
        style: TextStyle(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
      ),
      backgroundColor: Theme.of(context).primaryColor,
      centerTitle: true,
      foregroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }

  Column noHistoryView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Iconsax.clock,
          size: 100,
          color: Colors.grey[300],
        ),
        const SizedBox(height: 10),
        const Center(
          child: Text(
            'No History',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
