import 'package:get/get.dart';
import 'package:rent_home/data/models/payout_list_model.dart';
import 'package:rent_home/service/host_payout_service.dart';

class PayoutController extends GetxController {
  final _payoutService = HostPayoutService();
  Rx<PayoutListResponse?> payoutListResponse = PayoutListResponse(
      success: false,
      message: "",
      data: Data(hostTotalEarning: 0, earningLeft: 0, payoutRequests: [])).obs;
  RxBool isLoading = false.obs;
  RxBool isError = false.obs;

  // Future<void> fetchPayoutList() async {
  //   isLoading.value = true;
  //   try {
  //     payoutListResponse.value = await _payoutService.getPayoutList();
  //     isError.value = false;
  //   } catch (e) {
  //     isError.value = true;
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }
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
