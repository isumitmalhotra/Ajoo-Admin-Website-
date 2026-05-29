import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/ui/screens_host/payout/components/plan_overview_card.dart';
import 'package:rent_home/ui/screens_host/payout/payout_controller.dart';

class PayoutPage extends StatelessWidget {
  const PayoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize PayoutController
    final PayoutController payoutController = Get.put(PayoutController());

    // Fetch payout list on page load
    payoutController.fetchPayoutList();

    return Scaffold(
      backgroundColor: kcontentColor,
      appBar: AppBar(
        title: const Text('Payout'),
        backgroundColor: kprimaryColor,
        foregroundColor: kscaffoldColor,
        centerTitle: true,
      ),
      body: Obx(() {
        if (payoutController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (payoutController.isError.value) {
          return const Center(
            child: Text(
              'Error loading payout history',
              style: TextStyle(color: kprimaryColor),
            ),
          );
        }

        final payouts =
            payoutController.payoutListResponse.value?.data.payoutRequests ??
                [];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plan Overview Card
              PlanOverviewCard(payoutController: payoutController),
              const SizedBox(height: 20),
              // Payout Request Button
              _requestPayoutButton(context, payoutController),
              const SizedBox(height: 30),
              // Payout History Section
              const Text(
                'Payout History',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              payouts.isEmpty
                  ? _emptyState()
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: payoutController.payoutListResponse.value?.data
                              .payoutRequests.length ??
                          0,
                      itemBuilder: (context, index) {
                        final payoutRequest = payoutController
                            .payoutListResponse
                            .value!
                            .data
                            .payoutRequests[index];
                        return _buildPayoutHistoryTile(
                          date: DateFormat('MMM dd, yyyy')
                              .format(payoutRequest.createdAt),
                          amount: '₹${payoutRequest.payReqAmount}',
                          status: payoutRequest.payoutStatusBsTitle,
                          context: context,
                        );
                      },
                    ),
            ],
          ),
        );
      }),
    );
  }

  Center _requestPayoutButton(
      BuildContext context, PayoutController payoutController) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          _showPayoutRequestBottomSheet(context, payoutController);
        },
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kprimaryColor, kprimaryColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            constraints: const BoxConstraints(minWidth: 200, minHeight: 50),
            alignment: Alignment.center,
            child: const Text(
              'Request Payout',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.account_balance_wallet_outlined, size: 32),
          SizedBox(height: 8),
          Text('No Payout History'),
        ],
      ),
    );
  }

  Widget _buildPayoutHistoryTile({
    required String date,
    required String amount,
    required String status,
    required BuildContext context,
  }) {
    final bool isPending = status.toLowerCase() == 'pending';

    final Color statusColor =
        isPending ? const Color(0xFFB45309) : const Color(0xFF166534);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 3,
      color: const Color(0xFFF6D1DC), // Same as Plan card
      shadowColor: kIndigo600.withOpacity(0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            /// 🔹 Leading Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: kIndigo600,
                size: 22,
              ),
            ),

            const SizedBox(width: 14),

            /// 🔹 Title & Status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payout on $date',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: kIndigo600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isPending
                            ? Icons.hourglass_top_rounded
                            : Icons.check_circle_rounded,
                        size: 14,
                        color: statusColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// 🔹 Amount
            Text(
              amount,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A2C35),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPayoutRequestBottomSheet(
      BuildContext context, PayoutController payoutController) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController accountNumberController =
        TextEditingController();
    final TextEditingController accountIdController = TextEditingController();
    final TextEditingController ifscController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Request Payout',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Enter Amount (₹)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon:
                        const Icon(Icons.currency_rupee, color: kprimaryColor),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Account Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: accountNumberController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Account Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon:
                        const Icon(Icons.account_balance, color: kprimaryColor),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: accountIdController,
                  decoration: InputDecoration(
                    labelText: 'Account ID',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon:
                        const Icon(Icons.perm_identity, color: kprimaryColor),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: ifscController,
                  decoration: InputDecoration(
                    labelText: 'IFSC Code',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.code, color: kprimaryColor),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Obx(
                    () => ElevatedButton(
                      onPressed: payoutController.isLoading.value
                          ? null
                          : () async {
                              final amount =
                                  int.tryParse(amountController.text);
                              if (amount != null) {
                                final payoutData = {
                                  'amount': amount,
                                  'accountNumber': accountNumberController.text,
                                  'accountId': accountIdController.text,
                                  'accountIfsc': ifscController.text,
                                };
                                final success = await payoutController
                                    .createPayoutRequest(amount);
                                if (success) {
                                  Get.snackbar(
                                    'Success',
                                    'Payout request created successfully',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.green,
                                    colorText: Colors.white,
                                  );
                                  payoutController
                                      .fetchPayoutList(); // Refresh the payout list
                                  Navigator.pop(context);
                                } else {
                                  Get.snackbar(
                                    'Error',
                                    'Failed to create payout request',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.red,
                                    colorText: Colors.white,
                                  );
                                }
                              } else {
                                Get.snackbar(
                                  'Error',
                                  'Please enter a valid amount',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.red,
                                  colorText: Colors.white,
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              kprimaryColor,
                              kprimaryColor.withOpacity(0.8)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          constraints: const BoxConstraints(
                              minWidth: 200, minHeight: 50),
                          alignment: Alignment.center,
                          child: payoutController.isLoading.value
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Confirm Payout',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.white),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
