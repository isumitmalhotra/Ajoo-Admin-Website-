import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rent_home/data/models/properties_response_model.dart';
import 'package:rent_home/ui/screens_common/price_negotiation/negotiation_controller.dart';
import 'package:get/get.dart';

class ChatStatusCard extends StatelessWidget {
  final Property property;
  final NegotiationController negotiationController;

  // 👇 NEW PARAMS
  final bool isUser;
  final bool timerStarted;
  final bool showBookingOption;
  final int remainingTime;
  final String userId;
  final String hostId;

  // 👇 CALLBACK
  final VoidCallback onAcceptOffer;

  const ChatStatusCard({
    super.key,
    required this.property,
    required this.negotiationController,
    required this.isUser,
    required this.timerStarted,
    required this.showBookingOption,
    required this.remainingTime,
    required this.userId,
    required this.hostId,
    required this.onAcceptOffer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(locale: 'en_US', symbol: '₹');

    return SliverToBoxAdapter(
      child: Column(
        children: [
          // ================= CHAT STATUS =================
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Obx(() {
              final remainingMessages =
                  negotiationController.getRemainingMessages(userId, hostId);

              final whoseTurn =
                  negotiationController.getWhoseTurn(userId, hostId);

              final totalMessages =
                  negotiationController.userMessageCount.value +
                      negotiationController.hostMessageCount.value;

              return Card(
                elevation: 2,
                color: negotiationController.chatLimitReached.value
                    ? Colors.red[50]
                    : Colors.blue[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: negotiationController.chatLimitReached.value
                        ? Colors.red
                        : Colors.blue,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            negotiationController.chatLimitReached.value
                                ? Icons.chat_bubble_outline_rounded
                                : Icons.chat,
                            color: negotiationController.chatLimitReached.value
                                ? Colors.red
                                : Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              whoseTurn,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Denominator comes from the controller, not a
                          // literal. Hardcoding 4 here while the controller
                          // capped at 400 is how this row came to read
                          // "Messages: 0/4" beside "Your remaining: 400".
                          Text(
                              'Offers: $totalMessages/${negotiationController.maxTotalMessages}'),
                          Text(remainingMessages == 1
                              ? '1 offer left for you'
                              : '$remainingMessages offers left for you'),
                        ],
                      ),
                      if (negotiationController.chatLimitReached.value)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '⚠️ Chat limit reached! Accept the offer to proceed.',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),

          // ================= TIMER / BOOKING =================
          if (isUser && timerStarted)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 2,
                color: showBookingOption ? Colors.red[50] : Colors.orange[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: showBookingOption ? Colors.red : Colors.orange,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: showBookingOption
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.access_time, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  "Host not responding",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "The host hasn’t responded in time. You can book now.",
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: onAcceptOffer,
                              icon: const Icon(Icons.book_online),
                              label: Text(
                                "Book Now at ${formatter.format(negotiationController.currentPrice.value)}",
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 45),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            const Icon(Icons.timer, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(
                              "Waiting: ${_formatTime(remainingTime)}",
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
