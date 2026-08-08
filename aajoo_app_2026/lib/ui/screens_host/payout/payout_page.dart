import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/ui/screens_host/payout/add_payout_account_page.dart';
import 'package:rent_home/ui/screens_host/payout/components/plan_overview_card.dart';
import 'package:rent_home/ui/screens_host/payout/payout_controller.dart';
import 'package:rent_home/utils/fonts.dart';

class PayoutPage extends StatefulWidget {
  const PayoutPage({super.key});

  @override
  State<PayoutPage> createState() => _PayoutPageState();
}

class _PayoutPageState extends State<PayoutPage> {
  late final PayoutController _payoutController;

  @override
  void initState() {
    super.initState();
    _payoutController = Get.isRegistered<PayoutController>()
        ? Get.find<PayoutController>()
        : Get.put(PayoutController());
    // Fire both fetches concurrently; UI uses isLoading / isAccountLoading.
    _payoutController.fetchPayoutList();
    _payoutController.fetchAccountDetails();
  }

  Future<void> _refresh() async {
    await Future.wait([
      _payoutController.fetchPayoutList(),
      _payoutController.fetchAccountDetails(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kcontentColor,
      appBar: AppBar(
        title: Text('Payout',
            style: fraunces(
                fontSize: 20, fontWeight: FontWeight.w500, color: kCream)),
        backgroundColor: kprimaryColor,
        foregroundColor: kscaffoldColor,
        centerTitle: true,
      ),
      body: Obx(() {
        if (_payoutController.isLoading.value &&
            _payoutController.payoutListResponse.value?.data.payoutRequests
                    .isEmpty ==
                true) {
          return const Center(child: CircularProgressIndicator());
        }

        // Treat error and empty the same — both feel like "no payouts yet"
        // to the user. Soft empty state avoids red error text on a network
        // drop / 401.
        final payouts = _payoutController.isError.value
            ? const []
            : _payoutController
                    .payoutListResponse.value?.data.payoutRequests ??
                [];

        return RefreshIndicator(
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PlanOverviewCard(payoutController: _payoutController),
                const SizedBox(height: 20),
                _bankAccountCard(),
                const SizedBox(height: 20),
                _requestPayoutButton(context),
                const SizedBox(height: 30),
                Text(
                  'Payout History',
                  style: fraunces(
                      fontSize: 22, fontWeight: FontWeight.w500, color: kInk),
                ),
                const SizedBox(height: 10),
                payouts.isEmpty
                    ? _emptyState()
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: payouts.length,
                        itemBuilder: (context, index) {
                          final payoutRequest = _payoutController
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
          ),
        );
      }),
    );
  }

  Widget _bankAccountCard() {
    return Obx(() {
      final loading = _payoutController.isAccountLoading.value;
      final acc = _payoutController.accountDetails.value;

      if (loading && acc == null) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kCream,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kLine),
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Loading bank account…',
                  style: TextStyle(color: kInk2)),
            ],
          ),
        );
      }

      if (acc == null) {
        return _noAccountCard();
      }

      return _accountSummaryCard(acc.accountNumber, acc.accountIfsc);
    });
  }

  Widget _noAccountCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kClay.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance, color: kClay),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No bank account on file',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kInk,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Add your bank details to receive payouts.',
                      style: TextStyle(fontSize: 13, color: kMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openAddAccount,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Bank Account'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kClay,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountSummaryCard(String accountNumber, String ifsc) {
    final masked = _maskAccount(accountNumber);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kLine),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kIndigo.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_rounded, color: kIndigo),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payout Account',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  masked,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: kInk,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'IFSC · ${ifsc.toUpperCase()}',
                  style: const TextStyle(fontSize: 12.5, color: kInk2),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _openAddAccount,
            style: TextButton.styleFrom(foregroundColor: kIndigo),
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  String _maskAccount(String accountNumber) {
    if (accountNumber.length <= 4) return accountNumber;
    final last4 = accountNumber.substring(accountNumber.length - 4);
    return '•••• •••• $last4';
  }

  Future<void> _openAddAccount() async {
    final saved = await Get.to(() => const AddPayoutAccountPage());
    if (saved == true) {
      await _payoutController.fetchAccountDetails();
    }
  }

  Widget _requestPayoutButton(BuildContext context) {
    return Obx(() {
      final hasAccount = _payoutController.hasAccount;
      return Center(
        child: ElevatedButton(
          onPressed: hasAccount
              ? () => _showPayoutRequestBottomSheet(context, _payoutController)
              : () {
                  Get.snackbar(
                    'Add bank account',
                    'Please add your bank account before requesting a payout.',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: kClay,
                    colorText: Colors.white,
                  );
                  _openAddAccount();
                },
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledForegroundColor: Colors.white70,
          ),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: hasAccount
                    ? [kprimaryColor, kprimaryColor.withOpacity(0.8)]
                    : [kMuted.withOpacity(0.7), kMuted.withOpacity(0.5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              constraints:
                  const BoxConstraints(minWidth: 200, minHeight: 50),
              alignment: Alignment.center,
              child: Text(
                hasAccount ? 'Request Payout' : 'Add Account to Request',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _emptyState() {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_balance_wallet_outlined,
              size: 32, color: kMuted),
          const SizedBox(height: 8),
          Text('No Payout History',
              style: inter(fontSize: 14, color: kMuted)),
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
      color: kCream,
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
                color: kInk,
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
                Text(
                  'Request Payout',
                  style: fraunces(
                      fontSize: 22, fontWeight: FontWeight.w500, color: kInk),
                ),
                const SizedBox(height: 8),
                Obx(() {
                  final acc = payoutController.accountDetails.value;
                  if (acc == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Payout will be sent to ${_maskAccount(acc.accountNumber)} (IFSC ${acc.accountIfsc.toUpperCase()})',
                      style: const TextStyle(fontSize: 13, color: kMuted),
                    ),
                  );
                }),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Enter Amount (₹)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.currency_rupee,
                        color: kprimaryColor),
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
                              if (amount == null || amount <= 0) {
                                Get.snackbar(
                                  'Error',
                                  'Please enter a valid amount',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: kDanger,
                                  colorText: Colors.white,
                                );
                                return;
                              }
                              final success = await payoutController
                                  .createPayoutRequest(amount);
                              if (success) {
                                Get.snackbar(
                                  'Success',
                                  'Payout request created successfully',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: kSuccess,
                                  colorText: Colors.white,
                                );
                                payoutController.fetchPayoutList();
                                Navigator.pop(context);
                              } else {
                                Get.snackbar(
                                  'Error',
                                  'Failed to create payout request',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: kDanger,
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
