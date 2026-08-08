import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rent_home/controller/alert_dialog.dart';
import '../../../../service/verify_service.dart';
import '../auth_controller.dart';

/// Drives the DIDIT identity-verification step.
///
/// Flow: create a session → open DIDIT's hosted flow in the system browser
/// (camera works natively there, unlike an in-app webview) → when the user
/// returns and taps "I've finished", poll the decision (active pull first,
/// then DB status). `renter_kyc`/`host_kyc` finish to the dashboard; `guest_kyc`
/// returns the verified result to the caller (booking checkout).
class KycController extends GetxController {
  final VerifyService _service = VerifyService();

  final String context; // renter_kyc | host_kyc | guest_kyc
  final bool isHost;
  final int? bookingId;
  // When true (e.g. the booking gate), finishing returns a bool result to the
  // caller via Get.back instead of navigating to a dashboard.
  final bool returnResult;

  KycController({
    required this.context,
    required this.isHost,
    this.bookingId,
    this.returnResult = false,
  });

  // idle | starting | launched | polling | verified | in_review | declined | error
  final RxString status = 'idle'.obs;
  final RxBool busy = false.obs;
  String? _sessionId;

  bool get isGuestContext => context == 'guest_kyc';

  /// Step 1 — create the session and open the hosted flow in the browser.
  Future<void> startVerification() async {
    try {
      busy.value = true;
      status.value = 'starting';
      final session = await _service.createSession(
        context: context,
        bookingId: bookingId,
      );
      _sessionId = session['sessionId']?.toString();
      final url = session['sessionUrl']?.toString();

      // DIDIT not configured server-side (stub) — don't block the flow.
      if (session['stub'] == true || url == null || url.isEmpty) {
        showAlert('Verification unavailable',
            'Identity verification is temporarily unavailable. You can continue and verify later.', false);
        _finish(verified: false);
        return;
      }

      final opened = await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication);
      if (!opened) {
        status.value = 'error';
        showAlert('Error', "Couldn't open the verification page.", true);
        return;
      }
      status.value = 'launched';
    } catch (e) {
      status.value = 'error';
      showAlert('Error', e.toString().replaceAll('Exception: ', ''), true);
    } finally {
      busy.value = false;
    }
  }

  /// Step 2 — after the user completes the flow in the browser and returns.
  Future<void> pollDecision() async {
    if (_sessionId == null || _sessionId!.isEmpty) {
      showAlert('Error', 'No verification session found. Please start again.', true);
      status.value = 'idle';
      return;
    }
    try {
      busy.value = true;
      status.value = 'polling';
      // First call actively pulls the decision from DIDIT (don't wait for webhook).
      String st = 'pending';
      try {
        st = await _service.checkSession(_sessionId!);
      } catch (_) {}
      for (int i = 0; i < 8 && !_isTerminal(st); i++) {
        await Future.delayed(const Duration(seconds: 3));
        try {
          st = await _service.getStatus(_sessionId!);
        } catch (_) {}
      }

      if (_isVerified(st)) {
        status.value = 'verified';
        showAlert('Verified', 'Your identity has been verified.', false);
        _finish(verified: true);
      } else if (st == 'declined') {
        status.value = 'declined';
        showAlert('Verification failed',
            "We couldn't verify your identity. Please try again.", true);
      } else {
        // pending / in_review — let them proceed; status updates server-side.
        status.value = 'in_review';
        showAlert('In review',
            'Your verification is being reviewed. You can continue meanwhile.', false);
        _finish(verified: false);
      }
    } catch (e) {
      status.value = 'error';
      showAlert('Error', e.toString().replaceAll('Exception: ', ''), true);
    } finally {
      busy.value = false;
    }
  }

  /// User chose "I'll do this later".
  void skipForNow() {
    _finish(verified: false);
  }

  Future<void> _finish({required bool verified}) async {
    // Refresh cached user so verification_status reflects on profile + gates.
    if (Get.isRegistered<AuthController>()) {
      try {
        await Get.find<AuthController>().getUserDetails(skipLogoutOnError: true);
      } catch (_) {}
    }
    if (isGuestContext || returnResult) {
      Get.back(result: verified); // back to the caller (e.g. booking screen)
      return;
    }
    Get.offAllNamed(isHost ? '/host/home' : '/home');
  }

  bool _isTerminal(String s) =>
      _isVerified(s) || s == 'declined' || s == 'in_review' || s == 'error';

  bool _isVerified(String s) => s == 'verified' || s == 'approved';
}
