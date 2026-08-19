import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/ui/screens_host/payout/add_payout_account_page.dart';
import 'package:rent_home/ui/screens_host/payout/components/plan_overview_card.dart';
import 'package:rent_home/ui/screens_host/payout/payout_controller.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/utils/input_sanitizers.dart';

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
      backgroundColor: kSand,
      appBar: AppBar(
        title: Text('Payouts',
            style: fraunces(
                fontSize: 20, fontWeight: FontWeight.w700, color: kInk)),
        backgroundColor: kSand,
        foregroundColor: kInk,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 0,
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
                  'Payout history',
                  style: fraunces(
                      fontSize: 18, fontWeight: FontWeight.w700, color: kInk),
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
                            // Reference first, same as the website's table —
                            // it is what a host quotes to support when a
                            // payout is queried.
                            reference: 'PO-${payoutRequest.payReqId}',
                            date: DateFormat('MMM dd, yyyy')
                                .format(payoutRequest.createdAt),
                            amount: '₹${inr(payoutRequest.payReqAmount)}',
                            status: payoutRequest.payoutStatusBsTitle,
                            context: context,
                          );
                        },
                      ),
                const SizedBox(height: 24),
                // Same explanation the website gives, word for word.
                //
                // The app said nothing at all about when money moves, so the
                // page was a balance and a button with no account of what
                // happens between them. Note what it does NOT say: no "2-3
                // business days". Nothing enforces that — release is scheduled
                // by an admin and the transfer goes through RazorpayX — so
                // this describes the process instead of promising a date.
                const _PayoutScheduleNote(),
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
          // A flat filled button, like every other primary action in the app.
          // This was a transparent ElevatedButton wrapping an Ink gradient —
          // the only gradient button left on the host side.
          style: ElevatedButton.styleFrom(
            backgroundColor: hasAccount ? kIndigo : kLine,
            foregroundColor: hasAccount ? Colors.white : kMuted,
            disabledBackgroundColor: kLine,
            disabledForegroundColor: kMuted,
            elevation: 0,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            hasAccount ? 'Request payout' : 'Add an account to request',
            style: inter(fontSize: 15.5, fontWeight: FontWeight.w700),
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
    required String reference,
    required String date,
    required String amount,
    required String status,
    required BuildContext context,
  }) {
    final s = status.toLowerCase();
    final bool isPending = s.contains('pending') || s.contains('process');
    final bool isFailed =
        s.contains('fail') || s.contains('reject') || s.contains('cancel');

    final Color statusFg =
        isFailed ? kDanger : (isPending ? kClay : kSuccess);
    final Color statusBg = isFailed
        ? const Color(0xFFFDECEC)
        : (isPending ? const Color(0xFFFFF6E5) : const Color(0xFFEAF6EE));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kLine),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kIndigo50,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.account_balance_rounded,
                color: kIndigo, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reference,
                    style: inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: kInk)),
                const SizedBox(height: 2),
                Text(date, style: inter(fontSize: 12, color: kMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount,
                  style: fraunces(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: kInk)),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(status,
                    style: inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: statusFg)),
              ),
            ],
          ),
        ],
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
                  inputFormatters: AppInputFormatters.digits(7),
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

/// What actually happens to a payout, in the platform's own words.
class _PayoutScheduleNote extends StatelessWidget {
  const _PayoutScheduleNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kIndigo50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kIndigo.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 17, color: kIndigo),
              const SizedBox(width: 8),
              Text('Payout schedule',
                  style: inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: kInk)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Payouts are raised once a stay is completed, then released on "
            "your account's payout schedule. Every one is listed above with "
            "its current status, so you can see exactly where your money is.",
            style: inter(fontSize: 12.5, color: kInk2, height: 1.55),
          ),
        ],
      ),
    );
  }
}
