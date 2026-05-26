import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/ui/screens_host/payout/payout_controller.dart';

import 'package:flutter/material.dart';

class PlanOverviewCard extends StatelessWidget {
  const PlanOverviewCard({
    super.key,
    required this.payoutController,
  });

  final PayoutController payoutController;

  static const Color _cardBgColor = Color(0xFFF6D1DC); // Dark Pink
  static const Color _titleColor = Color(0xFF6A1B4D); // Deep Pink
  static const Color _textColor = Color(0xFF4A2C35);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _cardBgColor,
      elevation: 4,
      shadowColor: _titleColor.withOpacity(0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 Plan Title
            const Text(
              'Basic Plan',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _titleColor,
              ),
            ),

            const SizedBox(height: 6),

            /// 🔹 Subtitle
            const Text(
              'Free Listing on every Property',
              style: TextStyle(
                fontSize: 16,
                color: _textColor,
              ),
            ),

            const SizedBox(height: 22),

            /// 🔹 Content State
            payoutController.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : payoutController.isError.value
                    ? const Text(
                        'Error loading data',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : Column(
                        children: [
                          _infoRow(
                            icon: Icons.bookmark_outline,
                            label: 'Monthly Bookings',
                            value:
                                '${payoutController.payoutListResponse.value?.data.payoutRequests.length ?? 0}',
                          ),
                          const SizedBox(height: 14),
                          _infoRow(
                            icon: Icons.account_balance_wallet_outlined,
                            label: 'Total Earnings',
                            value:
                                '₹${payoutController.payoutListResponse.value?.data.hostTotalEarning ?? 0}',
                          ),
                          const SizedBox(height: 14),
                          _infoRow(
                            icon: Icons.pending_actions,
                            label: 'Amount Pending',
                            value:
                                '₹${payoutController.payoutListResponse.value?.data.earningLeft ?? 0}',
                          ),
                        ],
                      ),

            const SizedBox(height: 26),

            /// 🔹 Progress Title
            const Text(
              'Earnings Goal Progress',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _titleColor,
              ),
            ),

            const SizedBox(height: 10),

            /// 🔹 Progress Bar
            LinearProgressIndicator(
              value: payoutController.isLoading.value ||
                      payoutController.isError.value
                  ? 0
                  : ((payoutController.payoutListResponse.value?.data
                                  .hostTotalEarning ??
                              0) /
                          35000)
                      .clamp(0.0, 1.0),
              backgroundColor: Colors.white.withOpacity(0.6),
              color: _titleColor,
              minHeight: 10,
              borderRadius: BorderRadius.circular(10),
            ),

            const SizedBox(height: 8),

            /// 🔹 Progress Text
            Text(
              '${(((payoutController.payoutListResponse.value?.data.hostTotalEarning ?? 0) / 35000) * 100).clamp(0, 100).toStringAsFixed(0)}% of your ₹35,000 monthly goal',
              style: const TextStyle(
                fontSize: 14,
                color: _textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Reusable Info Row
  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: _titleColor, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: _textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            color: _titleColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// class PlanOverviewCard extends StatelessWidget {
//   const PlanOverviewCard({
//     super.key,
//     required this.payoutController,
//   });

//   final PayoutController payoutController;

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       color: kcontentColor,
//       elevation: 0,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Basic Plan',
//               style: TextStyle(
//                 fontSize: 26,
//                 fontWeight: FontWeight.bold,
//                 color: kprimaryColor,
//               ),
//             ),
//             const SizedBox(height: 10),
//             const Text(
//               'Free Listing on every Property',
//               style: TextStyle(fontSize: 18, color: Colors.grey),
//             ),
//             const SizedBox(height: 20),
//             payoutController.isLoading.value
//                 ? const Center(child: CircularProgressIndicator())
//                 : payoutController.isError.value
//                     ? const Text(
//                         'Error loading data',
//                         style: TextStyle(color: Colors.red, fontSize: 16),
//                       )
//                     : Column(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             'Monthly Bookings: ${payoutController.payoutListResponse.value?.data.payoutRequests.length ?? 0}',
//                             style: const TextStyle(
//                                 fontSize: 18, fontWeight: FontWeight.w700),
//                           ),
//                           const SizedBox(height: 20),
//                           Text(
//                             'Total Earnings: ₹${payoutController.payoutListResponse.value?.data.hostTotalEarning ?? 0}',
//                             style: const TextStyle(
//                                 fontSize: 18, fontWeight: FontWeight.w700),
//                           ),
//                           const SizedBox(height: 20),
//                           Text(
//                             'Amount Pending: ₹${payoutController.payoutListResponse.value?.data.earningLeft.toString() ?? 0}',
//                             style: const TextStyle(
//                                 fontSize: 15, fontWeight: FontWeight.w700),
//                           ),
//                         ],
//                       ),
//             const SizedBox(height: 20),
//             // Progress Indicator for Earnings Goal
//             const Text(
//               'Earnings Goal Progress',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             LinearProgressIndicator(
//               value: payoutController.isLoading.value ||
//                       payoutController.isError.value
//                   ? 0
//                   : (payoutController.payoutListResponse.value?.data
//                               .hostTotalEarning ??
//                           0) /
//                       35000, // Assuming ₹35,000 as the goal
//               backgroundColor: Colors.grey[200],
//               color: kprimaryColor,
//               minHeight: 8,
//             ),
//             const SizedBox(height: 5),
//             Text(
//               '${((payoutController.payoutListResponse.value?.data.hostTotalEarning ?? 0) / 35000 * 100).toStringAsFixed(0)}% of your ₹35,000 monthly goal',
//               style: const TextStyle(fontSize: 14, color: Colors.grey),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
