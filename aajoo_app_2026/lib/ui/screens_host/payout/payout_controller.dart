import 'package:get/get.dart';
import 'package:rent_home/data/models/payout_list_model.dart';
import 'package:rent_home/models/host_account_details_model.dart';
import 'package:rent_home/service/host_payout_service.dart';

import 'package:rent_home/utils/app_log.dart';
class PayoutController extends GetxController {
  final _payoutService = HostPayoutService();

  Rx<PayoutListResponse?> payoutListResponse = PayoutListResponse(
      success: false,
      message: "",
      data: Data(
          hostTotalEarning: 0,
          earningLeft: 0,
          settled: 0,
          payoutRequests: [])).obs;

  Rx<HostAccountDetails?> accountDetails = Rx<HostAccountDetails?>(null);

  RxBool isLoading = false.obs;
  RxBool isError = false.obs;
  RxBool isAccountLoading = false.obs;
  RxBool isSavingAccount = false.obs;

  bool get hasAccount => accountDetails.value != null;

  Future<void> fetchPayoutList() async {
    isLoading.value = true;
    appLog('[PAYOUT] fetchPayoutList → START');

    try {
      appLog('[PAYOUT] Calling getPayoutList API');

      final response = await _payoutService.getPayoutList();

      appLog(
        '[PAYOUT] API SUCCESS → '
        'count: ${response.data.payoutRequests.length}',
      );

      payoutListResponse.value = response;
      isError.value = false;
    } catch (e, stackTrace) {
      isError.value = true;

      appLog('[PAYOUT] API ERROR → $e');
      appLog('[PAYOUT] STACKTRACE → $stackTrace');
    } finally {
      isLoading.value = false;
      appLog('[PAYOUT] fetchPayoutList → END');
    }
  }

  Future<void> fetchAccountDetails() async {
    isAccountLoading.value = true;
    try {
      final acc = await _payoutService.getHostAccountDetails();
      accountDetails.value = acc;
    } catch (e) {
      appLog('[PAYOUT] fetchAccountDetails ERROR → $e');
      // Soft-fail: treat unreachable account endpoint as "no account yet"
      accountDetails.value = null;
    } finally {
      isAccountLoading.value = false;
    }
  }

  Future<bool> saveAccountDetails({
    required String accountNumber,
    required String accountIfsc,
    required String accountHolderName,
    String? bankName,
    int? accountId,
  }) async {
    isSavingAccount.value = true;
    try {
      final ok = await _payoutService.saveHostAccountDetails(
        accountNumber: accountNumber,
        accountIfsc: accountIfsc,
        accountHolderName: accountHolderName,
        bankName: bankName,
        accountId: accountId,
      );
      if (ok) {
        // Refresh saved state so UI gates flip immediately
        await fetchAccountDetails();
      }
      return ok;
    } catch (e) {
      appLog('[PAYOUT] saveAccountDetails ERROR → $e');
      return false;
    } finally {
      isSavingAccount.value = false;
    }
  }

  Future<bool> createPayoutRequest(int amount) async {
    isLoading.value = true;
    try {
      final response = await _payoutService.createPayoutRequest(amount);
      return response;
    } catch (e) {
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
