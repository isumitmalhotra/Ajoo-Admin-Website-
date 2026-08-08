import 'package:get/get.dart';
import 'package:rent_home/data/models/payout_list_model.dart';
import 'package:rent_home/models/host_account_details_model.dart';
import 'package:rent_home/service/host_payout_service.dart';

class PayoutController extends GetxController {
  final _payoutService = HostPayoutService();

  Rx<PayoutListResponse?> payoutListResponse = PayoutListResponse(
      success: false,
      message: "",
      data: Data(hostTotalEarning: 0, earningLeft: 0, payoutRequests: [])).obs;

  Rx<HostAccountDetails?> accountDetails = Rx<HostAccountDetails?>(null);

  RxBool isLoading = false.obs;
  RxBool isError = false.obs;
  RxBool isAccountLoading = false.obs;
  RxBool isSavingAccount = false.obs;

  bool get hasAccount => accountDetails.value != null;

  Future<void> fetchPayoutList() async {
    isLoading.value = true;
    print('[PAYOUT] fetchPayoutList → START');

    try {
      print('[PAYOUT] Calling getPayoutList API');

      final response = await _payoutService.getPayoutList();

      print(
        '[PAYOUT] API SUCCESS → '
        'count: ${response.data.payoutRequests.length}',
      );

      payoutListResponse.value = response;
      isError.value = false;
    } catch (e, stackTrace) {
      isError.value = true;

      print('[PAYOUT] API ERROR → $e');
      print('[PAYOUT] STACKTRACE → $stackTrace');
    } finally {
      isLoading.value = false;
      print('[PAYOUT] fetchPayoutList → END');
    }
  }

  Future<void> fetchAccountDetails() async {
    isAccountLoading.value = true;
    try {
      final acc = await _payoutService.getHostAccountDetails();
      accountDetails.value = acc;
    } catch (e) {
      print('[PAYOUT] fetchAccountDetails ERROR → $e');
      // Soft-fail: treat unreachable account endpoint as "no account yet"
      accountDetails.value = null;
    } finally {
      isAccountLoading.value = false;
    }
  }

  Future<bool> saveAccountDetails({
    required String accountNumber,
    required String accountIfsc,
    int? accountId,
  }) async {
    isSavingAccount.value = true;
    try {
      final ok = await _payoutService.saveHostAccountDetails(
        accountNumber: accountNumber,
        accountIfsc: accountIfsc,
        accountId: accountId,
      );
      if (ok) {
        // Refresh saved state so UI gates flip immediately
        await fetchAccountDetails();
      }
      return ok;
    } catch (e) {
      print('[PAYOUT] saveAccountDetails ERROR → $e');
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
